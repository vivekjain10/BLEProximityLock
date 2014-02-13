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
    CBUUID *service_uuid;
    CBUUID *send_uuid;
    CBUUID *receive_uuid;
    CBUUID *disconnect_uuid;
    NSString *deviceId;
    NSString *key;
}

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (weak, nonatomic) IBOutlet UILabel *statusField;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    deviceId = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_id"];
    key = [[NSUserDefaults standardUserDefaults] stringForKey:@"key"];
    

    service_uuid = [CBUUID UUIDWithString:@"2220"];
    send_uuid = [CBUUID UUIDWithString:@"2222"];
    receive_uuid = [CBUUID UUIDWithString:@"2221"];
    disconnect_uuid = [CBUUID UUIDWithString:@"2223"];

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
        int len = [manufacturerData length];
        // skip manufacturer uuid
        NSData *data = [NSData dataWithBytes:bytes+2 length:len-2];
        rfduinoAdvertisementData = [NSString stringWithUTF8String:[data bytes]];
    }

    if(![deviceId isEqualToString:rfduinoAdvertisementData]) {
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
    [peripheral discoverServices:@[service_uuid]];
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
        [peripheral discoverCharacteristics:@[receive_uuid, send_uuid, disconnect_uuid]
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
    
    for (CBCharacteristic *characterstic in service.characteristics) {
        if([characterstic.UUID isEqual:send_uuid]) {
            [peripheral writeValue:[key dataUsingEncoding:NSUTF8StringEncoding]
                 forCharacteristic:characterstic
                              type:CBCharacteristicWriteWithoutResponse];
        }
    }
}

#pragma mark - Private Methods
- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[service_uuid]
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
