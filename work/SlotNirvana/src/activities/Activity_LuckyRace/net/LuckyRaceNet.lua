--[[
    网络请求
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local LuckyRaceNet = class("LuckyRaceNet", BaseNetModel)

function LuckyRaceNet:requestLuckyRaceInfo(_success, _failed)
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
    self:sendActionMessage(ActionType.LuckyRaceRefresh, tbData, successFunc, failedFunc)
end

function LuckyRaceNet:requestCollectReward(_success, _failed)
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
    self:sendActionMessage(ActionType.LuckyRaceCollect, tbData, successFunc, failedFunc)
end

function LuckyRaceNet:requestBuyPromotionBuff(_success, _failed)
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
    self:sendActionMessage(ActionType.LuckyRaceBuyBuff, tbData, successFunc, failedFunc)
end

-- 激活本轮比赛游戏
function LuckyRaceNet:requestActiveCurRaceRound(_success, _failed)
    local function successFunc(resData)
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(errorCode, errorData)
        if _failed then
            _failed(errorCode, errorData)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.LuckyRaceJoin, tbData, successFunc, failedFunc)
end

return LuckyRaceNet
