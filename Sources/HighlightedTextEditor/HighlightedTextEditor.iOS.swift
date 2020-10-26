#if os(iOS)
import SwiftUI
import UIKit

public struct HighlightedTextEditor: UIViewRepresentable, HighlightingTextEditor {

    @Binding var text: String {
        didSet {
            self.onTextChange(text)
        }
    }
    let highlightRules: [HighlightRule]
    
    var autofocus = false
    var onEditingChanged: () -> Void       = {}
    var onCommit        : () -> Void       = {}
    var onTextChange    : (String) -> Void = { _ in }
    
    public init(
        text: Binding<String>,
        highlightRules: [HighlightRule],
        onEditingChanged: @escaping () -> Void = {},
        onCommit: @escaping () -> Void = {},
        onTextChange: @escaping (String) -> Void = { _ in }
    ) {
        _text = text
        self.highlightRules = highlightRules
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit
        self.onTextChange = onTextChange
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func autofocus(_ autofocus: Bool = true) -> Self {
        var copy = self
        copy.autofocus = autofocus
        return copy
    }
    
    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true

        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        if context.coordinator.autofocus {
            uiView.becomeFirstResponder()
            context.coordinator.autofocus = false
        }
        
        let cursor = uiView.selectedRange
        if cursor.upperBound <= uiView.attributedText.length {
            context.coordinator.updating = cursor
            // Attributedtext is updating the position the next tick
            // Therefore, so are we
            DispatchQueue.main.async {
                uiView.selectedRange = cursor
                context.coordinator.updating = nil
            }
        }
        
        let highlightedText = HighlightedTextEditor.getHighlightedText(text: text, highlightRules: highlightRules)
        uiView.attributedText = highlightedText
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: HighlightedTextEditor
        var updating: NSRange?
        var autofocus: Bool

        init(_ markdownEditorView: HighlightedTextEditor) {
            self.parent = markdownEditorView
            self.autofocus = markdownEditorView.autofocus
        }
        
        public func textViewDidChangeSelection(_ textView: UITextView) {
            if let updating = updating {
                textView.selectedRange = updating
            }
        }
        
        public func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }
        
        public func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onEditingChanged()
        }
        
        public func textViewDidEndEditing(_ textView: UITextView) {
            parent.onCommit()
        }
    }
}
#endif
