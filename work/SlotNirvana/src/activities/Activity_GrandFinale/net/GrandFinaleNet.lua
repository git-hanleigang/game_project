--[[
    赛季末返新卡
]]

local GrandFinaleConfig = require("activities.Activity_GrandFinale.config.GrandFinaleConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local GrandFinaleNet = class("GrandFinaleNet", BaseNetModel)

function GrandFinaleNet:getInstance()
    if self.instance == nil then
        self.instance = GrandFinaleNet.new()
    end
    return self.instance
end

function GrandFinaleNet:sendCollect()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(GrandFinaleConfig.notify_collect, {result = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(GrandFinaleConfig.notify_collect)
    end

    self:sendActionMessage(ActionType.GrandFinaleCollect,tbData,successCallback,failedCallback)
end

function GrandFinaleNet:sendRefreshData()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima()

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(GrandFinaleConfig.notify_refresh_data, {success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(GrandFinaleConfig.notify_refresh_data, {success = false})
    end

    self:sendActionMessage(ActionType.GrandFinaleRefresh,tbData,successCallback,failedCallback)
end

-- 付费
function GrandFinaleNet:buyUnlock(_data)
    if not _data then
        gLobalNoticManager:postNotification(GrandFinaleConfig.notify_pay_unlock)
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
        GrandFinaleConfig.buy_type,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(GrandFinaleConfig.notify_pay_unlock, {success = true})
            end)
        end,
        function()
            gLobalNoticManager:postNotification(GrandFinaleConfig.notify_pay_unlock)
        end
    )
end

function GrandFinaleNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "GrandFinaleSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "GrandFinaleSale"
    purchaseInfo.purchaseStatus = "GrandFinaleSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return GrandFinaleNet
