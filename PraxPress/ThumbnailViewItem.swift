//
//  ThumbnailViewItem.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/5/26.
//

import Cocoa
import PDFKit
import AppKit
import SwiftUI
import Observation

class ThumbnailViewItem: NSCollectionViewItem {
    var pdfModel: PDFModel
    var viewModel: ViewModel

    private var observationTask: Task<Void, Never>?
    
    required override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        pdfModel = PDFModel.shared
        viewModel = ViewModel.shared

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        pdfModel = PDFModel.shared
        viewModel = ViewModel.shared

        super.init(coder: coder)
    }
    
    
    
    @objc dynamic var text: String? = "Louise"
    @objc dynamic var image: NSImage?
    
   override func viewDidLoad() {
        super.viewDidLoad()
        
        print("ThumbnailViewItem viewDidLoad")
       
       observationTask = Task {
           for await _ in Observations({ self.pdfModel.currentIndex })
           {
              
               print("ThumbnailViewItem observationTask currentIndex  ", self.pdfModel.currentIndex)

               
           }
       }
       
        // Do view setup here.
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        
        print("ThumbnailViewItem viewWillLayout")

    }
    

}
