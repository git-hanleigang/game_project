

local TrainYourDragonJackPotBarView = class("TrainYourDragonJackPotBarView",util_require("base.BaseView"))
-- FIX IOS 139 1
function TrainYourDragonJackPotBarView:initUI()
    self:createCsbNode("TrainYourDragon_jackpot.csb")
end

function TrainYourDragonJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function TrainYourDragonJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end
function TrainYourDragonJackPotBarView:onExit()
 
end
-- 更新jackpot 数值信息
--
function TrainYourDragonJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("GRAND"),1,true)
    self:changeNode(self:findChild("MAJOR"),2,true)
    self:changeNode(self:findChild("MINOR"),3)
    self:changeNode(self:findChild("MINI"),4)

    self:updateSize()
end

function TrainYourDragonJackPotBarView:updateSize()
    local label1 = self.m_csbOwner["GRAND"]
    local info1 = {label = label1,sx = 1,sy = 1}

    local label2 = self.m_csbOwner["MAJOR"]
    local info2 = {label = label2,sx = 0.92,sy = 0.92}

    local label3 = self.m_csbOwner["MINOR"]
    local info3 = {label = label3,sx = 0.85,sy = 0.85}

    local label4 = self.m_csbOwner["MINI"]
    local info4 = {label = label4,sx = 0.78,sy = 0.78}

    self:updateLabelSize(info1,244)
    self:updateLabelSize(info2,219)
    self:updateLabelSize(info3,183)
    self:updateLabelSize(info4,159)
end

function TrainYourDragonJackPotBarView:changeNode(label,index,isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return TrainYourDragonJackPotBarView