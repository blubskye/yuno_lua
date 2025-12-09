--[[
    Database Module
    SQLite3 wrapper for persistent storage
]]

local sqlite3 = require('lsqlite3')

local Database = {}
Database.__index = Database

function Database:new(path)
    local self = setmetatable({}, Database)
    self.path = path
    self.db = nil
    return self
end

function Database:init()
    -- Ensure data directory exists
    os.execute('mkdir -p ' .. self.path:match('(.*/)')

    -- Open database
    self.db = sqlite3.open(self.path)

    -- Create tables
    self.db:exec([[
        -- Guild configuration
        CREATE TABLE IF NOT EXISTS guild_config (
            guild_id TEXT PRIMARY KEY,
            prefix TEXT DEFAULT '?',
            spam_filter_enabled INTEGER DEFAULT 1,
            leveling_enabled INTEGER DEFAULT 1,
            welcome_enabled INTEGER DEFAULT 0,
            welcome_channel_id TEXT,
            welcome_message TEXT,
            welcome_dm_enabled INTEGER DEFAULT 0,
            mod_log_channel_id TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        -- User XP/Levels
        CREATE TABLE IF NOT EXISTS user_levels (
            guild_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            xp INTEGER DEFAULT 0,
            level INTEGER DEFAULT 0,
            last_xp_time INTEGER DEFAULT 0,
            PRIMARY KEY (guild_id, user_id)
        );

        -- Rank rewards (role per level)
        CREATE TABLE IF NOT EXISTS rank_rewards (
            guild_id TEXT NOT NULL,
            role_id TEXT NOT NULL,
            level INTEGER NOT NULL,
            PRIMARY KEY (guild_id, role_id)
        );

        -- Moderation actions
        CREATE TABLE IF NOT EXISTS mod_actions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            guild_id TEXT NOT NULL,
            moderator_id TEXT NOT NULL,
            target_id TEXT NOT NULL,
            action TEXT NOT NULL,
            reason TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        -- Mention responses
        CREATE TABLE IF NOT EXISTS mention_responses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            guild_id TEXT NOT NULL,
            trigger TEXT NOT NULL,
            response TEXT,
            image_path TEXT,
            created_by TEXT,
            UNIQUE(guild_id, trigger)
        );

        -- Master users
        CREATE TABLE IF NOT EXISTS master_users (
            user_id TEXT PRIMARY KEY,
            added_by TEXT,
            added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        -- Warnings
        CREATE TABLE IF NOT EXISTS warnings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            guild_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            warned_by TEXT NOT NULL,
            reason TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        -- Create indexes
        CREATE INDEX IF NOT EXISTS idx_levels_guild ON user_levels(guild_id);
        CREATE INDEX IF NOT EXISTS idx_levels_xp ON user_levels(xp DESC);
        CREATE INDEX IF NOT EXISTS idx_mod_guild ON mod_actions(guild_id);
    ]])

    return true
end

function Database:close()
    if self.db then
        self.db:close()
    end
end

-- Guild Config Functions
function Database:initGuild(guildId)
    local stmt = self.db:prepare([[
        INSERT OR IGNORE INTO guild_config (guild_id) VALUES (?)
    ]])
    stmt:bind_values(guildId)
    stmt:step()
    stmt:finalize()
end

function Database:getGuildPrefix(guildId)
    local stmt = self.db:prepare([[
        SELECT prefix FROM guild_config WHERE guild_id = ?
    ]])
    stmt:bind_values(guildId)
    if stmt:step() == sqlite3.ROW then
        local prefix = stmt:get_value(0)
        stmt:finalize()
        return prefix
    end
    stmt:finalize()
    return nil
end

function Database:setGuildPrefix(guildId, prefix)
    local stmt = self.db:prepare([[
        INSERT INTO guild_config (guild_id, prefix) VALUES (?, ?)
        ON CONFLICT(guild_id) DO UPDATE SET prefix = ?
    ]])
    stmt:bind_values(guildId, prefix, prefix)
    stmt:step()
    stmt:finalize()
end

function Database:isLevelingEnabled(guildId)
    local stmt = self.db:prepare([[
        SELECT leveling_enabled FROM guild_config WHERE guild_id = ?
    ]])
    stmt:bind_values(guildId)
    if stmt:step() == sqlite3.ROW then
        local enabled = stmt:get_value(0)
        stmt:finalize()
        return enabled == 1
    end
    stmt:finalize()
    return true -- Default enabled
end

function Database:setLevelingEnabled(guildId, enabled)
    local stmt = self.db:prepare([[
        INSERT INTO guild_config (guild_id, leveling_enabled) VALUES (?, ?)
        ON CONFLICT(guild_id) DO UPDATE SET leveling_enabled = ?
    ]])
    local val = enabled and 1 or 0
    stmt:bind_values(guildId, val, val)
    stmt:step()
    stmt:finalize()
end

function Database:isWelcomeEnabled(guildId)
    local stmt = self.db:prepare([[
        SELECT welcome_enabled FROM guild_config WHERE guild_id = ?
    ]])
    stmt:bind_values(guildId)
    if stmt:step() == sqlite3.ROW then
        local enabled = stmt:get_value(0)
        stmt:finalize()
        return enabled == 1
    end
    stmt:finalize()
    return false
end

function Database:getWelcomeConfig(guildId)
    local stmt = self.db:prepare([[
        SELECT welcome_channel_id, welcome_message, welcome_dm_enabled
        FROM guild_config WHERE guild_id = ?
    ]])
    stmt:bind_values(guildId)
    if stmt:step() == sqlite3.ROW then
        local config = {
            channel_id = stmt:get_value(0),
            message = stmt:get_value(1),
            dm_enabled = stmt:get_value(2) == 1
        }
        stmt:finalize()
        return config
    end
    stmt:finalize()
    return nil
end

-- XP/Level Functions
function Database:getUserXP(guildId, userId)
    local stmt = self.db:prepare([[
        SELECT xp, level FROM user_levels WHERE guild_id = ? AND user_id = ?
    ]])
    stmt:bind_values(guildId, userId)
    if stmt:step() == sqlite3.ROW then
        local xp = stmt:get_value(0)
        local level = stmt:get_value(1)
        stmt:finalize()
        return xp, level
    end
    stmt:finalize()
    return 0, 0
end

function Database:setUserXP(guildId, userId, xp, level)
    local stmt = self.db:prepare([[
        INSERT INTO user_levels (guild_id, user_id, xp, level) VALUES (?, ?, ?, ?)
        ON CONFLICT(guild_id, user_id) DO UPDATE SET xp = ?, level = ?
    ]])
    stmt:bind_values(guildId, userId, xp, level, xp, level)
    stmt:step()
    stmt:finalize()
end

function Database:addUserXP(guildId, userId, amount)
    -- Get current XP
    local xp, level = self:getUserXP(guildId, userId)
    xp = xp + amount

    -- Calculate new level (formula: level = floor((sqrt(1 + 8*xp/50) - 1) / 2))
    local newLevel = math.floor((math.sqrt(1 + 8 * xp / 50) - 1) / 2)

    -- Update
    self:setUserXP(guildId, userId, xp, newLevel)

    return xp, newLevel, newLevel > level
end

function Database:getLeaderboard(guildId, limit)
    limit = limit or 10
    local results = {}

    local stmt = self.db:prepare([[
        SELECT user_id, xp, level FROM user_levels
        WHERE guild_id = ? ORDER BY xp DESC LIMIT ?
    ]])
    stmt:bind_values(guildId, limit)

    while stmt:step() == sqlite3.ROW do
        table.insert(results, {
            user_id = stmt:get_value(0),
            xp = stmt:get_value(1),
            level = stmt:get_value(2)
        })
    end
    stmt:finalize()

    return results
end

function Database:getUserRank(guildId, userId)
    local stmt = self.db:prepare([[
        SELECT COUNT(*) + 1 FROM user_levels
        WHERE guild_id = ? AND xp > (SELECT xp FROM user_levels WHERE guild_id = ? AND user_id = ?)
    ]])
    stmt:bind_values(guildId, guildId, userId)
    if stmt:step() == sqlite3.ROW then
        local rank = stmt:get_value(0)
        stmt:finalize()
        return rank
    end
    stmt:finalize()
    return 1
end

-- Rank Rewards
function Database:getRankRewards(guildId)
    local results = {}
    local stmt = self.db:prepare([[
        SELECT role_id, level FROM rank_rewards WHERE guild_id = ? ORDER BY level
    ]])
    stmt:bind_values(guildId)

    while stmt:step() == sqlite3.ROW do
        table.insert(results, {
            role_id = stmt:get_value(0),
            level = stmt:get_value(1)
        })
    end
    stmt:finalize()

    return results
end

function Database:addRankReward(guildId, roleId, level)
    local stmt = self.db:prepare([[
        INSERT OR REPLACE INTO rank_rewards (guild_id, role_id, level) VALUES (?, ?, ?)
    ]])
    stmt:bind_values(guildId, roleId, level)
    stmt:step()
    stmt:finalize()
end

function Database:removeRankReward(guildId, roleId)
    local stmt = self.db:prepare([[
        DELETE FROM rank_rewards WHERE guild_id = ? AND role_id = ?
    ]])
    stmt:bind_values(guildId, roleId)
    stmt:step()
    stmt:finalize()
end

-- Moderation
function Database:logModAction(guildId, moderatorId, targetId, action, reason)
    local stmt = self.db:prepare([[
        INSERT INTO mod_actions (guild_id, moderator_id, target_id, action, reason)
        VALUES (?, ?, ?, ?, ?)
    ]])
    stmt:bind_values(guildId, moderatorId, targetId, action, reason)
    stmt:step()
    stmt:finalize()
end

function Database:getModStats(guildId, moderatorId)
    local results = {}

    local sql = [[
        SELECT action, COUNT(*) as count FROM mod_actions
        WHERE guild_id = ?
    ]]
    if moderatorId then
        sql = sql .. ' AND moderator_id = ?'
    end
    sql = sql .. ' GROUP BY action'

    local stmt = self.db:prepare(sql)
    if moderatorId then
        stmt:bind_values(guildId, moderatorId)
    else
        stmt:bind_values(guildId)
    end

    while stmt:step() == sqlite3.ROW do
        results[stmt:get_value(0)] = stmt:get_value(1)
    end
    stmt:finalize()

    return results
end

function Database:getUserHistory(guildId, userId, limit)
    limit = limit or 10
    local results = {}

    local stmt = self.db:prepare([[
        SELECT action, reason, moderator_id, timestamp FROM mod_actions
        WHERE guild_id = ? AND target_id = ?
        ORDER BY timestamp DESC LIMIT ?
    ]])
    stmt:bind_values(guildId, userId, limit)

    while stmt:step() == sqlite3.ROW do
        table.insert(results, {
            action = stmt:get_value(0),
            reason = stmt:get_value(1),
            moderator_id = stmt:get_value(2),
            timestamp = stmt:get_value(3)
        })
    end
    stmt:finalize()

    return results
end

-- Mention Responses
function Database:getMentionResponse(guildId, trigger)
    local stmt = self.db:prepare([[
        SELECT response, image_path FROM mention_responses
        WHERE guild_id = ? AND LOWER(trigger) = LOWER(?)
    ]])
    stmt:bind_values(guildId, trigger)

    if stmt:step() == sqlite3.ROW then
        local result = {
            response = stmt:get_value(0),
            image_path = stmt:get_value(1)
        }
        stmt:finalize()
        return result
    end
    stmt:finalize()
    return nil
end

function Database:addMentionResponse(guildId, trigger, response, imagePath, createdBy)
    local stmt = self.db:prepare([[
        INSERT INTO mention_responses (guild_id, trigger, response, image_path, created_by)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(guild_id, trigger) DO UPDATE SET response = ?, image_path = ?, created_by = ?
    ]])
    stmt:bind_values(guildId, trigger, response, imagePath, createdBy, response, imagePath, createdBy)
    stmt:step()
    stmt:finalize()
end

function Database:removeMentionResponse(guildId, trigger)
    local stmt = self.db:prepare([[
        DELETE FROM mention_responses WHERE guild_id = ? AND LOWER(trigger) = LOWER(?)
    ]])
    stmt:bind_values(guildId, trigger)
    stmt:step()
    stmt:finalize()
end

function Database:getAllMentionResponses(guildId)
    local results = {}
    local stmt = self.db:prepare([[
        SELECT trigger, response, image_path FROM mention_responses WHERE guild_id = ?
    ]])
    stmt:bind_values(guildId)

    while stmt:step() == sqlite3.ROW do
        table.insert(results, {
            trigger = stmt:get_value(0),
            response = stmt:get_value(1),
            image_path = stmt:get_value(2)
        })
    end
    stmt:finalize()

    return results
end

-- Warnings
function Database:addWarning(guildId, userId, warnedBy, reason)
    local stmt = self.db:prepare([[
        INSERT INTO warnings (guild_id, user_id, warned_by, reason) VALUES (?, ?, ?, ?)
    ]])
    stmt:bind_values(guildId, userId, warnedBy, reason)
    stmt:step()
    stmt:finalize()

    -- Get warning count
    stmt = self.db:prepare([[
        SELECT COUNT(*) FROM warnings WHERE guild_id = ? AND user_id = ?
    ]])
    stmt:bind_values(guildId, userId)
    local count = 0
    if stmt:step() == sqlite3.ROW then
        count = stmt:get_value(0)
    end
    stmt:finalize()

    return count
end

function Database:getWarnings(guildId, userId)
    local results = {}
    local stmt = self.db:prepare([[
        SELECT reason, warned_by, timestamp FROM warnings
        WHERE guild_id = ? AND user_id = ? ORDER BY timestamp DESC
    ]])
    stmt:bind_values(guildId, userId)

    while stmt:step() == sqlite3.ROW do
        table.insert(results, {
            reason = stmt:get_value(0),
            warned_by = stmt:get_value(1),
            timestamp = stmt:get_value(2)
        })
    end
    stmt:finalize()

    return results
end

function Database:clearWarnings(guildId, userId)
    local stmt = self.db:prepare([[
        DELETE FROM warnings WHERE guild_id = ? AND user_id = ?
    ]])
    stmt:bind_values(guildId, userId)
    stmt:step()
    stmt:finalize()
end

return Database
