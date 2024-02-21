--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-15 14:56:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-15 16:00:38
FilePath: /SlotNirvana/src/activities/Activity_TreasureHunt/net/TreasureHuntNet.lua
Description: 寻宝之旅 网络net
--]]
local ActionNetModel = require("net.netModel.ActionNetModel")
local TreasureHuntNet = class("TreasureHuntNet", ActionNetModel)
local TreasureHuntConfig = util_require("activities.Activity_TreasureHunt.config.TreasureHuntConfig")

function TreasureHuntNet:sendCollectReq(_seq)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_receiveData)
        gLobalNoticManager:postNotification(TreasureHuntConfig.EVENT_NAME.ONRECIEVE_COLLECT_TREASURE_DASH_RQE, _receiveData)
        gLobalViewManager:removeLoadingAnima()
    end

    local failedFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
    end

    local reqData = {
        data = {
            params = {
                seq = _seq
            }
        }
    }
    self:sendActionMessage(ActionType.TreasureHuntCollect, reqData, successFunc, failedFunc)
end

return TreasureHuntNet