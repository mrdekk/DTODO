//  Created by Denis Malykh on 06.05.2021.

import Foundation
import Swifter
import SwiftUI

class Repository: ObservableObject {
    @Published var book: DBook

    private var bookFileURL: URL
    private var httpServer: HttpServer

    init(overridingBook: DBook? = nil) {
        let fm = FileManager.default
        let writeablePath = fm.urls(for: .documentDirectory, in: .userDomainMask).first! // AHHA, force unwraping, bad!!!
        self.bookFileURL = writeablePath.appendingPathComponent("book.json")

        if let obook = overridingBook {
            self.book = obook
        } else if fm.fileExists(atPath: bookFileURL.path) {
            self.book = (try? JSONDecoder().decode(DBook.self, from: Data(contentsOf: bookFileURL))) ?? DBook()
        } else {
            self.book = DBook()
        }

        self.httpServer = HttpServer()
        self.httpServer["/test"] = { _ in
            let json: [AnyHashable: Any] = ["status": "ok"]
            return .ok(.json(json))
        }
        self.httpServer.GET["/snapshot"] = { _ in
            do {
                let bookSnapshot = try JSONEncoder().encode(self.book)
                return .raw(200, "OK", nil, { try $0.write(bookSnapshot) })
            } catch {
                let err: [String: String] = [
                    "status": "error",
                    "error": error.localizedDescription
                ]
                return .raw(500, "Internal Server Error", nil) {
                    let data = try JSONEncoder().encode(err)
                    try $0.write(data)
                }
            }
        }
        self.httpServer.POST["/snapshot"] = { [weak self] request in
            do {
                let data = Data(request.body)
                let bookSnapshot = try JSONDecoder().decode(DBook.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.book = self.book.merged(with: bookSnapshot)
                }

                let result: [AnyHashable: Any] = ["status": "ok"]
                return .ok(.json(result))
            } catch {
                let err: [String: String] = [
                    "status": "error",
                    "error": error.localizedDescription
                ]
                return .raw(500, "Internal Server Error", nil) {
                    let data = try JSONEncoder().encode(err)
                    try $0.write(data)
                }
            }
        }
        try? self.httpServer.start(UInt16(Constants.port), forceIPv4: false, priority: .default)
    }

    func note(for id: DNote.ID) -> Binding<DNote> {
        .init(
            get: { () -> DNote in
                self.book.notes.first(where: { $0.id == id })!
            },
            set: { note in
                let index = self.book.notes.firstIndex(where: { $0.id == id })!
                self.book[index] = note
            }
        )
    }

    func note(for index: Int) -> Binding<DNote> {
        .init(
            get: { () -> DNote in
                self.book[index]
            },
            set: { note in
                self.book[index] = note
            }
        )
    }

    func addEmptyNote() {
        book.append(DNote())
    }

    func saveToDisk() {
        try? JSONEncoder().encode(book).write(to: bookFileURL)
    }

    func communicateToPeers(_ peers: [Peer]) {
        DispatchQueue.global().async {
            for peer in peers {
                let client = PeerClient(peer: peer)
                var sem = DispatchSemaphore(value: 0)
                var peerSnapshot: DBook? = nil
                client.acquireSnapshot { result in
                    switch result {
                    case let .success(book):
                        peerSnapshot = book
                    case .failure:
                        break
                    }
                    sem.signal()
                }
                _ = sem.wait(timeout: .now() + 100.0) // we don't want to block forever
                guard let snapshot = peerSnapshot else {
                    continue
                }

                DispatchQueue.main.sync {
                    self.book = self.book.merged(with: snapshot)
                }

                sem = DispatchSemaphore(value: 0)
                client.submitSnapshot(self.book) { _ in
                    // do nothing yet
                    sem.signal()
                }

                _ = sem.wait(timeout: .now() + 10.0) // we don't want to block forever
            }
        }
    }


}

