--[[
Author: cxc
Date: 2022-03-23 16:02:41
LastEditTime: 2022-03-23 16:02:42
LastEditors: cxc
Description: 3日行为付费聚合活动  网络类
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/net/WildChallengeNet.lua
--]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local WildChallengeNet = class("WildChallengeNet", BaseNetModel)
local WildChallengeConfig = require("activities.Activity_WildChallenge.config.WildChallengeConfig")

-- 周卡领取奖励
function WildChallengeNet:sendCollectReq(_idx, _bNovice)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            -- 失败
            return
        end
        gLobalNoticManager:postNotification(WildChallengeConfig.EVENT_NAME.WILD_CHALLENGE_COLLECT_SUCCESS, _idx)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(WildChallengeConfig.EVENT_NAME.WILD_CHALLENGE_COLLECT_FAILD, _idx)
    end

    local actionType = ActionType.WildChallengeCollect
    if _bNovice then
        actionType = ActionType.NewUserWildChallengeCollect
    end
    self:sendActionMessage(actionType, nil, successCallback, failedCallback)
end

return WildChallengeNet 