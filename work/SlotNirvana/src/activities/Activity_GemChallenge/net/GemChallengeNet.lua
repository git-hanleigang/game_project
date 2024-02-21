--[[
    第二货币消耗挑战
]]

local GemChallengeConfig = require("activities.Activity_GemChallenge.config.GemChallengeConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local GemChallengeNet = class("GemChallengeNet", BaseNetModel)

function GemChallengeNet:getInstance()
    if self.instance == nil then
        self.instance = GemChallengeNet.new()
    end
    return self.instance
end

function GemChallengeNet:sendCollect(_data)
    local tbData = {
        data = {
            params = {
                index = _data.p_index
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(GemChallengeConfig.notify_collect, {success = true, data = _data})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(GemChallengeConfig.notify_collect, {success = false, _data = _data})
    end

    self:sendActionMessage(ActionType.GemChallengeCollect,tbData,successCallback,failedCallback)
end

-- 付费
function GemChallengeNet:buyUnlock(_data)
    if not _data then
        gLobalNoticManager:postNotification(GemChallengeConfig.notify_pay_unlock)
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
        GemChallengeConfig.buy_type,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(GemChallengeConfig.notify_pay_unlock, {success = true})
            end)
        end,
        function()
            gLobalNoticManager:postNotification(GemChallengeConfig.notify_pay_unlock)
        end
    )
end

function GemChallengeNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "GemChallenge"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "GemChallenge"
    purchaseInfo.purchaseStatus = "GemChallenge"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return GemChallengeNet
