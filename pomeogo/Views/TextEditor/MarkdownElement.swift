import Foundation

struct MarkdownElement: Hashable {
    let type: MarkdownElementType
    let content: String
}

enum MarkdownElementType {
    case header1, header2, header3
    case paragraph
    case code
    case listItem
}
