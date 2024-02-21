
local FlamingPompeiiReSpinBarView = class("FlamingPompeiiReSpinBarView",util_require("Levels.BaseLevelDialog"))


function FlamingPompeiiReSpinBarView:initUI()
    self:createCsbNode("FlamingPompeii_spinTimesBar.csb")
    
    self:findChild("reSpin"):setVisible(true)

    self.m_curReSpinCount = 0
    self.m_totalReSpinCount = 0
end
--[[
    次数刷新
]]
function FlamingPompeiiReSpinBarView:showTimes(_curTimes, _totalTimes)
    self.m_curReSpinCount = _curTimes
    local leftLab  = self:findChild("m_lb_reSpinNum_1")
    leftLab:setString(_curTimes)
    self:updateLabelSize({label=leftLab,  sx=1, sy=1}, 50)
    
    self.m_totalReSpinCount = _totalTimes
    local rightLab = self:findChild("m_lb_reSpinNum_2")
    rightLab:setString(_totalTimes)
    self:updateLabelSize({label=rightLab,  sx=1, sy=1}, 50)
end
--[[
    出现消失
]]
function FlamingPompeiiReSpinBarView:playStartAnim()
    self:runCsbAction("start", false)
end
function FlamingPompeiiReSpinBarView:playAddTimesAnim()
    self:runCsbAction("animation", false)
end
function FlamingPompeiiReSpinBarView:playOverAnim(_fun)
    self:runCsbAction("over", false, _fun)
end

return FlamingPompeiiReSpinBarView