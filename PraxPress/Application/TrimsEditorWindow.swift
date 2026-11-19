//
//  TrimsEditorWindowView.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/22/26.
//

import SwiftUI
import PDFKit


struct TrimsEditorWindow: View {
    @Environment(PraxModel.self) private var prax
    //   @Environment(\.groupHovering) private var groupHovering
    @Environment(\.dismissWindow) private var dismissWindow
    //   @Environment(\.isPresented) private var isPresented { didSet { prax.showTrimsEditor = isPresented }}
    @State private var hovering: Bool = false

    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.selectedPageItem, let mergedPage = pageItem.mergedPage, let mergedPageIndex = prax.document.indexOfSection(mergedPage) {
            @Bindable var pageItem = pageItem
            VStack {
               
                Button { prax.document.clickedGuidePageButton(pageItem) }
                label: { Image(systemName: pageItem.skipped ? "ruler.fill" : "ruler") }
                
                    .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 435, isOn: prax.document.widthGuidePageID != nil))
                    .onHover { hovering in prax.hoveredButton = hovering ? 435 : nil }
                    .help("Set Width Guide")
                
                
                Grid {
                    
                    GridRow {
                        Text("Left")
                        Stepper("\(Int(pageItem.trims.left))", onIncrement:{if pageItem.trims.left < pageItem.bounds.width {pageItem.trims.left += 1}} , onDecrement: {if pageItem.trims.left > 0 {pageItem.trims.left -= 1}})
                        
                        //              Divider()
                        Button {  }
                        label: { Image(systemName: "chevron.backward")}
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: prax.guideLeft == nil, width: nil, height: nil))
                            .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                        Text("\(Int(prax.guideLeft ?? 0))")
                        Button { if prax.guideLeft != nil {prax.guideLeft = nil} else {prax.guideLeft = pageItem.trims.left}  }
                        label: { Image(systemName: "pin.square")}
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: prax.guideLeft == nil, width: nil, height: nil))
                            .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                            .disabled(pageItem.trims.left < 1 && prax.guideLeft == nil)
                    }
                    GridRow {
                        Text("Right")
                        Stepper("\(Int(pageItem.trims.right))", onIncrement: {if pageItem.trims.right > 0 {pageItem.trims.right -= 1}}, onDecrement: {if pageItem.trims.right < pageItem.bounds.width {pageItem.trims.right += 1}})
                        
                        //             Divider()
                        Button {  }
                        label: { Image(systemName: "chevron.backward")}
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: prax.guideRight == nil, width: nil, height: nil))
                            .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                        Text("\(Int(prax.guideRight ?? 0))")
                        Button { if prax.guideRight != nil {prax.guideRight = nil} else {prax.guideRight = pageItem.trims.right}  }
                        label: { Image(systemName: "pin.square")}
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: prax.guideRight == nil, width: nil, height: nil))
                            .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                            .disabled(pageItem.trims.right < 1 && prax.guideRight == nil)
                        
                    }
                    
                    Divider()
                    
                    GridRow {
                        
                        Text("Top")
                        Stepper("\(Int(pageItem.trims.top))", onIncrement: {if pageItem.trims.top > 0 {pageItem.trims.top -= 1}}, onDecrement: {if pageItem.trims.top < pageItem.bounds.height {pageItem.trims.top += 1}})
                        
                        //     Divider()
                        
                        Button { if pageItem.trims.top != 0 && prax.guideTop != pageItem.trims.top {prax.guideTop = pageItem.trims.top} else {prax.guideTop = nil} }
                        label: { Image(systemName: prax.guideTop != pageItem.trims.top ? "pin" : "pin.slash")}
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: prax.guideTop == nil, width: nil, height: nil))
                            .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                            .disabled(pageItem.trims.top < 1 && prax.guideTop == nil)
                        
                        Text(prax.guideTop.map { "\(Int($0))" } ?? " ")
                        
                        Button { pageItem.trims.top = prax.guideTop! }
                        label: { Image(systemName: "arrowshape.backward")}
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: prax.guideTop == nil)) //, width: nil, height: nil))
                            .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                            .disabled(prax.guideTop == nil || prax.guideTop == pageItem.trims.top)
                    }
                    
                    GridRow {
                        Text("Bottom")
                        Stepper("\(Int(pageItem.trims.bottom))", onIncrement: {if pageItem.trims.bottom < pageItem.bounds.height {pageItem.trims.bottom += 1}}, onDecrement: {if pageItem.trims.bottom > 0 {pageItem.trims.bottom -= 1}})
                        
                        //               Divider()
                        Button {  }
                        label: { Image(systemName: "chevron.backward")}
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: prax.guideBottom == nil, width: nil, height: nil))
                            .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                        Text("\(Int(prax.guideBottom ?? 0))")
                        Button { if prax.guideBottom != nil {prax.guideBottom = nil} else {prax.guideBottom = pageItem.trims.bottom}  }
                        label: { Image(systemName: "pin.square")}
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: prax.guideBottom == nil, width: nil, height: nil))
                            .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                            .disabled(pageItem.trims.bottom < 1 && prax.guideBottom == nil)
                        
                    }
                   
                    Divider()
                    Spacer()
                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Page \((pageItem.editPageIndex) + 1) of \(prax.editingPageItems.count)").font(.subheadline).foregroundStyle(.buttonDefaultBackground)
                            Text("\(Int(pageItem.bounds.width)) × \(Int(pageItem.bounds.height))")
                            Text(String(format: "%.2f × %.2f in", pageItem.bounds.size.inches.width, pageItem.bounds.size.inches.height))
                            Divider()
                            Text("Merged Page \(mergedPageIndex + 1) of \(prax.document.mergedPages.count)").font(.subheadline).foregroundStyle(.buttonDefaultBackground)
                            Text("\(Int(pageItem.mergedPage!.bounds.width)) × \(Int(pageItem.mergedPage!.bounds.height))")
 //                           Text(String(format: "%.2f × %.2f in", pageItem.mergedPage!.bounds.size.inches.width, pageItem.bounds.size.inches.height))
                            
                            
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Trimmed page size").font(.subheadline).foregroundStyle(.buttonDefaultBackground)
                            Text("\(Int(pageItem.bounds.trimmed(pageItem.trims).width)) × \(Int(pageItem.bounds.trimmed(pageItem.trims).height))")
                            Text(String(format: "%.2f × %.2f in", pageItem.bounds.trimmed(pageItem.trims).size.inches.width, pageItem.bounds.trimmed(pageItem.trims).size.inches.height))
                            Divider()
                            Text("")
