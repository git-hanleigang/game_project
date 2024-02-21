
local HogHustlerTipsView = class("HogHustlerTipsView", util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

local TipStatus = {
    START = 1,
    IDLE = 2,
    OVER = 3,
    NOTHING = 4,
}
local IDLE_TIME = 2
local default_csb_name = "HogHustler_dafuwentips.csb"

--_isGlobalTouch 弹出气泡是否可点击
function HogHustlerTipsView:initUI(_machine, _resourceName, _isGlobalTouch)
    self.m_click = false
    self.m_machine = _machine
    self.m_status = TipStatus.NOTHING
    self.m_isGlobalTouch = _isGlobalTouch

    local resourceFilename = _resourceName or default_csb_name
    self:createCsbNode(resourceFilename)
    
    if self.m_isGlobalTouch then
        self:addClick(self:findChild("Panel_tipClick"))
        self:findChild("Panel_tipClick"):setSwallowTouches(false)
    end
    

    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode)

end

function HogHustlerTipsView:onEnter()
    HogHustlerTipsView.super.onEnter(self)
end

function HogHustlerTipsView:onExit()
    HogHustlerTipsView.super.onExit(self)
end

function HogHustlerTipsView:clickFunc(sender)
    local name = sender:getName()
    if self.m_isGlobalTouch then
        if name == "Panel_tipClick" then
            self:TipClick()
        end
    end
    
end

--点击操作 只有nothing idle 点击有效果
function HogHustlerTipsView:TipClick()
    if self.m_status == TipStatus.NOTHING then
        self:setVisible(true)
        self.m_status = TipStatus.START
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_prompt_popup_start)
        self:runCsbAction("start", false, function()
            self.m_status = TipStatus.IDLE
            self:runCsbAction("idle", true)
            performWithDelay(self.m_delayNode,function ()
                if self.m_status == TipStatus.IDLE then
                    self.m_status = TipStatus.OVER
                    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_prompt_popup_over)
                    self:runCsbAction("over", false, function()
                        self:setVisible(false)
                        self.m_status = TipStatus.NOTHING
                    end)
                end
            end, IDLE_TIME)
        end)
    elseif self.m_status == TipStatus.IDLE then
        self.m_delayNode:stopAllActions()
        self.m_status = TipStatus.OVER
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_prompt_popup_over)
        self:runCsbAction("over", false, function()
            self.m_delayNode:stopAllActions()
            self:setVisible(false)
            self.m_status = TipStatus.NOTHING
        end)
    end
    
end

return HogHustlerTipsView