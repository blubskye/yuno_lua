--[[
    Yuno Configuration Example
    Copy this file to config.lua and fill in your values
]]

return {
    bot = {
        token = 'YOUR_BOT_TOKEN_HERE',
        prefix = '?',
        status = 'for levels',
        activity_type = 'watching',
        owner_ids = {
            'YOUR_USER_ID_HERE',
        },
    },

    database = {
        path = 'data/yuno.db',
    },

    leveling = {
        xp_per_message_min = 15,
        xp_per_message_max = 25,
        xp_per_voice_min = 18,
        xp_per_voice_max = 30,
        level_divisor = 50,
    },

    spam = {
        max_warnings = 3,
        message_limit = 4,
        warning_timeout = 15,
    },

    colors = {
        primary = 0xFF003D,
        success = 0x00FF00,
        error = 0xFF0000,
        warning = 0xFFAA00,
        info = 0x3498DB,
    },
}
