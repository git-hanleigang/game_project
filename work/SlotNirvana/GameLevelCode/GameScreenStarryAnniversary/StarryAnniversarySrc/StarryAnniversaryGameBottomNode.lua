-- 处理spin按钮点击跳过流程
local StarryAnniversaryGameBottomNode = class("StarryAnniversaryGameBottomNode", util_require("views.gameviews.GameBottomNode"))

function StarryAnniversaryGameBottomNode:initUI(...)
    StarryAnniversaryGameBottomNode.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipBonusBtn = util_createView("StarryAnniversarySrc.StarryAnniversarySpin")
        spinParent:addChild(self.m_skipBonusBtn, order)
        self.m_skipBonusBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipBonusBtn:setKangaPocketsMachine(self.m_machine)
        self:setSkipBonusBtnVisible(false)
    end
end

function StarryAnniversaryGameBottomNode:setSkipBonusBtnVisible(_vis)
    if nil ~= self.m_skipBonusBtn then
        self.m_skipBonusBtn:setVisible(_vis)
    end
end

return  StarryAnniversaryGameBottomNode