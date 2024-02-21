-- 新手期个人累充 网络消息处理

local BaseNetModel = require("net.netModel.BaseNetModel")
local TopUpBonusNet = class("TopUpBonusNet", BaseNetModel)

function TopUpBonusNet:getInstance()
    if self.instance == nil then
        self.instance = TopUpBonusNet.new()
    end
    return self.instance
end


function TopUpBonusNet:requestRefreshActivityData()
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
            return
        end

        G_GetMgr(ACTIVITY_REF.TopUpBonus):updateTopUpBonusGoldIncrease(true,_result)
        G_GetMgr(ACTIVITY_REF.TopUpBonus):clearRequestGetPool()
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_PLAYWHEEL, {type = "failed"})
    end

    self:sendActionMessage(ActionType.TopUpBonusRefresh,tbData,successCallback,failedCallback)
end


-- 发送获取字母消息
function TopUpBonusNet:requestCollect(price,index)
    if not price or price < 0 then
        return
    end

    local tbData = {
        data = {
            params = {
                price = price
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
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TOP_UP_BONUS_COLLECT, {isSucc = false,index = index})
            return
        end

        G_GetMgr(ACTIVITY_REF.TopUpBonus):recordRewardsList(_result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TOP_UP_BONUS_COLLECT, {isSucc = true,index = index})

    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TOP_UP_BONUS_COLLECT, {isSucc = false,index = index})
    end

    self:sendActionMessage(ActionType.TopUpBonusCollect,tbData,successCallback,failedCallback)
end


function TopUpBonusNet:requestPlayWheel(type) -- 0.单次 1.所有
    local tbData = {
        data = {
            params = {
                type = type
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
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_AFTER_TOP_UP_BONUS_PLAYWHEEL, {type = type ,isOk = "failed"})
            return
        end
        G_GetMgr(ACTIVITY_REF.TopUpBonus):recordRewardsList(_result)
        G_GetMgr(ACTIVITY_REF.TopUpBonus):updateTopUpBonusGoldIncrease(true,{})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_AFTER_TOP_UP_BONUS_PLAYWHEEL, {type = type ,isOk = "success", data = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_AFTER_TOP_UP_BONUS_PLAYWHEEL, {type = type ,isOk = "failed"})
    end

    self:sendActionMessage(ActionType.TopUpBonusWheelPlay,tbData,successCallback,failedCallback)
end

return TopUpBonusNet
