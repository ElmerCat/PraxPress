//
//  AuxilliaryViews.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/13/26.
//

import SwiftUI
import TipKit
import UniformTypeIdentifiers
import PDFKit


struct ImportOptionsInspector: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("import-width") var importWidth: Int = 0
    @AppStorage("import-height") var importHeight: Int = 0
    @FocusState var widthFocused: Bool
    var theTip = ImportOptionsTip()
    
    var body: some View {
        
        VStack {
            GroupBox {
                Button {
                    dismiss()
                } label: {
                    Label("Ok", systemImage: ("checkmark"))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                
                Grid {
                    GridRow {
                        Text("Import Width:")
                        TextField("",
                                  value: $importWidth,
                                  format: .number
                        ).border(Color("PraxColor"))
                            .onSubmit({
                                dismiss()
                            })
                            .focused($widthFocused)
                            .textContentType(.postalCode)
                    }
                    
                    GridRow {
                        Text("Import Height:")
                        TextField("",
                                  value: $importHeight,
                                  format: .number
                        ).border(Color("PraxColor"))
                        
                        
                    }
                }
                
                
                
                
                Text("\(importWidth)")
                //    .foregroundColor(emailFieldIsFocused ? .red : .blue)
                
                Text("Image Import Size")
                    .frame(minWidth: 100, maxWidth: 300, maxHeight: .infinity)
                    .background(Color("PraxColor"))
            }
            .padding(20)
            
        }
        .background(PraxGradient(0).edgesIgnoringSafeArea(.all))
        .popoverTip(theTip)
    }
}



struct ImportOptionsTip: Tip {
    var title: Text {
        Text("Image Import Options")
    }
    
    
    var message: Text? {
        Text("Imported images are resampled to reduce the size of the resulting PDF file. Use these options to control the quality of the output.")
    }
    
    
    var image: Image? {
        Image(systemName: "photo.badge.arrow.down")
    }
}



public struct ASlideableDivider: View {
    @Binding var dimension: Double
    @Binding var otherDimension: Double
    let position: Int
    let isShowingOtherPane: Bool
    let minDimension: Double
    let maxDimension: Double
    let windowWidth: Double
    //   @Binding var collapse: Bool?
    
    @State private var dimensionStart: Double?
    
    public var body: some View {
        Rectangle()
            .fill(.orange)
            .frame(width: 10)
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: CoordinateSpace.global)
            .onChanged { val in
                if dimensionStart == nil {
                    if position == 0 {
                        dimensionStart = dimension
                    }
                    else {
                        dimensionStart = otherDimension
                    }
                    dimensionStart = dimension
                }
                let delta = val.location.x - val.startLocation.x
                let newDimension = dimensionStart! + Double(delta)
                
                
                let difference = newDimension - dimension
                
                if difference > 0 {
                    
                    
                    
                }
                else if difference < 0 {
                    if position == 0 {
                        if newDimension < minDimension {
                            print("Julie d'Prax")
                            //  collapse = false
                        }
                        else {
                            dimension = newDimension
                        }
                    }
                    else {
                        if newDimension > maxDimension {
                            print("Juliette M. Belanger")
                            //  collapse = false
                        }
                        else {
                            dimension = newDimension
                        }
                        
                    }
                    
                }
                
                if position == 0 {
                    if newDimension < minDimension {
                        print("Julie d'Prax")
                        //  collapse = false
                        return
                    }
                    
                    if newDimension < windowWidth - maxDimension {
                        dimension = newDimension
                        return
                    }
                }
                
                if newDimension + dimension < minDimension {
                    
                    print("Julie d'Prax")
                    //  collapse = false
                    return
                }
                else if isShowingOtherPane {
                    
                    if newDimension < windowWidth - dimension - otherDimension - maxDimension {
                        dimension += difference / 2
                        otherDimension += difference / 2
                    }
                    
                    
                }
                else {
                    
                    if newDimension < windowWidth - maxDimension {
                        dimension += difference
                        otherDimension += difference
                    }
                    
                    
                }
                
                
                print("dimension: ", dimension)
                
            }
            .onEnded { val in
                dimensionStart = nil
            }
    }
}

public struct SlideableDivider: View {
    let dimension: Double
    let position: Int
    let onChangedDivider: (Double, Int) -> Void
    
    @State private var dimensionStart: Double?
    
    public var body: some View {
        Rectangle()
            .fill(.orange)
            .frame(width: 10)
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: CoordinateSpace.global)
            .onChanged { val in
                if dimensionStart == nil {
                    dimensionStart = dimension
                }
                let delta = val.location.x - val.startLocation.x
                let newDimension = dimensionStart! + Double(delta)
                
                onChangedDivider(newDimension, position)
            }
            .onEnded { val in
                dimensionStart = nil
            }
    }
}

struct ReusableSegmentedControl<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String {
    
    // The selection is now a @Binding so it can be changed from the parent view
    @Binding var selection: T
    private let items: [T] = T.allCases as! [T]
    @Namespace private var animation
    
    // We add a function to get the color for a specific item
    let colorProvider: (T) -> Color
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(items, id: \.self) { item in
                Text(item.rawValue)
                    .font(.headline)
                    .padding(10)
                    .foregroundStyle(selection == item ? .white : .primary.opacity(0.7))
                    .background {
                        if selection == item {
                            
                            Capsule()
                                .foregroundStyle(colorProvider(item).gradient)
                                .matchedGeometryEffect(id: "reusable_tab", in: animation)
                        }
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            selection = item
                        }
                    }
            }
        }
        .background(.primary.opacity(0.08), in: .capsule)
        //    .padding(.horizontal, 10)
    }
}

