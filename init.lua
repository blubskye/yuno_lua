#!/usr/bin/env lua
--[[
    Yuno Gasai Discord Bot - Lua Edition
    "I'll protect this server forever... just for you~" 💗

    Dependencies:
    - Luvit (https://luvit.io/) - Lua + libuv runtime
    - Discordia (https://github.com/SinisterRectus/Discordia) - Discord API wrapper

    Installation:
    1. Install Luvit: https://luvit.io/install.html
    2. lit install SinisterRectus/discordia
    3. Copy config.example.lua to config.lua and add your token
    4. Run: luvit init.lua
]]

local discordia = require('discordia')
local client = discordia.Client()

-- Add src to package path
local path = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
package.path = path .. "src/?.lua;" .. path .. "src/lib/?.lua;" .. package.path

-- Load modules
local Config = require('lib/config')
local Database = require('lib/database')
local CommandManager = require('lib/command_manager')
local Prompt = require('lib/prompt')

-- Initialize components
local config = Config:new('config.lua')
local prompt = Prompt:new({ colors = true })
local db = Database:new(config:get('database.path', 'data/yuno.db'))
local commandManager = CommandManager:new(config:get('bot.prefix', '?'))

-- Load all commands
local function loadCommands()
    local commands = {
        'commands/basic',
        'commands/moderation',
        'commands/leveling',
        'commands/fun',
        'commands/configuration',
    }

    for _, cmdPath in ipairs(commands) do
        local ok, err = pcall(function()
            local cmds = require(cmdPath)
            if type(cmds) == 'table' then
                for name, cmd in pairs(cmds) do
                    commandManager:register(cmd)
                end
            end
        end)
        if ok then
            prompt:log('INFO', 'Loaded: ' .. cmdPath)
        else
            prompt:log('ERROR', 'Failed to load ' .. cmdPath .. ': ' .. tostring(err))
        end
    end
end

-- Bot ready event
client:on('ready', function()
    prompt:log('SUCCESS', string.format('Logged in as %s (%s)', client.user.tag, client.user.id))
    prompt:log('INFO', string.format('Serving %d guilds', #client.guilds))

    -- Set presence
    local status = config:get('bot.status', 'for levels ♡')
    local activityType = config:get('bot.activity_type', 'watching')
    client:setGame({
        name = status,
        type = activityType == 'watching' and 3 or
               activityType == 'listening' and 2 or
               activityType == 'streaming' and 1 or 0
    })

    prompt:log('INFO', 'Yuno is ready to protect your server~ 💕')
end)

-- Message handler
client:on('messageCreate', function(message)
    -- Ignore bots
    if message.author.bot then return end

    -- Get guild prefix (or default)
    local prefix = config:get('bot.prefix', '?')
    if message.guild then
        local guildPrefix = db:getGuildPrefix(message.guild.id)
        if guildPrefix then
            prefix = guildPrefix
        end
    end

    -- Check if message starts with prefix
    if not message.content:sub(1, #prefix) == prefix then
        -- Handle XP if leveling enabled
        if message.guild then
            local levelingEnabled = db:isLevelingEnabled(message.guild.id)
            if levelingEnabled then
                local xp = math.random(15, 25)
                db:addUserXP(message.guild.id, message.author.id, xp)
            end
        end
        return
    end

    -- Parse and execute command
    local content = message.content:sub(#prefix + 1)
    local context = {
        client = client,
        message = message,
        guild = message.guild,
        channel = message.channel,
        author = message.author,
        member = message.member,
        db = db,
        config = config,
        prompt = prompt,
        prefix = prefix,
    }

    commandManager:execute(context, content)
end)

-- Member join handler
client:on('memberJoin', function(member)
    local guild = member.guild

    -- Check if welcome messages are enabled
    local welcomeEnabled = db:isWelcomeEnabled(guild.id)
    if not welcomeEnabled then return end

    local welcomeData = db:getWelcomeConfig(guild.id)
    if not welcomeData then return end

    -- Format message
    local msg = welcomeData.message or "Welcome {member} to {guild}!"
    msg = msg:gsub("{member}", member.user.mentionString)
    msg = msg:gsub("{user}", member.user.username)
    msg = msg:gsub("{guild}", guild.name)
    msg = msg:gsub("{count}", tostring(#guild.members))

    -- Send to channel
    if welcomeData.channel_id then
        local channel = guild:getChannel(welcomeData.channel_id)
        if channel then
            channel:send({
                embed = {
                    title = "Welcome to " .. guild.name .. "! 💕",
                    description = msg,
                    color = 0xFF003D,
                    thumbnail = { url = member.user.avatarURL },
                    footer = { text = "Member #" .. tostring(#guild.members) }
                }
            })
        end
    end

    -- Send DM if enabled
    if welcomeData.dm_enabled then
        local ok, err = pcall(function()
            member.user:send({
                embed = {
                    title = "Welcome to " .. guild.name .. "! 💕",
                    description = msg,
                    color = 0xFF003D,
                }
            })
        end)
        if not ok then
            prompt:log('WARNING', 'Could not DM ' .. member.user.tag)
        end
    end
end)

-- Guild join handler
client:on('guildCreate', function(guild)
    prompt:log('INFO', 'Joined guild: ' .. guild.name .. ' (' .. guild.id .. ')')
    db:initGuild(guild.id)
end)

-- Error handler
client:on('error', function(err)
    prompt:log('ERROR', 'Discord error: ' .. tostring(err))
end)

-- Main
local function main()
    prompt:log('INFO', '💕 Starting Yuno Gasai Discord Bot (Lua Edition) 💕')

    -- Load config
    local ok, err = config:load()
    if not ok then
        prompt:log('ERROR', 'Failed to load config: ' .. tostring(err))
        prompt:log('INFO', 'Copy config.example.lua to config.lua and add your token')
        os.exit(1)
    end

    -- Initialize database
    db:init()

    -- Load commands
    loadCommands()

    -- Get token
    local token = config:get('bot.token')
    if not token or token == '' or token == 'YOUR_TOKEN_HERE' then
        prompt:log('ERROR', 'No valid Discord token found in config.lua')
        os.exit(1)
    end

    -- Connect
    prompt:log('INFO', 'Connecting to Discord...')
    client:run('Bot ' .. token)
end

main()
