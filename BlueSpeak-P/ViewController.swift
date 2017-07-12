//
//  ViewController.swift
//  BlueSpeak-P
//
//  Created by William Jones on 7/10/17.
//  Copyright © 2017 ROKUBI,LLC. All rights reserved.
//


import UIKit
import CoreBluetooth


let BLUESPEAK_SERVICE_UUID_STRING           = "1F1E5A17-4F18-4CAA-920A-167C97A0DE84"
let bluespeakServiceUUID                    = CBUUID(string: BLUESPEAK_SERVICE_UUID_STRING)

let QUOTE_SERVICE_UUID_STRING               = "2A8D7E46-E9CB-4E8F-ADF7-BC48BB9FA364"
let quoteServiceUUID                        = CBUUID(string: QUOTE_SERVICE_UUID_STRING)

let QUOTE_CHARACTERISTIC_UUID_STRING        = "94E35701-399A-40B5-9210-5AB129B88674"
let bluespeakCharacteristicUUID             = CBUUID(string: QUOTE_CHARACTERISTIC_UUID_STRING)

// Star Wars Quotes
let quotes = ["May the Force be with you.",
              "I find your lack of faith disturbing.",
              "The Force will be with you. Always.",
              "Do. Or do not. There is no try.",
              "Fear is the path to the dark side. Fear leads to anger; anger leads to hate; hate leads to suffering. I sense much fear in you.",
              "I’m one with the Force. The Force is with me.",
              "Help me, Obi-Wan Kenobi. You’re my only hope.",
              "No. I am your father.",
              "When gone am I, the last of the Jedi will you be. The Force runs strong in your family. Pass on what you have learned.",
              "The dark side of the Force is a pathway to many abilities some consider to be unnatural."
]

class ViewController: UIViewController, CBPeripheralManagerDelegate {
    
    var advertisingSwitch = true
    var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic!
    
    var myTimer: Timer!
    var myQuoteIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad()")
        
        // Start up the CBPeripheralManager
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear()")
        // Don't keep it going while we're not showing.
        peripheralManager.stopAdvertising()
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("peripheralManagerDidUpdateState()")
        
        if (peripheral.state == .poweredOn){
            print("BLE powered on and ready")
            buildService()
        } else {
            print("*** BLE not on ***")
            return
        }
    }
    
    func buildService() {
        // build service.
        let transferService = CBMutableService(
            type: quoteServiceUUID,
            primary: true
        )
        
        // build the CBMutableCharacteristic for the Number
        let properties: CBCharacteristicProperties = [.read, .notify]
        let permissions: CBAttributePermissions = [.readable]
        transferCharacteristic = CBMutableCharacteristic(
            type: bluespeakCharacteristicUUID,
            properties: properties,
            value: nil,
            permissions: permissions)
        
        // Add the characteristics to the service
        transferService.characteristics = [transferCharacteristic!]
        
        // And add it to the peripheral manager
        peripheralManager.add(transferService)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("peripheralManager:didAdd service()")
        
        if let error = error {
            print("error: \(error)")
            return
        }
        
        // Start advertising
        // Advertise our service's UUID and Name
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey : [bluespeakServiceUUID],
            CBAdvertisementDataLocalNameKey:"BlueSpeak"
            ])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("peripheralManagerDidStartAdvertising()")
        
        if let error = error {
            print("error: \(error)")
            return
        }
        
        print("Advertising Succeeded!")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("peripheral:didUnsubscribeFrom characteristic()")
        
        // initialize the timer for 15 seconds and function to call
        myTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(sendQuote), userInfo: nil, repeats: true)
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("peripheral:didUnsubscribeFrom characteristic()")
        // Stop the timer
        myTimer.invalidate()
    }
    
    func sendQuote() {
        print("sendQuote()")
        
        var myValue = quotes[myQuoteIndex]
        let myBytes = NSData(bytes: &myValue, length: MemoryLayout<String>.size)
        let myConvertedString = myValue.data(using: .utf8)
        transferCharacteristic.value = myBytes as Data
        
        let updateSuccessful = peripheralManager.updateValue(myConvertedString!, for: transferCharacteristic, onSubscribedCentrals: nil)
        
        if (updateSuccessful) {
            print("Sent:\(quotes[myQuoteIndex])")
            
            myQuoteIndex += 1
            
            if myQuoteIndex == 10 {
                myQuoteIndex = 0
            }
            
        }
        
    }
    
}




