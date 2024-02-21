--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-04-28 16:04:47
    describe:刮刮卡网络层
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local ScratchCardsNet = class("ScratchCardsNet", BaseNetModel)
-- ScratchCardScratch = 257, -- 刮刮刮卡
-- ScratchCardFreeGet = 258, -- 刮刮卡免费领取
-- ScratchCardOpenFresh = 259, -- 刮刮卡打开刷新
-- ScratchCardClose = 260, -- 刮刮卡页面关闭

-- 刮刮卡免费领取
function ScratchCardsNet:requestFree(param, successCallFunc, failedCallFunc)
    local tbData = {
        data = {
            params = param or {}
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        -- if resData:HasField("result") == true then
        --     result = cjson.decode(resData.result)
        -- end
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    self:sendActionMessage(ActionType.ScratchCardFreeGet, tbData, successCallback, failedCallback)
end

-- 刮刮卡打开刷新
function ScratchCardsNet:requestOpenView(param, successCallFunc, failedCallFunc)
    local tbData = {
        data = {
            params = param or {}
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    self:sendActionMessage(ActionType.ScratchCardOpenFresh, tbData, successCallback, failedCallback)
end

-- 刮刮刮卡
function ScratchCardsNet:requestScratch(param, successCallFunc, failedCallFunc)
    local tbData = {
        data = {
            params = param or {}
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    self:sendActionMessage(ActionType.ScratchCardScratch, tbData, successCallback, failedCallback)
end

-- 刮刮卡页面关闭
function ScratchCardsNet:requestCloseView(param, successCallFunc, failedCallFunc)
    local tbData = {
        data = {
            params = param or {}
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    self:sendActionMessage(ActionType.ScratchCardClose, tbData, successCallback, failedCallback)
end

-- 刮刮卡付费购买
function ScratchCardsNet:requestBuyGoods(params, successCallFunc, failedCallFunc)
    local actData = G_GetMgr(ACTIVITY_REF.ScratchCards):getRunningData()
    if not actData then
        return
    end

    local index = params.index
    local btnInx = params.btnInx
    local gearInfo = actData:getGearInfoByIndex(index)
    local paInfo = gearInfo.payInfoList[btnInx]
    actData:setGearKey(tostring(gearInfo.gearKey))

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = paInfo.keyId
    goodsInfo.goodsPrice = tostring(paInfo.price)
    goodsInfo.goodsNum = paInfo.num
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo, index)

    local buySuccess = function()
        successCallFunc()
    end

    local buyFailed = function()
        failedCallFunc()
    end

    gLobalSaleManager:purchaseActivityGoods(
        "ScratchCards",
        tostring(gearInfo.gearKey),
        BUY_TYPE.SCRATCHCARD,
        goodsInfo.goodsId,
        goodsInfo.goodsPrice,
        0,
        0,
        buySuccess,
        buyFailed
    )
end

function ScratchCardsNet:sendIapLog(_goodsInfo, _index)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}

    goodsInfo.goodsTheme = "ScratchCards"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "ScratchBuy"
    purchaseInfo.purchaseStatus = "ScratchBuy" .. _goodsInfo.goodsNum
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo)
end

return ScratchCardsNet
