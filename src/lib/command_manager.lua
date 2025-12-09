--[[
    Command Manager
    Handles command registration and execution
]]

local CommandManager = {}
CommandManager.__index = CommandManager

function CommandManager:new(defaultPrefix)
    local self = setmetatable({}, CommandManager)
    self.commands = {}
    self.aliases = {}
    self.defaultPrefix = defaultPrefix or '?'
    return self
end

function CommandManager:register(command)
    if not command.name then
        error('Command must have a name')
    end

    local name = command.name:lower()
    self.commands[name] = command

    -- Register aliases
    if command.aliases then
        for _, alias in ipairs(command.aliases) do
            self.aliases[alias:lower()] = name
        end
    end
end

function CommandManager:get(name)
    name = name:lower()

    -- Check if it's an alias
    if self.aliases[name] then
        name = self.aliases[name]
    end

    return self.commands[name]
end

function CommandManager:getAll()
    local result = {}
    for _, cmd in pairs(self.commands) do
        table.insert(result, cmd)
    end
    return result
end

function CommandManager:parseArgs(content)
    local args = {}
    local current = ''
    local inQuote = false
    local quoteChar = nil

    for i = 1, #content do
        local char = content:sub(i, i)

        if (char == '"' or char == "'") and not inQuote then
            inQuote = true
            quoteChar = char
        elseif char == quoteChar and inQuote then
            inQuote = false
            quoteChar = nil
            if #current > 0 then
                table.insert(args, current)
                current = ''
            end
        elseif char == ' ' and not inQuote then
            if #current > 0 then
                table.insert(args, current)
                current = ''
            end
        else
            current = current .. char
        end
    end

    if #current > 0 then
        table.insert(args, current)
    end

    return args
end

function CommandManager:execute(ctx, content)
    local args = self:parseArgs(content)
    if #args == 0 then return end

    local cmdName = args[1]:lower()
    table.remove(args, 1)

    local command = self:get(cmdName)
    if not command then return end

    -- Check permissions
    if command.ownerOnly and not ctx.config:isOwner(ctx.author.id) then
        ctx.channel:send({
            embed = {
                description = '❌ This command can only be used by bot owners.',
                color = 0xFF0000
            }
        })
        return
    end

    if command.permissions and ctx.member then
        for _, perm in ipairs(command.permissions) do
            if not ctx.member:hasPermission(perm) then
                ctx.channel:send({
                    embed = {
                        description = '❌ You don\'t have permission to use this command.',
                        color = 0xFF0000
                    }
                })
                return
            end
        end
    end

    if command.guildOnly and not ctx.guild then
        ctx.channel:send({
            embed = {
                description = '❌ This command can only be used in a server.',
                color = 0xFF0000
            }
        })
        return
    end

    -- Execute command
    ctx.args = args
    ctx.commandManager = self

    local ok, err = pcall(function()
        command.execute(ctx)
    end)

    if not ok then
        ctx.prompt:log('ERROR', 'Command error (' .. cmdName .. '): ' .. tostring(err))
        ctx.channel:send({
            embed = {
                title = '❌ Error',
                description = 'An error occurred while executing the command.',
                color = 0xFF0000
            }
        })
    end
end

return CommandManager
