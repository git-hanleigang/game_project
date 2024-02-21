
local DemonessFairBottomNode = class("DemonessFairBottomNode", util_require("views.gameviews.GameBottomNode"))

function DemonessFairBottomNode:initUI(...)
    DemonessFairBottomNode.super.initUI(self, ...)
end

-- 修改已创建的收集反馈效果
function DemonessFairBottomNode:changeCoinWinEffectUI(_levelName, _spineName)
    if nil ~= self.coinBottomEffectNode and nil ~= _spineName then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
        self.coinBottomEffectNode = util_spineCreate(_spineName,true,true)
        self.coinWinNode:addChild(self.coinBottomEffectNode, -1)
        self.coinBottomEffectNode:setVisible(false)
        self.coinBottomEffectNode:setPositionY(-10)
    end
end

function DemonessFairBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        util_spinePlay(coinBottomEffectNode, "actionframe", false)
        util_spineEndCallFunc(coinBottomEffectNode, "actionframe", function()
            if type(callBack) == "function" then
                callBack()
            end
        end)
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

function DemonessFairBottomNode:setWinLabState(_state)
    self.m_bigWinLabCsb:setVisible(_state)
end

function DemonessFairBottomNode:getCoinsShowTimes(winCoin)
    local showTime = DemonessFairBottomNode.super.getCoinsShowTimes(winCoin)
    if self.m_machine.collectBonus then
        showTime = 0.5
    end
    return showTime
end

function DemonessFairBottomNode:playBigWinLabAnim(_params)
    if not self.m_bigWinLabCsb then
        return 
    end
    --[[
        _params = {
            beginCoins = 0,
            overCoins  = 100,
            jumpTime   = 3,
            actType    = 1,             --(二选一)通用的几种放大缩小表现
            animName   = "actionframe", --(二选一)工程内的时间线

            fnActOver  = function,
            fnJumpOver = function,
        }
    ]]
    if _params.isPlayCoins then
        local overCoins = _params.overCoins or 100
        _params.fnActOver = _params.fnActOver or function() end
        self:stopUpDateBigWinLab()
        self:setBigWinLabCoins(overCoins)
        --文本放大缩小 分为通用动作或时间线
        self:playBigWinLabActionByType(_params)
        self:playBigWinLabTimeLineByName(_params)
    else
        DemonessFairBottomNode.super.playBigWinLabAnim(self, _params)
    end
end

return DemonessFairBottomNode
