--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local AppChargePayData = class("AppChargePayData", BaseClientMailData)

function AppChargePayData:ctor()
    AppChargePayData.super.ctor(self)
end

-- function AppChargePayData:getExpireTime()
--     local data = G_GetMgr(ACTIVITY_REF.NewYearGift):getData()
--     if data then
--         return data:getExpireAt()
--     end
--     return 0
-- end

return AppChargePayData