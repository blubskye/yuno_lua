--[[
    Fun Commands
    Entertainment and social interaction commands
]]

local http = require('coro-http')
local json = require('json')

local commands = {}

-- Helper function for HTTP GET requests
local function httpGet(url)
    local res, body = http.request('GET', url, {
        {'User-Agent', 'Yuno-Bot/1.0'}
    })
    if res.code == 200 then
        return json.decode(body)
    end
    return nil
end

-- 8ball command
commands.eightball = {
    name = '8ball',
    description = 'Ask the magic 8ball a question',
    aliases = { 'ask', 'magic8ball' },
    category = 'Fun',

    execute = function(ctx)
        if #ctx.args == 0 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please ask a question!',
                    color = 0xFF0000
                }
            })
            return
        end

        local responses = {
            -- Positive
            'It is certain.',
            'It is decidedly so.',
            'Without a doubt.',
            'Yes - definitely.',
            'You may rely on it.',
            'As I see it, yes.',
            'Most likely.',
            'Outlook good.',
            'Yes.',
            'Signs point to yes.',
            -- Neutral
            'Reply hazy, try again.',
            'Ask again later.',
            'Better not tell you now.',
            'Cannot predict now.',
            'Concentrate and ask again.',
            -- Negative
            'Don\'t count on it.',
            'My reply is no.',
            'My sources say no.',
            'Outlook not so good.',
            'Very doubtful.',
            -- Yuno special
            'Only if it involves Yukki~ 💕',
            'I\'ll make it happen for you~ 💗',
            'Anyone who says no will regret it~',
        }

        local response = responses[math.random(#responses)]
        local question = table.concat(ctx.args, ' ')

        ctx.channel:send({
            embed = {
                title = '🎱 Magic 8-Ball',
                fields = {
                    { name = 'Question', value = question, inline = false },
                    { name = 'Answer', value = response, inline = false },
                },
                color = 0xFF003D
            }
        })
    end
}

-- Praise command
commands.praise = {
    name = 'praise',
    description = 'Praise someone',
    category = 'Fun',

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention someone to praise!',
                    color = 0xFF0000
                }
            })
            return
        end

        local praises = {
            'You\'re absolutely amazing, %s! 💕',
            '%s, you light up every room you enter! ✨',
            'The world is better with you in it, %s! 💗',
            '%s, your kindness knows no bounds! 🌸',
            'You\'re a treasure, %s! Never change! 💖',
            '%s is truly one of a kind! 🌟',
            'Everyone could learn from %s! 💕',
            '%s, you make everything better! 🎀',
            'We don\'t deserve someone as wonderful as %s! 💗',
            '%s is the best! Fight me on this! 💪',
        }

        local praise = praises[math.random(#praises)]

        ctx.channel:send({
            embed = {
                description = string.format(praise, target.mentionString),
                color = 0xFF003D
            }
        })
    end
}

-- Scold command
commands.scold = {
    name = 'scold',
    description = 'Scold someone (playfully)',
    category = 'Fun',

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention someone to scold!',
                    color = 0xFF0000
                }
            })
            return
        end

        local scolds = {
            '%s, you\'re being a bad person! 😤',
            'Shame on you, %s! 💢',
            '%s needs to think about what they\'ve done! 😠',
            'Bad %s! Very bad! 🙅',
            '%s, I\'m very disappointed in you! 😤',
            'You know what you did, %s! 💢',
            '%s, corner. Now. 👉',
            'I expected better from you, %s! 😔',
            '%s should apologize! 😤',
            'No snacks for %s today! 🚫',
        }

        local scold = scolds[math.random(#scolds)]

        ctx.channel:send({
            embed = {
                description = string.format(scold, target.mentionString),
                color = 0xFF6B6B
            }
        })
    end
}

-- Hug command
commands.hug = {
    name = 'hug',
    description = 'Hug someone',
    category = 'Fun',

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention someone to hug!',
                    color = 0xFF0000
                }
            })
            return
        end

        local data = httpGet('https://nekos.life/api/v2/img/hug')
        local imageUrl = data and data.url or nil

        ctx.channel:send({
            embed = {
                description = string.format('%s hugs %s! 💕', ctx.author.mentionString, target.mentionString),
                image = imageUrl and { url = imageUrl } or nil,
                color = 0xFF003D
            }
        })
    end
}

