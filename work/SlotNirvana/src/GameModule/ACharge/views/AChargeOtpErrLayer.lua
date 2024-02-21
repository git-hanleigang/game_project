--[[
    OTP链接登陆code
    author:{author}
    time:2023-12-25 20:20:08
]]
local AChargeOtpErrLayer = class("AChargeOtpErrLayer", BaseLayer)

function AChargeOtpErrLayer:initDatas(errCode)
    self.m_errCode = errCode
    self:setLandscapeCsbName("Dialog/OTP_Fail.csb")
end

function AChargeOtpErrLayer:initView()
    self:setButtonLabelContent("btn_submit", "BACK")
end

function AChargeOtpErrLayer:clickFunc(sender)
    local btnName = sender:getName()
    if btnName == "btn_submit" then
        self:closeUI()
    end
end

return AChargeOtpErrLayer
