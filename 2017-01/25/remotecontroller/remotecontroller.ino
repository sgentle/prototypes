#include <ESP8266WiFi.h>

const int POWER = 4;
const int BUTTON = 5;

void setup() {
  pinMode(BUTTON, INPUT_PULLUP);
  pinMode(POWER, OUTPUT);
  digitalWrite(POWER, HIGH);
  WiFi.forceSleepBegin();
}


void loop() {
  digitalWrite(POWER, HIGH);
  delay(1000);
  pinMode(BUTTON, INPUT);
  delay(100);
  pinMode(BUTTON, INPUT_PULLUP);
  digitalWrite(POWER, LOW);
  delay(1000);
}
