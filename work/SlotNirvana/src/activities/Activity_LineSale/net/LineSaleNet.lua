--[[
    bingo连线
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local LineSaleNet = class("LineSaleNet", BaseNetModel)

function LineSaleNet:getInstance()
    if self.instance == nil then
        self.instance = LineSaleNet.new()
    end
    return self.instance
end

function LineSaleNet:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_LINE_SALE_BUY)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.BINGO_LINE_SALE,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function(_result)
            local result = nil
            if _result then
                result = cjson.decode(_result)
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_LINE_SALE_BUY, {success = true, result = result})
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_LINE_SALE_BUY, {errorInfo = _errorInfo})
        end
    )
end

function LineSaleNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "LineSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "LineSale"
    purchaseInfo.purchaseStatus = "LineSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return LineSaleNet
