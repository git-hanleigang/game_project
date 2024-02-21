local ActivityNetModel = util_require("net.netModel.ActivityNetModel")
local LeagueNetModel = class("LeagueNetModel", ActivityNetModel)

-- 请求竞技场排行榜
function LeagueNetModel:requestRank(_successCB, _bSummit)
    gLobalViewManager:addLoadingAnima(true, 1)
    local successCallFun = function(jsonResult)
        gLobalViewManager:removeLoadingAnima()
        if self:checkMsgErrorInfo(jsonResult) then
            if _successCB then
                _successCB(jsonResult)
            end
        end
    end

    local failedCallFun = function()
        printInfo("ActionType.ArenaRank  failed!!!")
        gLobalViewManager:removeLoadingAnima()
    end

    local reqData = {}
    local actionType = ActionType.ArenaRank
    if _bSummit then
        actionType = ActionType.PeakArenaRank
    end
    self:sendActionMessage(actionType, reqData, successCallFun, failedCallFun)
end

-- 领取竞技场上赛季排行榜奖励
function LeagueNetModel:requestCollectRankReward(_successCB, _bSummit)
    gLobalViewManager:addLoadingAnima(true, 1)
    local successCallFun = function(jsonResult)
        gLobalViewManager:removeLoadingAnima()
        if self:checkMsgErrorInfo(jsonResult) then
            if _successCB then
                _successCB(jsonResult)
            end
        else
            -- 没有奖励
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_REWARD_SUCCESS)
        end
    end

    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        printInfo("ActionType.ArenaRankRewardCollect  failed!!!")
    end
    local reqData = {}
    local actionType = ActionType.ArenaRankRewardCollect
    if _bSummit then
        actionType = ActionType.PeakArenaRankRewardCollect
    end
    self:sendActionMessage(actionType, reqData, successCallFun, failedCallFun)
end

-- 上赛季竞技场排行榜
function LeagueNetModel:requestLastSeasonRank(_successCB, _bSummit)
    gLobalViewManager:addLoadingAnima(true, 1)
    local successCallFun = function(jsonResult)
        if self:checkMsgErrorInfo(jsonResult) and _successCB then
            _successCB(jsonResult)
        end

        gLobalViewManager:removeLoadingAnima()
    end

    local failedCallFun = function()
        printInfo("requestLastSeasonRank failed!!!")
        gLobalViewManager:removeLoadingAnima()
    end

    local reqData = {}
    local actionType = ActionType.ArenaLastSeasonRank
    if _bSummit then
        actionType = ActionType.PeakArenaLastRewardRank
    end
    self:sendActionMessage(actionType, reqData, successCallFun, failedCallFun)
end

-- 上赛季竞技场排行榜
function LeagueNetModel:requestSummitTopRankList(_successCB)
    gLobalViewManager:addLoadingAnima(true, 1)
    local successCallFun = function(jsonResult)
        if self:checkMsgErrorInfo(jsonResult) and _successCB then
            _successCB(jsonResult)
        end

        gLobalViewManager:removeLoadingAnima()
    end

    local failedCallFun = function()
        printInfo("requestSummitTopRankList failed!!!")
        gLobalViewManager:removeLoadingAnima()
    end

    local reqData = {}
    local actionType = ActionType.PeakArenaLastSeasonRank
    self:sendActionMessage(actionType, reqData, successCallFun, failedCallFun)
end

-- 首充降档
function LeagueNetModel:sendLeagueSaleUseGem(_successCB, faildCB)
    gLobalViewManager:addLoadingAnima(true, 1)

    local successCallFun = function(jsonResult)
        gLobalViewManager:removeLoadingAnima()
        if _successCB then
            _successCB(jsonResult)
        end
    end

    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if faildCB then
            faildCB()
        end
    end

    local reqData = {}
    self:sendActionMessage(ActionType.ArenaSaleUseGem, reqData, successCallFun, failedCallFun)
end

-- 检查消息异常
function LeagueNetModel:checkMsgErrorInfo(info)
    if type(info) ~= "table" then
        return false
    end
    local _notice = info.collectResult
    if not _notice then
        return true
    else
        if _notice == "RepeatCollect" then
        elseif _notice == "NoArenaData" then
        elseif _notice == "ArenaRankNotOpen" then
        elseif _notice == "NoArenaRankAward" then
        end
        return false
    end
end

return LeagueNetModel