-- Slap command
commands.slap = {
    name = 'slap',
    description = 'Slap someone',
    category = 'Fun',

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention someone to slap!',
                    color = 0xFF0000
                }
            })
            return
        end

        local data = httpGet('https://nekos.life/api/v2/img/slap')
        local imageUrl = data and data.url or nil

        ctx.channel:send({
            embed = {
                description = string.format('%s slaps %s! 💢', ctx.author.mentionString, target.mentionString),
                image = imageUrl and { url = imageUrl } or nil,
                color = 0xFF6B6B
            }
        })
    end
}

-- Kiss command
commands.kiss = {
    name = 'kiss',
    description = 'Kiss someone',
    category = 'Fun',

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention someone to kiss!',
                    color = 0xFF0000
                }
            })
            return
        end

        local data = httpGet('https://nekos.life/api/v2/img/kiss')
        local imageUrl = data and data.url or nil

        ctx.channel:send({
            embed = {
                description = string.format('%s kisses %s! 💋', ctx.author.mentionString, target.mentionString),
                image = imageUrl and { url = imageUrl } or nil,
                color = 0xFF69B4
            }
        })
    end
}

-- Pat command
commands.pat = {
    name = 'pat',
    description = 'Pat someone',
    aliases = { 'headpat' },
    category = 'Fun',

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention someone to pat!',
                    color = 0xFF0000
                }
            })
            return
        end

        local data = httpGet('https://nekos.life/api/v2/img/pat')
        local imageUrl = data and data.url or nil

        ctx.channel:send({
            embed = {
                description = string.format('%s pats %s! 💕', ctx.author.mentionString, target.mentionString),
                image = imageUrl and { url = imageUrl } or nil,
                color = 0xFFB6C1
            }
        })
    end
}

-- Cuddle command
commands.cuddle = {
    name = 'cuddle',
    description = 'Cuddle with someone',
    category = 'Fun',

    execute = function(ctx)
        local target = ctx.message.mentionedUsers.first

        if not target then
            ctx.channel:send({
                embed = {
                    description = '❌ Please mention someone to cuddle!',
                    color = 0xFF0000
                }
            })
            return
        end

        local data = httpGet('https://nekos.life/api/v2/img/cuddle')
        local imageUrl = data and data.url or nil

        ctx.channel:send({
            embed = {
                description = string.format('%s cuddles with %s! 💗', ctx.author.mentionString, target.mentionString),
                image = imageUrl and { url = imageUrl } or nil,
                color = 0xFF003D
            }
        })
    end
}

-- Neko command
commands.neko = {
    name = 'neko',
    description = 'Get a random neko image',
    aliases = { 'catgirl' },
    category = 'Fun',

    execute = function(ctx)
        local data = httpGet('https://nekos.life/api/v2/img/neko')
        local imageUrl = data and data.url or nil

        if imageUrl then
            ctx.channel:send({
                embed = {
                    title = 'Neko! 🐱',
                    image = { url = imageUrl },
                    color = 0xFF003D
                }
            })
        else
            ctx.channel:send({
                embed = {
                    description = '❌ Failed to fetch neko image.',
                    color = 0xFF0000
                }
            })
        end
    end
}

-- Waifu command
commands.waifu = {
    name = 'waifu',
    description = 'Get a random waifu image',
    category = 'Fun',

    execute = function(ctx)
        local data = httpGet('https://nekos.life/api/v2/img/waifu')
        local imageUrl = data and data.url or nil

        if imageUrl then
            ctx.channel:send({
                embed = {
                    title = 'Waifu! 💕',
                    image = { url = imageUrl },
                    color = 0xFF003D
                }
            })
        else
            ctx.channel:send({
                embed = {
                    description = '❌ Failed to fetch waifu image.',
                    color = 0xFF0000
                }
            })
        end
    end
}

