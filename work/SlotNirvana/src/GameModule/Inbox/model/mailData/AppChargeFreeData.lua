--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local AppChargeFreeData = class("AppChargeFreeData", BaseClientMailData)

function AppChargeFreeData:ctor()
    AppChargeFreeData.super.ctor(self)
end

-- function AppChargeFreeData:getExpireTime()
--     local data = G_GetMgr(ACTIVITY_REF.NewYearGift):getData()
--     if data then
--         return data:getExpireAt()
--     end
--     return 0
-- end

return AppChargeFreeData