--[[
    绑定手机号相关数据
    author:{author}
    time:2022-11-17 10:03:57
]]
local ShopItem = require("data.baseDatas.ShopItem")
local BindPhoneData = class("BindPhoneData")

function BindPhoneData:ctor()
    self.m_isOpen = false

    self.m_bindStatus = false
    self.m_isCollected = false
    self.m_rewardInfos = {}
    self.m_coins = 0
    self.m_lastTimes = 0
end

function BindPhoneData:parseData(data)
    if not data then
        return
    end

    self.m_isOpen = true

    self.m_bindStatus = data.bind or false
    self.m_isCollected = data.collected or false
    self.m_coins = data.coins or 0
    self.m_lastTimes = data.verifyTimes or 0

    self.m_rewardInfos = {}
    for i = 1, #(data.items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data.items[i])
        table.insert(self.m_rewardInfos, shopItem)
    end

    self.m_expireAt = tonumber(gLobalDataManager:getStringByField("BindPhoneExpireAt", "0")) -- 秒为单位
    if self.m_expireAt == 0 then
        local curTime = util_getCurrnetTime()
        local expireAt = curTime + 7 * 24 * 60 * 60
        gLobalDataManager:setStringByField("BindPhoneExpireAt", tostring(expireAt))
        self.m_expireAt = expireAt
    end
end

function BindPhoneData:isOpen()
    return self.m_isOpen
end

function BindPhoneData:getLastTimes()
    return self.m_lastTimes
end

function BindPhoneData:getCoins()
    return tonumber(self.m_coins)
end

function BindPhoneData:isBound()
    return self.m_bindStatus
end

function BindPhoneData:isCollected()
    return self.m_isCollected
end

function BindPhoneData:getBindRewardItems()
    return self.m_rewardInfos
end

function BindPhoneData:getExpireAt()
    return self.m_expireAt or 0
end

return BindPhoneData
