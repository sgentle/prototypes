#include <Servo.h>

Servo servo;
static int d0 = 0;
static int d1 = 1;

const int SERVO_OFF_POSITION = 180; //Angle in degrees for the off position
const int SERVO_ON_POSITION = 40; //Angle in degrees for the on position

const int SERVO_ON_TIME = 1; //Seconds to keep servo in the on position
const int FAN_WAIT_TIME = 5; //Seconds to wait until turning on the fan
const int FAN_ON_TIME = 30; //Seconds to leave the fan on for

void setup()
{
  // initialize serial communication at 57600 bits per second:
  Serial.begin(57600);

  pinMode(d1, OUTPUT);
  digitalWrite(d1, LOW);

  servo.attach(d0);
  servo.write(SERVO_OFF_POSITION);
}

int wasActive = 0;

void loop() {
  // Extra delay because we sometimes get woken up slightly before data is available
  if (!Serial.available()) delay(100);

  if (Serial.available()) {
    while(Serial.read() > -1);
    Serial.println("Activated!");

    servo.write(SERVO_ON_POSITION);
    Serial.println("Servo on");

    delay(SERVO_ON_TIME*1000);

    servo.write(SERVO_OFF_POSITION);
    Serial.println("Servo off");

    delay(FAN_WAIT_TIME*1000);
    digitalWrite(d1, HIGH);
    Serial.println("Fan on");

    delay(FAN_ON_TIME*1000);

    digitalWrite(d1, LOW);
    Serial.println("Fan off");

    while(Serial.read() > -1);
  }

  Serial.println("Waiting");

  // Busywork to keep the USB battery pack awake
  servo.write(SERVO_OFF_POSITION - 10);
  delay(500);
  servo.write(SERVO_OFF_POSITION + 10);
  delay(500);
  servo.write(SERVO_OFF_POSITION);
  delay(100);
  Bean.sleep(15000);
}
