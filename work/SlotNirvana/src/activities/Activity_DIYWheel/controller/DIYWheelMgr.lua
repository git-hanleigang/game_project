--[[
    三指针转盘促销
]]

local DIYWheelConfig = require("activities.Activity_DIYWheel.config.DIYWheelConfig")
local DIYWheelNet = require("activities.Activity_DIYWheel.net.DIYWheelNet")
local DIYWheelMgr = class("DIYWheelMgr", BaseActivityControl)

function DIYWheelMgr:ctor()
    DIYWheelMgr.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.DIYWheel)

    self.m_netModel = DIYWheelNet:getInstance()
end

function DIYWheelMgr:showMainLayer()
    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function DIYWheelMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function DIYWheelMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function DIYWheelMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function DIYWheelMgr:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(DIYWheelConfig.notify_buy_sale)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data.p_keyId
    goodsInfo.goodsPrice = _data.p_price

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalSaleManager:purchaseGoods(
        DIYWheelConfig.buy_type,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function(_result)
            local result = nil
            if _result then
                result = util_cjsonDecode(_result)
            end

            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(DIYWheelConfig.notify_buy_sale, {result = result})
            end)
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(DIYWheelConfig.notify_buy_sale)
        end
    )
end

function DIYWheelMgr:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "DIYWheelSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "DIYWheelSale"
    purchaseInfo.purchaseStatus = "DIYWheelSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return DIYWheelMgr
