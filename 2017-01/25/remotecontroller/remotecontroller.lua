POWER = 2
BUTTON = 1

gpio.mode(POWER, gpio.OUTPUT)
gpio.mode(BUTTON, gpio.INPUT, gpio.PULLUP)

function powercycle()
  gpio.write(POWER, gpio.LOW)
  tmr.delay(100000)
  gpio.write(POWER, gpio.HIGH)
end

function button()
  gpio.mode(BUTTON, gpio.INPUT, gpio.FLOAT)
  tmr.delay(100000)
  gpio.mode(BUTTON, gpio.INPUT, gpio.PULLUP)
end

