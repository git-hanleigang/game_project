--[[
    聚合挑战结束促销
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local QuestNewNet = class("QuestNewNet", BaseNetModel)

function QuestNewNet:getInstance()
    if self.instance == nil then
        self.instance = QuestNewNet.new()
    end
    return self.instance
end

function QuestNewNet:requestQuestRank()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {type = "failed"})
            return
        end
        if _result ~= nil then
            local questData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
            if questData then
                questData:parseQuestRankConfig(_result)
            end
    
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.QuestNew})
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_RANK, _result)
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:showReConnect()
    end

    self:sendActionMessage(ActionType.FantasyQuestRank,tbData,successCallback,failedCallback)
end

function QuestNewNet:requestCollectGift(chapterId,stageId)
    local tbData = {
        data = {
            params = {
                stage = stageId,
                phase = chapterId
            }
        }
    }
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_COLLECTGIFT, {type = "failed"})
            return
        end

        local questData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
        if questData then
            questData:checkChapterCompleted() -- 标记章节是否完成
        end

        local usePoint = G_GetMgr(ACTIVITY_REF.QuestNew):getPointDataByChapterIdAndIndex(chapterId,stageId)
        if usePoint then
            usePoint:afterBoxCollected()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_COLLECTGIFT, {type = "success",stageId = stageId})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_COLLECTGIFT, {type = "failed"})
    end

    self:sendActionMessage(ActionType.FantasyQuestCollectGift,tbData,successCallback,failedCallback)
end

function QuestNewNet:requestCollectStarMeter(chapterId)
    local tbData = {
        data = {
            params = {
                phase = chapterId
            }
        }
    }
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_GAINSTARREWARD, {type = "failed"})
            return
        end
        local questData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
        if questData then
            questData:checkChapterCompleted() -- 标记章节是否完成
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_GAINSTARREWARD, {type = "success"})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_GAINSTARREWARD, {type = "failed"})
    end

    self:sendActionMessage(ActionType.FantasyQuestCollectStarMeters,tbData,successCallback,failedCallback)
end

-- 获取link jackpot金币 刷新奖池
function QuestNewNet:requestGetPool()
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
        G_GetMgr(ACTIVITY_REF.QuestNew):updateQuestGoldIncrease(true,_result)
        G_GetMgr(ACTIVITY_REF.QuestNew):clearRequestGetPool()
    end

    local failedCallback = function (errorCode, errorData)
    end
    self:sendActionMessage(ActionType.FantasyQuestGetPool,tbData,successCallback,failedCallback)
end

function QuestNewNet:requestPlayWheel()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_PLAYWHEEL, {type = "failed"})
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_PLAYWHEEL, {type = "success", data = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_PLAYWHEEL, {type = "failed"})
    end

    self:sendActionMessage(ActionType.FantasyQuestPlayWheel,tbData,successCallback,failedCallback)
end

function QuestNewNet:requestCollectWheelReward()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_WHEELREWARD, {type = "failed"})
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_WHEELREWARD, {type = "success", data = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_WHEELREWARD, {type = "failed"})
    end

    self:sendActionMessage(ActionType.FantasyQuestCollectWheelReward,tbData,successCallback,failedCallback)
end


function QuestNewNet:doQuestNextRound()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        G_GetMgr(ACTIVITY_REF.QuestNew):setForceInitChapter(false)
        G_GetMgr(ACTIVITY_REF.QuestNew):clearQuestNextRound()
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_DONEXTROUND, {type = "failed"})
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_DONEXTROUND, {type = "success"})
    end

    local failedCallback = function (errorCode, errorData)
        G_GetMgr(ACTIVITY_REF.QuestNew):setForceInitChapter(false)
        G_GetMgr(ACTIVITY_REF.QuestNew):clearQuestNextRound()
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_DONEXTROUND, {type = "failed"})
    end

    self:sendActionMessage(ActionType.FantasyQuestNextRound,tbData,successCallback,failedCallback)
end



function QuestNewNet:doQuestBySaleUseGem(gemIndex)
    local tbData = {
        data = {
            params = {
                gemIndex = gemIndex
            }
        }
    }
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_BUYSALE, {type = "failed"})
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_BUYSALE, {type = "success"})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_BUYSALE, {type = "failed"})
    end

    self:sendActionMessage(ActionType.FantasyQuestSaleGem,tbData,successCallback,failedCallback)
end









function QuestNewNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "HolidayChallenge"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = _goodsInfo.discount
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "HolidayChallenge"
    purchaseInfo.purchaseStatus = "HolidayChallenge"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

return QuestNewNet
