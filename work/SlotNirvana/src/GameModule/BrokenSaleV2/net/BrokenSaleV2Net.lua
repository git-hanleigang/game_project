--[[
    破产促销V2 网络层
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local BrokenSaleV2Net = class("BrokenSaleV2Net", BaseNetModel)

-- buff金币领奖
function BrokenSaleV2Net:requestBuffCoinsReward(params, successFunc, failedCallFunc)
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

    self:sendActionMessage(ActionType.GoBrokeSaleBuffReward, tbData, successCallFun, failedCallFun)
end

-- 促销弹窗关闭
function BrokenSaleV2Net:requestCloseSaleView(params, successFunc, failedCallFunc)
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

    self:sendActionMessage(ActionType.GoBrokeSaleShowClose, tbData, successCallFun, failedCallFun)
end

-- 付费购买
function BrokenSaleV2Net:requestBuySale(params, successCallFunc, failedCallFunc)
    local paInfo = params
    if not paInfo then
        return 
    end
    self:sendIapLog(paInfo)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function()
        failedCallFunc()
    end

    gLobalSaleManager:purchaseActivityGoods(
        G_REF.BrokenSaleV2,
        paInfo:getIndex(),
        BUY_TYPE.BROKENSALEV2,
        paInfo:getKey(),
        paInfo:getPrice(),
        0,
        0,
        buySuccess,
        buyFailed
    )
end

function BrokenSaleV2Net:sendIapLog(_saleItem)
    if not _saleItem then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    goodsInfo.goodsTheme = G_REF.BrokenSaleV2
    goodsInfo.goodsId = _saleItem:getKey()
    goodsInfo.goodsPrice = _saleItem:getPrice()
    goodsInfo.discount = _saleItem:getDiscount()
    goodsInfo.totalCoins = _saleItem:getCoins()

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "normalBuy"
    purchaseInfo.purchaseName = "GoBrokeSale_" .. _saleItem:getIndex()
    purchaseInfo.purchaseStatus = "GoBrokeSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

return BrokenSaleV2Net
