#include <Servo.h>
#include <RFduinoBLE.h>

const char *lockId = "0D624DE";
const char *validKey = "34C";
boolean validKeyInRange = false;
int servoPin = 6;
Servo s1;

void setup() {
  s1.attach(servoPin);
  Serial.begin(9600);
  RFduinoBLE.deviceName = "BLELock";
  RFduinoBLE.advertisementInterval = 100; //100ms 
  RFduinoBLE.advertisementData = lockId;
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
    Serial.println("Stopped Advertising!");
}

//returns the dBm signal strength after connecting 
void RFduinoBLE_onRSSI(int rssi)
{
  if(validKeyInRange)
  {
    Serial.println(rssi);
    if(rssi > -50)
      s1.write(0); //Unlock
    else if(rssi < -60)
      s1.write(90); //Lock
    //Don't change lock state when rssi from -50 to -60
  }
}

//data from the radio
void RFduinoBLE_onReceive(char *key, int len)
{
  Serial.println(key);
  if(!strcmp(key, validKey))
  {
    Serial.println("valid key");
    validKeyInRange = true;
  }
  else
  {
    Serial.println("invalid key");
    validKeyInRange = false;
  }
}

void RFduinoBLE_onConnect(){
  Serial.println("On Connect");
}

void RFduinoBLE_onDisconnect(){
  Serial.println("On Disconnect");
}
