--[[
    respin提示兼计数栏
]]
local CherryBountyTopReSpinTips = class("CherryBountyTopReSpinTips", util_require("base.BaseView"))

function CherryBountyTopReSpinTips:initUI(_machine)
    self.m_machine     = _machine

    self:createCsbNode("CherryBounty_xinxiqu_respin.csb")
    self:initReSpinBar()
end

--计数栏
function CherryBountyTopReSpinTips:initReSpinBar()
    self.m_curTimes   = 0
    self.m_totalTimes = 3

    self.m_respinBar = util_createAnimation("CherryBounty_respinbar.csb")
    self:findChild("Node_respinbar"):addChild(self.m_respinBar)
end
--计数栏-刷新次数
function CherryBountyTopReSpinTips:upDateReSpinBarTimes(_curTimes)
    if _curTimes then
        self.m_curTimes   = _curTimes
    end
    for _times=1,self.m_totalTimes do
        local bVis = _times == self.m_curTimes
        local nodeName = string.format("times_%d_light", _times)
        local spLight = self.m_respinBar:findChild(nodeName)
        spLight:setVisible(bVis)
    end
end
--计数栏-次数重置
function CherryBountyTopReSpinTips:playReSpinBarResetAnim()
    self.m_respinBar:runCsbAction("switch", false)
    self:upDateReSpinBarTimes(self.m_totalTimes)
end


return CherryBountyTopReSpinTips