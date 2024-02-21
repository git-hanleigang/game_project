--jackpot奖池栏
local PenguinsBoomsJackPotBarView = class("PenguinsBoomsJackPotBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "PenguinsBoomsPublicConfig"

local GrandName = "m_lb_coins_1"
local MegaName = "m_lb_coins_2"
local MajorName = "m_lb_coins_3"
local MinorName = "m_lb_coins_4"
local MiniName = "m_lb_coins_5" 

function PenguinsBoomsJackPotBarView:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("PenguinsBooms_jackpot.csb")

    self:clearLightSprite()
    self:initLockEffect()
end

function PenguinsBoomsJackPotBarView:onEnter()
    PenguinsBoomsJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function PenguinsBoomsJackPotBarView:onExit()
    PenguinsBoomsJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function PenguinsBoomsJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1,true)
    self:changeNode(self:findChild(MegaName),  2,true)
    self:changeNode(self:findChild(MajorName), 3,true)
    self:changeNode(self:findChild(MinorName), 4)
    self:changeNode(self:findChild(MiniName),  5)

    self:updateSize()
end

function PenguinsBoomsJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,299)

    local label2=self.m_csbOwner[MajorName]
    local info2={label=label2,sx=0.95,sy=0.95}
    self:updateLabelSize(info2,253)

    local label3=self.m_csbOwner[MegaName]
    local info3={label=label3,sx=0.95,sy=0.95}
    self:updateLabelSize(info3,253)



    local label4=self.m_csbOwner[MinorName]
    local info4={label=label4,sx=0.95,sy=0.95}
    self:updateLabelSize(info4,207)

    local label5=self.m_csbOwner[MiniName]
    local info5={label=label5,sx=0.95,sy=0.95}
    self:updateLabelSize(info5,207)
end

function PenguinsBoomsJackPotBarView:changeNode(label,index,isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    中奖相关时间线
]]
function PenguinsBoomsJackPotBarView:playJackpotTriggerAnim(_jpIndex, _fun)
    local animName = "actionframe"
    self:runCsbAction(animName, true)

    self:setLightSpriteVisible(_jpIndex, true)
end
function PenguinsBoomsJackPotBarView:setLightSpriteVisible(_jpIndex, _visible)
    local spName  = string.format("sp_light_%d", _jpIndex)
    local spLight = self:findChild(spName)
    spLight:setVisible(_visible)
end
function PenguinsBoomsJackPotBarView:clearLightSprite()
    for _jpIndex=1,5 do
        self:setLightSpriteVisible(_jpIndex, false)
    end
end
function PenguinsBoomsJackPotBarView:playJackpotBarIdleAnim()
    self:clearLightSprite()
    self:runCsbAction("idle", false)
end

--[[
    锁定相关
]]
function PenguinsBoomsJackPotBarView:initLockEffect()
    self.m_lockSpine = util_spineCreate("PenguinsBooms_jackpot_suo", true, true)
    self:findChild("Node_suoSpine"):addChild(self.m_lockSpine)
    self.m_lockSpine:setVisible(false)

    self.m_lockTip = util_createAnimation("PenguinsBooms_jackpot_tips.csb")
    self:findChild("Node_tips"):addChild(self.m_lockTip)
    self.m_lockTip:setVisible(false)
    self.m_lockTip.m_playOver = false

    self:initUnLockClick()
end
--锁定时间线
function PenguinsBoomsJackPotBarView:playLockEffect()
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_jackpotBar_lock)
    self.m_lockSpine:stopAllActions()
    self.m_lockSpine:setVisible(true)
    self:setUmLockPanelVisible(true)

    util_spinePlay(self.m_lockSpine, "lock", false)
    performWithDelay(self.m_lockSpine,function()
        util_spinePlay(self.m_lockSpine, "idle", true)
    end, 30/30)
end
function PenguinsBoomsJackPotBarView:playUnLockEffect()
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_jackpotBar_unLock)
    self.m_lockSpine:stopAllActions()
    self:setUmLockPanelVisible(false)

    util_spinePlay(self.m_lockSpine, "unlock", false)
    performWithDelay(self.m_lockSpine,function()
        self.m_lockSpine:setVisible(false)
    end, 21/30)
end
--提示时间线
function PenguinsBoomsJackPotBarView:playLockTipStartAnim()
    if self.m_lockTip:isVisible() then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_jackpotBar_lockTip)
    self.m_lockTip:stopAllActions()
    self.m_lockTip:setVisible(true)
    self.m_lockTip.m_playOver = false

    self.m_lockTip:runCsbAction("start", false)
    performWithDelay(self.m_lockTip,function()
        self:playLockTipOverAnim()
    end, 3)
end
function PenguinsBoomsJackPotBarView:playLockTipOverAnim()
    if not self.m_lockTip:isVisible() or self.m_lockTip.m_playOver then
        return
    end
    self.m_lockTip.m_playOver = true
    self.m_lockTip:stopAllActions()
    
    self.m_lockTip:runCsbAction("over", false)
    performWithDelay(self.m_lockTip,function()
        self.m_lockTip:setVisible(false)
        self.m_lockTip.m_playOver = false
    end, 30/60)
end
--[[
    点击切换到可以解锁的bet
]]
function PenguinsBoomsJackPotBarView:initUnLockClick()
    self.m_panelUnLock = self:findChild("Panel_unLock")
    self:addClick(self.m_panelUnLock)
end
function PenguinsBoomsJackPotBarView:clickFunc(sender)
    local bottomUi  = self.m_machine.m_bottomUI
    local btnBetAdd = bottomUi.m_btn_add
    local bCanClick = btnBetAdd:isTouchEnabled()
    if not bCanClick then
        return
    end

    
    self:onPanelUnLockClick()
end
function PenguinsBoomsJackPotBarView:onPanelUnLockClick()
    self:setUmLockPanelVisible(false)
    self.m_machine:changeBetByLevel(2)
end
function PenguinsBoomsJackPotBarView:setUmLockPanelVisible(_visible)
    self.m_panelUnLock:setVisible(_visible)
end
return PenguinsBoomsJackPotBarView