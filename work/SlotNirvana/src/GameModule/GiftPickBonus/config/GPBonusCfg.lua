--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-11-26 17:11:16
]]
GD.GPBonusCfg = {}

GPBonusCfg.PICK_GAME_STATUS = {
    -- 准备
    PREPARE = "PREPARE",
    PLAYING = "PLAYING",
    FINISH = "FINISH"
}

-- local TEMP_TYPE =
-- {
--     "NONE",
--     "GRAND",
--     "MAJOR",
--     "MINOR",
--     "MINI",
--     "ADD_COINS",
--     "REDUCE_COINS",
--     "OVER",
-- }

GPBonusCfg.PICK_TYPE = {
    Star = "NONE",
    Grand = "GRAND",
    Major = "MAJOR",
    Minor = "MINOR",
    Mini = "MINI",
    AddCoin = "ADD_COINS",
    DelCoin = "REDUCE_COINS",
    MULCoin = "MULTIPLY",
    GameOver = "OVER"
}

GPBonusCfg.TEST_DATA = {
    {
        index = 1,
        coins = 5550000000,
        expireAt = 12314,
        status = "",
        jackpotCoins = {
            90000000000,
            80000000000,
            70000000000,
            60000000000
        },
        boxes = {
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            -- {type = GPBonusCfg.PICK_TYPE.Star},
            -- {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.AddCoin, coins = 51000000},
            {type = GPBonusCfg.PICK_TYPE.DelCoin, coins = -52000000},
            {type = GPBonusCfg.PICK_TYPE.Grand, coins = 61000000, pick = false},
            {type = GPBonusCfg.PICK_TYPE.Major, coins = 62000000, pick = false},
            {type = GPBonusCfg.PICK_TYPE.Minor, coins = 63000000, pick = false},
            {type = GPBonusCfg.PICK_TYPE.Mini, coins = 64000000, pick = false},
            -- {type = GPBonusCfg.PICK_TYPE.Star},
            -- {type = GPBonusCfg.PICK_TYPE.Star},
            -- {type = GPBonusCfg.PICK_TYPE.Star},
            -- {type = GPBonusCfg.PICK_TYPE.Star},

            -- {type = GPBonusCfg.PICK_TYPE.GameOver},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star},
            {type = GPBonusCfg.PICK_TYPE.Star}
        }
    }
}

NetType.GiftPickBonus = "GiftPickBonus"

NetLuaModule.GiftPickBonus = "GameModule.GiftPickBonus.net.GPBonusNet"

ViewEventType.NOTIFY_PICK_BONUS_INDEX = "NOTIFY_PICK_BONUS_INDEX"
ViewEventType.NOTIFY_GP_BONUS_START_UI_OVER = "NOTIFY_GP_BONUS_START_UI_OVER"
