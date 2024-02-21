---
--xcyy
--2018年5月23日
--HogHustlerJackPotBarView.lua

local HogHustlerJackPotBarView = class("HogHustlerJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_num_coins_grand"
local MajorName = "m_lb_num_coins_major"
local MinorName = "m_lb_num_coins_minor"
local MiniName = "m_lb_num_coins_mini" 

function HogHustlerJackPotBarView:initUI()

    self:createCsbNode("HogHustler_jackpot.csb")

    self:runCsbAction("idle", true)

    self.m_effectLight = util_createAnimation("HogHustler_jackpot_2.csb")
    self:findChild("zhongjiang"):addChild(self.m_effectLight)
    self.m_effectLight:setVisible(false)
end



function HogHustlerJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function HogHustlerJackPotBarView:onEnter()

    HogHustlerJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function HogHustlerJackPotBarView:onExit()
    HogHustlerJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function HogHustlerJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function HogHustlerJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,238)
    -- self:updateLabelSize(info2,219)
    -- self:updateLabelSize(info3,219)
    -- self:updateLabelSize(info4,219)

    local scale = label1:getScale()
    label2:setScale(scale)
    label3:setScale(scale)
    label4:setScale(scale)
end

function HogHustlerJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function HogHustlerJackPotBarView:showEffectLight(index)
    local name = {"mini", "minor", "major", "grand"}
    for i=1,#name do
        self.m_effectLight:findChild(name[i]):setVisible(i == index)
    end

    self.m_effectLight:setVisible(true)
    self.m_effectLight:runCsbAction("idle", true)
    util_playFadeInAction(self.m_effectLight, 0.1)
end

function HogHustlerJackPotBarView:hideEffectLight(index)
    local name = {"mini", "minor", "major", "grand"}
    for i=1,#name do
        self.m_effectLight:findChild(name[i]):setVisible(i == index)
    end
    util_playFadeOutAction(self.m_effectLight, 0.1, function()
        self.m_effectLight:setVisible(false)
    end)
end

-- function HogHustlerJackPotBarView:updateLabelSize(info, length, otherInfo)
--     local _label = info.label
--     if _label.mulNode then
--         _label = _label.mulNode
--     end
--     local width = _label:getContentSize().width
--     local scale = length / width
--     if width <= length then
--         scale = 1
--     end

--     _label:setScaleX(scale * (info.sx or 1))
--     _label:setScaleY(scale * (info.sy or 1))
--     if otherInfo and #otherInfo > 0 then
--         for k, orInfo in ipairs(otherInfo) do
--             orInfo.label:setScaleX(scale * (orInfo.sx or 1))
--             orInfo.label:setScaleY(scale * (orInfo.sy or 1))
--         end
--     end
-- end

return HogHustlerJackPotBarView