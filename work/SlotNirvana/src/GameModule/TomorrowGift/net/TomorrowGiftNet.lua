--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-04 15:17:08
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-04 17:20:58
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/net/TomorrowGiftNet.lua
Description: 次日礼物 net
--]]
local ActionNetModel = require("net.netModel.ActionNetModel")
local TomorrowGiftNet = class("TomorrowGiftNet", ActionNetModel)
local TomorrowGiftConfig = util_require("GameModule.TomorrowGift.config.TomorrowGiftConfig")

function TomorrowGiftNet:sendCollectReq()
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_receiveData)
        gLobalNoticManager:postNotification(TomorrowGiftConfig.EVENT_NAME.ONRECIEVE_COLLECT_TOMORROW_GIFT_RQE, _receiveData)
        gLobalViewManager:removeLoadingAnima()
    end

    local failedFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
    end

    local reqData = {}
    self:sendActionMessage(ActionType.TomorrowGiftCollect, reqData, successFunc, failedFunc)
end

return TomorrowGiftNet