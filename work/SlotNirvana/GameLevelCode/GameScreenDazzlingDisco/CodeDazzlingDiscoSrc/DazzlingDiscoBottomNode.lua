---
--xcyy
--2018年5月23日
--DazzlingDiscoBottomNode.lua

local DazzlingDiscoBottomNode = class("DazzlingDiscoBottomNode", util_require("views.gameviews.GameBottomNode"))

function DazzlingDiscoBottomNode:updateBetEnable(flag)
    local showPopUpUIFlag = nil
    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE and flag == true then
        showPopUpUIFlag = true
    end
    if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE or self.m_machine.m_isTriggerJackpotReels then
        flag = false
    end
    if showPopUpUIFlag == nil then
        showPopUpUIFlag = flag
    end

    if not self.m_showPopUpUIStates then
        showPopUpUIFlag = false
    end
    --test 特殊需求可以调整bet
    -- if DEBUG == 2 then
    --     flag = true
    -- end
    globalData.betFlag = flag
    self.m_btn_add:setBright(flag)
    self.m_btn_add:setTouchEnabled(flag)
    self.m_btn_sub:setBright(flag)
    self.m_btn_sub:setTouchEnabled(flag)

    self.m_btn_MaxBet:setBright(flag)
    self.m_btn_MaxBet:setTouchEnabled(flag)
    self.m_btn_MaxBet1:setBright(flag)
    self.m_btn_MaxBet1:setTouchEnabled(flag)

    if showPopUpUIFlag and self.m_bCheckShowPopUpUI then
        globalMachineController:checkShowPopUpUI(self.m_machine)
    end
    -- cxc 第一次 放到onEnter中执行
    self.m_bCheckShowPopUpUI = true

    return flag
end

return DazzlingDiscoBottomNode
