//
//  RecievingViewController.swift
//  blueToothMessaging
//
//  Created by huge on 02/10/2023.
//

import UIKit
import CoreBluetooth

class RecievingViewController: UIViewController {
    
    var connectedPeripheral: CBPeripheral?

    var centralManager: CBCentralManager!
    
    var data = Data()
    
    let alertManager = AlertManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])

        // Do any additional setup after loading the view.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        centralManager.stopScan()
        data.removeAll()
    }
    

    
}

extension RecievingViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if !checkIfAlreadyConnected() { //if could not find connected devices, scan.
                central.scanForPeripherals(withServices: [TransferService.serviceUUID],
                                           options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
            }
        default:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
    }
    
    func checkIfAlreadyConnected() -> Bool {
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [TransferService.serviceUUID])
        if let peri = connectedPeripherals.last { //if found connected, connect.
            centralManager.connect(peri)
            return true
        } else {
            return false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(RSSI.intValue)
        guard RSSI.intValue >= -50 else {return}
        print("Discovered \(peripheral.name ?? "peripheral without a name")")
        connectedPeripheral = peripheral
        central.stopScan()
        central.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("Successfully connected \(peripheral.name ?? "peripheral without a name")")
        
        connectedPeripheral = peripheral

        
        central.stopScan()
        
        peripheral.delegate = self
        
        data.removeAll()
        
        peripheral.discoverServices([TransferService.serviceUUID])
        
        
    }
    
    
}

extension RecievingViewController: CBPeripheralDelegate {
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            print("didDiscoverServices",error)
        }
        
        guard let services = peripheral.services else {return}
        
        //loop through discovered services and discover characteristics
        for service in services {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            print("didDiscoverCharacteristicsFor",error)
        }
        
        //filter TransferService characteristic and notify observer
        if let characteristic = service.characteristics?.filter({$0.uuid==TransferService.characteristicUUID}).last {
            print("Success!")
            view.backgroundColor = .green
            peripheral.setNotifyValue(true, for: characteristic)
        } else {
            fatalError("Found characteristic isnt matching")
        }
    }
    
    //observer being called
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let transferedData = characteristic.value,
              let dataString = String(data: transferedData, encoding: .utf8) else {return}
        print("Got data!",dataString)

        DispatchQueue.main.async {
            let alertVC = self.alertManager.alertViewController(type: .recievingAlert, action: nil, transferedData)
            
            self.present(alertVC, animated: true)
        }
    }
    
    //called when observer is being set
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            print("didUpdateNotificationStateFor",error)
        }
        print("Notification began on \(characteristic)")
    }
    
    
    
}


