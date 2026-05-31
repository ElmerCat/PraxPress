//
//  Popovers.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/19/26.
//

import SwiftUI
import PDFKit
import TipKit


struct Stub_PageItemPopover: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    var body: some View {
        @Bindable var prax = prax
        
 //       if let pageItem = prax.selectedPageItem?.mergedPage.dataFieldPage {
        if let pageItem = prax.selectedPageItem {
            Text(pageItem.name)
        }
        else {
            EmptyView()
        }
    }
}

struct DatePopover: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
    
    @State private var selectedDate = Date()
//    @State private var dateString = ""
 
    func dateFromPageItemDataField(_ pageItem: PageItem) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy" // Match your input string format
        return formatter.date(from:  ((pageItem.dataFields.contains(where: { $0.key == "Date" }) ? pageItem.dataFields["Date"]!.stringValue : "1/1/2026")!))
    }
    
//    dateFormatter.dateFormat = "d.M.yy"
   
    var body: some View {
        @Bindable var prax = prax
        
        
        if let pageItem = prax.selectedPageItem?.mergedPage.dataFieldPage {
            GroupBox {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .onChange(of: selectedDate) {
                    // Format to a string on every change
                    pageItem.dataFields["Date"] = .string(selectedDate.formatted(
                        .verbatim("\(month: .defaultDigits)/\(day: .defaultDigits)/\(year: .twoDigits)",
                        timeZone: .current,
                        calendar: .current)
                    ))
                }
                .datePickerStyle(.graphical)
            }
            

            .onHover { hovering in if !hovering { dismiss() } }
            .padding(20)
            
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 10) )
            .foregroundColor(Color("PraxColor"))
            .background(PraxGradient(1).ignoresSafeArea())
            
            
            .onAppear(perform: {
                if let pageItem = prax.selectedPageItem?.mergedPage.dataFieldPage {
                    selectedDate = dateFromPageItemDataField(pageItem) ?? Date()
                }
            })
            
        }
        
        else { EmptyView() }
    }
}

struct VendorAccountsPopover: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    @FocusState private var focusedField: String?
   
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.selectedPageItem?.mergedPage.dataFieldPage {

            GroupBox {
                
                Grid {
                    GridRow {
                        HStack {
                            Text("Vendor:")
                            TextField("Vendor", text: Binding<String>(
                                get: { pageItem.dataFields["Vendor"]?.stringValue ?? "" },
                                set: { newValue in
                                    pageItem.dataFields["Vendor"] = .string(newValue)
                                }
                            ) )
                            //    .focused($focusedField, equals: "Amount")
                            .focused($focusedField, equals: "Vendor")
                            
                        }
                    }
                    GridRow {
                        HStack {
                            Text("G/L Account:")
                            TextField("GLAccount", text: Binding<String>(
                                get: { pageItem.dataFields["GLAccount"]?.stringValue ?? "" },
                                set: { newValue in
                                    pageItem.dataFields["GLAccount"] = .string(newValue.filter(\.isNumber))
                                }
                            ) )
                            //    .focused($focusedField, equals: "Amount")
                            .focused($focusedField, equals: "GLAccount")
                        }
                    }
                    GridRow {
                        HStack {
                            Text("Cost Object:")
                            TextField("CostObject", text: Binding<String>(
                                get: { pageItem.dataFields["CostObject"]?.stringValue ?? "" },
                                set: { newValue in
                                    pageItem.dataFields["CostObject"] = .string(newValue.filter(\.isNumber))
                                }
                            ) )
                            //    .focused($focusedField, equals: "Amount")
                            .focused($focusedField, equals: "CostObject")
                        }
                    }
                }
                

            }
            .padding(20)
            .onHover { hovering in if !hovering { dismiss() } }
            .frame(minWidth: 350, maxWidth: 350)
            .multilineTextAlignment(.trailing)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onSubmit { dismiss() }
            .onKeyPress(.tab, action: {
                switch(focusedField) {
                case "Vendor":
                    focusedField = "GLAccount"
                case "GLAccount":
                    focusedField = "CostObject"
                default:
                    dismiss()
                }
                
                return .handled
            })
                
            }
        else {
            EmptyView()
        }
    }
}

