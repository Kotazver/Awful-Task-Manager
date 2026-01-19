local json = require("json")
local socket = require('socket.unix')

--GLOBAL VARIABLES--

local ACTIVE_DIALOGUES = {}
local LOADED_USER_DATA = {}


-- FUNCTIONS --

local function getRandomBytes(amount)
    local urand = io.open("/dev/random","rb")
    local bytes = nil

    if not urand then
        print("Error while getting random bytes")
    else
        bytes = urand:read(amount)
    end

    return bytes
end

local function load_config()
    local encoded_file = nil
    local config = nil
    
    --- try to open config file if succeeds encode it and return ---
    local config_file = io.open('config.json',"r")
    if config_file then
        encoded_file = config_file:read("a")
        config = json.decode(encoded_file)
    else
        print("Can't load config file as result can't start bot")
    end

    return config
end

local function rewrite_config(k,v)
    local config = load_config()
    config[k] = v
    local encoded_config = json.encode(config)
    local config_file = io.open('config.json','w+')
    if config_file then
        config_file:write(encoded_config)
        config_file:close()
    end
end

local function import_user_data(chat_id_to_import)
    -- find path of the data and get id as string to use in tables --
    local index = tostring(chat_id_to_import)
    local path = 'UserData/' .. index .. '.json'
    
    -- read file with user data and put it into loaded_data --
    local file_to_read = io.open(path,'r')
    if file_to_read then
        local loaded_data_json = file_to_read:read("a")
        if LOADED_USER_DATA[index] then
            table.insert(LOADED_USER_DATA[index],json.decode(loaded_data_json))
        elseif not LOADED_USER_DATA[index] then
            LOADED_USER_DATA[index] = json.decode(loaded_data_json)
        end
    else
        print("Can't find user data ".. chat_id_to_import)
        LOADED_USER_DATA[index] = {}
        LOADED_USER_DATA[index].tasks = {}
    end
end

local function export_user_data(chat_id_to_export)
    -- convert chat id into string to use it as table key -- 
    local index = tostring(chat_id_to_export)

    -- make data ready to be handled and exported --
    local data_to_export = LOADED_USER_DATA[index]

    -- convert user data to json string --
    local data_to_export_json = json.encode(data_to_export)

    -- write file --
    local file_to_write = io.open('UserData/' .. index .. '.json','w+')
    
    -- check if path exists if not print error --
    if file_to_write then
        file_to_write:write(data_to_export_json) -- sdaklmxzc''la[psod[sa-iiwidqjwiMAMASHA-RAIWELLA-SHLYONDRAsaodks[dk;'xz;ok;'kdasd]]]' --
        file_to_write:close()
    else
        print('Something went wrong while writing data')
    end

    LOADED_USER_DATA[index] = nil
end

local function add_new_task(chat_id,bot)
    -- local variables --
    local task_data = {}

    -- request task data and description --
    bot.send_message(chat_id,'Enter task name:')
    local task_name = coroutine.yield()
    task_data.name = task_name
    bot.send_message(chat_id,'Enter task description:')
    local task_description = coroutine.yield()
    task_data.description = task_description

    -- convert chat id into string to use it as table key --
    local index = tostring(chat_id)

    -- check if tasks in user data exists if not create empty dictionary --
    if not LOADED_USER_DATA[index] then
        LOADED_USER_DATA[index] = {}
        LOADED_USER_DATA[index].tasks = {}
    elseif LOADED_USER_DATA[index] then
        if not LOADED_USER_DATA[index].tasks then
            LOADED_USER_DATA[index].tasks = {}
        end
    end

    -- insert task to all user tasks
    table.insert(LOADED_USER_DATA[index].tasks,task_data)

    -- remove dialogue form ACTIVE_DIALOGUES -- 
    ACTIVE_DIALOGUES[chat_id] = nil
end



----------------------------------------------------
-- MAIN MESSAGE HANDLING FUNCTION AND BOT RUNTIME --
----------------------------------------------------

local bot = require('telegram-bot-lua.core').configure(load_config().token)

function bot.on_message(message)
    local text = message.text
    local chat_id = message.chat.id
    local index = tostring(chat_id)

    -- killing two targets with one arrow by checking if user data loaded and changing last message time --
    if not LOADED_USER_DATA[index] then
        import_user_data(chat_id)
    end
    
    LOADED_USER_DATA[index].last_message_date = message.date
    
    if ACTIVE_DIALOGUES[chat_id] then
        -- resume active dialogue --
        local resumed_co = ACTIVE_DIALOGUES[chat_id]
        local success = coroutine.resume(resumed_co,text)

        if not success then
            bot.send_message(chat_id,'Sorry, something went wrong:(')

            -- remove dialogue from list --
            ACTIVE_DIALOGUES[chat_id] = nil
        end


    elseif text == '/addnewtask' then
        -- create coroutine --
        local co = coroutine.create(function ()
            add_new_task(chat_id,bot)
        end)

        -- start coroutine --
        coroutine.resume(co)

        -- add coroutine to ACTIVE_DIALOGUES --
        ACTIVE_DIALOGUES[chat_id] = co


    elseif text == '/checkcurrenttasks' then
        print(json.encode(LOADED_USER_DATA))
    end
end




-- bot configurating values --
local limit = nil
local timeout = nil
local offset = nil
local autosave_time = 5 -- time in seconds to autosave if user idle --


-- socket setup --
local path = '/tmp/atmsocket' -- socket path --
local server = socket.stream()
os.remove(path)
server:bind(path)
server:listen(5)
server:settimeout(0)
local client = nil

-- bot runtime --
while true do
    
    -- get and handle requests form client(admin)
    if client then
        client:settimeout(0)
        local request = client:receive()
        if request then
            if request == '/test' then
                client:send('Connected.\n')
            elseif request == '/help' then
                client:send()
            end
        end
    
    elseif not client then
        client = server:accept()
    end


    -- getting and handling updates --
    local updates = bot.get_updates(timeout, offset, limit, "message")
    if updates and type(updates) == 'table' and updates.result then
        for _, v in pairs(updates.result) do
            bot.process_update(v)
            offset = v.update_id + 1
        end
    end
    -- check users id for autosave --
    if next(LOADED_USER_DATA) then
        for id, value in pairs(LOADED_USER_DATA) do
            if value.last_message_date + autosave_time < os.time() then
                print(json.encode(LOADED_USER_DATA))
                export_user_data(id)
            end
        end
    end
end