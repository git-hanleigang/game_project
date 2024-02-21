--[[
    
]]
local NutCarnivalReSpinLogo = class("NutCarnivalReSpinLogo",util_require("Levels.BaseLevelDialog"))

function NutCarnivalReSpinLogo:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("NutCarnival_respin_logo.csb")
end

--[[
    时间线
]]
function NutCarnivalReSpinLogo:playStartAnim(_fun)
    self:runCsbAction("chuxian", false, _fun)
end
function NutCarnivalReSpinLogo:playIdleAnim()
    self:runCsbAction("idle", true)
end
function NutCarnivalReSpinLogo:playOverAnim(_fun)
    self:runCsbAction("xiaoshi", false, _fun)
end
return NutCarnivalReSpinLogo