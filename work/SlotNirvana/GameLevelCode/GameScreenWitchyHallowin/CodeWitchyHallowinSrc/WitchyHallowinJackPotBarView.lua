---
--xcyy
--2018年5月23日
--WitchyHallowinJackPotBarView.lua

local WitchyHallowinJackPotBarView = class("WitchyHallowinJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_1"
local MajorName = "m_lb_coins_2"
local MinorName = "m_lb_coins_3"
local MiniName = "m_lb_coins_4" 

function WitchyHallowinJackPotBarView:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("WitchyHallowin_Jackpot.csb")

    self.m_hitLightAni = util_createAnimation("WitchyHallowin_Jackpot_tx.csb")
    self:findChild("ef_tx_grand"):addChild(self.m_hitLightAni)
    self.m_hitLightAni:setVisible(false)
    self.m_hitLightAni:findChild("Sprite_3"):setVisible(false)

    --延时节点
    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode)

    --当前动画
    self.aniIndex = 1
end

function WitchyHallowinJackPotBarView:onEnter()

    WitchyHallowinJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function WitchyHallowinJackPotBarView:onExit()
    WitchyHallowinJackPotBarView.super.onExit(self)
end

function WitchyHallowinJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function WitchyHallowinJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:changeNode(self:findChild("m_lb_coins_5"),3)
    self:changeNode(self:findChild("m_lb_coins_6"),4)

    self:updateSize()

    
end

function WitchyHallowinJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.9,sy=0.9}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.9,sy=0.9}

    local label5=self.m_csbOwner["m_lb_coins_5"]
    local info5={label=label5,sx=0.9,sy=0.9}
    local label6=self.m_csbOwner["m_lb_coins_6"]
    local info6={label=label6,sx=0.9,sy=0.9}
    self:updateLabelSize(info1,329)
    self:updateLabelSize(info2,329)
    self:updateLabelSize(info3,309)
    self:updateLabelSize(info4,307)
    self:updateLabelSize(info5,309)
    self:updateLabelSize(info6,307)
end

function WitchyHallowinJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    转换成单行显示
]]
function WitchyHallowinJackPotBarView:switchToSpecial()
    self:runCsbAction("switch",false,function()
        performWithDelay(self.m_delayNode,function(  )
            self:delaySwitch()
        end,3.5)
    end)
end

--[[
    延时切换
]]
function WitchyHallowinJackPotBarView:delaySwitch()
    self:runCsbAction("actionframe"..self.aniIndex)
    performWithDelay(self.m_delayNode,function(  )
        performWithDelay(self.m_delayNode,function(  )
            self:delaySwitch()
        end,3.5)
    end,15 / 60)
    self.aniIndex = self.aniIndex + 1
    if self.aniIndex > 3 then
        self.aniIndex = 1
    end
end

--[[
    转换成普通显示
]]
function WitchyHallowinJackPotBarView:switchToNormal( )
    self.m_delayNode:stopAllActions()
    self.aniIndex = 1
    self:runCsbAction("idle")
end

--[[
    显示中奖光效
]]
function WitchyHallowinJackPotBarView:showHitLightAni(func)
    self.m_hitLightAni:setVisible(true)
    self.m_hitLightAni:runCsbAction("start",false,function(  )
        self.m_hitLightAni:runCsbAction("actionframe",true)
    end)
end

--[[
    隐藏中奖光效
]]
function WitchyHallowinJackPotBarView:hideHitLightAni(func)
    self.m_hitLightAni:runCsbAction("over",false,function(  )
        self.m_hitLightAni:setVisible(false)
    end)
end

return WitchyHallowinJackPotBarView