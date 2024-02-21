--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local CrazyCartNet = class("CrazyCartNet", BaseNetModel)

--分享
function CrazyCartNet:requestShare(successCallFun, failedCallFun)
    gLobalViewManager:addLoadingAnimaDelay()
    local failedFunc = function()
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
    self:sendActionMessage(ActionType.CrazyShoppingCartShare, tbData, successFunc, failedFunc)
end

--领奖
function CrazyCartNet:requestCollect(successCallFun, failedCallFun)
    gLobalViewManager:addLoadingAnimaDelay()
    local failedFunc = function()
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
    self:sendActionMessage(ActionType.CrazyShoppingCartCollect, tbData, successFunc, failedFunc)
end

return CrazyCartNet
