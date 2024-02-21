---
--xcyy
--2018年5月23日
--VegasLifeJackPotBarView.lua

local VegasLifeJackPotBarView = class("VegasLifeJackPotBarView",util_require("base.BaseView"))

function VegasLifeJackPotBarView:initUI()

    self:createCsbNode("VegasLife_jackpot.csb")
    self:runCsbAction("start") 
  
end


function VegasLifeJackPotBarView:onExit()

end

function VegasLifeJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function VegasLifeJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function VegasLifeJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner
    local widthList = {193,175,155,130,115}
    local scaleList = {1.07,1.11,1.21,1.31,1.35}

    for i=1,#widthList do
        local lbCoins = self:findChild("jackpot_coins"..i)
        local lbLockCoins = self:findChild("jackpot_coins"..i.."_0")
        self:updateSize(lbCoins,lbLockCoins,i,widthList[i],scaleList[i])
    end
end

function VegasLifeJackPotBarView:updateSize(lbs,lockLbs,index,width,scale)
    local value=self.m_machine:BaseMania_updateJackpotScore(index+5)

    lbs:setString(util_formatCoins(value,20))
    local info1={label=lbs,sx = scale,sy = scale}
    self:updateLabelSize(info1,width)

    if lockLbs then
        lockLbs:setString(util_formatCoins(value,20))
        local info2={label=lockLbs,sx = scale,sy = scale}
        self:updateLabelSize(info2,width)
    end
end

function VegasLifeJackPotBarView:updateLock( level )

    if level == 4 then -- 最高档
        self:findChild("jackpot_coins1_0"):setVisible(false)
        self:findChild("jackpot_coins2_0"):setVisible(false)
        self:findChild("jackpot_coins3_0"):setVisible(false)
        self:findChild("jackpot_coins4_0"):setVisible(false)
    elseif level == 3 then
        self:findChild("jackpot_coins1_0"):setVisible(true)
        self:findChild("jackpot_coins2_0"):setVisible(false)
        self:findChild("jackpot_coins3_0"):setVisible(false)
        self:findChild("jackpot_coins4_0"):setVisible(false)
    elseif level == 2 then
        self:findChild("jackpot_coins1_0"):setVisible(true)
        self:findChild("jackpot_coins2_0"):setVisible(true)
        self:findChild("jackpot_coins3_0"):setVisible(false)
        self:findChild("jackpot_coins4_0"):setVisible(false)
    elseif level == 1 then
        self:findChild("jackpot_coins1_0"):setVisible(true)
        self:findChild("jackpot_coins2_0"):setVisible(true)
        self:findChild("jackpot_coins3_0"):setVisible(true)
        self:findChild("jackpot_coins4_0"):setVisible(false)
    elseif level == 0 then
        self:findChild("jackpot_coins1_0"):setVisible(true)
        self:findChild("jackpot_coins2_0"):setVisible(true)
        self:findChild("jackpot_coins3_0"):setVisible(true)
        self:findChild("jackpot_coins4_0"):setVisible(true)
    else
        self:findChild("jackpot_coins1_0"):setVisible(false)
        self:findChild("jackpot_coins2_0"):setVisible(false)
        self:findChild("jackpot_coins3_0"):setVisible(false)
        self:findChild("jackpot_coins4_0"):setVisible(false)
    end
end

function VegasLifeJackPotBarView:showjackPotAction(id)
    -- 中5/6两档Jackpot时 播放1遍 时间3秒 ，其他档位2遍 时间6秒
    local delayTime = 6
    if id == 1 or id == 2 then
        delayTime = 3
    end
    self:runCsbAction("animation"..id,true,function()end)
    performWithDelay(self,function(  )
        self:clearAnim()
    end,delayTime)

end

function VegasLifeJackPotBarView:clearAnim()
    self:runCsbAction("animation0")
end


return VegasLifeJackPotBarView