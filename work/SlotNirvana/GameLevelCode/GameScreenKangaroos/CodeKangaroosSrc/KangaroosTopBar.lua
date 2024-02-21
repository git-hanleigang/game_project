---
--xhkj
--2018年6月11日
--KangaroosTopBar.lua

local KangaroosTopBar = class("KangaroosTopBar", util_require("base.BaseView"))
KangaroosTopBar.m_animationID = nil

function KangaroosTopBar:initUI(data)

    local resourceFilename="Socre_Kangaroos_Top.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)

    self.m_animationID = 1
    self:runCsbAction("idle"..self.m_animationID)

    schedule(self, function()
        if self.m_animationID > 3 then
            self.m_animationID = 1
        end
        self:runCsbAction("change"..self.m_animationID)
        self.m_animationID = self.m_animationID + 1
    end, 5)
end

function KangaroosTopBar:setFadeOutAction(  )
    self.m_csbNode:runAction(cc.FadeOut:create(1)) 
end

function KangaroosTopBar:initMachine(machine)
    self.m_machine = machine
end

function KangaroosTopBar:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
    util_setCascadeOpacityEnabledRescursion(self,true)
end

-- 更新jackpot 数值信息
--
function KangaroosTopBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("m_lb_grand"),1,true)
    self:changeNode(self:findChild("m_lb_major"),2,true)
    self:changeNode(self:findChild("m_lb_minor"),3)
    self:updateSize()
end

function KangaroosTopBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local label3=self.m_csbOwner["m_lb_minor"]
    local info1={label=label1}
    local info2={label=label2}
    local info3={label=label3}
    self:updateLabelSize(info1,340,{info2, info3})
end

function KangaroosTopBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end

function KangaroosTopBar:toAction(actionName)
    self:runCsbAction(actionName)
end


-- 如果本界面需要添加touch 事件，则从BaseView 获取

return KangaroosTopBar