
local PalaceWishTipsCommonView = class("PalaceWishTipsCommonView", util_require("Levels.BaseLevelDialog"))

local TipStatus = {
    START = 1,
    IDLE = 2,
    OVER = 3,
    NOTHING = 4,
}
local IDLE_TIME = 5
local default_csb_name = "PalaceWish_jindutiao_tips.csb"

--_isGlobalTouch 弹出气泡是否可点击
function PalaceWishTipsCommonView:initUI(_machine, _resourceName, _isGlobalTouch)
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

function PalaceWishTipsCommonView:onEnter()
    PalaceWishTipsCommonView.super.onEnter(self)
end

function PalaceWishTipsCommonView:onExit()
    PalaceWishTipsCommonView.super.onExit(self)
end

function PalaceWishTipsCommonView:clickFunc(sender)
    local name = sender:getName()
    if self.m_isGlobalTouch then
        if name == "Panel_tipClick" then
            self:TipClick()
        end
    end
    
end

--点击操作 只有nothing idle 点击有效果
function PalaceWishTipsCommonView:TipClick()
    if self.m_status == TipStatus.NOTHING then
        self:setVisible(true)
        self.m_status = TipStatus.START
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_prompt_popup_start.mp3")
        self:runCsbAction("start", false, function()
            self.m_status = TipStatus.IDLE
            self:runCsbAction("idle", true)
            performWithDelay(self.m_delayNode,function ()
                if self.m_status == TipStatus.IDLE then
                    self.m_status = TipStatus.OVER
                    -- gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_prompt_popup_over.mp3")
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
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_prompt_popup_over.mp3")
        self:runCsbAction("over", false, function()
            self.m_delayNode:stopAllActions()
            self:setVisible(false)
            self.m_status = TipStatus.NOTHING
        end)
    end
    
end

function PalaceWishTipsCommonView:hideTips(  )
    if self.m_status == TipStatus.IDLE or self.m_status == TipStatus.START then
        self:runCsbAction("over", false, function()
            self.m_delayNode:stopAllActions()
            self:setVisible(false)
            self.m_status = TipStatus.NOTHING
        end)
    end
end

return PalaceWishTipsCommonView