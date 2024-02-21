--[[
    返回持金极大值促销
]]

local TimeBackConfig = require("activities.Activity_TimeBack.config.TimeBackConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local TimeBackNet = class("TimeBackNet", BaseNetModel)

function TimeBackNet:getInstance()
    if self.instance == nil then
        self.instance = TimeBackNet.new()
    end
    return self.instance
end

function TimeBackNet:ActivityClose()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(TimeBackConfig.notify_give_up)
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(TimeBackConfig.notify_give_up)
    end

    self:sendActionMessage(ActionType.TimeBackClose, tbData, successCallFun, failedCallFun)
end

-- 付费
function TimeBackNet:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(TimeBackConfig.notify_buy_sale)
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

    gLobalViewManager:addLoadingAnima(false, 1)

    gLobalSaleManager:purchaseGoods(
        TimeBackConfig.buy_type,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function(_result)
            gLobalViewManager:removeLoadingAnima()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(TimeBackConfig.notify_buy_sale, {success = true})
            end)
        end,
        function(_errorInfo)
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(TimeBackConfig.notify_buy_sale, {errorInfo = _errorInfo})
        end
    )
end

function TimeBackNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "TimeBack"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "TimeBack"
    purchaseInfo.purchaseStatus = "TimeBack"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return TimeBackNet
