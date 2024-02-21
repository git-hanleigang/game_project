--[[
    限时集卡多倍奖励
]]

local AlbumMoreAwardConfig = require("activities.Activity_AlbumMoreAward.config.AlbumMoreAwardConfig")
local AlbumMoreAwardMgr = class("AlbumMoreAwardMgr", BaseActivityControl)

function AlbumMoreAwardMgr:ctor()
    AlbumMoreAwardMgr.super.ctor(self)
    
    self.m_showLogo = false

    self:setRefName(ACTIVITY_REF.AlbumMoreAward)
end

function AlbumMoreAwardMgr:showMainLayer()
    local isOpen = self:checkActivityOpen()
    if not isOpen then
        return
    end

    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function AlbumMoreAwardMgr:showSaleLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local isOpen = self:checkActivityOpen()
    if not isOpen then
        return
    end

    local view = util_createView("Activity_AlbumMoreAward.Activity.Activity_AlbumMoreAwardSale")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function AlbumMoreAwardMgr:showLogoLayer()
    local isOpen = self:checkActivityOpen()
    if not isOpen then
        return
    end

    if not self:isCanShowLayer() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ALBUM_MORE_AWARD_LOGO_HIDE)
        return
    end

    if self.m_showLogo then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ALBUM_MORE_AWARD_LOGO_HIDE)
        return
    end

    local view = util_createView("Activity_AlbumMoreAward.Activity.Activity_AlbumMoreAwardLogo")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    self.m_showLogo = true
    return view
end

function AlbumMoreAwardMgr:getTimeNode()
    if not self:checkActivityOpen() then
        return
    end

    if not self:isCanShowLayer() then
        return
    end

    local node = util_createView("Activity_AlbumMoreAward.Activity.Activity_AlbumMoreAwardTime")
    return node
end

function AlbumMoreAwardMgr:getSaleNode()
    if not self:checkActivityOpen() then
        return
    end

    if not self:isCanShowLayer() then
        return
    end

    local node = util_createView("Activity_AlbumMoreAward.Activity.Activity_AlbumMoreAwardSaleLogo")
    return node
end

function AlbumMoreAwardMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function AlbumMoreAwardMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function AlbumMoreAwardMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function AlbumMoreAwardMgr:checkActivityOpen()
    local flag = false

    if not self:isDownloadRes() then
        return flag
    end

    local data = self:getRunningData()
    if data then
        local unlock = data:isUnlock()
        local saleExpireAt = data:getSaleExpireAt()
        local curTime = util_getCurrnetTime()
        if unlock and saleExpireAt > curTime + 3 then
            flag = true
        end
    end
    
    return flag
end

function AlbumMoreAwardMgr:getMultiply()
    local multiply = 0
    local data = self:getRunningData()
    if self:checkActivityOpen() then
        multiply = data:getMultiply()
    end
    return multiply
end

function AlbumMoreAwardMgr:buySale(_data, _index)
    if not _data then
        gLobalNoticManager:postNotification(AlbumMoreAwardConfig.notify_buy_sale)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data.p_keyId
    goodsInfo.goodsPrice = _data.p_price
    goodsInfo.totalCoins = _data.p_coins

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, _data.p_items)
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalSaleManager:purchaseActivityGoods(
        "",
        tostring(_data.p_index),
        BUY_TYPE.ALBUM_MORE_AWARD,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function(_result)
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(AlbumMoreAwardConfig.notify_buy_sale, {success = true, index = _index})
            end)
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(AlbumMoreAwardConfig.notify_buy_sale, {success = false, index = _index, errorInfo = _errorInfo})
        end
    )
end

function AlbumMoreAwardMgr:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "AlbumMoreAwardSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "AlbumMoreAwardSale"
    purchaseInfo.purchaseStatus = "AlbumMoreAwardSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return AlbumMoreAwardMgr
