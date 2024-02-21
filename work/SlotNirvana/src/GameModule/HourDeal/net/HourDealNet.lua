--[[
    限时抽奖
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local HourDealNet = class("HourDealNet", BaseNetModel)

function HourDealNet:sendGetReward(_index)
    local tbData = {
        data = {
            params = {
                index = _index
            }
        }
    }
    
    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_GET_REWARD)
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_GET_REWARD, {result = _result, index = _index})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_GET_REWARD)
    end
    self:sendActionMessage(ActionType.HourDealDraw, tbData, successCallFun, failedCallFun)
end

-- 付费
function HourDealNet:buySale(_data, _type)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_SALE)
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
        BUY_TYPE.HOUR_DEAL_SALE,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_SALE, {success = true})
            end)
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_SALE, {errorInfo = _errorInfo})
        end
    )
end

function HourDealNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "HourDeal"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "HourDeal"
    purchaseInfo.purchaseStatus = "HourDeal"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return HourDealNet
