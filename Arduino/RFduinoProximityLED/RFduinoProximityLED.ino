#include <RFduinoBLE.h>

#define LOCK_ID "0D624DE"
#define KEY "34C"

#define LED_RED 2
#define LED_BLUE 4

#define MIN_RSSI_FOR_BLUE -45
#define MAX_RSSI_FOR_RED -70

boolean validKeyInRange = false;

void setup() {
  Serial.begin(9600);

  pinMode(LED_RED, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);

  RFduinoBLE.deviceName = "BLELock";
  RFduinoBLE.advertisementInterval = 100; //100ms 
  RFduinoBLE.advertisementData = LOCK_ID;
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
    if(rssi > MIN_RSSI_FOR_BLUE)
      led_blue();
    else if(rssi < MAX_RSSI_FOR_RED)
      led_red();
  }
}

void RFduinoBLE_onReceive(char *key, int len)
{
  Serial.println(key);
  if(!strcmp(key, KEY))
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

void led_red()
{
  led(LED_RED);
}

void led_blue()
{
  led(LED_BLUE);
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
