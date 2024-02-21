--[[
    LevelRoadGame 小游戏网络层
    author: zzy
    time: 2023-08-10

    ActionType.
    LevelRoadValidation = 493, -- 等级里程碑小游戏校验完成免费任务
    LevelRoadReward = 494, -- 等级里程碑小游戏领奖
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local LevelRoadGameNet = class("LevelRoadGameNet", BaseNetModel)


-- 发送验证消息，免费10次玩完后
function LevelRoadGameNet:sendValidationFreeGame(gameIdx)
    --gLobalViewManager:addLoadingAnima(false)

    local successCallback = function (result)
        --gLobalViewManager:removeLoadingAnima()
        if not result or result.error then 
            --gLobalNoticManager:postNotification(ViewEventType.NOTIFI_LEVELROAD_FAILED)
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_LEVELROADGAME_FREEGAMEOVER)  -- 免费次数完成 校验成功
    end

    local failedCallback = function(errorCode, errorData)
        --gLobalViewManager:removeLoadingAnima()
        --gLobalNoticManager:postNotification(ViewEventType.NOTIFI_LEVELROAD_FAILED)
    end
    
    local reqData = {
        data = {
            params = {
                index = gameIdx
            }
        }
    }

    self:sendActionMessage(ActionType.LevelRoadValidation, reqData, successCallback, failedCallback)
end

-- 充值
function LevelRoadGameNet:goPurchase(_gameData)
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
    local localId = string.format("%s_%s", BUY_TYPE.LEVELROADGAME, idx)
    gLobalSaleManager:purchaseActivityGoods(localId, idx, BUY_TYPE.LEVELROADGAME, goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
end

function LevelRoadGameNet:buySuccess()
    if self.m_curPayGameData then
        self.m_curPayGameData = nil
    end

    gLobalViewManager:checkBuyTipList(function() 
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_LRGAME_PAY_SUCC)
    end)
end

function LevelRoadGameNet:buyFailed()
    --gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_PAY_FAILED)
    self.m_curPayGameData = nil
end

function LevelRoadGameNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "LevelRoadGame"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "LevelRoadGame"
    purchaseInfo.purchaseStatus = "LevelRoadGame"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end

--奖励
function LevelRoadGameNet:sendGetReward(gameIdx)
    --gLobalViewManager:addLoadingAnima(false)

    local successCallback = function (result)
        --gLobalViewManager:removeLoadingAnima()

        if not result or result.error then 

            --gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_REWARD_FAILED)
            return
        end

        local cData = G_GetMgr(G_REF.Inbox):getSysRunData()
        if cData then
            cData:removeLevelRoadGameMail(gameIdx)
        end 
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_LRGAME_REWARD_SUCC)
        G_GetMgr(ACTIVITY_REF.LevelRoadGame):getData():removeGameDataByIndex(gameIdx)
        G_GetMgr(ACTIVITY_REF.LevelRoadGame):saveStepToCache("","") -- 清除缓存数据
    end

    local failedCallback = function(errorCode, errorData)
        --gLobalViewManager:removeLoadingAnima()
        --gLobalNoticManager:postNotification(ViewEventType.NOTIFI_DARTS_REWARD_FAILED)
    end
    
    local reqData = {
        data = {
            params = {
                index = gameIdx
            }
        }
    }

    self:sendActionMessage(ActionType.LevelRoadReward, reqData, successCallback, failedCallback)
end

return LevelRoadGameNet