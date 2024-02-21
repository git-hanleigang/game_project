--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local NewYearGiftMailData = class("NewYearGiftMailData", BaseClientMailData)

function NewYearGiftMailData:ctor()
    NewYearGiftMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function NewYearGiftMailData:getExpireTime()
    local data = G_GetMgr(ACTIVITY_REF.NewYearGift):getData()
    if data then
        return data:getExpireAt()
    end
    return 0
end

return NewYearGiftMailData