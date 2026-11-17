/*
Liquid Glass Effect Modifier
ガラスモーフィズムスタイルのビジュアルエフェクト
*/

import SwiftUI

struct LiquidGlassEffect: ViewModifier {
    let tintColor: Color
    let blur: CGFloat
    let opacity: Double
    let borderWidth: CGFloat
    
    init(
        tintColor: Color = .white,
        blur: CGFloat = 20,
        opacity: Double = 0.1,
        borderWidth: CGFloat = 1
    ) {
        self.tintColor = tintColor
        self.blur = blur
        self.opacity = opacity
        self.borderWidth = borderWidth
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                // Glass background
                Rectangle()
                    .fill(tintColor.opacity(opacity))
                    .background(.ultraThinMaterial)
                    .blur(radius: blur / 4)
            }
            .overlay {
                // Glass border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.6),
                                .white.opacity(0.1),
                                .clear,
                                .white.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: .black.opacity(0.1),
                radius: 20,
                x: 0,
                y: 10
            )
    }
}

struct LiquidGlassButton: ViewModifier {
    let isPressed: Bool
    let tintColor: Color
    
    init(isPressed: Bool = false, tintColor: Color = .blue) {
        self.isPressed = isPressed
        self.tintColor = tintColor
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .background {
                // Glass background with color tint
                RoundedRectangle(cornerRadius: 16)
                    .fill(tintColor.opacity(0.15))
                    .background(.ultraThinMaterial)
                    .overlay {
                        // Inner glow
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tintColor.opacity(0.3),
                                        .clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                    }
            }
            .overlay {
                // Glass border with shimmer
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.8),
                                tintColor.opacity(0.4),
                                .clear,
                                .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(
                color: tintColor.opacity(0.3),
                radius: isPressed ? 8 : 12,
                x: 0,
                y: isPressed ? 4 : 8
            )
            .animation(.easeInOut(duration: 0.2), value: isPressed)
    }
}

struct LiquidGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                // Multi-layer glass effect
                ZStack {
                    // Base layer
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    // Gradient overlay
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.2),
                                    .clear,
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Noise texture simulation
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.05))
                        .blur(radius: 0.5)
                }
            }
            .overlay {
                // Premium border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.7),
                                .white.opacity(0.2),
                                .clear,
                                .white.opacity(0.4)
                            ],
                            startPoint: UnitPoint(x: 0, y: 0),
                            endPoint: UnitPoint(x: 1, y: 1)
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 15)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// View Extensions
extension View {
    func liquidGlass(
        tintColor: Color = .white,
        blur: CGFloat = 20,
        opacity: Double = 0.1,
        borderWidth: CGFloat = 1
    ) -> some View {
        modifier(LiquidGlassEffect(
            tintColor: tintColor,
            blur: blur,
            opacity: opacity,
            borderWidth: borderWidth
        ))
    }
    
    func liquidGlassButton(
        isPressed: Bool = false,
        tintColor: Color = .blue
    ) -> some View {
        modifier(LiquidGlassButton(
            isPressed: isPressed,
            tintColor: tintColor
        ))
    }
    
    func liquidGlassCard() -> some View {
        modifier(LiquidGlassCard())
    }
    
    @ViewBuilder
    func conditionalModifier<T: View>(
        _ condition: Bool,
        transform: (Self) -> T
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}