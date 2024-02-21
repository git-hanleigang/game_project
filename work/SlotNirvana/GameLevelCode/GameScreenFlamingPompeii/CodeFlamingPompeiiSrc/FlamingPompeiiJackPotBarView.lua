local FlamingPompeiiJackPotBarView = class("FlamingPompeiiJackPotBarView",util_require("Levels.BaseLevelDialog"))
local FlamingPompeiiPublicConfig = require "FlamingPompeiiPublicConfig"

function FlamingPompeiiJackPotBarView:onEnter()
    FlamingPompeiiJackPotBarView.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function FlamingPompeiiJackPotBarView:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("FlamingPompeii_Jackpotlan.csb")

    util_setCascadeOpacityEnabledRescursion(self,true)

    self:runCsbAction("saoguang", true)
    self:initLockEffect()
    self:initLockTip()
    self:initUnLockClick()
end

-- 更新jackpot 数值信息
function FlamingPompeiiJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    local jackpotList = {
        -- 名称,jackpot索引,宽度,x缩放y缩放
        {"m_lb_coins_grand", 1, 261, 0.87, 1},
        {"m_lb_coins_grand_gray", 1, 261, 0.87, 1},
        {"m_lb_coins_mega",  2, 223, 0.75, 0.75},
        {"m_lb_coins_major", 3, 223, 0.75, 0.75},
        {"m_lb_coins_minor", 4, 176, 0.7,  0.7},
        {"m_lb_coins_mini",  5, 176, 0.7,  0.7},
        {"m_lb_coins_minor_reSpin", 4, 176, 0.7,  0.7},
        {"m_lb_coins_mini_reSpin",  5, 176, 0.7,  0.7},
    }
    for i,_data in ipairs(jackpotList) do
        local label = self:findChild(_data[1])
        local value = self.m_machine:BaseMania_updateJackpotScore(_data[2])
        label:setString(util_formatCoins(value, 20, nil, nil, true))
        local info = {label=label, sx=_data[4], sy=_data[5]}
        self:updateLabelSize(info, _data[3])
    end
end



function FlamingPompeiiJackPotBarView:setShowState(_model)
    local bBase = "base" == _model
    local bReSpin = "reSpin" == _model

    self:findChild("Node_base"):setVisible(bBase)
    self:findChild("Node_reSpin"):setVisible(bReSpin)
    self:stopUpDateOpacity()
    if bReSpin then
        self:upDateOpacity()
    end
end

function FlamingPompeiiJackPotBarView:upDateOpacity()
    local node_megamajor = self:findChild("Node_mega_major")
    local node_minormini = self:findChild("Node_reSpin")
    --渐变时间
    local fadeTime   = 0.5
    --持续时间
    local delayTime  = 5
    
    local sequence_1 = cc.Sequence:create(
        cc.FadeIn:create(fadeTime), 
        cc.DelayTime:create(delayTime), 
        cc.FadeOut:create(fadeTime), 
        cc.DelayTime:create(delayTime)
    )
    local sequence_2 = cc.Sequence:create(
        cc.FadeOut:create(fadeTime), 
        cc.DelayTime:create(delayTime), 
        cc.FadeIn:create(fadeTime), 
        cc.DelayTime:create(delayTime)
    )
    node_megamajor:setOpacity(255)
    node_minormini:setOpacity(0)
    node_megamajor:runAction( cc.RepeatForever:create(sequence_1) )
    node_minormini:runAction( cc.RepeatForever:create(sequence_2) )
end
function FlamingPompeiiJackPotBarView:stopUpDateOpacity()
    local node_megamajor = self:findChild("Node_mega_major")
    local node_minormini = self:findChild("Node_reSpin")
    node_megamajor:stopAllActions()
    node_minormini:stopAllActions()
    node_megamajor:setOpacity(255)
    node_minormini:setOpacity(255)
end

