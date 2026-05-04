//
//  Popovers.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/19/26.
//

import SwiftUI
import PDFKit
import TipKit

struct ImageInspectingPopover: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("import-width") var importWidth: Int = 0
    @AppStorage("import-height") var importHeight: Int = 0

    @Environment(PraxModel.self) private var prax
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State private var hoveredButton: Int? = nil
    @State private var imageAngle = 0.0
    
    @FocusState var widthFocused: Bool
    
    func editingImage() -> Image {
        if let editingImage = prax.inspectingImage {
            var imageSize = editingImage.size
            if editingImage.size.height > CGFloat(importHeight) || editingImage.size.width > CGFloat(importWidth){
                let aspectRatio = imageSize.height / imageSize.width
                if aspectRatio > 1 {
                    imageSize.height =  CGFloat(importHeight)
                    imageSize.width =  CGFloat(importHeight) / aspectRatio
                }
                else {
                    imageSize.height =  CGFloat(importWidth) * aspectRatio
                    imageSize.width =  CGFloat(importWidth) / aspectRatio
                    
                }
            }
            
            print (imageSize)
            
            let resizedImage = editingImage.resize(to: imageSize)!
            
            return Image(nsImage: resizedImage)
            
        }
        else {
            return Image("PraxPress")
        }
    }
   
    var body: some View {
        @Bindable var prax = prax
        
        
        VStack {
            GroupBox {
                HStack {
                    Image("PraxPress").resizable().aspectRatio(contentMode: .fit).frame(width: 20)
                        .padding(3)
                        .rotationEffect(Angle(degrees: imageAngle))
                        .onAppear {
                            withAnimation {
                                imageAngle -= (2 * 360) - 120
                            }
                        }
                        .onDisappear {
                            withAnimation {
                                imageAngle = 0
                            }
                        }
                    Text("Delete All Page Items?")
                }
            }
            Divider()
            
            
            
            
            GroupBox {
                editingImage()
            }
            
            Toggle(isOn: $prax.inspectNextImageDrop, label: {
                    Text("Test on Next Drop")
            })
            
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
            

            
            
            GroupBox {
                VStack {
                    HStack {
                        Spacer()
                        
                        
                        Button { dismiss() }
                        label: {
                            HStack {
                                Text("Cancel")
                                Image(systemName: "checkmark.rectangle.stack")
                            }
                            
                        }
                        .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 427))
                        .onHover { hovering in hoveredButton = hovering ? 427 : nil }
                        

                    }
                }
            }
        }
          .containerShape(.rect(cornerRadius: 24)).border(.white, width: 5)
        .padding(20)
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
        
    }
}

struct DeletePopover: View {
//    let mergedPage: MergedPage
    @Environment(\.dismiss) private var dismiss
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State private var hoveredButton: Int? = nil
    @State private var imageAngle = 0.0
    
  //  var theTip = FilenamePrefixTip()

   
    var body: some View {
        @Bindable var document = document
        
        VStack {
            GroupBox {
                HStack {
                    Image("PraxPress").resizable().aspectRatio(contentMode: .fit).frame(width: 20)
                        .padding(3)
                        .rotationEffect(Angle(degrees: imageAngle))
                        .onAppear {
                            withAnimation {
                                    imageAngle -= (1 * 360) 
                            }
                        }
                        .onDisappear {
                            withAnimation {
                                    imageAngle = 0
                            }
                        }
               //     Text("Clear All Page Items?")
                //        Spacer()

                        
                        Button { dismiss() }
                        label: {
                            HStack {
                                Text("Cancel")
                                Image(systemName: "checkmark.rectangle.stack")
                            }
                                
                       }
                        .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 427))
                        .onHover { hovering in hoveredButton = hovering ? 427 : nil }

                        
                        Button {
                            document.pageSections.removeAll()
                            dismiss()
                            }
                        label: {
                            HStack {
                                Text("Clear All Page Items")
                                Image(systemName: "rectangle.stack.slash").rotationEffect(Angle(degrees: imageAngle))
                            }
                                
                       }
                        .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 426))
                        .onHover { hovering in hoveredButton = hovering ? 426 : nil }
                    }
                
            }
        }
  //      .containerShape(.rect(cornerRadius: 24)).border(.white, width: 5)
      //  .padding(20)
    //    .padding(.horizontal, 10)
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
//        .popoverTip(theTip)
      //  .tipImageSize(CGSize(width: 500, height: 500))
        
        
        
    }
}

