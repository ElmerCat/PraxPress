//
//  PraxTheme.swift
//  Test-260226
//
//  Created by Elmer Cat on 2/26/26.
//

import PDFKit
import SwiftUI


extension EnvironmentValues {
    @Entry var selectedPageItem: PageItem?
    @Entry var groupHovering = false
    @Entry var viewSize = CGSize(.zero)
    @Entry var scaleFactor = CGFloat(1)
}


extension View {
    func groupHovering(_ groupHovering: Bool) -> some View {
        environment(\.groupHovering, groupHovering)
    }
}




enum ButtonState {
    case enabled
    case on
    case groupHovering
    case hovering
    case focused
    case groupHoveringOn
    case hoveringOn
    case focusedOn
    case groupHoveringFocusedOn
    case hoveringFocusedOn
    case disabled
}
enum ThemeStyle {
    case standard
    case delete
    case burn
    case special
}

struct ButtonThemeColors {
    let buttonState: ButtonState
    var theme: ThemeStyle = .standard
    var colors: [Color] { switch self.buttonState {
    case .enabled: [.cyan, .cyan, .cyan, .cyan]
    case .on: { switch theme {
        case .standard:  return [.green, .green, .green, .green]
        case .delete: return [.yellow, .yellow, .yellow, .yellow]
        case .burn: return [.orange, .orange, .orange, .orange]
        case .special: return [.mint, .mint, .mint, .mint] } }()
        
    case .hovering: [.blue, .blue, .blue, .blue]
    case .focused: [.mint, .mint, .mint, .mint]
    case .groupHovering: [.yellow, .yellow, .yellow, .yellow]
    case .focusedOn: [.orange, .orange, .orange, .orange]
    case .hoveringFocusedOn: [.pink, .pink, .pink, .pink]
    case .groupHoveringFocusedOn: [.pink, .pink, .pink, .pink]
    case .disabled: [.gray, .gray, .gray, .gray]
    case .groupHoveringOn: [.pink, .pink, .pink, .pink]
    case .hoveringOn: [.orange, .orange, .orange, .orange] }}
}

func PraxButtonState(theme: ThemeStyle = .standard, enabled: Bool = true, groupHovering: Bool = false, hovering: Bool = false, on: Bool = false, focused: Bool = false) -> ButtonState {
    var buttonState: ButtonState = .disabled
    if groupHovering && focused && on { buttonState = .groupHoveringFocusedOn }
    if hovering && focused && on { buttonState = .hoveringFocusedOn }
    if focused && on { buttonState = .focusedOn } else
    if groupHovering && on { buttonState = .groupHoveringOn } else
    if hovering && on { buttonState = .hoveringOn } else
    if focused { buttonState = .focused } else
    if groupHovering { buttonState = .hovering } else
    if hovering { buttonState = .hovering } else
    if on { buttonState = .on } else
    if enabled { buttonState = .enabled }
    return buttonState
}

struct PraxButton: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.groupHovering) private var groupHovering
    var action: () -> Void = {}
    var symbol: String = ""
    var symbol2: String = ""
    var label: String = ""
    var help: String = "Julie d'Prax"
    var isOn = false
    var theme: ThemeStyle = .standard
    var size: CGSize = CGSize(width: 30, height: 30)
 //   var notHoveringOpacity: Double = 0.1
 //   var notGroupHoveringOpacity: Double = 0.1
    
    @State private var hovering = false
    
    var body: some View {
        let buttonState = PraxButtonState(enabled: isEnabled, groupHovering: groupHovering, hovering: hovering, on: isOn)
        ZStack {
            RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                .fill(PraxButtonBackground(buttonState: buttonState))
            HStack {
                if !label.isEmpty {
                    Text(label)

                }
                Image(systemName: symbol ).resizable().frame(width: 20, height: 20)}

            }
        .frame(maxWidth: size.width, maxHeight: size.height, alignment: .center)
        //     .padding(2)
        //        .background(PraxButtonBackground(theme: theme, isHovering: hovering, isOn: isOn))
        //        .border(hovering ? .red : Color.cyan, width: hovering ? 2 : 1)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(hovering ? .red : Color.cyan, lineWidth: 2))
        .onTapGesture { action() }
        .onHover { hovering in self.hovering = hovering }
        .help(help)
  //      .opacity(groupHovering ? 1.0  : 0.0)
        
    }
}

