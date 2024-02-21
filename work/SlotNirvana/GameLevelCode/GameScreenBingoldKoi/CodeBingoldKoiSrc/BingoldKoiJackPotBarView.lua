---
--xcyy
--2018年5月23日
--BingoldKoiJackPotBarView.lua

local BingoldKoiJackPotBarView = class("BingoldKoiJackPotBarView",util_require("Levels.BaseLevelDialog"))


local GrandName = "m_lb_coins_1"
local MegaName = "m_lb_coins_2"
local MajorName = "m_lb_coins_3"
local MinorName = "m_lb_coins_4"
local MiniName = "m_lb_coins_5" 

function BingoldKoiJackPotBarView:initUI(params)
    self:initMachine(params.machine)

    self:createCsbNode("BingoldKoi_Jackpotlan.csb")

    self:runCsbAction("idle",true)

end

function BingoldKoiJackPotBarView:onEnter()

    BingoldKoiJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function BingoldKoiJackPotBarView:onExit()
    BingoldKoiJackPotBarView.super.onExit(self)
end

function BingoldKoiJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function BingoldKoiJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MegaName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self:findChild(MinorName),4)
    self:changeNode(self:findChild(MiniName),5)

    self:updateSize()
end

function BingoldKoiJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1,sy=1}

    local label2=self.m_csbOwner[MegaName]
    local info2={label=label2,sx=1,sy=1}

    local label3=self.m_csbOwner[MajorName]
    local info3={label=label3,sx=1,sy=1}

    local label4=self.m_csbOwner[MinorName]
    local info4={label=label4,sx=1,sy=1}

    local label5=self.m_csbOwner[MiniName]
    local info5={label=label5,sx=1,sy=1}
    self:updateLabelSize(info1,237)
    self:updateLabelSize(info2,207)
    self:updateLabelSize(info3,192)
    self:updateLabelSize(info4,169)
    self:updateLabelSize(info5,153)
end

function BingoldKoiJackPotBarView:changeNode(label,index,isJump)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.m_machine.m_isSuperFree and self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet then
        lineBet = self.m_machine.m_runSpinResultData.p_fsExtraData.avgBet
    end
    local value=self.m_machine:BaseMania_updateJackpotScore(index,lineBet)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return BingoldKoiJackPotBarView