-- quest 章节数据

local ShopItem = require "data.baseDatas.ShopItem"
local QuestNewPointData = require "activities.Activity_QuestNew.model.QuestNewPointData"
local QuestNewWheelData = require "activities.Activity_QuestNew.model.QuestNewWheelData"
local QuestNewChapterData = class("QuestNewChapterData")

-- message FantasyQuestPhase {
--   repeated FantasyQuestStage stages = 1; // 关卡数据
--   optional FantasyQuestWheel jackpotWheel = 2; // 轮盘数据
--   repeated FantasyQuestStarMeter starMeters = 3; // starMeter
--   optional int32 pickStars = 4; //当前章节已经收集星星
--   optional int32 maxStars = 5; // 最大收集星星
-- }

function QuestNewChapterData:parseData(data,chapterId,maxCurrentChapter,isReset)
    self.m_chapterId = chapterId --当前数据属于哪一章节
    if isReset then
        self.m_isReset = isReset --是否是重置章节
        return
    end
    if maxCurrentChapter then
        if not self.p_maxCurrentChapter then
            self.p_maxCurrentChapter = maxCurrentChapter
        else
            if self.m_unlock ~= nil then
                if self.m_chapterId <= maxCurrentChapter and self.p_maxCurrentChapter <= maxCurrentChapter and not self.m_unlock then
                    self.m_willDoUnlock = true
                end
            end
            self.p_maxCurrentChapter = maxCurrentChapter
        end
        if self.m_chapterId <= maxCurrentChapter then
            self.m_unlock = true
        else
            self.m_unlock = false
        end
    end
    self.p_stage = data.stage -- 当前章节玩到哪一关
    if data.stages and #data.stages > 0 then
        if not self.p_stages then
            self.p_stages = {}
            local allStageNum = #data.stages
            for i = 1, allStageNum do
                local _data = data.stages[i]
                local stage_data = QuestNewPointData:create()
                stage_data:parseData(_data,self.p_stage,chapterId,allStageNum)
                self.p_stages[i] = stage_data
            end
        else
            for i = 1, #data.stages do
                local _data = data.stages[i]
                self.p_stages[i]:parseData(_data,self.p_stage,chapterId)
            end
        end
    end

    self.p_pickStars = data.pickStars -- 当前章节已经收集星星
    if not self.p_pickStars_Before then
        self.p_pickStars_Before = self.p_pickStars
    end
    self.p_maxStars = data.maxStars-- 最大收集星星
    self.p_status = data.status

    --轮盘数据 章节只有一组轮盘数据
    if data.jackpotWheel then
        if self.p_wheel_data then
            self.p_wheel_data:parseData(data.jackpotWheel,self.p_pickStars)
            self.p_wheel_data:setStatus(data.status)
        else
            local wheel_data = QuestNewWheelData:create()
            wheel_data:parseData(data.jackpotWheel,self.p_pickStars)
            self.p_wheel_data = wheel_data
            wheel_data:setStatus(data.status)
        end
    end

    if data.starMeters and #data.starMeters > 0 then
        self.p_starMeters = {}
        for i,v in ipairs(data.starMeters) do
            local one_star = {}
            one_star.p_id = v.id
            one_star.p_stars = v.stars or 0  --获得本节点奖励所需星星
            one_star.p_coins = tonumber(v.coins) or 0
            one_star.p_collected = not not v.collected -- 是否领取
        
            one_star.p_items = {}
            if v.items ~= nil and #v.items > 0 then
               for j = 1, #v.items do
                   local shopItem = ShopItem:create()
                   shopItem:parseData(v.items[j], true)
                   one_star.p_items[j] = shopItem
               end
            end
            self.p_starMeters[i] = one_star
        end
        if not self.p_starMeters_Before then
            self.p_starMeters_Before = self.p_starMeters
        end
    end

    if self.p_pickStars >= self.p_maxStars and self:isWheelFinish() and self:isAllBoxCollected()  and self:isStarMetersRewardOver() then 
        if self.p_hasCheckCompleted and self.p_completed == nil then
            self.p_willDoCompleted = true
        end
        self.p_completed = true
    end
    self.p_hasCheckCompleted = true
end

-------------------------------------------------刷新关卡-----------------------------------------------

function QuestNewChapterData:isUnlock()
    return self.m_unlock
end

function QuestNewChapterData:isWillDoUnlock()
    return not not self.m_willDoUnlock
end

function QuestNewChapterData:clearWillDoUnlock()
    self.m_willDoUnlock = false
end

function QuestNewChapterData:isCompleted()
    return self.p_completed
end

function QuestNewChapterData:isWillDoCompleted()
    return not not self.p_willDoCompleted 
end

function QuestNewChapterData:clearWillDoCompleted()
    self.p_willDoCompleted = false
