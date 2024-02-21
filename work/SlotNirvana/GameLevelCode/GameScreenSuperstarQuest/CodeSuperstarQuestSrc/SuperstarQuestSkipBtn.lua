---
--xcyy
--2018年5月23日
--SuperstarQuestSkipBtn.lua
local SuperstarQuestSkipBtn = class("SuperstarQuestSkipBtn",util_require("base.BaseView"))

function SuperstarQuestSkipBtn:initUI(params)
    self.m_machine = params.machine
    local dcName = ""
    if globalData.slotRunData.isDeluexeClub then
        dcName = "_dc"
    end
    local csbName = "Game/spinBtnNode" .. dcName .. ".csb"
    if globalData.slotRunData.isPortrait == true then
        csbName = "Game/spinBtnNodePortrait" .. dcName .. ".csb"
    end
    self:createCsbNode(csbName)
    self.m_spinBtn = self:findChild("btn_spin")
    self.m_autoBtn = self:findChild("btn_autoBtn")
    self.m_stopBtn = self:findChild("btn_stop")
    self:findChild("btn_spin_specile"):setVisible(false)

    self.m_spinBtn:setVisible(false)
    self.m_autoBtn:setVisible(false)
    self.m_stopBtn:setVisible(true)
    
end

function SuperstarQuestSkipBtn:onEnter()
    SuperstarQuestSkipBtn.super.onEnter(self)
    self:createClickLayer()
end

--[[
    创建压黑层
]]
function SuperstarQuestSkipBtn:createClickLayer()
    --压黑层
    self.m_clickLayer = ccui.Layout:create()
    self.m_clickLayer:setContentSize(self.m_machine.m_clipReelSize)
    self.m_clickLayer:setAnchorPoint(cc.p(0, 0))
    local sp_reel = self.m_machine:findChild("sp_reel_0")
    local pos = util_convertToNodeSpace(sp_reel,self)
    self.m_clickLayer:setPosition(pos)
    self.m_clickLayer:setTouchEnabled(true)
    self.m_clickLayer:setSwallowTouches(false)
    self:addChild(self.m_clickLayer)
    self:addClick(self.m_clickLayer)

    -- self.m_clickLayer:setBackGroundColor(cc.c3b(0, 0, 0))
    -- self.m_clickLayer:setBackGroundColorOpacity(180)
    -- self.m_clickLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end


--默认按钮监听回调
function SuperstarQuestSkipBtn:clickFunc(sender)
    self.m_machine:skipFunc()
end

return SuperstarQuestSkipBtn