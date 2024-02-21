--[[
    
]]

local VipPointsBoostNet = require("activities.Activity_VipPoints_Boost.net.VipPointsBoostNet")
local VipPointsBoostMgr = class("VipPointsBoostMgr", BaseActivityControl)

function VipPointsBoostMgr:ctor()
    VipPointsBoostMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.VipPointsBoost)

    self.m_netModel = VipPointsBoostNet:getInstance()   -- 网络模块
end

function VipPointsBoostMgr:showMainLayer(_isFirst)
    if not self:isCanShowLayer() then
        return nil
    end

    local mainLayer = nil
    if gLobalViewManager:getViewByExtendData("Activity_VipPoints_Boost") == nil then
        mainLayer = util_createView("Activity_VipPoints_Boost.Activity.Activity_VipPoints_Boost", _isFirst)
        self:showLayer(mainLayer, ViewZorder.ZORDER_UI)
    end

    return mainLayer
end

function VipPointsBoostMgr:showBoxLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local boxLayer = nil
    if gLobalViewManager:getViewByExtendData("Activity_VipPoints_BoostBox") == nil then
        boxLayer = util_createView("Activity_VipPoints_Boost.Activity.Activity_VipPoints_BoostBox")
        self:showLayer(boxLayer, ViewZorder.ZORDER_UI)
    end

    return boxLayer
end

function VipPointsBoostMgr:shwoShopLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local shopLayer = nil
    if gLobalViewManager:getViewByExtendData("Activity_VipPoints_BoostShop") == nil then
        shopLayer = util_createView("Activity_VipPoints_Boost.Activity.Activity_VipPoints_BoostShop")
        self:showLayer(shopLayer, ViewZorder.ZORDER_UI)
    end

    return shopLayer
end

-- 付费
function VipPointsBoostMgr:buySale(_index, _data)
    if not _data then
        release_print("clickBuyBtn buyFailed, vipPiontsBoost sale data is NIL")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_VIP_POINTS_BOOST_SHOP_BUY)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data.p_keyId
    goodsInfo.goodsPrice = _data.p_price

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo, _index)

    gLobalViewManager:addLoadingAnima(false, 1)

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.VIP_POINTS_BOOST,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function()
            gLobalViewManager:removeLoadingAnima()
            gLobalViewManager:checkBuyTipList(function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_VIP_POINTS_BOOST_SHOP_BUY, {index = _index, success = true})
            end)        
        end,
        function(_errorInfo)
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_VIP_POINTS_BOOST_SHOP_BUY, {errorInfo = _errorInfo, index = _index})
        end
    )
end

function VipPointsBoostMgr:sendIapLog(_goodsInfo, _index)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "vipPiontsBoost"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "vipSale" .. _index
    purchaseInfo.purchaseStatus = "vipSale" .. _index
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

function VipPointsBoostMgr:sendFirstStatus()
    self.m_netModel:sendFirstStatus()
end

function VipPointsBoostMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function VipPointsBoostMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function VipPointsBoostMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return VipPointsBoostMgr
