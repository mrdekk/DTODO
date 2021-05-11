//  Created by Denis Malykh on 26.04.2021.

import Foundation

struct DNote: Identifiable, Codable, Equatable {
    var id = UUID()
    var title = DecentralizedVariable<String>("")
    var text = DecentralizedArray<Character>()
}

extension DNote: Decentralized {
    func merged(with other: DNote) -> DNote {
        var result = self
        result.title = title.merged(with: other.title)
        result.text = text.merged(with: other.text)
        return result
    }
}

extension DNote {
    static func makeDummyNote() -> DNote {
        var text = DecentralizedArray<Character>()
        "Some Sketchy Text".enumerated().forEach { text.append($0.element) }

        return DNote(
            id: UUID(),
            title: DecentralizedVariable("Hello"),
            text: text
        )
    }
}
