--[[
    Prompt / Logging System
    Colored console output with log levels
]]

local Prompt = {}
Prompt.__index = Prompt

-- ANSI color codes
local colors = {
    reset = '\27[0m',
    bold = '\27[1m',
    red = '\27[31m',
    green = '\27[32m',
    yellow = '\27[33m',
    blue = '\27[34m',
    magenta = '\27[35m',
    cyan = '\27[36m',
    white = '\27[37m',
    pink = '\27[38;5;205m',
}

local levelColors = {
    INFO = colors.cyan,
    SUCCESS = colors.green,
    WARNING = colors.yellow,
    ERROR = colors.red,
    DEBUG = colors.magenta,
}

local levelIcons = {
    INFO = 'ℹ️ ',
    SUCCESS = '✅',
    WARNING = '⚠️ ',
    ERROR = '❌',
    DEBUG = '🔍',
}

function Prompt:new(options)
    local self = setmetatable({}, Prompt)
    options = options or {}
    self.colors = options.colors ~= false
    self.showTime = options.showTime ~= false
    self.hiddenLevels = options.hiddenLevels or {}
    return self
end

function Prompt:log(level, message)
    level = level:upper()

    -- Check if level is hidden
    for _, hidden in ipairs(self.hiddenLevels) do
        if hidden:upper() == level then
            return
        end
    end

    local output = ''

    -- Timestamp
    if self.showTime then
        local timestamp = os.date('%Y-%m-%d %H:%M:%S')
        if self.colors then
            output = output .. colors.white .. '[' .. timestamp .. '] ' .. colors.reset
        else
            output = output .. '[' .. timestamp .. '] '
        end
    end

    -- Level
    local levelColor = levelColors[level] or colors.white
    local icon = levelIcons[level] or ''

    if self.colors then
        output = output .. levelColor .. colors.bold .. '[' .. level .. ']' .. colors.reset .. ' '
    else
        output = output .. '[' .. level .. '] '
    end

    -- Icon and message
    if self.colors then
        output = output .. icon .. ' ' .. colors.pink .. message .. colors.reset
    else
        output = output .. icon .. ' ' .. message
    end

    print(output)
end

function Prompt:info(message)
    self:log('INFO', message)
end

function Prompt:success(message)
    self:log('SUCCESS', message)
end

function Prompt:warning(message)
    self:log('WARNING', message)
end

function Prompt:error(message)
    self:log('ERROR', message)
end

function Prompt:debug(message)
    self:log('DEBUG', message)
end

return Prompt
