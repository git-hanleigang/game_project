--[[
    网络请求
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local GemPiggyNet = class("GemPiggyNet", BaseNetModel)

-- 集卡小猪付费购买
function GemPiggyNet:requestBuyGemPiggy(successCallFunc, failedCallFunc)
    local actData = G_GetMgr(ACTIVITY_REF.GemPiggy):getRunningData()
    if not actData then
        return
    end

    local coins = actData:getCurrentPoints()
    local priceData = actData:getPriceData()


    local goodsInfo = {}
    goodsInfo.goodsTheme = "GemPiggy"
    goodsInfo.discount = 0
    goodsInfo.goodsId = priceData:getKeyId()
    goodsInfo.goodsPrice = priceData:getPrice()
    goodsInfo.totalCoins = coins or 0
    self:sendIapLog(goodsInfo)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function(_errorInfo)
        failedCallFunc(_errorInfo)
    end

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.PIG_GEM,
        goodsInfo.goodsId,
        goodsInfo.goodsPrice,
        goodsInfo.totalCoins,
        0,
        buySuccess,
        buyFailed
    )
end

function GemPiggyNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "GemPiggyBuy"
    purchaseInfo.purchaseStatus = "GemPiggyBuy"
    gLobalSendDataManager:getLogIap():openIapLogInfo(_goodsInfo, purchaseInfo)
end

return GemPiggyNet
