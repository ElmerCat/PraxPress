//
//  ThumbnailViewController.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/5/26.
//

import Cocoa
import PDFKit
import AppKit
import SwiftUI
import Observation

extension NSUserInterfaceItemIdentifier {
    static let thumbnailViewItem = NSUserInterfaceItemIdentifier("ThumbnailViewItem")
}

class ThumbnailViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    @Bindable var viewModel:  ViewModel
    @Bindable var pdfModel: PDFModel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(with viewModel: ViewModel, pdfModel: PDFModel) {
        self.viewModel = viewModel
        self.pdfModel = pdfModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    
    weak var pdfView: PDFView? {
        didSet {
            
            print("ThumbnailViewController pdfView didSet")
            
          //  reloadData()
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Uwandua numberOfItemsInSection ", section)
        return pdfModel.pdfDocument?.pageCount ?? 0
        
    }
    
    var thumbnailSize: CGSize = CGSize(width: 120, height: 160)

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        print("Uwandua itemForRepresentedObjectAt ", indexPath)
        
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ThumbnailViewItem"), for: indexPath) as! ThumbnailViewItem
        
        if let page = pdfView?.document?.page(at: indexPath.item) {
            item.image = page.thumbnail(of: thumbnailSize, for: .cropBox)
            item.text = "\(indexPath.item + 1)"
        } else {
            item.image = nil
            item.text = "?"
        }
        
        item.pdfModel = pdfModel
        item.viewModel = viewModel
        return item
        
   //     if let pdfView = pdfView {
   //         if let page: PDFPage = pdfView.document?.page(at: indexPath.index) {
   //             item.pdfPage = page
   //         }
   //     }
        
        return item
        
    }
    

    override func viewDidLoad() {
        
        
        super.viewDidLoad()
        
        let nib = NSNib(nibNamed: "ThumbnailViewItem", bundle: nil)!
        thumbnailView.register(nib, forItemWithIdentifier: .thumbnailViewItem)

        
        thumbnailView.dataSource = self
        thumbnailView.delegate = self
        
        // (Optional) Configure layout, e.g., NSCollectionViewFlowLayout
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 100.0, height: 100.0)
        thumbnailView.collectionViewLayout = flowLayout
        
        // Do view setup here.
    }
    
 
    
    @IBOutlet weak var thumbnailView: NSCollectionView!
}
