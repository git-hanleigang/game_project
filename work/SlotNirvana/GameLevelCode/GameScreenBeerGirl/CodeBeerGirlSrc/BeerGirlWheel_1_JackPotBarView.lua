---
--xcyy
--2018年5月23日
--BeerGirlWheel_1_JackPotBarView.lua

local BeerGirlWheel_1_JackPotBarView = class("BeerGirlWheel_1_JackPotBarView",util_require("base.BaseView"))


function BeerGirlWheel_1_JackPotBarView:initUI(bet)

    self:createCsbNode("BeerGirl_Wheel_jackPot_2.csb")

    self:runCsbAction("idleframe",true)

    self.m_totalBet = bet

end

function BeerGirlWheel_1_JackPotBarView:onExit()
 
end

function BeerGirlWheel_1_JackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function BeerGirlWheel_1_JackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function BeerGirlWheel_1_JackPotBarView:updateJackpotInfo()

    local data=self.m_csbOwner

    self:changeNode(self:findChild("font_grand"),1,true)
    self:changeNode(self:findChild("font_major"),2,true)
    self:changeNode(self:findChild("font_minor"),3)
    self:updateSize()
end

function BeerGirlWheel_1_JackPotBarView:updateSize()

    local label1=self.m_csbOwner["font_grand"]
    local label2=self.m_csbOwner["font_major"]
    local info1={label=label1,sx=1.8,sy=1.8}
    local info2={label=label2,sx=1.4,sy=1.4}

    local label3=self.m_csbOwner["font_minor"]

    local info3={label=label3,sx=1.3,sy=1.3}


    self:updateLabelSize(info1,186)
    self:updateLabelSize(info2,186)
    self:updateLabelSize(info3,186)

end

function BeerGirlWheel_1_JackPotBarView:BaseMania_updateJackpotScore(index,totalBet)
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

function BeerGirlWheel_1_JackPotBarView:changeNode(label,index,isJump)
    local value=self:BaseMania_updateJackpotScore(index,self.m_totalBet)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function BeerGirlWheel_1_JackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return BeerGirlWheel_1_JackPotBarView