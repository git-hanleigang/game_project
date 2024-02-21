---
--xcyy
--2018年5月23日
--CharmsViewFlyNode.lua

local CharmsViewFlyNode = class("CharmsViewFlyNode",util_require("base.BaseView"))
CharmsViewFlyNode.m_symbolType = nil
CharmsViewFlyNode.machine = nil

function CharmsViewFlyNode:initUI(data)

    self.m_symbolType = data.symboltype
    self.m_machine = data.machine
    self.m_coins = data.coins
    local csbPath ="LinkReels/CharmsLink/" .. self:getCsbName(data.freespin) ..".csb"
    self:createCsbNode(csbPath)

    self:setLabCoins()

end


function CharmsViewFlyNode:setLabCoins()

    -- if self.m_coins then
    --     local lab = self:findChild("m_lb_score")

    --     if lab then
    --         lab:setString(self.m_coins)
    --     end
    -- end
    

end

function CharmsViewFlyNode:getCsbName(isfreespin)


    local csbName = "4in1_Socre_Charms_Bonus_4"

    if isfreespin == true then
        csbName = "4in1_Socre_Charms_Bonus_6"
    end
 
    if math.abs( self.m_symbolType ) == self.m_machine.SYMBOL_FIX_SYMBOL_DOUBLE then
        csbName = "4in1_Socre_Charms_Bonus_5"
    end

    if math.abs( self.m_symbolType ) == self.m_machine.SYMBOL_FIX_MINOR then
        csbName = "4in1_Socre_Charms_Bonus_5"
    end

    if math.abs( self.m_symbolType ) == self.m_machine.SYMBOL_FIX_MINOR_DOUBLE then
        csbName = "4in1_Socre_Charms_Bonus_5"
    end

    -- if self.m_machine and self.m_symbolType then
    --     --csbName = self.m_machine:MachineRule_GetSelfCCBName(self.m_symbolType)
        
    -- end  

   return csbName 
end


function CharmsViewFlyNode:onEnter()
 

end

function CharmsViewFlyNode:onExit()
 
end


return CharmsViewFlyNode