-- Urban Dictionary command
commands.urban = {
    name = 'urban',
    description = 'Look up a word on Urban Dictionary',
    aliases = { 'ud', 'define' },
    category = 'Fun',

    execute = function(ctx)
        if #ctx.args == 0 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide a word to look up!',
                    color = 0xFF0000
                }
            })
            return
        end

        local term = table.concat(ctx.args, ' ')
        local url = 'https://api.urbandictionary.com/v0/define?term=' .. term:gsub(' ', '%%20')
        local data = httpGet(url)

        if not data or not data.list or #data.list == 0 then
            ctx.channel:send({
                embed = {
                    description = '❌ No definition found for: ' .. term,
                    color = 0xFF0000
                }
            })
            return
        end

        local entry = data.list[1]
        local definition = entry.definition:gsub('%[', ''):gsub('%]', '')
        local example = entry.example:gsub('%[', ''):gsub('%]', '')

        -- Truncate if too long
        if #definition > 1024 then
            definition = definition:sub(1, 1021) .. '...'
        end
        if #example > 1024 then
            example = example:sub(1, 1021) .. '...'
        end

        ctx.channel:send({
            embed = {
                title = entry.word,
                url = entry.permalink,
                fields = {
                    { name = 'Definition', value = definition or 'No definition', inline = false },
                    { name = 'Example', value = example ~= '' and example or 'No example', inline = false },
                    { name = '👍', value = tostring(entry.thumbs_up), inline = true },
                    { name = '👎', value = tostring(entry.thumbs_down), inline = true },
                },
                color = 0xEFFF00,
                footer = { text = 'By: ' .. entry.author }
            }
        })
    end
}

-- Coin flip command
commands.coinflip = {
    name = 'coinflip',
    description = 'Flip a coin',
    aliases = { 'coin', 'flip' },
    category = 'Fun',

    execute = function(ctx)
        local result = math.random(2) == 1 and 'Heads' or 'Tails'
        local emoji = result == 'Heads' and '🪙' or '💫'

        ctx.channel:send({
            embed = {
                title = emoji .. ' Coin Flip',
                description = '**' .. result .. '!**',
                color = 0xFF003D
            }
        })
    end
}

-- Roll dice command
commands.roll = {
    name = 'roll',
    description = 'Roll dice (e.g., 2d6)',
    aliases = { 'dice' },
    category = 'Fun',

    execute = function(ctx)
        local input = ctx.args[1] or '1d6'
        local count, sides = input:match('(%d+)d(%d+)')

        if not count then
            -- Try just a number
            sides = tonumber(input) or 6
            count = 1
        else
            count = tonumber(count)
            sides = tonumber(sides)
        end

        if count > 100 then count = 100 end
        if sides > 1000 then sides = 1000 end

        local rolls = {}
        local total = 0

        for i = 1, count do
            local roll = math.random(sides)
            table.insert(rolls, roll)
            total = total + roll
        end

        local rollStr = table.concat(rolls, ', ')
        if #rollStr > 200 then
            rollStr = rollStr:sub(1, 197) .. '...'
        end

        ctx.channel:send({
            embed = {
                title = '🎲 Dice Roll',
                description = string.format('Rolling %dd%d', count, sides),
                fields = {
                    { name = 'Rolls', value = rollStr, inline = false },
                    { name = 'Total', value = tostring(total), inline = true },
                },
                color = 0xFF003D
            }
        })
    end
}

-- Choose command
commands.choose = {
    name = 'choose',
    description = 'Choose between options (separate with |)',
    aliases = { 'pick' },
    category = 'Fun',

    execute = function(ctx)
        if #ctx.args == 0 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide options separated by |',
                    color = 0xFF0000
                }
            })
            return
        end

        local input = table.concat(ctx.args, ' ')
        local options = {}

        for option in input:gmatch('[^|]+') do
            local trimmed = option:match('^%s*(.-)%s*$')
            if trimmed and #trimmed > 0 then
                table.insert(options, trimmed)
            end
        end

        if #options < 2 then
            ctx.channel:send({
                embed = {
                    description = '❌ Please provide at least 2 options separated by |',
                    color = 0xFF0000
                }
            })
            return
        end

        local choice = options[math.random(#options)]

        ctx.channel:send({
            embed = {
                title = '🤔 I choose...',
                description = '**' .. choice .. '**',
                color = 0xFF003D
            }
        })
    end
}

return commands
