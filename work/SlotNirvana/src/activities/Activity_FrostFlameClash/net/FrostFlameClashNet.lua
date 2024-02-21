--[[
    网络请求
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local FrostFlameClashNet = class("FrostFlameClashNet", BaseNetModel)

--膨胀消耗1v1比赛数据刷新
function FrostFlameClashNet:requestRefreshFrostFlameClashInfo(_success, _failed)
    --gLobalViewManager:addLoadingAnima()
    local function successFunc(resData)
        --gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(errorCode, errorData)
        --gLobalViewManager:removeLoadingAnima()
        if _failed then
            _failed(errorCode, errorData)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.FlameClashData, tbData, successFunc, failedFunc)
end

-- 膨胀消耗1v1比赛结算奖励领取
function FrostFlameClashNet:requestCollectReward(_success, _failed)
    gLobalViewManager:addLoadingAnima()
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failed then
            _failed(errorCode, errorData)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.FlameClashReward, tbData, successFunc, failedFunc)
end

-- 膨胀消耗1v1比赛失败保留净胜
function FrostFlameClashNet:requestFlameClashFailedRetain(_success, _failed)
    gLobalViewManager:addLoadingAnima()
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failed then
            _failed(errorCode, errorData)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.FlameClashFailedRetain, tbData, successFunc, failedFunc)
end

-- 膨胀消耗1v1比赛 胜场奖励
function FrostFlameClashNet:requestFlameClashStageReward(_params, _success, _failed)
    gLobalViewManager:addLoadingAnima()
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failed then
            _failed(errorCode, errorData)
        end
    end
    local tbData = {
        data = {
            params = _params or {}
        }
    }
    self:sendActionMessage(ActionType.FlameClashStageCollect, tbData, successFunc, failedFunc)
end

return FrostFlameClashNet
