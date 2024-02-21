---
--xcyy
--2018年5月23日
--WheelOfRomanceJackPotBarView.lua

local WheelOfRomanceJackPotBarView = class("WheelOfRomanceJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

WheelOfRomanceJackPotBarView.m_linebet = 0

function WheelOfRomanceJackPotBarView:initUI(_isBonusJpBar)

    self:createCsbNode("WheelOfRomance_jackpot.csb")

    self.m_isBonusJpBar = _isBonusJpBar

end

function WheelOfRomanceJackPotBarView:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function WheelOfRomanceJackPotBarView:onExit()
 
end

function WheelOfRomanceJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WheelOfRomanceJackPotBarView:updateLinebet(_linebet )
    self.m_linebet = _linebet
end


-- 更新jackpot 数值信息
--
function WheelOfRomanceJackPotBarView:updateJackpotInfo()
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

function WheelOfRomanceJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.8,sy=0.8}
    local info2={label=label2,sx=0.8,sy=0.8}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.75,sy=0.75}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.65,sy=0.65}
    self:updateLabelSize(info1,142)
    self:updateLabelSize(info2,142)
    self:updateLabelSize(info3,142)
    self:updateLabelSize(info4,142)
end

function WheelOfRomanceJackPotBarView:function_name( )
    
end

function WheelOfRomanceJackPotBarView:changeNode(label,index,isJump)


    local value=self.m_machine:BaseMania_updateJackpotScore(index)

    if self.m_isBonusJpBar then
        value=self.m_machine:BaseMania_updateJackpotScore(index,self.m_linebet)
    end

    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return WheelOfRomanceJackPotBarView