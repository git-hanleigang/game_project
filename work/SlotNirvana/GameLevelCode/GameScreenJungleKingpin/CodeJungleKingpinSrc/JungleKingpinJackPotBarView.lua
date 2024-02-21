---
--xcyy
--2018年5月23日
--JungleKingpinJackPotBarView.lua

local JungleKingpinJackPotBarView = class("JungleKingpinJackPotBarView",util_require("base.BaseView"))

local GrandName = "jackpot_grand"
local MajorName = "jackpot_major"
local MiniName = "jackpot_mini" 

function JungleKingpinJackPotBarView:initUI(machine)
    self.m_machine = machine
    if self.m_machine.m_bJackpotHeight then
        self:createCsbNode("JungleKingpin_Jackpot_1.csb")
    else
        self:createCsbNode("JungleKingpin_Jackpot_ipad.csb")
    end
    self:runCsbAction("idle",true)
end

function JungleKingpinJackPotBarView:onExit()
 
end

function JungleKingpinJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function JungleKingpinJackPotBarView:onEnter()

    self:setCurrBet()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function JungleKingpinJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MiniName),3,true)

    self:updateSize()
end

function JungleKingpinJackPotBarView:updateSize()

    if self.m_machine.m_bJackpotHeight then
        local label1=self.m_csbOwner[GrandName]
        local info1={label=label1,sx=1,sy=1}
        self:updateLabelSize(info1,328)

        local label2=self.m_csbOwner[MajorName]
        local info2={label=label2,sx=0.8,sy=0.8}
        self:updateLabelSize(info2,328)
        
        local label3=self.m_csbOwner[MiniName]
        local info3={label=label3,sx=0.8,sy=0.8}
        self:updateLabelSize(info3,328)
    else
        local label1=self.m_csbOwner[GrandName]
        local info1={label=label1,sx=0.73,sy=0.73}
        self:updateLabelSize(info1,336)

        local label2=self.m_csbOwner[MajorName]
        local info2={label=label2,sx=0.5,sy=0.5}
        self:updateLabelSize(info2,269)
        
        local label3=self.m_csbOwner[MiniName]
        local info3={label=label3,sx=0.5,sy=0.5}
        self:updateLabelSize(info3,269)
    end
end

function JungleKingpinJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index,self.m_currBet)
    label:setString(util_formatCoins(value,50,nil,nil,true))
end

function JungleKingpinJackPotBarView:setCurrBet(_currBet)
    if not _currBet or  _currBet == 0 then
        self.m_currBet = nil
    else
        self.m_currBet = _currBet
    end
    
end

function JungleKingpinJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return JungleKingpinJackPotBarView