import SwiftUI

struct VideoFeedView: View {
    @StateObject var viewModel: VideoFeedViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        if viewModel.isLoading {
            ProgressView("Loading...")
        } else if let error = viewModel.error {
            Text("Error: \(error)")
        } else {
            GeometryReader { proxy in
                ZStack {
                    ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                        if abs(index - viewModel.currentIndex) <= 1 {
                            VideoPlayerView(
                                player: viewModel.player(for: index),
                                isActive: .constant(viewModel.currentIndex == index),
                                accessibilityId: index
                            )
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .offset(y: CGFloat(index - viewModel.currentIndex) * proxy.size.height + dragOffset)
                            .animation(isDragging ? nil : .spring(), value: dragOffset)
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                            isDragging = true
                        }
                        .onEnded { value in
                            let direction: Int
                            if value.translation.height < -swipeThreshold {
                                direction = 1
                            } else if value.translation.height > swipeThreshold {
                                direction = -1 
                            } else {
                                direction = 0
                            }
                            let newIndex = viewModel.currentIndex + direction
                            if direction != 0,
                               newIndex >= 0,
                               newIndex < viewModel.videos.count,
                               viewModel.videoReadyStates[safe: newIndex, default: false] {
                                viewModel.currentIndex = newIndex
                                viewModel.onPageChange(to: newIndex)
                            }
                            dragOffset = 0
                            isDragging = false
                        }
                )
            }
            .background(Color.black)
            .ignoresSafeArea()
        }
    }
}

// Safe subscript extension remains unchanged
extension Array {
    subscript(safe index: Int, default defaultValue: Element) -> Element {
        indices.contains(index) ? self[index] : defaultValue
    }
}
