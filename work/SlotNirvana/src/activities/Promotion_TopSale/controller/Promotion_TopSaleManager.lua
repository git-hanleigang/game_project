local Promotion_TopSaleManager = class("Promotion_TopSaleManager", BaseActivityControl)
local Promotion_TopSaleNet = require("activities.Promotion_TopSale.net.Promotion_TopSaleNet")

function Promotion_TopSaleManager:ctor()
    Promotion_TopSaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Promotion_TopSale)

    self._net = Promotion_TopSaleNet:getInstance()
end

function Promotion_TopSaleManager:getNet()
    return self._net
end

function Promotion_TopSaleManager:isWillShowTopSale(callback)
    if not self:isCanShowLayer() then
        return false
    end
    if gLobalViewManager:getViewByName("Promotion_TopSale") ~= nil then
        return false
    end
    local activityData = self:getRunningData()
    if not activityData or activityData:isDirty() then
        return false
    end
    self.m_showcallback = callback
    return true
end

function Promotion_TopSaleManager:showTopSaleView(reconnect,data)
    if not self:isCanShowLayer() then
        return nil
    end
    self.m_dataList = data
    self.m_reconnect = reconnect
    if gLobalViewManager:getViewByName("Promotion_TopSale") ~= nil then
        return nil
    end
    local view = util_createView("Activity/Promotion_TopSale")
    view:setName("Promotion_TopSale")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function Promotion_TopSaleManager:afterTopSale()
    if self.m_dataList then
        if not self.m_reconnect then
            gLobalViewManager:checkBuyTipList(
                function()
                    G_GetMgr(G_REF.Shop):buySuccessDropCard(self.m_dataList)
                end
            )
        else
            G_GetMgr(G_REF.Shop):buySuccessDropCard(self.m_dataList)
        end
    end
end

function Promotion_TopSaleManager:setBuyStatus(status)
    self._buyStatus = status
end

function Promotion_TopSaleManager:getBuyStatus()
    return self._buyStatus
end

function Promotion_TopSaleManager:showPayQuitConfirmation()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("Promotion_TopSaleConfirmationLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity/Promotion_TopSaleConfirmationLayer")
    view:setName("Promotion_TopSaleConfirmationLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function Promotion_TopSaleManager:afterCloseBuyView()
    self:getNet():afterCloseBuyView()
    if self.m_showcallback then
        self.m_showcallback()
    else
        self:afterTopSale()
    end
end

function Promotion_TopSaleManager:rememberBeforeData(propsBagList,lotteryTickets)
    self.propsBagList = clone(propsBagList) 
    self.m_lotteryTickets = lotteryTickets
end

function Promotion_TopSaleManager:getRememberBeforeData()
    local bagList = self.propsBagList or {}
    self.propsBagList = nil
    local lotteryTickets = self.m_lotteryTickets or 0
    return bagList,lotteryTickets
end

function Promotion_TopSaleManager:isBuying()
    return not not self._isBuying
end

function Promotion_TopSaleManager:buySale()
    if self._isBuying then
        return
    end
    local _data = self:getRunningData()
    if not _data or _data:isDirty() then
        return
    end
    self._isBuying = true
    
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- gLobalViewManager:addLoadingAnima()
    gLobalSaleManager:setBuyVippoint(_data:getVipPoint())

    local rate = 0
    local buyType = BUY_TYPE.TopSale
    gLobalSaleManager:purchaseGoods(
        buyType,
        _data:getKey(),
        _data:getPrice(),
        _data:getCoins(),
        rate,
        function()
            -- gLobalViewManager:removeLoadingAnima()
            self:buySuccess(_data)
            local activityData = G_GetMgr(ACTIVITY_REF.Promotion_TopSale):getRunningData()
            if activityData then
                activityData:changeToDirty()
            end  
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYSALE_TOPSALE,{success = true})
            self._isBuying = false
        end,
        function()
            -- gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYSALE_TOPSALE,{success = false})
            self._isBuying = false
        end
    )
end

function Promotion_TopSaleManager:buySuccess(data)
    local levelUpNum = gLobalSaleManager:getLevelUpNum()
    local buyType = BUY_TYPE.TopSale

    local view = util_createView("GameModule.Shop.BuyTip")
    view:initBuyTip(buyType, data, tonumber(data:getCoins()), levelUpNum)
    view:setIsForTopSale(true)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

return Promotion_TopSaleManager