//
//  EditingToolbarView.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/6/26.
//

import SwiftUI
import PDFKit
import TipKit



struct ExportFilenamePopover: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    
    @State private var showPrefixPopover: Bool = false
    @State private var showSuffixPopover: Bool = false
    @FocusState private var focusedField: FieldName?
    
    
    var body: some View {
        
        Grid {
            GridRow {
                Text("Prefix")
                Text("Filename")
                Text("Suffix")

            }
            GridRow {
                Button { showPrefixPopover.toggle() }
                label: {
                    if prax.document.exportFilenamePrefix.isEmpty {
                        Text("prefix").font(.caption).italic().padding(5).foregroundStyle(.buttonDefaultForeground)
                    }
                    else {
                        Text("\(prax.document.exportFilenamePrefix)").padding(.horizontal, 5)
                    }
                }
                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 427, isOn: !prax.document.exportFilenamePrefix.isEmpty))
            
                //, width: 200, height: 30))
                .onHover { hovering in prax.hoveredButton = hovering ? 427 : nil }
                .popover(isPresented: $showPrefixPopover, arrowEdge: .bottom, content: {
                    FilenamePrefixPopover()
                    
                })
                
                TextField("Filename", text: Binding<String>(
                    get: { prax.document.exportFilenameBody },
                    set: { newValue in
                        prax.document.exportFilenameBody = newValue.filter{!Prax.filechars.contains($0)}}))
                .frame(maxWidth: 300)
                .focused($focusedField, equals: .exportFilenameBody)
                
            //    Text(prax.document.exportFilenameSuffix)
                
                
                Button { showSuffixPopover.toggle() }
                label: {
                    if prax.document.exportFilenameSuffix.isEmpty {
                        Text("suffix").font(.caption).italic().padding(5).foregroundStyle(.buttonDefaultForeground)
                    }
                    else {
                        Text("\(prax.document.exportFilenameSuffix)").padding(.horizontal, 5)
                    }
                }
                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 487, isOn: !prax.document.exportFilenameSuffix.isEmpty)) //, width: nil, height: nil))
                .onHover { hovering in prax.hoveredButton = hovering ? 487 : nil }
                .popover(isPresented: $showSuffixPopover, arrowEdge: .top, content: {
                    FilenameSuffixPopover()
                })
                
                
                
                
            }
            
        }
        .padding(10)
        .frame(maxWidth: .infinity)
       
    }
}

