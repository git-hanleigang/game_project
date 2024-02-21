local MagicSpiritJackPotBarView = class("MagicSpiritJackPotBarView", util_require("base.BaseView"))

MagicSpiritJackPotBarView.m_maxZunNum = 6
MagicSpiritJackPotBarView.m_lightAniIndex = 6

function MagicSpiritJackPotBarView:initUI()
    self:createCsbNode("MagicSpirit_jackpot.csb")

    for i = 2,self.m_maxZunNum do
        self["zuanshiUi_"..i] = util_createAnimation("MagicSpirit_jackpot_zuanshi.csb")
        self:findChild("zuanshi_"..i):addChild(self["zuanshiUi_"..i]) 
    end

    self:initLabelSizeParams()

    self.m_JpBarWaitNode = cc.Node:create()
    self:addChild(self.m_JpBarWaitNode)

    self.m_isPlayIdleAction = false
    self:beginLight( )
end

function MagicSpiritJackPotBarView:onExit()
end

function MagicSpiritJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MagicSpiritJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end


function MagicSpiritJackPotBarView:initLabelSizeParams()
    --存一下cocos工程列面的缩放和尺寸
    self.m_labelParams = {}
    for _jackpotIndex=1,6 do
        local labelNode = self:findChild(string.format("m_lb_coin_%d",_jackpotIndex))
        if labelNode then
            local labelSize = labelNode:getContentSize()
            table.insert(self.m_labelParams, {
                label = labelNode,
                sx = labelNode:getScaleX(),
                sy = labelNode:getScaleY(),
                length = labelSize.width,
            })
        end
    end
end
function MagicSpiritJackPotBarView:flushLabelSize()
    for i,_params in ipairs(self.m_labelParams) do
        self:updateLabelSize(_params, _params.length)
    end
end

-- 更新jackpot 数值信息
--
function MagicSpiritJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    for _jackpotIndex=1,6 do
        local labelNode = self:findChild(string.format("m_lb_coin_%d", _jackpotIndex))
        if labelNode then
            self:updateJackpotLabel(labelNode, _jackpotIndex)
        end
    end
    self:flushLabelSize()
end

function MagicSpiritJackPotBarView:updateJackpotLabel(lbs, index)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    lbs:setString(util_formatCoins(value, 20))
end

function MagicSpiritJackPotBarView:showOneLight(_index ) -- 由高到低  1-6
    for i=1,self.m_maxZunNum do
        local light = self:findChild("Sprite_ligjt_"..i)
        if light then
            if i == _index then
                light:setVisible(true)
            else
                light:setVisible(false)  
            end
        end
    end
end

function MagicSpiritJackPotBarView:beginLight( )
    self.m_JpBarWaitNode:stopAllActions()
    self:playJpIdleAnim( )
end

function MagicSpiritJackPotBarView:playJpIdleAnim( )
    --bonus玩法
    if self.m_isBonus then
        self.m_isPlayIdleAction = false
        return
    end
    --正在执行递归时 其他接口调用不理会
    if(self.m_isPlayIdleAction)then
        return
    end
    self.m_isPlayIdleAction = true

    self:showOneLight(self.m_lightAniIndex )
    self:runCsbAction("idle")
    --如果有对应钻石，也跟着播
    local csb_zuanshi = self[string.format("zuanshiUi_%d", self.m_lightAniIndex)]
    if(csb_zuanshi)then
        csb_zuanshi:runCsbAction("idle")
    end

    performWithDelay(self.m_JpBarWaitNode,function(  )
       
        self.m_lightAniIndex = self.m_lightAniIndex - 1
        if self.m_lightAniIndex <= 0 then
            self.m_lightAniIndex = self.m_maxZunNum
        end

        self.m_isPlayIdleAction = false
        self:playJpIdleAnim( )
    end,150/60)
    
end
--设置idle播放状态来打断递归或者恢复递归
function MagicSpiritJackPotBarView:setIsBonusState(_isBonus)
    self.m_isBonus =  _isBonus
end
function MagicSpiritJackPotBarView:getJackpotIndexBuNum(num)

    local firstNum = 10
    for _num = firstNum,5,-1 do

        if _num == num then
            return 1 + (firstNum - _num)
        end
    end

    return 0
end
return MagicSpiritJackPotBarView
