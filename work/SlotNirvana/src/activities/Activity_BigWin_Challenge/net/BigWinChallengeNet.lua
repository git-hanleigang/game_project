--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local BigWinChallengeNet = class("BigWinChallengeNet", BaseNetModel)

--分享
function BigWinChallengeNet:requestCollect(successCallFun, failedCallFun, _index)
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
            params = {
                index = _index,
            }
        }
    }
    self:sendActionMessage(ActionType.BigWinChallengeCollect, tbData, successFunc, failedFunc)
end

return BigWinChallengeNet
