---
--xcyy
--2018年5月23日
--MagicLadyJackPotBarView.lua

local MagicLadyJackPotBarView = class("MagicLadyJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function MagicLadyJackPotBarView:initUI()
    self:createCsbNode("MagicLady_jackpot.csb")

    self:resetCurRefreshTime()

    self.m_light = util_createAnimation("Node_jackpot.csb")
    self:findChild("Node_jackpot"):addChild(self.m_light)
    self.m_light:setVisible(false)
end

function MagicLadyJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function MagicLadyJackPotBarView:onExit()
    
end

function MagicLadyJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function MagicLadyJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    --公共jackpot
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    if status == "Normal" then
        self:changeNode(self:findChild(GrandName),1,true)
    else
        self.m_curTime = self.m_curTime + 0.08

        local time     = math.min(120, self.m_curTime)
        local addTimes = time/0.08 
        local jackpotValue = self.m_machine:getCommonJackpotValue(status, addTimes)
        local ml_b_coins_grand = self:findChild(GrandName)
        ml_b_coins_grand:setString(util_formatCoins(jackpotValue,50))
    end

    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function MagicLadyJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1,sx = 1,sy = 1}
    local info2 = {label = label2,sx = 1,sy = 1}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3,sx = 1,sy = 1}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4,sx = 1,sy = 1}
    self:updateLabelSize(info1,330)
    self:updateLabelSize(info2,330)
    self:updateLabelSize(info3,225)
    self:updateLabelSize(info4,225)
end

function MagicLadyJackPotBarView:changeNode(label,index,isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--------------------------------公共jackpot-------------------------------------------------
--[[
    重置刷新时间
]]
function MagicLadyJackPotBarView:resetCurRefreshTime()
    self.m_curTime = 0
end

function MagicLadyJackPotBarView:updateMegaShow()
    local icon_super = self:findChild("MagicLady_jackpot_super")
    local icon_mega = self:findChild("MagicLady_jackpot_mega")
    local icon_grand = self:findChild("MagicLady_jackpot_grand")
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    icon_super:setVisible(status == "Super")
    icon_mega:setVisible(status == "Mega")
    icon_grand:setVisible(status == "Normal")

    if self.m_curStatus and self.m_curStatus ~= status and (status == "Mega" or status == "Super") then
        self.m_light:setVisible(true)
        self.m_light:runCsbAction("win",false,function()
            self.m_light:setVisible(false)
        end)
        for index = 1,8 do
            self.m_light:findChild("Particle_"..index):resetSystem()
        end
    end

    self.m_curStatus = status
    
end

return MagicLadyJackPotBarView