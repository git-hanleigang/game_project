--[[
    author:{author}
    time:2020-07-21 10:52:08
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local CrazyCartData = class("CrazyCartData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

function CrazyCartData:ctor()
    CrazyCartData.super.ctor(self)
    self.m_coins = 0
end

function CrazyCartData:parseData(data)
    CrazyCartData.super.parseData(self, data)
    self.p_expireAt = data.expireAt  --过期时间戳
    self.p_expire = data.expire  --活动剩余秒
    self.p_shareReward = data.shareReward --分享奖励
    self.p_cartReward = data.cartReward --购物车累计奖励
    self.p_collectRewardTime = data.collectRewardTime --领奖时间戳
    self.p_lastDay = data.lastDay --是否是黑五当天
    if self.p_shareReward then
        self:parseShopItems(self.p_shareReward)
    end
    if self.p_cartReward then
        self:parseCartItems(self.p_cartReward)
    end
    if data:HasField("shareTimes") then
        self.p_shareTimes = data.shareTimes - 1
    end
    if data:HasField("shared") then
        self.p_shared = data.shared
    end
    gLobalNoticManager:postNotification( ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH,{ name = ACTIVITY_REF.CrazyCart } )
end

function CrazyCartData:isRunning()
    if CrazyCartData.super.isRunning(self) then
        return true
    end
    return false
end
--true是黑五
function CrazyCartData:getLastDay()
    return self.p_lastDay or false
end

function CrazyCartData:getCollectTime()
    return self.p_collectRewardTime or 0
end
--分享奖励
function CrazyCartData:parseShopItems(_data)
    self.p_shareList = {}
    if _data.coins and tonumber(_data.coins) > 0 then
        local item_data = gLobalItemManager:createLocalItemData("Coins", _data.coins,{p_mark = {ITEM_MARK_TYPE.NONE}})
        item_data:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
        table.insert(self.p_shareList,item_data)
    end
    if _data.itemList and #_data.itemList > 0 then
        for i,v in ipairs(_data.itemList) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            if tempData.p_type == "Package" then
                tempData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
            end
            table.insert(self.p_shareList, tempData)
        end
    end
end
--累计奖励
function CrazyCartData:parseCartItems(_data)
    self.p_cartItems = {}
    if _data.coins and tonumber(_data.coins) > 0 then
        self.m_coins = _data.coins
        local item_data = gLobalItemManager:createLocalItemData("Coins", _data.coins)
        table.insert(self.p_cartItems,item_data)
    end
    if _data.itemList and #_data.itemList > 0 then
        for i,v in ipairs(_data.itemList) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(self.p_cartItems, tempData)
        end
    end
end

function CrazyCartData:getCoins()
    return self.m_coins or 0
end

function CrazyCartData:getItems()
    return self.p_cartItems or {}
end

function CrazyCartData:getShareTimes()
    return self.p_shareTimes or 1
end

function CrazyCartData:getShared()
    return self.p_shared or false
end

function CrazyCartData:getShopItem()
    return self.p_shareList or {}
end

function CrazyCartData:getExDay()
    local day = (self.p_collectRewardTime-globalData.userRunData.p_serverTime)/(60*60*24*1000)
    return math.floor(day)
end

function CrazyCartData:getExConnect()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self.p_expireAt / 1000 - curTime
    return math.floor(leftTime)
end

return CrazyCartData
