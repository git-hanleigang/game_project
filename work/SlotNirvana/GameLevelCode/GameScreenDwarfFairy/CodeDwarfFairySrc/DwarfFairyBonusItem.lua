---
--smy
--2018年4月26日
--BonusItem.lua

local BonusItem = class("BonusItem",util_require("base.BaseView"))

function BonusItem:initUI()
    self:createCsbNode("DwarfFairy_coins.csb")
    self:runCsbAction("idle")
end

function BonusItem:onEnter()

end

function BonusItem:onExit()

end

function BonusItem:runAnimation(animatin, isLoop, func)
    self:runCsbAction(animatin, isLoop, function()
        if func ~= nil then
            func()
        end
    end)
end

function BonusItem:startTurn(delayTime, isTurn)
    local callback = nil
    local animation = "show1"
    if isTurn == true then
        animation = "show2"
    end
    performWithDelay(self, function()
        self:runAnimation(animation)
        if isTurn == true then
            performWithDelay(self, function()
                gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_rotate_over_"..self.m_index..".mp3")
            end, 3.3)
        end
    end, delayTime)
    
end

function BonusItem:setTurnID(index)
    self.m_index = index
end

return BonusItem