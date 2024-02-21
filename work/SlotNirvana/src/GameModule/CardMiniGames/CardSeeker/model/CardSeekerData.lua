--[[
]]
local CardAdventureChapterData = import(".CardAdventureChapterData")
local CardAdventureRewardData = import(".CardAdventureRewardData")
local CardAdventureWinRewardData = import(".CardAdventureWinRewardData")

local BaseGameModel = require("GameBase.BaseGameModel")
local CardSeekerData = class("CardSeekerData", BaseGameModel)

function CardSeekerData:ctor()
    self:setRefName(G_REF.CardSeeker)
    self.m_logTrace = ""
end

-- message CardAdventureGameResult {
--     optional int64 allChapter = 1; //章节总数
--     optional int64 expireAt = 2; //cd解释时间（毫秒）
--     optional string source = 3;//来源
--     optional string status = 4; //状态 INIT,PLAYING,FINISH
--     repeated CardAdventureReward rewards = 5; //章节配置
--     optional CardAdventureWinReward winRewardData = 6;//获得奖励
--     repeated CardAdventureChapter chapterDataList = 7;//章节相关
--     optional bool adventureFistBuy = 8;//小游戏是否首次购买
--     optional bool showGuide = 9;//是否显示新手引导
--     optional bool canFree = 10;//能否免费复活 月卡权益
--     optional bool openAgain = 11;//是否开启再选一次
--   }
function CardSeekerData:parseData(data)
    self.p_allChapter = tonumber(data.allChapter)
    self.p_expireAt = tonumber(data.expireAt)
    self.p_source = data.source
    self.p_status = data.status
    self.p_levelConfigs = {}
    if data.chapterDataList and #data.chapterDataList > 0 then
        for i = 1, #data.chapterDataList do
            local rewardData = CardAdventureChapterData:create()
            rewardData:parseData(data.chapterDataList[i])
            table.insert(self.p_levelConfigs, rewardData)
        end
    end
    self.p_levels = {}
    release_print("CardSeekerData:parseData 1")
    if data.rewards and #data.rewards > 0 then
        release_print("CardSeekerData:parseData 2, len="..#data.rewards)
        for i = 1, #data.rewards do
            local rewardData = CardAdventureRewardData:create()
            rewardData:parseData(data.rewards[i])
            table.insert(self.p_levels, rewardData)
        end
    end
    self.m_logTrace = self.m_logTrace .. "|CardSeekerData.rewards="..#data.rewards

    self.p_winRewardData = nil
    if data:HasField("winRewardData") then
        local wRData = CardAdventureWinRewardData:create()
        wRData:parseData(data.winRewardData)
        self.p_winRewardData = wRData
    end

    self.p_isFisrtBuy = data.adventureFistBuy
    self.p_showGuide = data.showGuide
    self.p_canFree = data.canFree -- 月卡权益(第一次免费复活)

    self.p_openAgain = data.openAgain

    -- self:initCDTime()
    gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_DATA_REFRESH)
end

function CardSeekerData:getFirstBuy()
    return self.p_isFisrtBuy
end

function CardSeekerData:getCoins()
    return self.p_coins or 0
end

function CardSeekerData:getExpireAt()
    return (self.p_expireAt or 0)/1000
end

function CardSeekerData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function CardSeekerData:getStatus()
    return self.p_status
end

function CardSeekerData:getWinRewardData()
    return self.p_winRewardData
end

function CardSeekerData:getLevelCount()
    return self.p_allChapter
end

function CardSeekerData:getCanFree()
    return self.p_canFree
end

function CardSeekerData:isOpenAgain()
    return self.p_openAgain
end

function CardSeekerData:isInited()
    if self.p_status == CardSeekerCfg.GameStatus.init then
        return true
    end
    return false
end

function CardSeekerData:isPlaying()
    if self.p_status == CardSeekerCfg.GameStatus.playing then
        return true
    end
    return false
end

function CardSeekerData:isFinished()
    if self.p_status == CardSeekerCfg.GameStatus.finish then
        return true
    end
    return false
end

function CardSeekerData:getLevelConfigByIndex(_index)
    if _index and _index > 0 and #self.p_levelConfigs > 0 and _index <= #self.p_levelConfigs then
        return self.p_levelConfigs[_index]
    end
end

function CardSeekerData:getCurLevelIndex()
    return #self.p_levels
end

function CardSeekerData:getLevelDataByIndex(_index)
    if _index == nil then
        release_print("1CardSeekerData:getLevelDataByIndex,_index=nil")
    else
        release_print("2CardSeekerData:getLevelDataByIndex,_index=".._index .. ",levels=" .. #self.p_levels)
    end
    if _index and _index > 0 and _index <= #self.p_levels then
        return self.p_levels[_index]
    end
    local msg = "2CardSeekerData:getChapterIndex,"
    if self.p_levels and #self.p_levels > 0 then
        for i=1,#self.p_levels do
            local chapterIndex = self.p_levels[i]:getChapterIndex()
            msg = msg .. "chapter_"..i.."="..chapterIndex .. ","
        end
    end
    release_print(msg)
end

function CardSeekerData:getCurLevelData()
    local index = self:getCurLevelIndex()
    return self:getLevelDataByIndex(index)
end

function CardSeekerData:getCurLevelConfig()
    local index = self:getCurLevelIndex()
    return self:getLevelConfigByIndex(index)
end

function CardSeekerData:getLevelBubbleType(_levelIndex)
    if _levelIndex == 1 then
        return CardSeekerCfg.BubbleTextType.firstLevel
    elseif _levelIndex == #self.p_levelConfigs then
        return CardSeekerCfg.BubbleTextType.lastLevel
    else
        local levelCfg = self:getLevelConfigByIndex(_levelIndex)
        if levelCfg and levelCfg:getSpecial() == 1 then
            return CardSeekerCfg.BubbleTextType.specialLevel
        end
        local preLevelCfg = self:getLevelConfigByIndex(_levelIndex - 1)
        if preLevelCfg and preLevelCfg:getSpecial() == 1 then
            return CardSeekerCfg.BubbleTextType.firstAfterSpecialLevel
        end
    end
    return CardSeekerCfg.BubbleTextType.normalLevel
end

-- function CardSeekerData:initCDTime()
--     if self.m_expireAt ~= nil and self.m_expireAt == self:getExpireAt() then
--         return
--     end
--     -- cardtodo 待优化 一秒刷新一次
--     if self.m_cdTimer ~= nil then
--         scheduler.unscheduleGlobal(self.m_cdTimer)
--         self.m_cdTimer = nil
--     end
--     self.m_lastTime = self:getLeftTime()
--     self.m_cdTimer =
--         scheduler.scheduleUpdateGlobal(
--         function(dt)
--             local time = self:getLeftTime()
--             if self.m_lastTime > 0 and time <= 0 then
--                 if self.m_cdTimer ~= nil then
--                     scheduler.unscheduleGlobal(self.m_cdTimer)
--                     self.m_cdTimer = nil
--                 end
--                 gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_PICKGAME_ENTER_CD)
--             else
--                 self.m_lastTime = time
--             end
--         end
--     )
-- end

function CardSeekerData:isPickAgainLevel(_levelIndex)
    if _levelIndex == 10 or _levelIndex == 15 or _levelIndex == 20 then
        return true
    end
    return false
end

function CardSeekerData:isCheckPickAgain(_levelIndex)
    if self:isOpenAgain() then
        if self:isPickAgainLevel(_levelIndex) then
            return true
        end
    end
    return false
end

return CardSeekerData
