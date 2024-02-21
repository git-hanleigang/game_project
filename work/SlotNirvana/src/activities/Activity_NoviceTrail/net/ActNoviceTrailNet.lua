--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-04-20 17:09:10
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-26 11:13:03
FilePath: /SlotNirvana/src/activities/Activity_NoviceTrail/net/ActNoviceTrailNet.lua
Description: 新手期三日任务 网络net
--]]
local ActionNetModel = require("net.netModel.ActionNetModel")
local ActNoviceTrailNet = class("ActNoviceTrailNet", ActionNetModel)
local ActNoviceTrailConfig = util_require("activities.Activity_NoviceTrail.config.ActNoviceTrailConfig")

function ActNoviceTrailNet:sendCollectTaskReq(_type, _taskId, _day)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_receiveData)
        if type(_receiveData) == "table" then
            _receiveData.showDay = _day
            gLobalNoticManager:postNotification(ActNoviceTrailConfig.EVENT_NAME.COLLECT_NOVICE_TRAIL_SUCCESS, _receiveData)
        end
        gLobalViewManager:removeLoadingAnima()
    end

    local failedFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
    end

    local reqData = {
        data = {
            params = {
                type = _type,
                taskId = _taskId,
                day = _day
            }
        }
    }
    self.m_timeOutKickOff = false
    self:sendActionMessage(ActionType.NoviceTrailCollect, reqData, successFunc, failedFunc)
end

-- 获取最新 活动数据
function ActNoviceTrailNet:sendGetNewActDataReq()
    local successFunc = function(_receiveData)
        if type(_receiveData) == "table" then
            gLobalNoticManager:postNotification(ActNoviceTrailConfig.EVENT_NAME.REQ_TRAIL_NEW_DATA_SUCCESS)
        end
    end

    local failedFunc = function(_errorCode, errorMsg)
    end

    local reqData = {}
    self.m_timeOutKickOff = false
    self:sendActionMessage(ActionType.NoviceTrailRefresh, reqData, successFunc, failedFunc)
end

return ActNoviceTrailNet