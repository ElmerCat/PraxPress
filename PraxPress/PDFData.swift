//
//  PDFEntry.swift
//  PraxPress
//
//  Created by Elmer Cat on 12/22/25.
//



struct PDFEntry: Identifiable, Hashable {
    let id: UUID
    let url: URL
    var fileName: String { url.lastPathComponent }
    let pcardHolderName: String?
    let documentNumber: String?
    let date: String?
    let amount: String?
    let vendor: String?
    let glAccount: String?
    let costObject: String?
    let description: String?
    
    init(id: UUID = UUID(), url: URL, pcardHolderName: String?, documentNumber: String?, date: String?, amount: String?, vendor: String?, glAccount: String?, costObject: String?, description: String?) {
        self.id = id
        self.url = url
        self.pcardHolderName = pcardHolderName
        self.documentNumber = documentNumber
        self.date = date
        self.amount = amount
        self.vendor = vendor
        self.glAccount = glAccount
        self.costObject = costObject
        self.description = description
    }
}


