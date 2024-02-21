--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local ReturnNet = class("ReturnNet", BaseNetModel)

function ReturnNet:requestCollectSign(_dayIndex, _success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
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
    tbData.data.params.collectDay = _dayIndex
    self:sendActionMessage(ActionType.ReturnSignV2Collect, tbData, successFunc, failedFunc)
end

function ReturnNet:requestCollectTask(_type, _taskId, _success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
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
    tbData.data.params.type = _type
    tbData.data.params.taskId = _taskId
    self:sendActionMessage(ActionType.ReturnTaskCollect, tbData, successFunc, failedFunc)
end

function ReturnNet:requestCollectPass(_level, _type, _success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
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
    tbData.data.params.level = _level
    tbData.data.params.type = _type
    self:sendActionMessage(ActionType.ReturnPassLevelCollect, tbData, successFunc, failedFunc)
end

function ReturnNet:requestWheelSpin(_success, _failed)
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(_result)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(_result)
        end
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if _failed then
            _failed()
        end
    end

    self:sendActionMessage(ActionType.BackWheelPlay, tbData, successCallFun, failedCallFun)
end


-- function ReturnNet:requestCollectReward(_gameId, _chapter, _success, _failed)
--     gLobalViewManager:addLoadingAnimaDelay()
--     -- 返回数据在minigame中解析
--     local function successFunc(resData)
--         gLobalViewManager:removeLoadingAnima()
--         if _success then
--             _success()
--         end
--     end
--     local function failedFunc(target, errorCode, errorData)
--         gLobalViewManager:removeLoadingAnima()
--         release_print(errorCode)
--         if _failed then
--             _failed()
--         end
--     end
--     local tbData = {
--         data = {
--             params = {}
--         }
--     }
--     tbData.data.params.index = _gameId
--     tbData.data.params.chapter = _chapter
--     self:sendActionMessage(ActionType.AdventureRewardData, tbData, successFunc, failedFunc)
-- end

return ReturnNet
