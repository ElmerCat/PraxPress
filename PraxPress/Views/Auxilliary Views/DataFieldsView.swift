//
//  DateFieldView.swift
//  
//
//  Created by Elmer Cat on 9/21/26.
//

import SwiftUI



struct DataFieldsView: View {
    var body: some View {
        
        GroupBox {
            Grid {
                GridRow {
                    DateFieldView()
                    VendorFieldView().gridCellColumns(2)
                    PcardHolderNameFieldView() }
                GridRow {
                    DocumentNumberFieldView()
                    GLAccountFieldView()
                    CostObjectFieldView()
                    AmountFieldView() }
                JustificationFieldView()
            }
        }
        .padding(10)
    }
}



struct DateFieldView: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    @State private var hovering = false
    @State private var showPicker = false
    @State private var selectedDate = Date()
 //   @State private var dateString: String = ""
      

    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.document.dataFieldPage {
            GroupBox {
                VStack(alignment: .leading) {
                    Text("Date")
                    TextField("Date", text: Binding<String>(
                        get: { pageItem.dataFields["Date"]?.stringValue ?? "" },
                        set: { newValue in
                            pageItem.dataFields["Date"] = .string(newValue)

                        }
                    ) )
                    .popover(isPresented: $showPicker, content: {
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .onChange(of: selectedDate) {
                                pageItem.dataFields["Date"] = .string(selectedDate.formatted(
                                    .verbatim("\(month: .defaultDigits)/\(day: .defaultDigits)/\(year: .twoDigits)",
                                              timeZone: .current,
                                              calendar: .current)))
                            }
                            .datePickerStyle(.graphical)
                            .padding(30)
                    })
                }
            }
            
            .onTapGesture { showPicker.toggle() }
            
            //       .onChange(of: dateString) { selectedDate = Date() }
            .onHover { hovering in self.hovering = hovering }
            
            
            .border(Color.gray, width: hovering ? 1 : 0)
            
            .background(PraxGradient(4))
            
            
            .onAppear(perform: {
                //        if let pageItem = prax.document.dataFieldPage {
                //    dateString = pageItem.dataFields["Date"]!.stringValue ?? "11/22/3333"
        //        selectedDate = dateFromPageItemDataField(pageItem) ?? Date()
                //         }
            })
            
        }
    }
}

struct PcardHolderNameFieldView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
    @State private var hovering = false
    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.document.dataFieldPage {
            GroupBox {
                VStack(alignment: .leading) {
                    
                    Text("PcardHolderName")
                    TextField("PcardHolderName", text: Binding<String>(
                        get: { pageItem.dataFields["PcardHolderName"]?.stringValue ?? "" },
                        set: { newValue in
                            pageItem.dataFields["PcardHolderName"] = .string(newValue)
                        }
                    ) )
                }
            }
            
            .onHover { hovering in self.hovering = hovering }
            
            
            .border(Color.gray, width: hovering ? 1 : 0)
            .background(PraxGradient(4))
        }
            
        
       
        
    }
}


struct VendorFieldView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
    @State private var hovering = false
    
    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.document.dataFieldPage {
            GroupBox {
                VStack(alignment: .leading) {
                    Text("Vendor")
                    TextField("Vendor", text: Binding<String>(
                        get: { pageItem.dataFields["Vendor"]?.stringValue ?? "" },
                        set: { newValue in
                            pageItem.dataFields["Vendor"] = .string(newValue)
                        }
                    ) )
                }
            }
            
            .onHover { hovering in self.hovering = hovering }
            
            
            .border(Color.gray, width: hovering ? 1 : 0)
            .background(PraxGradient(4))
        }
    }
}

