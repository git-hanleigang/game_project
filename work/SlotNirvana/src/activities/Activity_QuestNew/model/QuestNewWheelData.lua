local ShopItem = require "data.baseDatas.ShopItem"
local QuestNewWheelData = class("QuestNewWheelData")
local QuestNewWheelGridData = require "activities.Activity_QuestNew.model.QuestNewWheelGridData"

function QuestNewWheelData:parseData(data,pickStars)
    if self.p_type then
        if not self:isWheelFinish() and self.p_type == 2 and (data.type + 1) == 3 then
            if self.m_changeToLevel_Three == nil then
                self.m_changeToLevel_Three = true
                self.m_changeToLevel_Three_Out = true --地图上升级标记
            end
        else
            if not self:isWheelFinish() and self.p_type == 3 and (data.type + 1) == 4 then
                if self.m_changeToLevel_Four == nil then
                    self.m_changeToLevel_Four = true
                    self.m_changeToLevel_Four_Out = true --地图上升级标记
                end
            end
        end
    end
    self.p_type = data.type + 1 --轮盘类型（解锁的行数不同）

    self.p_pickStars = pickStars 

    self.p_lockStars = {} --每层解锁所需星星数目
    if data.lockStars and #data.lockStars > 0 then
        for i,v in ipairs(data.lockStars) do
            self.p_lockStars[i] = v
        end
    end

    if not self.p_tiers then
        if data.tiers and #data.tiers > 0 then
            self.p_tiers = {} --每层 数据
            for i,tier in ipairs(data.tiers) do
                local one_tier = {}
                one_tier.p_id = tier.id --层级序号
                one_tier.p_grids = {}  --每个格子信息
                if tier.grids and #tier.grids > 0 then
                    for j,grid in ipairs(tier.grids) do
                        local grid_data = QuestNewWheelGridData:create()
                        grid_data:parseData(grid)
                        table.insert(one_tier.p_grids,grid_data)
                    end
                end
                self.p_tiers[tier.id ] = one_tier
            end
        end
    else
        if data.tiers and #data.tiers > 0 then
            for i,tier in ipairs(data.tiers) do
                local tier_id = tier.id --层级序号
                if tier_id < 4 then
                    if tier.grids and #tier.grids > 0 then
                        for j,grid in ipairs(tier.grids) do
                            local grid_id = grid.id --序号
                            self.p_tiers[tier_id].p_grids[grid_id]:parseData(grid)
                        end
                    end
                end
            end
        end
    end

    self.p_active = data.active --轮盘是否解锁 bool
    
    if data.posIds and #data.posIds > 0 then
        self.p_posIds = data.posIds --轮盘中奖ID
        self.p_wheelCoins = tonumber(data.coins)--轮盘中奖 奖励金币

       if data.items ~= nil and #data.items > 0 then
            self.p_wheelItems = {}
            for k = 1, #data.items do
                local shopItem = ShopItem:create()
                shopItem:parseData(data.items[k], true)
                self.p_wheelItems[k] = shopItem
            end
        end
        if data.hitTier then
            self.p_hitTier = data.hitTier --轮盘中奖层数
        end
        if data.jackpotType then
            self.p_jackpotType = data.jackpotType --中大奖类型
        end
    end
end

function QuestNewWheelData:getType()
    return self.p_type 
end

-- 是否开启第三层
function QuestNewWheelData:isWillchangeToLevelThree(isOut)
    if isOut then
        return not not self.m_changeToLevel_Three_Out
    else
        return self.m_changeToLevel_Three
    end
end

function QuestNewWheelData:clearWillchangeToLevelThree(isOut)
    if isOut then
        self.m_changeToLevel_Three_Out = false
    else
        self.m_changeToLevel_Three = false
    end
end

-- 是否开启第四层
function QuestNewWheelData:isWillchangeToLevelFour(isOut)
    if isOut then
        return not not self.m_changeToLevel_Four_Out
    else
        return self.m_changeToLevel_Four
    end
end

function QuestNewWheelData:clearWillchangeToLevelFour(isOut)
    if isOut then
        self.m_changeToLevel_Four_Out = false
    else
        self.m_changeToLevel_Four = false
    end
end

function QuestNewWheelData:clearRemember()
    self.p_type_before = self.p_type
end

-- 根据层级Id 获取轮盘数据
function QuestNewWheelData:getWheelDataByTierId(tierId)
    return self.p_tiers[tierId] or {}
end

function QuestNewWheelData:isUnlock()
    return not not self.p_active
end

function QuestNewWheelData:setPickStars(pickStars)
    self.p_pickStars = pickStars 
end

function QuestNewWheelData:getWheelReward()
    if self.p_wheel then
        local items = self.p_wheel.p_items
        local idx = self.p_wheel.hitIndex
        if items and table.nums(items) > 0 and idx then
            return items[idx]
        end
    end
end

function QuestNewWheelData:getWheelNextLevelUnlockStars()
    if self.p_type >= 4 then
        return 0,self.p_lockStars[3]
    end
    local nextLevel = self.p_type
    local needStar = self.p_lockStars[nextLevel]
    return needStar - self.p_pickStars,needStar,nextLevel
end

function QuestNewWheelData:setWillDoWheelUnlock(willDo)
    self.p_willDoWheelUnlock = willDo
end
function QuestNewWheelData:isWillDoWheelUnlock()
    return not not self.p_willDoWheelUnlock
end

function QuestNewWheelData:setStatus(status)
    self.p_status = status
end

function QuestNewWheelData:isWheelHasPalyed()
    return not not self.p_posIds ,self.p_posIds,self.p_wheelCoins , self.p_hitTier
end

function QuestNewWheelData:getWheelGainBigJackpotType()
    local type = 0
    if self.p_jackpotType then
        if self.p_jackpotType == "Grand" then
            type = 3
        elseif self.p_jackpotType == "Major" then
            type = 2
        elseif self.p_jackpotType == "Minor" then
            type = 1
        end
    end
    return type
end

function QuestNewWheelData:isWheelFinish()
    return self.p_status == "Finish" 
end

return QuestNewWheelData
