--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local CommonJackpotNet = class("CommonJackpotNet", BaseNetModel)

function CommonJackpotNet:requestStart(_key, _levelName, successCallFun, failedCallFun)
    gLobalViewManager:addLoadingAnimaDelay()
    local failedFunc = function(p1, p2, p3)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFun then
            failedCallFun()
        end
    end
    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if resJson.result ~= nil and resJson.result ~= "" then
            local result = util_cjsonDecode(resJson.result)
            if result and result["error"] ~= nil then
                if failedCallFun then
                    failedCallFun()
                end
                return
            end
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
    tbData.data.params.key = _key
    tbData.data.params.game = _levelName
    self:sendActionMessage(ActionType.JillionJackpotPlay, tbData, successFunc, failedFunc)
end

return CommonJackpotNet
