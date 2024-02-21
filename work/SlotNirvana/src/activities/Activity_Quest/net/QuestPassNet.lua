--[[
    
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local QuestPassNet = class("QuestPassNet", BaseNetModel)

function QuestPassNet:getInstance()
    if self.instance == nil then
        self.instance = QuestPassNet.new()
    end
    return self.instance
end

function QuestPassNet:sendPassCollect(_data, _type)
    local tbData = {
        data = {
            params = {
                level = _data.p_level,
                type = _type
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        local gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if gameData and _result and _result.questPass then 
            gameData:parsePassData(_result.questPass)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_PASS_COLLECT, {success = true, data = _data, type = _type})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_PASS_COLLECT, {success = false, _data = _data, type = _type})
    end

    self:sendActionMessage(ActionType.QuestPassCollect,tbData,successCallback,failedCallback)
end

function QuestPassNet:sendPassBoxCollect(_data, _type)
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima()

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        local gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if gameData and _result and _result.questPass then 
            gameData:parsePassData(_result.questPass)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_PASS_COLLECT, {success = true, data = _data, type = _type})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_PASS_COLLECT, {success = false, _data = _data, type = _type})
    end

    self:sendActionMessage(ActionType.QuestPassCollectBox,tbData,successCallback,failedCallback)
end

-- 付费
function QuestPassNet:buyPassUnlock(_data)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.QUEST_PASS,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK, {success = true})
            end)
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK)
        end
    )
end

function QuestPassNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "QuestPass"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "QuestPass"
    purchaseInfo.purchaseStatus = "QuestPass"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end


-- 获取link jackpot金币 刷新奖池
function QuestPassNet:requestGetPool()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successCallback = function (_result)
        G_GetMgr(ACTIVITY_REF.Quest):updateQuestGoldIncrease(true,_result)
        G_GetMgr(ACTIVITY_REF.Quest):clearRequestGetPool()
    end

    local failedCallback = function (errorCode, errorData)
    end
    self:sendActionMessage(ActionType.QuestJackpotWheelInfo,tbData,successCallback,failedCallback)
end

return QuestPassNet
