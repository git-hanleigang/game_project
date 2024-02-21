---
--xcyy
--2018年5月23日
--JackpotOGoldJackPotSuperBarView.lua

local JackpotOGoldJackPotSuperBarView = class("JackpotOGoldJackPotSuperBarView",util_require("Levels.BaseLevelDialog"))

function JackpotOGoldJackPotSuperBarView:initUI()

    self:createCsbNode("JackpotOGold_Jackpot_Super.csb")

    self:runCsbAction("idle",true)

    local Panel_1 = self:findChild("Panel_1")
    self:addClick(Panel_1)


    self.m_Suolian = util_createAnimation("JackpotOGold_Suolian.csb")
    local Node_suolian = self:findChild("Node_suolian")
    Node_suolian:addChild(self.m_Suolian)
    self.m_Suolian:runCsbAction("idle", true)
    self.m_Suolian:findChild("Node_grand"):setVisible(true)
    self.m_Suolian:findChild("Node_super"):setVisible(false)


    self.lockStatus = "unlock"

    self.m_Grand_bg_0 = self:findChild("Grand_bg_0")
    self.m_Grand_bg_0:setVisible(false)
end


function JackpotOGoldJackPotSuperBarView:onEnter()
    JackpotOGoldJackPotSuperBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function JackpotOGoldJackPotSuperBarView:onExit()
    JackpotOGoldJackPotSuperBarView.super.onExit(self)
end

function JackpotOGoldJackPotSuperBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function JackpotOGoldJackPotSuperBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    self:changeNode(self:findChild("m_lb_coins"),2,true)
    self:changeNode(self:findChild("m_lb_coins_0"),2,true)

    self:updateSize()
end

function JackpotOGoldJackPotSuperBarView:updateSize()

    local label1=self.m_csbOwner["m_lb_coins"]
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,436)

    local label2=self.m_csbOwner["m_lb_coins_0"]
    local info2={label=label2,sx=1,sy=1}
    self:updateLabelSize(info2,436)

end

function JackpotOGoldJackPotSuperBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function JackpotOGoldJackPotSuperBarView:clickFunc(sender)
    local sBtnName = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if sBtnName == "Panel_1" then
        if self.m_machine:checkIsUnLockJackpot() then
            if self.m_machine:checkIsLock(1) then
                self:unLock()
                self.m_machine.m_bottomUI:changeBetCoinNumToHight(1)
            end
        end
    end
end

function JackpotOGoldJackPotSuperBarView:lock(isInit)
    if isInit then
        self.m_Suolian:setVisible(true)
        self:findChild("Panel_1"):setOpacity(255 * 0.45)
        self.m_Suolian:runCsbAction("idle", true)
        self.m_csbOwner["m_lb_coins"]:setVisible(false)
        self.m_csbOwner["m_lb_coins_0"]:setVisible(true)
        self.lockStatus = "lock"
        
        return
    end
    if self.lockStatus == "lock" then
        return
    end
    local lockCallBack = function()
        self.m_csbOwner["m_lb_coins"]:setVisible(false)
        self.m_csbOwner["m_lb_coins_0"]:setVisible(true)
        self.m_Suolian:setVisible(true)
        self:findChild("Panel_1"):setOpacity(255 * 0.45)
        self.m_Suolian:runCsbAction("idle", true)
    end

    self.lockStatus = "lock"
    self.m_csbOwner["m_lb_coins"]:setVisible(false)
    self.m_csbOwner["m_lb_coins_0"]:setVisible(true)
    self.m_Suolian:setVisible(true)
    self:findChild("Panel_1"):setOpacity(0)
    self:findChild("Panel_1"):runAction(cc.FadeIn:create(0.5))
    self.m_Suolian:runCsbAction("start", false, lockCallBack)
end

function JackpotOGoldJackPotSuperBarView:unLock(isInit, isPlaySound)
    local isPlaySound = isPlaySound == nil and true or isPlaySound
    if isInit then
        self.m_Suolian:setVisible(false)
        self.m_csbOwner["m_lb_coins"]:setVisible(true)
        self.m_csbOwner["m_lb_coins_0"]:setVisible(false)
        self:findChild("Panel_1"):setOpacity(0)
        self.lockStatus = "unlock"

        return
    end
    if self.lockStatus == "unlock" then
        return
    end
    local unLockCallBack = function()
        self.m_Suolian:setVisible(false)
        self.m_csbOwner["m_lb_coins"]:setVisible(true)
        self.m_csbOwner["m_lb_coins_0"]:setVisible(false)
        self:findChild("Panel_1"):setOpacity(0)
    end

    if isPlaySound then
        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_Jackpot_unlock.mp3")
    end
    
    self.lockStatus = "unlock"
    self:findChild("Panel_1"):runAction(cc.FadeOut:create(0.5))
    self.m_Suolian:stopAllActions()
    self.m_Suolian:runCsbAction("over", false, unLockCallBack)
end

return JackpotOGoldJackPotSuperBarView