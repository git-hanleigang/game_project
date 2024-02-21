--[[
    
]]

local AvatarGameSmoke = class("AvatarGameSmoke", BaseView)

function AvatarGameSmoke:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_guochang.csb"
end

function AvatarGameSmoke:playStart(_func)
    gLobalSoundManager:playSound("Activity/sound/game/SmokeStart.mp3")
    self:runCsbAction("start", false, function ()
        if _func then 
            _func()
        end
        self:removeFromParent()
    end, 60)
end

return AvatarGameSmoke