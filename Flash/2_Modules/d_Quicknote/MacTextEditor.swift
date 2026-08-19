import SwiftUI

final class FocusableScrollView: NSScrollView {
    override var acceptsFirstResponder: Bool { true }
    
    override func becomeFirstResponder() -> Bool {
        if let textView = self.documentView as? NSTextView {
            return self.window?.makeFirstResponder(textView) ?? false
        }
        return super.becomeFirstResponder()
    }
}

struct MacTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onCancel: () -> Void
    
    func makeNSView(context: Context) -> FocusableScrollView {
        let scrollView = FocusableScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        
        let textView = NSTextView(frame: .zero)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: 14)
        textView.delegate = context.coordinator
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 0, height: 0)
        
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
        }
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: FocusableScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacTextEditor
        
        init(_ parent: MacTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                self.parent.onCancel()
                return true
            }
            return false
        }
    }
}
