---
--xcyy
--2018年5月23日
--CoinConiferBottomNode.lua

local CoinConiferBottomNode = class("CoinConiferBottomNode",util_require("views.gameviews.GameBottomNode"))

function CoinConiferBottomNode:initUI(...)
    CoinConiferBottomNode.super.initUI(self, ...)
    self.isShowSkipBtn = false
    if nil ~= self.m_spinBtn then
        local spinParent = self.m_spinBtn:getParent()
        local order = self.m_spinBtn:getLocalZOrder() + 1
        self.m_skipBtn = util_createView("CoinConiferSrc.CoinConiferSkipSpinBtn")
        spinParent:addChild(self.m_skipBtn, order)
        self.m_skipBtn:setGuideScale(self.m_spinBtn.m_guideScale)

        self.m_skipBtn:setGeminiJourneMachine(self.m_machine)
        self:setSkipBtnVisible(false)
    end
end

function CoinConiferBottomNode:setSkipBtnVisible(_vis)
    if nil ~= self.m_skipBtn then
        self.m_skipBtn:setVisible(_vis)
        self.isShowSkipBtn = _vis
    end
end

return CoinConiferBottomNode
