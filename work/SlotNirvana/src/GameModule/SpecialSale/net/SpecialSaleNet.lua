--[[
    
    author: 徐袁
    time: 2021-11-26 20:01:16
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local SpecialSaleNet = class("SpecialSaleNet", BaseNetModel)

function SpecialSaleNet:requestFirstSale(_type, successCallFun, failedCallFun)
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
    tbData.data.params.type = _type

    self:sendActionMessage(ActionType.FirstSaleResult, tbData, successFunc, failedFunc)
end

return SpecialSaleNet
