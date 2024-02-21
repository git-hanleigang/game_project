--[[
    大活动PASS
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local FunctionSalePassNet = class("FunctionSalePassNet", BaseNetModel)


function FunctionSalePassNet:sendPassCollect(_data, _type, _selectIndexList)
    local tbData = {
        data = {
        }
    }

    local params = {
        level = _data.p_level,
        type = _type
    }
    if #_selectIndexList > 0 then
        params.selectIndexList = _selectIndexList
    end
    tbData.data.params = params

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FUNCTION_SALE_PASS_COLLECT, {success = true, data = _data, type = _type})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FUNCTION_SALE_PASS_COLLECT, {success = false, _data = _data, type = _type})
    end

    self:sendActionMessage(ActionType.FunctionSalePassCollect,tbData,successCallback,failedCallback)
end

-- 付费
function FunctionSalePassNet:buyUnlock(_data)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FUNCTION_SALE_PASS_UNLOCK)
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
        BUY_TYPE.FUNCTION_SALE_PASS,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FUNCTION_SALE_PASS_UNLOCK, {success = true})
            end)
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FUNCTION_SALE_PASS_UNLOCK)
        end
    )
end

function FunctionSalePassNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "FunctionSalePass"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "FunctionSalePass"
    purchaseInfo.purchaseStatus = "FunctionSalePass"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return FunctionSalePassNet
