-- 处理spin按钮点击跳过流程
local BeastlyBeautyBottomUI = class("BeastlyBeautyBottomUI", util_require("views.gameviews.GameBottomNode"))

function BeastlyBeautyBottomUI:initUI(...)
    BeastlyBeautyBottomUI.super.initUI(self, ...)

    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipBonusBtn = util_createView("CodeBeastlyBeautySrc.BeastlyBeautySpinBtn")
        spinParent:addChild(self.m_skipBonusBtn, order)
        self.m_skipBonusBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipBonusBtn:setKangaPocketsMachine(self.m_machine)
        self:setSkipBonusBtnVisible(false)
    end
end

function BeastlyBeautyBottomUI:setSkipBonusBtnVisible(_vis)
    if nil ~= self.m_skipBonusBtn then
        self.m_skipBonusBtn:setVisible(_vis)
    end
end

return BeastlyBeautyBottomUI