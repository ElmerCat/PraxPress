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


struct InspectorView: View {
    @Environment(PraxModel.self) private var prax
    @State private var hovering: Bool = false
    var body: some View {
        @Bindable var prax = prax
        VStack {
            
            
            Text("Julie d'Prax")
                .frame(maxWidth: .infinity, alignment: .init(horizontal: .leading, vertical: .top))
            
            
        }
        .padding(20)
        
        
    }
}



struct DocumentEditingLeadingEdge: View {
    //  @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    @State private var viewWidth: CGFloat = 20
    @State private var auxilliaryOpacity: CGFloat = 0.0
    
    @State private var hoverLocation: CGPoint = .zero
    @State private var isHovering = false
    @State private var paddingTop = 20.0
    @State private var imageAngle = 0.0
    
    var body: some View {
        @Bindable var prax = praxModel
        
        GeometryReader { geometry in
            
            
            ZStack {
                
                
                VStack {
                    
                    
                    GroupBox {
                        
                        
                        Image(systemName: prax.columnVisibility == .detailOnly ?  "building.columns" : "building.columns.fill")
                        
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .padding(0)
                            .padding(.top, 5)
                            .padding(.leading, 5)
                            .frame(width: viewWidth, height: viewWidth)
                            .symbolEffect(.bounce.up.byLayer, options: .nonRepeating)
                            .foregroundColor(prax.columnVisibility == .detailOnly ? .blue : .white)
                        Spacer()
                        
                        Image("PraxPress").resizable().aspectRatio(contentMode: .fit)
                            .rotationEffect(Angle(degrees: imageAngle))
                            .padding(.leading, 5)
                        //   .padding(.top, hoverOffset)
                        //.zIndex(997)
                            .frame(width: viewWidth, height: viewWidth)
                    }
                    
                    
                    Spacer()
                    
                }
                Rectangle().background(Color.blue).opacity(auxilliaryOpacity)
                    .onTapGesture {
                        withAnimation {
                            prax.columnVisibility = prax.columnVisibility == .detailOnly ? .all : .detailOnly
                        }
                    }.zIndex(998)
            }
            .frame(minWidth: viewWidth, maxWidth: viewWidth, maxHeight: .infinity)
            
            
            .onHover { hovering in
                withAnimation {
                    viewWidth = hovering ? 30 : 20
                    
                    imageAngle = hovering ? -3000 : 0
                    paddingTop = hovering ? geometry.size.width / 2 : 20
                    
                    auxilliaryOpacity = hovering ? 0.01 : 0.0
                    
                }
            }
            
            /*           .onContinuousHover { phase in
             switch phase {
             case .active(let location):
             hoverLocation = location
             
             isHovering = true
             case .ended:
             isHovering = false
             }
             }
             .overlay {
             Rectangle()
             .frame(width: 50, height: 50)
             .foregroundColor(isHovering ? .green : .blue)
             .offset(x: hoverLocation.x, y: hoverLocation.y)
             }
             
             */
            
        }
        
        
        
        
        
    }
}

struct AnyOldView: View {
    //  @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    var body: some View {
        @Bindable var prax = praxModel
        
        Group {
            HStack {
                Text("Any Old View")
                    .font(.headline)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .contentShape(.rect)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                    .foregroundStyle(Color.prax)
            }
        }
    }
}


struct PraxSegmentedControl<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String {
    
    // The selection is now a @Binding so it can be changed from the parent view
    @Binding var selection: T
    private let items: [T] = T.allCases as! [T]
    @Namespace private var animation
    
    // We add a function to get the color for a specific item
    let colorProvider: (T) -> Color
    let iconProvider: (T) -> String
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                HStack {
                    Image(systemName: iconProvider(item)).font(.default).padding(5)
                    Text(item.rawValue).font(.caption)
                }
                .padding(.horizontal, 5)
                .foregroundStyle(selection == item ? .white : .primary.opacity(0.7))
                .background {
                    if selection == item {
                        RoundedRectangle(cornerRadius: 5)
                    }
                }
                .onTapGesture {
                    withAnimation(.bouncy) {
                        selection = item
                    }
                }
            }.padding(2)
        }
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.cyan, lineWidth: 2))
        
      //  .background(.primary.opacity(0.08), in: .capsule)
        //    .padding(.horizontal, 10)
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



struct OptionKeyPressedToolbarItem: View {
    //  @Environment(MergedPDFDocument.self) var document
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

#Preview {
    PraxGradient(3)
}
