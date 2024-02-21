---
--xcyy
--2018年5月23日
--BankCrazeTopBarView.lua
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeTopBarView = class("BankCrazeTopBarView",util_require("Levels.BaseLevelDialog"))
BankCrazeTopBarView.m_totalCount = 10

function BankCrazeTopBarView:initUI(_machine)
    self:createCsbNode("BankCraze_Jindutiao.csb")
    self.m_machine = _machine

    --收集栏
    self.m_collectView = util_createView("CodeBankCrazeCollectSrc.BankCrazeCollectView", self)
    self:findChild("Node_collect"):addChild(self.m_collectView)

    --收集栏银行
    self.m_bankView = util_createView("CodeBankCrazeCollectSrc.BankCrazeTopBankView", self)
    self:findChild("Node_bank"):addChild(self.m_bankView)

    -- 粒子
    self.m_particleTbl = {}
    for i=1, 2 do
        self.m_particleTbl[i] = self:findChild("Particle_"..i)
        self.m_particleTbl[i]:setVisible(false)
    end

    -- 粒子
    self.m_actParticle = self:findChild("Particle_3")
    self.m_actParticle:setVisible(false)
    
    self:addClick(self:findChild("Panel_click"))

    self:playIdle()

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function BankCrazeTopBarView:playIdle()
    self:runCsbAction("idle", true)
end

function BankCrazeTopBarView:playHeightIdle()
    self:runCsbAction("idle2", true)
end

--默认按钮监听回调
function BankCrazeTopBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" and self.m_machine:bonusBtnIsCanClick() and self.m_machine.m_curBankLevel < 3 then
        self.m_machine.m_collectTipsView:showTips(self.m_machine.m_curBankLevel)
    end
end

-- 收集saveBonus
function BankCrazeTopBarView:collectSaveBonus(_onEnter, _curBankLevel, _collectCount)
    self.m_collectView:collectSaveBonus(_onEnter, _curBankLevel, _collectCount)
    if _onEnter and _curBankLevel == 3 then
        self:playHeightIdle()
    end
end

-- 从高档到低档转换
-- isHeightLevel：是否为最高档
function BankCrazeTopBarView:playHeightToLowAct(_isHeightLevel)
    self.m_collectView:playHeightToLowAct(_isHeightLevel)
    if _isHeightLevel then
        self:runCsbAction("start", false, function()
            self:playIdle()
        end)
    end
end

-- 集满触发；清空
function BankCrazeTopBarView:playTriggerAct(_curLevel)
    -- 粒子
    for i=1, 2 do
        self.m_particleTbl[i]:setVisible(true)
        self.m_particleTbl[i]:resetSystem()
    end
    self.m_machine:delayCallBack(1.0,function()
        for i=1, 2 do
            self.m_particleTbl[i]:stopSystem()
        end
    end)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectBar_Flicker)
    self:runCsbAction("actionframe", false, function()
        if _curLevel == 3 then
            self:runCsbAction("actionframe2", false, function()
                self:playHeightIdle()
            end)
            self.m_collectView:playTriggerAct(_curLevel)
        else
            self.m_actParticle:setVisible(true)
            self.m_actParticle:resetSystem()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CollectBar_Light)
            self:runCsbAction("actionframe3", false, function()
                self:playIdle()
                self.m_actParticle:stopSystem()
            end)
            self.m_collectView:playTriggerAct(_curLevel)
        end
    end)
end

function BankCrazeTopBarView:refreshShowType(_isFreeMode)
    self:findChild("Free"):setVisible(_isFreeMode)
    self.m_bankView:setVisible(not _isFreeMode)
end

return BankCrazeTopBarView
