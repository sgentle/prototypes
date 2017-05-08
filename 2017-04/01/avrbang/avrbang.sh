#!/bin/bash
set -e
if kextstat | grep -q FTDI; then
  echo "Unloading FTDI kext"
  echo "Re-enable with: sudo kextload -b com.apple.driver.AppleUSBFTDI"
  sudo kextunload -b com.apple.driver.AppleUSBFTDI
fi
echo "Connect FTDI D0(TXD)->AVR D13(SCK), FTDI D1(RXD)->AVR D12(MISO), FTDI D2(RTS)->AVR D11(MOSI), FTDI D4(DTR)->AVR 1(RST)"
read -p "Press enter..."

echo "Flashing with optiboot..."
avrdude -c ft232r -p atmega328p -b 19200 -U flash:w:"optiboot_atmega328.hex" :i

echo "Setting fuses..."
avrdude -c ft232r -p atmega328p -b 19200 -U efuse:w:0xFD:m -U hfuse:w:0xDA:m -U lfuse:w:0xFF:m

