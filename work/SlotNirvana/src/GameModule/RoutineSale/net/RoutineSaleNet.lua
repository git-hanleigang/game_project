--[[
    新版常规促销
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local RoutineSaleNet = class("RoutineSaleNet", BaseNetModel)

function RoutineSaleNet:sendWheelReward()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROUTINE_SALE_WHEEL_REWARD, {result = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROUTINE_SALE_WHEEL_REWARD)
    end

    local actionType = ActionType.RoutineSaleWheelGetReward
    self:sendActionMessage(actionType,tbData,successCallback,failedCallback)
end

-- 付费
function RoutineSaleNet:buySale(_data, _index)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROUTINE_SALE_BUY_FAILED)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = _data.p_discount
    goodsInfo.goodsId = _data.p_key
    goodsInfo.goodsPrice = _data.p_price
    goodsInfo.totalCoins = _data.p_coins

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo, _index)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    
    gLobalSaleManager:purchaseActivityGoods(
        "",
        tostring(_index),
        BUY_TYPE.ROUTINE_SALE,
        _data.p_key,
        _data.p_price,
        _data.p_coins,
        _data.p_discount,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROUTINE_SALE_BUY_SUCCESS, {index = _index})
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROUTINE_SALE_BUY_FAILED, {errorInfo = _errorInfo, index = _index})
        end
    )
end

function RoutineSaleNet:sendIapLog(_goodsInfo, _index)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "RoutineSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = _goodsInfo.discount 
    goodsInfo.totalCoins = _goodsInfo.totalCoins 
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "RoutineSale" .. _index
    purchaseInfo.purchaseStatus = "RoutineSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return RoutineSaleNet
