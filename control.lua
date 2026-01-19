local socket = require('socket.unix')
local bear = require("bear")
local json = require("json")

COMMANDS = nil

-----------------
--- FUNCTIONS ---
-----------------

local function json_load(filename)
    local table = nil
    
    local file_to_handle = io.open(filename,"r")
    if file_to_handle then
        local file_content = file_to_handle:read("a")
        table = json.decode(file_content)
    end

    return table
end

local function handleCommands(command)
    local request = {}
    request.command = nil
    
    if not COMMANDS then
        COMMANDS = json_load("commandList.json") --[[@as table]]
    end

    for arg in command:gmatch("%S+") do
        if not request.command then
            for k,v in pairs(COMMANDS) do
                if k == arg then
                    request.command = arg
                    break
                end
            end
        end

        break
    end
    
    return COMMANDS[request.command].executionCode
end

::retry::
local client = socket.stream()
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
    local command = io.read()
    if command then
        local code = handleCommands(command)
        if code == 1 then
            print("help")
        end
    end
end