---
--xcyy
--2018年5月23日
--BeerGirlWheel_0_JackPotBarView.lua

local BeerGirlWheel_0_JackPotBarView = class("BeerGirlWheel_0_JackPotBarView",util_require("base.BaseView"))


function BeerGirlWheel_0_JackPotBarView:initUI(bet)

    self:createCsbNode("BeerGirl_Wheel_jackPot_1.csb")

    self:runCsbAction("idleframe",true)

    self.m_totalBet = bet

end

function BeerGirlWheel_0_JackPotBarView:onExit()
 
end

function BeerGirlWheel_0_JackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function BeerGirlWheel_0_JackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function BeerGirlWheel_0_JackPotBarView:updateJackpotInfo()

    local data=self.m_csbOwner

    self:changeNode(self:findChild("font_grand"),1,true)
    self:changeNode(self:findChild("font_major"),2,true)
    self:changeNode(self:findChild("font_minor"),3)
    self:changeNode(self:findChild("font_min"),4)
    self:updateSize()
end

function BeerGirlWheel_0_JackPotBarView:updateSize()

    local label1=self.m_csbOwner["font_grand"]
    local label2=self.m_csbOwner["font_major"]
    local info1={label=label1,sx=1.8,sy=1.8}
    local info2={label=label2,sx=1.3,sy=1.3}

    local label3=self.m_csbOwner["font_minor"]
    local label4=self.m_csbOwner["font_min"]
    local info3={label=label3,sx=1.3,sy=1.3}
    local info4={label=label4,sx=1.3,sy=1.3}

    self:updateLabelSize(info1,186)
    self:updateLabelSize(info2,186)
    self:updateLabelSize(info3,186)
    self:updateLabelSize(info4,186)
end

function BeerGirlWheel_0_JackPotBarView:BaseMania_updateJackpotScore(index,totalBet)
    if not totalBet then
        totalBet=globalData.slotRunData:getCurTotalBet()
    end
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools[index] then
        return 0
    end
    local totalScore,baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index],true,totalBet)
    return totalScore
end

function BeerGirlWheel_0_JackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index,self.m_totalBet)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function BeerGirlWheel_0_JackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return BeerGirlWheel_0_JackPotBarView