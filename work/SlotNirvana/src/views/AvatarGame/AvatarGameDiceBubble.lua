--[[
    
]]

local AvatarGameDiceBubble = class("AvatarGameDiceBubble", BaseView)

function AvatarGameDiceBubble:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_qipao.csb"
end

function AvatarGameDiceBubble:playStart(_callback)
    self:runCsbAction("start", false, function ()
        performWithDelay(self, function ()
            self:runCsbAction("over", false, function ()
                if _callback then 
                    _callback()
                end
            end, 60)
        end, 2)
    end, 60)
end

return AvatarGameDiceBubble