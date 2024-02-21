--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-13 20:35:36
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-13 20:36:54
FilePath: /SlotNirvana/src/net/netModel/ActionNetModel.lua
Description: Action 类型网络请求
--]]
local BaseNetModel = import(".BaseNetModel")
local ActionNetModel = class("ActionNetModel", BaseNetModel)

function ActionNetModel:ctor()
    ActionNetModel.super.ctor(self)

    self.m_reqingList = {}
    self.m_reqingTimeList = {}
    self.m_timeOutKickOff = false
end

-- 发送Action消息
function ActionNetModel:sendActionMessage(_actionType, _tbData, _successFunc, _failedFunc)
    if not _actionType then
        return
    end

    if self.m_reqingList[_actionType] then
        return
    end
    local successCB = function(_jsonResult)
        self.m_reqingList[_actionType] = false
        self.m_reqingTimeList[_actionType] = nil
        if _successFunc then
            _successFunc(_jsonResult)
        end
    end
    local failedCB = function(_errorCode, _errorData)
        self.m_reqingList[_actionType] = false
        if _failedFunc then
            _failedFunc(_errorCode, _errorData)
        end
        local timeFaild = xcyy.SlotsUtil:getMilliSeconds()
        if self.m_timeOutKickOff and self.m_reqingTimeList[_actionType] and ((timeFaild - self.m_reqingTimeList[_actionType]) > 29*1000  or _errorCode == -1) then
            -- 断网 超时踢下线
            if gLobalGameHeartBeatManager then
                gLobalGameHeartBeatManager:stopHeartBeat()
            end
            util_restartGame()
        end
        self.m_reqingTimeList[_actionType] = nil
    end
    self.m_reqingList[_actionType] = true
    self.m_reqingTimeList[_actionType] = xcyy.SlotsUtil:getMilliSeconds()
    ActionNetModel.super.sendActionMessage(self, _actionType, _tbData, successCB, failedCB)
end

return ActionNetModel