struct DescriptionPopover: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
   
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.selectedPageItem?.mergedPage.dataFieldPage {

            GroupBox {
                TextEditor(text: Binding<String>(
                    get: { pageItem.dataFields["Description"]?.stringValue ?? "" },
                    set: { newValue in
                        pageItem.dataFields["Description"] = .string(newValue)
                    }
                ) )
                //    .focused($focusedField, equals: "Amount")
                .focused($isFocused)
                .onChange(of: isFocused) { oldValue, newValue in
                    if newValue {
                        // Set selection to the entire range of the text
                        //        .selection = .init(pageItem.dataFields["Amount"] .startIndex..<pageItem.dataFields["Amount"] .endIndex)
                    }
                }
            }
                
                .frame(width: 400, height: 200)
                .multilineTextAlignment(.leading)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit { dismiss() }
                .onKeyPress(.tab, action: {
                    dismiss()
                    return .handled
                })
                .padding(20)
                .onHover { hovering in if !hovering { dismiss() } }
        }
        
        else {
            EmptyView()
        }
    }
}

struct DocumentNumberPopover: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
    @State private var hoveredButton: Int?
   
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.selectedPageItem?.mergedPage.dataFieldPage {

            HStack {
                Button { if let string = NSPasteboard.general.string(forType: .string){
                    pageItem.dataFields["DocumentNumber"] = .string(string.filter(\.isNumber)) } }
                 label: {
                     Image(systemName: "arrow.right.page.on.clipboard").padding(0)
                }
                 .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 422))
                 .onHover { hovering in hoveredButton = hovering ? 422: nil }
                TextField("DocumentNumber", text: Binding<String>(
                    get: { pageItem.dataFields["DocumentNumber"]?.stringValue ?? "" },
                    set: { newValue in
                        pageItem.dataFields["DocumentNumber"] = .string(newValue.filter{Prax.decimals.contains($0)} )
                    }
                ) )
                //    .focused($focusedField, equals: "Amount")
                .focused($isFocused)
                .onChange(of: isFocused) { oldValue, newValue in
                    if newValue {
                        // Set selection to the entire range of the text
                        //        .selection = .init(pageItem.dataFields["Amount"] .startIndex..<pageItem.dataFields["Amount"] .endIndex)
                    }
                }
            }
                
                .frame(minWidth: 150, maxWidth: 150)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit { dismiss() }
                .onKeyPress(.tab, action: {
                    dismiss()
                    return .handled
                })
                .onHover { hovering in if !hovering { dismiss() } }
            }
        else {
            EmptyView()
        }
    }
}

struct AmountPopover: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
   
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.selectedPageItem?.mergedPage.dataFieldPage {
            
            VStack {
                GroupBox {
                    TextField("Amount", text: Binding<String>(
                        get: { pageItem.dataFields["Amount"]?.stringValue ?? "" },
                        set: { newValue in
                            pageItem.dataFields["Amount"] = .string(newValue.filter{Prax.decimals.contains($0)} )
                            if prax.useAmountForFilename {
                                prax.document.exportFilenameBody = newValue.filter(\.isNumber)
                            }
                        }
                    ) )
                    //    .focused($focusedField, equals: "Amount")
                    .focused($isFocused)
                    .onChange(of: isFocused) { oldValue, newValue in
                        if newValue {
                            // Set selection to the entire range of the text
                    //        .selection = .init(pageItem.dataFields["Amount"] .startIndex..<pageItem.dataFields["Amount"] .endIndex)
                        }
                    }
                    
                    .frame(minWidth: 100, maxWidth: 100)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit { dismiss() }
                    .onKeyPress(.tab, action: {
                        dismiss()
                        return .handled
                    })
                }
                .padding()
                Toggle(isOn: $prax.useAmountForFilename) {
                    Text( "Use Amount for Filename")
                        .font(.system(size: 8))
                }
                    .toggleStyle(.switch)
                    .padding()
                    .controlSize(ControlSize.mini)
                    .onTapGesture { prax.useAmountForFilename.toggle() }
                
                
            }
            .onHover { hovering in if !hovering { dismiss() } }
            .padding()
            
        }
        else {
            EmptyView()
        }
    }
}






struct DeletePopover: View {
//    let mergedPage: MergedPage
    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    
    @State private var hoveredButton: Int? = nil
    @State private var imageAngle = 0.0
    
  //  var theTip = FilenamePrefixTip()

   
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
                            prax.document.mergedPages.removeAll()
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
    @Environment(PraxModel.self) private var prax
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State private var hoveredButton: Int? = nil
    @State private var imageAngle = 0.0
    
    var theTip = FilenamePrefixTip()

    
    var savedPrefixes = ["Amazon-", "Costco-", "ezCater-", "airfare-", "conference-", "meal-", "taxi-" ]
    
