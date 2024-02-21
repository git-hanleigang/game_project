local NutCarnivalJackPotBar = class("NutCarnivalJackPotBar",util_require("Levels.BaseLevelDialog"))

function NutCarnivalJackPotBar:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("NutCarnival_jackpot_base.csb")

    util_setCascadeOpacityEnabledRescursion(self,true)

    self:initJackpotLabInfo()

    self:initLockEffect()
    self:initUnLockClick()
end

function NutCarnivalJackPotBar:onEnter()
    NutCarnivalJackPotBar.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end
--[[
    jackpot文本刷新
]]
function NutCarnivalJackPotBar:initJackpotLabInfo()
    self.m_jackpotLabInfo = {
        -- 名称,jackpot索引,宽度,x缩放y缩放
        {"m_lb_coins_1", 1, 100, 1, 1},
        {"m_lb_coins_2", 2, 100, 1, 1},
        {"m_lb_coins_3", 3, 100, 1, 1},
        {"m_lb_coins_4", 4, 100, 1, 1},
        {"m_lb_coins_5", 5, 100, 1, 1},
    }
    for i,_labInfo in ipairs(self.m_jackpotLabInfo) do
        local lab     = self:findChild(_labInfo[1])
        local labSize = lab:getContentSize()
        _labInfo[3] = labSize.width
        _labInfo[4] = lab:getScaleX()
        _labInfo[5] = lab:getScaleY()
    end
end
-- 更新jackpot 数值信息
function NutCarnivalJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    for i,_labInfo in ipairs(self.m_jackpotLabInfo) do
        local label = self:findChild(_labInfo[1])
        local value = self.m_machine:BaseMania_updateJackpotScore(_labInfo[2])
        label:setString(util_formatCoins(value, 20, nil, nil, true))
        local info = {label=label, sx=_labInfo[4], sy=_labInfo[5]}
        self:updateLabelSize(info, _labInfo[3])
    end
end

--[[
    锁定特效
]]
function NutCarnivalJackPotBar:initLockEffect()
    self.m_lockParent = self:findChild("Node_grandLock")
end
function NutCarnivalJackPotBar:playLockEffect()
    self.m_lockParent:stopAllActions()
    self:setUnLockPanelVisible(true)

    self.m_lockParent:setVisible(true)
    local animName = "suoding"
    local animTime = util_csbGetAnimTimes(self.m_csbAct, animName)
    self:runCsbAction(animName, false)
    performWithDelay(self.m_lockParent,function()
        self:playIdleAnim()
    end, animTime)
end
function NutCarnivalJackPotBar:playUnLockEffect()
    self.m_lockParent:stopAllActions()
    self:setUnLockPanelVisible(false)

    local animName = "jiesuo"
    local animTime = util_csbGetAnimTimes(self.m_csbAct, animName)
    self:runCsbAction(animName, false)
    performWithDelay(self.m_lockParent,function()
        self:playIdleAnim()
        self.m_lockParent:setVisible(false)
    end, 51/60)
end

--[[
    点击切换到可以解锁的bet
]]
function NutCarnivalJackPotBar:initUnLockClick()
    self.m_PanelUnLock = self:findChild("Panel_unLock")
    self:addClick(self.m_PanelUnLock)
end
function NutCarnivalJackPotBar:setUnLockPanelVisible(_visible)
    self.m_PanelUnLock:setVisible(_visible)
end
function NutCarnivalJackPotBar:clickFunc(sender)
    local bottomUi  = self.m_machine.m_bottomUI
    local btnBetAdd = bottomUi.m_btn_add
    local bCanClick = btnBetAdd:isTouchEnabled()
    if not bCanClick then
        return
    end
    self:onPanelUnLockClick()
end
function NutCarnivalJackPotBar:onPanelUnLockClick()
    self:setUnLockPanelVisible(false)
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local unLockBet  = specialBets[1].p_totalBetValue
    local betId = globalData.slotRunData:changeMoreThanBet(unLockBet)
    globalData.slotRunData.iLastBetIdx =   betId
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

--[[
    时间线
]]
function NutCarnivalJackPotBar:playIdleAnim()
    self:runCsbAction("idle", true)
end
function NutCarnivalJackPotBar:playFadeAction()
    local node_1 = self:findChild("Node_major_maxi")
    local node_2 = self:findChild("Node_minor_mini")
    --渐变时间
    local fadeTime  = 0.5
    --持续时间
    local delayTime = 5
    
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
    node_1:setOpacity(255)
    node_2:setOpacity(0)
    node_1:runAction( cc.RepeatForever:create(sequence_1) )
    node_2:runAction( cc.RepeatForever:create(sequence_2) )
end

return NutCarnivalJackPotBar