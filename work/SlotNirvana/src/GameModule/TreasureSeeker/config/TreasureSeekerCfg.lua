--[[
]]
GD.TreasureSeekerCfg = {}

TreasureSeekerCfg.TEST_DATA = {}

-- 换皮全局搜索： 换皮时需主动更改这个名字，暂时无法通过配置来换皮
-- TreasureSeekerCfg.csbPath = "Activity/Activity_TreasureSeeker/csb/"
-- TreasureSeekerCfg.otherPath = "Activity/Activity_TreasureSeeker/other/"
-- TreasureSeekerCfg.luaPath = "Activity.TreasureSeeker."


-- 换皮时需主动更改这个名字，暂时无法通过配置来换皮
TreasureSeekerCfg.csbPath = "Activity/Activity_TreasureSeekerAllCard/csb/"
TreasureSeekerCfg.otherPath = "Activity/Activity_TreasureSeekerAllCard/other/"
TreasureSeekerCfg.luaPath = "Activity.TreasureSeekerAllCard."

TreasureSeekerCfg.BoxTotalCount = 4
TreasureSeekerCfg.GameStatus = {
    init = "INIT",
    playing = "PLAYING",
    finish = "FINISH"
}
TreasureSeekerCfg.LevelType = {
    normal = 0,
    special = 1
}
TreasureSeekerCfg.BoxType = {
    coin = "COINS",
    gem = "GEMS",
    item = "ITEM",
    monster = "END"
}

TreasureSeekerCfg.BubblETextType = {
    normalLevel = "normalLevel", -- 普通关卡，无气泡的
    firstLevel = "firstLevel", -- 第一关
    specialLevel = "specialLevel", -- 特殊关
    firstAfterSpecialLevel = "firstAfterSpecialLevel", -- 特殊关后的第一关
    lastLevel = "lastLevel" -- 最后一关
}

TreasureSeekerCfg.BubbleTexts = {
    {levelType = "firstLevel", ["levels"] = {1}, ["texts"] = {"PICK YOUR CHEST!"}},
    {levelType = "specialLevel", ["levels"] = {5, 10, 15}, ["texts"] = {"YOU'RE SAFE NOW!", "FIND THE GREAT REWARDS!"}},
    {levelType = "firstAfterSpecialLevel", ["levels"] = {6, 11, 16}, ["texts"] = {"WATCH OUT", "FOR THE GUARD!"}},
    {levelType = "lastLevel", ["levels"] = {20}, ["texts"] = {"GREAT!", "THIS IS THE FINAL STAGE!"}}
}

TreasureSeekerCfg.getBubbleTextByLevelIndex = function(_levelIndex)
    if _levelIndex and _levelIndex > 0 then
        for i = 1, #TreasureSeekerCfg.BubbleTexts do
            local cfg = TreasureSeekerCfg.BubbleTexts[i]
            if cfg.levels and #cfg.levels > 0 then
                for j = 1, #cfg.levels do
                    if cfg.levels[j] == _levelIndex then
                        return cfg.texts
                    end
                end
            end
        end
    end
    return nil
end

TreasureSeekerCfg.getBubbleTextByLevelType = function(_levelType)
    if _levelType and _levelType ~= "" then
        for i = 1, #TreasureSeekerCfg.BubbleTexts do
            local cfg = TreasureSeekerCfg.BubbleTexts[i]
            if cfg.levelType == _levelType then
                return cfg.texts
            end
        end
    end
    return nil
end

ViewEventType.TREASURE_SEEKER_REQUEST_OPENBOX = "TREASURE_SEEKER_REQUEST_OPENBOX"
ViewEventType.TREASURE_SEEKER_REQUEST_COLLECT = "TREASURE_SEEKER_REQUEST_COLLECT"
ViewEventType.TREASURE_SEEKER_REQUEST_COSTGEM = "TREASURE_SEEKER_REQUEST_COSTGEM"
ViewEventType.TREASURE_SEEKER_REQUEST_GIVEUP = "TREASURE_SEEKER_REQUEST_GIVEUP"
ViewEventType.TREASURE_SEEKER_SHAKE_BOX = "TREASURE_SEEKER_SHAKE_BOX"
ViewEventType.TREASURE_SEEKER_CG_CLOSED = "TREASURE_SEEKER_CG_CLOSED"