func PraxButtonBackground(buttonState: ButtonState, theme: ThemeStyle = .standard)
-> MeshGradient {
    let colors = ButtonThemeColors(buttonState: buttonState, theme: theme).colors
    return MeshGradient(
        width: 2,
        height: 2,
        points: [[0.0, 0.0], [1.0, 0.0],[0.0, 1.0], [1.0, 1.0]],
        colors: colors)
}


struct PraxGroupBoxStyle: GroupBoxStyle {
    
    var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Check if there is a label to prevent empty space
                configuration.label
                    .font(.headline)
                    .foregroundStyle(.purple)
                
                Divider()
            
            // The main content of the GroupBox
            configuration.content
        }
        
        .border(Color.gray, width: isHovering ? 1 : 0)
        .background(PraxGradient(4))
        
        
    }
}

// 2. Create an extension for cleaner modifier syntax
extension GroupBoxStyle where Self == PraxGroupBoxStyle {
    static var prax: PraxGroupBoxStyle { PraxGroupBoxStyle() }
}




extension PDFDisplayMode {
    var color: Color { switch self {
        case .singlePage: return .pink
        case .singlePageContinuous: return .blue
        case .twoUp: return .orange
        case .twoUpContinuous: return .yellow
        default: return .black } }
    
    var icon: String { switch self {
        case .singlePage: return "inset.filled.center.rectangle.portrait"
        case .singlePageContinuous: return "inset.filled.center.rectangle.portrait"
        case .twoUp: return "inset.filled.center.rectangle.portrait"
        case .twoUpContinuous: return "inset.filled.center.rectangle.portrait"
        default: return "inset.filled.center.rectangle.portrait" } }
    
    var title: String { switch self {
        case .singlePage: return "Single"
        case .singlePageContinuous: return "Continuous"
        case .twoUp: return "Two Up"
        case .twoUpContinuous: return "Two Up Cont."
        default: return "Unknown"  } }
}



struct PraxTheme {
    
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



struct PageItemButtonStyle: ButtonStyle {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.groupHovering) private var groupHovering
    var isHovering = false
    var isOn = false
    
    func buttonForegroundColor() -> Color {
        if isHovering {
            if isOn { return Color.yellow }
            return Color.white
        }
        if isOn { return Color.red }
        return Color.blue
    }
    
    func buttonBackgroundColor(role: ButtonRole?) -> Color {

        if groupHovering { return Color.orange } 
        
        if isHovering {
            switch role {
            case .destructive: return Color.red
                
            default:
                if isOn { return Color.green }
                return Color.blue
            }
        }
        if isOn { return Color.green }
        return Color.blue.opacity(0.5)
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .buttonStyle(.glassProminent)
            .imageScale(.large)
         //   .font(.system(size: 20, weight: .medium))
         //   .font(.system(size: prax.mergedPagesSize.width * 0.10))
        //    .frame(width: prax.mergedPagesSize.width * 0.25, height: prax.mergedPagesSize.width * 0.25)
            .frame(width: 30, height: 30)
            .foregroundColor(buttonForegroundColor())
            .background(buttonBackgroundColor(role: configuration.role), in: RoundedRectangle(cornerRadius: 8))
    }
}


struct PraxButtonStyle: ButtonStyle {
    @Environment(PraxModel.self) private var prax
    @Environment(\.isEnabled) private var isEnabled
    var isHovering = false
    var isOn = false
    var isFocused = false
    var width = 30.0
    var height = 30.0
    var hoverWidth: CGFloat?
    var hoverHeight: CGFloat?

    func frameHeight(isHovering: Bool) -> CGFloat {
        if isHovering, let height = hoverHeight { return height }
        return height
    }
    func frameWidth(isHovering: Bool) -> CGFloat {
        if isHovering, let width = hoverWidth { return width }
        return width
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
       
        return configuration.label
            .buttonStyle(.glassProminent)
            .imageScale(.large)
            .frame(width: frameWidth(isHovering: isHovering), height: frameHeight(isHovering: isHovering), alignment: .center)
          //  .zIndex(23)
            .padding(.horizontal, 8)
          //  .buttonBorderShape(.roundedRectangle(radius: 8) )
          //  .border(Color.black, width: 3)
            .foregroundColor(buttonForegroundColor(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused))
        
            .background(ButtonBackground(configuration: configuration, isEnabled: isEnabled, isHovering: isHovering, isOn: isOn, isFocused: isFocused), in: RoundedRectangle(cornerRadius: 5))
            
            .animation(.easeInOut(duration: 0.3), value: isHovering)
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






func PraxGradient(_ style: Int? = nil, opacity: CGFloat = 1) -> MeshGradient {
    
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


#Preview {
    
    PraxGradient(0)
    PraxGradient(1)
}
