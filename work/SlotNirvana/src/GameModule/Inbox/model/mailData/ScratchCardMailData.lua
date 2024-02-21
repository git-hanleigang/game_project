--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local ScratchCardMailData = class("ScratchCardMailData", BaseClientMailData)

function ScratchCardMailData:ctor()
    ScratchCardMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function ScratchCardMailData:getExpireTime()
    -- inx:索引刮刮卡对应档位信息
    local inx = self.m_index
    local data = G_GetMgr(ACTIVITY_REF.ScratchCards):getData()
    if data then
        local gearPurchase = data:getGearPurchaseByIndex(inx, "inbox")
        if gearPurchase then
            local expireTime = gearPurchase.expirationTime or 0
            return math.max(math.floor(expireTime / 1000), 0)
        else
            return 0
        end
    else
        return 0
    end
end

return ScratchCardMailData