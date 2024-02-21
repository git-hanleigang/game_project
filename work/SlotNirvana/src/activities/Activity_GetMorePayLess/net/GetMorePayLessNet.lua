--[[
    付费目标
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local GetMorePayLessNet = class("GetMorePayLessNet", BaseNetModel)

function GetMorePayLessNet:getInstance()
    if self.instance == nil then
        self.instance = GetMorePayLessNet.new()
    end
    return self.instance
end

function GetMorePayLessNet:sendCollect(_index)
    local tbData = {
        data = {
            params = {
                index = _index
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_GET_MORE_PAY_LESS_COLLECT, {index = _index})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_GET_MORE_PAY_LESS_COLLECT)
    end

    self:sendActionMessage(ActionType.GetMorePayLessCollect, tbData, successCallFun, failedCallFun)
end

return GetMorePayLessNet
