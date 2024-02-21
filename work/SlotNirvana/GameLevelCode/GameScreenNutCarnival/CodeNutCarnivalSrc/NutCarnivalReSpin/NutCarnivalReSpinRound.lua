--[[
    全满触发转盘结束后还有次数时的提示弹板
]]
local NutCarnivalReSpinRound = class("NutCarnivalReSpinRound",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "NutCarnivalPublicConfig"

function NutCarnivalReSpinRound:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("NutCarnival_respin_round.csb")
end

--[[
    时间线
]]
function NutCarnivalReSpinRound:playStartAnim(_addTimes, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpin_newRound)
    self:findChild("m_lb_num"):setString(_addTimes)
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:setVisible(false)
        _fun()
    end)
end

return NutCarnivalReSpinRound