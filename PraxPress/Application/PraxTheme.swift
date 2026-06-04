//
//  PraxTheme.swift
//  Test-260226
//
//  Created by Elmer Cat on 2/26/26.
//

import PDFKit
import SwiftUI

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
/*    enum PraxThemeVariant {
        case julie
        case erika
    }
*/
    
    let fontFeature = Font.custom("BrushScriptMT", size: 20)
    
    let buttonDisabledForeground = Color.buttonDisabledForeground
    let buttonDisabledBackground = Color.buttonDisabledBackground
    
    let buttonDefaultForeground = Color.buttonDefaultForeground
    let buttonDefaultBackground = Color.buttonDefaultBackground
    let buttonDefaultForegroundHover = Color.buttonDefaultForegroundHover
    let buttonDefaultBackgroundHover = Color.buttonDefaultBackgroundHover
    let buttonDefaultForegroundPressed = Color.buttonDefaultForegroundPressed
    let buttonDefaultBackgroundPressed = Color.buttonDefaultBackgroundPressed
    
    let buttonDestructiveForeground = Color.buttonDestructiveForeground
    let buttonDestructiveBackground = Color.buttonDestructiveBackground
    let buttonDestructiveForegroundHover = Color.buttonDestructiveForegroundHover
    let buttonDestructiveBackgroundHover = Color.buttonDestructiveBackgroundHover
    let buttonDestructiveForegroundPressed = Color.buttonDestructiveForegroundPressed
    let buttonDestructiveBackgroundPressed = Color.buttonDestructiveBackgroundPressed
    
/*    var foregroundColor: Color
    var backgroundColor: Color
    var foregroundColorDisabled: Color
    var backgroundColorDisabled: Color
    var foregroundColorHover: Color
    var backgroundColorHover: Color
    var foregroundColorPressed: Color
    var backgroundColorPressed: Color
    var foregroundColorSelected: Color
    var backgroundColorSelected: Color
*/
    

    
  //  var themeVariant: PraxThemeVariant

 /*   init(_ themeVariant: PraxThemeVariant) {
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
*/
}


func buttonForegroundColor(configuration: ButtonStyle.Configuration, isEnabled: Bool = true, isHovering: Bool = false, isOn: Bool = false, isFocused: Bool = false) -> Color {
    if !isEnabled { return Color.buttonDisabledForeground } else
    if configuration.isPressed { switch configuration.role {
    case .destructive: return Color.buttonDestructiveForegroundPressed
        default:  return Color.buttonDefaultForegroundPressed } } else
    if isHovering {  switch configuration.role {
    case .destructive: return Color.buttonDestructiveForegroundHover
        default:  return Color.buttonDefaultForegroundHover} }
    else { switch configuration.role {
    case .destructive: return Color.buttonDestructiveForeground
        default:  return Color.buttonDefaultForeground} }
}



struct PrefixButtonStyle: ButtonStyle {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    var isHovering = false
    var isOn = false
    var isFocused = false

