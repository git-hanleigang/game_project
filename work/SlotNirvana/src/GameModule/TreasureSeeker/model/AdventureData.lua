--[[
    message Adventure {
    optional int32 index = 1;//小游戏序号
    optional int64 coins = 2; //或得奖励金币总价值
    optional int64 expireAt = 3; //cd解释时间（毫秒）
    optional string status = 4; //状态 INIT,PLAYING
    repeated AdventureReward rewards = 5; //章节配置
    optional int64 allChapter = 6; //章节总数
    optional string source = 7;//来源
    optional AdventureWinReward winRewardData = 8;//获得奖励
    }
]]
local AdventureChapterData = import(".AdventureChapterData")
local AdventureRewardData = import(".AdventureRewardData")
local AdventureWinRewardData = import(".AdventureWinRewardData")
local AdventureData = class("AdventureData")

function AdventureData:parseData(data)
    self.p_id = data.index
    self.p_coins = tonumber(data.coins)
    self.p_expireAt = tonumber(data.expireAt)
    self.p_status = data.status
    self.p_levelConfigs = {}
    if data.chapterDataList and #data.chapterDataList > 0 then
        for i = 1, #data.chapterDataList do
            local rewardData = AdventureChapterData:create()
            rewardData:parseData(data.chapterDataList[i])
            table.insert(self.p_levelConfigs, rewardData)
        end
    end
    self.p_levels = {}
    if data.rewards and #data.rewards > 0 then
        for i = 1, #data.rewards do
            local rewardData = AdventureRewardData:create()
            rewardData:parseData(data.rewards[i])
            table.insert(self.p_levels, rewardData)
        end
    else
        assert(false, "数据初始化有错误")
    end
    self.p_allChapter = tonumber(data.allChapter)
    self.p_source = data.source
    self.p_winRewardData = nil
    if data.winRewardData ~= nil then
        local wRData = AdventureWinRewardData:create()
        wRData:parseData(data.winRewardData)
        self.p_winRewardData = wRData
    end
end

function AdventureData:getId()
    return self.p_id
end

function AdventureData:getCoins()
    return self.p_coins
end

function AdventureData:getExpireAt()
    return self.p_expireAt
end

function AdventureData:getStatus()
    return self.p_status
end

function AdventureData:getWinRewardData()
    return self.p_winRewardData
end

function AdventureData:getLevelCount()
    return self.p_allChapter
end

function AdventureData:isInited()
    if self.p_status == TreasureSeekerCfg.GameStatus.init then
        return true
    end
    return false
end

function AdventureData:isPlaying()
    if self.p_status == TreasureSeekerCfg.GameStatus.playing then
        return true
    end
    return false
end

function AdventureData:isFinished()
    if self.p_status == TreasureSeekerCfg.GameStatus.finish then
        return true
    end
    return false
end

function AdventureData:getLevelConfigByIndex(_index)
    if _index and _index > 0 and #self.p_levelConfigs > 0 and _index <= #self.p_levelConfigs then
        return self.p_levelConfigs[_index]
    end
end

function AdventureData:getCurLevelIndex()
    return #self.p_levels
end

function AdventureData:getLevelDataByIndex(_index)
    if _index and _index > 0 and _index <= #self.p_levels then
        return self.p_levels[_index]
    end
end

function AdventureData:getCurLevelData()
    local index = self:getCurLevelIndex()
    return self:getLevelDataByIndex(index)
end

function AdventureData:getCurLevelConfig()
    local index = self:getCurLevelIndex()
    return self:getLevelConfigByIndex(index)
end

function AdventureData:getLevelBubbleType(_levelIndex)
    if _levelIndex == 1 then
        return TreasureSeekerCfg.BubblETextType.firstLevel
    elseif _levelIndex == #self.p_levelConfigs then
        return TreasureSeekerCfg.BubblETextType.lastLevel
    else
        local levelCfg = self:getLevelConfigByIndex(_levelIndex)
        if levelCfg and levelCfg:getSpecial() == 1 then
            return TreasureSeekerCfg.BubblETextType.specialLevel
        end
        local preLevelCfg = self:getLevelConfigByIndex(_levelIndex - 1)
        if preLevelCfg and preLevelCfg:getSpecial() == 1 then
            return TreasureSeekerCfg.BubblETextType.firstAfterSpecialLevel
        end
    end
    return TreasureSeekerCfg.BubblETextType.normalLevel
end

return AdventureData
