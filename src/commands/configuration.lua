--[[
    Configuration Commands
    Server and bot configuration commands
]]

local commands = {}

-- Set prefix command
commands.setprefix = {
    name = 'setprefix',
    description = 'Change the bot prefix for this server',
    aliases = { 'prefix' },
    category = 'Configuration',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local newPrefix = ctx.args[1]

        if not newPrefix then
            local currentPrefix = ctx.db:getGuildPrefix(ctx.guild.id) or ctx.config:get('bot.prefix', '?')
            ctx.channel:send({
                embed = {
                    description = string.format('Current prefix: `%s`\nUsage: `%ssetprefix <new prefix>`', currentPrefix, currentPrefix),
                    color = 0xFF003D
                }
            })
            return
        end

        if #newPrefix > 5 then
            ctx.channel:send({
                embed = {
                    description = '❌ Prefix must be 5 characters or less.',
                    color = 0xFF0000
                }
            })
            return
        end

        ctx.db:setGuildPrefix(ctx.guild.id, newPrefix)

        ctx.channel:send({
            embed = {
                description = string.format('✅ Prefix changed to `%s`', newPrefix),
                color = 0x00FF00
            }
        })
    end
}

-- Config command
commands.config = {
    name = 'config',
    description = 'View server configuration',
    aliases = { 'settings' },
    category = 'Configuration',
    guildOnly = true,

    execute = function(ctx)
        local prefix = ctx.db:getGuildPrefix(ctx.guild.id) or ctx.config:get('bot.prefix', '?')
        local levelingEnabled = ctx.db:isLevelingEnabled(ctx.guild.id)
        local welcomeEnabled = ctx.db:isWelcomeEnabled(ctx.guild.id)

        ctx.channel:send({
            embed = {
                title = ctx.guild.name .. ' Configuration',
                thumbnail = { url = ctx.guild.iconURL },
                fields = {
                    { name = 'Prefix', value = '`' .. prefix .. '`', inline = true },
                    { name = 'Leveling', value = levelingEnabled and '✅ Enabled' or '❌ Disabled', inline = true },
                    { name = 'Welcome Messages', value = welcomeEnabled and '✅ Enabled' or '❌ Disabled', inline = true },
                },
                color = 0xFF003D
            }
        })
    end
}

-- Toggle leveling command
commands.toggleleveling = {
    name = 'toggleleveling',
    description = 'Enable or disable the leveling system',
    aliases = { 'setleveling' },
    category = 'Configuration',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local current = ctx.db:isLevelingEnabled(ctx.guild.id)
        local newValue = not current
        ctx.db:setLevelingEnabled(ctx.guild.id, newValue)

        ctx.channel:send({
            embed = {
                description = string.format('✅ Leveling system %s.', newValue and 'enabled' or 'disabled'),
                color = 0x00FF00
            }
        })
    end
}

-- Init guild command (owner only)
commands.initguild = {
    name = 'initguild',
    description = 'Initialize guild in database',
    aliases = { 'init-guild' },
    category = 'Configuration',
    guildOnly = true,
    ownerOnly = true,

    execute = function(ctx)
        ctx.db:initGuild(ctx.guild.id)

        ctx.channel:send({
            embed = {
                description = '✅ Guild initialized in database.',
                color = 0x00FF00
            }
        })
    end
}

-- Set welcome channel command
commands.setwelcome = {
    name = 'setwelcome',
    description = 'Set the welcome channel',
    category = 'Configuration',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local channel = ctx.message.mentionedChannels.first

        if not channel then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a channel.',
                    color = 0xFF0000
                }
            })
            return
        end

        -- Update welcome config in database
        local stmt = ctx.db.db:prepare([[
            INSERT INTO guild_config (guild_id, welcome_enabled, welcome_channel_id) VALUES (?, 1, ?)
            ON CONFLICT(guild_id) DO UPDATE SET welcome_enabled = 1, welcome_channel_id = ?
        ]])
        stmt:bind_values(ctx.guild.id, channel.id, channel.id)
        stmt:step()
        stmt:finalize()

        ctx.channel:send({
            embed = {
                description = string.format('✅ Welcome channel set to %s', channel.mentionString),
                color = 0x00FF00
            }
        })
    end
}

-- Set welcome message command
commands.setwelcomemsg = {
    name = 'setwelcomemsg',
    description = 'Set the welcome message',
    aliases = { 'welcomemsg' },
    category = 'Configuration',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        if #ctx.args == 0 then
            ctx.channel:send({
                embed = {
                    title = 'Welcome Message Variables',
                    description = [[
Use these placeholders in your welcome message:
• `{member}` - Mentions the new member
• `{user}` - Member's username
• `{guild}` - Server name
• `{count}` - Member count

Example: `Welcome {member} to {guild}! You are member #{count}!`
                    ]],
                    color = 0xFF003D
                }
            })
            return
        end

        local message = table.concat(ctx.args, ' ')

        local stmt = ctx.db.db:prepare([[
            INSERT INTO guild_config (guild_id, welcome_message) VALUES (?, ?)
            ON CONFLICT(guild_id) DO UPDATE SET welcome_message = ?
        ]])
        stmt:bind_values(ctx.guild.id, message, message)
        stmt:step()
        stmt:finalize()

        ctx.channel:send({
            embed = {
                description = '✅ Welcome message updated!',
                fields = {
                    { name = 'Preview', value = message, inline = false }
                },
                color = 0x00FF00
            }
        })
    end
}

