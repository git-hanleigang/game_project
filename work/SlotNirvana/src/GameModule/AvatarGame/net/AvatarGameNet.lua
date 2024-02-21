--[[
]]

local BaseNetModel = import("net.netModel.BaseNetModel")
local AvatarGameNet = class("AvatarGameNet", BaseNetModel)

function AvatarGameNet:getInstance()
    if self.instance == nil then
        self.instance = AvatarGameNet.new()
    end
    return self.instance
end

function AvatarGameNet:sendPlay()
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
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AVATAR_GAME_PLAY, false)
            return
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AVATAR_GAME_PLAY, _result)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AVATAR_GAME_PLAY, false)
    end

    self:sendActionMessage(ActionType.AvatarFrameGamePlay,tbData,successCallback,failedCallback)
end

return AvatarGameNet