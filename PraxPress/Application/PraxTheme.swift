//
//  PraxTheme.swift
//  Test-260226
//
//  Created by Elmer Cat on 2/26/26.
//

import PDFKit

extension PDFDisplayMode {
    var color: Color {
        switch self {
            
        case .singlePage: return .pink
        case .singlePageContinuous: return .blue
        case .twoUp: return .orange
        case .twoUpContinuous: return .yellow
        default: return .black
        }
    }
    
    var icon: String {
        switch self {
        case .singlePage: return "inset.filled.center.rectangle.portrait"
        case .singlePageContinuous: return "inset.filled.center.rectangle.portrait"
        case .twoUp: return "inset.filled.center.rectangle.portrait"
        case .twoUpContinuous: return "inset.filled.center.rectangle.portrait"
        default: return "inset.filled.center.rectangle.portrait"
         }
    }
    
}



struct PraxTheme {
    enum PraxThemeVariant {
        case julie
        case erika
    }
    
    var foregroundColor: Color
    var backgroundColor: Color
    var foregroundColorDisabled: Color
    var backgroundColorDisabled: Color
    var foregroundColorHover: Color
    var backgroundColorHover: Color
    var foregroundColorPressed: Color
    var backgroundColorPressed: Color
    var foregroundColorSelected: Color
    var backgroundColorSelected: Color
    
    var themeVariant: PraxThemeVariant

    init(_ themeVariant: PraxThemeVariant) {
            self.themeVariant = themeVariant
            switch themeVariant {
            case .erika:
                self.foregroundColor = Color.praxButtonForeground
                self.backgroundColor = Color.praxButtonBackground
                self.foregroundColorDisabled = Color.praxButtonForeground.opacity(0.5)
                self.backgroundColorDisabled = Color.praxButtonBackground.opacity(0.5)
                self.foregroundColorHover = Color.praxButtonForegroundHover
                self.backgroundColorHover = Color.praxButtonBackgroundHover
                self.foregroundColorPressed = Color.praxButtonForegroundPressed
                self.backgroundColorPressed = Color.praxButtonBackgroundPressed
                self.foregroundColorSelected = Color.praxButtonForegroundSelected
                self.backgroundColorSelected = Color.praxButtonBackgroundSelected
                
            case .julie:
                self.foregroundColor = Color.praxDeleteForeground
                self.backgroundColor = Color.praxDeleteBackground
                self.foregroundColorDisabled = Color.praxDeleteForeground.opacity(0.5)
                self.backgroundColorDisabled = Color.praxDeleteBackground.opacity(0.5)
                self.foregroundColorHover = Color.praxDeleteForegroundHover
                self.backgroundColorHover = Color.praxDeleteBackgroundHover
                self.foregroundColorPressed = Color.praxButtonForegroundPressed
                self.backgroundColorPressed = Color.praxButtonBackgroundPressed
                self.foregroundColorSelected = Color.praxButtonForegroundSelected
                self.backgroundColorSelected = Color.praxButtonBackgroundSelected

                
            }
    }
    
}


struct PrefixButtonStyle: ButtonStyle {
    var theme: PraxTheme
    var isHovering = false
    var isDisabled = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        let backgroundColor: Color
        let foregroundColor: Color
        
        if configuration.isPressed {
            backgroundColor = theme.backgroundColorPressed
            foregroundColor = theme.foregroundColorPressed
        } else if isDisabled {
            backgroundColor = theme.backgroundColorDisabled
            foregroundColor = theme.foregroundColorDisabled }
        else if isHovering {
                backgroundColor = theme.backgroundColorHover
                foregroundColor = theme.foregroundColorHover
        } else {
            backgroundColor = theme.backgroundColor
            foregroundColor = theme.foregroundColor
        }
        
        return configuration.label
            .buttonStyle(.glassProminent)
 //           .imageScale(.large)
 //           .frame(width: 20, height: 25, alignment: .center )
            .padding(3)
            .padding(.trailing, 0)
            .foregroundColor(foregroundColor)
            .background {
                RoundedRectangle(cornerSize: CGSize(width: 5, height: 8))
                    .foregroundStyle(backgroundColor)
            }
         //   .cornerRadius(8)
            .animation(.bouncy(duration: 0.5), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed )    }
}



struct ItemButtonStyle: ButtonStyle {
    var theme: PraxTheme
    var isHovering: Bool
    
    func makeBody(configuration: Self.Configuration) -> some View {
        let backgroundColor: Color
        let foregroundColor: Color
        
        if configuration.isPressed {
            backgroundColor = theme.backgroundColorPressed
            foregroundColor = theme.foregroundColorPressed
        } else if isHovering {
            backgroundColor = theme.backgroundColorHover
            foregroundColor = theme.foregroundColorHover
        } else {
            backgroundColor = theme.backgroundColor
            foregroundColor = theme.foregroundColor
        }
        
        return configuration.label
            .buttonStyle(.glassProminent)
            .imageScale(.large)
            .frame(width: 20, height: 25, alignment: .center )
            .padding(.horizontal, 4)
            .foregroundColor(foregroundColor)
            .background {
                Rectangle()
                    .foregroundStyle(backgroundColor)
            }
            .cornerRadius(8)
            .animation(.bouncy(duration: 0.5), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed )    }
}


