--[[
]]

local MythicGameConfig = require("GameModule.MythicGame.config.MythicGameConfig")
local MythicGameChapterData = import(".MythicGameChapterData")
local MythicGameRewardData = import(".MythicGameRewardData")
local MythicGameWinRewardData = import(".MythicGameWinRewardData")

local BaseGameModel = require("GameBase.BaseGameModel")
local MythicGameData = class("MythicGameData", BaseGameModel)

function MythicGameData:ctor()
    MythicGameData.super.ctor(self)

    self.m_logTrace = ""
end

-- message MythicGame {
--     optional int32 index = 1;//小游戏序号
--     optional int64 coins = 2; //或得奖励金币总价值
--     optional int64 expireAt = 3; //cd解释时间（毫秒）
--     optional string status = 4; //状态 INIT,PLAYING, FINISH
--     repeated MythicGameReward rewards = 5; //章节配置
--     optional int64 allChapter = 6; //章节总数
--     optional string source = 7;//来源
--     optional MythicGameWinReward winRewardData = 8;//获得奖励
--     repeated MythicGameChapter chapterDataList = 9;//章节相关
--   }
function MythicGameData:parseData(_data)
    self.p_id = _data.index
    self.p_coins = tonumber(_data.coins)
    self.p_expireAt = tonumber(_data.expireAt)
    self.p_allChapter = tonumber(_data.allChapter)
    self.p_status = _data.status
    self.p_source = _data.source

    self.p_levelConfigs = {}
    if _data.chapterDataList and #_data.chapterDataList > 0 then
        for i = 1, #_data.chapterDataList do
            local rewardData = MythicGameChapterData:create()
            rewardData:parseData(_data.chapterDataList[i])
            table.insert(self.p_levelConfigs, rewardData)
        end
    end

    self.p_levels = {}
    if _data.rewards and #_data.rewards > 0 then
        for i = 1, #_data.rewards do
            local rewardData = MythicGameRewardData:create()
            rewardData:parseData(_data.rewards[i])
            table.insert(self.p_levels, rewardData)
        end
    end
    
    self.m_logTrace = self.m_logTrace .. "|MythicGameData.rewards="..#_data.rewards

    self.p_winRewardData = nil
    if _data:HasField("winRewardData") then
        local wRData = MythicGameWinRewardData:create()
        wRData:parseData(_data.winRewardData)
        self.p_winRewardData = wRData
    end
end

function MythicGameData:getId()
    return self.p_id
end

function MythicGameData:getCoins()
    return self.p_coins or 0
end

function MythicGameData:getExpireAt()
    return (self.p_expireAt or 0)/1000
end

function MythicGameData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function MythicGameData:getStatus()
    return self.p_status
end

function MythicGameData:getWinRewardData()
    return self.p_winRewardData
end

function MythicGameData:getLevelCount()
    return self.p_allChapter
end

function MythicGameData:isInited()
    if self.p_status == MythicGameConfig.GameStatus.init then
        return true
    end
    return false
end

function MythicGameData:isPlaying()
    if self.p_status == MythicGameConfig.GameStatus.playing then
        return true
    end
    return false
end

function MythicGameData:isFinished()
    if self.p_status == MythicGameConfig.GameStatus.finish then
        return true
    end
    return false
end

function MythicGameData:getLevelConfigByIndex(_index)
    if _index and _index > 0 and #self.p_levelConfigs > 0 and _index <= #self.p_levelConfigs then
        return self.p_levelConfigs[_index]
    end
end

function MythicGameData:getCurLevelIndex()
    return #self.p_levels
end

function MythicGameData:getLevelDataByIndex(_index)
    if _index == nil then
        release_print("1CardSeekerData:getLevelDataByIndex,_index=nil")
    else
        release_print("2CardSeekerData:getLevelDataByIndex,_index=".._index .. ",levels=" .. #self.p_levels)
    end
    if _index and _index > 0 and _index <= #self.p_levels then
        return self.p_levels[_index]
    end
    release_print(debug.traceback("2CardSeekerData:debug:", 5))
end

function MythicGameData:getCurLevelData()
    local index = self:getCurLevelIndex()
    return self:getLevelDataByIndex(index)
end

function MythicGameData:getCurLevelConfig()
    local index = self:getCurLevelIndex()
    return self:getLevelConfigByIndex(index)
end

function MythicGameData:getLevelBubbleType(_levelIndex)
    if _levelIndex == 1 then
        return MythicGameConfig.BubbleTextType.firstLevel
    elseif _levelIndex == #self.p_levelConfigs then
        return MythicGameConfig.BubbleTextType.lastLevel
    else
        local levelCfg = self:getLevelConfigByIndex(_levelIndex)
        if levelCfg and levelCfg:getSpecial() == 1 then
            return MythicGameConfig.BubbleTextType.specialLevel
        end
        local preLevelCfg = self:getLevelConfigByIndex(_levelIndex - 1)
        if preLevelCfg and preLevelCfg:getSpecial() == 1 then
            return MythicGameConfig.BubbleTextType.firstAfterSpecialLevel
        end
    end
    return MythicGameConfig.BubbleTextType.normalLevel
end

function MythicGameData:isPickAgainLevel(_levelIndex)
    return false
end

function MythicGameData:isCheckPickAgain(_levelIndex)
    return false
end

return MythicGameData
