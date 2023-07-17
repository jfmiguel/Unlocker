import SwiftUI

/// Unlocker is a simple slider library for SwiftUI, which can look like `Slide to Unlock`.
/// You can use this library easily wherever you want, such as `Slide to Purchase` for the payment UX.
public struct Unlocker<Content>: View where Content: View {
    
    /// This is a flag to `prevent the slider works multiple times` during the process.
    @Binding var disabled: Bool
    /// This is the percentage of the slider.
    @Binding var percentage: Float
    
    /// This is the width of the view that holds the toggle.
    private let toggleWidth: Float
    /// This is the threshold where the completion would start. Also this will make your slider disabled to prevent the slider works multiple times during the process.
    private let threshold: Float
    /// This is the duration for the animation to make the slider fully filled. The default value is 0.3 second.
    private let duration: Double
    
    /// This is the custom view inside of the slider.
    private let content: (_ sliderWidth: CGFloat) -> Content
    
    /// This is the completion, which will be run the percentage of the progress of the slider has passed the threshold.
    private let completion: (() -> Void)?
    
    /// This defines if the percentage should be reset after completion has been executed
    private let resetOnCompletion: Bool
    
    /// Unlocker
    /// - Parameters:
    ///   - disabled: This is a flag to `prevent the slider works multiple times` during the process.
    ///   - percentage: This is the percentage of the slider.
    ///   - toggleWidth: This is the width of the view that holds the toggle.
    ///   - threshold: This is the threshold where the completion would start. Also this will make your slider disabled to prevent the slider works multiple times during the process.
    ///   - duration: /// This is the duration for the animation to make the slider fully filled. The default value is 0.3 second.
    ///   - content: This is the custom view inside of the slider.
    ///   - completion: This is the completion, which will be run the percentage of the progress of the slider has passed the threshold.
    public init(
        disabled: Binding<Bool>,
        percentage: Binding<Float>,
        toggleWidth: Float = 50,
        threshold: Float = 50.0,
        duration: Double = 0.3,
        resetOnCompletion: Bool = true,
        @ViewBuilder content: @escaping (_ sliderWidth: CGFloat) -> Content,
        completion: (() -> Void)? = nil
    ) {
        self._disabled = disabled
        self._percentage = percentage
        self.threshold = threshold
        self.duration = duration
        self.content = content
        self.completion = completion
        self.toggleWidth = toggleWidth
        self.resetOnCompletion = resetOnCompletion
    }
    
    public var body: some View {
        GeometryReader { geo in
            
            // Slider
            ZStack(alignment: .leading) {
                
                let swipeWidth = abs(geo.size.width * CGFloat(percentage / 100))

                // Custom View
                content(swipeWidth)
                    .frame(width: swipeWidth)
                
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        onChanged(with: value, geoProxy: geo)
                    })
                    .onEnded({ _ in
                        onEnded()
                    })
            )
            
            } //: Z

        } //: G
        .padding(.leading, CGFloat(self.toggleWidth) / 2)
        .disabled(disabled)
    }
    
}

// MARK: - Slider Gestures

extension Unlocker {
    
    
    /// Drag gesture onChanged for the slider
    /// - Parameters:
    ///   - value: The gesture value
    ///   - geoProxy: The geometry proxy of the slider
    private func onChanged(with value: DragGesture.Value, geoProxy: GeometryProxy) {
        
        // Dragged to the right
        if value.translation.width > 0 {
            DispatchQueue.main.async {
                withAnimation(.easeOut) {
                    // change percentage value
                    percentage = min(max(0.0, Float(value.location.x / geoProxy.size.width * 100)), 100)
                }
            }
        }
        
        // Dragged to the left / shouldn't change
        if value.translation.width < 0 {
            DispatchQueue.main.async {
                withAnimation(.easeOut) {
                    // reset
                    percentage = 0.0
                }
            }
        }
    }
    
    /// Drag gesture onEnded for the slider
    private func onEnded() {
        if percentage > threshold {
            
            disabled = true // prevent user interaction for the completion
            
            // Fill the slider
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: duration)) {
                    percentage = 100
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                completion?()
            }
            
            // Reset slider
            if resetOnCompletion {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.2) {
                    withAnimation(.easeOut(duration: duration)) {
                        percentage = 0.0
                    }
                }
            }
            
        } else {
            
            // Reset slider
            DispatchQueue.main.async {
                withAnimation(.easeOut) {
                    percentage = 0.0
                }
            }
            
        }
    }
    
}
