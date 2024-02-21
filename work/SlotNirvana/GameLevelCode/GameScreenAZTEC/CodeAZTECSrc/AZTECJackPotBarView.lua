---
--xcyy
--2018年5月23日
--AZTECJackPotBarView.lua

local AZTECJackPotBarView = class("AZTECJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MegaName = "m_lb_mega"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

local ALL_JACKPOT_ARRAY = {"Mini", "Minor", "Major", "Maxi", "Grand"}

function AZTECJackPotBarView:initUI()

    self:createCsbNode("AZTEC_jackpot.csb")

    self:runCsbAction("idleframe",true)

end

function AZTECJackPotBarView:onExit()
 
end

function AZTECJackPotBarView:addBonusIcon()
    self.m_vecBonusIcon = {}
    for i = 1, #ALL_JACKPOT_ARRAY, 1 do
        local parent = self:findChild("bonus_"..ALL_JACKPOT_ARRAY[i])
        local bonus = util_createView("CodeAZTECSrc.AZTECJackpotBonusIcon", ALL_JACKPOT_ARRAY[i])
        self.m_vecBonusIcon[ALL_JACKPOT_ARRAY[i]] = bonus
        parent:addChild(bonus)
    end
end

function AZTECJackPotBarView:updateBonusIcon(jackpot, index, isAnimation, isGray)
    if jackpot == "Super" then
        return
    end
    if isGray == true then
        self.m_vecBonusIcon[jackpot]:showGrayIdle()
    else
        if isAnimation == true then
            self.m_vecBonusIcon[jackpot]:showAnimation(index)
        else
            self.m_vecBonusIcon[jackpot]:showIdle(index)
        end
    end
    
end

function AZTECJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function AZTECJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function AZTECJackPotBarView:updateJackpotInfo()
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

function AZTECJackPotBarView:updateSize()

    local label1 = self.m_csbOwner[GrandName]
    local info1 = {label = label1, sx = 1, sy = 1}

    local label2 = self.m_csbOwner[MegaName]
    local info2 = {label = label2, sx = 0.7, sy = 0.7}

    local label3 = self.m_csbOwner[MajorName]
    local info3 = {label = label3, sx = 0.7, sy = 0.7}
    
    local label4 = self.m_csbOwner[MinorName]
    local info4 = {label = label4, sx = 0.6, sy = 0.6}

    local label5 = self.m_csbOwner[MiniName]
    local info5 = {label = label5, sx = 0.6, sy = 0.6}


    self:updateLabelSize(info1,426)
    self:updateLabelSize(info2,456)
    self:updateLabelSize(info3,456)
    self:updateLabelSize(info4,398)
    self:updateLabelSize(info5,398)
end

function AZTECJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function AZTECJackPotBarView:toAction(actionName, loop, func)

    self:runCsbAction(actionName, loop, func)
end


return AZTECJackPotBarView