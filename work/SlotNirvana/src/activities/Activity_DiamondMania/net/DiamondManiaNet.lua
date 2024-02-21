--[[
    钻石挑战通关挑战
]]

local DiamondManiaConfig = require("activities.Activity_DiamondMania.config.DiamondManiaConfig")
local BaseNetModel = require("net.netModel.BaseNetModel")
local DiamondManiaNet = class("DiamondManiaNet", BaseNetModel)

function DiamondManiaNet:sendCollect()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(DiamondManiaConfig.notify_collect, {success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(DiamondManiaConfig.notify_collect)
    end

    self:sendActionMessage(ActionType.DiamondManiaCollect,tbData,successCallback,failedCallback)
end

return DiamondManiaNet