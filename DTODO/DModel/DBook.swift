//  Created by Denis Malykh on 26.04.2021.

import Foundation

struct DBook: Codable, Equatable {
    private var _notes: DecentralizedDictionary<DNote.ID, DNote> {
        didSet {
            if _notes != oldValue {
                notifyNewVersion()
            }
        }
    }

    private var _order: DecentralizedArray<DNote.ID> {
        didSet {
            if _order != oldValue {
                notifyNewVersion()
            }
        }
    }

    private(set) var versionId = UUID()
    private mutating func notifyNewVersion() {
        versionId = UUID()
    }

    var notes: [DNote] {
        _order.compactMap { _notes[$0] }
    }

    init() {
        _notes = .init()
        _order = .init()
    }

    subscript(_ index: Int) -> DNote {
        get {
            let id = _order[index]
            return _notes[id]!
        }
        set {
            let id = _order[index]
            _notes[id] = newValue
        }
    }

    mutating func append(_ note: DNote) {
        _notes[note.id] = note
        _order.append(note.id)
    }
}

extension DBook: Decentralized {
    func merged(with other: DBook) -> DBook {
        var result = self

        result._notes = result._notes.merged(with: other._notes)

        let orderedIds = _order.merged(with: other._order)
        var encounterIds = Set<DNote.ID>()
        var toRemove = [Int]()
        for (i, id) in orderedIds.enumerated() {
            if !encounterIds.insert(id).inserted || result._notes[id] == nil {
                toRemove.append(i)
            }
        }

        var uniqueIds = orderedIds
        for i in toRemove.reversed() {
            uniqueIds.remove(at: i)
        }
        result._order = uniqueIds

        return result
    }
}

extension DBook {
    static func makeDummyBook(count: Int) -> DBook {
        var book = DBook()
        for _ in 0..<count {
            book.append(DNote.makeDummyNote())
        }
        return book
    }
}
