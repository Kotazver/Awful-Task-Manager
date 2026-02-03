local socket = require('socket.unix')
local bear = require("bear")
local json = require("dkjson")

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
                    request.command = v.executionCode
                    goto continue
                end
            end
        end

        if not request.command then
            request = nil
            print("Invalid command")
            break
        end

        if not request.args then
            request.args = {}
            table.insert(request.args,arg)
        else
            table.insert(request.args,arg)
        end
    
        ::continue::
    end

    print(json.encode(request))
    return request
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
        local request = handleCommands(command)
        if request then
            if request.command and request.command < 0 then
                if request.command == -1 then
                    client:send(json.encode(request) .. "\n")
                    client:close()
                    os.exit()
                elseif request.command == -2 then
                    print("help")
                end
            else
                client:send(json.encode(request) .. "\n")
                local response = client:receive()
                if request.command == 1 then
                    local userData = json.decode(response)
                    for k,v in pairs(userData) do
                        print("ChatID: " .. k)
                        print("         Tasks:\n")
                        for k,v in ipairs(v.tasks) do
                            print("             ID: " .. k)
                            print("                 Name:" .. v.name)
                            print("                 Descrription:" .. v.description .. "\n")
                        end
                    end
                end
            end
        end
    end
end