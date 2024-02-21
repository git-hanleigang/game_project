--[[
    活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local DiyFeaturePromotionNet = class("DiyFeaturePromotionNet", BaseNetModel)

function DiyFeaturePromotionNet:getInstance()
    if self.instance == nil then
        self.instance = DiyFeaturePromotionNet.new()
    end
    return self.instance
end

-- diyfeature付费购买
function DiyFeaturePromotionNet:requestBuyDiyFeature(params, successCallFunc, failedCallFunc)
    local actData = G_GetMgr(ACTIVITY_REF.DiyFeatureOverSale):getRunningData()
    if not actData then
        return
    end
    -- {{普通低档, 普通高档}, {豪华低档, 豪华高档}}
    local DiyFeatureType = {{"NORMAL", "NORMAL2"}, {"HIGH", "HIGH2"}}
    -- 1-普通版， 2-豪华版
    local type = params.type
    -- 1-低档，2-高档
    local position = params.position

    local paInfo = actData:getSaleDataByType(type, position)
    local pBuyType = DiyFeatureType[type][position]
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = paInfo.p_keyId
    goodsInfo.goodsPrice = tostring(paInfo.p_price)
    goodsInfo.buyType = pBuyType
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function()
        failedCallFunc()
    end

    gLobalSaleManager:purchaseActivityGoods(
        "Promotion_DiyFeature",
        pBuyType,
        BUY_TYPE.DIYFEATURE_OVERSALE,
        goodsInfo.goodsId,
        goodsInfo.goodsPrice,
        0,
        0,
        buySuccess,
        buyFailed
    )
end

function DiyFeaturePromotionNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}

    goodsInfo.goodsTheme = "Promotion_DiyFeature"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    local buyType = _goodsInfo.buyType
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = buyType
    purchaseInfo.purchaseStatus = buyType
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

return DiyFeaturePromotionNet
