---
--xcyy
--2018年5月23日
--FairyDragonJackPotBarView.lua

local FairyDragonJackPotBarView = class("FairyDragonJackPotBarView",util_require("base.BaseView"))

local GrandName = "GrandNum"
local MajorName = "MajorNum"
local MinorName = "MinorNum"
local MiniName = "MiniNum" 

function FairyDragonJackPotBarView:initUI()

    self:createCsbNode("FairyDragon_Jackpot.csb")

    -- self:runCsbAction("idleframe",true)
    
    self:addClick(self:findChild("click"))

end

function FairyDragonJackPotBarView:onExit()
 
end

function FairyDragonJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function FairyDragonJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function FairyDragonJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    self:changeNode(self:findChild(GrandName),1)
    self:changeNode(self:findChild(MajorName),2)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function FairyDragonJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local label3=self.m_csbOwner[MinorName]
    local label4=self.m_csbOwner[MiniName]
    self:updateLabelSize({label=label1,sx=0.95,sy=0.95},240)
    self:updateLabelSize({label=label2,sx=0.95,sy=0.95},240)
    self:updateLabelSize({label=label3,sx=0.95,sy=0.95},180)
    self:updateLabelSize({label=label4,sx=0.95,sy=0.95},180)
end

function FairyDragonJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function FairyDragonJackPotBarView:toAction(actionName)
    self:runCsbAction(actionName)
end

function FairyDragonJackPotBarView:clickFunc(sender)
    local name = sender:getName()
    if name == "click" then

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
        
    end
end

return FairyDragonJackPotBarView