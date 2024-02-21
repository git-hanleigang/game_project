---
--xcyy
--2018年5月23日
--BeerGirlWheel_2_JackPotBarView.lua

local BeerGirlWheel_2_JackPotBarView = class("BeerGirlWheel_2_JackPotBarView",util_require("base.BaseView"))


function BeerGirlWheel_2_JackPotBarView:initUI(bet)

    self:createCsbNode("BeerGirl_Wheel_jackPot_3.csb")

    self:runCsbAction("idleframe",true)

    self.m_totalBet = bet

end

function BeerGirlWheel_2_JackPotBarView:onExit()
 
end

function BeerGirlWheel_2_JackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function BeerGirlWheel_2_JackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function BeerGirlWheel_2_JackPotBarView:updateJackpotInfo()

    local data=self.m_csbOwner

    self:changeNode(self:findChild("font_grand"),1,true)
    self:changeNode(self:findChild("font_major"),2,true)
    self:updateSize()
end

function BeerGirlWheel_2_JackPotBarView:updateSize()

    local label1=self.m_csbOwner["font_grand"]
    local label2=self.m_csbOwner["font_major"]
    local info1={label=label1,sx=2.1,sy=2.1}
    local info2={label=label2,sx=1.9,sy=1.9}

    self:updateLabelSize(info1,186)
    self:updateLabelSize(info2,186)

end

function BeerGirlWheel_2_JackPotBarView:BaseMania_updateJackpotScore(index,totalBet)
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

function BeerGirlWheel_2_JackPotBarView:changeNode(label,index,isJump)
    local value=self:BaseMania_updateJackpotScore(index,self.m_totalBet)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function BeerGirlWheel_2_JackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return BeerGirlWheel_2_JackPotBarView