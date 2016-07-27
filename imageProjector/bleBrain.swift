//
//  bleBrain.swift
//  BluetoothTest
//
//  Created by Sander on 13/07/2016.
//  Copyright © 2016 Sander. All rights reserved.
//
//var ROBOT_SERVICE_UUID = "AF237777-879D-6186-1F49-DECA0E85D9C1"
//var COMMAND1_CHAR_UUID = "AF230002-879D-6186-1F49-DECA0E85D9C1"
//var SENSOR1_CHAR_UUID = "AF230006-879D-6186-1F49-DECA0E85D9C1"
//var SENSOR2_CHAR_UUID = "AF230003-879D-6186-1F49-DECA0E85D9C1"
//var COMMAND2_CHAR_UUID =  "AF230000-879D-6186-1F49-DECA0E85D9C1"
//var INFO_CHAR_UUID = "AF230001-879D-6186-1F49-DECA0E85D9C1"

var LED_SERVICE_UUID = "ED670000-FE3D-40EF-8254-F9D89A501D6D"
var LED_COMMAND_UUID = "ED670001-FE3D-40EF-8254-F9D89A501D6D"
var LED_DATA_UUID = "ED670002-FE3D-40EF-8254-F9D89A501D6D"
var DEVICE_NAME = "LEDstrip"
var NUMLEDS: UInt8 = 144

import Foundation
import CoreBluetooth

var ble: bleManager!



class bleManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    var centralManager : CBCentralManager!
    //var bleHandler : BLEHandler!
    var connectingPeripheral:CBPeripheral!
    var commandChar:CBCharacteristic!
    var dataChar:CBCharacteristic!
    
    override init(){
        super.init()
        NSLog("Init bleManager")
        //self.bleHandler = BLEHandler()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state)
        {
        case.Unsupported:
            NSLog("BLE is unsupported")
        case.Unauthorized:
            NSLog("BLE is unauthorized")
        case.Resetting:
            NSLog("BLE is resetting")
        case.PoweredOff:
            NSLog("BLE is powered off")
        case.Unknown:
            NSLog("BLE is unknown")
        case.PoweredOn:
            NSLog("BLE is powered on")
        }
    }

    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        NSLog("Updated pheripheral state")
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if peripheral.name != nil {
            NSLog("\(peripheral.name) ) : \(RSSI) dbm")
        }
        if (peripheral.name == DEVICE_NAME){
            connectingPeripheral =  peripheral
            connectingPeripheral.delegate = self
            central.connectPeripheral(connectingPeripheral, options : [
                CBCentralManagerOptionShowPowerAlertKey : true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
            central.stopScan()
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        NSLog("Connected to: \(peripheral.name!)")
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NSLog("Could not connect to: \(peripheral.name!)")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NSLog("Disconnected peripheral")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for service in peripheral.services as [CBService]!{
            NSLog("Discovered service: \(service.UUID.UUIDString)")
            peripheral.discoverCharacteristics(nil, forService: service)
            //peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for characteristic in service.characteristics as [CBCharacteristic]!{
            NSLog("Discovered characteristic: \(characteristic.UUID.UUIDString)")
            switch characteristic.UUID.UUIDString{
                
            case LED_COMMAND_UUID:
                commandChar = characteristic
            case LED_DATA_UUID:
                dataChar = characteristic
            default:
                NSLog("")
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        NSLog("Received data for characteristic: \(characteristic.UUID.UUIDString)")
    }
}

func initBLE(){
    ble = bleManager()
}

func dataWithHexString(hex: String) -> NSData {
    let string = hex
    
    let length = string.characters.count
    
    let rawData = UnsafeMutablePointer<CUnsignedChar>.alloc(length/2)
    var rawIndex = 0
    
    for index in 0.stride(to: length, by: 2) {
        let single = NSMutableString()
        single.appendString(string.substringWithRange(string.startIndex.advancedBy(index) ..< string.startIndex.advancedBy(index + 2)))
        rawData[rawIndex] = UInt8(single as String, radix:16)!
        rawIndex += 1
    }
    
    let data:NSData = NSData(bytes: rawData, length: length/2)
    rawData.dealloc(length/2)
    return data
}

func writeHexCommand(command: String){
    NSLog("Sending command: \(command)")
    let data = dataWithHexString(command);
    if (ble.commandChar != nil){
        ble.connectingPeripheral.writeValue(data, forCharacteristic: ble.commandChar, type: CBCharacteristicWriteType.WithResponse)
    }
}

func writeCommand(command: [UInt8]){
    let data = NSData(bytes: command as [UInt8], length: command.count)
    var commandstring = ""
    var hexByte = ""
    for c in command {
        hexByte = String(c, radix: 16)
        if hexByte.characters.count == 1 {
            hexByte = "0" + hexByte
        }
        commandstring += hexByte
    }
    NSLog("Sending command: \(commandstring)")
    if (ble.commandChar != nil){
        ble.connectingPeripheral.writeValue(data, forCharacteristic: ble.commandChar, type: CBCharacteristicWriteType.WithResponse)
    }
}

func writeData(dataArray: [UInt8]){
    let data = NSData(bytes: dataArray as [UInt8], length: dataArray.count)
    var datastring = ""
    var hexByte = ""
    for c in dataArray {
        hexByte = String(c, radix: 16)
        if hexByte.characters.count == 1 {
            hexByte = "0" + hexByte
        }
        datastring += hexByte
    }
    NSLog("Sending data: \(datastring)")
    if (ble.commandChar != nil){
        ble.connectingPeripheral.writeValue(data, forCharacteristic: ble.dataChar, type: CBCharacteristicWriteType.WithResponse)
    }
}

func connectDevice(){
    if (ble.centralManager.state == CBCentralManagerState.PoweredOn){
        NSLog("Scanning")
        //ble.centralManager.scanForPeripheralsWithServices(nil, options: nil)
        let services: [CBUUID] = [CBUUID(string:LED_SERVICE_UUID)]
        ble.centralManager.scanForPeripheralsWithServices(services, options: nil)
    } else {
        NSLog("Cannot access bluetooth controller")
    }
}

func activateSolid(){
    writeCommand([0x01, 0x00])
}

func activateRainbow(){
    writeCommand([0x01, 0x01])
}

func setColor(red:UInt8, green:UInt8, blue:UInt8){
    writeCommand([0x03, red, green, blue])
}

func setBrightness(brightness: UInt8){
    writeCommand([0x02, brightness])
}

func writeLine(){
    var data: [UInt8] = []
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    writeCommand([0x04, NUMLEDS])
    for i in 0...(NUMLEDS-1){
        red = UInt8(i)
        green = UInt8(i)
        blue = UInt8(i)
        data += [red,green, blue]
    }
    writeData(data)
}
