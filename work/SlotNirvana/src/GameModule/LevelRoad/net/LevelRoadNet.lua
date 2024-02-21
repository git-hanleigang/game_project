local BaseNetModel = require("net.netModel.BaseNetModel")
local LevelRoadNet = class("LevelRoadNet", BaseNetModel)

function LevelRoadNet:getInstance()
    if self.instance == nil then
        self.instance = LevelRoadNet.new()
    end
    return self.instance
end

-- 领取奖励
function LevelRoadNet:requestCollectReward(params, _successFunc, _failedCallback)
    gLobalViewManager:addLoadingAnima()
    local successCallback = function(_rewardList)
        gLobalViewManager:removeLoadingAnima()
        if _successFunc then
            _successFunc(_rewardList)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failedCallback then
            _failedCallback()
        end
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.LevelRoadCollect, tbData, successCallback, failedCallback)
end

-- 促销购买
function LevelRoadNet:requestBuySale(params, successCallFunc, failedCallFunc)
    local saleData = params.saleData -- 促销数据
    if not saleData then
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = saleData.value
    goodsInfo.goodsPrice = tostring(saleData.price)
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function()
        failedCallFunc()
    end

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.LEVEL_ROAD_SALE,
        goodsInfo.goodsId,
        goodsInfo.goodsPrice,
        0,
        0,
        buySuccess,
        buyFailed
    )
end

function LevelRoadNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}

    goodsInfo.goodsTheme = "LevelRoadPromotion"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "LevelRoadPromotion"
    purchaseInfo.purchaseStatus = "LevelRoadPromotion"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

return LevelRoadNet
