--[[
    聚合挑战结束促销
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local HolidayEndSaleNet = class("HolidayEndSaleNet", BaseNetModel)

function HolidayEndSaleNet:getInstance()
    if self.instance == nil then
        self.instance = HolidayEndSaleNet.new()
    end
    return self.instance
end

function HolidayEndSaleNet:sendFreeReward()
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
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE, {type = "failed"})
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE, {type = "Free"})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE, {type = "failed"})
    end

    self:sendActionMessage(ActionType.ChristmasTourDepositCollect,tbData,successCallback,failedCallback)
end

-- 付费
function HolidayEndSaleNet:buyPayReward(_data)
    if not _data then
        release_print("clickBuyBtn buyFailed, HolidayEndSaleData is NIL")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE, {type = "failed"})
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = _data:getDiscounts()
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data)
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.HOLIDAY_END_SALE,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            self:buySuccess()
        end,
        function(_errorInfo)
            self:buyFaild(_errorInfo)
        end
    )
end

function HolidayEndSaleNet:buySuccess()
    gLobalViewManager:checkBuyTipList(function() 
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE, {type = "Pay"})
    end)
end

function HolidayEndSaleNet:buyFaild(_errorInfo)
    local view = self:checkPopPayConfirmLayer(_errorInfo)
    if not view then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE, {type = "failed"})
    end
end

-- 检查是否弹出 二次确认弹板
function HolidayEndSaleNet:checkPopPayConfirmLayer(_errorInfo)
    if not _errorInfo or not _errorInfo.bCancel then
        -- 非用户自主取消 返回
        return
    end

    local data = G_GetMgr(G_REF.HolidayEnd):getRunningData()
    if not data then
        return
    end

    local payCoins = data:getPayCoins()
    local priceV = data:getPrice()
    local params = {
        coins = payCoins,
        price = priceV,
        confirmCB = function()
            self:buyPayReward(data)
        end,
        cancelCB = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE, {type = "failed"})
        end
    }
    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    return view
end

function HolidayEndSaleNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "HolidayChallenge"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = _goodsInfo.discount
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "HolidayChallenge"
    purchaseInfo.purchaseStatus = "HolidayChallenge"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return HolidayEndSaleNet
