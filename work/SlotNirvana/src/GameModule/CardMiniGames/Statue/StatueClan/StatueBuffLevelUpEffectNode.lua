local StatueBuffLevelUpEffectNode = class("StatueBuffLevelUpEffectNode", BaseView)
function StatueBuffLevelUpEffectNode:initUI()
    StatueBuffLevelUpEffectNode.super.initUI(self)
end

function StatueBuffLevelUpEffectNode:getCsbName()
    return "CardRes/season202102/Statue/Statue_effect_buff_levelup_Sg.csb"
end

function StatueBuffLevelUpEffectNode:playLevelUp(levelUpOver)
    performWithDelay(self, function()
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueBuffLight)
    end, 1)
    self:runCsbAction("jiesuo", false, function()
        if levelUpOver then
            levelUpOver()
        end
        self:closeUI()
    end, 60)
end

function StatueBuffLevelUpEffectNode:closeUI()
    self:removeFromParent()
end

return StatueBuffLevelUpEffectNode