struct EditingToolbarView: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.groupHovering) private var groupHovering
    @FocusState private var focusedField: FieldName?
    @State private var hovering: Bool = false
    @State private var showPrefixPopover: Bool = false
    @State private var showSuffixPopover: Bool = false
    
    var body: some View {
        @Bindable var prax = prax
        if prax.selectedPageItem != nil {
            HStack {
                Spacer()
                Button { prax.showTrimsEditor.toggle() }
                label: { Image(systemName: "scissors") }
                    .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 407))
                    .onHover { hovering in prax.hoveredButton = hovering ? 407 : nil }
                
                Button { prax.showFileExportOptions.toggle() }
                label: { Image(systemName: "folder.badge.gearshape") }
                    .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 447))
                    .onHover { hovering in prax.hoveredButton = hovering ? 447 : nil }
                    .popover(isPresented: $prax.showFileExportOptions) {ExportFilenamePopover()}
                                                                             
                Spacer()

                VStack {
                    HStack{
                        
                        
                        
                        Button { showPrefixPopover.toggle() }
                        label: {
                            if prax.document.exportFilenamePrefix.isEmpty {
                                Text("prefix").font(.caption).italic().padding(5).foregroundStyle(.buttonDefaultForeground)
                            }
                            else {
                                Text("\(prax.document.exportFilenamePrefix)").padding(.horizontal, 5)
                            }
                        }
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 427, isOn: !prax.document.exportFilenamePrefix.isEmpty, width: nil, height: nil))
                        .onHover { hovering in prax.hoveredButton = hovering ? 427 : nil }
                        .popover(isPresented: $showPrefixPopover, arrowEdge: .top, content: {
                            FilenamePrefixPopover()
                        })
                        
                        TextField("Filename", text: Binding<String>(
                            get: { prax.document.exportFilenameBody },
                            set: { newValue in
                                prax.document.exportFilenameBody = newValue.filter{!Prax.filechars.contains($0)}}))
                        .frame(maxWidth: 300)
                        .focused($focusedField, equals: .exportFilenameBody)
                        
                        Text(prax.document.exportFilenameSuffix)
                        
                        
                        Button { showSuffixPopover.toggle() }
                        label: {
                            if prax.document.exportFilenameSuffix.isEmpty {
                                Text("suffix").font(.caption).italic().padding(5).foregroundStyle(.buttonDefaultForeground)
                            }
                            else {
                                Text("\(prax.document.exportFilenameSuffix)").padding(.horizontal, 5)
                            }
                        }
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 487, isOn: !prax.document.exportFilenameSuffix.isEmpty, width: nil, height: nil))
                        .onHover { hovering in prax.hoveredButton = hovering ? 487 : nil }
                        .popover(isPresented: $showSuffixPopover, arrowEdge: .top, content: {
                            FilenameSuffixPopover()
                        })
                        
                        
                        
                    }
                    
                    Text("Filename").font(.caption)
                    
                }
                
                if prax.document.dataFieldPage != nil {
                    
                    Button { withAnimation {prax.showDataFields.toggle() } }
                    label: { Image(systemName: "gear") }
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 436))
                        .onHover { hovering in prax.hoveredButton = hovering ? 436 : nil }
                        .help("Edit Data")
                        .padding(.leading, 20)
                }
                
                
             //   .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
             //   .onHover { hovering in prax.hoveredButton = hovering ? 437 : nil }
                
                /*                    GroupBox {
                 VStack {
                 Text("Suffix")
                 TextField("Filename", text: Binding<String>(
                 get: { prax.document.exportFilenameSuffix },
                 set: { newValue in
                 prax.document.exportFilenameSuffix = newValue.filter{!Prax.filechars.contains($0)}}))
                 .focused($focusedField, equals: .exportFilenameSuffix)
                 }
                 .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                 }
                 .frame(maxWidth: 100)
                 .groupBoxStyle(PraxGroupBoxStyle(isHovering: prax.hoveredButton == 447 ))
                 .onHover { hovering in prax.hoveredButton = hovering ? 447 : nil }
                 */
                
                Spacer()
            }
        
            .onGeometryChange(for: CGSize.self) { viewGeometry in return viewGeometry.size }
            action: { oldValue, newValue in prax.editingToolbarSize = newValue }
            
                .animation(.easeIn(duration: 0.5), value: prax.showDataFields)
                .animation(.easeIn(duration: 0.5), value: groupHovering)
                .animation(.easeIn(duration: 0.5), value: hovering)
                .frame(maxWidth: .infinity, minHeight: 20)
                .onHover { isHovering in withAnimation { hovering = isHovering  } }
                .environment(\.groupHovering, hovering)
            
                .background(PraxGradient(4))
                .background(PraxGradient(4))
            //            .opacity(hovering ? 1 : 0.1)
            
                .focusedSceneValue(\.setExportFilenameBody, {
                    focusedField = .exportFilenameBody
                })
            
        }
        else {
            EmptyView()
        }
    }
    
}


