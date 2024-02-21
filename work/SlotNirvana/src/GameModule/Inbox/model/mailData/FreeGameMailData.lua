--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local FreeGameMailData = class("FreeGameMailData", BaseClientMailData)

function FreeGameMailData:ctor()
    FreeGameMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = false
end

-- function FreeGameMailData:getExpireTime()
--     --无数据或者过期了
--     local freeSpinData = globalData.iapRunData:getFreeGameData()
--     local ticketData = freeSpinData:getRewardsById( self.ticketId )
--     if not ticketData or ticketData:isOverdue() then
--         return 0
--     end

--     if ticketData:isActive() then
--         return -100
--     else
--         return ticketData.expireAt
--     end
-- end

return FreeGameMailData