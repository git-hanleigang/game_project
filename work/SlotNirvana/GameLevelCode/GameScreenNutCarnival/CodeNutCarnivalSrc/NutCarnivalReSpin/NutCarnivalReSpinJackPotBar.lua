local NutCarnivalReSpinJackPotBar = class("NutCarnivalReSpinJackPotBar",util_require("Levels.BaseLevelDialog"))

function NutCarnivalReSpinJackPotBar:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("NutCarnival_jackpot_respin.csb")

    self:initJackpotLabInfo()
end

function NutCarnivalReSpinJackPotBar:onEnter()
    NutCarnivalReSpinJackPotBar.super.onEnter(self)

    schedule(self:findChild("root"),function()
        self:updateJackpotInfo()
    end,0.08)
end
--[[
    jackpot文本刷新
]]
function NutCarnivalReSpinJackPotBar:initJackpotLabInfo()
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
function NutCarnivalReSpinJackPotBar:updateJackpotInfo()
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
    grand锁定
]]
function NutCarnivalReSpinJackPotBar:setGrandLockState(_bLock)
    local lockNode = self:findChild("Node_grandLock")
    lockNode:setVisible(_bLock)
end

--[[
    时间线
]]
function NutCarnivalReSpinJackPotBar:playIdleAnim()
    self:setLightSpriteVisible(0)
    self:runCsbAction("idle", true)
end
function NutCarnivalReSpinJackPotBar:playFadeAction()
    self:stopFadeAction()
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
function NutCarnivalReSpinJackPotBar:stopFadeAction()
    local node_1 = self:findChild("Node_major_maxi")
    local node_2 = self:findChild("Node_minor_mini")
    node_1:stopAllActions()
    node_2:stopAllActions()
end
--reSpin转盘时取消轮播
function NutCarnivalReSpinJackPotBar:showReSpinWheelJackpotBar()
    self:stopFadeAction()
    self:findChild("Node_major_maxi"):setOpacity(255)
    self:findChild("Node_minor_mini"):setOpacity(0)
end
--中奖
function NutCarnivalReSpinJackPotBar:playActionframeAnim(_jpIndex, _fun)
    self:setLightSpriteVisible(_jpIndex)
    self:runCsbAction("actionframe", true)
end
function NutCarnivalReSpinJackPotBar:setLightSpriteVisible(_jpIndex)
    self:findChild("light_1"):setVisible(1 == _jpIndex)
    self:findChild("light_2"):setVisible(2 == _jpIndex or 4 == _jpIndex)
    self:findChild("light_3"):setVisible(3 == _jpIndex or 5 == _jpIndex)
end

return NutCarnivalReSpinJackPotBar