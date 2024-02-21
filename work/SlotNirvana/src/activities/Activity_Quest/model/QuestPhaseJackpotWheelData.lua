-- quest 章节数据

local QuestPhaseJackpotWheelData = class("QuestPhaseJackpotWheelData")
local QuestJackpotCoinIncreaseData = require "activities.Activity_Quest.model.QuestJackpotCoinIncreaseData"
local QuestPhaseJackpotWheelGridData = require "activities.Activity_Quest.model.QuestPhaseJackpotWheelGridData"

function QuestPhaseJackpotWheelData:ctor()
    self.p_tierData = {}
end

function QuestPhaseJackpotWheelData:parseData(data)
    self.p_minor = tonumber(data.miniJackpot)  --link jackpot金币
    self.p_major = tonumber(data.majorJackpot) 
    self.p_grand = tonumber(data.grandJackpot) 
    self.p_wheelId  = data.wheelId --轮盘id， 决定解锁几
    self:parseWheelData(data.tiers)
    self:updateQuestGoldIncrease(true,data)
    self.p_hitPosVec = {2,6}
end

function QuestPhaseJackpotWheelData:parseWheelData(wheelData)
    if wheelData and #wheelData > 0 then
        self.p_tierData = {}
        for index,tierData in ipairs(wheelData) do
            local tierVec = {}
            local tier_id = tierData.id
            if tierData.grids and #tierData.grids > 0 then
                for i,oneData in ipairs(tierData.grids) do
                    local gridData = QuestPhaseJackpotWheelGridData:create()
                    gridData:parseData(oneData)
                    gridData:setTierId(tier_id)
                    table.insert(tierVec, gridData)
                end
            end
            self.p_tierData[tier_id] = tierVec
        end
    end
end

function QuestPhaseJackpotWheelData:getWheelTierVecByTierId(tier_id)
    return self.p_tierData[tier_id] or {}
end

function QuestPhaseJackpotWheelData:setHitPos(hitPos)
    self.p_hitPosVec = hitPos
end


function QuestPhaseJackpotWheelData:getHitResultData()
    local data = {}
    data.tier_id = self:getHitTier()
    data.hitPosIds = self:getHitPos()
    local hitPos = self.p_hitPosVec[#self.p_hitPosVec]
    local hitGridData = self.p_tierData[data.tier_id][hitPos]
    data.grid_type = hitGridData:getType()
    data.jackpotType = hitGridData:getJackpotType()
    data.hitCoin = hitGridData:getCoins()
    if self.m_hitCoins then
        data.hitCoin = self.m_hitCoins
    end
    if data.hitCoin == 0 then
        data.hitItem = hitGridData:getItem()
    end
    return data
end

function QuestPhaseJackpotWheelData:getHitPos()
    return self.p_hitPosVec
end

function QuestPhaseJackpotWheelData:getHitTier()
    return #self.p_hitPosVec
end

function QuestPhaseJackpotWheelData:setTargetQuestGoldIncrease(data)
    self.p_minor = tonumber(data.miniJackpot)  --link jackpot金币
    self.p_major = tonumber(data.majorJackpot) 
    self.p_grand = tonumber(data.grandJackpot) 
end

function QuestPhaseJackpotWheelData:updateQuestGoldIncrease(forceInit,data)
    if not self.m_isInitGoldRun and not data then
        return false 
    end

    if data then
        self:setTargetQuestGoldIncrease(data)
    end
    local refresh = false
    if (forceInit  or not self.m_increaseList) and data then
        self.m_increaseList = {}
       
        local minorData = QuestJackpotCoinIncreaseData:create()
        minorData:setMaxCoins(self.p_minor)
        self.m_increaseList[#self.m_increaseList + 1] = minorData

        local majorData = QuestJackpotCoinIncreaseData:create()
        majorData:setMaxCoins(self.p_major)
        self.m_increaseList[#self.m_increaseList + 1] = majorData

        local grandData = QuestJackpotCoinIncreaseData:create()
        grandData:setMaxCoins(self.p_grand)
        self.m_increaseList[#self.m_increaseList + 1] = grandData
        if not self.m_isInitGoldRun then
            self.m_isInitGoldRun = true
        end
    else
        for i = 1, #self.m_increaseList do
            local oneRefresh = self.m_increaseList[i]:updateIncrese()
            if not refresh then
                refresh = oneRefresh
            end
        end
    end
    return refresh
end

-- 第二个返回值 是否是展示名字
function QuestPhaseJackpotWheelData:getRunGoldCoinByType(type)
    local _inc = self.m_increaseList[type]
    if _inc then
        return _inc:getRuningGold()
    else
        return 0
    end 
end

function QuestPhaseJackpotWheelData:isCanShowRunGold()
    return not not self.m_isInitGoldRun
end

function QuestPhaseJackpotWheelData:setWheelResultData(resultData)
   if resultData then
       if resultData.wheelPos then
            self:setHitPos(resultData.wheelPos)
       end
       if resultData.wheelCoins then
            self:setHitCoins(resultData.wheelCoins)
       end
   end
end

function QuestPhaseJackpotWheelData:setHitCoins(coins)
    self.m_hitCoins = coins
end

--是否解锁中心位置
function QuestPhaseJackpotWheelData:isUnlockGrand()
    return not not self.p_tierData[4]
end

return QuestPhaseJackpotWheelData
