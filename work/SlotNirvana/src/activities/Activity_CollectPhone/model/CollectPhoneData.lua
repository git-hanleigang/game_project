--[[
    绑定手机号相关数据
    author:{author}
    time:2022-11-17 10:03:57
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ShopItem = require("data.baseDatas.ShopItem")
local CollectPhoneData = class("CollectPhoneData", BaseActivityData)

function CollectPhoneData:ctor()
    self.m_bindStatus = false
    self.m_rewardInfos = {}
    self.m_coins = toLongNumber(0)
    self.m_lastTimes = 0
    self:setNovice(false)
end

--[[
    message CollectPhone {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional bool bind = 4; //是否绑定
        optional int32 verifyTimes = 5;//剩余验证次数
        optional string coins = 6;//金币值
        repeated ShopItem items = 7; // 道具
    }
]]
function CollectPhoneData:parseData(data)
    CollectPhoneData.super.parseData(self, data)
    self.m_bindStatus = data.bind or false
    self.m_lastTimes = data.verifyTimes or 0
    if data.coins and data.coins ~= "" then
        self.m_coins:setNum(data.coins)
    end

    self.m_rewardInfos = {}
    for i = 1, #(data.items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data.items[i])
        table.insert(self.m_rewardInfos, shopItem)
    end
end

function CollectPhoneData:getLastTimes()
    return self.m_lastTimes
end

function CollectPhoneData:getCoins()
    return self.m_coins
end

function CollectPhoneData:isBound()
    return self.m_bindStatus
end

function CollectPhoneData:getBindRewardItems()
    return self.m_rewardInfos
end

function CollectPhoneData:isRunning()
    if self:isCompleted() then
        return false
    end
    return CollectPhoneData.super.isRunning(self)
end

-- 检查完成条件
function CollectPhoneData:checkCompleteCondition()
    return self:isBound()
end

return CollectPhoneData
