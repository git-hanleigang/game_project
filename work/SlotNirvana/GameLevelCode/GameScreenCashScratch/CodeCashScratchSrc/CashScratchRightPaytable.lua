---
--xcyy
--2018年5月23日
--CashScratchRightPaytable.lua

local CashScratchRightPaytable = class("CashScratchRightPaytable",util_require("Levels.BaseLevelDialog"))

function CashScratchRightPaytable:initUI(_machine)
    self:createCsbNode("CashScratch_right_paytable.csb")

    self.m_machine = _machine
    
end

function CashScratchRightPaytable:showPaytableAnim()
    self:runCsbAction("start", false)
end
function CashScratchRightPaytable:hidePaytableAnim(_fun)
    self:runCsbAction("over", false, _fun)
end

function CashScratchRightPaytable:upDateByType(_symbolType)
    -- 信号值 对应的 关键字
    local symbolName = {
        [self.m_machine.SYMBOL_Bonus_1] = "1x",
        [self.m_machine.SYMBOL_Bonus_2] = "2x",
        [self.m_machine.SYMBOL_Bonus_3] = "3x",
        [self.m_machine.SYMBOL_Bonus_4] = "5x",
        [self.m_machine.SYMBOL_Bonus_5] = "2x3x5x",
    }


    local isABTest = self.m_machine:checkCashScratchABTest()

    local commonPaytable = self:findChild("commonPaytable")
    commonPaytable:setVisible(not isABTest)

    for _symType,_sName in pairs(symbolName) do
        local isVisible = _symbolType == _symType
        local symbolNode = self:findChild( string.format("Node_%s", _sName) )

        symbolNode:setVisible(isVisible)
        if isVisible then
            local abTestNode = self:findChild( string.format("%s_abtest", _sName) )
            abTestNode:setVisible(isABTest)
        end
    end
end

return CashScratchRightPaytable
    

