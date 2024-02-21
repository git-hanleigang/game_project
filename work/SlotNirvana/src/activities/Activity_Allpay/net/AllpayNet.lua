-- 气球挑战 网络消息处理

local AllpayNet = class("AllpayNet", util_require("baseActivity.BaseActivityManager"))

function AllpayNet:getInstance()
    if self.instance == nil then
        self.instance = AllpayNet.new()
    end
    return self.instance
end

-- 发送获取字母消息
function AllpayNet:requestUpdate()
    self:sendMsgBaseFunc(ActionType.AccumulatedRechargeGet, "Allpay")
end

return AllpayNet
