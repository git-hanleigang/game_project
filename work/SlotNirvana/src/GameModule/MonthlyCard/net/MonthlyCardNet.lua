--[[
    月卡 网络层
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local MonthlyCardNet = class("MonthlyCardNet", BaseNetModel)

function MonthlyCardNet:getInstance()
    if self.instance == nil then
        self.instance = MonthlyCardNet.new()
    end
    return self.instance
end

-- params {type = "standard"} 标准版 or {type = "deluxe"} 豪华版
function MonthlyCardNet:requestMonthlyCardReward(params, successFunc, failedCallFunc)
    local tbData = {
        data = {
            params = params or {}
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        if successFunc then
            successFunc(resData)
        end
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    self:sendActionMessage(ActionType.MonthlyCardCollect, tbData, successCallFun, failedCallFun)
end

-- 月卡付费购买
function MonthlyCardNet:requestBuyMothlyCard(params, successCallFunc, failedCallFunc)
    local actData = G_GetMgr(G_REF.MonthlyCard):getRunningData()
    if not actData then
        return
    end

    local MonthlyCardType = {"standard", "deluxe"} --标准版, 豪华版 (服务器区分用)
    local type = params.type -- 1-普通版， 2-豪华版
    local paInfo = actData:getInfoByType(type)

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = paInfo.keyId
    goodsInfo.goodsPrice = tostring(paInfo.price)
    goodsInfo.buyType = type
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function()
        failedCallFunc()
    end

    globalData.iapRunData.p_activityId = "MonthlyCard"
    globalData.iapRunData.p_contentId = MonthlyCardType[type]
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.MONTHLY_CARD,
        goodsInfo.goodsId,
        goodsInfo.goodsPrice,
        0,
        0,
        buySuccess,
        buyFailed
    )
end

function MonthlyCardNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}

    goodsInfo.goodsTheme = "MonthlyCard"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    local monthType = _goodsInfo.buyType == 1 and "NormalMonth" or "SpecialMonth"
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = monthType
    purchaseInfo.purchaseStatus = monthType
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

return MonthlyCardNet
