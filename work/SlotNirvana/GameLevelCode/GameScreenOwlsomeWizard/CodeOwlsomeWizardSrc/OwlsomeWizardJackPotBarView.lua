---
--xcyy
--2018年5月23日
--OwlsomeWizardJackPotBarView.lua
local PublicConfig = require "OwlsomeWizardPublicConfig"
local OwlsomeWizardJackPotBarView = class("OwlsomeWizardJackPotBarView", util_require("base.BaseView"))

local BTN_TAG_MAJOR     =       1001
local BTN_TAG_GRAND     =       1002

function OwlsomeWizardJackPotBarView:initUI(params)
    self:initMachine(params.machine)
    self.m_majorNode = util_createAnimation("OwlsomeWizard_jackpot_major.csb")
    self:addChild(self.m_majorNode)
    self:createLockNode("major",self.m_majorNode)

    self.m_btn_click_major = self.m_majorNode:findChild("btn_click_major")
    self.m_btn_click_major:setTag(BTN_TAG_MAJOR)
    self:addClick(self.m_btn_click_major)
    

    self.m_grandNode = util_createAnimation("OwlsomeWizard_jackpot_grand.csb")
    self:addChild(self.m_grandNode)
    self:createLockNode("grand",self.m_grandNode)

    self.m_btn_click_grand = self.m_grandNode:findChild("btn_click_grand")
    self.m_btn_click_grand:setTag(BTN_TAG_GRAND)
    self:addClick(self.m_btn_click_grand)

end

--[[
    创建锁定节点
]]
function OwlsomeWizardJackPotBarView:createLockNode(jackpotType,jackpotNode)
    local lockNode = util_spineCreate("OwlsomeWizard_jackpot_Lock",true,true)
    jackpotNode:findChild("Node_suoding"):addChild(lockNode)
    jackpotNode.m_lockNode = lockNode

    lockNode:setSkin(jackpotType)
end

function OwlsomeWizardJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function OwlsomeWizardJackPotBarView:onEnter()
    OwlsomeWizardJackPotBarView.super.onEnter(self)
    self.m_grandNode:setPosition(util_convertToNodeSpace(self.m_machine:findChild("Node_grand"),self))
    self.m_majorNode:setPosition(util_convertToNodeSpace(self.m_machine:findChild("Node_major"),self))

    -- self:runIdleAni()

    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

-- 更新jackpot 数值信息
--
function OwlsomeWizardJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self.m_grandNode:findChild("m_lb_coins"), 1, true)
    self:changeNode(self.m_majorNode:findChild("m_lb_coins"), 2, true)

    self:updateSize()
end

function OwlsomeWizardJackPotBarView:updateSize()
    local label1 = self.m_grandNode:findChild("m_lb_coins")
    local label2 = self.m_majorNode:findChild("m_lb_coins")
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    self:updateLabelSize(info1, 207)
    self:updateLabelSize(info2, 207)
end

function OwlsomeWizardJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

--[[
    idle
]]
function OwlsomeWizardJackPotBarView:runIdleAni()
    self.m_majorNode:runCsbAction("idle",true)
    self.m_grandNode:runCsbAction("idle",true)
end

--[[
    中奖动效
]]
function OwlsomeWizardJackPotBarView:hitLightAni(jackpot)
    if jackpot == "major" then
        self.m_majorNode:runCsbAction("actionframe",true)
    else
        self.m_grandNode:runCsbAction("actionframe",true)
    end
end

--[[
    初始化锁定状态(无动画)
]]
function OwlsomeWizardJackPotBarView:initLockStatus(betLevel)
    self.m_majorNode.m_lockNode:setVisible(betLevel < 1)
    self.m_grandNode.m_lockNode:setVisible(betLevel < 2)

    self.m_btn_click_major:setVisible(betLevel < 1)
    self.m_btn_click_grand:setVisible(betLevel < 2)

    self.m_betLevel = betLevel

    util_spinePlay(self.m_majorNode.m_lockNode,"lock",true)
    util_spinePlay(self.m_grandNode.m_lockNode,"lock",true) 

    if betLevel < 1 then
        self.m_majorNode:runCsbAction("idleframe")
        self.m_grandNode:runCsbAction("idleframe")
        
    elseif betLevel == 1 then
        self.m_majorNode:runCsbAction("idle",true)
        self.m_grandNode:runCsbAction("idleframe")

    else
        self:runIdleAni()
    end
