local socket = require('socket.unix')
local bear = require("bear")

local client = socket.stream()

::retry::
local connection = client:connect('/tmp/atmsocket')
if not connection then
    print("Can't connect to socket.\nRetry? Y/n")
    local ans = io.read()
    if string.lower(ans) == ('n') then
        print(bear)
        os.exit()
    else
        goto retry
    end
end

while true do
    io.write('Enter command: ')
    local request = io.read()
    client:send(request .. '\n')
    local response = client:receive()
    print(response)
end

