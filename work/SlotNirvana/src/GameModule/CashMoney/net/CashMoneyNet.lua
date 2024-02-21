--[[
Author: dhs
Date: 2022-04-19 11:14:52
LastEditTime: 2022-04-19 11:14:52
LastEditors: your name
Description: CashMoney 道具通用化 网络层
FilePath: /SlotNirvana/src/GameModule/CashMoney/net/CashMoneyNet.lua
--]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local CashMoneyNet = class("CashMoneyNet", BaseNetModel)

function CashMoneyNet:sendCashMoneyPlay(_gameId, _successCall, _failedCall)
    local tbData = {
        data = {
            params = {}
        }
    }
    gLobalViewManager:addLoadingAnimaDelay()

    local successCallBack = function(_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then
            if _failedCall then
                _failedCall()
            end
            return
        end

        if _successCall then
            _successCall(_result)
        end
    end

    local failedCallBack = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode, errorData)
        local logMsg = "errorCode:" .. errorCode .. ",errorData:" .. errorData
        util_sendToSplunkMsg("CashMoneyRequestPlayFailed", errorData)

        if _failedCall then
            _failedCall()
        end
    end

    tbData.data.params.index = _gameId -- CashMoney 游戏ID
    self:sendActionMessage(ActionType.CashMoneyPlay, tbData, successCallBack, failedCallBack)
end
-- 领奖协议
function CashMoneyNet:sendCashMoneyCollect(_gameId, _successCall, _failedCall)
    local tbData = {
        data = {
            params = {}
        }
    }
    gLobalViewManager:addLoadingAnimaDelay()

    local successCallBack = function(_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then
            if _failedCall then
                _failedCall()
            end
            return
        end

        if _successCall then
            _successCall(_result)
        end
    end

    local failedCallBack = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode, errorData)
        local logMsg = "errorCode:" .. errorCode .. ",errorData:" .. errorData
        util_sendToSplunkMsg("CashMoneyRequestPlayFailed", errorData)

        if _failedCall then
            _failedCall()
        end
    end

    tbData.data.params.index = _gameId -- CashMoney 游戏ID
    self:sendActionMessage(ActionType.CashMoneyCollect, tbData, successCallBack, failedCallBack)
end

function CashMoneyNet:sendCashMoneyClear(_gameId, _successCall, _failedCall)
    local tbData = {
        data = {
            params = {}
        }
    }
    gLobalViewManager:addLoadingAnimaDelay()

    local successCallBack = function(_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then
            if _failedCall then
                _failedCall()
            end
            return
        end

        if _successCall then
            _successCall(_result)
        end
    end

    local failedCallBack = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode, errorData)
        local logMsg = "errorCode:" .. errorCode .. ",errorData:" .. errorData
        util_sendToSplunkMsg("CashMoneyRequestPlayFailed", errorData)

        if _failedCall then
            _failedCall()
        end
    end

    tbData.data.params.index = _gameId -- CashMoney 游戏ID
    self:sendActionMessage(ActionType.CashMoneyClear, tbData, successCallBack, failedCallBack)
end

function CashMoneyNet:sendSaveTakeStatusRequest(_gameId, _status)
    local tbData = {
        data = {
            params = {}
        }
    }
    gLobalViewManager:addLoadingAnimaDelay()

    local successCallBack = function(_result)
        gLobalViewManager:removeLoadingAnima()
    end

    local failedCallBack = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode, errorData)
        local logMsg = "errorCode:" .. errorCode .. ",errorData:" .. errorData
        util_sendToSplunkMsg("CashMoneyRequestSaveTakeFailed", errorData)
    end

    tbData.data.params.index = _gameId
    tbData.data.params.take = tostring(_status)
    self:sendActionMessage(ActionType.CashMoneyTake, tbData, successCallBack, failedCallBack)
end

return CashMoneyNet
