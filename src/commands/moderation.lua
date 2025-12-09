--[[
    Moderation Commands
    Server moderation tools
]]

local commands = {}

-- Ban command
commands.ban = {
    name = 'ban',
    description = 'Ban a user from the server',
    category = 'Moderation',
    guildOnly = true,
    permissions = { 'banMembers' },

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a user to ban.',
                    color = 0xFF0000
                }
            })
            return
        end

        -- Get reason
        local reason = 'No reason provided'
        if #ctx.args > 1 then
            table.remove(ctx.args, 1)
            reason = table.concat(ctx.args, ' ')
        end

        local member = ctx.guild:getMember(target.id)
        if not member then
            ctx.channel:send({
                embed = {
                    description = '❌ User not found in this server.',
                    color = 0xFF0000
                }
            })
            return
        end

        -- Check if can ban
        if member.highestRole.position >= ctx.member.highestRole.position then
            ctx.channel:send({
                embed = {
                    description = '❌ You cannot ban someone with equal or higher role.',
                    color = 0xFF0000
                }
            })
            return
        end

        local ok, err = pcall(function()
            member:ban(reason, 7)
        end)

        if ok then
            ctx.db:logModAction(ctx.guild.id, ctx.author.id, target.id, 'ban', reason)

            ctx.channel:send({
                embed = {
                    title = 'User Banned 🔨',
                    description = string.format('%s has been banned.', target.tag),
                    fields = {
                        { name = 'Reason', value = reason, inline = false },
                        { name = 'Moderator', value = ctx.author.tag, inline = true },
                    },
                    color = 0xFF0000
                }
            })
        else
            ctx.channel:send({
                embed = {
                    description = '❌ Failed to ban user: ' .. tostring(err),
                    color = 0xFF0000
                }
            })
        end
    end
}

-- Kick command
commands.kick = {
    name = 'kick',
    description = 'Kick a user from the server',
    category = 'Moderation',
    guildOnly = true,
    permissions = { 'kickMembers' },

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a user to kick.',
                    color = 0xFF0000
                }
            })
            return
        end

        local reason = 'No reason provided'
        if #ctx.args > 1 then
            table.remove(ctx.args, 1)
            reason = table.concat(ctx.args, ' ')
        end

        local member = ctx.guild:getMember(target.id)
        if not member then
            ctx.channel:send({
                embed = {
                    description = '❌ User not found in this server.',
                    color = 0xFF0000
                }
            })
            return
        end

        if member.highestRole.position >= ctx.member.highestRole.position then
            ctx.channel:send({
                embed = {
                    description = '❌ You cannot kick someone with equal or higher role.',
                    color = 0xFF0000
                }
            })
            return
        end

        local ok, err = pcall(function()
            member:kick(reason)
        end)

        if ok then
            ctx.db:logModAction(ctx.guild.id, ctx.author.id, target.id, 'kick', reason)

            ctx.channel:send({
                embed = {
                    title = 'User Kicked 👢',
                    description = string.format('%s has been kicked.', target.tag),
                    fields = {
                        { name = 'Reason', value = reason, inline = false },
                        { name = 'Moderator', value = ctx.author.tag, inline = true },
                    },
                    color = 0xFFAA00
                }
            })
        else
            ctx.channel:send({
                embed = {
                    description = '❌ Failed to kick user: ' .. tostring(err),
                    color = 0xFF0000
                }
            })
        end
    end
}

-- Unban command
commands.unban = {
    name = 'unban',
    description = 'Unban a user by ID',
    category = 'Moderation',
    guildOnly = true,
    permissions = { 'banMembers' },

    execute = function(ctx)
        local userId = ctx.args[1]

        if not userId then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide a user ID to unban.',
                    color = 0xFF0000
                }
            })
            return
        end

        -- Remove any mention formatting
        userId = userId:gsub('[<@!>]', '')

        local ok, err = pcall(function()
            ctx.guild:unbanUser(userId)
        end)

        if ok then
            ctx.db:logModAction(ctx.guild.id, ctx.author.id, userId, 'unban', 'Unbanned')

            ctx.channel:send({
                embed = {
                    title = 'User Unbanned ✅',
                    description = string.format('User ID %s has been unbanned.', userId),
                    fields = {
                        { name = 'Moderator', value = ctx.author.tag, inline = true },
                    },
                    color = 0x00FF00
                }
            })
        else
            ctx.channel:send({
                embed = {
                    description = '❌ Failed to unban user: ' .. tostring(err),
                    color = 0xFF0000
                }
            })
        end
    end
}

-- Warn command
commands.warn = {
    name = 'warn',
    description = 'Warn a user',
    category = 'Moderation',
    guildOnly = true,
    permissions = { 'kickMembers' },

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a user to warn.',
                    color = 0xFF0000
                }
            })
            return
        end

        local reason = 'No reason provided'
        if #ctx.args > 1 then
            table.remove(ctx.args, 1)
            reason = table.concat(ctx.args, ' ')
        end

        local count = ctx.db:addWarning(ctx.guild.id, target.id, ctx.author.id, reason)
        ctx.db:logModAction(ctx.guild.id, ctx.author.id, target.id, 'warn', reason)

        ctx.channel:send({
            embed = {
                title = 'User Warned ⚠️',
                description = string.format('%s has been warned.', target.tag),
                fields = {
                    { name = 'Reason', value = reason, inline = false },
                    { name = 'Total Warnings', value = tostring(count), inline = true },
                    { name = 'Moderator', value = ctx.author.tag, inline = true },
                },
                color = 0xFFAA00
            }
        })

        -- Auto-action based on warning count
        local maxWarnings = ctx.config:get('spam.max_warnings', 3)
        if count >= maxWarnings then
            ctx.channel:send({
                embed = {
                    description = string.format('⚠️ %s has reached %d warnings!', target.tag, count),
                    color = 0xFF0000
                }
            })
        end
    end
}

