---
--xcyy
--2018年5月23日
--RobinIsHoodSkipBtn.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodSkipBtn = class("RobinIsHoodSkipBtn",util_require("base.BaseView"))

function RobinIsHoodSkipBtn:initUI(params)
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


--默认按钮监听回调
function RobinIsHoodSkipBtn:clickFunc(sender)
    self.m_machine:skipCollectBonus()
end

return RobinIsHoodSkipBtn