local MagicSpiritRsJackPotBarView = class("MagicSpiritRsJackPotBarView", util_require("base.BaseView"))

MagicSpiritRsJackPotBarView.m_maxZunNum = 6

function MagicSpiritRsJackPotBarView:initUI()
    self:createCsbNode("MagicSpirit_jackpot_rs.csb")

    for i = 2,self.m_maxZunNum do
        self["zuanshiUi_"..i] = util_createAnimation("MagicSpirit_jackpot_zuanshi.csb")
        self:findChild("zuanshi_"..i):addChild(self["zuanshiUi_"..i]) 
    end

    self:initLabelSizeParams()
end

function MagicSpiritRsJackPotBarView:initLabelSizeParams()
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
function MagicSpiritRsJackPotBarView:flushLabelSize()
    for i,_params in ipairs(self.m_labelParams) do
        self:updateLabelSize(_params, _params.length)
    end
end

function MagicSpiritRsJackPotBarView:onExit()
end

function MagicSpiritRsJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MagicSpiritRsJackPotBarView:onEnter()
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
function MagicSpiritRsJackPotBarView:updateJackpotInfo()
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

function MagicSpiritRsJackPotBarView:updateJackpotLabel(lbs, index)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    lbs:setString(util_formatCoins(value, 20))
end

function MagicSpiritRsJackPotBarView:getJackpotIndexBuNum(num)
    local firstNum = 10
    for _num = firstNum,5,-1 do

        if _num == num then
            return 1 + (firstNum - _num)
        end
    end

    return 0
end

function MagicSpiritRsJackPotBarView:updateLock(level)

end

function MagicSpiritRsJackPotBarView:showjackPotAction()
end

function MagicSpiritRsJackPotBarView:clearAnim()
   
end

return MagicSpiritRsJackPotBarView
