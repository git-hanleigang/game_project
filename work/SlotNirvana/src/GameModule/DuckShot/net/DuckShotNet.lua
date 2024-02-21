--[[
    DuckShotNet
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local DuckShotNet = class("DuckShotNet", BaseNetModel)

function DuckShotNet:getInstance()
    if self.instance == nil then
        self.instance = DuckShotNet.new()
    end
    return self.instance
end

-- 发射
function DuckShotNet:sendCollect(_index)
    local tbData = {
        data = {
            params = {
                index = _index
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_FIRE_BULLET, false)
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_FIRE_BULLET, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_FIRE_BULLET, false)
    end

    self:sendActionMessage(ActionType.DuckShotCollect,tbData,successCallback,failedCallback)
end

-- 命中
function DuckShotNet:sendBulletHit(params)
    local tbData = {
        data = {
            params = params
        }
    }
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_BULLET_HIT, params)

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_BULLET_HIT, false)
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_BULLET_HIT, params)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_BULLET_HIT, false)
    end

    self:sendActionMessage(ActionType.DuckShotHit,tbData,successCallback,failedCallback)
end

-- 关闭
function DuckShotNet:sendPayClose(_index)
    local tbData = {
        data = {
            params = {
                index = _index
            }
        }
    }

    local successCallback = function (_result)

    end

    local failedCallback = function (errorCode, errorData)

    end

    self:sendActionMessage(ActionType.DuckShotClear,tbData,successCallback,failedCallback)
end

-- 激活
function DuckShotNet:sendGamePlay(_index)
    local tbData = {
        data = {
            params = {
                index = _index
            }
        }
    }
    
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_ACTIVATE, false)
            return
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_ACTIVATE, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DUCKSHOT_ACTIVATE, false)
    end

    self:sendActionMessage(ActionType.DuckShotPlay,tbData,successCallback,failedCallback)
end

return DuckShotNet
