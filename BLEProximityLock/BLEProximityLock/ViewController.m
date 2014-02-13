//
//  ViewController.m
//  BLEProximityLock
//
//  Created by Vivek Jain on 1/20/14.
//  Copyright (c) 2014 Vivek Jain. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController() <CBCentralManagerDelegate, CBPeripheralDelegate> {
@private
    CBUUID *serviceUUID;
    CBUUID *sendUUID;
    CBUUID *receiveUUID;
    CBUUID *disconnectUUID;
    NSString *deviceID;
    NSString *key;
}

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (weak, nonatomic) IBOutlet UILabel *statusField;
@property (weak, nonatomic) IBOutlet UILabel *deviceIDField;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    deviceID = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_id"];
    if(deviceID == nil) {
        deviceID = @"0D624DE";
    }

    key = [[NSUserDefaults standardUserDefaults] stringForKey:@"key"];
    if(key == nil) {
        key = @"34C";
    }

    self.deviceIDField.text = deviceID;

    serviceUUID = [CBUUID UUIDWithString:@"2220"];
    sendUUID = [CBUUID UUIDWithString:@"2222"];
    receiveUUID = [CBUUID UUIDWithString:@"2221"];
    disconnectUUID = [CBUUID UUIDWithString:@"2223"];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil
                                                             options:@{
                                                                       CBCentralManagerOptionRestoreIdentifierKey: @"myCentralManagerIdentifier"
                                                                       }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Central Manager Methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if(central.state != CBCentralManagerStatePoweredOn)
    {
        [self updateStatus:@"No Bluetooth"];
        return;
    }

    [self scan];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    [self.centralManager stopScan];
    
    NSString *rfduinoAdvertisementData = nil;

    id manufacturerData = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
    if (manufacturerData) {
        const uint8_t *bytes = [manufacturerData bytes];
        NSUInteger len = [manufacturerData length];
        // skip manufacturer uuid
        NSData *data = [NSData dataWithBytes:bytes+2 length:len-2];
        rfduinoAdvertisementData = [NSString stringWithUTF8String:[data bytes]];
    }

    if(![deviceID isEqualToString:rfduinoAdvertisementData]) {
        [self updateStatus:@"Peripheral Mismatched"];
        return;
    }

    [self updateStatus:@"Peripheral Matched"];

    if(self.peripheral != peripheral) {
        self.peripheral = peripheral;
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self updateStatus:@"Connection Failed"];
    [self cleanup];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self updateStatus:@"Peripheral Connected"];
    
    peripheral.delegate = self;
    [peripheral discoverServices:@[serviceUUID]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    [self updateStatus:@"Peripheral Disconnected"];
    self.peripheral = nil;
    [self scan];
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    self.peripheral = [peripherals objectAtIndex:0];
}

#pragma mark - Peripheral Methods
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self updateStatus:@"Service Discovery Error"];
        [self cleanup];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[receiveUUID, sendUUID, disconnectUUID]
                                 forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self updateStatus:@"Characteristic Discovery Error"];
        [self cleanup];
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if([characteristic.UUID isEqual:sendUUID]) {
            [peripheral writeValue:[key dataUsingEncoding:NSUTF8StringEncoding]
                 forCharacteristic:characteristic
                              type:CBCharacteristicWriteWithoutResponse];
        }
        else if([characteristic.UUID isEqual:receiveUUID]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if([characteristic.UUID isEqual:receiveUUID]) {
        const uint8_t *value = [characteristic.value bytes];
        if(value[0]) {
            [self updateStatus:@"Peripheral Close"];
        } else {
            [self updateStatus:@"Peripheral Far"];
        }
    }
}

#pragma mark - Private Methods
- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[serviceUUID]
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
}

- (void)cleanup
{
    if (self.peripheral.state == CBPeripheralStateDisconnected) {
        return;
    }
    [self.centralManager cancelPeripheralConnection:self.peripheral];
}

- (void)updateStatus:(NSString *)status
{
    [self.statusField setText:status];
}

@end