//                            Text("\(Int(pageItem.mergedPage!.bounds.width)) × \(Int(pageItem.mergedPage!.bounds.height))")
                            Text(String(format: "%.2f × %.2f in", pageItem.mergedPage!.bounds.size.inches.width, pageItem.bounds.size.inches.height))
                            
                            
                            
                        //    Text(String(format: "%.2f × %.2f in", pageItem.mergedPage!.bounds.size.inches.width, pageItem.bounds.size.inches.height))
                         //   Text(String(format: "%.2f × %.2f in", pageItem.mergedPage!.bounds.trimmed(pageItem.trims).size.inches.width, pageItem.bounds.trimmed(pageItem.trims).size.inches.height))
                        }
                    }
                    
                   /*
                    HStack {
                        Text("Page \((pageItem.editPageIndex) + 1) of \(prax.editingPageItems.count)").font(.subheadline).foregroundStyle(.buttonDefaultBackground)
                        Spacer()
                        Text("Merged Page \((prax.document.indexOfSection(pageItem.mergedPage!)! + 1)) of \(prax.document.mergedPages.count)").font(.subheadline).foregroundStyle(.buttonDefaultBackground)
                        
                    }
                   
                    HStack {
                        Text(String(format: "%.2f × %.2f in", pageItem.bounds.size.inches.width, pageItem.bounds.size.inches.height))
                        Spacer()
                        Text(String(format: "%.2f × %.2f in", pageItem.bounds.trimmed(pageItem.trims).size.inches.width, pageItem.bounds.trimmed(pageItem.trims).size.inches.height))
                        //        Text(inchesText(pageItem.bounds.size.inches))
                        //        Text(pageSizeText(pageItem.mergedPage?.pdfPage?.bounds(for: .cropBox) ?? .zero))
                    }*/


                }.padding(5)
                
                
                
               
                

                
            }
            
            //            .opacity(prax.editorHovering ? 1.0 : 0.0)
            
            .overlay(Rectangle().fill(Color.blue).frame(height: 2),alignment: .top)
            
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.cyan, lineWidth: 2))
            .frame(width: 300, height: 500)
            .padding(10)
            .animation(.easeIn(duration: 0.2), value: hovering)
            .onHover { isHovering in hovering = isHovering }
            .environment(\.groupHovering, hovering)
            .background(pageItem.editPageIndex.isMultiple(of: 2) ? PraxGradient(41) : PraxGradient(1), in: RoundedRectangle(cornerRadius: 5))
           
            .onKeyPress(phases: .down) { keyPress in  switch keyPress.key {
            case .escape: dismissWindow(id: "trims-editor") //prax.showPreview.toggle()
                return .handled
                default: print(keyPress.key); return .ignored } }
            
            
            .onGeometryChange(for: CGRect.self) {  viewGeometry in return viewGeometry.frame(in: .named("MainWindow")) }
            action: { _, newValue in prax.utilityWindowFrame = newValue }
            
                .toolbar(content: {
                    
                    ToolbarItemGroup(placement: .status) {
                        
                        Button("🧪 Open Log") {
                            PraxLogger.shared.openLogFile()
                        }
                        
                        Button("🧪 Test Error") {
                            prax.praxTest()
                        }
                        
                        //       ReusableSegmentedControl(selection: $prax.praxPressMode, colorProvider: { $0.color })
                        
                        
                        
                    }
                })
                .toolbarBackground(PraxGradient(), for: .windowToolbar)

        }

    }
}