    var body: some View {
        @Bindable var prax = prax
        @Bindable var document = prax.document
        
        
        
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

                    if document.mergedPages.count > 1 {
                        Text("\(document.mergedPages.count) Merged Pages from \(document.totalPageItems) Page Items")
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
                        document.mergedPages.removeAll(where: { mergedPage in
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
            
            
            if document.mergedPages.count > 1 {
                Divider()
                
                GroupBox {
                
                    if document.mergedPages.count == 2 {
                        Text("Other Merged Page")
                    }
                    else {
                        Text("\(document.mergedPages.count - 1 ) other Merged Pages")
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
                        if document.mergedPages.count == 2 {
                            Text("Delete Both Merged Pages")
                        }
                        else {
                            Text("Delete All \(document.totalPageItems) Merged Pages")
                        }
                        Button {
                            document.mergedPages.removeAll()
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



/*
 
 struct ImageInspectingPopover: View {
 @Environment(\.dismiss) private var dismiss
 @Environment(PraxModel.self) private var prax
 
 @AppStorage("import-sizing-mode") private var importSizingModeRaw: String = PraxModel.ImportSizingMode.fileSizeLimit.rawValue
 @AppStorage("import-size-limit") private var importSizeLimitKB: Int = 1024
 @AppStorage("import-target-width-inches") private var importTargetWidthInches: Double = 0
 @AppStorage("import-target-height-inches") private var importTargetHeightInches: Double = 0
 
 @State private var imageAngle = 0.0
 //  @State private var options = PraxModel.ImageImportOptions()
 @State private var previewImage: NSImage?
 
 @State private var sourcePixelSize: CGSize = .zero
 @State private var outputPixelSize: CGSize = .zero
 @State private var outputInches: CGSize = .zero
 @State private var estimatedPDFKB: Int?
 @State private var loadedURLForSource: URL?
 @State private var importInProgress = false
 
 private let minRemainingCrop = 0.05
 
 /*    private var importSizingMode: PraxModel.ImportSizingMode {
  get { PraxModel.ImportSizingMode(rawValue: importSizingModeRaw) ?? .fileSizeLimit }
  set { importSizingModeRaw = newValue.rawValue }
  }
  
  private var importSizingModeBinding: Binding<PraxModel.ImportSizingMode> {
  Binding(
  get: { importSizingMode },
  set: { importSizingMode = $0 }
  )
  }
  */
 /*
  private var effectiveOptions: PraxModel.ImageImportOptions {
  var o = options
  o.sizingMode = prax.importImageOptions.sizingMode
  
  switch prax.importImageOptions.sizingMode {
  case .fileSizeLimit:
  o.sizeLimitKB = importSizeLimitKB > 0 ? importSizeLimitKB : nil
  o.targetWidthInches = nil
  o.targetHeightInches = nil
  
  case .targetInches:
  o.sizeLimitKB = nil
  o.targetWidthInches = importTargetWidthInches > 0 ? importTargetWidthInches : nil
  o.targetHeightInches = importTargetHeightInches > 0 ? importTargetHeightInches : nil
  
  }
  
  return o
  }
  */
 
 private var cropLeftBinding: Binding<Double> {
 Binding(
 get: { prax.importImageOptions.cropLeft },
 set: { prax.importImageOptions.cropLeft = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropRight) }
 )
 }
 
 private var cropRightBinding: Binding<Double> {
 Binding(
 get: { prax.importImageOptions.cropRight },
 set: { prax.importImageOptions.cropRight = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropLeft) }
 )
 }
 
 private var cropTopBinding: Binding<Double> {
 Binding(
 get: { prax.importImageOptions.cropTop },
 set: { prax.importImageOptions.cropTop = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropBottom) }
 )
 }
 
 private var cropBottomBinding: Binding<Double> {
 Binding(
 get: { prax.importImageOptions.cropBottom },
 set: { prax.importImageOptions.cropBottom = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropTop) }
 )
 }
 
 var body: some View {
 @Bindable var prax = prax
 
 VStack(spacing: 12) {
 GroupBox {
 HStack {
 Image("PraxPress")
 .resizable()
 .aspectRatio(contentMode: .fit)
 .frame(width: 20)
 .padding(3)
 .rotationEffect(.degrees(imageAngle))
 .onAppear { withAnimation { imageAngle -= (2 * 360) - 120 } }
 .onDisappear { withAnimation { imageAngle = 0 } }
 
 Text("Image Drop Inspector")
 Spacer()
 Toggle("Test on Next Drop", isOn: $prax.inspectNextImageDrop)
 .toggleStyle(.switch)
 }
 }
 
 GroupBox("Preview") {
 ZStack {
 if let previewImage {
 Image(nsImage: previewImage)
 .resizable()
 .aspectRatio(contentMode: .fit)
 .frame(maxWidth: .infinity, maxHeight: 320)
 } else {
 Text("No preview available")
 .frame(maxWidth: .infinity, minHeight: 220)
 }
 }
 }
 
 GroupBox("Import Size") {
 Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
 GridRow {
 Text("Size Limit:")
 HStack {
 TextField("", value: $importSizeLimitKB, format: .number)
 .frame(width: 90)
 Text("KB")
 }
 }
 
 GridRow {
 Text("Limit By:")
 Picker("", selection: $prax.importImageOptions.sizingMode) {
 Text("File Size").tag(PraxModel.ImportSizingMode.fileSizeLimit)
 Text("PDF Inches").tag(PraxModel.ImportSizingMode.targetInches)
 }
 .pickerStyle(.segmented)
 }
 
 if prax.importImageOptions.sizingMode == .fileSizeLimit {
 GridRow {
 Text("Size Limit:")
 HStack {
 TextField("", value: $importSizeLimitKB, format: .number)
 .frame(width: 90)
 Text("KB")
 }
 }
 
 GridRow {
 Text("Scale Down:")
 HStack {
 Slider(value: $prax.importImageOptions.scaleDown, in: 0.1...1.0, step: 0.01)
 Text("\(Int(prax.importImageOptions.scaleDown * 100))%")
 .frame(width: 50, alignment: .trailing)
 }
 }
 } else {
 GridRow {
 Text("PDF Width:")
 HStack {
 TextField("", value: $importTargetWidthInches, format: .number.precision(.fractionLength(0...2)))
 .frame(width: 90)
 Text("in")
 }
 }
 
 GridRow {
 Text("PDF Height:")
 HStack {
 TextField("", value: $importTargetHeightInches, format: .number.precision(.fractionLength(0...2)))
 .frame(width: 90)
 Text("in")
 }
 }
 }
 
 
 GridRow {
 Text("Scale Down:")
 HStack {
 Slider(value: $prax.importImageOptions.scaleDown, in: 0.1...1.0, step: 0.01)
 Text("\(Int(prax.importImageOptions.scaleDown * 100))%")
 .frame(width: 50, alignment: .trailing)
 }
 }
 
 GridRow {
 Text("Original:")
 Text(pxText(sourcePixelSize))
 .font(.system(.caption, design: .monospaced))
 }
 GridRow {
 Text("After Resize:")
 Text(pxText(outputPixelSize))
 .font(.system(.caption, design: .monospaced))
 }
 GridRow {
 Text("PDF Page Size:")
 Text(inchesText(outputInches))
 .font(.system(.caption, design: .monospaced))
 }
 GridRow {
 Text("Est. PDF Size:")
 Text(estimatedSizeText)
 .font(.system(.caption, design: .monospaced))
 }
 }
 }
 
 GroupBox("Crop (%)") {
 VStack {
 HStack {
 Text("Left")
 Slider(value: cropLeftBinding, in: 0...0.9, step: 0.01)
 Text("\(Int(prax.importImageOptions.cropLeft * 100))").frame(width: 36, alignment: .trailing)
 }
 HStack {
 Text("Right")
 Slider(value: cropRightBinding, in: 0...0.9, step: 0.01)
 Text("\(Int(prax.importImageOptions.cropRight * 100))").frame(width: 36, alignment: .trailing)
 }
 HStack {
 Text("Top")
 Slider(value: cropTopBinding, in: 0...0.9, step: 0.01)
 Text("\(Int(prax.importImageOptions.cropTop * 100))").frame(width: 36, alignment: .trailing)
 }
 HStack {
 Text("Bottom")
 Slider(value: cropBottomBinding, in: 0...0.9, step: 0.01)
 Text("\(Int(prax.importImageOptions.cropBottom * 100))").frame(width: 36, alignment: .trailing)
 }
 }
 }
 
 GroupBox("Adjustments") {
 VStack {
 HStack {
 Text("Brightness")
 Slider(value: $prax.importImageOptions.brightness, in: -0.5...0.5, step: 0.01)
 Text(prax.importImageOptions.brightness, format: .number.precision(.fractionLength(2)))
 .frame(width: 52, alignment: .trailing)
 }
 HStack {
 Text("Contrast")
 Slider(value: $prax.importImageOptions.contrast, in: 0.5...2.0, step: 0.01)
 Text(prax.importImageOptions.contrast, format: .number.precision(.fractionLength(2)))
 .frame(width: 52, alignment: .trailing)
 }
 HStack {
 Text("Exposure")
 Slider(value: $prax.importImageOptions.exposure, in: -2.0...2.0, step: 0.01)
 Text(prax.importImageOptions.exposure, format: .number.precision(.fractionLength(2)))
 .frame(width: 52, alignment: .trailing)
 }
 HStack {
 Text("Sharpness")
 Slider(value: $prax.importImageOptions.sharpness, in: 0.0...2.0, step: 0.01)
 Text(prax.importImageOptions.sharpness, format: .number.precision(.fractionLength(2)))
 .frame(width: 52, alignment: .trailing)
 }
 }
 }
 
 HStack {
 Button("Reset Controls") {
 prax.importImageOptions = .neutral
 }
 Spacer()
 Button("Cancel") {
 closeInspector()
 }
 Button("Import Image") {
 guard !importInProgress else { return }
 guard let url = prax.importSourceURL else {
 closeInspector()
 return
 }
 
 importInProgress = true
 defer { importInProgress = false }
 
 prax.addPageFromImageURL(
 url,
 at: prax.importDropIndexPath,
 options: prax.importImageOptions)
 closeInspector()
 }
 .keyboardShortcut(.defaultAction)
 .disabled(importInProgress)
 }
 }
 .padding(20)
 .frame(minWidth: 620, minHeight: 780)
 .background(PraxGradient(0).ignoresSafeArea())
 .foregroundColor(.white)
 .onAppear { refreshPreview() }
 .onChange(of: prax.importImageOptions) { refreshPreview() }
 .onChange(of: importSizingModeRaw) { refreshPreview() }
 .onChange(of: importSizeLimitKB) { refreshPreview() }
 .onChange(of: importTargetWidthInches) { refreshPreview() }
 .onChange(of: importTargetHeightInches) { refreshPreview() }
 }
 
 private func closeInspector() {
 prax.clearImageInspectorState()
 dismiss()
 }
 
 private func pixelSize(of image: NSImage) -> CGSize {
 if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first {
 return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
 }
 if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
 return CGSize(width: cg.width, height: cg.height)
 }
 return image.size
 }
 
 private func pxText(_ size: CGSize) -> String {
 guard size.width > 0, size.height > 0 else { return "—" }
 return "\(Int(size.width)) × \(Int(size.height)) px"
 }
 
 private func inchesText(_ size: CGSize) -> String {
 guard size.width > 0, size.height > 0 else { return "—" }
 return String(format: "%.2f × %.2f in", size.width, size.height)
 }
 
 private var estimatedSizeText: String {
 guard let estimatedPDFKB else { return "—" }
 return "\(estimatedPDFKB) KB"
 }
 
 private func refreshPreview() {
 guard let url = prax.importSourceURL else {
 previewImage = nil
 sourcePixelSize = .zero
 outputPixelSize = .zero
 outputInches = .zero
 estimatedPDFKB = nil
 loadedURLForSource = nil
 return
 }
 
 if loadedURLForSource != url {
 loadedURLForSource = url
 if let src = NSImage(contentsOf: url) {
 sourcePixelSize = pixelSize(of: src)
 } else {
 sourcePixelSize = .zero
 }
 }
 
 previewImage = prax.processedImageFromURL(url, options: prax.importImageOptions)
 
 guard let previewImage else {
 outputPixelSize = .zero
 outputInches = .zero
 estimatedPDFKB = nil
 return
 }
 
 outputPixelSize = pixelSize(of: previewImage)
 
 if let page = PDFPage(image: previewImage) {
 let bounds = page.bounds(for: .mediaBox)
 outputInches = CGSize(width: bounds.width / 72.0, height: bounds.height / 72.0)
 
 let doc = PDFDocument()
 doc.insert(page, at: 0)
 if let data = doc.dataRepresentation() {
 estimatedPDFKB = Int(ceil(Double(data.count) / 1024.0))
 } else {
 estimatedPDFKB = nil
 }
 } else {
 outputInches = .zero
 estimatedPDFKB = nil
 }
 }
 }
 
 */
