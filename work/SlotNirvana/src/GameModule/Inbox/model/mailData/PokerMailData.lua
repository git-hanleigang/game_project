--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local PokerMailData = class("PokerMailData", BaseClientMailData)

function PokerMailData:ctor()
    PokerMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

-- 重点关注：移植过来的，应该是不对的，应该判断poker数据
function PokerMailData:getExpireTime()
    local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
    if levelDashData then 
        return tonumber(levelDashData.p_endDayExpireAt / 1000)
    else
        return 0
    end
end

return PokerMailData