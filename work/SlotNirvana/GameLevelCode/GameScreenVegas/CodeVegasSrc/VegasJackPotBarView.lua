---
--xcyy
--2018年5月23日
--VegasJackPotBarView.lua

local VegasJackPotBarView = class("VegasJackPotBarView",util_require("base.BaseView"))

local GrandName = "grand_shuzi"
local MajorName = "major_shuzi"
local MinorName = "minor_shuzi"
local MiniName = "mini_shuzi" 

function VegasJackPotBarView:initUI(machine)
    self.m_machine=machine
    self:createCsbNode("Vegas_jackpot.csb")
    self:runCsbAction("idleframe",true)
end



function VegasJackPotBarView:onExit()
 
end

function VegasJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function VegasJackPotBarView:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function VegasJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3,true)
    self:changeNode(self:findChild(MiniName),4,true)

    self:updateSize()
end

function VegasJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,228)

    local label2=self.m_csbOwner[MajorName]
    local info2={label=label2,sx=1,sy=1}
    self:updateLabelSize(info2,216)

    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    self:updateLabelSize(info3,181)

    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info4,151)
end

function VegasJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function VegasJackPotBarView:toAction(actionName)
    self:runCsbAction(actionName)
end


return VegasJackPotBarView