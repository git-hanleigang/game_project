---
--xcyy
--2018年5月23日
--ReelRocksJackPotBarView.lua

local ReelRocksJackPotBarView = class("ReelRocksJackPotBarView",util_require("base.BaseView"))

local GrandName = ""
local MajorName = ""
local MinorName = ""
local MiniName = "" 

function ReelRocksJackPotBarView:initUI()

    -- self:createCsbNode("Puss_jackpot.csb")

    -- self:runCsbAction("idleframe",true)

end

function ReelRocksJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function ReelRocksJackPotBarView:onExit()
 
end

function ReelRocksJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function ReelRocksJackPotBarView:updateJackpotInfo()
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

function ReelRocksJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.6,sy=0.6}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.6,sy=0.6}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.6,sy=0.6}
    self:updateLabelSize(info1,436)
    self:updateLabelSize(info2,359)
    self:updateLabelSize(info3,359)
    self:updateLabelSize(info4,359)
end

function ReelRocksJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return ReelRocksJackPotBarView