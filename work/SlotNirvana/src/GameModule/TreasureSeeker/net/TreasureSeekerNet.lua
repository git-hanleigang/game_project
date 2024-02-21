--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local TreasureSeekerNet = class("TreasureSeekerNet", BaseNetModel)

-- AdventurePlay = 227;//4选1小游戏play
-- AdventureRewardData = 228;//4选1小游戏领奖
-- AdventureGemConsume = 229;//4选1小游戏消耗宝石
-- AdventureClearData = 231;//4选1小游戏清除数据
function TreasureSeekerNet:requestOpenBox(_gameId, _chapter, _pos, _success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success()
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = _gameId
    tbData.data.params.pos = _pos
    tbData.data.params.chapter = _chapter
    self:sendActionMessage(ActionType.AdventurePlay, tbData, successFunc, failedFunc)
end

function TreasureSeekerNet:requestCollectReward(_gameId, _chapter, _success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success()
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = _gameId
    tbData.data.params.chapter = _chapter
    self:sendActionMessage(ActionType.AdventureRewardData, tbData, successFunc, failedFunc)
end

function TreasureSeekerNet:requestCostGem(_gameId, _chapter, _success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success()
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = _gameId
    tbData.data.params.chapter = _chapter
    self:sendActionMessage(ActionType.AdventureGemConsume, tbData, successFunc, failedFunc)
end

function TreasureSeekerNet:requestGiveUp(_gameId, _chapter, _success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success()
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = _gameId
    tbData.data.params.chapter = _chapter
    self:sendActionMessage(ActionType.AdventureClearData, tbData, successFunc, failedFunc)
end

return TreasureSeekerNet
