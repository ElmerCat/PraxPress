//
//  DataFieldsEditor.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/2/26.
//

import SwiftUI


struct DataFieldsEditor: View {
    @Bindable var prax: PraxModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: String?
    @State private var hoveredButton: String?
    
//    let praxTheme = PraxTheme(.erika)
   
    var body: some View {
        
        if !prax.selectedPageItems.isEmpty,
           let indexPath = prax.selectedPageItems.first,
           let pageItem = prax.document.pageItem(indexPath: indexPath) {
            
            VStack {
                GroupBox {
                    HStack {
                        Text("PraxPress Data Fields")
                            .font(Font.custom("BrushScriptMT", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        Button {
                            dismiss()
                        }
                        label: {
                                Text("Close")
                        }
                       
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
                                        pageItem.dataFields[key] = .string(newValue) }
                                ) )

                             //   .focusable(interactions: .automatic)
                                .focused($focusedField, equals: key)
                         //       .onSubmit {
                                    
                        //            print("Julie d'Prax stringValue: ", value.stringValue)
                     //               if index < keys.count - 1 { focusedField = keys[index + 1]}
                     //               else { focusedField = keys[0] }
                           //     }
                                
                                .frame(minWidth: 50, maxWidth: 600)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                                
                                Spacer()
                                
                                Button("Copy") {
                                    let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(value.stringValue ?? "", forType: .string)
                                }
                               // .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == index, isFocused: false))
                                .onHover { hovering in
                                    hoveredButton = hovering ? key : nil
                                }
                                
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
     }
}