struct FilenamePrefixPopover: View {
//    let mergedPage: MergedPage
    @Environment(\.dismiss) private var dismiss
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State private var hoveredButton: Int? = nil
    @State private var imageAngle = 0.0
    
    var theTip = FilenamePrefixTip()

    
    var savedPrefixes = ["Amazon-", "Costco-", "ezCater-", "airfare-", "conference-", "meal-", "taxi-" ]
    
    var body: some View {
        @Bindable var document = document
        
        
        
        VStack {
            GroupBox {
                HStack {
                    Image("PraxPress").resizable().aspectRatio(contentMode: .fit).frame(width: 20)
                        .padding(3)
                        .rotationEffect(Angle(degrees: imageAngle))
                        .onAppear {
                            withAnimation {
                                    imageAngle -= (2 * 360) - 120
                            }
                            
                        }
                        .onDisappear {
                            withAnimation {
                                    imageAngle = 0
                            }
                        }
                    Text("Export Filename Prefix")
                   
                }
            }
            

            
            Divider()
            
            GroupBox {
                
                VStack {
                    
                    
                    
                    ForEach(savedPrefixes, id: \.self, content: { savedPrefix in
                        
                        Button {
                            document.exportFilenamePrefix = savedPrefix
                            dismiss()
                        } label: {
                            Text(savedPrefix)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                       
                    })
                }
               
                
            }

            Divider()

            VStack {
                HStack {
                    TextField("Export Filename Prefix", text: $document.exportFilenamePrefix)
                        
                        
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                        .overlay(alignment: .trailing) {
                            if !document.exportFilenamePrefix.isEmpty {
                                Button {
                                    document.exportFilenamePrefix = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 6) // adjust for your field style
                                }
                                .buttonStyle(.plain)
                                .help("Clear")
                            }
                        }
                        
                        
                        
                        .onSubmit {
                        dismiss()
                    }
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 427))
                    .onHover { hovering in hoveredButton = hovering ? 427 : nil }
                }
                
                if document.exportFilenamePrefix != "" {
                    
                    HStack {
                        Spacer()
                        Text("Clear Prefix")
                        Button {
                            document.exportFilenamePrefix = ""
                            dismiss()
                            }
                        label: {
                            
                                Image(systemName: "text.page.slash")

                            
                        }
                        .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 426))
                        .onHover { hovering in hoveredButton = hovering ? 426 : nil }
                    }

                }
            }
 
         
        }
  //      .containerShape(.rect(cornerRadius: 24)).border(.white, width: 5)
        .padding(20)
    //    .padding(.horizontal, 10)
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
        .popoverTip(theTip)
      //  .tipImageSize(CGSize(width: 500, height: 500))
        
        
        
    }
}

struct SectionHeaderPopover: View {
    let mergedPage: MergedPage
    @Environment(\.dismiss) private var dismiss
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State private var hoveredButton: Int? = nil
    @State private var imageAngle = 0.0
    
    var theTip = PageItemTip()
    
