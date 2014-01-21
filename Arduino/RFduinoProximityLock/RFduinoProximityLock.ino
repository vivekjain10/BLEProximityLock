#include <RFduinoBLE.h>

void setup() {
  Serial.begin(9600);
  RFduinoBLE.deviceName = "BLELock";
  RFduinoBLE.advertisementInterval = 100; //100ms 
  RFduinoBLE.advertisementData = "0D624DE";
  RFduinoBLE.begin();
}

void loop() {
  RFduino_ULPDelay(INFINITE);
}

void RFduinoBLE_onAdvertisement(bool start)
{
  if (start)
    Serial.println("Started Advertising!");
  else
    Serial.println("Stopped Advertising");
}

//returns the dBm signal strength after connecting 
void RFduinoBLE_onRSSI(int rssi)
{
  Serial.println(rssi);
}

//data from the radio
void RFduinoBLE_onReceive(char *data, int len)
{
  Serial.println(data);
} 

