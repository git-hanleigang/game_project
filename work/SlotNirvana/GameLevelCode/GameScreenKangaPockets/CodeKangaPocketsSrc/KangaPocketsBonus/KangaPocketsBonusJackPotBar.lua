local KangaPocketsBonusJackPotBar = class("KangaPocketsBonusJackPotBar",util_require("Levels.BaseLevelDialog"))

KangaPocketsBonusJackPotBar.Order = {
    SpineDown = 5,
    Label     = 10,
    SpineUp   = 15,
    Progress  = 20,
    Boost     = 30,
    JiaoBiao  = 30,
}
KangaPocketsBonusJackPotBar.JackpotName = {
    [1] = "Node_Grand",
    [2] = "Node_Major",
    [3] = "Node_Minor",
    [4] = "Node_Mini",
}
KangaPocketsBonusJackPotBar.SpineLinePrefix = {
    [1] = "GRAND",
    [2] = "MAJOR",
    [3] = "MINOR",
    [4] = "MINI",
}


function KangaPocketsBonusJackPotBar:initUI(_data)
    self.m_machine = _data.machine
    self.m_bFinish = false

    self:createCsbNode("KangaPockets_BonusJackpot.csb")
    self:initSpine()
    self:initProgress()
    self:initJiaoBiao()
    self:initOrder()
end

function KangaPocketsBonusJackPotBar:onEnter()
    KangaPocketsBonusJackPotBar.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function KangaPocketsBonusJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    local jackpotList = {
        [1] = {label=self:findChild("m_lb_coins_1"), sx=0.7, sy=0.85, width = 266},
        [2] = {label=self:findChild("m_lb_coins_2"), sx=0.7, sy=0.85, width = 266},
        [3] = {label=self:findChild("m_lb_coins_3"), sx=0.7, sy=0.85, width = 266},
        [4] = {label=self:findChild("m_lb_coins_4"), sx=0.7, sy=0.85, width = 266},
    }
    for _jpIndex,_data in ipairs(jackpotList) do
        local labCoins = _data.label
        local value    = self.m_machine:BaseMania_updateJackpotScore(_jpIndex)
        local boostValue = self.m_jiaobiaoCurValueList[_jpIndex]
        local addValue = value * boostValue
        local allValue = math.floor(value + addValue) 
        labCoins:setString(util_formatCoins(allValue, 20, nil, nil, true))
        self:updateLabelSize(_data, _data.width)
    end
end

function KangaPocketsBonusJackPotBar:resetUi()
    self.m_bFinish = false

    self:resetSpine()
    self:resetProgress()
    self:resetJiaoBiao()
end
--[[
    spine背景
]]
function KangaPocketsBonusJackPotBar:initSpine()
    -- { {低层spine循环idle, 高层spine 增幅反馈|Jackpot闪光} }
    self.m_spineList = {}
    for _jpIndex,_jpNodeName in ipairs(self.JackpotName) do
        local parent = self:findChild(_jpNodeName)
        local spineList = {}
        spineList[1] = util_spineCreate("KangaPockets_Bonus_lp_down",true,true)
        spineList[2] = util_spineCreate("KangaPockets_Bonus_lp_up",true,true)
        parent:addChild(spineList[1])
        parent:addChild(spineList[2])

        self.m_spineList[_jpIndex] = spineList
    end
end
function KangaPocketsBonusJackPotBar:resetSpine()
    for _jpIndex,_spineList in ipairs(self.m_spineList) do
        local animName = string.format("%s_idle", self.SpineLinePrefix[_jpIndex])
        util_spinePlay(_spineList[1], animName, true)
        _spineList[2]:setVisible(false)
    end
end
--[[
    进度条
]]
function KangaPocketsBonusJackPotBar:initProgress()
    self.m_progressList = {}
    --{ {收集效果, 期待效果} }
    self.m_pointList = {}
    for _jpIndex=1,4 do
        -- 进度条
        local progressCsb = util_createAnimation("KangaPockets_BonusJackpot_jindu.csb")
        local progressParent = self:findChild(string.format("Node_jindu_%d", _jpIndex))
        progressParent:addChild(progressCsb)
        self.m_progressList[_jpIndex] = progressCsb
        for _progressIndex=1,3 do
            local pointNode = progressCsb:findChild(string.format("sp_jackpotPoint_%d_%d", _progressIndex, _jpIndex))
            pointNode:setVisible(true)
        end
        -- 闪光点
        local pointList = {}
        local pointParent = progressCsb:findChild("Node_Point")
        local pointCsb  = util_createAnimation("KangaPockets_Jackpot_dian.csb")
        local pointCsb2 = util_createAnimation("KangaPockets_Jackpot_dian.csb")
        pointParent:addChild(pointCsb)
        pointParent:addChild(pointCsb2)
        pointCsb:setVisible(false)
        pointCsb2:setVisible(false)
        pointList[1] = pointCsb
        pointList[2] = pointCsb2
        pointCsb2:runCsbAction("actionframe2", true)
        self.m_pointList[_jpIndex] = pointList
    end
