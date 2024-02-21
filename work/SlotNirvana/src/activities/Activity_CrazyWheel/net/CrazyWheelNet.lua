--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local CrazyWheelNet = class("CrazyWheelNet", BaseNetModel)


-- CrazyWheelPlay = 556, -- 抽奖转盘的play接口
-- CrazyWheelPayCoupon = 557, -- 抽奖转盘买劵接口
-- CrazyWheelCollectReward = 558, -- 抽奖转盘领奖接口    

function CrazyWheelNet:requestPlay(_multiple, _success, _failed)
    local tbData = {
        data = {
            params = {
            }
        }
    }
    gLobalViewManager:addLoadingAnimaDelay()
    local function successCallFun(_result)
        gLobalViewManager:removeLoadingAnima()
        if _result and _result.rewards and _result.rewards.index > 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CRAZYWHEEL_PLAY, {success = true})
            if _success then
                _success(_result.rewards.index)
            end
        else
            release_print("!!!dont have win index")
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CRAZYWHEEL_PLAY, {success = false})
            if _failed then
                _failed()
            end
        end
    end
    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CRAZYWHEEL_PLAY, {success = false})
        if _failed then
            _failed()
        end
    end
    tbData.data.params.multiple = _multiple
    self:sendActionMessage(ActionType.CrazyWheelPlay, tbData, successCallFun, failedCallFun)
end

function CrazyWheelNet:buyLottery(_num, _success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CRAZYWHEEL_BUY_LOTTERY, {success = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {isPlayEffect = false})
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CRAZYWHEEL_BUY_LOTTERY, {success = false})
        gLobalViewManager:showReConnect()
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.num = _num
    self:sendActionMessage(ActionType.CrazyWheelPayCoupon, tbData, successFunc, failedFunc)
end

function CrazyWheelNet:requestCollect(_success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        gLobalViewManager:showReConnect()
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.CrazyWheelCollectReward, tbData, successFunc, failedFunc)
end

return CrazyWheelNet
