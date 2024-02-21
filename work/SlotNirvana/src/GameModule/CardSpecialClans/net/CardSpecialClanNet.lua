--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local CardSpecialClanNet = class("CardSpecialClanNet", BaseNetModel)

-- function CardSpecialClanNet:sendExtraRequest(stepId)
--     local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
--     local extraData = {}
--     extraData[ExtraType.cardSpecialClan] = stepId
--     actionData.data.extra = cjson.encode(extraData)
--     gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
-- end

return CardSpecialClanNet