end
function KangaPocketsBonusJackPotBar:resetProgress()
    for _jpIndex,_progressCsb in ipairs(self.m_progressList) do
        self:setProgress(_jpIndex, 0, false)
    end
end
function KangaPocketsBonusJackPotBar:setProgress(_jpIndex, _value, _play)
    local progressCsb = self.m_progressList[_jpIndex]
    if _play then
        for _progressIndex=1,3 do
            local visible = _value >= _progressIndex
            local pointNode = progressCsb:findChild(string.format("Node_%d", _progressIndex))
            pointNode:setVisible(visible)
        end
    else
        for _progressIndex=1,3 do
            local visible = _value >= _progressIndex
            local pointNode = progressCsb:findChild(string.format("Node_%d", _progressIndex))
            pointNode:setVisible(visible)
        end
    end
end
-- 收集事件
function KangaPocketsBonusJackPotBar:getProgressFlyEndPos(_jpIndex, _progressValue)
    _progressValue = math.min(3, _progressValue)

    local progressCsb = self.m_progressList[_jpIndex]
    local node = progressCsb:findChild(string.format("Node_%d", _progressValue))
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))

    return worldPos
end
-- 飞行完毕
function KangaPocketsBonusJackPotBar:playProgressFlyEndAnim(_jpIndex, _progressValue)
    local pointCsb = self.m_pointList[_jpIndex][1]
    self:updatePointPos(pointCsb, _jpIndex, _progressValue)
    pointCsb:setVisible(true)
    -- 41/60
    pointCsb:runCsbAction("actionframe1", false, function()
        pointCsb:setVisible(false)
    end)
    performWithDelay(pointCsb,function()
        self:playProgressExpectAnim(_jpIndex, _progressValue)
        self:playProgressFinishAnim(_jpIndex, _progressValue)
    end, 30/60)
end
--期待动画
function KangaPocketsBonusJackPotBar:playProgressExpectAnim(_jpIndex, _progressValue)
    if _progressValue == 2 and not self.m_bFinish then
        local pointCsb = self.m_pointList[_jpIndex][2]
        self:updatePointPos(pointCsb, _jpIndex, 3)
        pointCsb:setVisible(true)
    end
end
function KangaPocketsBonusJackPotBar:stopProgressExpectAnim()
    for _jpIndex,_pointList in ipairs(self.m_pointList) do
        _pointList[2]:setVisible(false)
    end
end
--收集完成动画
function KangaPocketsBonusJackPotBar:playProgressFinishAnim(_jpIndex, _progressValue)
    if _progressValue >= 3 then
        self.m_bFinish = true
        local spineList = self.m_spineList[_jpIndex]
        spineList[2]:setVisible(true)

        local animName = string.format("%s_cf", self.SpineLinePrefix[_jpIndex])
        util_spinePlay(spineList[1], animName, true)
        util_spinePlay(spineList[2], animName, true)
        self:stopProgressExpectAnim()
    end
end
function KangaPocketsBonusJackPotBar:stopProgressFinishAnim(_jpIndex)
    local spineList = self.m_spineList[_jpIndex]
    local animName = string.format("%s_idle", self.SpineLinePrefix[_jpIndex])
    util_spinePlay(spineList[1], animName, true)
    spineList[2]:setVisible(false)
end
--刷新点的坐标
function KangaPocketsBonusJackPotBar:updatePointPos(_pointCsb, _jpIndex, _progressValue)
    local worldPos = self:getProgressFlyEndPos(_jpIndex, _progressValue)
    local nodePos  = _pointCsb:getParent():convertToNodeSpace(worldPos)
    _pointCsb:setPosition(nodePos)
end
--[[
    增幅
]]


--[[
    增幅角标
]]
function KangaPocketsBonusJackPotBar:initJiaoBiao()
    self.m_jiaobiaoCurValueList = {}
    self.m_jiaobiaoValueList = {}
    self.m_jiaobiaoList = {}
    for _jpIndex=1,4 do
        local animCsb = util_createAnimation("KangaPockets_Boostjiaobiao.csb")
        local parent = self:findChild(string.format("Node_jiaobiao_%d", _jpIndex))
        parent:addChild(animCsb)
        util_setCascadeOpacityEnabledRescursion(animCsb, true)
        self.m_jiaobiaoList[_jpIndex] = animCsb
        self.m_jiaobiaoCurValueList[_jpIndex] = 0
        self.m_jiaobiaoValueList[_jpIndex] = 0
    end
