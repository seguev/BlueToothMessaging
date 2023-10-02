//
//  AlertManager.swift
//  blueToothMessaging
//
//  Created by huge on 02/10/2023.
//

import UIKit

class AlertManager {
    
    enum alertType {
        case sendingAlert
        case recievingAlert
    }
    
    func alertViewController(type: alertType,action: ((Data) -> Void)?,_ recievedData:Data? = nil) -> UIAlertController {
        
        var alert: UIAlertController!
        
        switch type {
        case .sendingAlert:
            alert = .init(title: "Write something!", message: "", preferredStyle: .alert)
            if let action {
                alert.addTextField()
                alert.addAction(UIAlertAction(title: "SEND", style: .default, handler: { _ in
                    guard let textfield = alert.textFields?.first else {fatalError("Could not find textfield")}
                    guard let validText = textfield.text, !validText.isEmpty , validText.contains(where: { $0 != Character(" ") }) else {
                        print("Invalid text")
                        return
                    }
                    guard let dataToSend = validText.data(using: .utf8) else { fatalError("Could not convert text to data!") }
                    action(dataToSend)
                    alert.dismiss(animated: true)
                }))
            }
            alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel))
        case .recievingAlert:
            if let recievedData, let message = String(data: recievedData, encoding: .utf8) {
                alert = .init(title: "Got a new message!", message: message, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK!", style: .cancel))
            } else {
                fatalError("No recieved data!")
            }
        }
        return alert
    }
    
}

