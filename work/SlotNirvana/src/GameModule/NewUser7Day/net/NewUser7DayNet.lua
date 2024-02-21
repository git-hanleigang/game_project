--[[
Author: dhs
Date: 2022-05-06 19:33:57
LastEditTime: 2022-05-09 17:51:38
LastEditors: dinghansheng.local
Description: 新手7日目标 Net
FilePath: /SlotNirvana/src/GameModule/NewUser7Day/net/NewUser7DayNet.lua
--]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local NewUser7DayNet = class("NewUser7DayNet", BaseNetModel)

function NewUser7DayNet:sendCollect(_successCall, _failedCall)
    local tbData = {
        data = {
            params = {}
        }
    }

    local successFunc = function()
        if _successCall then
            _successCall()
        end
    end

    local failedFunc = function(errorCode, errorData)
        release_print(errorCode, errorData)
        local logMsg = "errorCode:" .. errorCode .. ",errorData:" .. errorData
        util_sendToSplunkMsg("NewUser7Day Request CollectRewardFailed", errorData)

        if _failedCall then
            _failedCall()
        end
    end

    self:sendActionMessage(ActionType.VegasTripCollect, tbData, successFunc, failedFunc)
end

return NewUser7DayNet
