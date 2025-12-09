--[[
    Leveling Commands
    XP and level management commands
]]

local commands = {}

-- XP command
commands.xp = {
    name = 'xp',
    description = 'Check your or another user\'s XP and level',
    aliases = { 'level', 'rank' },
    category = 'Leveling',
    guildOnly = true,

    execute = function(ctx)
        -- Get target user (mentioned or self)
        local target = ctx.message.mentionedUsers.first or ctx.author
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

        local xp, level = ctx.db:getUserXP(ctx.guild.id, target.id)
        local rank = ctx.db:getUserRank(ctx.guild.id, target.id)

        -- Calculate XP needed for next level
        local nextLevel = level + 1
        local xpForNext = math.floor(nextLevel * (nextLevel + 1) * 50 / 2)
        local xpForCurrent = math.floor(level * (level + 1) * 50 / 2)
        local progress = xp - xpForCurrent
        local needed = xpForNext - xpForCurrent

        -- Create progress bar
        local barLength = 10
        local filledBars = math.floor((progress / needed) * barLength)
        local progressBar = string.rep('█', filledBars) .. string.rep('░', barLength - filledBars)

        ctx.channel:send({
            embed = {
                title = target.username .. '\'s Level',
                thumbnail = { url = target.avatarURL },
                fields = {
                    { name = 'Level', value = tostring(level), inline = true },
                    { name = 'XP', value = tostring(xp), inline = true },
                    { name = 'Rank', value = '#' .. tostring(rank), inline = true },
                    { name = 'Progress', value = string.format('%s\n%d / %d XP', progressBar, progress, needed), inline = false },
                },
                color = 0xFF003D,
                footer = { text = 'Keep chatting to level up! 💕' }
            }
        })
    end
}

-- Leaderboard command
commands.leaderboard = {
    name = 'leaderboard',
    description = 'Show the server XP leaderboard',
    aliases = { 'lb', 'top' },
    category = 'Leveling',
    guildOnly = true,

    execute = function(ctx)
        local limit = tonumber(ctx.args[1]) or 10
        if limit > 25 then limit = 25 end
        if limit < 1 then limit = 1 end

        local leaderboard = ctx.db:getLeaderboard(ctx.guild.id, limit)

        if #leaderboard == 0 then
            ctx.channel:send({
                embed = {
                    description = 'No one has earned any XP yet!',
                    color = 0xFF003D
                }
            })
            return
        end

        local description = ''
        for i, entry in ipairs(leaderboard) do
            local user = ctx.client:getUser(entry.user_id)
            local username = user and user.username or 'Unknown User'

            local medal = ''
            if i == 1 then medal = '🥇 '
            elseif i == 2 then medal = '🥈 '
            elseif i == 3 then medal = '🥉 '
            else medal = '**' .. i .. '.** '
            end

            description = description .. string.format(
                '%s%s - Level %d (%d XP)\n',
                medal, username, entry.level, entry.xp
            )
        end

        ctx.channel:send({
            embed = {
                title = ctx.guild.name .. ' Leaderboard 🏆',
                description = description,
                color = 0xFF003D,
                footer = { text = 'Keep chatting to climb the ranks! 💕' }
            }
        })
    end
}

-- Give XP command (admin only)
commands.givexp = {
    name = 'givexp',
    description = 'Give XP to a user',
    aliases = { 'addxp' },
    category = 'Leveling',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first
        local amount = tonumber(ctx.args[2] or ctx.args[1])

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a user to give XP to.',
                    color = 0xFF0000
                }
            })
            return
        end

        if not amount or amount <= 0 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide a valid XP amount.',
                    color = 0xFF0000
                }
            })
            return
        end

        local newXP, newLevel, leveledUp = ctx.db:addUserXP(ctx.guild.id, target.id, amount)

        local msg = string.format('Added %d XP to %s! They now have %d XP (Level %d)',
            amount, target.username, newXP, newLevel)

        if leveledUp then
            msg = msg .. ' 🎉 Level up!'
        end

        ctx.channel:send({
            embed = {
                description = '✅ ' .. msg,
                color = 0x00FF00
            }
        })
    end
}

