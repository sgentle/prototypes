-- ID, baud, data, parity, stop, echo
uart.setup(0, 115200, 8, 0, 1, 0)

function trim(s)
  return s:match'^%s*(.*%S)' or ''
end

posting = false
uart.on('data', '\n', function(data)
  data = trim(data)
  if data:sub(1,1) == '{' then
    if posting then
      uart.write(0, 'Net: previous request still waiting\r\n')
    else
      uart.write(0, 'Net: sending request: '..data..'\r\n')
      posting = true
      http.post('http://rlvsinternet.samgentle.com/panel?secret=xxx',
        'Content-Type: application/json\r\n',
        data,
        function(code, data)
          posting = false
          if (code == 200) then
            uart.write(0, 'Net: request succeeded\r\n')
            uart.write(0, data .. '\r\n')
          elseif data then
            uart.write(0, 'Net: error '..code..': '..data..'\r\n')
          else
            uart.write(0, 'Net: error '..code..'\r\n')
          end
        end)
    end
  elseif data:sub(1,1) == '/' then
    if data == '/quit' then
      uart.write(0, 'Net: quitting...\r\n')
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