struct FilenamePrefixPopover: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    var savedPrefixes = ["Amazon-", "Costco-", "ezCater-", "airfare-", "conference-", "meal-", "taxi-" ]
    var body: some View {
        @Bindable var prax = prax
        VStack {
            Text("Export Filename Prefix")
            Divider()
            VStack {
                ForEach(savedPrefixes, id: \.self, content: { savedPrefix in
                    Button { prax.document.exportFilenamePrefix = savedPrefix; dismiss()} label: { Text(savedPrefix)}
                    .frame(maxWidth: .infinity, alignment: .trailing) }) }
            Divider()
            
            VStack {
                HStack {
                    TextField("Export Filename Prefix", text: $prax.document.exportFilenamePrefix)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(alignment: .trailing) {
                            if !prax.document.exportFilenamePrefix.isEmpty {
                                Button { prax.document.exportFilenamePrefix = "" }
                                label: {Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).padding(.trailing, 6)}
                                    .buttonStyle(.plain)
                                    .help("Clear")
                            }
                        }
                        .onSubmit { dismiss() }
                    
                    Button { dismiss() } label: { Image(systemName: "checkmark") }
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 427))
                        .onHover { hovering in prax.hoveredButton = hovering ? 427 : nil }
                }
                
                if prax.document.exportFilenamePrefix != "" {
                    HStack {
                        Spacer()
                        Text("Clear Prefix")
                        Button {  prax.document.exportFilenamePrefix = ""; dismiss() }
                        label: { Image(systemName: "text.page.slash") }
                            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 426))
                            .onHover { hovering in prax.hoveredButton = hovering ? 426 : nil }
                    }
                }
            }
        }
        //      .containerShape(.rect(cornerRadius: 24)).border(.white, width: 5)
        .padding(20)
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
        
    }
}

struct FilenameSuffixPopover: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    var savedPrefixes = ["Amazon-", "Costco-", "ezCater-", "airfare-", "conference-", "meal-", "taxi-" ]
    var body: some View {
        @Bindable var prax = prax
        VStack {
            /*            if prax.document.exportFilenameSuffix != "" {
             HStack {
             Spacer()
             Text("Clear Prefix")
             Button {  prax.document.exportFilenameSuffix = ""; dismiss() }
             label: { Image(systemName: "text.page.slash") }
             .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 626))
             .onHover { hovering in prax.hoveredButton = hovering ? 626 : nil }
             }
             }
             */
            HStack {
                TextField("Export Filename Suffix", text: $prax.document.exportFilenameSuffix)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                //         .overlay(alignment: .trailing) {
                //             if !prax.document.exportFilenameSuffix.isEmpty {
                //                 Button { prax.document.exportFilenameSuffix = ""; dismiss() }
                //                 label: {Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).padding(.trailing, 6)}
                //                     .buttonStyle(.plain)
                //                     .help("Clear")
                //             }
                //         }
                    .onSubmit { dismiss() }
                
                if prax.document.exportFilenameSuffix != "" {
                    Button { prax.document.exportFilenameSuffix = ""; dismiss()  }
                    label: {  Image(systemName: "xmark.circle") }
                        .buttonStyle(PraxButtonStyle())
                        .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                }
                
                
                Button { dismiss() }
                label: {  Image(systemName: "checkmark.circle") }
                    .buttonStyle(PraxButtonStyle())
                    .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
            }
            
            //   Text("Export Filename Suffix")
            Divider()
            VStack {
                ForEach(savedPrefixes, id: \.self, content: { savedPrefix in
                    Button { prax.document.exportFilenameSuffix = savedPrefix; dismiss()} label: { Text(savedPrefix)}
                    .frame(maxWidth: .infinity, alignment: .trailing) }) }
            Divider()
            
            //     VStack {
            //          HStack {
            
            
            //                  Button { dismiss() } label: { Image(systemName: "checkmark") }
            //                      .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 627))
            //                      .onHover { hovering in prax.hoveredButton = hovering ? 627 : nil }
            //            }
            
            
            //     }
        }
        //      .containerShape(.rect(cornerRadius: 24)).border(.white, width: 5)
        .padding(20)
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
        
    }
}

