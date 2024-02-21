--[[
    网络请求
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local TrioPiggyNet = class("TrioPiggyNet", BaseNetModel)

function TrioPiggyNet:requestTrioPigInfo(_success, _failed)
    gLobalViewManager:addLoadingAnima()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success()
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.PigFamilyData, tbData, successFunc, failedFunc)
end


-- 集卡小猪付费购买
function TrioPiggyNet:requestBuyTrioPiggy(successCallFunc, failedCallFunc)
    local actData = G_GetMgr(ACTIVITY_REF.TrioPiggy):getRunningData()
    if not actData then
        return
    end

    local totalCoins = 0
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    if piggyBankData then
        totalCoins = totalCoins + piggyBankData:getRewardCoin()
    end
    local chipPiggyData = G_GetMgr(ACTIVITY_REF.ChipPiggy):getRunningData()
    if chipPiggyData then
        local chipCoins = chipPiggyData:getRewardCoin()
        totalCoins = totalCoins + chipCoins
    end

    local goodsInfo = {}
    goodsInfo.goodsTheme = "TrioPiggy"
    goodsInfo.discount = 0
    goodsInfo.goodsId = actData:getKeyId()
    goodsInfo.goodsPrice = actData:getPrice()
    goodsInfo.totalCoins = totalCoins
    self:sendIapLog(goodsInfo)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function(_errorInfo)
        failedCallFunc(_errorInfo)
    end

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.PIG_TRIO_SALE,
        goodsInfo.goodsId,
        goodsInfo.goodsPrice,
        goodsInfo.totalCoins,
        0,
        buySuccess,
        buyFailed
    )
end

function TrioPiggyNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "TrioPiggyBuy"
    purchaseInfo.purchaseStatus = "TrioPiggyBuy"
    gLobalSendDataManager:getLogIap():openIapLogInfo(_goodsInfo, purchaseInfo)
end

return TrioPiggyNet