struct DocumentNumberFieldView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
    @State private var hovering = false
    
    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.document.dataFieldPage {
            GroupBox {
                VStack(alignment: .leading) {
                    Button { if let string = NSPasteboard.general.string(forType: .string){
                        pageItem.dataFields["DocumentNumber"] = .string(string.filter(\.isNumber)) } }
                    label: {
                        Image(systemName: "arrow.right.page.on.clipboard").padding(0)
                    }
                    .buttonStyle(PraxButtonStyle(isHovering: hovering))
                    .onHover { hovering in self.hovering = hovering }
                    Text("Document #")
                    TextField("DocumentNumber", text: Binding<String>(
                        get: { pageItem.dataFields["DocumentNumber"]?.stringValue ?? "" },
                        set: { newValue in
                            pageItem.dataFields["DocumentNumber"] = .string(newValue.filter{Prax.decimals.contains($0)} )
                        }
                    ) )
                }
            }
            
            .onHover { hovering in self.hovering = hovering }
            
            
            .border(Color.gray, width: hovering ? 1 : 0)
            .background(PraxGradient(4))
        }
    }
}

struct CostObjectFieldView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
    @State private var hovering = false
    
    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.document.dataFieldPage {
            GroupBox {
                VStack(alignment: .leading) {
                    Text("CostObject")
                    TextField("CostObject", text: Binding<String>(
                        get: { pageItem.dataFields["CostObject"]?.stringValue ?? "" },
                        set: { newValue in
                            pageItem.dataFields["CostObject"] = .string(newValue.filter{Prax.decimals.contains($0)} )
                        }
                    ) )
                }
            }
            
            .onHover { hovering in self.hovering = hovering }
            
            
            .border(Color.gray, width: hovering ? 1 : 0)
            .background(PraxGradient(4))
        }
    }
}


struct GLAccountFieldView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
    @State private var hovering = false
    
    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.document.dataFieldPage {
            
            GroupBox(content: {
                TextField("GLAccount", text: Binding<String>(
                    get: { pageItem.dataFields["GLAccount"]?.stringValue ?? "" },
                    set: { newValue in
                        pageItem.dataFields["GLAccount"] = .string(newValue.filter{Prax.decimals.contains($0)} )
                    }
                ) )
            }, label: {Text("GL Account")})
            .onHover { hovering in self.hovering = hovering }
            .groupBoxStyle(PraxGroupBoxStyle(isHovering: hovering))
        }
    }
}
struct JustificationFieldView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
    @State private var hovering = false
    
    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.document.dataFieldPage {
            GroupBox {
                VStack(alignment: .leading) {
                    Text("Justification")
                    TextEditor(text: Binding<String>(
                        get: {
                            pageItem.dataFields["Description"]?.stringValue ?? "" },
                        set: { newValue in
                            pageItem.dataFields["Description"] = .string(newValue)
                        }
                    ))
                    Button {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(pageItem.dataFields["Description"]?.stringValue ?? "" , forType: .string)
                    }
                    label: {
                        Image(systemName: "arrow.up.page.on.clipboard").padding(0)
                    }
                    .buttonStyle(PraxButtonStyle(isHovering: hovering))
                    .onHover { hovering in self.hovering = hovering ? true : false }
                    
                    //     .controlSize(.mini)
                    .padding(0)
                   
                }
            }
            
            .onHover { hovering in self.hovering = hovering }
            
            
            .border(Color.gray, width: hovering ? 1 : 0)
            .background(PraxGradient(4))
            
            .frame(height: 100)
        }
    }
}


struct AmountFieldView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var isFocused: Bool
    @State private var hovering = false
    
    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.document.dataFieldPage {
            GroupBox {
                VStack(alignment: .leading) {
                    Text("Amount")
                    TextField("Amount", text: Binding<String>(
                        get: { pageItem.dataFields["Amount"]?.stringValue ?? "" },
                        set: { newValue in
                            pageItem.dataFields["Amount"] = .string(newValue.filter{Prax.decimals.contains($0)} )
                        }
                    ) )
                }
            }
            
            .onHover { hovering in self.hovering = hovering }
            
            
            .border(Color.gray, width: hovering ? 1 : 0)
            .background(PraxGradient(4))
        }
    }
}