struct EditingZoomOverlayView: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.groupHovering) private var groupHovering
    
    @State private var hovering: Bool = false
    
    var body: some View {
        @Bindable var prax = prax
        //   if let pageItem = prax.selectedPageItem {
        VStack {
            Text("View Zoom")
            Grid {
                GridRow {
                    
                    Button {
                        prax.editorViewScaleMode = .user
                        prax.editingDocumentPDFView.zoomOut(self) }
                    label: {  Image(systemName: "minus.circle") }
                        .buttonStyle(PraxButtonStyle())
                        .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                        .help("Zoom Out")
                    
                    Button { prax.scaleEditorView()}
                    label: {  Image(systemName: "arrow.up.and.down.and.arrow.left.and.right") }
                        .buttonStyle(PraxButtonStyle())
                        .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                        .help("Scale to Fit")
                        .disabled(prax.editorViewScaleMode == .fit)
                    
                    Button {
                        prax.editorViewScaleMode = .user
                        prax.editingDocumentPDFView.zoomIn(self) }
                    label: {  Image(systemName: "plus.circle") }
                        .buttonStyle(PraxButtonStyle())
                        .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                        .help("Zoom In")
                }
                GridRow {
                    Button(action: { prax.scaleEditorView(.vertical)}, label: {
                        Image(systemName: "arrow.up.and.down") })
                    .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 731))
                    .onHover { hovering in prax.hoveredButton = hovering ? 731 : nil }
                    .help("Fit Vertically")
                    .disabled(!(prax.editorViewScaleMode != .vertical && prax.editorViewFitMode != .vertical))
                    
                    
                    VStack {
                        Text("Zoom").font(.caption2).foregroundStyle(Color.black)
                        Text("\(Int(prax.editorViewScaleFactor * 100))").font(.caption2).foregroundStyle(Color.black)
                    }
                    
                    Button(action: { prax.scaleEditorView(.horizontal)}, label: {
                        Image(systemName: "arrow.left.and.right") })
                    .buttonStyle(PraxButtonStyle())
                    .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                    .help("Fit Horizontally")
                    .disabled(!(prax.editorViewScaleMode != .horizontal))
                }
                
                Slider(value: $prax.editorViewScaleFactor, in: 0.1...2.0)
                    .gridCellColumns(2)
                    .frame(width: 100)
                    .gridCellUnsizedAxes(.horizontal)
            }
            .padding(5)
            .opacity(hovering ? 1.0 : 0.5)
            
        }
        .animation(.easeIn(duration: 0.2), value: groupHovering)
        .animation(.easeIn(duration: 0.2), value: hovering)
        .onHover { isHovering in hovering = isHovering }
        .environment(\.groupHovering, hovering)
        .background(PraxGradient(4), in: RoundedRectangle(cornerRadius: 5))
        .opacity(groupHovering ? 1.0 : 0.25)
        
        .offset(x: -50, y: prax.editorViewSize.height * 0.75)
        //        }
        //        else { EmptyView()  }
    }
}



