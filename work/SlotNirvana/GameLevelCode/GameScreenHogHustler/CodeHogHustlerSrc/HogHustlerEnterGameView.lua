
local HogHustlerEnterGameView = class("HogHustlerEnterGameView", util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

--fixios0223
function HogHustlerEnterGameView:initUI(data)
    self.m_click = false
    self.m_machine = data

    local resourceFilename = "HogHustler/Tishi.csb"
    self:createCsbNode(resourceFilename)
    -- self:runCsbAction("idle")
    -- self:addClick(self:findChild("Panel_1"))

    self:findChild("root_0"):setScale(self.m_machine.m_machineRootScale)

    self.m_machine:addPopupCommonRole(self)

    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode)
    performWithDelay(self.m_delayNode,function ()
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_prompt_popup_over)
        -- util_spinePlay(role, "over_tanban")
    end, 155/60)
    util_setCascadeOpacityEnabledRescursion(self,true)

    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_prompt_popup_start)
    self:runCsbAction("auto", false, function()
        self:removeFromParent()
    end)
end

function HogHustlerEnterGameView:onEnter()
    HogHustlerEnterGameView.super.onEnter(self)
end

function HogHustlerEnterGameView:onExit()
    HogHustlerEnterGameView.super.onExit(self)
end

function HogHustlerEnterGameView:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_1" then
        if self.m_click == true then
            return
        end
        self:removeSelf()
    end
end

function HogHustlerEnterGameView:removeSelf()
    self.m_delayNode:stopAllActions()
    self.m_click = true
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_prompt_popup_over)
    self:runCsbAction("over", false, function()
        self:removeFromParent()
    end)
end
return HogHustlerEnterGameView