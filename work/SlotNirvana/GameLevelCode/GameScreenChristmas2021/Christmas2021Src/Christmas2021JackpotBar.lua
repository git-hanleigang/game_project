---
--xhkj
--2018年6月11日
--Christmas2021JackpotBar.lua

local Christmas2021JackpotBar = class("Christmas2021JackpotBar", util_require("base.BaseView"))

function Christmas2021JackpotBar:initUI(data)

    local resourceFilename="Christmas2021_jackpot.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
end

function Christmas2021JackpotBar:setFadeOutAction(  )
    self.m_csbNode:runAction(cc.FadeOut:create(1)) 
end

function Christmas2021JackpotBar:initMachine(machine)
    self.m_machine = machine
end

function Christmas2021JackpotBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function Christmas2021JackpotBar:updateJackpotInfo()
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

function Christmas2021JackpotBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local label3=self.m_csbOwner["m_lb_minor"]
    local label4=self.m_csbOwner["m_lb_mini"]

    local info1={label = label1, sx = 1,sy = 1}
    local info2={label = label2, sx = 0.92,sy = 0.92}
    local info3={label = label3, sx = 0.84,sy = 0.84}
    local info4={label = label4, sx = 0.78,sy = 0.78}

    self:updateLabelSize(info1,300)
    self:updateLabelSize(info2,270)
    self:updateLabelSize(info3,250)
    self:updateLabelSize(info4,230)
end

function Christmas2021JackpotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function Christmas2021JackpotBar:toAction(actionName)

    self:runCsbAction(actionName)
end

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return Christmas2021JackpotBar