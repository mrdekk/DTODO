//  Created by Denis Malykh on 09.05.2021.

import Foundation

class PeerClient {
    enum Errors: Error {
        case requestPreparationFailed
        case emptyData
        case internalError(cause: Error)
    }

    let peer: Peer

    init(peer: Peer) {
        self.peer = peer
    }

    func acquireSnapshot(_ completion: @escaping (Result<DBook, Errors>) -> Void) {
        guard var request = peer.makeSnapshotRequest() else {
            completion(.failure(.requestPreparationFailed))
            return
        }

        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.internalError(cause: error)))
                return
            }

            guard let data = data else {
                completion(.failure(.emptyData))
                return
            }

            do {
                let bookSnapshot = try JSONDecoder().decode(DBook.self, from: data)
                completion(.success(bookSnapshot))
            } catch {
                completion(.failure(.internalError(cause: error)))
            }
        }
        task.resume()
    }

    func submitSnapshot(_ snapshot: DBook, completion: @escaping (Result<Void, Errors>) -> Void) {
        guard var request = peer.makeSnapshotRequest() else {
            completion(.failure(.requestPreparationFailed))
            return
        }

        request.httpMethod = "POST"

        do {
            request.httpBody = try JSONEncoder().encode(snapshot)
        } catch {
            completion(.failure(.requestPreparationFailed))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.internalError(cause: error)))
                return
            }

            guard data != nil else {
                completion(.failure(.emptyData))
                return
            }

            completion(.success(()))
        }

        task.resume()
    }
}