-- Warnings command
commands.warnings = {
    name = 'warnings',
    description = 'View a user\'s warnings',
    aliases = { 'warns' },
    category = 'Moderation',
    guildOnly = true,

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first or ctx.author
        local warnings = ctx.db:getWarnings(ctx.guild.id, target.id)

        if #warnings == 0 then
            ctx.channel:send({
                embed = {
                    description = string.format('%s has no warnings.', target.tag),
                    color = 0x00FF00
                }
            })
            return
        end

        local description = ''
        for i, warn in ipairs(warnings) do
            local warner = ctx.client:getUser(warn.warned_by)
            local warnerName = warner and warner.tag or 'Unknown'
            description = description .. string.format(
                '**%d.** %s\nBy: %s | %s\n\n',
                i, warn.reason or 'No reason', warnerName, warn.timestamp
            )
        end

        ctx.channel:send({
            embed = {
                title = target.tag .. '\'s Warnings',
                description = description,
                color = 0xFFAA00,
                footer = { text = string.format('Total: %d warnings', #warnings) }
            }
        })
    end
}

-- Clear warnings command
commands.clearwarnings = {
    name = 'clearwarnings',
    description = 'Clear all warnings for a user',
    aliases = { 'clearwarns' },
    category = 'Moderation',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a user.',
                    color = 0xFF0000
                }
            })
            return
        end

        ctx.db:clearWarnings(ctx.guild.id, target.id)

        ctx.channel:send({
            embed = {
                description = string.format('✅ Cleared all warnings for %s.', target.tag),
                color = 0x00FF00
            }
        })
    end
}

-- Mod stats command
commands.modstats = {
    name = 'modstats',
    description = 'View moderation statistics',
    aliases = { 'mod-stats' },
    category = 'Moderation',
    guildOnly = true,

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first
        local stats = ctx.db:getModStats(ctx.guild.id, target and target.id or nil)

        local title = target and (target.tag .. '\'s Mod Stats') or 'Server Mod Stats'
        local fields = {}

        for action, count in pairs(stats) do
            table.insert(fields, {
                name = action:sub(1, 1):upper() .. action:sub(2) .. 's',
                value = tostring(count),
                inline = true
            })
        end

        if #fields == 0 then
            ctx.channel:send({
                embed = {
                    description = 'No moderation actions recorded.',
                    color = 0xFF003D
                }
            })
            return
        end

        ctx.channel:send({
            embed = {
                title = title,
                fields = fields,
                color = 0xFF003D
            }
        })
    end
}

-- History command
commands.history = {
    name = 'history',
    description = 'View a user\'s moderation history',
    aliases = { 'modhistory' },
    category = 'Moderation',
    guildOnly = true,
    permissions = { 'kickMembers' },

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a user.',
                    color = 0xFF0000
                }
            })
            return
        end

        local history = ctx.db:getUserHistory(ctx.guild.id, target.id, 10)

        if #history == 0 then
            ctx.channel:send({
                embed = {
                    description = string.format('%s has no moderation history.', target.tag),
                    color = 0x00FF00
                }
            })
            return
        end

        local description = ''
        for _, entry in ipairs(history) do
            local mod = ctx.client:getUser(entry.moderator_id)
            local modName = mod and mod.tag or 'Unknown'
            description = description .. string.format(
                '**%s** - %s\nBy: %s | %s\n\n',
                entry.action:upper(), entry.reason or 'No reason', modName, entry.timestamp
            )
        end

        ctx.channel:send({
            embed = {
                title = target.tag .. '\'s History',
                description = description,
                color = 0xFF003D
            }
        })
    end
}

-- Purge command
commands.purge = {
    name = 'purge',
    description = 'Delete multiple messages',
    aliases = { 'clear', 'prune' },
    category = 'Moderation',
    guildOnly = true,
    permissions = { 'manageMessages' },

    execute = function(ctx)
        local amount = tonumber(ctx.args[1])

        if not amount or amount < 1 or amount > 100 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide a number between 1 and 100.',
                    color = 0xFF0000
                }
            })
            return
        end

        -- Delete the command message first
        ctx.message:delete()

        -- Bulk delete
        local ok, err = pcall(function()
            local messages = ctx.channel:getMessages(amount)
            ctx.channel:bulkDelete(messages)
        end)

        if ok then
            ctx.channel:send({
                embed = {
                    description = string.format('✅ Deleted %d messages.', amount),
                    color = 0x00FF00
                }
            }):then(function(msg)
                -- Auto-delete confirmation after 3 seconds
                require('timer').sleep(3000)
                msg:delete()
            end)
        else
            ctx.channel:send({
                embed = {
                    description = '❌ Failed to delete messages: ' .. tostring(err),
                    color = 0xFF0000
                }
            })
        end
    end
}

return commands
