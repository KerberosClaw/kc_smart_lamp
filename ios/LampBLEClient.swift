// LampBLEClient.swift
// CoreBluetooth client. Single service, single 5-byte LAMP_STATE characteristic.
// See ../docs/gatt_spec.md for protocol.

import Foundation
import CoreBluetooth
@preconcurrency import Combine

@Observable
final class LampBLEClient: NSObject {

    // UUIDs come from gatt_spec.md
    static let serviceUUID = CBUUID(string: "2f421b7d-41dd-4de6-a19a-1194b4d04361")
    static let stateCharUUID = CBUUID(string: "2f421b7d-41dd-4de6-a19a-a2a6dae023f9")
    static let advertisedName = "kc_smart_lamp"

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var stateChar: CBCharacteristic?

    private var connectContinuation: CheckedContinuation<String, Error>?
    private var readContinuation: CheckedContinuation<Data, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?

    enum BLEError: Error { case notReady, scanTimeout, characteristicMissing, peripheralUnavailable }

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Public API

    func connect(timeout: TimeInterval = 6) async throws -> String {
        if central.state != .poweredOn { throw BLEError.notReady }

        return try await withCheckedThrowingContinuation { cont in
            connectContinuation = cont
            central.scanForPeripherals(withServices: [Self.serviceUUID], options: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard let self, self.peripheral == nil,
                      let c = self.connectContinuation else { return }
                self.central.stopScan()
                self.connectContinuation = nil
                c.resume(throwing: BLEError.scanTimeout)
            }
        }
    }

    func disconnect() {
        if let p = peripheral { central.cancelPeripheralConnection(p) }
        peripheral = nil
        stateChar = nil
    }

    func write(_ data: Data) async throws {
        guard let p = peripheral, let ch = stateChar else { throw BLEError.characteristicMissing }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            writeContinuation = cont
            p.writeValue(data, for: ch, type: .withResponse)
        }
    }

    func read() async throws -> Data {
        guard let p = peripheral, let ch = stateChar else { throw BLEError.characteristicMissing }
        return try await withCheckedThrowingContinuation { cont in
            readContinuation = cont
            p.readValue(for: ch)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension LampBLEClient: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Could surface .poweredOff / .unauthorized to the UI here.
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard self.peripheral == nil else { return }
        self.peripheral = peripheral
        peripheral.delegate = self
        central.stopScan()
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectContinuation?.resume(throwing: error ?? BLEError.peripheralUnavailable)
        connectContinuation = nil
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.peripheral = nil
        self.stateChar = nil
        // v1.1: kick off auto-retry here.
    }
}

// MARK: - CBPeripheralDelegate

extension LampBLEClient: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let svc = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            connectContinuation?.resume(throwing: BLEError.characteristicMissing)
            connectContinuation = nil
            return
        }
        peripheral.discoverCharacteristics([Self.stateCharUUID], for: svc)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let ch = service.characteristics?.first(where: { $0.uuid == Self.stateCharUUID }) {
            self.stateChar = ch
            connectContinuation?.resume(returning: peripheral.name ?? Self.advertisedName)
        } else {
            connectContinuation?.resume(throwing: BLEError.characteristicMissing)
        }
        connectContinuation = nil
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            readContinuation?.resume(throwing: err)
        } else {
            readContinuation?.resume(returning: characteristic.value ?? Data())
        }
        readContinuation = nil
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            writeContinuation?.resume(throwing: err)
        } else {
            writeContinuation?.resume()
        }
        writeContinuation = nil
    }
}
