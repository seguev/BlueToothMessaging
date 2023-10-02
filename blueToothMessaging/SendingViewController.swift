//
//  SendingViewController.swift
//  blueToothMessaging
//
//  Created by huge on 02/10/2023.
//

import UIKit
import CoreBluetooth

class SendingViewController: UIViewController {
    
    @IBOutlet weak var infoLabel: UILabel!
    
    var peripheralManager: CBPeripheralManager!
    
    let alertManager = AlertManager()
        
    var transferCharacteristic: CBMutableCharacteristic?
    
    var connectedCentral: CBCentral?
    
    var sendDataIndex: Int = 0
    
    var data: Data!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showAlert(_:))))
    }
    
    @objc func showAlert(_ sender:UITapGestureRecognizer) {
        let alertVC = alertManager.alertViewController(type: .sendingAlert, action: sendDataFix(_:))
        
        self.present(alertVC, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        peripheralManager.stopAdvertising()
    }
    
    private func setupPeripheral() {
        
        //initialize a new mutable characterstic
        transferCharacteristic = CBMutableCharacteristic(type: TransferService.characteristicUUID,
                                                         properties: [.notify,.writeWithoutResponse],
                                                         value: nil,
                                                         permissions: [.readable,.writeable])
        
        //initialize a new transfer service
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        
        //add characteristic service
        transferService.characteristics = [transferCharacteristic!] //force unwrap cause the init is literaly 2 lines above
        
        //add service to central
        peripheralManager.add(transferService)
    }
    
    
    func sendDataFix(_ recievedData:Data) {
        
        guard let transferCharacteristic else {fatalError("You need to set the characteristics global variable")}
        
        print("Message To Send\n",String(data: recievedData, encoding: .utf8) ?? "Empty Message")
        
        let messageLength = recievedData.count
        print("recieved data length:", messageLength)
        
        guard let maximumLength = connectedCentral?.maximumUpdateValueLength else {
            self.infoLabel.text = "Nobody's connected..."
            return
        }
        
        print("maximumUpdateValueLength:",maximumLength)
        
        let isOneChunk = messageLength <= maximumLength
        if isOneChunk {
            print("Its one chunk")
            
            let didSend = peripheralManager.updateValue(recievedData,
                                          for: transferCharacteristic,
                                          onSubscribedCentrals: nil)
            
            print(didSend ? "Sent!" : "Did not send!")
            
        } else {
            fatalError("ho no its more than one chunk")
        }
    }
    
}

extension SendingViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            // ... so start working with the peripheral
            print("CBManager is powered on")
            setupPeripheral()
        case .poweredOff:
            print("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            print("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            print("You are not authorized to use Bluetooth")
            return
        case .unknown:
            print("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            print("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        default:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            return
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Someone is listening! 🫨")
        self.view.backgroundColor = .green
        infoLabel.text = "Someone is listening... \nTap anywhere 😎"
        connectedCentral = central
        
    }
}
