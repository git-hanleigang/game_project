---
--xcyy
--2018年5月23日
--ZeusJackPotBarView.lua

local ZeusJackPotBarView = class("ZeusJackPotBarView",util_require("base.BaseView"))

local GrandName = "grand_Num"
local MajorName = "major_Num"
local MinorName = "minor_Num"
local MiniName = "mini_Num" 

function ZeusJackPotBarView:initUI(path)

    self:createCsbNode("Zeus_Jackpotbar.csb")

    -- self:runCsbAction("idleframe",true)

end



function ZeusJackPotBarView:onExit()
 
end

function ZeusJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function ZeusJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function ZeusJackPotBarView:updateJackpotInfo()
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

function ZeusJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.77,sy=0.77}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.6,sy=0.6}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.55,sy=0.55}
    self:updateLabelSize(info1,475)
    self:updateLabelSize(info2,475)
    self:updateLabelSize(info3,262)
    self:updateLabelSize(info4,362)
end

function ZeusJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function ZeusJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return ZeusJackPotBarView