-- Set XP command (admin only)
commands.setxp = {
    name = 'setxp',
    description = 'Set a user\'s XP',
    category = 'Leveling',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first
        local amount = tonumber(ctx.args[2] or ctx.args[1])

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a user.',
                    color = 0xFF0000
                }
            })
            return
        end

        if not amount or amount < 0 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide a valid XP amount.',
                    color = 0xFF0000
                }
            })
            return
        end

        -- Calculate level from XP
        local level = math.floor((math.sqrt(1 + 8 * amount / 50) - 1) / 2)
        ctx.db:setUserXP(ctx.guild.id, target.id, amount, level)

        ctx.channel:send({
            embed = {
                description = string.format('✅ Set %s\'s XP to %d (Level %d)',
                    target.username, amount, level),
                color = 0x00FF00
            }
        })
    end
}

-- Set level command (admin only)
commands.setlevel = {
    name = 'setlevel',
    description = 'Set a user\'s level',
    category = 'Leveling',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first
        local level = tonumber(ctx.args[2] or ctx.args[1])

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a user.',
                    color = 0xFF0000
                }
            })
            return
        end

        if not level or level < 0 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide a valid level.',
                    color = 0xFF0000
                }
            })
            return
        end

        -- Calculate XP needed for level
        local xp = math.floor(level * (level + 1) * 50 / 2)
        ctx.db:setUserXP(ctx.guild.id, target.id, xp, level)

        ctx.channel:send({
            embed = {
                description = string.format('✅ Set %s to Level %d (%d XP)',
                    target.username, level, xp),
                color = 0x00FF00
            }
        })
    end
}

-- Rank rewards command
commands.ranks = {
    name = 'ranks',
    description = 'Show level-up role rewards',
    aliases = { 'rewards', 'levelroles' },
    category = 'Leveling',
    guildOnly = true,

    execute = function(ctx)
        local rewards = ctx.db:getRankRewards(ctx.guild.id)

        if #rewards == 0 then
            ctx.channel:send({
                embed = {
                    description = 'No rank rewards configured for this server.',
                    color = 0xFF003D
                }
            })
            return
        end

        local description = ''
        for _, reward in ipairs(rewards) do
            local role = ctx.guild:getRole(reward.role_id)
            local roleName = role and role.name or 'Deleted Role'
            description = description .. string.format('Level %d → %s\n', reward.level, roleName)
        end

        ctx.channel:send({
            embed = {
                title = 'Rank Rewards 🎖️',
                description = description,
                color = 0xFF003D
            }
        })
    end
}

-- Add rank reward (admin only)
commands.addrank = {
    name = 'addrank',
    description = 'Add a level-up role reward',
    category = 'Leveling',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local role = ctx.message.mentionedRoles.first
        local level = tonumber(ctx.args[2] or ctx.args[1])

        if not role then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a role.',
                    color = 0xFF0000
                }
            })
            return
        end

        if not level or level < 1 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide a valid level (1 or higher).',
                    color = 0xFF0000
                }
            })
            return
        end

        ctx.db:addRankReward(ctx.guild.id, role.id, level)

        ctx.channel:send({
            embed = {
                description = string.format('✅ Added rank reward: Level %d → %s', level, role.name),
                color = 0x00FF00
            }
        })
    end
}

-- Remove rank reward (admin only)
commands.removerank = {
    name = 'removerank',
    description = 'Remove a level-up role reward',
    aliases = { 'delrank' },
    category = 'Leveling',
    guildOnly = true,
    permissions = { 'administrator' },

    execute = function(ctx)
        local role = ctx.message.mentionedRoles.first

        if not role then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention a role to remove.',
                    color = 0xFF0000
                }
            })
            return
        end

        ctx.db:removeRankReward(ctx.guild.id, role.id)

        ctx.channel:send({
            embed = {
                description = string.format('✅ Removed rank reward for %s', role.name),
                color = 0x00FF00
            }
        })
    end
}

return commands
