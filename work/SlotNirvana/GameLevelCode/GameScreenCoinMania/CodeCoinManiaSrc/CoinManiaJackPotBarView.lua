---
--xcyy
--2018年5月23日
--CoinManiaJackPotBarView.lua

local CoinManiaJackPotBarView = class("CoinManiaJackPotBarView",util_require("base.BaseView"))

local MegaName = "ml_b_coins1"
local GrandName = "ml_b_coins2"
local MajorName = "ml_b_coins3"
local MinorName = "ml_b_coins4"
local MiniName = "ml_b_coins5" 

function CoinManiaJackPotBarView:initUI()

    self:createCsbNode("CoinMania_JackPot.csb")

    self:runCsbAction("idleframe",true)

end

function CoinManiaJackPotBarView:onExit()
 
end

function CoinManiaJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CoinManiaJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function CoinManiaJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner


    self:changeNode(self:findChild(MegaName),1,true)
    self:changeNode(self:findChild(GrandName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self:findChild(MinorName),4,true)
    self:changeNode(self:findChild(MiniName),5,true)

    self:updateSize()
end

function CoinManiaJackPotBarView:updateSize()

    local MegaName = "ml_b_coins1"

    local label5=self.m_csbOwner[MegaName]
    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local label3=self.m_csbOwner[MinorName]
    local label4=self.m_csbOwner[MiniName]

    local info5={label=label5,sx=0.7,sy=0.7}
    local info1={label=label1,sx=0.79,sy=0.79}
    local info2={label=label2,sx=0.85,sy=0.85}
    local info3={label=label3,sx=0.85,sy=0.85}
    local info4={label=label4,sx=0.85,sy=0.85}

    self:updateLabelSize(info5,494)
    self:updateLabelSize(info1,296)
    self:updateLabelSize(info2,249)
    self:updateLabelSize(info3,175)
    self:updateLabelSize(info4,165)
end

function CoinManiaJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function CoinManiaJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return CoinManiaJackPotBarView