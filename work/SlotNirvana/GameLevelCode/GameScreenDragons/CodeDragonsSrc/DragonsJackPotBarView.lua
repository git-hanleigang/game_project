---
--xcyy
--2018年5月23日
--DragonsJackPotBarView.lua

local DragonsJackPotBarView = class("DragonsJackPotBarView",util_require("base.BaseView"))

local GrandName = "BitmapFontLabel_1"
local SuperName = "BitmapFontLabel_2"
local MajorName = "BitmapFontLabel_3"
local MinorName = "BitmapFontLabel_4"
local MiniName = "BitmapFontLabel_5" 

function DragonsJackPotBarView:initUI(machine)
    self.m_machine=machine
    self:createCsbNode("Dragons_Jackpot.csb")
    self:runCsbAction("idleframe",true)
end

function DragonsJackPotBarView:onExit()
 
end

function DragonsJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function DragonsJackPotBarView:onEnter()
    -- util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function DragonsJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(SuperName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self:findChild(MinorName),4,true)
    self:changeNode(self:findChild(MiniName),5,true)

    self:updateSize()
end

function DragonsJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,388)

    local label2=self.m_csbOwner[SuperName]
    local info2={label=label2,sx=1,sy=1}
    self:updateLabelSize(info2,210)

    local label3=self.m_csbOwner[MajorName]
    local info3={label=label3,sx=1,sy=1}
    self:updateLabelSize(info3,210)

    local label4=self.m_csbOwner[MinorName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info4,177)

    local label5=self.m_csbOwner[MiniName]
    local info5={label=label5,sx=1,sy=1}
    self:updateLabelSize(info5,177)
end

function DragonsJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function DragonsJackPotBarView:toAction(actionName)
    self:runCsbAction(actionName)
end

return DragonsJackPotBarView