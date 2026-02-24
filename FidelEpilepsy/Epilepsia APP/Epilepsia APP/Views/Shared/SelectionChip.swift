import SwiftUI

struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.Medical.accent : Color.Medical.card)
                .foregroundColor(isSelected ? .white : Color.Medical.textSecondary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.Medical.accent : Color.Medical.neutral.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// Helper for Flow Layout
struct ChipLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return rows.reduce(CGSize.zero) { size, row in
            CGSize(width: max(size.width, row.width), height: size.height + row.height + spacing)
        }
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var height: CGFloat = 0
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        for row in rows {
            var x: CGFloat = 0
            for item in row.items {
                item.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + height), proposal: ProposedViewSize(width: item.width, height: item.height))
                x += item.width + spacing
            }
            height += row.height + spacing
        }
    }
    
    struct Row {
        var items: [Item]
        var width: CGFloat
        var height: CGFloat
    }
    
    struct Item {
        var subview: LayoutSubview
        var width: CGFloat
        var height: CGFloat
        
        func place(at point: CGPoint, proposal: ProposedViewSize) {
            subview.place(at: point, proposal: proposal)
        }
    }
    
    func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow: [Item] = []
        var currentX: CGFloat = 0
        var currentHeight: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && !currentRow.isEmpty {
                rows.append(Row(items: currentRow, width: currentX - spacing, height: currentHeight))
                currentRow = []
                currentX = 0
                currentHeight = 0
            }
            
            currentRow.append(Item(subview: subview, width: size.width, height: size.height))
            currentX += size.width + spacing
            currentHeight = max(currentHeight, size.height)
        }
        
        if !currentRow.isEmpty {
            rows.append(Row(items: currentRow, width: currentX - spacing, height: currentHeight))
        }
        
        return rows
    }
}
