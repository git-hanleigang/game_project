--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-08 16:31:46
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-08 18:25:22
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/net/NewUserExpandNet.lua
Description: 扩圈系统 网络net
--]]
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local ActionNetModel = import("net.netModel.ActionNetModel")
local NewUserExpandNet = class("NewUserExpandNet", ActionNetModel)

-- 发请求激活扩圈系统
function NewUserExpandNet:sendActiveExpandFeatureReq(_successFunc)
    local successFunc = function(_receiveData)
        if _successFunc then
            _successFunc(_receiveData)
        end 
    end

    local failedFunc = function(_errorCode, errorMsg)
    end
    local reqData = {}
    self.m_timeOutKickOff = false
    self:sendActionMessage(ActionType.ExpandCircleActive, reqData, successFunc, failedFunc)
end

-- 完成上一关激活下一个关卡
function NewUserExpandNet:sendActiveExpandNewTaskReq(_openMiniGameKey, _successFunc)
    local successFunc = function(_receiveData)
        print("ExpandCirclePyiNext--success-")
        if _successFunc then
            _successFunc(_receiveData)
        end
        gLobalNoticManager:postNotification(NewUserExpandConfig.EVENT_NAME.ACTIVE_EXPAND_NEW_TASK_SUCCESS)
        gLobalViewManager:removeLoadingAnima()
    end

    local failedFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        print("ExpandCirclePyiNext---", _errorCode)
    end
    local reqData = {}
    local actionName = NewUserExpandConfig.MINI_GAME_ACTION_NAME[_openMiniGameKey]
    self.m_timeOutKickOff = true
    performWithDelay(display.getRunningScene(), function()
        if not self.m_reqingList[ActionType[actionName]] then
            return
        end
        gLobalViewManager:addLoadingAnima(false, 2)
    end, 1)
    self:sendActionMessage(ActionType[actionName], reqData, successFunc, failedFunc)
end

return NewUserExpandNet