--[[
    完成任务装饰圣诞树
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local MissionsToDIYNet = class("MissionsToDIYNet", BaseNetModel)

function MissionsToDIYNet:sendCollect(_index, _selections)
    local tbData = {
        data = {
            params = {
                order = _index,
                selections = _selections
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        if _index > 0 then
            G_GetMgr(ACTIVITY_REF.MissionsToDIY):saveDecorateSelect(_index, "a")
        end

        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.MISSIONS_TO_DIY_COLLECT, {success = true, index = _index})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.MISSIONS_TO_DIY_COLLECT, {})
    end

    self:sendActionMessage(ActionType.MissionsToDiyTaskReward,tbData,successCallback,failedCallback)
end

function MissionsToDIYNet:sendRefreshData()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima()

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.MISSIONS_TO_DIY_REFRESH_DATA)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.MISSIONS_TO_DIY_REFRESH_DATA)
    end

    self:sendActionMessage(ActionType.MissionsToDiyRefreshData,tbData,successCallback,failedCallback)
end

function MissionsToDIYNet:setSaveData(_saveData)
    local tbData = {
        data = {
            params = {
                steer = _saveData
            }
        }
    }

    local successCallback = function (_result)
    end

    local failedCallback = function (errorCode, errorData)
    end

    self:sendActionMessage(ActionType.MissionsToDiySaveSteer,tbData,successCallback,failedCallback)
end

return MissionsToDIYNet
