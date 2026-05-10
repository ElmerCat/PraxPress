//
//  Tips.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/19/26.
//


// import SwiftUI
import TipKit

struct FilenamePrefixTip: Tip {
    var title: Text {
        Text("Export Filename Prefix") }
    var message: Text? {
        Text("Add a frequently used prefix before the entered Export Filename") }
    var image: Image? {
        Image(systemName: "rectangle.portrait.and.arrow.right") }
}

struct PageItemTip: Tip {
    var title: Text {
        Text("Page Item Options")  }
    var message: Text? {
        Text("Hide or Delele page items") }
    var image: Image? {
        Image(systemName: "doc.badge.gearshape") }
}
