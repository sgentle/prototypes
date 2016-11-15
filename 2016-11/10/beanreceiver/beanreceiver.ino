#include <Servo.h>

Servo servo;
static int d0 = 0;
static int d1 = 1;

// the setup routine runs once when you press reset:
void setup()
{
  // initialize serial communication at 57600 bits per second:
  Serial.begin(57600);

  pinMode(d1, OUTPUT);

  servo.attach(d0);
  servo.write(180);
}

int wasActive = 0;

void loop()
{
 if (Serial.available()) {
  uint8_t buffer;
  uint8_t red = 0;
  uint8_t green = 0;
  uint8_t blue = 0;
  buffer = Serial.read();
  if (!(buffer & 1)) {
    red = 127;
    digitalWrite(d1, HIGH);
    if (!wasActive) {
      wasActive = 1;
      servo.write(40);
    }
  }
  else {
    digitalWrite(d1, LOW);
    if (wasActive) {
      wasActive = 0;
      servo.write(180);
    }
  }
  if (!(buffer & 2)) green = 127;
  if (!(buffer & 4)) blue = 127;
  Bean.setLed(red, green, blue);
 }
 // Sleep for half a second before checking the pins again
 Bean.sleep(500);
}
