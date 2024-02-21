--[[
    无限促销
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local FunctionSaleInfiniteNet = class("FunctionSaleInfiniteNet", BaseNetModel)

function FunctionSaleInfiniteNet:sendCollect()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INFINITE_SALE_COLLECT, {success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INFINITE_SALE_COLLECT, {success = false})
    end

    self:sendActionMessage(ActionType.FunctionSaleInfiniteCollect,tbData,successCallback,failedCallback)
end

-- 付费
function FunctionSaleInfiniteNet:buySale(_data, _pickIdx)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INFINITE_SALE_BUY)
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
    gLobalSaleManager:purchaseActivityGoods(
        "",
        tostring(_pickIdx),
        BUY_TYPE.FUNCTION_SALE_INFINITE,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INFINITE_SALE_BUY, {success = true})
            end)
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INFINITE_SALE_BUY)
        end
    )
end

function FunctionSaleInfiniteNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "FunctionSaleInfinite"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "FunctionSaleInfinite"
    purchaseInfo.purchaseStatus = "FunctionSaleInfinite"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return FunctionSaleInfiniteNet