    func makeBody(configuration: Self.Configuration) -> some View {
        
        return configuration.label
            .buttonStyle(.glassProminent)
            .padding(3)
            .padding(.trailing, 0)
            .foregroundColor(buttonForegroundColor(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
            .background(ButtonBackground(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
            .cornerRadius(8)
            .animation(.bouncy(duration: 0.5), value: isHovering)
            .animation(.bouncy(duration: 0.5), value: isOn)
            .animation(.bouncy(duration: 0.5), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed )    }
}


struct PraxButtonStyle: ButtonStyle {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    var isHovering = false
    var isOn = false
    var isFocused = false
    var width = 35.0
    var height = 25.0
    var hoverWidth = 35.0
    var hoverHeight = 30.0

    
    
    func makeBody(configuration: Self.Configuration) -> some View {
       
        return configuration.label
            .buttonStyle(.glassProminent)
            .imageScale(.large)
            .frame(width: isHovering && isEnabled ? hoverWidth: width, height:  isHovering && isEnabled ? hoverHeight: height, alignment: .center )
            .zIndex(23)
            .padding(.horizontal, 4)
          //  .buttonBorderShape(.roundedRectangle(radius: 8) )
          //  .border(Color.black, width: 3)
            .foregroundColor(buttonForegroundColor(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
        
            .background(ButtonBackground(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused), in: RoundedRectangle(cornerRadius: 8))
            .animation(.bouncy(duration: 0.5), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed )    }
}



struct DragButtonStyle: ButtonStyle {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    var isHovering = false
    var isOn = false
    var isFocused = false

    

    func makeBody(configuration: Self.Configuration) -> some View {
        
        let frameWidth = isHovering && isEnabled ? 300.0 : 30.0
        let frameHeight = isHovering && isEnabled ? 50.0 : 25.0

        return configuration.label
            .buttonStyle(.glassProminent)
            .imageScale(.large)
            .frame(width: frameWidth, height: frameHeight, alignment: .center )
            .padding(.horizontal, 4)
            .foregroundColor(buttonForegroundColor(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
            .background(ButtonBackground(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))

            .cornerRadius(8)
            .animation(.bouncy(duration: 0.5), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed )    }
}


struct ItemButtonStyle: ButtonStyle {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    var isHovering = false
    var isOn = false
    var isFocused = false

    

    func makeBody(configuration: Self.Configuration) -> some View {
         
        return configuration.label
            .buttonStyle(.glassProminent)
            .imageScale(.large)
            .frame(width: 20, height: 25, alignment: .center )
            .padding(.horizontal, 4)
            .foregroundColor(buttonForegroundColor(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
            .background(ButtonBackground(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))

            .cornerRadius(8)
            .animation(.bouncy(duration: 0.5), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed )    }
}

struct aStackedButtonStyle: ButtonStyle {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    var isHovering = false
    var isOn = false
    var isFocused = false

    func makeBody(configuration: Self.Configuration) -> some View {
        

        
        return configuration.label
            .buttonStyle(.glass)
            .imageScale( .medium)
          //  .frame(width: 15, height: 15, alignment: .center )
           // .padding(.leading, 8)
            .foregroundColor(buttonForegroundColor(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
            .background(ButtonBackground(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
        //            .cornerRadius(8)
            .animation(.bouncy(duration: 0.2), value: isHovering)
          //  .animation(.bouncy(duration: 0.5), value: isSelected)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed )    }
}

struct aSwitchButtonStyle: ButtonStyle {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    var isHovering = false
    var isOn = false
    var isFocused = false


    func makeBody(configuration: Self.Configuration) -> some View {
        
       
        
        return configuration.label
            .buttonStyle(.glass)
            .imageScale(.large)
           // .frame(width: 20, height: 20, alignment: .center )
            .padding(.leading, 8)
            .foregroundColor(buttonForegroundColor(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
            .background(ButtonBackground(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
            .cornerRadius(8)
            .animation(.bouncy(duration: 0.2), value: isHovering)
            .animation(.bouncy(duration: 0.5), value: isOn)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed )    }
}


struct aSelectableButtonStyle: ButtonStyle {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    var isHovering = false
    var isOn = false
    var isFocused = false

    func makeBody(configuration: Self.Configuration) -> some View {
        

        return configuration.label
            .buttonStyle(.glass)
            .imageScale(.large)
            .frame(width: 20, height: 20, alignment: .center )
            .padding(.leading, 8)
            .foregroundColor(buttonForegroundColor(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
            .background(ButtonBackground(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
            .cornerRadius(8)
            .animation(.bouncy(duration: 0.2), value: isHovering)
            .animation(.bouncy(duration: 0.5), value: isOn)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed )    }
}

import SwiftUI

func ButtonBackground(configuration: ButtonStyle.Configuration, isEnabled: Bool = true, isHovering: Bool = false, isOn: Bool = false, isFocused: Bool = false) -> MeshGradient {
    let colors: [Color]
    if !isEnabled { colors = [.gray, .gray, .gray, .gray] } else
    
    if configuration.isPressed { switch configuration.role {
    case .destructive: colors = [.buttonDestructiveBackgroundPressed.opacity(0.9), .buttonDestructiveBackgroundPressed.opacity(0.5), .buttonDestructiveBackgroundPressed.opacity(0.9), .buttonDestructiveBackgroundPressed.opacity(0.5)]
        default:  colors = [.buttonDefaultBackgroundPressed.opacity(0.9), .buttonDefaultBackgroundPressed.opacity(0.3), .buttonDefaultBackgroundPressed.opacity(0.3), .buttonDefaultBackgroundPressed.opacity(0.9)] } } else
    
    if isHovering { switch configuration.role {
    case .destructive: colors = [.buttonDestructiveBackgroundHover.opacity(0.9), .buttonDestructiveBackgroundHover.opacity(0.3), .buttonDestructiveBackgroundHover.opacity(0.3), .buttonDestructiveBackgroundHover.opacity(0.9)]
        default:  colors = [.buttonDefaultBackgroundHover.opacity(0.9), .buttonDefaultBackgroundHover.opacity(0.3), .buttonDefaultBackgroundHover.opacity(0.3), .buttonDefaultBackgroundHover.opacity(0.9)] } } else
    
    if isOn { switch configuration.role {
    case .destructive: colors = [.buttonDestructiveBackgroundHover.opacity(0.9), .buttonDestructiveBackgroundHover.opacity(0.3), .buttonDestructiveBackgroundHover.opacity(0.3), .buttonDestructiveBackgroundHover.opacity(0.9)]
        default:  colors = [.buttonDefaultBackgroundHover.opacity(0.9), .buttonDestructiveBackgroundHover.opacity(0.3), .buttonDestructiveBackgroundHover.opacity(0.3), .buttonDefaultBackgroundHover.opacity(0.9)] } }
    
    else { switch configuration.role {
    case .destructive: colors = [.buttonDestructiveBackground.opacity(0.9), .buttonDestructiveBackground.opacity(0.3), .buttonDestructiveBackground.opacity(0.3), .buttonDestructiveBackground.opacity(0.9)]
        default:  colors = [.buttonDefaultBackground.opacity(0.9), .buttonDefaultBackground.opacity(0.3), .buttonDefaultBackground.opacity(0.3), .buttonDefaultBackground.opacity(0.9)] } }
    
    return MeshGradient(
        width: 2,
        height: 2,
        points: [
            [0.0, 0.0], [1.0, 0.0],
            [0.0, 1.0], [1.0, 1.0]
            
        ],
        colors: colors
        )
}
    




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
    
    @FocusState private var focusedField: Int?
    @State var prax = false
    @State var praxText = "Prax Text"
    @State private var hoveredButton: Int? = nil
   
    
    var body: some View {
       
        HStack {
            Button("", systemImage: prax ?  "circle.inset.filled" : "inset.filled.center.rectangle.portrait", action: { prax = true })
                .buttonStyle(PraxButtonStyle(isHovering: hoveredButton == 1, isOn: prax, isFocused: focusedField == 1))
                .onHover { hovering in
                    hoveredButton = hovering ? 1 : nil
                }
               .focusable(true)
                .focused($focusedField, equals: 1)
                .keyboardShortcut(.space, modifiers: [])
            
              
            Button("", systemImage: !prax ?  "rectangle.portrait.inset.filled" : "inset.filled.center.rectangle.portrait", action: { prax = false })
                .buttonStyle(PraxButtonStyle(isHovering: hoveredButton == 2, isOn: !prax, isFocused: focusedField == 2))
                .onHover { hovering in
                    hoveredButton = hovering ? 2 : nil
                }
                .focusable(true)
                .focused($focusedField, equals: 2)
                .keyboardShortcut(.space, modifiers: [])
            
            TextField("Prax", text: $praxText)
                .frame(width: 150)
                .focused($focusedField, equals: 3)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = 2
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
