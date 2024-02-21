--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local ObsidianCardNet = class("ObsidianCardNet", BaseNetModel)

-- function ObsidianCardNet:sendExtraRequest(stepId)
--     local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
--     local extraData = {}
--     extraData[ExtraType.cardSpecialClan] = stepId
--     actionData.data.extra = cjson.encode(extraData)
--     gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
-- end

return ObsidianCardNet