--[[
    grand锁定
]]
function FlamingPompeiiJackPotBarView:setGrandLockState(_bLock)
    local spGrandBg = self:findChild("sp_grandBg")
    local spGrandBgGray = self:findChild("sp_grandBg_gray")
    local spGrandTitle = self:findChild("sp_grandTitle")
    local spGrandTitleGray = self:findChild("sp_grandTitle_gray")
    local labGrand = self:findChild("m_lb_coins_grand")
    local labGrandGray = self:findChild("m_lb_coins_grand_gray")

    spGrandBg:setVisible(not _bLock)
    spGrandBgGray:setVisible(_bLock)
    spGrandTitle:setVisible(not _bLock)
    spGrandTitleGray:setVisible(_bLock)
    labGrand:setVisible(not _bLock)
    labGrandGray:setVisible(_bLock)
    self:findChild("sp_grandLight"):setVisible(not _bLock)
    self.m_PanelUnLock:setVisible(_bLock)
end
--[[
    锁定特效
]]
function FlamingPompeiiJackPotBarView:initLockEffect()
    self.m_lockEffect = util_createAnimation("FlamingPompeii_Jackpotlan_jiesuo.csb")
    self:findChild("Node_jiesuo"):addChild(self.m_lockEffect)
    self.m_lockEffect:setVisible(false)
end
function FlamingPompeiiJackPotBarView:playLockEffect()
    self.m_lockEffect:stopAllActions()
    self.m_lockEffect:setVisible(true)
    self.m_lockEffect:runCsbAction("darkover", false)
    --第18帧硬切灰色
    performWithDelay(self.m_lockEffect,function()
        self:setGrandLockState(true)
        performWithDelay(self.m_lockEffect,function()
            self.m_lockEffect:setVisible(false)
        end, 18/60)
    end, 24/60)
end
function FlamingPompeiiJackPotBarView:playUnLockEffect()
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_jackpotBar_unLock)
    
    self.m_lockEffect:stopAllActions()
    self.m_lockEffect:setVisible(true)
    self.m_lockEffect:runCsbAction("darkstart", false)
    --第12帧硬切亮色
    performWithDelay(self.m_lockEffect,function()
        self:setGrandLockState(false)
        performWithDelay(self.m_lockEffect,function()
            self.m_lockEffect:setVisible(false)
        end, 48/60)
    end, 12/60)
end
--[[
    锁定提示
]]
function FlamingPompeiiJackPotBarView:initLockTip()
    self.m_lockTip = util_createAnimation("FlamingPompeii_Jackpotsuoding.csb")
    self:findChild("Node_Jackpotsuoding"):addChild(self.m_lockTip)
    self.m_lockTip:setVisible(false)
    self.m_lockTip.m_bOver = false
end
function FlamingPompeiiJackPotBarView:showLockTip()
    if self.m_lockTip:isVisible() then
        return
    end
    self.m_lockTip:setVisible(true)
    self.m_lockTip.m_bOver = false
    self.m_lockTip:runCsbAction("start")
    performWithDelay(self.m_lockTip,function()
        self:hideLockTip()
    end, 3)
end
function FlamingPompeiiJackPotBarView:hideLockTip()
    if not self.m_lockTip:isVisible() or self.m_lockTip.m_bOver then
        return
    end
    self.m_lockTip.m_bOver = true
    self.m_lockTip:stopAllActions()
    self.m_lockTip:runCsbAction("over", false, function()
        self.m_lockTip:setVisible(false)
        self.m_lockTip.m_bOver = false
    end)
end
--[[
    点击切换到可以解锁的bet
]]
function FlamingPompeiiJackPotBarView:initUnLockClick()
    self.m_PanelUnLock = self:findChild("Panel_unLock")
    self:addClick(self.m_PanelUnLock)
end
function FlamingPompeiiJackPotBarView:clickFunc(sender)
    local bottomUi  = self.m_machine.m_bottomUI
    local btnBetAdd = bottomUi.m_btn_add
    local bCanClick = btnBetAdd:isTouchEnabled()
    if not bCanClick then
        return
    end
    self:onPanelUnLockClick()
end
function FlamingPompeiiJackPotBarView:onPanelUnLockClick()
    self.m_PanelUnLock:setVisible(false)
    local unLockBet  = self.m_machine.m_grandLockBet
    local betId = globalData.slotRunData:changeMoreThanBet(unLockBet)
    globalData.slotRunData.iLastBetIdx =   betId
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

return FlamingPompeiiJackPotBarView