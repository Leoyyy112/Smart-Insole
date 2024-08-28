import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var latestData: SensorData?
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var errorMessage: String?
    @Published var stepCounter: StepCounter
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    private var scanTimer: Timer?
    

    private let ESP32_SERVICE_UUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    private let ESP32_CHARACTERISTIC_UUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    
    override init() {
            self.stepCounter = StepCounter(userHeight: 170, userWeight: 70, userAge: 30, userGender: "male")
            super.init()
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    
    func startScanning() {
        print("Start scanning for all devices")
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        // 设置30秒超时
        scanTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            self.centralManager.stopScan()
            print("Scan timeout. No devices found.")
            // 可以在这里添加重试逻辑
        }
    }
    
    func connect() {
        print("Attempting to connect")
        startScanning()
    }
    
    func disconnect() {
        print("Disconnecting")
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func checkBluetoothState() {
        bluetoothState = centralManager.state
        print("Bluetooth state: \(bluetoothState)")
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        print("Central manager did update state: \(bluetoothState)")
        if central.state == .poweredOn {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral: \(peripheral.name ?? "Unknown"), UUID: \(peripheral.identifier), RSSI: \(RSSI)")
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            print("Advertised services: \(serviceUUIDs)")
        }
        if peripheral.name == "ESP32_MPU6050" {
            self.peripheral = peripheral
            central.stopScan()
            print("Connecting to ESP32_MPU6050")
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
        scanTimer?.invalidate()
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices([ESP32_SERVICE_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown"), error: \(error?.localizedDescription ?? "None")")
        isConnected = false
        self.peripheral = nil
        self.characteristic = nil
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Discovered services")
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Service: \(service.uuid)")
            peripheral.discoverCharacteristics([ESP32_CHARACTERISTIC_UUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Discovered characteristics")
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print("Characteristic: \(characteristic.uuid)")
            if characteristic.uuid == ESP32_CHARACTERISTIC_UUID {
                self.characteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("Subscribed to characteristic")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else {
            print("No data received")
            return
        }
        
        print("Received data: \(data.count) bytes")
        if let string = String(data: data, encoding: .utf8) {
            print("Received string: \(string)")
            let components = string.components(separatedBy: ",")
            if components.count == 7 {
                let sensorData = SensorData(
                    timestamp: Double(components[0]) ?? 0,
                    accelX: Double(components[1]) ?? 0,
                    accelY: Double(components[2]) ?? 0,
                    accelZ: Double(components[3]) ?? 0,
                    gyroX: Double(components[4]) ?? 0,
                    gyroY: Double(components[5]) ?? 0,
                    gyroZ: Double(components[6]) ?? 0
                )
                DispatchQueue.main.async {
                    self.latestData = sensorData
                    self.stepCounter.addSensorData(sensorData)
                    
                }
            } else {
                print("Unexpected number of components: \(components.count)")
            }
        } else {
            print("Unable to convert data to string")
        }
    }
}

struct SensorData {
    let timestamp: Double
    let accelX: Double
    let accelY: Double
    let accelZ: Double
    let gyroX: Double
    let gyroY: Double
    let gyroZ: Double
}
