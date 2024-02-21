--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local YESMailData = class("YESMailData", BaseClientMailData)

function YESMailData:ctor()
    YESMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function YESMailData:getExpireTime()
    local Data = G_GetActivityDataByRef(ACTIVITY_REF.YearEndSummary)
    if Data then
        return tonumber(Data:getExpireAt())
    else
        return 0
    end
end

return YESMailData