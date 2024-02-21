---
--xcyy
--2018年5月23日
--MrCashJackPotBarView.lua

local MrCashJackPotBarView = class("MrCashJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_num"
local MajorName = "m_lb_num1"
local MinorName = "m_lb_num2"
local MiniName = "m_lb_num3" 

function MrCashJackPotBarView:initUI()

    self:createCsbNode("MrCash_jackpot.csb")

    -- self:runCsbAction("idleframe",true)

end



function MrCashJackPotBarView:onExit()
 
end

function MrCashJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MrCashJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function MrCashJackPotBarView:updateJackpotInfo()
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

function MrCashJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.9,sy=0.9}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.8,sy=0.8}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.7,sy=0.7}
    self:updateLabelSize(info1,432)
    self:updateLabelSize(info2,389)
    self:updateLabelSize(info3,360)
    self:updateLabelSize(info4,360)
end

function MrCashJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function MrCashJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return MrCashJackPotBarView