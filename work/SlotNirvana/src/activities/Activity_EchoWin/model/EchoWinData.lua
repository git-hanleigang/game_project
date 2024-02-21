
-- EchoWin 数据解析

local BaseActivityData = require "baseActivity.BaseActivityData"
local EchoWinData = class("EchoWinData", BaseActivityData)

function EchoWinData:ctor()
    gLobalNoticManager:addObserver(self,function(self,params)
        if params[1] == true then
            local spinData = params[2]
            if spinData.action == "SPIN" then
                self:onSpinResult(spinData.extend)
            end
        end
    end,ViewEventType.NOTIFY_GET_SPINRESULT)

    self:setIsBuyTips(false)
end

-- message EchoWins {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional string activityId = 3; //活动id
--     optional string begin = 4;
--     optional string end = 5;
--     optional int64 coins = 6; // 奖励金币
--     optional bool active = 7;// 活动是否激活
--     optional string purchaseReward = 8; // 付费奖励最小付费
--     optional string coeBase = 9; // 未付费奖励系数
--     optional string coePurchase = 10; // 付费奖励系数
-- }
function EchoWinData:parseData(data)
    EchoWinData.super.parseData(self, data)

    if not self.m_isBuyTips then
        if self.p_isBuy ~= nil and self.p_isBuy ~= data.active then
            self:setIsBuyTips(data.active)
        end
    end

    self.p_activityId = data.activityId
    self.p_end = data["end"]
    self.p_coins = tonumber(data.coins) or 0
    self.p_isBuy = data.active
    self.purchaseReward = data.purchaseReward
    self.coeBase = data.coeBase
    self.coePurchase = data.coePurchase
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_SALE_GAMENODE, {name = ACTIVITY_REF.EchoWin})
end

function EchoWinData:onSpinResult( spinData )
    if spinData.echoWins then
        self.p_coins = spinData.echoWins.coins
    end
end

-- 是否已经购买
function EchoWinData:isBuy()
    return self.p_isBuy or false
end

function EchoWinData:getCoins()
    return self.p_coins or 0
end

function EchoWinData:getEndTimeString()
    return self.p_end or ""
end

-- 奖励升档基准线
function EchoWinData:getPurchaseLine()
    return self.purchaseReward or 0
end

-- 基础百分比
function EchoWinData:getBasePercent()
    return self.coeBase or 0
end

-- 升档百分比
function EchoWinData:getHeightPercent()
    return self.coePurchase or 0
end

-- 升档百分比
function EchoWinData:isBuyTips()
    return self.m_isBuyTips
end

function EchoWinData:setIsBuyTips( bl_isBuy )
    self.m_isBuyTips = bl_isBuy
end


return EchoWinData
