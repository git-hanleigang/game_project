--[[
Author: cxc
Date: 2022-01-11 11:50:44
LastEditTime: 2022-01-11 14:18:48
LastEditors: your name
Description: Lottery乐透 额外奖励活动 网络模块
FilePath: /SlotNirvana/src/activities/Activity_Lottery_Jackpot/net/LotteryJackpotNet.lua
--]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local LotteryJackpotNet = class("LotteryJackpotNet", BaseNetModel)

function LotteryJackpotNet:sendCollectReq(_successFunc)
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _successFunc then
            _successFunc()
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end

    local tbData = {
        data = {
            params = {
            }
        }
    }
    self:sendActionMessage(ActionType.LotteryExtraCollect, tbData, successCallback, failedCallback)
end

return LotteryJackpotNet