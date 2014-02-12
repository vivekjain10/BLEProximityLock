#include <RFduinoBLE.h>

#define ADVERTISEMENT_DATA "0D624DE"
#define ACCESS_KEY "34C"

#define LED_RED 2
#define LED_BLUE 4

#define MIN_RSSI_FOR_BLUE -50
#define MAX_RSSI_FOR_RED -60
#define MAX_COUNT 3

boolean validKeyInRange = false;
boolean blueLedOn = false;
boolean redLedOn = false;
int closeCount = 0;
int farCount = 0;

void setup() {
  Serial.begin(9600);

  pinMode(LED_RED, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);

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
    if(rssi > MIN_RSSI_FOR_BLUE) {
      if(closeCount == MAX_COUNT) {
        if(!blueLedOn)
        {
          led(LED_BLUE);
          blueLedOn = true;
          redLedOn = false;
        }
      } else {
        closeCount++;
        farCount=0;
      }
    }
    else if(rssi < MAX_RSSI_FOR_RED) // Connected device is far
    {
      if(farCount == MAX_COUNT) {
        if (!redLedOn) {
          led(LED_RED);
          redLedOn = true;
          blueLedOn = false;
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
  led_off();
}

void RFduinoBLE_onDisconnect(){
  Serial.println("On Disconnect");
  led_off();
}

void led(int pin)
{
  led_off();
  digitalWrite(pin, HIGH);
}

void led_off()
{
  digitalWrite(LED_RED, LOW);
  digitalWrite(LED_BLUE, LOW);
}
