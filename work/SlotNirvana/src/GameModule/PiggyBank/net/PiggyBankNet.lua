--[[
    网络请求
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local PiggyBankNet = class("PiggyBankNet", BaseNetModel)

function PiggyBankNet:buyFree(_success, _failed)
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        local result = util_cjsonDecode(resData.result)
        if result ~= nil and result ~= "" then
            if result["error"] ~= nil then
                if _failed then
                    _failed()
                end
                return
            end
        end
        if _success then
            _success()
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.PigFreeBuy, tbData, successFunc, failedFunc)
end

return PiggyBankNet
