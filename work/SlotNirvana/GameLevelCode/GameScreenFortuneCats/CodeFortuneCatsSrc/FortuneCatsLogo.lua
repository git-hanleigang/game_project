---
--xcyy
--2018年5月23日
--FortuneCatsLogo.lua

local FortuneCatsLogo = class("FortuneCatsLogo",util_require("base.BaseView"))


function FortuneCatsLogo:initUI()
    self:createCsbNode("FortuneCats_Logo_Panel.csb")

    self.m_cat = util_spineCreate("FortuneCatsLogo", true, true)
    self:addChild(self.m_cat)
    util_spinePlay(self.m_cat, "idle1", true)
    self:addClick(self:findChild("Panel_1")) -- 非按钮节点得手动绑定监听
end


function FortuneCatsLogo:onEnter()

end

function FortuneCatsLogo:onExit()
 
end

--默认按钮监听回调
function FortuneCatsLogo:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_1" then
        if self:canClick() then
            gLobalNoticManager:postNotification("SHOW_SHOP")
        end
    end
end

function FortuneCatsLogo:setBaseMachine(machine)
    self.m_baseMachine = machine
end

function FortuneCatsLogo:canClick()
    local isFreespin = self.m_baseMachine.m_bProduceSlots_InFreeSpin == true
    local isNormalNoIdle = self.m_baseMachine:getCurrSpinMode() == NORMAL_SPIN_MODE and self.m_baseMachine:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self.m_baseMachine:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self.m_baseMachine:getGameSpinStage() ~= IDLE
    local isRunningEffect = self.m_baseMachine.m_isRunningEffect == true
    local isAutoSpin = self.m_baseMachine:getCurrSpinMode() == AUTO_SPIN_MODE
    local isInRespin = self.m_baseMachine.m_addRepin == true
    local isRespin = self.m_baseMachine:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true
    if isFreespin or isNormalNoIdle or isFreespinOver or isRunningEffect or isAutoSpin or isInRespin or isRespin then
        return false
    end
    return true
end

return FortuneCatsLogo