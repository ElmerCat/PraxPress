//
//  InspectorPanel.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/2/26.
//

import SwiftUI

class InspectorPanel<Content: View>: NSPanel {
 
    @Binding var isPresented: Bool
    
    init(view: () -> Content,
             contentRect: NSRect,
             backing: NSWindow.BackingStoreType = .buffered,
             defer flag: Bool = false,
             isPresented: Binding<Bool>) {
        /// Initialize the binding variable by assigning the whole value via an underscore
        self._isPresented = isPresented
     
        /// Init the window as usual
        super.init(contentRect: contentRect,
                   styleMask: [.docModalWindow, .hudWindow, .titled, .resizable, .closable], // .fullSizeContentView],
                    backing: backing,
                    defer: flag)
     
        /// Allow the panel to be on top of other windows
        isFloatingPanel = true
        level = .normal
       
        collectionBehavior = .participatesInCycle
     
        /// Allow the pannel to be overlaid in a fullscreen space
     //   collectionBehavior.insert(.fullScreenAuxiliary)
     
        /// Don't show a window title, even if it's set
        titleVisibility = .visible
        titlebarAppearsTransparent = true
     
        /// Since there is no title bar make the window moveable by dragging on the background
        isMovableByWindowBackground = true
        isMovable = true
     
        /// Hide when unfocused
        hidesOnDeactivate = false
     
        /// Hide all traffic light buttons
        standardWindowButton(.closeButton)?.isHidden = false
        standardWindowButton(.miniaturizeButton)?.isHidden = false
        standardWindowButton(.zoomButton)?.isHidden = false
     
        /// Sets animations accordingly
        animationBehavior = .utilityWindow
     
        /// Set the content view.
        /// The safe area is ignored because the title bar still interferes with the geometry
        contentView = NSHostingView(rootView: view()
            .ignoresSafeArea()
            .environment(\.inspectorPanel, self))
    }
    
    
    /// Close automatically when out of focus, e.g. outside click
    override func resignMain() {
        super.resignMain()
 //       close()
    }
     
    /// Close and toggle presentation, so that it matches the current state of the panel
    override func close() {
        super.close()
        isPresented = false
    }
     
    /// `canBecomeKey` and `canBecomeMain` are both required so that text inputs inside the panel can receive focus
    override var canBecomeKey: Bool {
        return true
    }
     
    override var canBecomeMain: Bool {
        return true
    }
    
    
    
}

private struct InspectorPanelKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}
 
extension EnvironmentValues {
  var inspectorPanel: NSPanel? {
    get { self[InspectorPanelKey.self] }
    set { self[InspectorPanelKey.self] = newValue }
  }
}



/// Add a  ``InspectorPanel`` to a view hierarchy
fileprivate struct InspectorPanelModifier<PanelContent: View>: ViewModifier {
    /// Determines wheter the panel should be presented or not
    @Binding var isPresented: Bool
 
    /// Determines the starting size of the panel
    var contentRect: CGRect = CGRect(x: 0, y: 0, width: 624, height: 512)
 
    /// Holds the panel content's view closure
    @ViewBuilder let view: () -> PanelContent
 
    /// Stores the panel instance with the same generic type as the view closure
    @State var panel: InspectorPanel<PanelContent>?
 
    func body(content: Content) -> some View {
        content
            .onAppear {
                /// When the view appears, create, center and present the panel if ordered
                panel = InspectorPanel(view: view, contentRect: contentRect, isPresented: $isPresented)
                panel?.center()
                if isPresented {
                    present()
                }
            }.onDisappear {
                /// When the view disappears, close and kill the panel
                panel?.close()
                panel = nil
            }
            .onChange(of: isPresented) {
                if isPresented {
                    present()
                } else {
                    panel?.close()
                }
            }
    }
 
    /// Present the panel and make it the key window
    func present() {
        panel?.orderFront(nil)
        panel?.makeKey()
    }
}


extension View {
    /** Present a ``InspectorPanel`` in SwiftUI fashion
     - Parameter isPresented: A boolean binding that keeps track of the panel's presentation state
     - Parameter contentRect: The initial content frame of the window
     - Parameter content: The displayed content
     **/
    func inspectorPanel<Content: View>(isPresented: Binding<Bool>,
                                      contentRect: CGRect = CGRect(x: 0, y: 0, width: 624, height: 512),
                                      @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(InspectorPanelModifier(isPresented: isPresented, contentRect: contentRect, view: content))
    }
}


/// Bridge AppKit's NSVisualEffectView into SwiftUI
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State
    var emphasized: Bool
 
    func makeNSView(context: Context) -> NSVisualEffectView {
        context.coordinator.visualEffectView
    }
 
    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        context.coordinator.update(
            material: material,
            blendingMode: blendingMode,
            state: state,
            emphasized: emphasized
        )
    }
 
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
 
    class Coordinator {
        let visualEffectView = NSVisualEffectView()
 
        init() {
            visualEffectView.blendingMode = .withinWindow
        }
 
        func update(material: NSVisualEffectView.Material,
                        blendingMode: NSVisualEffectView.BlendingMode,
                        state: NSVisualEffectView.State,
                        emphasized: Bool) {
            visualEffectView.material = material
        }
    }
  }
