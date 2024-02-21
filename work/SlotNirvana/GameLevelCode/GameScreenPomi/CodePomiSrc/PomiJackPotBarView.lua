---
--xcyy
--2018年5月23日
--PomiJackPotBarView.lua

local PomiJackPotBarView = class("PomiJackPotBarView",util_require("base.BaseView"))

function PomiJackPotBarView:initUI()

    self:createCsbNode("Pomi_Jackpot.csb")
    self:resetCurRefreshTime()

    self.m_light = util_createAnimation("Node_jackpot.csb")
    self:findChild("Node_jackpot"):addChild(self.m_light)
    self.m_light:setVisible(false)
end



function PomiJackPotBarView:onExit()
 
end



function PomiJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function PomiJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end



-- 更新jackpot 数值信息
--
function PomiJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    --公共jackpot
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    if status == "Normal" then
        self:changeNode(self:findChild("ml_b_coins1"),1,true)
    else
        self.m_curTime = self.m_curTime + 0.08

        local time     = math.min(120, self.m_curTime)
        local addTimes = time/0.08 
        local jackpotValue = self.m_machine:getCommonJackpotValue(status, addTimes)
        local ml_b_coins_grand = self:findChild("ml_b_coins1")
        ml_b_coins_grand:setString(util_formatCoins(jackpotValue,50))
    end

    self:changeNode(self:findChild("ml_b_coins2"),2,true)
    self:changeNode(self:findChild("ml_b_coins3"),3)
    self:changeNode(self:findChild("ml_b_coins4"),4)

    self:updateSize()
end

function PomiJackPotBarView:updateSize()

    local label1=self.m_csbOwner["ml_b_coins1"]
    local label2=self.m_csbOwner["ml_b_coins2"]
    local label3=self.m_csbOwner["ml_b_coins3"]
    local label4=self.m_csbOwner["ml_b_coins4"]


    local info1={label=label1,sx = 1,sy = 1}
    local info2={label=label2,sx = 0.87,sy = 0.87}
    local info3={label=label3,sx = 0.78,sy = 0.78}
    local info4={label=label4,sx = 0.78,sy = 0.78}


    self:updateLabelSize(info1,560)
    self:updateLabelSize(info2,518)
    self:updateLabelSize(info3,417)
    self:updateLabelSize(info4,331)

end


function PomiJackPotBarView:changeNode(label,index,isJump)

        local value=self.m_machine:BaseMania_updateJackpotScore(index)

        label:setString(util_formatCoins(value,20))

    
end


--------------------------------公共jackpot-------------------------------------------------
--[[
    重置刷新时间
]]
function PomiJackPotBarView:resetCurRefreshTime()
    self.m_curTime = 0
end

function PomiJackPotBarView:updateMegaShow()
    local icon_super = self:findChild("Pomi_Super")
    local icon_mega = self:findChild("Pomi_Mega")
    local icon_grand = self:findChild("Pomi_Grand")
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


return PomiJackPotBarView