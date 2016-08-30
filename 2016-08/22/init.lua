PIN=1 -- 1 = GPIO5

gpio.mode(PIN, gpio.INPUT, gpio.PULLUP)

print('booting unless GPIO5 low...')

if (gpio.read(PIN) == 1) then
  dofile('net2.lua')
end
