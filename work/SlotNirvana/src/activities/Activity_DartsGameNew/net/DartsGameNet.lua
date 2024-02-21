local BaseNetModel = require("net.netModel.BaseNetModel")
local DartsGameNet = class("DartsGameNet", BaseNetModel)

--spin
function DartsGameNet:sendStartGameReq(gameIdx)
    gLobalViewManager:addLoadingAnima(false)
    local successCallback = function (result)
        gLobalViewManager:removeLoadingAnima()
        if not result or result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_SPIN_FAILED)
            return
        end
        G_GetMgr(ACTIVITY_REF.DartsGameNew):getData():getGameDataBuyIndex(gameIdx):setGameStartData(result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_SPIN_SUCC)
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_SPIN_FAILED)
    end
    
    local reqData = {
        data = {
            params = {
                index = gameIdx
            }
        }
    }
    --ActionType.DartsGameV2Play
    self:sendActionMessage(ActionType.DartsGameV2Play, reqData, successCallback, failedCallback)
end

--奖励
function DartsGameNet:sendGetReeward(gameIdx)
    gLobalViewManager:addLoadingAnima(false)
    local successCallback = function (result)
        gLobalViewManager:removeLoadingAnima()
        if not result or result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_REWARD_FAILED)
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_REWARD_SUCC)
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_REWARD_FAILED)
    end
    
    local reqData = {
        data = {
            params = {
                index = gameIdx
            }
        }
    }
    --ActionType.DartsGameV2Collect
    self:sendActionMessage(ActionType.DartsGameV2Collect, reqData, successCallback, failedCallback)
end

--结束
function DartsGameNet:sendGameEnd(gameIdx)
    gLobalViewManager:addLoadingAnima(false)
    local successCallback = function (result)
        gLobalViewManager:removeLoadingAnima()
        if not result or result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_END_FAILED)
            return
        end
        local cData = G_GetMgr(G_REF.Inbox):getSysRunData()
        if cData then
            cData:removeDartsGameNewMail(gameIdx)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_END_SUCC,gameIdx)
        G_GetMgr(ACTIVITY_REF.DartsGameNew):getData():removeGameDataByIndex(gameIdx)
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_END_FAILED)
    end
    
    local reqData = {
        data = {
            params = {
                index = gameIdx
            }
        }
    }
    --ActionType.DartsGameV2Skip
    self:sendActionMessage(ActionType.DartsGameV2Skip, reqData, successCallback, failedCallback)
end

-- 充值
function DartsGameNet:goPurchase(_gameData)
    if not _gameData then
        return 
    end
    
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _gameData:getKeyId()
    goodsInfo.goodsPrice = tostring(_gameData:getPrice())
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_gameData)
    
    local idx = _gameData:getIndex() 
    self.m_curPayGameData = _gameData
    local localId = string.format("%s_%s", BUY_TYPE.DartsGameV2, idx)
    gLobalSaleManager:purchaseActivityGoods(localId, idx, BUY_TYPE.DartsGameV2, goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
end

function DartsGameNet:buySuccess()
    if self.m_curPayGameData then
        self.m_curPayGameData = nil
    end
    gLobalViewManager:checkBuyTipList(function() 
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_PAY_SUCC)
    end)
end

function DartsGameNet:buyFailed()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_PAY_FAILED)
    self.m_curPayGameData = nil
end

function DartsGameNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "DartsGame"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "Darts"
    purchaseInfo.purchaseStatus = "Darts"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end

return DartsGameNet