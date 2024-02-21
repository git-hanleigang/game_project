--[[
    
]]
local NutCarnivalReSpinBar = class("NutCarnivalReSpinBar",util_require("Levels.BaseLevelDialog"))

function NutCarnivalReSpinBar:initUI(_machine)
    self.m_machine = _machine

    self.m_curTimes = 0
    self.m_animName = ""

    self:createCsbNode("NutCarnival_respin_cishu.csb")
end

function NutCarnivalReSpinBar:updateTimes(_times, _bAnim)
    self.m_curTimes = _times
    local bLastLab = _times <= 0
    local bGoldLab = 0 < _times and _times <= 3

    local numberNode = self:findChild("Node_shuzhi")
    local spLast     = self:findChild("sp_last")
    numberNode:setVisible(not bLastLab)
    spLast:setVisible(bLastLab)
    if not bLastLab then
        local label_1 = self:findChild("m_lb_num")
        local label_2 = self:findChild("m_lb_num_2")
        label_1:setVisible(not bGoldLab)
        label_2:setVisible(bGoldLab)
        local label = bGoldLab and label_2 or label_1
        label:setString(_times)
        self:updateLabelSize({label=label, sx=1, sy=1}, 114)
        local bPlural = _times > 1
        self:findChild("sp_spin"):setVisible(not bPlural)
        self:findChild("sp_spins"):setVisible(bPlural)
    end

    if _bAnim then
        self:playIdleAnimByTimes(_times)
    end
end

function NutCarnivalReSpinBar:playIdleAnimByTimes(_times)
    local bLastIdle = _times <= 3
    if bLastIdle then
        self:playLastIdleAnim()
    else
        self:playIdleAnim()
    end
end
--[[
    时间线
]]
function NutCarnivalReSpinBar:playIdleAnim()
    local animName = "idle"
    if animName == self.m_animName then
        return
    end
    self.m_animName = animName
    self:runCsbAction(self.m_animName, true)
end
--最后几次的idle
function NutCarnivalReSpinBar:playLastIdleAnim()
    local animName = "idle3"
    if animName == self.m_animName then
        return
    end
    self.m_animName = animName
    self:runCsbAction(self.m_animName, true)
end
function NutCarnivalReSpinBar:playMoveAnim(_bExit)
    self.m_animName = _bExit and "youyi" or "zuoyi"
    self:runCsbAction(self.m_animName, false)
end

function NutCarnivalReSpinBar:playReSpinMoreAnim(_times, _fun)
    self.m_animName = "fankui"
    self:runCsbAction(self.m_animName, false, function()
        self:updateTimes(_times, true)
        _fun()
    end)
    performWithDelay(self,function()
        self:updateTimes(_times, false)
    end, 9/60)
end
return NutCarnivalReSpinBar