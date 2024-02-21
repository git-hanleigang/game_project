-- 袋鼠底栏-处理spin按钮点击跳过流程
local KangaPocketsGameBottomNode = class("KangaPocketsGameBottomNode", util_require("views.gameviews.GameBottomNode"))

function KangaPocketsGameBottomNode:initUI(...)
    KangaPocketsGameBottomNode.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipBonusBtn = util_createView("CodeKangaPocketsSrc.KangaPocketsSpin")
        spinParent:addChild(self.m_skipBonusBtn, order)
        self.m_skipBonusBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipBonusBtn:setKangaPocketsMachine(self.m_machine)
        self:setSkipBonusBtnVisible(false)
    end
end

function KangaPocketsGameBottomNode:setSkipBonusBtnVisible(_vis)
    if nil ~= self.m_skipBonusBtn then
        self.m_skipBonusBtn:setVisible(_vis)
    end
end

return  KangaPocketsGameBottomNode