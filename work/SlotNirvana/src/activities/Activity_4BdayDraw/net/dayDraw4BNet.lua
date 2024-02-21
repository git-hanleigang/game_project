--[[
    -- 4周年抽奖+分奖
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local dayDraw4BNet = class("dayDraw4BNet", BaseNetModel)

function dayDraw4BNet:saveCollect()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_4B_DAY_DRAW_COLLECT, {success = true})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_4B_DAY_DRAW_COLLECT, {success = false})
    end

    self:sendActionMessage(ActionType.FourBirthdayDrawCollect,tbData,successCallback,failedCallback)
end

return dayDraw4BNet