--[[
    网络请求
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local ChipPiggyNet = class("ChipPiggyNet", BaseNetModel)

-- 集卡小猪付费购买
function ChipPiggyNet:requestBuyChipPiggy(successCallFunc, failedCallFunc)
    local actData = G_GetMgr(ACTIVITY_REF.ChipPiggy):getRunningData()
    if not actData then
        return
    end

    local curPhaseReward = actData:getCurPhaseReward()

    local goodsInfo = {}
    goodsInfo.goodsTheme = "ChipPiggy"
    goodsInfo.discount = 0
    goodsInfo.goodsId = actData:getKeyId()
    goodsInfo.goodsPrice = actData:getPrice()
    goodsInfo.totalCoins = curPhaseReward.coins or 0
    self:sendIapLog(goodsInfo)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function(_errorInfo)
        failedCallFunc(_errorInfo)
    end

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.PIG_CHIP,
        goodsInfo.goodsId,
        goodsInfo.goodsPrice,
        goodsInfo.totalCoins,
        0,
        buySuccess,
        buyFailed
    )
end

function ChipPiggyNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "ChipPiggyBuy"
    purchaseInfo.purchaseStatus = "ChipPiggyBuy"
    gLobalSendDataManager:getLogIap():openIapLogInfo(_goodsInfo, purchaseInfo)
end

return ChipPiggyNet
