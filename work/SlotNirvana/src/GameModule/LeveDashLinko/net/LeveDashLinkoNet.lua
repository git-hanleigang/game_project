--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local LeveDashLinkoNet = class("LeveDashLinkoNet", BaseNetModel)

-- 激活
function LeveDashLinkoNet:requestActiveGame(_gameId, _success, _fail)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then
            _fail()
            return
        end
        _success(_result)
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
    self:sendActionMessage(ActionType.PearlsLinkActivateGame, tbData, successCallback, failedCallback)
end

-- play
function LeveDashLinkoNet:requestPlayGame(_gameId,_success, _fail)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        _success(_result)
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
    self:sendActionMessage(ActionType.PearlsLinkReSpin, tbData, successCallback, failedCallback)
end

-- reward
function LeveDashLinkoNet:requestCollectGame(_gameId, _success, _fail)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        _success(_result)
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
    self:sendActionMessage(ActionType.PearlsLinkRewards, tbData, successCallback, failedCallback)
end
--paylater
function LeveDashLinkoNet:requestPayLater(_gameId,_success, _fail, _payLevel)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        _success(_result)
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
    tbData.data.params.payLevel = _payLevel
    self:sendActionMessage(ActionType.PearlsLinkPayLater, tbData, successCallback, failedCallback)
end

--paylater
function LeveDashLinkoNet:requestQuietLater(_gameId,_success, _fail)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        _success(_result)
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
    self:sendActionMessage(ActionType.PearlsLinkValidationFinish, tbData, successCallback, failedCallback)
end

return LeveDashLinkoNet
