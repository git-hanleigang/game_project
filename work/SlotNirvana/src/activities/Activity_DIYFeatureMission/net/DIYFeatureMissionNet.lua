local BaseNetModel = require("net.netModel.BaseNetModel")
local DIYFeatureMissionNet = class("DIYFeatureMissionNet", BaseNetModel)

function DIYFeatureMissionNet:getInstance()
    if self.instance == nil then
        self.instance = DIYFeatureMissionNet.new()
    end
    return self.instance
end

function DIYFeatureMissionNet:sendCollect(data,successCallback,failedCallback)
    local tbData = {
        data = {
            params = {
                taskId = data.m_taskId
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    self:sendActionMessage(ActionType.DiyFeatureMissionCollect,tbData,successCallback,failedCallback)
end

function DIYFeatureMissionNet:sendDiyTaskUpdate(successCallback,failedCallback)
    local tbData = {
        data = {
            params = {
            }
        }
    }
    self:sendActionMessage(ActionType.DiyFeatureMissionData,tbData,successCallback,failedCallback)
end

return DIYFeatureMissionNet
