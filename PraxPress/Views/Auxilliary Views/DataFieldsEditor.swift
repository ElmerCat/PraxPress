//
//  DataFieldsEditor.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/2/26.
//

import SwiftUI


struct DataFieldsEditor: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: String?
    @State private var hoveredButton: String?
    @State private var setTitleKey = ""
    
    var body: some View {
        @Bindable var prax = prax
        if let pageItem = prax.selectedPageItem {
            
            VStack {
                GroupBox {
                    HStack {
                        Text("PraxPress Data Fields")
                            .font(Font.custom("BrushScriptMT", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        Button { dismiss() } label: { Text("Close") }
                    }
                }
                GroupBox {
                   
                    Grid(alignment: .trailing) {
                        ForEach(pageItem.dataFields.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            
                            GridRow {
                                Text(key)
                                Spacer()
                                
                                TextField(key, text: Binding<String>(
                                    get: { value.stringValue ?? "" },
                                    set: { newValue in
                                        pageItem.dataFields[key] = .string(newValue)
                                        if setTitleKey == key {
                                            prax.document.exportFilenameBody = newValue
                                        }
                                    }
                                ) )
                                .focused($focusedField, equals: key)
                                .frame(minWidth: 50, maxWidth: 600)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                                Spacer()
                                
                                Button("Copy") {
                                    let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(value.stringValue ?? "", forType: .string)
                                }
                                .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == key, isFocused: false))
                                .onHover { hovering in
                                    hoveredButton = hovering ? key : nil
                                }
                                .frame(minWidth: 40)
                                
                                Button("Set Title") {
                                    if setTitleKey == key { setTitleKey = "" }
                                    else { setTitleKey = key }
                                }
                                .buttonStyle(SelectableButtonStyle(isSelected: setTitleKey == key, isHovering: hoveredButton == key, isFocused: false))
                                .onHover { hovering in
                                    hoveredButton = hovering ? key : nil
                                }
                                .frame(minWidth: 40)
                                
                            }
                        }
                    }
                    .focusable()
                }
                .focusSection()
                .defaultFocus($focusedField, pageItem.dataFields.first?.key)
                .padding(20)
                
                GroupBox {
                    HStack {
                        Text("Julie d'Prax")
                            .font(Font.custom("BrushScriptMT", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                       
                    }
                }
            }
        }
        else {
            EmptyView()
        }
     }
}

