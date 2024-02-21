---
--xcyy
--2018年5月23日
--PelicanJackPotBarView.lua

local PelicanJackPotBarView = class("PelicanJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "ml_b_coins1"
local MajorName = "ml_b_coins2"
local MinorName = "ml_b_coins3"
local MiniName = "ml_b_coins4" 

function PelicanJackPotBarView:initUI(_csbPath)

    self:createCsbNode(_csbPath ..".csb")

    self.jackpotBarType = 0
    if _csbPath == "Pelican_Jackpot_Rs" then
        self.jackpotBarType = 1
    end

end

function PelicanJackPotBarView:onEnter()

    PelicanJackPotBarView.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function PelicanJackPotBarView:onExit()
    PelicanJackPotBarView.super.onExit(self)
end

function PelicanJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function PelicanJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)
    if self.jackpotBarType == 0 then
        self:updateSize()
    else
        self:updateSize2()
    end
    
end

--用于respin
function PelicanJackPotBarView:updateSize2( )
    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,968)
    self:updateLabelSize(info2,692)
    self:updateLabelSize(info3,508)
    self:updateLabelSize(info4,508)
end

function PelicanJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,958)
    self:updateLabelSize(info2,887)
    self:updateLabelSize(info3,712)
    self:updateLabelSize(info4,712)
end

function PelicanJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return PelicanJackPotBarView