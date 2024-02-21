--[[
    宠物-预热宣传
]]
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local PetLoadingData = class("PetLoadingData", BaseActivityData)

function PetLoadingData:ctor()
    PetLoadingData.super.ctor(self)
    self.p_open = true
end

return PetLoadingData