/*
struct aEditingTrimsOverlayView: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.groupHovering) private var groupHovering
    
    @State private var hovering: Bool = false
    @State private var markedTop: CGFloat?
    @State private var markedBottom: CGFloat?
    @State private var markedLeft: CGFloat?
    @State private var markedRight: CGFloat?
    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.selectedPageItem {
            @Bindable var pageItem = pageItem
            VStack {
                Text("Trims Editor").font(.headline).foregroundStyle(.buttonDefaultBackground)
                
                HStack {
                    VStack {
                        Text("Page \((pageItem.editPageIndex) + 1) of \(prax.editingPageItems.count)")
                        
                        HStack {
                            Text("Top")
                            Stepper("", onIncrement: {if pageItem.trims.top > 0 {pageItem.trims.top -= 1}}, onDecrement: {if pageItem.trims.top < pageItem.bounds.height {pageItem.trims.top += 1}}).labelsHidden().frame(width: 15)
                            
                            Text("\(Int(pageItem.trims.top))")
                            
                        }.backgroundStyle(PraxGradient(4))
                    }
                    VStack {
                        Text("Pins")
                        
                        HStack {
                            Button {  }
                            label: { Image(systemName: "chevron.backward")}
                                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil, height: nil))
                                .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                            
                            
                            Text("\(Int(markedTop ?? 0))")
                            
                            Button { if markedTop != nil {markedTop = nil} else {markedTop = pageItem.trims.top}  }
                            label: { Image(systemName: "pin.square")}
                                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil, height: nil))
                                .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                            
                                .disabled(pageItem.trims.top < 1 && markedTop == nil)
                            
                            
                            /*                    Button { if markedTop != nil {markedTop = nil} else {markedTop = pageItem.trims.top}  }
                             label: {  HStack { if markedTop == nil {
                             Image(systemName: "pin.circle")
                             Text("Mark")
                             }else {
                             Text("Marked: \(Int(markedTop!))")
                             Image(systemName: "xmark.circle")}
                             }}
                             .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                             .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                             .disabled(pageItem.trims.top < 1 && markedTop == nil)
                             */
                        }.padding(.leading, 4)
                        
                    }.overlay(Rectangle().fill(Color.blue).frame(width: 2),alignment: .leading)
                    
                }.overlay(Rectangle().fill(Color.blue).frame(height: 2),alignment: .top)
                
                
                
                /*
                 Grid(alignment: .center) {
                 HStack {
                 Text("Page \((pageItem.editPageIndex) + 1) of \(prax.editingPageItems.count)")
                 Spacer()
                 Text("Pins")
                 }
                 
                 Divider().foregroundStyle(.black)
                 
                 GridRow {
                 
                 HStack {
                 Image(systemName: "arrow.up.to.line")
                 Stepper("", onIncrement: {if pageItem.trims.top > 0 {pageItem.trims.top -= 1}}, onDecrement: {if pageItem.trims.top < pageItem.bounds.height {pageItem.trims.top += 1}}).labelsHidden().frame(width: 15)
                 
                 Text("\(Int(pageItem.trims.top))")
                 Button {  }
                 label: { Image(systemName: "arrow.up.to.line")}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 
                 }.backgroundStyle(PraxGradient(4))
                 
                 Rectangle().frame(width: 1).gridCellUnsizedAxes(.vertical)
                 
                 
                 
                 
                 Button { if markedTop != nil {markedTop = nil} else {markedTop = pageItem.trims.top}  }
                 label: { Image(systemName: "pin.square")}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 .disabled(pageItem.trims.top < 1 && markedTop == nil)
                 
                 
                 Text("\(Int(markedTop ?? 0))")
                 
                 Button { if markedTop != nil {markedTop = nil} else {markedTop = pageItem.trims.top}  }
                 label: {  HStack { if markedTop == nil {
                 Image(systemName: "pin.circle")
                 Text("Mark")
                 }else {
                 Text("Marked: \(Int(markedTop!))")
                 Image(systemName: "xmark.circle")}
                 }}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 .disabled(pageItem.trims.top < 1 && markedTop == nil)
                 }
                 
                 GridRow {
                 
                 HStack {
                 Image(systemName: "arrow.backward.to.line")
                 Stepper("", onIncrement:{if pageItem.trims.left < pageItem.bounds.width {pageItem.trims.left += 1}} , onDecrement: {if pageItem.trims.left > 0 {pageItem.trims.left -= 1}} ).labelsHidden().frame(width: 15)
                 Text("\(Int(pageItem.trims.left))")
                 }
                 
                 Button {  }
                 label: { Image(systemName: "arrow.right.circle")}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 
                 
                 Rectangle().frame(width: 1).gridCellUnsizedAxes(.vertical)
                 
                 Button {  }
                 label: { Image(systemName: "arrow.left.circle")}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 
                 Text("\(Int(markedLeft ?? 0))")
                 
                 Button { if markedLeft != nil {markedLeft = nil} else {markedLeft = pageItem.trims.left}  }
                 label: {  HStack { if markedLeft == nil {
                 Image(systemName: "pin.circle")
                 Text("Mark")
                 }else {
                 Text("Marked: \(Int(markedLeft!))")
                 Image(systemName: "xmark.circle")}
                 }}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedLeft == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 .disabled(pageItem.trims.left < 1 && markedLeft == nil)
                 }
                 
                 GridRow {
                 
                 HStack {
                 Image(systemName: "arrow.forward.to.line")
                 Stepper("", onIncrement: {if pageItem.trims.right > 0 {pageItem.trims.right -= 1}}, onDecrement: {if pageItem.trims.right < pageItem.bounds.width {pageItem.trims.right += 1}}).labelsHidden().frame(width: 15)
                 Text("\(Int(pageItem.trims.right))")
                 }
                 
                 
                 Button {  }
                 label: { Image(systemName: "arrow.right.circle")}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 
                 Rectangle().frame(width: 1).gridCellUnsizedAxes(.vertical)
                 
                 Button {  }
                 label: { Image(systemName: "arrow.left.circle")}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 
                 Text("\(Int(markedRight ?? 0))")
                 
                 Button { if markedRight != nil {markedRight = nil} else {markedRight = pageItem.trims.right}  }
                 label: {  HStack { if markedRight == nil {
                 Image(systemName: "pin.circle")
                 Text("Mark")
                 }else {
                 Text("Marked: \(Int(markedRight!))")
                 Image(systemName: "xmark.circle")}
                 }}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedRight == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 .disabled(pageItem.trims.right < 1 && markedRight == nil)
                 }
                 
                 GridRow {
                 
                 HStack {
                 Image(systemName: "arrow.down.to.line")
                 
                 Stepper("", onIncrement: {if pageItem.trims.bottom < pageItem.bounds.height {pageItem.trims.bottom += 1}}, onDecrement: {if pageItem.trims.bottom > 0 {pageItem.trims.bottom -= 1}}).font(.caption2).labelsHidden().frame(width: 15)
                 Text("\(Int(pageItem.trims.bottom))")
                 }
                 
                 Button {  }
                 label: { Image(systemName: "arrow.right.circle")}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 
                 Rectangle().frame(width: 1).gridCellUnsizedAxes(.vertical)
                 
                 Button {  }
                 label: { Image(systemName: "arrow.left.circle")}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 402, isOn: markedTop == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 402 : nil }
                 
                 Text("\(Int(markedBottom ?? 0))")
                 
                 Button { if markedBottom != nil {markedBottom = nil} else {markedBottom = pageItem.trims.bottom}  }
                 label: {  HStack { if markedBottom == nil {
                 Image(systemName: "pin.circle")
                 Text("Mark")
                 }else {
                 Text("Marked: \(Int(markedBottom!))")
                 Image(systemName: "xmark.circle")}
                 }}
                 .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 403, isOn: markedBottom == nil, width: nil))
                 .onHover { hovering in prax.hoveredButton = hovering ? 403 : nil }
                 .disabled(pageItem.trims.bottom < 1 && markedBottom == nil)
                 }
                 
                 Divider().foregroundStyle(.black)
                 Text(pageSizeText(pageItem.bounds)).font(.caption2)
                 
                 }
                 .fixedSize(horizontal: true, vertical: false)
                 .padding(5)
                 .background(PraxGradient(1), in: RoundedRectangle(cornerRadius: 5))
                 .opacity(hovering ? 1.0 : 0.95)
                 */
            }
            .padding(5)
            .animation(.easeIn(duration: 0.2), value: groupHovering)
            .animation(.easeIn(duration: 0.2), value: hovering)
            .onHover { isHovering in hovering = isHovering }
            .environment(\.groupHovering, hovering)
            .background(pageItem.editPageIndex.isMultiple(of: 2) ? PraxGradient(41) : PraxGradient(1), in: RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
            .opacity(groupHovering ? 1.0 : 0.1)
            
            .offset(x: 50, y: 50)
        }
        else {
            EmptyView()
        }
    }
}



*/
