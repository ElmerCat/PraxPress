//
//  PraxModel+Utility.swift
//  PraxPress
//
//  Created by Elmer Cat on 9/27/26.
//

import SwiftUI
import PDFKit

extension PraxModel {
    
    
    func scrollViewParameters() -> (axes: Axis.Set, margin: CGFloat) {
        let viewWidth = mergedViewSize.width
        let documentWidth = document.maxWidth
        let scaledWidth = documentWidth * mergedViewScaleFactor
        let axes: Axis.Set
        let margin: CGFloat
        
        if viewWidth > scaledWidth {
            axes = [.vertical]
            margin = (viewWidth - scaledWidth) / 2
        }
        else {
            axes = [.horizontal, .vertical]
            margin = 0
        }
        return (axes, margin)
    }
    
    
    func scaleFactorFor(documentSize: CGSize, inViewSize viewSize: CGSize, direction: ViewScaleMode = .fit, viewMargin: CGSize = CGSize(width: 30, height: 10)) -> CGFloat {
        
        let viewSize = viewSize - viewMargin
        let verticalScale = viewSize.height / documentSize.height
        let horizontalScale = viewSize.width / documentSize.width
        
        switch direction {
        case .vertical: return verticalScale
        case .horizontal: return horizontalScale
        default: return min(verticalScale, horizontalScale)
            
        }
    }

    func scaleEditorView(_ direction: ViewScaleMode = .fit, viewMargin: CGSize = CGSize(width: 30, height: 10)) {

        let documentSize = pdfDocumentSize(document.editingPDFDocument)
        guard documentSize.width > 0, documentSize.height > 0 else { return }
        
        editorViewScaleMode = direction
        
        let viewSize = editorViewSize - viewMargin
        let verticalScale = viewSize.height / documentSize.height
        let horizontalScale = viewSize.width / documentSize.width
        
        if direction == .fit {
            editorViewFitMode = verticalScale < horizontalScale ? .vertical : .horizontal
        }
        else {
            editorViewFitMode = direction
        }
        

        let scaleFactor: CGFloat; switch direction {
            case .vertical: scaleFactor = verticalScale
            case .horizontal: scaleFactor = horizontalScale
            default: scaleFactor = min(verticalScale, horizontalScale) }
        
        editingDocumentPDFView.scaleFactor = scaleFactor
    }

    
    func scaleMergedView(_ direction: ViewScaleMode = .fit, viewMargin: CGSize = CGSize(width: 30, height: 10)) {
        
        let documentSize = CGSize(width: document.maxWidth, height: document.totalHeight)
        guard documentSize.width > 0, documentSize.height > 0 else { return }
        
        mergedViewScaleMode = direction
        let viewSize = mergedViewSize - viewMargin
        let verticalScale = viewSize.height / documentSize.height
        let horizontalScale = viewSize.width / documentSize.width

        mergedViewFitMode = verticalScale < horizontalScale ? .vertical : .horizontal

        
        let scaleFactor: CGFloat; switch direction {
        case .vertical: scaleFactor = verticalScale
        case .horizontal: scaleFactor = horizontalScale
            default: scaleFactor = min(verticalScale, horizontalScale) }
    
        mergedViewScaleFactor = scaleFactor
    }
    
    func deleteSouurceFileFromDatabase(_ sourceFile: SourceFile) {
        print("deleteSouurceFileFromDatabase()")
        Task {
            do {
                try await document.persistence?.deleteSourceFiles([sourceFile.id])
            } catch {
                // Handle or present the error appropriately
                print("Failed to delete files: \(error)")
            }
        }
        selectedFiles.remove(sourceFile.id)
    }
    
 func addPageFromImageURL(
        _ url: URL,
        at indexPath: IndexPath? = nil,
        title: String? = nil,
        imageOptions: ImageImportOptions = .neutral
    ) {
        let mergedPage = document.mergedPagefrom(url, at: indexPath)
        let pageInsertIndex = document.normalizedInsertionIndex(
            count: mergedPage.pageItems.count,
            location: (indexPath?.item ?? 0) + 1
        )
        
        let effectiveOptions = resolvedImportOptions(imageOptions)
        
        guard let image = processedImageFromURL(url, imageOptions: effectiveOptions) else {
            assertionFailure("Failed to process image at \(url)")
            return
        }
        
        guard let pdfPage = PDFPage(image: image) else {
            assertionFailure("Failed to create PDFPage from processed image at \(url)")
            return
        }
        
        let pageItem = PageItem(
            prax: self,
            mergedPage: mergedPage,
            name: title ?? url.deletingPathExtension().lastPathComponent,
            sourceURL: url,
            isLibraryFile: false,
            imageOptions: imageOptions,
            dataFields: [:]
        )
        pageItem.pdfPage = pdfPage
        
        
        mergedPage.pageItems.insert(pageItem, at: pageInsertIndex)
    }
    
