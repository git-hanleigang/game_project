--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local PlinkoNet = class("PlinkoNet", BaseNetModel)

-- 激活
function PlinkoNet:requestActiveGame(_gameId, _success, _fail)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then
            _fail()
            return
        end
        _success()
    end
    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        _fail()
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = _gameId
    self:sendActionMessage(ActionType.LuckFishActivate, tbData, successCallback, failedCallback)
end

-- play
function PlinkoNet:requestPlayGame(_gameId, _collisions, _success, _fail)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then
            _fail()
            return
        end
        _success()
    end
    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        _fail()
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = _gameId
    tbData.data.params.collision = table_values(_collisions)
    self:sendActionMessage(ActionType.LuckFishPlay, tbData, successCallback, failedCallback)
end

-- reward
function PlinkoNet:requestCollectGame(_gameId, _success, _fail)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then
            _fail()
            return
        end
        _success()
    end
    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        _fail()
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = _gameId
    self:sendActionMessage(ActionType.LuckFishCollect, tbData, successCallback, failedCallback)
end

return PlinkoNet
