-- ID, baud, data, parity, stop, echo
uart.setup(0, 115200, 8, 0, 1, 0)

function trim(s)
  return s:match'^%s*(.*%S)' or ''
end

socket = nil
sending = false

function connect()
  socket = net.createConnection(net.TCP, 0)

  uart.write(0, 'Net: connecting to backend...\r\n')
  socket:connect(9999, 'rlvi-backend.samgentle.com')

  socket:on('connection', function()
    uart.write(0, 'Net: connected to backend\r\n')
    socket:send('xxx\n') --secret
  end)
  socket:on('reconnection', function()
    uart.write(0, 'Net: reconnected to backend\r\n')
    socket:send('xxx\n')
  end)
  socket:on('disconnection', function()
    uart.write(0, 'Net: connection lost\r\n')
    tmr.alarm(0, 1000, tmr.ALARM_SINGLE, function()
      connect()
    end)
  end)

  socket:on('receive', function(sock, data) uart.write(0, data) end)

  socket:on('sent', function() sending = false end)
end

connect()

uart.on('data', '\n', function(data)
  data = trim(data)
  if data:sub(1,1) == '{' then
    if data:sub(2,2) == '}' then return end -- Ignore empty objects

    if sending then
      uart.write(0, 'Net: previous request still waiting\r\n')
    else
      if socket then
        uart.write(0, 'Net: sending request: '..data..'\r\n')
        socket:send(data..'\r\n')
      else
        uart.write(0, 'Net: ignoring request while disconnected: '..data..'\r\n')
      end
    end
  elseif data:sub(1,1) == '/' then
    if data == '/quit' then
      uart.write(0, 'Net: quitting...\r\n')
      socket:close()
      tmr.unregister(0)
      node.task.post(function()
        uart.setup(0, 115200, 8, 0, 1, 1)
        uart.on('data')
      end)
    else
      uart.write(0, 'Net: unrecognised command: '..data..'\r\n')
    end
  else
    -- uart.write(0, 'Net: ignored: '..data..'\r\n')
  end
end, 0)

uart.write(0, 'Net: ready\r\n')