    /// New signature (size-limit based).
    func processedImageFromURL(_ url: URL, imageOptions: ImageImportOptions) -> NSImage? {
        guard let sourceImage = NSImage(contentsOf: url) else { return nil }
        return processedImage(sourceImage, imageOptions: resolvedImportOptions(imageOptions))
    }
    
    
    
    // MARK: - Core processing
    private static let imageCIContext = CIContext()
    private func processedImage(_ sourceImage: NSImage, imageOptions: ImageImportOptions) -> NSImage? {
        guard let tiff = sourceImage.tiffRepresentation,
              var ciImage = CIImage(data: tiff) else { return nil }
        
        // 1) Crop
        let crop = cropRect(for: ciImage.extent.size, imageOptions: imageOptions)
        ciImage = ciImage.cropped(to: crop)
        
        // 2) Adjustments
        ciImage = applyAdjustments(to: ciImage, imageOptions: imageOptions)
        
        // 3) Render CI -> NSImage
        let extent = ciImage.extent.integral
        guard let cgImage = Self.imageCIContext.createCGImage(ciImage, from: extent) else { return nil }
        var output = NSImage(cgImage: cgImage, size: NSSize(width: extent.width, height: extent.height))
        
        // 4) Size strategy
        switch imageOptions.sizingMode {
        case .fileSizeLimit:
            // Keep current manual downscale behavior
            let userScale = CGFloat(imageOptions.scaleDown).clamped(to: 0.05...1.0)
            if userScale < 0.999 {
                let px = pixelSize(of: output)
                let scaled = NSSize(
                    width: max(1, floor(px.width * userScale)),
                    height: max(1, floor(px.height * userScale))
                )
                output = output.resize(to: scaled) ?? output
            }
            
            if imageOptions.sizeLimitKB > 0 {
                output = downscaleToMeetPDFSizeLimit(output, targetKB: imageOptions.sizeLimitKB)
            }
            
        case .targetInches:
            output = scaleImageToTargetInches(
                output,
                targetWidthInches: imageOptions.targetWidthInches,
                targetHeightInches: imageOptions.targetHeightInches
            )
        }
        
        return output
    }
    
    private func scaleImageToTargetInches(
        _ image: NSImage,
        targetWidthInches: Double,
        targetHeightInches: Double
    ) -> NSImage {
        let px = pixelSize(of: image)
        let currentW = max(px.width, 1)
        let currentH = max(px.height, 1)
        
        // 0 or less means "not specified"
        let targetW: CGFloat? = targetWidthInches > 0 ? CGFloat(targetWidthInches * 72.0) : nil
        let targetH: CGFloat? = targetHeightInches > 0 ? CGFloat(targetHeightInches * 72.0) : nil
        
        guard targetW != nil || targetH != nil else { return image }
        
        let scale: CGFloat
        switch (targetW, targetH) {
        case let (.some(w), .some(h)):
            // preserve aspect ratio, fit inside requested bounds
            scale = min(w / currentW, h / currentH)
        case let (.some(w), nil):
            scale = w / currentW
        case let (nil, .some(h)):
            scale = h / currentH
        default:
            scale = 1.0
        }
        
        guard scale.isFinite, scale > 0 else { return image }
        
        let newSize = NSSize(
            width: max(1, floor(currentW * scale)),
            height: max(1, floor(currentH * scale))
        )
        
        return image.resize(to: newSize) ?? image
    }
    
    private func cropRect(for size: CGSize, imageOptions: ImageImportOptions) -> CGRect {
        let minRemainingFraction: CGFloat = 0.05
        
        let w = max(size.width, 1)
        let h = max(size.height, 1)
        
        let left = CGFloat(imageOptions.cropLeft).clamped(to: 0...0.95)
        let right = CGFloat(imageOptions.cropRight).clamped(to: 0...0.95)
        let top = CGFloat(imageOptions.cropTop).clamped(to: 0...0.95)
        let bottom = CGFloat(imageOptions.cropBottom).clamped(to: 0...0.95)
        
        let horizontalTrim = min(left + right, 1 - minRemainingFraction)
        let verticalTrim = min(top + bottom, 1 - minRemainingFraction)
        
        let effectiveRight = min(right, horizontalTrim - left)
        let effectiveTop = min(top, verticalTrim - bottom)
        
        let x = w * left
        let y = h * bottom
        let cw = max(1, w - w * (left + effectiveRight))
        let ch = max(1, h - h * (bottom + effectiveTop))
        
        return CGRect(x: x, y: y, width: cw, height: ch).integral
    }
    