    var body: some View {
        
        VStack {
            GroupBox {
                HStack {
                    Image("PraxPress").resizable().aspectRatio(contentMode: .fit).frame(width: 40)
                        .padding(3)
                        .rotationEffect(Angle(degrees: imageAngle))
                        .onAppear {
                            withAnimation {
                                    imageAngle -= 3000
                            }
                            
                        }
                        .onDisappear {
                            withAnimation {
                                    imageAngle = 0
                            }
                        }

                    if document.pageSections.count > 1 {
                        Text("\(document.pageSections.count) Merged Pages from \(document.totalPageItems) Page Items")
                    }
                    else {
                        Text("Merged Page")
                    }
                }

            }

            Divider()

            GroupBox {
                Text("\(mergedPage.title).pdf")
                if mergedPage.pageItems.count < 2 {
                    Text("Just Trimming This Page")
                }
                else if mergedPage.skippedPages < 1 {
                    Text("Merging \(mergedPage.pageItems.count) Pages")
                }
                else {
                    Text("Skipping \(mergedPage.skippedPages) of \(mergedPage.pageItems.count) Pages")
                }
                
                Grid(alignment: .trailing) {
                
                Divider()
                
                GridRow {
                    if mergedPage.pageItems.count == 1 {
                        Text("Include This Page")
                    }
                    else if mergedPage.pageItems.count == 2 {
                        Text("Include Both Pages")
                    }
                    else {
                        Text("Include All \(mergedPage.pageItems.count) Pages")
                    }
                    
                    Button {
                        mergedPage.includeAllPages()
                        dismiss() }
                    label: {
                        
                        Image(systemName: "rectangle.portrait.slash")
                        
                    }
                    .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 153))
                    .onHover { hovering in hoveredButton = hovering ? 153 : nil }
                    
                }
                .disabled(mergedPage.skippedPages == 0)
                .opacity(mergedPage.skippedPages == 0 ? 0.25 : 1)
                
                GridRow {
                    
                    if mergedPage.pageItems.count == 1 {
                        Text("Skip This Page")
                    }
                    else if mergedPage.pageItems.count == 2 {
                        Text("Skip Both Pages")
                    }
                    else {
                        Text( "Skip All \(mergedPage.pageItems.count) Pages")
                    }
                    
                    Button {
                        mergedPage.skipAllPages()
                        dismiss() }
                    label: {
                        
                        Image(systemName: "rectangle.portrait.slash")
                        
                    }
                    .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 156))
                    .onHover { hovering in hoveredButton = hovering ? 156 : nil }
                    
                }
                .disabled(mergedPage.pageItems.count <= mergedPage.skippedPages)
                .opacity(mergedPage.pageItems.count <= mergedPage.skippedPages ? 0.25 : 1)
                
                GridRow {
                    if mergedPage.pageItems.count < 2 {
                        Text("Delete This Page")
                    }
                    else {
                        Text("Delete This Merged Page")
                    }
                    Button {
                        document.pageSections.removeAll(where: { mergedPage in
                            mergedPage == self.mergedPage
                        })
                      
                        dismiss() }
                    label: { Image(systemName: "trash")   }
                        .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 150))
                        .onHover { hovering in
                            hoveredButton = hovering ? 150 : nil
                        }
                        .help("Delete page")
                    
                    
                }
                
                
            }
                
            }
            .frame(maxWidth: .infinity)
            .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.blue, lineWidth: 3) )
            
            
            if document.pageSections.count > 1 {
                Divider()
                
                GroupBox {
                
                    if document.pageSections.count == 2 {
                        Text("Other Merged Page")
                    }
                    else {
                        Text("\(document.pageSections.count - 1 ) other Merged Pages")
                    }
                    
                    Grid(alignment: .trailing) {
                        
                        GridRow {
                            
                            if document.totalPageItems == 2 {
                                Text("Include Both Page Items")
                            }
                            else {
                                Text("Include All \(document.totalPageItems) Page Items")
                            }
                            
                            
                            Button {
                                document.includeAllPages()
                                dismiss() }
                            label: {
                                
                                Image(systemName: "rectangle.portrait.slash")
                                
                            }
                            .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 153))
                            .onHover { hovering in hoveredButton = hovering ? 153 : nil }
                            
                        }
                        .disabled(mergedPage.skippedPages == 0)
                        .opacity(mergedPage.skippedPages == 0 ? 0.25 : 1)
                        
                        GridRow {
                            if document.totalPageItems == 2 {
                                Text("Skip Both Page Items")
                            }
                            else {
                                Text("Skip All \(document.totalPageItems) Page Items")
                            }
                            
                            Button {
                                
                                document.skipAllPages()
                                dismiss() }
                            label: {
                                
                                Image(systemName: "rectangle.portrait.slash")
                                
                            }
                            .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 176))
                            .onHover { hovering in hoveredButton = hovering ? 176 : nil }
                            
                        }
                        .disabled(mergedPage.pageItems.count <= mergedPage.skippedPages)
                        .opacity(mergedPage.pageItems.count <= mergedPage.skippedPages ? 0.25 : 1)
                        
                    GridRow {
                        if document.pageSections.count == 2 {
                            Text("Delete Both Merged Pages")
                        }
                        else {
                            Text("Delete All \(document.totalPageItems) Merged Pages")
                        }
                        Button {
                            document.pageSections.removeAll()
                            document.refreshMergedDocument()
                            dismiss() }
                        label: { Image(systemName: "trash")   }
                            .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 150))
                            .onHover { hovering in
                                hoveredButton = hovering ? 150 : nil
                            }
                            .help("Delete page")
                        
                    }
                       
                    }
                }
                
                
            }
            
            Divider()
            
            GroupBox {
                Text("Julie d'Prax = \(mergedPage.pageItems.count) Source Pages")
            }
            
        }
        .padding(.top, 20)
        .padding(.horizontal, 10)
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
 //       .popoverTip(theTip)
    }
}

