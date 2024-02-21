--[[
    大R高性价比礼包促销
]]

local SuperValueConfig = require("activities.Activity_SuperValue.config.SuperValueConfig")
local SuperValueMgr = class("SuperValueMgr", BaseActivityControl)

function SuperValueMgr:ctor()
    SuperValueMgr.super.ctor(self)
    
    

    self:setRefName(ACTIVITY_REF.SuperValue)
end

function SuperValueMgr:showMainLayer(_isSpin)
    local isOpen = self:checkActivityOpen(_isSpin)
    if not isOpen then
        return
    end

    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function SuperValueMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function SuperValueMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function SuperValueMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function SuperValueMgr:checkActivityOpen(_isSpin)
    local flag = false

    local data = self:getRunningData()
    if data then
        local roundExpireAt = data:getRoundExpireAt()
        local remainingTimes = data:getRemainingTimes()
        if roundExpireAt > globalData.userRunData.p_serverTime and remainingTimes > 0 then
            flag = true
        end

        if _isSpin then 
            local saveRoundExpireAt = gLobalDataManager:getNumberByField("SuperValue", 0)
            if roundExpireAt > saveRoundExpireAt then
                flag = true
                gLobalDataManager:setNumberByField("SuperValue", roundExpireAt)
                gLobalActivityManager:showActivityEntryNode()
            else
                flag = false
            end
        end
    end
    
    return flag
end

function SuperValueMgr:sendBuySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(SuperValueConfig.notify_buy_sale)
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
        "",
        SuperValueConfig.buy_type,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function(_result)
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(SuperValueConfig.notify_buy_sale, {success = true})
            end)
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(SuperValueConfig.notify_buy_sale, {success = false, errorInfo = _errorInfo})
        end
    )
end

function SuperValueMgr:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "SuperValueSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "SuperValueSale"
    purchaseInfo.purchaseStatus = "SuperValueSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return SuperValueMgr
