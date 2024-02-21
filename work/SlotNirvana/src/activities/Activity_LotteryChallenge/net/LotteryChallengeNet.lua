--[[
Author: cxc
Date: 2022-01-10 14:58:10
LastEditTime: 2022-01-10 14:58:26
LastEditors: your name
Description: Lottery乐透 挑战活动 网络模块
FilePath: /SlotNirvana/src/activities/Activity_LotteryChallenge/net/LotteryChallengeNet.lua
--]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local LotteryChallengeNet = class("LotteryChallengeNet", BaseNetModel)

function LotteryChallengeNet:sendCollectReq(_successFunc)
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_rewardList)
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
    self:sendActionMessage(ActionType.LotteryChallengeCollect, tbData, successCallback, failedCallback)
end

return LotteryChallengeNet