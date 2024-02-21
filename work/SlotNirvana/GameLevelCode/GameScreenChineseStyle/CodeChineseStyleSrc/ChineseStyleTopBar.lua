---
--xhkj
--2018年6月11日
--ChineseStyleTopBar.lua

local ChineseStyleTopBar = class("ChineseStyleTopBar", util_require("base.BaseView"))

function ChineseStyleTopBar:initUI(data)

    local resourceFilename="Socre_ChineseStyle_Top.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
end

function ChineseStyleTopBar:setFadeOutAction(  )
    self.m_csbNode:runAction(cc.FadeOut:create(1)) 
end

function ChineseStyleTopBar:initMachine(machine)
    self.m_machine = machine
end

function ChineseStyleTopBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function ChineseStyleTopBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self:findChild("m_lb_grand"),1)
    self:changeNode(self:findChild("m_lb_major"),2)
    self:changeNode(self:findChild("m_lb_minor"),3)
    self:changeNode(self:findChild("m_lb_mini"),4)
    self:updateSize()
end

function ChineseStyleTopBar:updateSize()

    local label1=self:findChild("m_lb_grand")
    local label2=self:findChild("m_lb_major")
    local info1={label=label1}
    local info2={label=label2}
    self:updateLabelSize(info1,210,{info2})

    -- self:updateLabelSize(info2,265)

    local label3=self:findChild("m_lb_minor")
    local label4=self:findChild("m_lb_mini")
    local info3={label=label3,sx=0.9,sy=0.9}
    local info4={label=label4,sx=0.9,sy=0.9}
    self:updateLabelSize(info3,220,{info4})
end

function ChineseStyleTopBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function ChineseStyleTopBar:toAction(actionName)

    self:runCsbAction(actionName)
end


return ChineseStyleTopBar