--[[
    Echo Win
]]

local ShopLoadingControl = class("ShopLoadingControl", BaseActivityControl)

function ShopLoadingControl:ctor()
    ShopLoadingControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ShopLoading)
end

return ShopLoadingControl
