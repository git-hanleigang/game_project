---
--xcyy
--2018年5月23日
--MagneticBreakInJackPotBarView.lua

local MagneticBreakInJackPotBarView = class("MagneticBreakInJackPotBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MagneticBreakInPublicConfig"

local GrandName = "m_lb_grand"
local MegaName = "m_lb_mega"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function MagneticBreakInJackPotBarView:initUI()

    self:createCsbNode("JackPotBarMagneticBreakIn.csb")

    self.m_lockStatus = false

    --锁
    self.lockEffect = util_createAnimation("JackPotBarMagneticBreakIn_lock.csb")
    self:findChild("Node_lock"):addChild(self.lockEffect)

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:findChild("root"):addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    local pos = util_convertToNodeSpace(self:findChild("MagneticBreakIn_Jackpot_glow_3"),self:findChild("root"))
    layout:setPosition(pos)
    layout:setContentSize(CCSizeMake(379,65))
    layout:setTouchEnabled(true)
    self:addClick(layout,1000)

    self:showIdleAct()
    self.showNode = cc.Node:create()
    self:addChild(self.showNode)
end

function MagneticBreakInJackPotBarView:onEnter()

    MagneticBreakInJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function MagneticBreakInJackPotBarView:onExit()
    MagneticBreakInJackPotBarView.super.onExit(self)
end

function MagneticBreakInJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function MagneticBreakInJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MegaName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self:findChild(MinorName),4)
    self:changeNode(self:findChild(MiniName),5)

    self:updateSize()
end

function MagneticBreakInJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MegaName]
    local label3=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.83,sy=0.83}
    local info3={label=label3,sx=0.83,sy=0.83}
    local label4=self.m_csbOwner[MinorName]
    local info4={label=label4,sx=0.84,sy=0.84}
    local label5=self.m_csbOwner[MiniName]
    local info5={label=label5,sx=0.81,sy=0.81}
    self:updateLabelSize(info1,361)
    self:updateLabelSize(info2,269)
    self:updateLabelSize(info3,269)
    self:updateLabelSize(info4,215)
    self:updateLabelSize(info5,240)
end

function MagneticBreakInJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,50,nil,nil,true))
    -- if value <= 0 then
    --     local sMsg = "p_id："..globalData.slotRunData.machineData.p_id .. "totalBet:" .. globalData.slotRunData:getCurTotalBet()

    --     util_printLog(sMsg, true)
    -- end
end

function MagneticBreakInJackPotBarView:showJackpotLock()
    self.m_lockStatus = true
    self.showNode:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_betLock)
    self.lockEffect:runCsbAction("lock",false)
    performWithDelay(self.showNode,function ()
        self.lockEffect:runCsbAction("lock_idle",true)
    end,0.5)
end

function MagneticBreakInJackPotBarView:showJackpotUnLock()
    self.m_lockStatus = false
    self.showNode:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagneticBreakIn_betUnLock)
    local particle = self.lockEffect:findChild("Particle_1")
    if particle then
        particle:resetSystem()
    end
    self.lockEffect:runCsbAction("unlock",false)
end

function MagneticBreakInJackPotBarView:showGetJackpotAct(index)
    self:runCsbAction("actionframe"..index,true)
end

function MagneticBreakInJackPotBarView:showIdleAct()
    self:runCsbAction("idle")
end

--默认按钮监听回调
function MagneticBreakInJackPotBarView:clickFunc(sender)
    if self.m_lockStatus then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

return MagneticBreakInJackPotBarView