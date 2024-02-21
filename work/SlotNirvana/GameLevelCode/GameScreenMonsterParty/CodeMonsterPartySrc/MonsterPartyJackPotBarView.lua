---
--xcyy
--2018年5月23日
--MonsterPartyJackPotBarView.lua

local MonsterPartyJackPotBarView = class("MonsterPartyJackPotBarView",util_require("base.BaseView"))

local MegaName = "ml_b_coins1"
local GrandName = "ml_b_coins2"
local MajorName = "ml_b_coins3"
local MinorName = "ml_b_coins4"
local MiniName = "ml_b_coins5" 

function MonsterPartyJackPotBarView:initUI()

    self:createCsbNode("MonsterParty_jackpot.csb")

    self:runCsbAction("idle",true)

end



function MonsterPartyJackPotBarView:onExit()
 
end

function MonsterPartyJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MonsterPartyJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function MonsterPartyJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    

    self:changeNode(self:findChild(MegaName),1,true)
    self:changeNode(self:findChild(GrandName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self:findChild(MinorName),4)
    self:changeNode(self:findChild(MiniName),5)

    self:updateSize()
end

function MonsterPartyJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1,sy=1}

    local label2=self.m_csbOwner[MajorName]
    local info2={label=label2,sx=1,sy=1}

    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}

    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}

    local label5=self.m_csbOwner[MegaName]
    local info5={label=label5,sx=1,sy=1}

    self:updateLabelSize(info5,481)
    self:updateLabelSize(info1,243)
    self:updateLabelSize(info2,203)
    self:updateLabelSize(info3,159)
    self:updateLabelSize(info4,139)
    
end

function MonsterPartyJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function MonsterPartyJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return MonsterPartyJackPotBarView