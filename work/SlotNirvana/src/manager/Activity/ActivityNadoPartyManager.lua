--[[
    nadoParty  新关预热
]]
local NetWorkBase = require "network.NetWorkBase"
local ActivityNadoPartyManager = class("ActivityNadoPartyManager",NetWorkBase)


function ActivityNadoPartyManager:getInstance()
	if not self._instance then
        self._instance = ActivityNadoPartyManager:create()
    end
    return self._instance
end

function ActivityNadoPartyManager:sendNadoPartyMessage()
    local actionData = self:getSendActionData(ActionType.NadoParty)
    
    local params = {}
    actionData.data.params = json.encode(params)

    local collectSuccess = function(_target, _resData)
        local data = cjson.decode(_resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NADO_PARTY_SUCCESS)
    end
    local collectFailed = function(_target, _resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_NADO_PARTY_FAILED)
    end

    self:sendMessageData(actionData, collectSuccess, collectFailed)
end

return ActivityNadoPartyManager