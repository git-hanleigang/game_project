--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-19 17:24:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-19 17:32:39
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/net/NoviceSevenSignNet.lua
Description: 新手期 7日签到V2 网络net
--]]
local ActionNetModel = require("net.netModel.ActionNetModel")
local NoviceSevenSignNet = class("NoviceSevenSignNet", ActionNetModel)
local NoviceSevenSignConfig = util_require("GameModule.NoviceSevenSign.config.NoviceSevenSignConfig")

function NoviceSevenSignNet:sendCollectReq()
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_receiveData)
        gLobalNoticManager:postNotification(NoviceSevenSignConfig.EVENT_NAME.ONRECIEVE_COLLECT_NOVICE_SIGN_DAY_REWARD, _receiveData)
        gLobalViewManager:removeLoadingAnima()
    end

    local failedFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
    end

    local reqData = {}
    self:sendActionMessage(ActionType.NoviceCheckV2Collect, reqData, successFunc, failedFunc)
end

return NoviceSevenSignNet