--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local FactionFightNet = class("FactionFightNet", BaseNetModel)

function FactionFightNet:selectCamp(_side, _pos)
    local tbData = {
        data = {
            params = {
                side = _side,
                pos = _pos
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_SELECT_CAMP, false)
            return
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_SELECT_CAMP, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_SELECT_CAMP, false)
    end

    self:sendActionMessage(ActionType.FactionFightSideSelect,tbData,successCallback,failedCallback)
end

function FactionFightNet:passCollect(_index)
    local tbData = {
        data = {
            params = {
                position = _index
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_COLLECT, false)
            return
        end
        _result.index = _index
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_COLLECT, _result)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_COLLECT, false)
    end

    self:sendActionMessage(ActionType.FactionFightCollect,tbData,successCallback,failedCallback)
end

function FactionFightNet:dataRefresh()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_DATA_REFRESH, false)
            return
        end

        local gameData = G_GetMgr(ACTIVITY_REF.FactionFight):getRunningData()
        if gameData then    
            gameData:refreshData(_result)
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_DATA_REFRESH, _result)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_DATA_REFRESH, false)
    end

    self:sendActionMessage(ActionType.FactionFightRefresh,tbData,successCallback,failedCallback)
end

function FactionFightNet:requestRankData()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_RANK, false)
            return
        end
        local gameData = G_GetMgr(ACTIVITY_REF.FactionFight):getRunningData()
        if gameData then
            gameData:parseRankData(_result)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_RANK, true)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_RANK, false)
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_RANK, false)
    end

    self:sendActionMessage(ActionType.FactionFightRank,tbData,successCallback,failedCallback)
end

-- 付费
function FactionFightNet:buyBuff(_data)
    local tbData = {
        data = {
            params = {
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_BUFF_BUY, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_BUFF_BUY, false)
    end

    self:sendActionMessage(ActionType.FactionFightBuySale,tbData,successCallback,failedCallback)
end

return FactionFightNet