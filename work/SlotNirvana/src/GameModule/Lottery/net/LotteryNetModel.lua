--[[
Author: cxc
Date: 2021-11-18 20:09:40
LastEditTime: 2022-05-25 17:43:55
LastEditors: bogon
Description: 乐透 网络类
FilePath: /SlotNirvana/src/GameModel/Lottery/net/LotteryNetModel.lua
--]]
local BaseNetModel = import("net.netModel.BaseNetModel")
local LotteryNetModel = class("LotteryNetModel", BaseNetModel)

-- 获取历史记录
function LotteryNetModel:sendHistoryListReq(_successFunc, _faildFunc)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_numberList)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc then
            _successFunc(_numberList)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()

        if _faildFunc then
            _faildFunc()
        end
    end
    local reqData = {}
    self:sendActionMessage(ActionType.LotteryHistory, reqData, successFunc, faildFunc)
end

-- 同步选择的号码到服务器
function LotteryNetModel:sendSyncChooseNumber(_number, _bRandom,_isAuto ,_successFunc, _faildFunc)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(protoResult)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc then
            _successFunc(protoResult)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        
        if _faildFunc then
            _faildFunc()
        end
    end

    local reqData = {
        data = {
            params = {
                number = _number,
                machine = _bRandom,
                auto = _isAuto
            }
        }
    }
    self:sendActionMessage(ActionType.LotterySubmit, reqData, successFunc, faildFunc)
end

-- 服务器生成随机号码
function LotteryNetModel:sendGenerateRanNumber(_successFunc, _faildFunc)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(protoResult)
        gLobalViewManager:removeLoadingAnima()

        local numberList = string.split(protoResult.machineNumber or "", "-")
        if _successFunc then
            _successFunc(numberList)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        
        if _faildFunc then
            _faildFunc()
        end
    end
    local reqData = {}
    self:sendActionMessage(ActionType.LotteryMachine, reqData, successFunc, faildFunc)
end

-- 领奖
function LotteryNetModel:sendCollectReward(_successFunc, _faildFunc)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(protoResult)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc then
            _successFunc()
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        
        if _faildFunc then
            _faildFunc()
        end
    end
    local reqData = {}
    self:sendActionMessage(ActionType.LotteryCollect, reqData, successFunc, faildFunc)
end

return LotteryNetModel