struct DragOutControl: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    @FocusState private var isFocused: Bool
    // 2. Track the text selection
    @State private var selection: TextSelection?
    
    var body: some View {
        @Bindable var prax = praxModel
        
        Group {
            HStack {
                Spacer(minLength: 25)
                Text("Drag out PDF as...   ")
                    .font(.headline)
                    .padding(.vertical, 10)
                
                    .foregroundStyle(.white)
                
                    .contentShape(.rect)
                
                Button {
                    prax.showingFileExportOptions.toggle()
                } label: {
                    Label("Import Options", systemImage: (prax.showingMergedDocumentInspector ? "gearshape.fill" : "gearshape"))
                }
                .sheet(isPresented: $prax.showingFileExportOptions) {
                    ImportOptionsInspector()
                    
                        .presentationDetents(
                            [.height(120), .medium, .large])
                        .presentationBackgroundInteraction(
                            .enabled(upThrough: .height(120)))
                        .presentationSizing(.form)
                    
                }
                
                Spacer(minLength: 5)
                Text(document.exportFilenamePrefix)
                TextField("Filename", text: Binding<String>(
                    get: { document.exportFilenameBody },
                    set: { newValue in
                        var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let dotRange = newName.range(of: ".") {
                            newName = String(newName[..<dotRange.lowerBound])
                        }
                        document.exportFilenameBody = newName
                    }),selection: $selection).focused($isFocused)
                .onChange(of: isFocused) {
                    if isFocused {
                        // Select the entire string range
                        selection = .init(range: document.exportFilenameBody.startIndex..<document.exportFilenameBody.endIndex)
                    }
                }
                .font(.headline)
           //     .padding(.vertical, 10)
                
                .foregroundStyle(.white)
                
                .frame(minWidth: 50, idealWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                .textFieldStyle(.automatic)
                    .padding(.horizontal, 20)
                //    .disabled(prax.exportFolderURL == nil)
//                .foregroundStyle(.cyan)
 //               .backgroundStyle(.yellow)
                
                Text(document.exportFilenameSuffix)
                Spacer(minLength: 5)
                Image(systemName: "arrow.right.doc.on.clipboard")
                Spacer(minLength: 5)
                Text(".\(document.exportFilenameExtension)          ")

                Spacer(minLength: 25)
            }
            .draggable {
                if let data = document.mergedPDFDocument().dataRepresentation() {
                    return MergedPDFTransfer(data: data, filename: (document.exportFilename))
                } else { return nil }
            }
            .background {
                Capsule()
                    .foregroundStyle(Color.blue.gradient)
            }
        }
        
        .onAppear {
           
            isFocused = true
        }

    }
}

struct DropTargetControl: View {
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    
    var body: some View {
        @Bindable var prax = praxModel
        
        Group {
            HStack {
                Spacer(minLength: 25)
                Text("   Drop Files Here   ")
                    .font(.headline)
                    .padding(.vertical, 10)
                
                    .foregroundStyle(.white)
                
                    .contentShape(.rect)
                
                Button {
                    prax.showingFileImportOptions.toggle()
                } label: {
                    Label("Import Options", systemImage: (prax.showingMergedDocumentInspector ? "gearshape.fill" : "gearshape"))
                }
                .sheet(isPresented: $prax.showingFileImportOptions) {
                    ImportOptionsInspector()
                    
                        .presentationDetents(
                            [.height(120), .medium, .large])
                        .presentationBackgroundInteraction(
                            .enabled(upThrough: .height(120)))
                        .presentationSizing(.form)
                    
                    
                }
                Spacer(minLength: 25)
            }.background {
                Capsule()
                    .foregroundStyle(prax.dropTargeted ? Color.green.gradient : Color.blue.gradient )
            }
        }
        
        .onDrop(of: [.fileURL, .mergedPageType, .pdfPageDragType], delegate: PraxDropDelegate(document, prax))
        
        
    }
}

struct OptionKeyPressedToolbarItem: View {
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    var body: some View {
        @Bindable var prax = praxModel
        
        Group {
            HStack {
                Spacer(minLength: 25)
                
                Label(" ", systemImage: prax.optionKeyPressed ? "squareshape.squareshape.dotted" :"squareshape")
                
                    .font(.headline)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .contentShape(.rect)
                Spacer(minLength: 25)
            }.background {
                Capsule()
                    .foregroundStyle(Color.clear)
            }
        }
    }
}



class praxListItem: NSCollectionViewItem {
    
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("list-item-reuse-identifier")
    
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            updateSelectionHighlighting()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionHighlighting()
        }
    }
    
    private func updateSelectionHighlighting() {
        if !isViewLoaded {
            return
        }
        
        let showAsHighlighted = (highlightState == .forSelection) ||
        (isSelected && highlightState != .forDeselection) ||
        (highlightState == .asDropTarget)
        
        textField?.textColor = showAsHighlighted ? .selectedControlTextColor : .labelColor
        view.layer?.backgroundColor = showAsHighlighted ? NSColor.selectedControlColor.cgColor : nil
    }
}


#Preview {
    OptionKeyPressedToolbarItem()
}