struct PageItemPopover: View {
    let pageItem: PageItem
    @Environment(\.dismiss) private var dismiss
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State private var hoveredButton: Int? = nil
    
    var theTip = PageItemTip()
    
    var body: some View {
        
        VStack {
            Text(pageItem.name)
            Divider()
            GroupBox {
   
                
                Grid(alignment: .trailing) {
                    GridRow {
                        if prax.optionKeyPressed {
                            Text(pageItem.skipped ? "Include All Except This Page" : "Skip All Except This Page")
                        }
                        else {
                            Text(pageItem.skipped ? "Include This Page" : "Skip This Page")
                        }

                        Button {
                            document.clickedSkipPageButton(pageItem)
                            dismiss() }
                        label: {
                            if pageItem.skipped {
                                Image(systemName: "rectangle.portrait.slash.fill")
                            }
                            else {
                                Image(systemName: "rectangle.portrait.slash")
                            }
                        }
                        .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 126))
                        .onHover { hovering in hoveredButton = hovering ? 126 : nil }
                        
                    }
                    
                    GridRow {
                        Text("Merge Mode")
                        Button { document.clickedMergeModeButton(pageItem)
                            dismiss() }
                        label: {
                            switch(pageItem.merge) {
                            case .mergeSkip:
                                Image(systemName: "rectangle.portrait.slash.fill")
                             case .mergeDown:
                                Image(systemName: "arrow.down.document.fill")
                            case .mergeRight:
                                Image(systemName: "inset.filled.trailinghalf.arrow.trailing.rectangle")
                            }
                        }
                        .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 121))
                        .onHover { hovering in hoveredButton = hovering ? 121 : nil }
                        .help("Merge page mode")
                    }
                    
                    GridRow {
                        Text("Set Width Guide")
                        Button {
                            document.clickedGuidePageButton(pageItem)
                            dismiss() }
                        label: { Image(systemName: "ruler") }
                        .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 124, isFocused: false))
                        .onHover { hovering in hoveredButton = hovering ? 124 : nil }
                        .help("Set width guide")
                        
                        
                    }
                    GridRow {
                        Text("Delete page")
                        Button {
                            document.clickedDeletePageButton(pageItem)
                            dismiss() }
                        label: { Image(systemName: "trash")   }
                        .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 120))
                        .onHover { hovering in
                            hoveredButton = hovering ? 120 : nil
                        }
                        .help("Delete page")
                        
                        
                    }
                }

            }
            .padding(5)
            Button {
                dismiss()
            } label: {
                Label("Ok", systemImage: ("checkmark"))
            }
            
        }
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
 //       .popoverTip(theTip)
    }
}



