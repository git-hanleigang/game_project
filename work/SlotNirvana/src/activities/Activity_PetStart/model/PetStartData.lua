--[[
    宠物-开启宣传
]]
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local PetStartData = class("PetStartData", BaseActivityData)

function PetStartData:ctor()
    PetStartData.super.ctor(self)
    self.p_open = true
end

return PetStartData
