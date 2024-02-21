--[[
    高倍场体验卡促销
]]

local HighClubSaleConfig = require("activities.Activity_HighClubSale.config.HighClubSaleConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local HighClubSaleNet = class("HighClubSaleNet", BaseNetModel)

function HighClubSaleNet:getInstance()
    if self.instance == nil then
        self.instance = HighClubSaleNet.new()
    end
    return self.instance
end

-- 付费
function HighClubSaleNet:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(HighClubSaleConfig.notify_buy_sale)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getkeyId()
    goodsInfo.goodsPrice = _data:getPrice()

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        HighClubSaleConfig.buyType,
        _data:getkeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalNoticManager:postNotification(HighClubSaleConfig.notify_buy_sale, {success = true})
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(HighClubSaleConfig.notify_buy_sale, {errorInfo = _errorInfo})
        end
    )
end

function HighClubSaleNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "HighClubSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "HighClubSale"
    purchaseInfo.purchaseStatus = "HighClubSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return HighClubSaleNet
