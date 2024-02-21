--[[
    生日 网络层
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local BirthdayNet = class("BirthdayNet", BaseNetModel)

function BirthdayNet:getInstance()
    if self.instance == nil then
        self.instance = BirthdayNet.new()
    end
    return self.instance
end

-- 请求修改生日信息
function BirthdayNet:requestEditBirthday(params, successFunc, failedCallFunc)
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

    self:sendActionMessage(ActionType.BirthdayInformationModify, tbData, successCallFun, failedCallFun)
end

-- 生日礼品领取
function BirthdayNet:requestCollectBirthdayGift(params, successFunc, failedCallFunc)
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

    self:sendActionMessage(ActionType.BirthdayCollect, tbData, successCallFun, failedCallFun)
end

-- 生日促销购买
function BirthdayNet:requestBuyBirthdaySale(successCallFunc, failedCallFunc)
    local actData = G_GetMgr(ACTIVITY_REF.Birthday):getRunningData()
    if not actData then
        return
    end

    local saleData = actData:getBirthdaySaleData()

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = saleData.p_key
    goodsInfo.goodsPrice = tostring(saleData.p_price)
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function()
        failedCallFunc()
    end

    gLobalSaleManager:purchaseActivityGoods(
        saleData.p_activityId,
        saleData.p_activityId,
        BUY_TYPE.BIRTHDAY_SALE,
        goodsInfo.goodsId,
        goodsInfo.goodsPrice,
        0,
        0,
        buySuccess,
        buyFailed
    )
end

function BirthdayNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}

    goodsInfo.goodsTheme = "BirthdaySale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "BirthdaySale"
    purchaseInfo.purchaseStatus = "BirthdaySale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

return BirthdayNet
