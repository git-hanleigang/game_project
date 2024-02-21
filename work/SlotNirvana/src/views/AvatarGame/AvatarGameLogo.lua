--[[
    
]]

local AvatarGameLogo = class("AvatarGameLogo", BaseView)

function AvatarGameLogo:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_logo.csb"
end

function AvatarGameLogo:initUI()
    AvatarGameLogo.super.initUI(self)

    self:runCsbAction("idle", true, nil, 60)
end

return AvatarGameLogo