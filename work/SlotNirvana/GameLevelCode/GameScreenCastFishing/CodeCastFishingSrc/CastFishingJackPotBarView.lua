local CastFishingJackPotBarView = class("CastFishingJackPotBarView",util_require("Levels.BaseLevelDialog"))

function CastFishingJackPotBarView:onEnter()
    CastFishingJackPotBarView.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function CastFishingJackPotBarView:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("CastFishing_Jackpot.csb")

    util_setCascadeOpacityEnabledRescursion(self,true)
end

-- 更新jackpot 数值信息
--
function CastFishingJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    local jackpotList = {
        -- 名称,jackpot索引,宽度,x缩放y缩放
        {"m_lb_coins_grand", 1, 461, 0.87, 1},
        {"m_lb_coins_mega",  2, 428, 0.7,  0.7},
        {"m_lb_coins_major", 3, 428, 0.65, 0.65},
        {"m_lb_coins_minor", 4, 428, 0.7,  0.7},
        {"m_lb_coins_mini",  5, 428, 0.65, 0.65},
    }
    for i,_data in ipairs(jackpotList) do
        local label = self:findChild(_data[1])
        local value = self.m_machine:BaseMania_updateJackpotScore(_data[2])
        label:setString(util_formatCoins(value, 20, nil, nil, true))
        local info = {label=label, sx=_data[4], sy=_data[5]}
        self:updateLabelSize(info, _data[3])
    end
end

function CastFishingJackPotBarView:upDateOpacity()
    local node_megamajor = self:findChild("Node_megamajor")
    local node_minormini = self:findChild("Node_minormini")
    node_megamajor:stopAllActions()
    node_minormini:stopAllActions()
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

--[[
    进入bonus隐藏下面两组jackpot栏
]]
function CastFishingJackPotBarView:enterBonusHideJackpotBar()
    local node_megamajor = self:findChild("Node_megamajor")
    local node_minormini = self:findChild("Node_minormini")
    node_megamajor:stopAllActions()
    node_minormini:stopAllActions()
    node_megamajor:setVisible(false)
    node_minormini:setVisible(false)
end
function CastFishingJackPotBarView:leaveBonusShowJackpotBar()
    local node_megamajor = self:findChild("Node_megamajor")
    local node_minormini = self:findChild("Node_minormini")
    node_megamajor:setVisible(true)
    node_minormini:setVisible(true)
    self:upDateOpacity()
end
return CastFishingJackPotBarView