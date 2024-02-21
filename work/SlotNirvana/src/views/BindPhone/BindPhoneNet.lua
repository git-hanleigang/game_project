--[[
    绑定手机网络
    author:{author}
    time:2022-11-18 12:18:17
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local BindPhoneNet = class("BindPhoneNet", BaseNetModel)

-- 获取验证码
function BindPhoneNet:reqestBindAction(tbData, succFunc, failFunc)
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

    self:sendActionMessage(ActionType.BindPhone, tbData, successCallFun, failedCallFun)
end

return BindPhoneNet
