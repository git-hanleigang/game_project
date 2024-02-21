--[[
    
    author: 徐袁
    time: 2021-11-26 20:01:16
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local GPBonusNet = class("GPBonusNet", BaseNetModel)

function GPBonusNet:requestPickStar(idx, pos, successCallFun, failedCallFun)
    local failedFunc = function()
        if failedCallFun then
            failedCallFun()
        end
    end

    local successFunc = function(resJson)
        if successCallFun then
            successCallFun(resJson)
        end
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = idx
    -- lua中table初始索引是1
    tbData.data.params.pos = math.max(pos - 1, 0)

    self:sendActionMessage(ActionType.PickStarData, tbData, successFunc, failedFunc)
end

return GPBonusNet
