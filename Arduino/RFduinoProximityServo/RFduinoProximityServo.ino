#include <RFduinoBLE.h>
#include <Servo.h>

#define ADVERTISEMENT_DATA "0D624DE"
#define ACCESS_KEY "34C"

#define SERVO_PIN 2

#define MIN_RSSI_FOR_UNLOCK -50
#define MAX_RSSI_FOR_LOCK -60
#define MAX_COUNT 3

boolean validKeyInRange = false;
boolean locked = false;
boolean unLocked = false;
int closeCount = 0;
int farCount = 0;
Servo s1;

void setup() {
  Serial.begin(9600);
  s1.attach(SERVO_PIN);

  RFduinoBLE.deviceName = "BLELock";
  RFduinoBLE.advertisementInterval = 100; //100ms 
  RFduinoBLE.advertisementData = ADVERTISEMENT_DATA;
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

void RFduinoBLE_onRSSI(int rssi)
{
  if(validKeyInRange)
  {
    Serial.println(rssi);

    // Connected device is very close
    if(rssi > MIN_RSSI_FOR_UNLOCK) {
      if(closeCount == MAX_COUNT) {
        if(!locked)
        {
          s1.write(0);
          RFduinoBLE.send(1);
          locked = true;
          unLocked = false;
        }
      } else {
        closeCount++;
        farCount=0;
      }
    }
    else if(rssi < MAX_RSSI_FOR_LOCK) // Connected device is far
    {
      if(farCount == MAX_COUNT) {
        if (!unLocked) {
          s1.write(90);
          RFduinoBLE.send(0);
          unLocked = true;
          locked = false;
        }
      } else {
        farCount++;
        closeCount=0;
      }
    } else { // Connected device in ambiguous range (neither close nor far)
      closeCount = 0;
      farCount = 0;
    }
  }
}

void RFduinoBLE_onReceive(char *key, int len)
{
  Serial.println(key);
  if(!strcmp(key, ACCESS_KEY)) {
    Serial.println("valid key");
    validKeyInRange = true;
  } else {
    Serial.println("invalid key");
    validKeyInRange = false;
  }
}

void RFduinoBLE_onConnect(){
  Serial.println("On Connect");
  s1.write(90);
}

void RFduinoBLE_onDisconnect(){
  Serial.println("On Disconnect");
  s1.write(90);
}
