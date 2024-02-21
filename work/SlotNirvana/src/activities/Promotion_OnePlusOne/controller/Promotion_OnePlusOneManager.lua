local Promotion_OnePlusOneManager = class("Promotion_OnePlusOneManager", BaseActivityControl)
local Promotion_OnePlusOneNet = require("activities.Promotion_OnePlusOne.net.Promotion_OnePlusOneNet")

function Promotion_OnePlusOneManager:ctor()
    Promotion_OnePlusOneManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Promotion_OnePlusOne)

    self._net = Promotion_OnePlusOneNet:getInstance()
end

function Promotion_OnePlusOneManager:getNet()
    return self._net
end

function Promotion_OnePlusOneManager:sendGetRewards(...)
    self._net:sendGetRewards(...)
end

function Promotion_OnePlusOneManager:setBuyStatus(status)
    self._buyStatus = status
end

function Promotion_OnePlusOneManager:getBuyStatus()
    return self._buyStatus
end

function Promotion_OnePlusOneManager:createRewardUI(items,callback,coins)
    local call = function()
        if CardSysManager:needDropCards("1+1") then
            CardSysManager:doDropCards("1+1",function()
                if callback then
                    callback()
                end
            end)
        else
            if callback then
                callback()
            end
        end
    end
    local view = gLobalItemManager:createRewardLayer(items, call, coins or 0, true)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function Promotion_OnePlusOneManager:buySuccess(data)
    local levelUpNum = gLobalSaleManager:getLevelUpNum()
    local buyType = BUY_TYPE.OnePlusOneSale

    local view = util_createView("GameModule.Shop.BuyTip")
    view:initBuyTip(buyType, data:makeDataForBuyTip(), tonumber(data._paidReward.coins), levelUpNum)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

return Promotion_OnePlusOneManager