-- 美杜莎底栏-处理spin按钮点击跳过流程
local MedusaManiaBottomNode = class("MedusaManiaBottomNode", util_require("views.gameviews.GameBottomNode"))

function MedusaManiaBottomNode:initUI(...)
    MedusaManiaBottomNode.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipBtn = util_createView("CodeMedusaManiaSrc.MedusaManiaSkipSpinBtn")
        spinParent:addChild(self.m_skipBtn, order)
        self.m_skipBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipBtn:setMedusaManiaMachine(self.m_machine)
        self:setSkipBtnVisible(false)
    end
end

function MedusaManiaBottomNode:setSkipBtnVisible(_vis)
    if nil ~= self.m_skipBtn then
        self.m_skipBtn:setVisible(_vis)
    end
end

return MedusaManiaBottomNode
