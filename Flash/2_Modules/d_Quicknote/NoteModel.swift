import Foundation

public struct NoteModel: Identifiable, Equatable {
    // 遵循 Identifiable 协议，方便 SwiftUI 列表的高效渲染
    public var id: URL { url }
    
    // 文件的绝对路径（作为唯一标识）
    public let url: URL
    
    // 显示在左侧历史列表中的标题
    public var title: String
    
    // 文本框内的具体正文内容
    public var content: String
    
    // 本地硬件时钟记录的最后修改时间
    public let modifiedDate: Date
    
    public init(url: URL, title: String, content: String, modifiedDate: Date) {
        self.url = url
        self.title = title
        self.content = content
        self.modifiedDate = modifiedDate
    }
    
    // 遵循 Equatable 协议，方便判断当前选中的是不是同一个文件
    public static func == (lhs: NoteModel, rhs: NoteModel) -> Bool {
        return lhs.url == rhs.url
            && lhs.title == rhs.title
            && lhs.content == rhs.content
            && lhs.modifiedDate == rhs.modifiedDate
    }
}
