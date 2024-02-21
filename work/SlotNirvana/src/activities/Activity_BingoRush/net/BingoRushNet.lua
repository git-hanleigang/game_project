-- blast网络

local BingoRushNet = class("BingoRushNet", util_require("baseActivity.BaseActivityManager"))

function BingoRushNet:getInstance()
    if self.instance == nil then
        self.instance = BingoRushNet.new()
    end
    return self.instance
end

function BingoRushNet:ctor()
    BingoRushNet.super.ctor(self)
    self.bl_waitting = false
end

-- 报名比赛
function BingoRushNet:requestEnterRoom(idx, successCallFunc, failedCallFunc)
    local success_call_fun = function(responseTable, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = cjson.decode(resData.result)
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(target, errorCode, errorData)
        end
    end
    gLobalViewManager:addLoadingAnima()
    gLobalSendDataManager:getNetWorkFeature():sendActionBingoRushEnter(idx, success_call_fun, faild_call_fun)
end

-- 退出报名
function BingoRushNet:requestQuitRoom(successCallFunc, failedCallFunc)
    local success_call_fun = function(responseTable, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = cjson.decode(resData.result)
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(target, errorCode, errorData)
        end
    end
    gLobalViewManager:addLoadingAnima()
    gLobalSendDataManager:getNetWorkFeature():sendActionBingoRushQuit(success_call_fun, faild_call_fun)
end

-- 状态刷寻
function BingoRushNet:requestStatus(status, successCallFunc, failedCallFunc, bl_showLoading)
    -- 等待消息结果
    if self.bl_waitting ~= nil and self.bl_waitting == true then
        return
    end
    local success_call_fun = function(responseTable, resData)
        if bl_showLoading then
            gLobalViewManager:removeLoadingAnima()
        end
        self.bl_waitting = false
        local result = cjson.decode(resData.result)
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        if bl_showLoading then
            gLobalViewManager:removeLoadingAnima()
        end
        self.bl_waitting = false
        if failedCallFunc then
            failedCallFunc(target, errorCode, errorData)
        end
    end
    if bl_showLoading then
        gLobalViewManager:addLoadingAnima()
    end
    gLobalSendDataManager:getNetWorkFeature():sendActionBingoRushStatus(status, success_call_fun, faild_call_fun)
    self.bl_waitting = true
end

-- 获取spin结果
function BingoRushNet:requestReward(successCallFunc, failedCallFunc)
    local success_call_fun = function(responseTable, resData)
        gLobalViewManager:removeLoadingAnima()
        if successCallFunc then
            successCallFunc(resData)
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(target, errorCode, errorData)
        end
    end
    gLobalViewManager:addLoadingAnima()
    gLobalSendDataManager:getNetWorkFeature():sendActionBingoRushReward(success_call_fun, faild_call_fun)
end

-- 排行榜pass 任务 领取
function BingoRushNet:requestPassCollect(_idx, _payType, successCallFunc, failedCallFunc)
    local success_call_fun = function(responseTable, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = cjson.decode(resData.result)
        if successCallFunc then
            successCallFunc(result)
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(target, errorCode, errorData)
        end
    end
    gLobalViewManager:addLoadingAnima()
    if _idx and _idx >= 1 then
        _idx = _idx - 1
    end

    gLobalSendDataManager:getNetWorkFeature():sendActionBingoRushPassCollect(_idx, _payType, success_call_fun, faild_call_fun)
end

-- 获取spin结果
function BingoRushNet:requestSpin(successCallFunc, failedCallFunc)
    local success_call_fun = function(responseTable, resData)
        -- gLobalViewManager:removeLoadingAnima()
        local result = cjson.decode(resData.result)
        if successCallFunc then
            successCallFunc(resData)
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        -- gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(target, errorCode, errorData)
        end
    end
    -- gLobalViewManager:addLoadingAnima()
    gLobalSendDataManager:getNetWorkFeature():sendActionBingoRushSpin(success_call_fun, faild_call_fun)
end

-- 获取排行榜消息
function BingoRushNet:requestRankData(successCallFunc, failedCallFunc)
    local success_call_fun = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData.result ~= nil then
            local rankData = cjson.decode(resultData.result)
            if successCallFunc then
                successCallFunc(rankData)
            end
        end
    end

    local faild_call_fun = function(target, code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(target, code, errorMsg)
        end
    end
    gLobalViewManager:addLoadingAnima()
    gLobalSendDataManager:getNetWorkFeature():sendActionBingoRushRank(success_call_fun, faild_call_fun)
end

------------------------------促销付费------------------------------
function BingoRushNet:goPurchaseSale(bl_nocoin)
    local actData = G_GetMgr(ACTIVITY_REF.BingoRush):getRunningData()
    if not actData then
        return
    end

    if bl_nocoin then
        local saleData = actData:getSaleNoCoinData()
        if not saleData then
            return
        end
        local buyType = BUY_TYPE.BINGO_RUSH_NOCOIN_SALE
        self:sendIapLog(saleData, buyType)
        gLobalSaleManager:purchaseGoods(buyType, saleData:getGoodsId(), saleData:getPrice(), 0, 0, handler(self, self.buySuccessSale), handler(self, self.buyFailedSale))
    else
        local saleData = actData:getSaleData()
        if not saleData then
            return
        end
        local buyType = BUY_TYPE.BINGO_RUSH_SALE
        self:sendIapLog(saleData, buyType)
        gLobalSaleManager:purchaseGoods(buyType, saleData:getGoodsId(), saleData:getPrice(), 0, 0, handler(self, self.buySuccessSale), handler(self, self.buyFailedSale))
    end
end

function BingoRushNet:buySuccessSale()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGORUSH_SALE_BUY_SUCCESS)
end

function BingoRushNet:buyFailedSale()
end
------------------------------促销付费------------------------------

------------------------------pass付费------------------------------
function BingoRushNet:goPurchasePass()
    local actData = G_GetMgr(ACTIVITY_REF.BingoRush):getRunningData()
    if not actData then
        return
    end

    local passData = actData:getPassData()
    if not passData then
        return
    end

    self:sendIapLog(passData, BUY_TYPE.BINGO_RUSH_PASS)

    gLobalSaleManager:purchaseGoods(BUY_TYPE.BINGO_RUSH_PASS, passData:getGoodsId(), passData:getPrice(), 0, 0, handler(self, self.buySuccessPass), handler(self, self.buyFailedPass))
end

function BingoRushNet:buySuccessPass()
    gLobalViewManager:checkBuyTipList(function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGORUSH_TASK_PASS_BUY_SUCCESS)
    end)
end

function BingoRushNet:buyFailedPass()
end
------------------------------促销付费------------------------------

function BingoRushNet:sendIapLog(_buyData, _theme)
    if not _buyData then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    goodsInfo.goodsTheme = _theme
    goodsInfo.discount = _buyData:getDiscount()
    goodsInfo.goodsId = _buyData:getGoodsId()
    goodsInfo.discount = _buyData:getPrice()
    goodsInfo.totalCoins = _buyData:getCoins()

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = _theme
    if _theme == BUY_TYPE.BINGO_RUSH_SALE then
        purchaseInfo.purchaseStatus = _buyData:getLeftTimes()
    elseif _theme == BUY_TYPE.BINGO_RUSH_PASS then
        purchaseInfo.purchaseStatus = _buyData:getScore()
    elseif _theme == BUY_TYPE.BINGO_RUSH_NOCOIN_SALE then
        purchaseInfo.purchaseStatus = "BingoRush_0"
        local act_data = G_GetMgr(ACTIVITY_REF.BingoRush):getRunningData()
        if act_data then
            local hall_data = act_data:getHallData()
            local curRound, bl_inHall = hall_data:getCurRoundAndState()
            purchaseInfo.purchaseStatus = "BingoRush_" .. curRound + 1
        end
    end

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_buyData)
end

-- 退出bingo轮次
function BingoRushNet:requestLostData(successCallFunc, failedCallFunc)
    local success_call_fun = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData.result ~= nil then
            local rankData = cjson.decode(resultData.result)
            if successCallFunc then
                successCallFunc(rankData)
            end
        end
    end

    local faild_call_fun = function(target, code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc(target, code, errorMsg)
        end
    end
    gLobalViewManager:addLoadingAnima()
    gLobalSendDataManager:getNetWorkFeature():sendActionBingoRushLost(success_call_fun, faild_call_fun)
end

return BingoRushNet