end
function KangaPocketsBonusJackPotBar:resetJiaoBiao()
    for _jpIndex,_animCsb in ipairs(self.m_jiaobiaoList) do
        self:setJiaoBiaoValue(_jpIndex, 0)

        _animCsb:setVisible(false)
    end
end
-- 增幅飞行终点
function KangaPocketsBonusJackPotBar:getBoostFlyEndPos(_jpIndex)
    local labName = string.format("m_lb_coins_%d", _jpIndex)
    local labNode = self:findChild(labName)
    local worldPos = labNode:getParent():convertToWorldSpace(cc.p(labNode:getPosition()))

    return worldPos
end
--增幅spine动画
function KangaPocketsBonusJackPotBar:playBoostAnim(_jpIndex)
    local spineList = self.m_spineList[_jpIndex]
    local animName = string.format("%s_sx", self.SpineLinePrefix[_jpIndex])
    util_spinePlay(spineList[2], animName, false)
    util_spineEndCallFunc(spineList[2], animName, function()
        spineList[2]:setVisible(false)
    end)
    spineList[2]:setVisible(true)
end
--设置增幅数值
function KangaPocketsBonusJackPotBar:setJiaoBiaoValue(_jpIndex, _value, _play)
    self.m_jiaobiaoValueList[_jpIndex] = _value

    if _play then
    else
        self.m_jiaobiaoCurValueList[_jpIndex] = _value
    end
end
--更新增幅文本
function KangaPocketsBonusJackPotBar:upDateJiaoBiaoLabel(_jpIndex, _value)
    local animCsb = self.m_jiaobiaoList[_jpIndex]
    local sValue = string.format("+%d%s", _value * 100, "%")
    local labBoost = animCsb:findChild("m_lb_num")
    labBoost:setString(sValue)
    self:updateLabelSize({label=labBoost,sx=0.8, sy=0.8}, 88)
end
--启动增幅文本计时器
function KangaPocketsBonusJackPotBar:startJiaoBiaoUpDate()
    local animTime = self:playJiaoBiaoCsbAddAction()
    self:stopJiaoBiaoUpDate()

    local interval = 0.08
    local increment = (self.m_jiaobiaoValueList[1] - self.m_jiaobiaoCurValueList[1]) / (animTime / interval)
    self.m_updateJiaoBiao =  schedule(self, function()
        local bStop = true
        for _jpIndex,_value in ipairs(self.m_jiaobiaoCurValueList) do
            local targrtValue = self.m_jiaobiaoValueList[_jpIndex]
            if _value < targrtValue then
                bStop = false
                _value = math.min(targrtValue, _value + increment) 
            end
            self:upDateJiaoBiaoLabel(_jpIndex, _value)
            self.m_jiaobiaoCurValueList[_jpIndex] = _value
        end
        if bStop then
            self:stopJiaoBiaoUpDate()
        end
    end, interval)

    return animTime
end
function KangaPocketsBonusJackPotBar:playJiaoBiaoCsbAddAction()
    local animName = "start"
    local animTime = 45/60
    local bVisible = self.m_jiaobiaoList[1]:isVisible()
    if bVisible then
        animName = "shouji"
        animTime = 60/60
    else
        for _jpIndex,_animCsb in ipairs(self.m_jiaobiaoList) do
            _animCsb:setVisible(true)
        end
    end
    for _jpIndex,_animCsb in ipairs(self.m_jiaobiaoList) do
        _animCsb:runCsbAction(animName, false)
    end

    return animTime
end
function KangaPocketsBonusJackPotBar:stopJiaoBiaoUpDate()
    if nil ~= self.m_updateJiaoBiao then
        self:stopAction(self.m_updateJiaoBiao)
        self.m_updateJiaoBiao = nil
    end
end
--[[
    层级
]]
function KangaPocketsBonusJackPotBar:initOrder()
    for _jpIndex=1,4 do
        --下spine
        local spineDown = self.m_spineList[_jpIndex][1]
        spineDown:setLocalZOrder(self.Order.SpineDown)
        --文本
        local label = self:findChild(string.format("m_lb_coins_%d", _jpIndex))
        label:setLocalZOrder(self.Order.Label)
        --上sping
        local spineUp = self.m_spineList[_jpIndex][2]
        spineUp:setLocalZOrder(self.Order.SpineUp)
        --进度
        local progress = self:findChild(string.format("Node_jindu_%d", _jpIndex))
        progress:setLocalZOrder(self.Order.Progress)
        --增幅
        local boost = self:findChild(string.format("Node_boost_%d", _jpIndex))
        boost:setLocalZOrder(self.Order.Boost)
        --增幅角标
        local jiaobiao = self:findChild(string.format("Node_jiaobiao_%d", _jpIndex))
        jiaobiao:setLocalZOrder(self.Order.JiaoBiao)
    end
end
return KangaPocketsBonusJackPotBar