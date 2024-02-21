--[[
    集卡赛季末聚合
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local ChaseForChipsNet = class("ChaseForChipsNet", BaseNetModel)

function ChaseForChipsNet:requestInfo(successCallFun, failedCallFun)
    gLobalViewManager:addLoadingAnimaDelay()
    local failedFunc = function(p1, p2, p3)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFun then
            failedCallFun()
        end
    end
    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        local result = util_cjsonDecode(resJson.result)
        if result ~= nil and result ~= "" and result["error"] ~= nil then
            if failedCallFun then
                failedCallFun()
            end
            return
        end
        if successCallFun then
            successCallFun(resJson)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.ChaseForChipsInfo, tbData, successFunc, failedFunc)
end

function ChaseForChipsNet:requestCollectReward(_index, _isFree, successCallFun, failedCallFun)
    gLobalViewManager:addLoadingAnimaDelay()
    local failedFunc = function(p1, p2, p3)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFun then
            failedCallFun()
        end
    end
    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successCallFun then
            successCallFun(resJson)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = _index
    tbData.data.params.free = _isFree
    self:sendActionMessage(ActionType.ChaseForChipsCollectReward, tbData, successFunc, failedFunc)
end

return ChaseForChipsNet