end

--[[
    设置锁定状态(有动画)
]]
function OwlsomeWizardJackPotBarView:setLockStatus(betLevel)
    self.m_btn_click_major:setVisible(false)
    self.m_btn_click_grand:setVisible(false)
    if betLevel == 0 then
        local isAim = false
        local isPlay = false
        
        if self.m_betLevel > 1 then
            isAim = true
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_bet_lock)
            isPlay = true
            self.m_grandNode.m_lockNode:setVisible(true)
            self.m_grandNode:runCsbAction("idleframe",true)
            util_spinePlay(self.m_grandNode.m_lockNode,"startlock")
            util_spineEndCallFunc(self.m_grandNode.m_lockNode,"startlock",function()
                util_spinePlay(self.m_grandNode.m_lockNode,"lock",true)
                self.m_btn_click_grand:setVisible(true)
            end)
        end

        if self.m_betLevel > 0 then
            isAim = true
            if not isPlay then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_bet_lock)
            end
            self.m_majorNode.m_lockNode:setVisible(true)
            self.m_majorNode:runCsbAction("idleframe",true)
            util_spinePlay(self.m_majorNode.m_lockNode,"startlock")
            util_spineEndCallFunc(self.m_majorNode.m_lockNode,"startlock",function()
                util_spinePlay(self.m_majorNode.m_lockNode,"lock",true)
                self.m_btn_click_major:setVisible(true)
            end)
        end

        if not isAim then
            self.m_btn_click_major:setVisible(true)
            self.m_btn_click_grand:setVisible(true)
        end
    elseif betLevel == 1 then

        if self.m_betLevel < 1 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_bet_unlock)
            util_spinePlay(self.m_majorNode.m_lockNode,"unlock")
            util_spineEndCallFunc(self.m_majorNode.m_lockNode,"unlock",function()
                self.m_majorNode.m_lockNode:setVisible(false)
                self.m_majorNode:runCsbAction("idle",true)
                self.m_btn_click_grand:setVisible(true)
            end)
        end

        if self.m_betLevel > 1 then
            isAim = true
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_bet_lock)
            self.m_grandNode.m_lockNode:setVisible(true)
            self.m_grandNode:runCsbAction("idleframe",true)
            util_spinePlay(self.m_grandNode.m_lockNode,"startlock")
            util_spineEndCallFunc(self.m_grandNode.m_lockNode,"startlock",function()
                util_spinePlay(self.m_grandNode.m_lockNode,"lock",true)
                self.m_btn_click_grand:setVisible(true)
            end)
        else
            self.m_btn_click_grand:setVisible(true)
        end

    else
        local isPlay = false
       
        if self.m_betLevel < 1 then
            isPlay = true
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_bet_unlock)
            util_spinePlay(self.m_majorNode.m_lockNode,"unlock")
            util_spineEndCallFunc(self.m_majorNode.m_lockNode,"unlock",function()
                self.m_majorNode.m_lockNode:setVisible(false)
                self.m_majorNode:runCsbAction("idle",true)
            end)
        else
            self.m_btn_click_major:setVisible(true)
        end

        if self.m_betLevel < 2 then
            if not isPlay then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_bet_unlock)
            end
            util_spinePlay(self.m_grandNode.m_lockNode,"unlock")
            util_spineEndCallFunc(self.m_grandNode.m_lockNode,"unlock",function()
                self.m_grandNode.m_lockNode:setVisible(false)
                self.m_grandNode:runCsbAction("idle",true)
            end)
        else
            self.m_btn_click_grand:setVisible(true)
        end
    end
    self.m_betLevel = betLevel
end

--默认按钮监听回调
function OwlsomeWizardJackPotBarView:clickFunc(sender)
    if not self.m_machine:collectBarClickEnabled() then
        return
    end

    local tag = sender:getTag()

    self.m_btn_click_major:setVisible(false)
    local betLevel = 2
    if tag == BTN_TAG_MAJOR then
        betLevel = 1
    else
        self.m_btn_click_grand:setVisible(false)
    end

    self.m_machine.m_bottomUI:changeBetCoinNumToHight(betLevel)
    
    
end

return OwlsomeWizardJackPotBarView
