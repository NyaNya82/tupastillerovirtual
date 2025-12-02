/*
 * Smart Pill Dispenser - Arduino Code + LCD I2C
 * 
 * Includes:
 * - Servo motor control
 * - Passive buzzer (tone)
 * - LED blinking
 * - Bluetooth HC-05 communication
 * - LCD 16x2 I2C display
 * - Stop alarm using a push button
 * 
 * Command format received from Flutter:
 * ALARM;compartmentId;medicineName
 */

#include <Servo.h>
#include <SoftwareSerial.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// === Pin definitions ===
#define SERVO_PIN 10
#define BUZZER_PIN 11
#define LED_PIN 13
#define BT_RX_PIN 2   // Bluetooth TX → Arduino RX
#define BT_TX_PIN 3   // Bluetooth RX → Arduino TX
#define BUTTON_PIN 7  // Push button to stop alarm

// === Hardware objects ===
Servo compartmentServo;
SoftwareSerial bluetooth(BT_RX_PIN, BT_TX_PIN);
LiquidCrystal_I2C lcd(0x27, 16, 2);

// === Constants ===
const int COMPARTMENT_COUNT = 8;
const float DEGREES_PER_COMPARTMENT = 22.5;
const int SERVO_SPEED_DELAY = 15;
const int ALARM_DURATION = 30000;
const int BEEP_INTERVAL = 500;
const int BLINK_INTERVAL = 250;

// === State variables ===
bool alarmActive = false;
unsigned long alarmStartTime = 0;
unsigned long lastBeepTime = 0;
unsigned long lastBlinkTime = 0;
bool ledState = false;
int currentPosition = 0;

String inputBuffer = "";
String currentMedicine = "";

// ====================================================
// SETUP
// ====================================================
void setup() {
  Serial.begin(9600);
  bluetooth.begin(9600);

  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);

  pinMode(BUTTON_PIN, INPUT_PULLUP);  // Button pressed = LOW

  compartmentServo.attach(SERVO_PIN);
  compartmentServo.write(0);
  currentPosition = 0;

  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_PIN, LOW);

  // LCD Initialization
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Pill Dispenser");
  lcd.setCursor(0, 1);
  lcd.print("     Listo     ");

  Serial.println("Pill Dispenser Ready!");
  bluetooth.println("READY");

  delay(1500);
  lcd.clear();
}

// ====================================================
// MAIN LOOP
// ====================================================
void loop() {
  checkBluetoothCommands();
  handleAlarmState();
}

// ====================================================
// READ BLUETOOTH COMMANDS
// ====================================================
void checkBluetoothCommands() {
  while (Serial.available()) readChar(Serial.read());
  while (bluetooth.available()) readChar(bluetooth.read());
}

void readChar(char c) {
  if (c == '\n' || c == '\r') {
    if (inputBuffer.length() > 0) {
      processCommand(inputBuffer);
      inputBuffer = "";
    }
  } else {
    inputBuffer += c;
  }
}

// ====================================================
// PROCESS COMMAND
// ====================================================
void processCommand(String cmd) {
  cmd.trim();
  Serial.println("Received: " + cmd);

  if (cmd.startsWith("ALARM;")) {
    int first = cmd.indexOf(';');
    int second = cmd.indexOf(';', first + 1);

    if (second == -1) {
      Serial.println("Invalid command format.");
      return;
    }

    int compartmentId = cmd.substring(first + 1, second).toInt();
    compartmentId = compartmentId - 1;  // AHORA RECIBE 1–8, CONVIERTE A 0–7

    currentMedicine = cmd.substring(second + 1);
    currentMedicine.trim();

    if (currentMedicine.length() > 16) {
      currentMedicine = currentMedicine.substring(0, 16);
    }

    triggerAlarm(compartmentId);
  }
  else if (cmd == "STOP") {
    stopAlarm();
  }
  else {
    Serial.println("Unknown command");
  }
}

// ====================================================
// TRIGGER ALARM
// ====================================================
void triggerAlarm(int compartmentId) {
  if (compartmentId < 0 || compartmentId >= COMPARTMENT_COUNT) {
    Serial.println("Invalid compartment");
    return;
  }

  Serial.println("Triggering compartment " + String(compartmentId + 1));

  int targetPosition = round(compartmentId * DEGREES_PER_COMPARTMENT);
  moveServoToPosition(targetPosition);

  alarmActive = true;
  alarmStartTime = millis();
  lastBeepTime = 0;
  lastBlinkTime = 0;

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Tome su pastilla");

  lcd.setCursor(0, 1);
  lcd.print(currentMedicine);

  bluetooth.println("ALARM_STARTED");
}

// ====================================================
// STOP ALARM
// ====================================================
void stopAlarm() {
  if (!alarmActive) return;

  alarmActive = false;
  noTone(BUZZER_PIN);
  digitalWrite(LED_PIN, LOW);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Alarma detenida");
  lcd.setCursor(0, 1);
  lcd.print("OK");

  bluetooth.println("ALARM_STOPPED");
  Serial.println("Alarm stopped");
}

// ====================================================
// MOVE SERVO
// ====================================================
void moveServoToPosition(int targetPosition) {
  int difference = targetPosition - currentPosition;

  if (difference > 180) difference -= 360;
  if (difference < -180) difference += 360;

  int step = (difference > 0) ? 1 : -1;
  int steps = abs(difference);

  for (int i = 0; i < steps; i++) {
    currentPosition += step;
    if (currentPosition >= 360) currentPosition = 0;
    if (currentPosition < 0) currentPosition = 359;

    compartmentServo.write(currentPosition);
    delay(SERVO_SPEED_DELAY);
  }

  currentPosition = targetPosition;
  compartmentServo.write(currentPosition);
}

// ====================================================
// HANDLE ALARM STATE
// ====================================================
void handleAlarmState() {
  if (!alarmActive) return;

  unsigned long now = millis();

  // 🔴 STOP ALARM WHEN BUTTON PRESSED
  if (digitalRead(BUTTON_PIN) == LOW) {
    stopAlarm();
    return;
  }

  // Auto stop after duration
  //if (now - alarmStartTime >= ALARM_DURATION) {
  //  stopAlarm();
  //  return;
  //}

  // Buzzer beep (passive, tone)
  if (now - lastBeepTime >= BEEP_INTERVAL) {
    tone(BUZZER_PIN, 2000, 300);
    lastBeepTime = now;
  }

  // LED blink
  if (now - lastBlinkTime >= BLINK_INTERVAL) {
    ledState = !ledState;
    digitalWrite(LED_PIN, ledState);
    lastBlinkTime = now;
  }
}
