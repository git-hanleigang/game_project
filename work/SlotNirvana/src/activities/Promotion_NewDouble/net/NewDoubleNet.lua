--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local NewDoubleNet = class("NewDoubleNet", BaseNetModel)

function NewDoubleNet:giveUp()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NEWDOUBLE_GIVE_UP, false)
            return
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NEWDOUBLE_GIVE_UP, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NEWDOUBLE_GIVE_UP, false)
    end

    self:sendActionMessage(ActionType.NewDoubleSaleGiveUp,tbData,successCallback,failedCallback)
end

function NewDoubleNet:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NEWDOUBLE_BUY_FAILED)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.NEW_DOUBLE_SALE,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            self:buySuccess()
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NEWDOUBLE_BUY_FAILED)
        end
    )
end

function NewDoubleNet:buySuccess()
    gLobalViewManager:checkBuyTipList(function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NEWDOUBLE_BUY_SUCCESS)
    end)
end

function NewDoubleNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "Promotion_NewDouble"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "Promotion_NewDouble"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return NewDoubleNet