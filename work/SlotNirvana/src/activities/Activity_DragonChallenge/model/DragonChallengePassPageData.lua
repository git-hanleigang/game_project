--[[

    author:{author}
    time:2023-08-28 22:27:19
]]
local DragonChallengePassDisplayData = import(".DragonChallengePassDisplayData")
local DragonChallengePassPay = import(".DragonChallengePassPay")
local DragonChallengePassRewardData = import(".DragonChallengePassRewardData")
local DragonChallengePassPageData = class("DragonChallengePassPageData")

function DragonChallengePassPageData:ctor()
    --self.p_display_clone = nil
    self.p_isCanShowBuyTips = false
end

function DragonChallengePassPageData:parseData(data)
    -- pass的序号 标识
    self.p_passSeq = tonumber(data.passSeq)
    -- pass的当前进度
    self.p_curProgress = tonumber(data.curProgress)
    -- pass的总进度
    self.p_totalProgress = tonumber(data.totalProgress)
    -- 是否付费
    self.p_payUnlocked = data.payUnlocked
    -- 是否完成该pass
    self.p_finished = data.finished
    -- 是否解锁该pass
    self.p_unLocked = data.unLocked
    -- 单个pass的价格
    if not self.p_payValue then
        self.p_payValue = DragonChallengePassPay:create()
    end
    self.p_payValue:parseData(data.payValue)

    -- 打包价格
    if not self.p_packPayValue then
        self.p_packPayValue = DragonChallengePassPay:create()
    end
    self.p_packPayValue:parseData(data.packPayValue)

    -- 免费节点数据
    self.p_freePoint = self:parsePassRewardList(data.free)
    -- 付费的节点数据
    self.p_payPoint = self:parsePassRewardList(data.pay)
    -- 玩家对boss进行的累计伤害
    self.p_damage = data.damage
    -- Pass付费提示数据
    self.p_display = self:parsePassDisplayList(data.display)

    if #self.p_display>0 then --1.没有到有 
        local mgr = G_GetMgr(ACTIVITY_REF.DragonChallenge)
        --local isEmpty = mgr:isEmptyPassDisplay()
        self.p_display.p_passSeq = self.p_passSeq 
        mgr:setPassDisplay(self.p_display)
    end
    -- 显示付费pass的价值
    self.p_passUsd = data.passUsd
    -- 显示打包pass的价值
    self.p_passPackUsd = data.passPackUsd
end

-- pass节点奖励数据
function DragonChallengePassPageData:parsePassRewardList(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local rewardData = DragonChallengePassRewardData:create()
            rewardData:parseData(v)
            table.insert(list, rewardData)
        end
    end
    return list
end

-- pass付费提示奖励节点数据
function DragonChallengePassPageData:parsePassDisplayList(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local rewardData = DragonChallengePassDisplayData:create()
            rewardData:parseData(v)
            table.insert(list, rewardData)
        end
    end
    return list
end

function DragonChallengePassPageData:getPassSeq()
    return self.p_passSeq
end

function DragonChallengePassPageData:getRewards()
end

function DragonChallengePassPageData:getPassIsUnlocked()
    return self.p_unLocked
end

function DragonChallengePassPageData:getFreeRewards()
    return self.p_freePoint
end

function DragonChallengePassPageData:getPayRewards()
    return self.p_payPoint
end

function DragonChallengePassPageData:getCurProgress()
    return self.p_curProgress
end

function DragonChallengePassPageData:getNextPayRewards()
    local payPoint = nil
    if self.p_finished then 
        payPoint = self.p_payPoint[#self.p_payPoint]
    else
        for i, v in pairs(self.p_payPoint) do
            if v.p_params > self.p_curProgress then
                payPoint = v 
                break
            end
        end
    end
    if payPoint == nil then
        payPoint = self.p_payPoint[#self.p_payPoint]
    end
    return payPoint
end

function DragonChallengePassPageData:getTotalProgress()
    return self.p_totalProgress
end

function DragonChallengePassPageData:getPayUnlocked()
    return self.p_payUnlocked
end

function DragonChallengePassPageData:getPayValue(type)
    if type == nil or type == 0 then
        return self.p_payValue
    end
    return self.p_packPayValue
end

function DragonChallengePassPageData:getPayValueFairly(type)
    if type == nil or type == 0 then
        return self.p_passUsd
    end
    return self.p_passPackUsd
end

-- 获取可领奖数量
function DragonChallengePassPageData:getCanCollectCount()
    local count = 0
    for i, v in pairs(self.p_freePoint) do
        if v.p_params <= self.p_curProgress and not v:isCollected() then
            count = count + 1
        end
    end

    if self.p_payUnlocked then
        for i, v in pairs(self.p_payPoint) do
            if v.p_params <= self.p_curProgress and not v:isCollected() then
                count = count + 1
            end
        end
    end
    return count
end

-- 获取可领奖的付费节点
-- function DragonChallengePassPageData:getPayNodeCanCollect()
--     local params = {}
--     for i, v in pairs(self.p_payPoint) do
--         if v.p_params <= self.p_curProgress and not v:isCollected() then
--             params[#params+1] = v
--         end
--     end
   
--     return self.p_display_clone
-- end

return DragonChallengePassPageData
