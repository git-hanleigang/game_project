--[[
   圣诞聚合 -- pass
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local HolidayPassNet = class("HolidayPassNet", BaseNetModel)

function HolidayPassNet:requestRefreshData(successFunc, failedCallFunc)
    local tbData = {
        data = {
            params = {}
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

    self:sendActionMessage(ActionType.HolidayNewChallengePassTaskRefresh, tbData, successCallFun, failedCallFun)
end

function HolidayPassNet:requestCollectReward(_params, successFunc, failedCallFunc)
    local r_params = _params or {}
    local tbData = {
        data = {
            params = {seq = r_params.seq, free = r_params.free}
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

    self:sendActionMessage(ActionType.HolidayNewChallengePassCollectReward, tbData, successCallFun, failedCallFun)
end

-- pass付费购买
function HolidayPassNet:requestBuyPass(params, successCallFunc, failedCallFunc)
    local actData = G_GetMgr(ACTIVITY_REF.HolidayPass):getRunningData()
    if not actData then
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = actData:getKeyId()
    goodsInfo.goodsPrice = actData:getPrice()
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function()
        failedCallFunc()
    end

    gLobalSaleManager:purchaseGoods(BUY_TYPE.HolidayNewChallengePass, goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, buySuccess, buyFailed)
end

function HolidayPassNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}

    goodsInfo.goodsTheme = "HolidayPass"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "HolidayPass"
    purchaseInfo.purchaseStatus = "HolidayPass"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

return HolidayPassNet
