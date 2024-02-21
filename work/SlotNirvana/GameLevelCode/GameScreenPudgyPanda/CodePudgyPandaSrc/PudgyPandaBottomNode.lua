
local PudgyPandaBottomNode = class("PudgyPandaBottomNode", util_require("views.gameviews.GameBottomNode"))

function PudgyPandaBottomNode:initUI(...)
    PudgyPandaBottomNode.super.initUI(self, ...)

    
    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1

        -- 轮盘按钮
        self.m_wheelBtn = util_createView("CodePudgyPandaSrc.PudgyPandaWheelSpinBtn")
        spinParent:addChild(self.m_wheelBtn, order)
        self.m_wheelBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_wheelBtn:setPudgyPandaMachine(self.m_machine)
        self:setWheelBtnVisible(false)
    end
end

-- 轮盘按钮设置
function PudgyPandaBottomNode:setWheelBtnVisible(_vis)
    if nil ~= self.m_wheelBtn then
        self.m_wheelBtn:setVisible(_vis)
    end
end

function PudgyPandaBottomNode:getCoinsShowTimes(winCoin)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local showTime = 2
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 3
    end
    if self.m_machine.collectWheel then
        showTime = 1.5
    end
    return showTime
end

return PudgyPandaBottomNode
