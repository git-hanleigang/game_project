--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:26:58
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/net/TrillionChallengeNet.lua
Description: 亿万赢钱挑战 网络
--]]
local ActionNetModel = require("net.netModel.ActionNetModel")
local TrillionChallengeNet = class("TrillionChallengeNet", ActionNetModel)
local TrillionChallengeConfig = util_require("GameModule.TrillionChallenge.config.TrillionChallengeConfig")

-- 获取最新 排行榜数据
function TrillionChallengeNet:sendGetRankDataReq(_successCb)
    local successFunc = function(_receiveData)
        if type(_receiveData) == "table" and _successCb then
            _successCb(_receiveData)
        end
    end
    local failedFunc = function(_errorCode, errorMsg)
    end

    local reqData = {}
    self.m_timeOutKickOff = false
    self:sendActionMessage(ActionType.TrillionsWinnerChallengeRank, reqData, successFunc, failedFunc)
end

-- 领取奖励
function TrillionChallengeNet:sendCollectReq(_taskOrder)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_receiveData)
        gLobalNoticManager:postNotification(TrillionChallengeConfig.EVENT_NAME.ONRECIEVE_TRILLION_BOX_TASK_COL_SUCCESS, _receiveData) --领取到宝箱奖励
        gLobalViewManager:removeLoadingAnima()
    end

    local failedFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
    end

    local reqData = {
        data = {
            params = {
                taskOrder = -1
            }
        }
    }
    self:sendActionMessage(ActionType.TrillionsWinnerChallengeCollect, reqData, successFunc, failedFunc)
end

return TrillionChallengeNet