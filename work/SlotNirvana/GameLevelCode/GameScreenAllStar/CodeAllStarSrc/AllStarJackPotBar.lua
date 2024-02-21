---
--xcyy
--2018年5月23日
--AllStarJackPotBar.lua

local AllStarJackPotBar = class("AllStarJackPotBar",util_require("base.BaseView"))


function AllStarJackPotBar:initUI()

    self:createCsbNode("AllStar_Bonus_kuang.csb")

    self:runCsbAction("idle",true) -- 播放时间线



    self.m_LockGrand = util_createView("CodeAllStarSrc.AllStarLockGrand")
    self:findChild("Jackpot_unlock"):addChild(self.m_LockGrand)
    self.m_LockGrand:runCsbAction("idle",true)
    self.m_LockGrand:setVisible(false)


end

function AllStarJackPotBar:onExit()
 
end

function AllStarJackPotBar:initMachine(machine)
    self.m_machine = machine
end

function AllStarJackPotBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function AllStarJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("m_lb_grand"),1,true,30)
    self:changeNode(self:findChild("m_lb_major"),2,true,30)
    self:changeNode(self:findChild("m_lb_minor"),3,true,30)
    self:changeNode(self:findChild("m_lb_mini"),4,true,30)

    self:updateSize()
end

function AllStarJackPotBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.9,sy=0.9}

    local label3=self.m_csbOwner["m_lb_minor"]
    local label4=self.m_csbOwner["m_lb_mini"]
    local info3={label=label3,sx=0.9,sy=0.9}
    local info4={label=label4,sx=0.9,sy=0.9}

    self:updateLabelSize(info1,354)
    self:updateLabelSize(info2,225)
    self:updateLabelSize(info3,225)
    self:updateLabelSize(info4,225)
end

function AllStarJackPotBar:changeNode(label,index,isJump,cut)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,cut))
end

function AllStarJackPotBar:toAction(actionName)

    self:runCsbAction(actionName)
end


return AllStarJackPotBar