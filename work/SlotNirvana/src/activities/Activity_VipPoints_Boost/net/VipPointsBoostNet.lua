--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local VipPointsBoostNet = class("VipPointsBoostNet", BaseNetModel)

function VipPointsBoostNet:getInstance()
    if self.instance == nil then
        self.instance = VipPointsBoostNet.new()
    end
    return self.instance
end

function VipPointsBoostNet:sendFirstStatus()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    local successCallback = function (_result)
    end

    local failedCallback = function (errorCode, errorData)
    end

    self:sendActionMessage(ActionType.VipPointsPoolFirst,tbData,successCallback,failedCallback)
end

return VipPointsBoostNet