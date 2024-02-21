---
--xhkj
--2018年6月11日
--CrazyBombTopBar.lua

local CrazyBombTopBar = class("CrazyBombTopBar", util_require("base.BaseView"))

function CrazyBombTopBar:initUI(data)

    local resourceFilename="CrazyBomb_Jackpot.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
end

function CrazyBombTopBar:setFadeOutAction(  )
    self.m_csbNode:runAction(cc.FadeOut:create(1)) 
end

function CrazyBombTopBar:initMachine(machine)
    self.m_machine = machine
end

function CrazyBombTopBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function CrazyBombTopBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("m_lb_grand"),1,true)
    self:changeNode(self:findChild("m_lb_major"),2,true)
    self:changeNode(self:findChild("m_lb_minor"),3)
    self:changeNode(self:findChild("m_lb_mini"),4)
    self:updateSize()
end

function CrazyBombTopBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local label3=self.m_csbOwner["m_lb_minor"]
    local label4=self.m_csbOwner["m_lb_mini"]

    local info1={label=label1}
    local info2={label=label2}
    local info3={label=label3}
    local info4={label=label4}

    self:updateLabelSize(info1,131)
    self:updateLabelSize(info2,120)
    self:updateLabelSize(info3,110)
    self:updateLabelSize(info4,110)
end

function CrazyBombTopBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function CrazyBombTopBar:toAction(actionName)

    self:runCsbAction(actionName)
end

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return CrazyBombTopBar