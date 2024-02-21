local NutCarnivalPickGameJackPotBar = class("NutCarnivalPickGameJackPotBar",util_require("Levels.BaseLevelDialog"))

function NutCarnivalPickGameJackPotBar:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("NutCarnival_duofuduocai_jackpot.csb")
    self:initJackpotLabInfo()
    self:initCollectUi()
    util_setCascadeOpacityEnabledRescursion(self,true)


    -- self:runCsbAction("saoguang", true)
end

function NutCarnivalPickGameJackPotBar:onEnter()
    NutCarnivalPickGameJackPotBar.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end
--[[
    jackpot文本刷新
]]
function NutCarnivalPickGameJackPotBar:initJackpotLabInfo()
    self.m_jackpotCsbInfo = {
        -- 工程名称, 挂点名称, 工程对象, jackpot索引, 宽度, x缩放, y缩放
        {"NutCarnival_jackpot_grand.csb", "Node_grand", nil, 1, 100, 1, 1},
        {"NutCarnival_jackpot_major.csb", "Node_major", nil, 2, 100, 1, 1},
        {"NutCarnival_jackpot_maxi.csb",  "Node_maxi",  nil, 3, 100, 1, 1},
        {"NutCarnival_jackpot_minor.csb", "Node_minor", nil, 4, 100, 1, 1},
        {"NutCarnival_jackpot_mini.csb",  "Node_mini", nil, 5, 100, 1, 1},
    }
    for i,_labInfo in ipairs(self.m_jackpotCsbInfo) do
        local parent = self:findChild(_labInfo[2])
        local labCsb = util_createAnimation(_labInfo[1])
        parent:addChild(labCsb)
        _labInfo[3] = labCsb
        local label   = labCsb:findChild("m_lb_coins")
        local labSize = label:getContentSize()
        _labInfo[5] = labSize.width
        _labInfo[6] = label:getScaleX()
        _labInfo[7] = label:getScaleY()
    end
end
-- 更新jackpot 数值信息
function NutCarnivalPickGameJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    for i,_labInfo in ipairs(self.m_jackpotCsbInfo) do
        local labCsb = _labInfo[3]
        local label  = labCsb:findChild("m_lb_coins")
        local value  = self.m_machine:BaseMania_updateJackpotScore(_labInfo[4])
        label:setString(util_formatCoins(value, 20, nil, nil, true))
        local info = {label=label, sx=_labInfo[6], sy=_labInfo[7]}
        self:updateLabelSize(info, _labInfo[5])
    end
end
function NutCarnivalPickGameJackPotBar:playJackpotBarIdleAnim()
    for i,_labInfo in ipairs(self.m_jackpotCsbInfo) do
        local jackpotBarCsb = _labInfo[3]
        jackpotBarCsb:runCsbAction("idle", true)
    end
end
function NutCarnivalPickGameJackPotBar:playJackpotBarExpectAnim(_jpIndex)
    for i,_labInfo in ipairs(self.m_jackpotCsbInfo) do
        if _jpIndex == _labInfo[4] then
            local jackpotBarCsb = _labInfo[3]
            jackpotBarCsb:runCsbAction("idle2", true)
        end
    end
end
function NutCarnivalPickGameJackPotBar:playJackpotBarActionframeAnim(_jpIndex)
    for i,_labInfo in ipairs(self.m_jackpotCsbInfo) do
        if _jpIndex == _labInfo[4] then
            local jackpotBarCsb = _labInfo[3]
            jackpotBarCsb:runCsbAction("actionframe", true)
            break
        end
    end
end

--[[
    锁定特效
]]
function NutCarnivalPickGameJackPotBar:setLockState(_bLock)
    local grandBar = self.m_jackpotCsbInfo[1][3]
    local lockNode = grandBar:findChild("Node_suo")
    lockNode:setVisible(_bLock)
end

function NutCarnivalPickGameJackPotBar:resetUi()
    self.m_bFinish = false
    self:setLockState(self.m_machine:getCurLockState())
    self:resetCollectUi()
    self:playJackpotBarIdleAnim()
end
--[[
    收集相关
]]
function NutCarnivalPickGameJackPotBar:initCollectUi()
    self.m_collectBarList = {}
    for i,_labInfo in ipairs(self.m_jackpotCsbInfo) do
        local labCsb  = _labInfo[3]
        local jpIndex = _labInfo[4]
        self.m_collectBarList[jpIndex] = {}
        for _progressIndex=1,3 do
            local parent   = labCsb:findChild(string.format("Node_point%d", _progressIndex))
            local pointCsb = util_createAnimation("NutCarnival_pick_jackpot_point.csb")
            parent:addChild(pointCsb)
            self.m_collectBarList[jpIndex][_progressIndex] = pointCsb
            --打开一种类型的展示
            pointCsb:findChild(string.format("sp_jackpot_%d", jpIndex)):setVisible(true)
        end
    end
end
function NutCarnivalPickGameJackPotBar:resetCollectUi()
    for _index_1,_pointList in ipairs(self.m_collectBarList) do
        for _index_2,_pointCsb in ipairs(_pointList) do
            _pointCsb:runCsbAction("normal")
        end
    end
end

function NutCarnivalPickGameJackPotBar:getProgressFlyEndPos(_jpIndex, _progressValue)
    local pointList = self.m_collectBarList[_jpIndex]
    local pointCsb  = pointList[_progressValue]
    local worldPos = pointCsb:getParent():convertToWorldSpace(cc.p(pointCsb:getPosition()))
    return worldPos
end
-- 飞行完毕
function NutCarnivalPickGameJackPotBar:playProgressFlyEndAnim(_jpIndex, _progressValue)
    local pointList = self.m_collectBarList[_jpIndex]
    local pointCsb  = pointList[_progressValue]

    pointCsb:runCsbAction("chuxian", false)
    performWithDelay(pointCsb,function()
        self:playProgressExpectAnim(_jpIndex, _progressValue)
        -- self:playProgressFinishAnim(_jpIndex, _progressValue)
    end, 21/60)
end
--期待动画
function NutCarnivalPickGameJackPotBar:playProgressExpectAnim(_jpIndex, _progressValue)
    if _progressValue == 2 and not self.m_bFinish then
        self:playJackpotBarExpectAnim(_jpIndex)
    elseif _progressValue >= 3 then
        self:playJackpotBarIdleAnim()
    end
end
--收集完成动画
function NutCarnivalPickGameJackPotBar:playProgressFinishAnim(_jpIndex, _progressValue)
    if _progressValue >= 3 then
        self.m_bFinish = true
        self:playJackpotBarActionframeAnim(_jpIndex)
    end
end

return NutCarnivalPickGameJackPotBar