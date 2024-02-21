--[[
    限时促销
]]

local LimitedOfferNet = require("activities.Activity_LimitedOffer.net.LimitedOfferNet")
local LimitedOfferMgr = class("LimitedOfferMgr", BaseActivityControl)

function LimitedOfferMgr:ctor()
    LimitedOfferMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.LimitedOffer)
    self.m_net = LimitedOfferNet:getInstance()
end

function LimitedOfferMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function LimitedOfferMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function LimitedOfferMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function LimitedOfferMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

-- 免费
function LimitedOfferMgr:sendFreeGift(_index)
    local gameData = self:getData()
    local bNovice = false
    if gameData and gameData:isNovice() then
        bNovice = true
    end

    self.m_net:sendFreeGift(_index, bNovice)
end

-- 付费
function LimitedOfferMgr:buySale(_data, _index)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_LIMITEDOFFER_BUY_SALE)
        return
    end

    local gameData = self:getData()
    local bNovice = false
    if gameData and gameData:isNovice() then
        bNovice = true
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data.p_keyId
    goodsInfo.goodsPrice = _data.p_price

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo, bNovice)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    local gameData = self:getData()
    local buyType = BUY_TYPE.LimitedGift
    if bNovice then
        buyType = BUY_TYPE.NOVICE_LimitedGift
    end
    gLobalSaleManager:purchaseActivityGoods(
        "",
        tostring(_index),
        buyType,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_LIMITEDOFFER_BUY_SALE, {index = _index, success = true})
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_LIMITEDOFFER_BUY_SALE, {errorInfo = _errorInfo, index = _index})
        end
    )
end

function LimitedOfferMgr:sendIapLog(_goodsInfo, _bNovice)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "LimitGifeSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "LimitGifeSale"
    purchaseInfo.purchaseStatus = "LimitGifeSale"
    if _bNovice then
        purchaseInfo.purchaseName = "novice_LimitGifeSale"
        purchaseInfo.purchaseStatus = "novice_LimitGifeSale"
    end
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return LimitedOfferMgr
