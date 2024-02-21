--[[
    
]]
local NutCarnivalReSpinMultip = class("NutCarnivalReSpinMultip",util_require("Levels.BaseLevelDialog"))

function NutCarnivalReSpinMultip:initUI(_machine)
    self.m_machine = _machine

    self.m_showType = self.m_machine.SYMBOL_SpecialBonus_1
    self:createCsbNode("NutCarnival_respin_chengbeisongguo.csb")
end

function NutCarnivalReSpinMultip:setType(_symbolType)
    self.m_showType = _symbolType
    local bonusIndex = self.m_machine:getSpecialBonusIndex(_symbolType)
    for _typeIndex=1,4 do
        local bVisible = bonusIndex == _typeIndex
        local typeNode = self:findChild(string.format("Node_%d", _typeIndex))
        typeNode:setVisible(bVisible)
    end
end

--[[
    时间线
]]
function NutCarnivalReSpinMultip:playIdleAnim()
    self:runCsbAction("idle", true)
end
function NutCarnivalReSpinMultip:playMoveAnim(_bExit)
    local animName = _bExit and "zuoyi" or "youyi" 
    self:runCsbAction(animName, false)
end

return NutCarnivalReSpinMultip