--[[
    
]]

local AvatarGameInfoLayer = class("AvatarGameInfoLayer", BaseLayer)

function AvatarGameInfoLayer:ctor()
    AvatarGameInfoLayer.super.ctor(self)

    self:setLandscapeCsbName("Activity/csb/Cash_dice/CashDice_info.csb")
    self:setExtendData("AvatarGameInfoLayer")
end

function AvatarGameInfoLayer:clickFunc(_sander)
    self:closeUI()
end

return AvatarGameInfoLayer