NetType.TreasureSeeker = "TreasureSeeker"
NetLuaModule.TreasureSeeker = "GameModule.TreasureSeeker.net.TreasureSeekerNet"

-- 初始化
local exat = util_getCurrnetTime() * 1000 + 86400
TreasureSeekerCfg.TEST_DATA = {
    adventureFistBuy = true,
    adventureResults = {
        {
            index = 1,
            coins = 9090909000,
            expireAt = exat,
            status = "INIT",
            chapterDataList = {
                {
                    chapter = 1,
                    special = 0,
                    needGems = 100
                },
                {
                    chapter = 2,
                    special = 1,
                    needGems = 200
                },
                {
                    chapter = 3,
                    special = 0,
                    needGems = 300
                },
                {
                    chapter = 4,
                    special = 0,
                    needGems = 400
                }
            },
            -- level
            rewards = {
                {
                    chapter = 1,
                    index = 0,
                    -- box
                    rewards = {
                        {
                            type = "COINS",
                            values = 100,
                            items = {}
                        },
                        {
                            type = "COINS",
                            values = 200,
                            items = {}
                        },
                        {
                            type = "COINS",
                            values = 300,
                            items = {}
                        },
                        {
                            type = "COINS",
                            values = 400,
                            items = {}
                        }
                    },
                    leftCount = 1,
                    pos = {}
                }
            },
            allChapter = 4,
            source = "",
            winRewardData = {
                coins = 0,
                gems = 0,
                items = {}
            }
        }
    }
}
-- 点第一个宝箱返回数据
TreasureSeekerCfg.TEST_DATA_OPENBOX_1 = function()
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].status = "PLAYING"
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].winRewardData.coins = 100
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].leftCount = 0
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].pos = {1}
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards + 1] = {
        chapter = 2,
        index = 1,
        -- box
        rewards = {
            {
                type = "COINS",
                values = 1000,
                items = {}
            },
            {
                type = "END",
                values = 2000,
                items = {}
            },
            {
                type = "COINS",
                values = 3000,
                items = {}
            },
            {
                type = "COINS",
                values = 4000,
                items = {}
            }
        },
        leftCount = 1,
        pos = {}
    }
end
-- 点第二宝箱返回数据，中鲨鱼
TreasureSeekerCfg.TEST_DATA_OPENBOX_2 = function()
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].leftCount = 0
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].pos = {2}
end
-- 点花费钻石返回数据
TreasureSeekerCfg.TEST_DATA_COST = function()
    TreasureSeekerCfg.TEST_DATA.adventureFistBuy = false
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].index = 2
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].leftCount = 1
end
-- 点第三个宝箱返回数据
TreasureSeekerCfg.TEST_DATA_OPENBOX_3 = function()
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].winRewardData.coins = 3100
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].leftCount = 0
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].pos = {2, 3}
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards + 1] = {
        chapter = 3,
        index = 1,
        -- box
        rewards = {
            {
                type = "COINS",
                values = 10000,
                items = {}
            },
            {
                type = "GEMS",
                values = 90,
                items = {}
            },
            {
                type = "END",
                values = 30000,
                items = {}
            },
            {
                type = "COINS",
                values = 40000,
                items = {}
            }
        },
        leftCount = 1,
        pos = {}
    }
end
-- 点第四个宝箱返回数据
TreasureSeekerCfg.TEST_DATA_OPENBOX_4 = function()
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].winRewardData.gems = 90
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].leftCount = 0
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].pos = {4}
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards + 1] = {
        chapter = 4,
        index = 1,
        -- box
        rewards = {
            {
                type = "COINS",
                values = 10000,
                items = {}
            },
            {
                type = "GEMS",
                values = 900,
                items = {}
            },
            {
                type = "END",
                values = 30000,
                items = {}
            },
            {
                type = "COINS",
                values = 40000,
                items = {}
            }
        },
        leftCount = 1,
        pos = {}
    }
end
-- 点第五个宝箱返回数据
TreasureSeekerCfg.TEST_DATA_OPENBOX_5 = function()
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].winRewardData.gems = 990
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].leftCount = 0
    TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards[#TreasureSeekerCfg.TEST_DATA.adventureResults[1].rewards].pos = {1}
end