end

--是否是重置章节
function QuestNewChapterData:isResetChapter() 
    return self.m_isReset
end

function QuestNewChapterData:setCurrentStage(stage)
    self.p_stage = stage
    for i,oneStage in ipairs(self.p_stages) do
        oneStage:setMaxStage(stage)
    end
end

function QuestNewChapterData:getCurrentStage()
    return self.p_stage
end

function QuestNewChapterData:getMinWillCompletedStage()
    local minStage = 0
    for i,stage in ipairs(self.p_stages) do
        if stage then
            if stage:isWillDoCompleted() then
                minStage = stage:getId()
                break
            end
        end
    end
    return minStage
end

function QuestNewChapterData:getMinWillUnlockStage()
    local minStage = 0
    for i,stage in ipairs(self.p_stages) do
        if stage then
            if stage:isWillDoUnlock() then
                minStage = stage:getId()
                break
            end
        end
    end
    return minStage
end


function QuestNewChapterData:getAllPointData()
    return self.p_stages
end

function QuestNewChapterData:getPointDataByIndex(index)
    if index <= #self.p_stages then
        return self.p_stages[index]
    end
    return nil
end

function QuestNewChapterData:setPickStars(pickStars)
    self.p_pickStars = pickStars 
    self:checkChapterCompleted()
    self.p_wheel_data:setPickStars(pickStars)
end

function QuestNewChapterData:checkChapterCompleted()
    if self.m_isReset then
        return
    end
    if self.p_pickStars >= self.p_maxStars and self:isWheelFinish() and self:isAllBoxCollected() and self:isStarMetersRewardOver() then
        if self.p_completed == nil then
            self.p_willDoCompleted = true
        end
        self.p_completed = true
    end
end

function QuestNewChapterData:isAllBoxCollected()
    local result = true
    for i,stage in ipairs(self.p_stages) do
        if stage then
            if not stage:isBoxCompleted() then
                result = false
                break
            end
        end
    end
    return result
end

function QuestNewChapterData:isStarMetersRewardOver()
    local result = true
    for i,one_star in ipairs(self.p_starMeters) do
        if not one_star.p_collected then
            result = false
            break
        end
    end
    return result
end

function QuestNewChapterData:refreshWheelData(jackpotWheel)
    local unlock_before = self.p_wheel_data:isUnlock()
    self.p_wheel_data:parseData(jackpotWheel,self.p_pickStars)
    local unlock_now = self.p_wheel_data:isUnlock()
    if unlock_now == true and unlock_before == false then
        if not self.p_willDoWheelUnlock then
            self.p_willDoWheelUnlock = true
            self.p_wheel_data:setWillDoWheelUnlock(true)
        end
    end
end

function QuestNewChapterData:isWillDoWheelUnlock()
    return not not self.p_willDoWheelUnlock
end

function QuestNewChapterData:clearWillDoWheelUnlock()
    self.p_willDoWheelUnlock = false
    self.p_wheel_data:setWillDoWheelUnlock(false)
end

function QuestNewChapterData:getWheelData()
    return self.p_wheel_data
end

function QuestNewChapterData:getNextStarRewardData()
    if self.p_pickStars == self.p_maxStars then
        return self.p_starMeters[#self.p_starMeters]
    end
    for i,one_star in ipairs(self.p_starMeters) do
        if one_star.p_stars > self.p_pickStars  then
            return one_star
        end
    end
    return self.p_starMeters[1]
end

function QuestNewChapterData:getStarMeters(forBefore)
    if forBefore then
        return self.p_starMeters_Before
    end
    return self.p_starMeters
end

function QuestNewChapterData:resetCurrentChapterStarPrizesRememberData()
    self.p_starMeters_Before = self.p_starMeters
    self.p_pickStars_Before = self.p_pickStars
end

function QuestNewChapterData:checkHasStarMetersRewardToGain()
    for i,one_star in ipairs(self.p_starMeters) do
        if one_star.p_stars <= self.p_pickStars and  not one_star.p_collected then
            return true
        end
    end
    return false
end

function QuestNewChapterData:getPickStars(forBefore)
    if forBefore then
        return self.p_pickStars_Before
    end
    return self.p_pickStars
end

function QuestNewChapterData:getMaxStars()
    return self.p_maxStars
end
function QuestNewChapterData:isWheelFinish()
    return self.p_status == "Finish" 
end

function QuestNewChapterData:setAllChapterCount(allChapterCount)
    self.m_allChapterCount = allChapterCount
end

function QuestNewChapterData:isCurrentChapter()
    return self.m_chapterId == self.p_maxCurrentChapter and self.m_chapterId ~= self.m_allChapterCount
end
return QuestNewChapterData
