--[[
    OTP链接登陆code
    author:{author}
    time:2023-12-25 20:20:08
]]
local AChargeOtpCodeLayer = class("AChargeOtpCodeLayer", BaseLayer)

function AChargeOtpCodeLayer:initDatas(code)
    self.m_code = code
    self:setLandscapeCsbName("Dialog/OTP_Layer.csb")
end

function AChargeOtpCodeLayer:initCsbNodes()
    self.m_txtNums = {}
    for i = 1, 4 do
        self.m_txtNums[i] = self:findChild("lb_num" .. i)
    end
end

-- function AChargeOtpCodeLayer:onEnter()
--     AChargeOtpCodeLayer.super.onEnter(self)
-- end

function AChargeOtpCodeLayer:updateCode(code)
    self.m_code = code or "    "

    for i = 1, #(self.m_txtNums or {}) do
        local _c = string.sub(self.m_code, i, i)
        self.m_txtNums[i]:setString(_c)
    end
end

function AChargeOtpCodeLayer:clickFunc(sender)
    local btnName = sender:getName()
    if btnName == "btn_close" then
        self:closeUI()
    end
end

return AChargeOtpCodeLayer