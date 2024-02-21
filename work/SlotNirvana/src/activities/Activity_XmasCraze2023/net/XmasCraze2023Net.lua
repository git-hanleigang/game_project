
local BaseNetModel = require("net.netModel.BaseNetModel")
local XmasCraze2023Net = class(" XmasCraze2023Net", BaseNetModel)

function XmasCraze2023Net:getInstance()
    if self.instance == nil then
        self.instance = XmasCraze2023Net.new()
    end
    return self.instance
end

-- 请求抽奖
function XmasCraze2023Net:requestNewData()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    local successCallback = function(_result)
        if not _result or _result.error then
            --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_XMASCRAZE2023_REFRESH, false)
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_XMASCRAZE2023_REFRESH)
    end

    local failedCallback = function(errorCode, errorData)
        --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_XMASCRAZE2023_REFRESH, false)
    end

    self:sendActionMessage(ActionType.HolidayNewChallengeCrazeRefresh, tbData, successCallback, failedCallback)
end

return XmasCraze2023Net
