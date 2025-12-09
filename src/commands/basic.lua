--[[
    Basic Commands
    Core utility commands for the bot
]]

local commands = {}

-- Ping command
commands.ping = {
    name = 'ping',
    description = 'Check bot latency',
    aliases = { 'pong', 'latency' },

    execute = function(ctx)
        local start = os.clock()
        ctx.channel:send({
            embed = {
                description = 'Pinging...',
                color = 0xFF003D
            }
        }):then(function(msg)
            local latency = math.floor((os.clock() - start) * 1000)
            msg:setContent('')
            msg:setEmbed({
                title = 'Pong! 🏓',
                description = string.format('**Latency:** %dms', latency),
                color = 0xFF003D
            })
        end)
    end
}

-- Help command
commands.help = {
    name = 'help',
    description = 'Show all commands or info about a specific command',
    aliases = { 'commands', 'h' },

    execute = function(ctx)
        local cmdName = ctx.args[1]

        if cmdName then
            -- Show specific command help
            local cmd = ctx.commandManager:get(cmdName)
            if not cmd then
                ctx.channel:send({
                    embed = {
                        description = '❌ Command not found: ' .. cmdName,
                        color = 0xFF0000
                    }
                })
                return
            end

            local fields = {}
            if cmd.aliases and #cmd.aliases > 0 then
                table.insert(fields, {
                    name = 'Aliases',
                    value = table.concat(cmd.aliases, ', '),
                    inline = true
                })
            end
            if cmd.permissions then
                table.insert(fields, {
                    name = 'Permissions',
                    value = table.concat(cmd.permissions, ', '),
                    inline = true
                })
            end
            if cmd.ownerOnly then
                table.insert(fields, {
                    name = 'Owner Only',
                    value = 'Yes',
                    inline = true
                })
            end

            ctx.channel:send({
                embed = {
                    title = ctx.prefix .. cmd.name,
                    description = cmd.description or 'No description available',
                    fields = fields,
                    color = 0xFF003D
                }
            })
        else
            -- Show all commands grouped by category
            local allCmds = ctx.commandManager:getAll()
            local categories = {}

            for _, cmd in ipairs(allCmds) do
                local cat = cmd.category or 'Other'
                if not categories[cat] then
                    categories[cat] = {}
                end
                table.insert(categories[cat], cmd.name)
            end

            local fields = {}
            for cat, cmds in pairs(categories) do
                table.insert(fields, {
                    name = cat,
                    value = '`' .. table.concat(cmds, '`, `') .. '`',
                    inline = false
                })
            end

            ctx.channel:send({
                embed = {
                    title = 'Yuno Commands 💕',
                    description = string.format('Use `%shelp <command>` for more info', ctx.prefix),
                    fields = fields,
                    color = 0xFF003D,
                    footer = { text = 'I\'ll protect this server forever~ 💗' }
                }
            })
        end
    end
}

-- Stats command
commands.stats = {
    name = 'stats',
    description = 'Show bot statistics',
    aliases = { 'info', 'botinfo' },
    category = 'Utility',

    execute = function(ctx)
        local client = ctx.client
        local guilds = #client.guilds
        local users = 0
        for guild in client.guilds:iter() do
            users = users + #guild.members
        end

        ctx.channel:send({
            embed = {
                title = 'Yuno Statistics 💕',
                thumbnail = { url = client.user.avatarURL },
                fields = {
                    { name = 'Servers', value = tostring(guilds), inline = true },
                    { name = 'Users', value = tostring(users), inline = true },
                    { name = 'Lua Version', value = _VERSION, inline = true },
                    { name = 'Library', value = 'Discordia', inline = true },
                },
                color = 0xFF003D,
                footer = { text = 'Made with love by Yuno~ 💗' }
            }
        })
    end
}

-- Source command
commands.source = {
    name = 'source',
    description = 'Get the bot\'s source code link',
    aliases = { 'github', 'repo' },
    category = 'Utility',

    execute = function(ctx)
        ctx.channel:send({
            embed = {
                title = 'Source Code 💕',
                description = 'You can find my source code here:\nhttps://github.com/japaneseenrichmentorganization/Yuno_lua\n\nI\'m open source! Feel free to contribute~ 💗',
                color = 0xFF003D
            }
        })
    end
}

-- Shutdown command (owner only)
commands.shutdown = {
    name = 'shutdown',
    description = 'Shut down the bot',
    aliases = { 'die', 'stop' },
    ownerOnly = true,
    category = 'Owner',

    execute = function(ctx)
        ctx.channel:send({
            embed = {
                description = 'Goodbye... I\'ll be back for you~ 💔',
                color = 0xFF003D
            }
        }):then(function()
            ctx.prompt:log('INFO', 'Shutdown requested by ' .. ctx.author.tag)
            os.exit(0)
        end)
    end
}

-- Invite command
commands.invite = {
    name = 'invite',
    description = 'Get the bot invite link',
    category = 'Utility',

    execute = function(ctx)
        local clientId = ctx.client.user.id
        local inviteUrl = string.format(
            'https://discord.com/api/oauth2/authorize?client_id=%s&permissions=8&scope=bot%%20applications.commands',
            clientId
        )

        ctx.channel:send({
            embed = {
                title = 'Invite Me! 💕',
                description = string.format('[Click here to invite me to your server!](%s)\n\nI\'ll protect your server forever~ 💗', inviteUrl),
                color = 0xFF003D
            }
        })
    end
}

-- Say command (owner only)
commands.say = {
    name = 'say',
    description = 'Make the bot say something',
    ownerOnly = true,
    category = 'Owner',

    execute = function(ctx)
        if #ctx.args == 0 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide a message to say!',
                    color = 0xFF0000
                }
            })
            return
        end

        local message = table.concat(ctx.args, ' ')
        ctx.message:delete()
        ctx.channel:send(message)
    end
}

return commands
