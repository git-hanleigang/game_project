--[[
    第二货币抽奖
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local GemMayWinNet = class("GemMayWinNet", BaseNetModel)

function GemMayWinNet:getInstance()
    if self.instance == nil then
        self.instance = GemMayWinNet.new()
    end
    return self.instance
end

function GemMayWinNet:gemMayWinSpin()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_GEM_MAY_WIN_SPIN)
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_GEM_MAY_WIN_SPIN, {result = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_GEM_MAY_WIN_SPIN)
    end

    self:sendActionMessage(ActionType.GemMayWinSpin,tbData,successCallback,failedCallback)
end

return GemMayWinNet
