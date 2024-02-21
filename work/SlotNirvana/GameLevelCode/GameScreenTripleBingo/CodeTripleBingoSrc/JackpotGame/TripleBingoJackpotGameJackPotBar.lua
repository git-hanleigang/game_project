--[[
    多福多彩-奖池栏
        处理每个奖池栏的idle,期待,中奖
        处理每个奖池栏的收集进度
]]
local TripleBingoJackpotGameJackPotBar = class("TripleBingoJackpotGameJackPotBar", util_require("base.BaseView"))

function TripleBingoJackpotGameJackPotBar:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("TripleBingo_jackpot.csb")
    self:initJackpotLabInfo()
    self:initCollectUi()
    util_setCascadeOpacityEnabledRescursion(self,true)
end
function TripleBingoJackpotGameJackPotBar:resetUi()
    self.m_bFinish = false
    self:resetCollectUi()
end

function TripleBingoJackpotGameJackPotBar:onEnter()
    TripleBingoJackpotGameJackPotBar.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

--[[
    jackpot文本参数
]]
function TripleBingoJackpotGameJackPotBar:initJackpotLabInfo()
    self.m_jackpotLabelInfo = {
        -- 文本节点, jackpot索引, 宽度, x缩放, y缩放
        {nil, 1, 100, 1, 1},
        {nil, 2, 100, 1, 1},
        {nil, 3, 100, 1, 1},
        {nil, 4, 100, 1, 1},
    }
    for i,_labInfo in ipairs(self.m_jackpotLabelInfo) do
        local labelName = ""
        if 1 == _labInfo[2] then
            labelName = "m_lb_coins"
        else
            labelName = string.format("m_lb_coins_%d", _labInfo[2]-1)
        end
        local label = self:findChild(labelName)
        local labSize = label:getContentSize()
        _labInfo[1]   = label
        _labInfo[3]   = labSize.width
        _labInfo[4]   = label:getScaleX()
        _labInfo[5]   = label:getScaleY()
    end
end
-- 更新jackpot 数值信息
function TripleBingoJackpotGameJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    for i,_labInfo in ipairs(self.m_jackpotLabelInfo) do
        local label  = _labInfo[1]
        local value  = self.m_machine:getTripleBingoJackpotScore(_labInfo[2])
        label:setString(util_formatCoins(value, 20, nil, nil, true))
        local info = {label=label, sx=_labInfo[4], sy=_labInfo[5]}
        self:updateLabelSize(info, _labInfo[3])
    end
end

--中奖
function TripleBingoJackpotGameJackPotBar:playJackpotBarActionframeAnim(_jpIndex)
    for i,_labInfo in ipairs(self.m_jackpotCsbInfo) do
        if _jpIndex == _labInfo[4] then
            local jackpotBarCsb = _labInfo[3]
            -- jackpotBarCsb:runCsbAction("actionframe", true)
            break
        end
    end
end

--[[
    收集相关
]]
function TripleBingoJackpotGameJackPotBar:initCollectUi()
    self.m_collectBarList = {}
    self.m_pointList      = {}
    for _jpIndex=1,4 do
        local parent = self:findChild(string.format("Node_dfdc_%d", _jpIndex))
        local collectBar  = util_createAnimation("TripleBingo_jackpot_dfdc.csb")
        parent:addChild(collectBar)
        collectBar:findChild(string.format("bg_%d", _jpIndex)):setVisible(true)
        self.m_collectBarList[_jpIndex] = collectBar
        self.m_pointList[_jpIndex] = {}
        for _progressIndex=1,3 do
            local pointName   = string.format("point_%d", _progressIndex)
            local pointParent = collectBar:findChild(pointName)
            local pointCsb    = util_createAnimation("TripleBingo_jackpot_dfdc2.csb")
            pointParent:addChild(pointCsb)
            pointCsb:findChild(string.format("point_%d", _jpIndex)):setVisible(true)
            self.m_pointList[_jpIndex][_progressIndex] = pointCsb
        end
    end
end
function TripleBingoJackpotGameJackPotBar:resetCollectUi()
    for _jpIndex,_pointList in ipairs(self.m_pointList) do
        for _progressIndex,_pointCsb in ipairs(_pointList) do
            _pointCsb:setVisible(false)
        end
    end
end

--奖励飞行终点
function TripleBingoJackpotGameJackPotBar:getCollectFlyWorldPos(_jpIndex, _progressIndex)
    local pointList = self.m_pointList[_jpIndex]
    local pointCsb  = pointList[_progressIndex]
    local worldPos = pointCsb:getParent():convertToWorldSpace(cc.p(pointCsb:getPosition()))
    return worldPos
end
-- 飞行完毕
function TripleBingoJackpotGameJackPotBar:playProgressFlyEndAnim(_jpIndex, _progressIndex)
    if _progressIndex >= 3 then
        self.m_bFinish = true
    end

    local pointList = self.m_pointList[_jpIndex]
    local pointCsb  = pointList[_progressIndex]
    pointCsb:setVisible(true)
    pointCsb:runCsbAction("start", false)
    performWithDelay(pointCsb,function()
        self:playProgressExpectAnim(_jpIndex, _progressIndex)
    end, 21/60)
end
--期待动画 / 收集完成
function TripleBingoJackpotGameJackPotBar:playProgressExpectAnim(_jpIndex, _progressIndex)
    if _progressIndex == 2 and not self.m_bFinish then
        local collectBar  = self.m_collectBarList[_jpIndex]
        collectBar:runCsbAction("idle2", true)
    elseif _progressIndex >= 3 then
        for i,_collectBar in ipairs(self.m_collectBarList) do
            if i ~= _jpIndex then
                _collectBar:runCsbAction("darkstart", false)
            else
                _collectBar:runCsbAction("actionframe", true)
            end
        end
    end
end

return TripleBingoJackpotGameJackPotBar