struct SelectableButtonStyle: ButtonStyle {
    var theme: PraxTheme
    var isSelected: Bool
    var isHovering: Bool
    var isFocused: Bool
    
    func makeBody(configuration: Self.Configuration) -> some View {
        let backgroundColor: Color
        let foregroundColor: Color
        
        if configuration.isPressed {
            backgroundColor = theme.backgroundColorPressed
            foregroundColor = theme.foregroundColorPressed
        } else if isHovering {
            backgroundColor = theme.backgroundColorHover
            foregroundColor = theme.foregroundColorHover
        } else if isSelected {
            backgroundColor = theme.backgroundColorSelected
            foregroundColor = theme.foregroundColorSelected
        } else {
            backgroundColor = theme.backgroundColor
            foregroundColor = theme.foregroundColor
        }
        
        return configuration.label
            .buttonStyle(.glass)
            .imageScale(.large)
            .frame(width: 20, height: 20, alignment: .center )
            .padding(.leading, 8)
            .foregroundColor(foregroundColor)
            .background {
                Rectangle()
                    .foregroundStyle(backgroundColor)
            }
            .cornerRadius(8)
            .animation(.bouncy(duration: 0.2), value: isHovering)
            .animation(.bouncy(duration: 0.5), value: isSelected)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed )    }
}

import SwiftUI

func PraxGradient(_ style: Int? = nil) -> MeshGradient {
    
    switch style {
    case 0:
        MeshGradient(
            width: 2,
            height: 2,
            points: [
                [0.0, 0.0], [1.0, 0.0],
                [0.0, 1.0], [1.0, 1.0]
                
            ],
            colors: [
                .black,.blue.opacity(0.5),
                .blue.opacity(0.5), .black
            ])
    case 1:
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .clear,.blue,.clear,
                .blue, .clear, .blue,
                .clear, .green, .clear
            ]
        )
    
    case 3:
        MeshGradient(
            width: 2,
            height: 2,
            points: [
                [0.0, 0.0], [1.0, 0.0],
                [0.0, 1.0], [1.0, 1.0]
                
            ],
            colors: [
                Color("GradientDarkOne").opacity(0.75), Color("GradientLightOne").opacity(0.75),
                Color("GradientLightOne").opacity(0.5), Color("GradientDarkOne").opacity(0.5)
            ])
        
    case 4:
        MeshGradient(
            width: 2,
            height: 2,
            points: [
                [0.0, 0.0], [1.0, 0.0],
                [0.0, 1.0], [1.0, 1.0]
                
            ],
            colors: [
                Color("GradientDarkTwo").opacity(0.15), Color("GradientLightTwo").opacity(0.25),
                Color("GradientLightTwo").opacity(0.25), Color("GradientDarkTwo").opacity(0.15)
            ])
        
    default:
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .white,.black,.white,
                .blue, .blue, .blue,
                .white, .green, .white
            ])
    }
    

}

struct PraxThemeView: View {
    
    enum PraxFocus: Hashable {
        case firstButton
        case secondButton
        case textField
        // add more if needed
    }
    
    @FocusState private var focusedField: PraxFocus?
    @State var prax = false
    @State var praxText = "Prax Text"
    @State private var hoveredButton: Int? = nil
    let praxTheme = PraxTheme(.erika)
    
    var body: some View {
       
        HStack {
            Button("", systemImage: prax ?  "circle.inset.filled" : "inset.filled.center.rectangle.portrait", action: { prax = true })
                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: prax, isHovering: hoveredButton == 1, isFocused: focusedField == .firstButton))
                .onHover { hovering in
                    hoveredButton = hovering ? 1 : nil
                }
              //  .focusable(true)
              //  .focused($focusedField, equals: .firstButton)
              //  .keyboardShortcut(.space, modifiers: [])
            
              
            Button("", systemImage: !prax ?  "rectangle.portrait.inset.filled" : "inset.filled.center.rectangle.portrait", action: { prax = false })
                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: !prax, isHovering: hoveredButton == 2, isFocused: focusedField == .secondButton))
                .onHover { hovering in
                    hoveredButton = hovering ? 2 : nil
                }
             //   .focusable(true)
             //   .focused($focusedField, equals: .secondButton)
             //   .keyboardShortcut(.space, modifiers: [])
            
            TextField("Prax", text: $praxText)
                .frame(width: 150)
                .focused($focusedField, equals: .textField)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .secondButton
                }
                .keyboardShortcut(.space, modifiers: [])
            
            Text(praxText)
        }
        .frame(width: 400)
        .padding()
    }
}

#Preview {
    
    PraxThemeView()
}

#Preview {
    PraxThemeView()
    PraxGradient(0)
    PraxGradient(1)
}
