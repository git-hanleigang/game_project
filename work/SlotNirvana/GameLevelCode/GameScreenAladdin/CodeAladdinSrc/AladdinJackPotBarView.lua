---
--xcyy
--2018年5月23日
--AladdinJackPotBarView.lua

local AladdinJackPotBarView = class("AladdinJackPotBarView",util_require("base.BaseView"))

local GrandName = "ml_b_coins1"
local MajorName = "ml_b_coins2"
local MinorName = "ml_b_coins3"
local MiniName = "ml_b_coins4" 

function AladdinJackPotBarView:initUI()

    self:createCsbNode("Aladdin_jackpot.csb")

    self:runCsbAction("idleframe",true)

end

function AladdinJackPotBarView:onExit()
 
end

function AladdinJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function AladdinJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function AladdinJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function AladdinJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,276)
    self:updateLabelSize(info2,260)
    self:updateLabelSize(info3,240)
    self:updateLabelSize(info4,220)
end

function AladdinJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function AladdinJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return AladdinJackPotBarView