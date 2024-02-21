--[[
    集卡倒计时
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local cardEndCountdownData = class("cardEndCountdownData", BaseActivityData)

function cardEndCountdownData:ctor(_data)
    cardEndCountdownData.super.ctor(self, _data)
    self.p_open = true
end

function cardEndCountdownData:parseNormalActivityData(_data)
    cardEndCountdownData.super.parseNormalActivityData(self, _data)
    self.p_curTheme = self:getThemeName()
    -- self:setThemeName(self:getRefName())
    self.p_openLevel = 20
end

function cardEndCountdownData:getCurThemeName()
    if self.p_curTheme then
        return self.p_curTheme
    else
        return self:getRefName()
    end
end

function cardEndCountdownData:isRunning()
    if not cardEndCountdownData.super.isRunning(self) then
        return false
    end

    local novice = globalData:isCardNovice()
    if novice then
        return false
    end
    return true

end

return cardEndCountdownData
