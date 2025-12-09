--[[
    Configuration Manager
    Handles loading and accessing configuration values
]]

local Config = {}
Config.__index = Config

function Config:new(filepath)
    local self = setmetatable({}, Config)
    self.filepath = filepath
    self.data = {}
    self.defaults = {
        ['bot.token'] = '',
        ['bot.prefix'] = '?',
        ['bot.status'] = 'for levels ♡',
        ['bot.activity_type'] = 'watching',
        ['bot.owner_ids'] = {},

        ['database.path'] = 'data/yuno.db',

        ['leveling.xp_per_message_min'] = 15,
        ['leveling.xp_per_message_max'] = 25,
        ['leveling.xp_per_voice_min'] = 18,
        ['leveling.xp_per_voice_max'] = 30,
        ['leveling.level_divisor'] = 50,

        ['spam.max_warnings'] = 3,
        ['spam.message_limit'] = 4,
        ['spam.warning_timeout'] = 15,

        ['colors.primary'] = 0xFF003D,
        ['colors.success'] = 0x00FF00,
        ['colors.error'] = 0xFF0000,
        ['colors.warning'] = 0xFFAA00,
        ['colors.info'] = 0x3498DB,
    }
    return self
end

function Config:load()
    -- Try to load the config file
    local ok, result = pcall(function()
        return dofile(self.filepath)
    end)

    if ok and type(result) == 'table' then
        self.data = result
        return true
    end

    -- Try loading from environment
    local token = os.getenv('DISCORD_TOKEN')
    if token then
        self.data = { bot = { token = token } }
        return true
    end

    return false, result
end

function Config:get(key, default)
    -- Split key by dots
    local parts = {}
    for part in key:gmatch('[^.]+') do
        table.insert(parts, part)
    end

    -- Navigate the data structure
    local value = self.data
    for _, part in ipairs(parts) do
        if type(value) == 'table' then
            value = value[part]
        else
            value = nil
            break
        end
    end

    -- Return value, default, or global default
    if value ~= nil then
        return value
    elseif default ~= nil then
        return default
    else
        return self.defaults[key]
    end
end

function Config:set(key, value)
    local parts = {}
    for part in key:gmatch('[^.]+') do
        table.insert(parts, part)
    end

    local current = self.data
    for i = 1, #parts - 1 do
        if current[parts[i]] == nil then
            current[parts[i]] = {}
        end
        current = current[parts[i]]
    end
    current[parts[#parts]] = value
end

function Config:isOwner(userId)
    local owners = self:get('bot.owner_ids', {})
    for _, id in ipairs(owners) do
        if id == userId then
            return true
        end
    end
    return false
end

function Config:save()
    local function serialize(tbl, indent)
        indent = indent or 0
        local result = "{\n"
        local prefix = string.rep("    ", indent + 1)

        for k, v in pairs(tbl) do
            local key = type(k) == 'string' and ('["' .. k .. '"]') or ('[' .. k .. ']')
            local value

            if type(v) == 'table' then
                value = serialize(v, indent + 1)
            elseif type(v) == 'string' then
                value = '"' .. v:gsub('"', '\\"') .. '"'
            elseif type(v) == 'boolean' then
                value = v and 'true' or 'false'
            else
                value = tostring(v)
            end

            result = result .. prefix .. key .. ' = ' .. value .. ',\n'
        end

        return result .. string.rep("    ", indent) .. "}"
    end

    local content = "-- Yuno Configuration\nreturn " .. serialize(self.data) .. "\n"

    local file = io.open(self.filepath, 'w')
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

return Config
