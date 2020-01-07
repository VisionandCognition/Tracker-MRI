/*
  Serial communication for 3T DBS stimulator

  Hardware is Arduino MKR Zero

  Using Serial1 for Bluetooth

  20200107 Joris Coppens
*/



// inslude the SPI library:
#include <SPI.h>


const uint8_t slaveSelectPin = 2; //SPI Slave Select pin
const uint8_t SDApin = 11;
const uint8_t SCLpin = 12;
const uint8_t pulsePin = 6;
const uint8_t clearPin = 4;
const uint8_t latchPin = 5;


String inputString = "";      // a String to hold incoming data
bool stringComplete = false;  // whether the string is complete
int amplitude = 1000;
int frequency = 0;
int isi = 5000;
int volts = 127;
int width = 50;
volatile int nrep = 0;
volatile int n = 1;
int interactive = true;



void serialEventRun(void) {
  if (Serial1.available()) serialEvent();
}


void setup() {
  // initialize serial:
  Serial1.begin(9600);
  //Serial1.begin(115200);
  while (!Serial1)
  {
    delay(10);
  }
  // reserve 200 bytes for the inputString:
  inputString.reserve(200);
  analogWriteResolution(10);
  // initialize SPI:
  SPI.begin();
  SPI.beginTransaction(SPISettings(12000000, MSBFIRST, SPI_MODE0));
  pinMode(clearPin, OUTPUT);
  pinMode(slaveSelectPin, OUTPUT);
  pinMode(SDApin, OUTPUT);
  pinMode(SCLpin, OUTPUT);
  pinMode(pulsePin, OUTPUT);
  pinMode(latchPin, OUTPUT);
  digitalWrite(latchPin, HIGH);
  digitalPotWrite(10);
  setmax(10);
}

void setmax(byte val)
{
  digitalWrite(latchPin, HIGH);
  digitalWrite(clearPin, HIGH);
  //  delayMicroseconds(5);
  SPI.transfer(val);
  digitalWrite(latchPin, LOW);
  //  delayMicroseconds(5);
  digitalWrite(clearPin, LOW);
}

void digitalPotWrite(unsigned int command)
{
  //local constants
  const byte WRITE_WIPER = 0x00; //command to write to the wiper register only
  //command the new wiper setting (requires sending 3 bytes)
  digitalWrite(slaveSelectPin, LOW); //set the SS pin low to select the chip
  shiftOut(SDApin, SCLpin, MSBFIRST, WRITE_WIPER);
  shiftOut(SDApin, SCLpin, MSBFIRST, highByte(command << 6));
  shiftOut(SDApin, SCLpin, MSBFIRST, lowByte(command << 6));
  digitalWrite(slaveSelectPin, HIGH); //set the SS pin high to "latch the data into the appropriate control register" (see datasheet pg. 14)
}

void stimulate()
{
  noInterrupts();
  setmax(9);
  digitalWrite(pulsePin, HIGH);
  delayMicroseconds(width);
  digitalWrite(pulsePin, LOW);
  setmax(6);
  digitalWrite(pulsePin, HIGH);
  delayMicroseconds(width);
  digitalWrite(pulsePin, LOW);
  setmax(10); // Passive charge balance on high side
  //setmax(5); //Passive charge balance on low side
  interrupts();
}

void loop() {

  while (n < nrep)
  {
    stimulate();
    delayMicroseconds(isi);
    n++;
  }
  // print the string when a newline arrives:
  if (stringComplete) {
    if (interactive)
    {
      Serial1.println(inputString);
    }
    // clear the string:
    inputString = "";
    stringComplete = false;
  }
  //Serial1.println("finished");
}



/*
  SerialEvent occurs whenever a new data comes in the hardware serial RX. This
  routine is run between each time loop() runs, so using delay inside loop can
  delay response. Multiple bytes of data may be available.
*/
void serialEvent() {
  while (Serial1.available()) {
    // get the new byte:
    char inChar = (char)Serial1.read();
    // add it to the inputString:
    inputString += inChar;
    // if the incoming character is a carriage return, set a flag so the main loop can
    // do something with it:
    if (inChar == '\r') {
      stringComplete = true;
      interpretCommand(); // Handle the requested command

    }
  }
}

void interpretCommand()
{
  // Expecting strings in the form "cxxxx" where c is the command indicating which parameter to change,
  // and xxxx the value. Line ends are defined above as '\r'.
  if (inputString.startsWith("a"))
  {
    inputString.setCharAt(0, '0');
    amplitude = inputString.toInt();
    amplitude = constrain(amplitude, 0, 1023);
    Serial1.print("amplitude = ");
    Serial1.println(amplitude);
    digitalPotWrite(1023 - amplitude);
  }

  if (inputString.startsWith("f"))
  {
    inputString.setCharAt(0, '0');
    frequency = inputString.toInt();
    isi = (1000000 / frequency) - (2 * width + 10);
    Serial1.print("frequency = ");
    Serial1.print(frequency);
    Serial1.println(" (Hz)");
    isi = constrain(isi, 100, 16383);
    Serial1.print("interstimulus interval = ");
    Serial1.print(isi);
    Serial1.println(" (us)");
  }

  if (inputString.startsWith("i"))
  {
    float f = 0;
    inputString.setCharAt(0, '0');
    isi = inputString.toInt();
    isi = constrain(isi, 100, 16383);
    Serial1.print("interstimulus interval = ");
    Serial1.print(isi);
    Serial1.println(" (us)");
    Serial1.print("total stimulus duration = ");
    Serial1.print(isi + width + 5 + width);
    Serial1.println(" (us)");
    f = 1e6 / (isi + width + 5 + width);
    Serial1.print("frequency = ");
    Serial1.print(f);
    Serial1.println(" (Hz)");
  }

  if (inputString.startsWith("n"))
  {
    inputString.setCharAt(0, '0');
    nrep = inputString.toInt();
    n = nrep + 1; // The stimulus is only started by the command 's'
    Serial1.print("number of repetitions = ");
    Serial1.println(nrep);
    Serial1.println("You loose control after starting the stimulus train until it has ended.");
    Serial1.println("Interupts are disabled on timing critical stimulus delivery");
  }

  if (inputString.startsWith("q")) // quit
  {
    n = nrep + 1;
  }

  if (inputString.startsWith("s")) //start
  {
    Serial1.println("started a stimulation");
    n = 0;
  }

  if (inputString.startsWith("v"))
  {
    inputString.setCharAt(0, '0');
    volts = inputString.toInt();
    volts = constrain(volts, 0, 1023);
    analogWrite(A0, volts);
    Serial1.print("voltage = ");
    Serial1.println(volts);
  }

  if (inputString.startsWith("w"))
  {
    inputString.setCharAt(0, '0');
    width = inputString.toInt();
    width = constrain(width, 10, 2000); // Keep below 2 ms, unless more freedom is requested
    Serial1.print("stimulus width = ");
    Serial1.print(width);
    Serial1.println(" (us)");
  }
}