-- Toggle welcome DM command
commands.togglewelcomedm = {
    name = 'togglewelcomedm',
    description = 'Toggle sending welcome messages via DM',
    category = 'Configuration',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local welcomeConfig = ctx.db:getWelcomeConfig(ctx.guild.id)
        local current = welcomeConfig and welcomeConfig.dm_enabled or false
        local newValue = not current and 1 or 0

        local stmt = ctx.db.db:prepare([[
            INSERT INTO guild_config (guild_id, welcome_dm_enabled) VALUES (?, ?)
            ON CONFLICT(guild_id) DO UPDATE SET welcome_dm_enabled = ?
        ]])
        stmt:bind_values(ctx.guild.id, newValue, newValue)
        stmt:step()
        stmt:finalize()

        ctx.channel:send({
            embed = {
                description = string.format('✅ Welcome DMs %s.', newValue == 1 and 'enabled' or 'disabled'),
                color = 0x00FF00
            }
        })
    end
}

-- Disable welcome command
commands.disablewelcome = {
    name = 'disablewelcome',
    description = 'Disable welcome messages',
    category = 'Configuration',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local stmt = ctx.db.db:prepare([[
            INSERT INTO guild_config (guild_id, welcome_enabled) VALUES (?, 0)
            ON CONFLICT(guild_id) DO UPDATE SET welcome_enabled = 0
        ]])
        stmt:bind_values(ctx.guild.id)
        stmt:step()
        stmt:finalize()

        ctx.channel:send({
            embed = {
                description = '✅ Welcome messages disabled.',
                color = 0x00FF00
            }
        })
    end
}

-- Add mention response command
commands.addmention = {
    name = 'addmention',
    description = 'Add a mention response trigger',
    aliases = { 'addmentionresponse' },
    category = 'Configuration',
    guildOnly = true,
    permissions = { 'manageMessages' },

    execute = function(ctx)
        if #ctx.args < 2 then
            ctx.channel:send({
                embed = {
                    description = 'Usage: `' .. ctx.prefix .. 'addmention <trigger> <response>`',
                    color = 0xFF0000
                }
            })
            return
        end

        local trigger = ctx.args[1]
        table.remove(ctx.args, 1)
        local response = table.concat(ctx.args, ' ')

        ctx.db:addMentionResponse(ctx.guild.id, trigger, response, nil, ctx.author.id)

        ctx.channel:send({
            embed = {
                description = string.format('✅ Added mention response: `%s` → `%s`', trigger, response),
                color = 0x00FF00
            }
        })
    end
}

-- Delete mention response command
commands.delmention = {
    name = 'delmention',
    description = 'Delete a mention response trigger',
    aliases = { 'delmentionresponse', 'removemention' },
    category = 'Configuration',
    guildOnly = true,
    permissions = { 'manageMessages' },

    execute = function(ctx)
        if #ctx.args < 1 then
            ctx.channel:send({
                embed = {
                    description = 'Usage: `' .. ctx.prefix .. 'delmention <trigger>`',
                    color = 0xFF0000
                }
            })
            return
        end

        local trigger = ctx.args[1]
        ctx.db:removeMentionResponse(ctx.guild.id, trigger)

        ctx.channel:send({
            embed = {
                description = string.format('✅ Removed mention response for: `%s`', trigger),
                color = 0x00FF00
            }
        })
    end
}

-- List mention responses command
commands.mentions = {
    name = 'mentions',
    description = 'List all mention responses',
    aliases = { 'mentionresponses', 'listmentions' },
    category = 'Configuration',
    guildOnly = true,

    execute = function(ctx)
        local responses = ctx.db:getAllMentionResponses(ctx.guild.id)

        if #responses == 0 then
            ctx.channel:send({
                embed = {
                    description = 'No mention responses configured for this server.',
                    color = 0xFF003D
                }
            })
            return
        end

        local description = ''
        for _, resp in ipairs(responses) do
            local preview = resp.response or '[Image only]'
            if #preview > 50 then
                preview = preview:sub(1, 47) .. '...'
            end
            description = description .. string.format('**%s** → %s\n', resp.trigger, preview)
        end

        ctx.channel:send({
            embed = {
                title = 'Mention Responses',
                description = description,
                color = 0xFF003D,
                footer = { text = string.format('%d total responses', #responses) }
            }
        })
    end
}

return commands
