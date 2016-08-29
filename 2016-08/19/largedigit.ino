#include <ArduinoJson.h>

struct Display {
  char name[10]; //Name for data purposes
  int digits; //How many digits are in this display

  int lat; //Latch pin
  int clk; //Clock pin
  int ser; //Data pin
  int btn; //Button (pull low to trigger)

  long value; //Number being displayed
  long lastTrigger; //milliseconds for debounce
  bool dirty; //Does this display have data that needs to be sent to the server?
  bool unacked; //Are we waiting to hear back from the server that our send worked?
};

const int NUM_DISPLAYS = 2;

Display displays[NUM_DISPLAYS] = {
  {"irl", 5, 5, 6, 7, 2, 0, 0, false, false},
  {"internet", 5, 8, 9, 10, 3, 0, 0, false, false}
};

const int DEBOUNCE_DELAY = 1000; //milliseconds

/* 7-Segment layout
 *  A
 * F B
 *  G
 * E C
 *  D.
 */

#define SEG_A   1<<0
#define SEG_B   1<<6
#define SEG_C   1<<5
#define SEG_D   1<<4
#define SEG_E   1<<3
#define SEG_F   1<<1
#define SEG_G   1<<2
#define SEG_DOT 1<<7


const byte NUMBERS[] = {
  SEG_A | SEG_F | SEG_B | SEG_E | SEG_C | SEG_D,
  SEG_B | SEG_C,
  SEG_A | SEG_B | SEG_G | SEG_E | SEG_D,
  SEG_A | SEG_B | SEG_G | SEG_C | SEG_D,
  SEG_F | SEG_B | SEG_G | SEG_C,
  SEG_A | SEG_F | SEG_G | SEG_C | SEG_D,
  SEG_A | SEG_F | SEG_G | SEG_E | SEG_C | SEG_D,
  SEG_A | SEG_B | SEG_C,
  SEG_A | SEG_B | SEG_C | SEG_D | SEG_E | SEG_F | SEG_G,
  SEG_A | SEG_B | SEG_C | SEG_F | SEG_G
};

// Send one bit at a time between clock pin toggles
void sendByte(byte segments, Display* disp) {
  for (byte x = 0 ; x < 8 ; x++)
  {
    digitalWrite(disp->clk, LOW);
    digitalWrite(disp->ser, segments & 1 << (7 - x));
    digitalWrite(disp->clk, HIGH);
  }
}

// Toggle the latch pin to finish displaying
void sendLine(Display* disp) {
  digitalWrite(disp->lat, LOW);
  digitalWrite(disp->lat, HIGH);
}

void updateDisplay(Display* disp) {
  long num = disp->value;
  Serial.print("Display: updating '");
  Serial.print(disp->name);
  Serial.print("' to ");
  Serial.print(num, DEC);
  Serial.println();
  for (int i=0; i<disp->digits; i++) {
    int digit = num % 10;
    sendByte(NUMBERS[digit], disp);
    num = num / 10;
  }
  sendLine(disp);
}

void initDisplay(Display* disp) {
  pinMode(disp->lat, OUTPUT);
  pinMode(disp->clk, OUTPUT);
  pinMode(disp->ser, OUTPUT);

  digitalWrite(disp->lat, LOW);
  digitalWrite(disp->clk, LOW);
  digitalWrite(disp->ser, LOW);

  pinMode(disp->btn, INPUT_PULLUP);

  updateDisplay(disp);
}

void updateDisplaysFrom(String data) {
  Serial.print("Display: decoding data ");
  Serial.print(data);
  Serial.println();
  StaticJsonBuffer<200> jsonBuffer;
  JsonObject& root = jsonBuffer.parseObject(data);
  if (!root.success()) {
    Serial.println("Display: failed to parse JSON update");
    return;
  }

  for (int i=0; i<NUM_DISPLAYS; i++) {
    Display* disp = &displays[i];
    if (root.containsKey(disp->name)) {
      long newval = root[disp->name].as<long>();
      Serial.print("Display: received data for '");
      Serial.print(disp->name);
      Serial.println("'");
      if (disp->value > newval) {
        Serial.print("Display: new value is less ");
        if (root["force"]) {
          Serial.print("[forced]");
          disp->value = newval;
          disp->unacked = false;
        }
        else {
          Serial.print("[ignored]");
        }
        Serial.println();
      }
      else {
        disp->value = newval;
        disp->unacked = false;
      }
      updateDisplay(disp);
    }
  }
}

void checkButtons() {
  long now = millis();
  for (int i=0; i<NUM_DISPLAYS; i++) {
    Display* disp = &displays[i];
    if (digitalRead(disp->btn) == LOW && now >= disp->lastTrigger + DEBOUNCE_DELAY) {
      Serial.print("Display: button triggered for '");
      Serial.print(disp->name);
      Serial.println("'");
      disp->lastTrigger = now;
      disp->value++;
      disp->dirty = true;
      disp->unacked = true;
      updateDisplay(disp);
    }
  }
}

long lastUpdate = 0;
const long UPDATE_INTERVAL = 1000;
void maybeUpdate() {
  long now = millis();
  if (now > lastUpdate + UPDATE_INTERVAL) {
    lastUpdate = now;
    Serial.println("Display: requesting data update");
    Serial.println("{}");
  }
}

void sendUpdates() {
  long now = millis();
//  if (now < lastUpdate + UPDATE_INTERVAL) return; //avoid spamming the netcode

  StaticJsonBuffer<200> jsonBuffer;
  JsonObject& root = jsonBuffer.createObject();
  bool needsUpdate = false;
  for (int i=0; i<NUM_DISPLAYS; i++) {
    Display* disp = &displays[i];
    if (disp->dirty || (disp->unacked && (now > lastUpdate + UPDATE_INTERVAL))) {
      needsUpdate = true;
      disp->dirty = false;
      root[disp->name] = disp->value;
    }
  }
  if (needsUpdate) {
    lastUpdate = now;
    root.printTo(Serial);
    Serial.println();
  }
}

void setup()
{
  Serial.begin(115200);
  Serial.println("Display: init");

//  Serial.setTimeout(100);

  for (int i=0; i<NUM_DISPLAYS; i++) {
    initDisplay(&displays[i]);
  }
}

void loop()
{
  if (Serial.available() > 0) {
//    String data = Serial.readString();
    String data = Serial.readStringUntil('\n');
    data.trim();
    if (data.charAt(0) == '{') {
      updateDisplaysFrom(data);
    }
    else {
//      Serial.print("Display: ignored: ");
//      Serial.println(data);
    }
  }
  checkButtons();
  sendUpdates();
  maybeUpdate();
}

