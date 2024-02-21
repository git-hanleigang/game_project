--[[
    绑定手机网络
    author:{author}
    time:2022-11-18 12:18:17
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local CollectPhoneNet = class("CollectPhoneNet", BaseNetModel)

-- 获取验证码
function CollectPhoneNet:reqestBindAction(tbData, succFunc, failFunc)
    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        if succFunc then
            succFunc(resData)
        end
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
    end

    self:sendActionMessage(ActionType.CollectPhoneProcess, tbData, successCallFun, failedCallFun)
end

return CollectPhoneNet