    private func applyAdjustments(to image: CIImage, imageOptions: ImageImportOptions) -> CIImage {
        var output = image
        
        if imageOptions.brightness != 0 || imageOptions.contrast != 1 {
            let f = CIFilter(name: "CIColorControls")
            f?.setValue(output, forKey: kCIInputImageKey)
            f?.setValue(imageOptions.brightness, forKey: kCIInputBrightnessKey)
            f?.setValue(imageOptions.contrast, forKey: kCIInputContrastKey)
            f?.setValue(1.0, forKey: kCIInputSaturationKey)
            if let o = f?.outputImage { output = o }
        }
        
        if imageOptions.exposure != 0 {
            let f = CIFilter(name: "CIExposureAdjust")
            f?.setValue(output, forKey: kCIInputImageKey)
            f?.setValue(imageOptions.exposure, forKey: kCIInputEVKey)
            if let o = f?.outputImage { output = o }
        }
        
        if imageOptions.sharpness > 0 {
            let f = CIFilter(name: "CISharpenLuminance")
            f?.setValue(output, forKey: kCIInputImageKey)
            f?.setValue(imageOptions.sharpness, forKey: kCIInputSharpnessKey)
            if let o = f?.outputImage { output = o }
        }
        
        return output
    }
    
    // MARK: - Size-limit logic
    
    func resolvedImportOptions(_ imageOptions: ImageImportOptions) -> ImageImportOptions {
        // Convention:
        // - .neutral means "use app-wide defaults from prax.imageOptions"
        // - otherwise use explicit passed imageOptions
        if imageOptions == .neutral {
            return imageOptions
        }
        return imageOptions
    }
    
    /*
     private func storedImportSizingMode() -> ImportSizingMode {
     let defaults = UserDefaults.standard
     guard let raw = defaults.string(forKey: "import-sizing-mode"),
     let mode = ImportSizingMode(rawValue: raw) else {
     return .fileSizeLimit
     }
     return mode
     }
     
     private func storedImportTargetWidthInches() -> Double? {
     let defaults = UserDefaults.standard
     guard defaults.object(forKey: "import-target-width-inches") != nil else { return nil }
     let v = defaults.double(forKey: "import-target-width-inches")
     return v > 0 ? v : nil
     }
     
     private func storedImportTargetHeightInches() -> Double? {
     let defaults = UserDefaults.standard
     guard defaults.object(forKey: "import-target-height-inches") != nil else { return nil }
     let v = defaults.double(forKey: "import-target-height-inches")
     return v > 0 ? v : nil
     }
     
     private func storedImportSizeLimitKB() -> Int? {
     let defaults = UserDefaults.standard
     if defaults.object(forKey: "import-size-limit") == nil {
     return 1024 // default 1 MB
     }
     let value = defaults.integer(forKey: "import-size-limit")
     return value > 0 ? value : nil
     }
     */
    
    private func pixelSize(of image: NSImage) -> CGSize {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first {
            return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        }
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return CGSize(width: cg.width, height: cg.height)
        }
        return image.size
    }
    
    private func estimatePDFSizeKB(for image: NSImage) -> Int? {
        guard let page = PDFPage(image: image) else { return nil }
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        guard let data = doc.dataRepresentation() else { return nil }
        return Int(ceil(Double(data.count) / 1024.0))
    }
    
    private func downscaleToMeetPDFSizeLimit(_ image: NSImage, targetKB: Int) -> NSImage {
        guard targetKB > 0 else { return image }
        guard let startKB = estimatePDFSizeKB(for: image), startKB > targetKB else { return image }
        
        let px = pixelSize(of: image)
        let minScale: CGFloat = 0.05
        var lo = minScale
        var hi: CGFloat = 1.0
        var best: NSImage?
        
        for _ in 0..<10 { // binary search
            let mid = (lo + hi) / 2
            let candidateSize = NSSize(
                width: max(1, floor(px.width * mid)),
                height: max(1, floor(px.height * mid))
            )
            
            guard let candidate = image.resize(to: candidateSize),
                  let kb = estimatePDFSizeKB(for: candidate) else {
                hi = mid
                continue
            }
            
            if kb > targetKB {
                hi = mid
            } else {
                best = candidate
                lo = mid
            }
        }
        
        return best ?? image
    }
    
    
    func moreThanOneDataPageError() {
        print("\nJulie d'Prax")
        PraxLogger.shared.logWarning("More than one data page", category: .general)
        
        let praxError = PraxError.generic(
            title: "More Than One Data Page",
            message: "Only one Page Item should contain Data Fields.\n\nThe first Page Item will be used for the data source and it's fields will be filled on export.\n\nHowever, unless you use the Burn option, the form fields on other pages will blank and no longer editable.\n\nRemove the extra Data Page Item(s) if you don't wish for this behavior."
        )
        presentError(praxError)
    }

}







