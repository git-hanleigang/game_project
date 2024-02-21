--[[
    关卡顶部法阵
    处理圆形轮盘的滚动
]]
local WinningWizardSpecialReelView = class("WinningWizardSpecialReelView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WinningWizardPublicConfig"

--挂点层级
WinningWizardSpecialReelView.NodeOrder = {
    WildChangeList = 10,
    CollectAnim    = 50,
    Fly = 100,
}
--插槽的参数
WinningWizardSpecialReelView.SLOTDATA = {
    count        = 15,      --插槽数量
    speedScale   = 0.5,     --和base棋盘的速度关系
    symbolHeight = 82,      --插槽内图标的高度

    --哪些列的reSpinNode对应base下卷轴的滚动节奏
    baseColToReSpinCol = {
        -- [base列] = {reSpinNode列1， reSpinNode列2}
        [1] = {9, 10},
        [2] = {8, 11, 12, 14},
        [3] = {1, 7, 13},
        [4] = {2, 3, 6, 15},
        [5] = {4, 5},
    },
}
--中心文本参数
WinningWizardSpecialReelView.CenterLabData = {
    maxFreeType = 4, --free的最大类型
    -- 服务器buff的key
    freeTypeKey_freeTimes   = "free",  --free次数
    freeTypeKey_winMultiple = "multi", --结算乘倍
    freeTypeKey_wildChange  = "wild",  --wild变化
    --可能变为wild的图标种类
    wildChange_typeList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
    }
}

--[[
    _data = {
        machine = machine,

    }
]]
function WinningWizardSpecialReelView:initUI(_data)
    self.m_machine     = _data.machine

    self.m_buffList = {}

    self:createCsbNode("WinningWizard_fazhen.csb")
    self:initCenterLabCsb()
    self:initWildChangeList()
    self:initSlotList()
    self:initSlotRing()
    self:initSlotRewardCollectAnim()
    self:initWinningWizardRespinView()

    self:setSlotRingOrder(true)
end

function WinningWizardSpecialReelView:onEnter()
    WinningWizardSpecialReelView.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end
function WinningWizardSpecialReelView:addObservers()
    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:reSpinReelDown()
        end,
        ViewEventType.NOTIFY_RESPIN_RUN_STOP
    )
    gLobalNoticManager:addObserver(self,function(params)
        self:updateCenterLabFreeTimesNoParams()
    end, ViewEventType.SHOW_FREE_SPIN_NUM)

    gLobalNoticManager:addObserver(self, function()
        self:reSpinViewQuickStop()
    end, ViewEventType.QUICKLY_SPIN_EFFECT)

    -- reSpinNode buling
    gLobalNoticManager:addObserver(self,function(self,params)
        self:playBulingAnim(params[1])
    end,"WinningWizardMachine_reSpinNodeBuling")
end
--[[
    法阵本身的动画播放
]]
function WinningWizardSpecialReelView:playAnimScatterActionframe()
    self:runCsbAction("actionframe", false,function()
        self:playBaseToFreeIdleAnim()
    end)
end
function WinningWizardSpecialReelView:playBaseIdleAnim()
    self:runCsbAction("idle1", true)
end
function WinningWizardSpecialReelView:playBaseToFreeIdleAnim()
    self:runCsbAction("idle2", true)
end
function WinningWizardSpecialReelView:playFreeIdleAnim()
    self:runCsbAction("idle3", true)
end
function WinningWizardSpecialReelView:playBaseToFreeAnim()
    self:runCsbAction("switch1", false, function()
        self:playFreeIdleAnim()
    end)
end
function WinningWizardSpecialReelView:playFreeToBaseAnim()
    self:runCsbAction("switch2", false, function()
        self:playBaseIdleAnim()
    end)
end
function WinningWizardSpecialReelView:playBulingAnim(_reSpinCol)
    local newPosData    = self.m_machine:getCurBetBonusPosData()
    local bulingPosData = self:getNewBulingPosData(newPosData, self.m_posData)
    local lastBaseCol = 1
    for _index,_pos in ipairs(bulingPosData) do
        local baseCol = self:getBaseColByReSpinCol(_pos + 1)
        lastBaseCol = math.max(lastBaseCol, baseCol)
    end
    
    local baseCol = self:getBaseColByReSpinCol(_reSpinCol)
    if baseCol == lastBaseCol then
        self:runCsbAction("buling", false, function()
            self:playBaseIdleAnim()
        end)
        --粒子
        local particleNode = self:findChild("Particle_2")
        particleNode:stopAllActions()
        particleNode:runAction(cc.Sequence:create(
            cc.DelayTime:create(15/60),
            cc.CallFunc:create(function()
                particleNode:setPositionType(0)
                particleNode:setVisible(true)
                particleNode:setDuration(1)
                particleNode:resetSystem()
            end),
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(function()
                particleNode:stopSystem()
                util_setCascadeOpacityEnabledRescursion(particleNode, true)
            end),
            cc.FadeOut:create(0.5),
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(function()
                particleNode:setVisible(false)
            end)
        ))
        --重置期待动画
        self:reSetSlotAnim()
    end
end
--[[
    中心说明文本
]]
function WinningWizardSpecialReelView:initCenterLabCsb()
    self.m_baseCollectCount = 0
    self.m_posData = {}

    self.m_centerLabCsb = util_createAnimation("WinningWizard_fazhen_zhonjian.csb")
    self:findChild("Node_zhonjian"):addChild(self.m_centerLabCsb)

    --魔法石
    self.m_centerBonusSymbol = util_createAnimation("WinningWizard_fazhen_shitou.csb")
    self.m_centerLabCsb:findChild("Node_mofashi"):addChild(self.m_centerBonusSymbol)
    self.m_centerBonusSymbol:runCsbAction("idleframe2", true)

    util_setCascadeOpacityEnabledRescursion(self.m_centerLabCsb, true)

    self:resetCenterLabStatus()
end
function WinningWizardSpecialReelView:setCenterLabStatus(_freeType, _fnMoveEnd)
    local nodeName = string.format("Node_free%d", _freeType)
    self.m_centerLabCsb:findChild(nodeName):setVisible(true)

    local animName = string.format("actionframe%d", _freeType)
    self.m_centerLabCsb:runCsbAction(animName)
    self.m_machine:levelPerformWithDelay(self,21/30,function()
        self:resetCenterLabStatus()
        self.m_centerLabCsb:findChild(nodeName):setVisible(true)
        if _fnMoveEnd then
            _fnMoveEnd()
        end
    end)

    return 30/60
end

function WinningWizardSpecialReelView:resetCenterLabStatus()
    --[[
        1:全都有 
        2:freeTimes 和 wildChange 
        3:freeTimes 和 winMultiple
        4:freeTimes
    ]] 
    self.m_centerLabCsb:findChild("Node_base"):setVisible(false)
    self.m_centerLabCsb:findChild("Node_free1"):setVisible(false)
    self.m_centerLabCsb:findChild("Node_free2"):setVisible(false)
    self.m_centerLabCsb:findChild("Node_free3"):setVisible(false)
    self.m_centerLabCsb:findChild("Node_free4"):setVisible(false)
end
function WinningWizardSpecialReelView:getFreeTypeByBuffList(_buffList)
    --[[
        1:全都有 
        2:freeTimes 和 wildChange 
        3:freeTimes 和 winMultiple
        4:freeTimes
    ]] 
    local freeType = 4

    local bWildChange = false
    local bWinMultiple = false
    for i,_buffData in ipairs(_buffList) do
        if not bWildChange then
            bWildChange = self.CenterLabData.freeTypeKey_wildChange == _buffData[2]
        end
        if not bWinMultiple then
            bWinMultiple = self.CenterLabData.freeTypeKey_winMultiple == _buffData[2]
        end
    end

    if bWildChange and bWinMultiple then
        freeType = 1
    elseif bWildChange then
        freeType = 2
    elseif bWinMultiple then
        freeType = 3
    end

    return freeType
end
--base收集数量
function WinningWizardSpecialReelView:setCenterLabBaseStatus()
    self:resetCenterLabStatus()
    self.m_centerLabCsb:findChild("Node_base"):setVisible(true)
    self.m_centerLabCsb:runCsbAction("idleframe")
end
function WinningWizardSpecialReelView:updateCenterLabBaseCollectCount(_posData, _playAnim)
    local newCount = #_posData
    local bChange  = self.m_baseCollectCount ~= newCount
    self.m_baseCollectCount = newCount 
    self.m_posData = clone(_posData)
    local labCount = self.m_centerLabCsb:findChild("m_lb_num")
    if bChange and _playAnim then
        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_baseCollectUpDate)
        
        self.m_centerLabCsb:runCsbAction("actionframe", false)
        self.m_machine:levelPerformWithDelay(self, 9/60, function()
            labCount:setString(string.format("%d", newCount))
            self.m_machine:updateLabelSize({label=labCount, sx=1, sy=1}, 123)
        end)
    else
        labCount:setString(string.format("%d", newCount))
        self.m_machine:updateLabelSize({label=labCount, sx=1, sy=1}, 123)
    end
end
--[[
    idleframe1 -> over-> idle2 or 3
    spin后 < 14   新落地的 播idle2
    spin后 == 14  全体    播idle3
    spin后 == 15  全体    播idle2
]]

function WinningWizardSpecialReelView:playBonusSymbolIdleframeLoop(_posData)
    local idleName = self:getSlotIdleNameByCount(#_posData) 
    local iRow = 1
    local playData = _posData
    if #_posData < 14 then
        playData = self:getNewBulingPosData(_posData, self.m_posData)
    end
    --先把新落地的 over播了
    local bulingPosData = self:getNewBulingPosData(_posData, self.m_posData)
    for i,_reelIndex in ipairs(bulingPosData) do
        local iCol = _reelIndex + 1
        local lastNode = self.m_respinView:getWinningWizardSymbolNode(iRow, iCol)
        lastNode:runAnim("over", false)
    end
    local delayTime = #bulingPosData > 0 and 21/60 or 0
    -- 触发列表播idle
    self.m_machine:levelPerformWithDelay(self, delayTime, function()
        for i,_reelIndex in ipairs(playData) do
            local iCol = _reelIndex + 1
            local lastNode = self.m_respinView:getWinningWizardSymbolNode(iRow, iCol)
            lastNode:runAnim(idleName, true)
        end
    end)
    -- 期待
    self:playSlotExpectAnim(_posData)
end

function WinningWizardSpecialReelView:getNewBulingPosData(_newData, _curData)
    local bulingPosData = {}
    for _newIndex,_newPos in ipairs(_newData) do
        local bExist = false
        for _curIndex,_curPos in ipairs(_curData) do
            if _newPos == _curPos then
                bExist = true
                break
            end
        end
        if not bExist then
            table.insert(bulingPosData, _newPos)
        end
    end
    return bulingPosData
end
--free次数
function WinningWizardSpecialReelView:updateCenterLabFreeTimes(_count1, _count2)
    local scaleList = {
        [1] = 0.35,
        [2] = 0.35,
        [3] = 0.4,
        [4] = 0.5,
    }
    for _typeIndex=1,self.CenterLabData.maxFreeType do
        local lab1 = self.m_centerLabCsb:findChild(string.format("m_lb_num_%d_1", _typeIndex))
        local lab2 = self.m_centerLabCsb:findChild(string.format("m_lb_num_%d_2", _typeIndex))
        lab1:setString(string.format("%d", _count1))
        lab2:setString(string.format("%d", _count2))
        self.m_machine:updateLabelSize({label=lab1, sx=scaleList[_typeIndex], sy=scaleList[_typeIndex]}, 215)
        self.m_machine:updateLabelSize({label=lab2, sx=scaleList[_typeIndex], sy=scaleList[_typeIndex]}, 215)
    end
end
function WinningWizardSpecialReelView:updateCenterLabFreeTimesNoParams()
    local leftFsCount  = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateCenterLabFreeTimes(leftFsCount, totalFsCount)
end
function WinningWizardSpecialReelView:playCenterLabFreeTimesStartAnim()
    --free次数刷新
    local fsExtraData = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    local totalCount  =  fsExtraData.freeInitTimes or 0
    self:updateCenterLabFreeTimes(0, totalCount)

    local animTime = self:setCenterLabStatus(4)
end
--free结算乘倍
function WinningWizardSpecialReelView:updateCenterLabWinMultipleNumber(_multiple)
    local labMultiple_1 = self.m_centerLabCsb:findChild("m_lb_num_1_3")
    local labMultiple_3 = self.m_centerLabCsb:findChild("m_lb_num_3_3")
    labMultiple_1:setString(string.format("X%d", _multiple))
    labMultiple_3:setString(string.format("X%d", _multiple))
    self.m_machine:updateLabelSize({label=labMultiple_1, sx=0.35, sy=0.35}, 219)
    self.m_machine:updateLabelSize({label=labMultiple_3, sx=0.35, sy=0.35}, 219)
end
--free模式内变换wild
function WinningWizardSpecialReelView:initWildChangeList()
    self.m_wildChangeList = util_createView("CodeWinningWizardSrc.WinningWizardFree.WinningWizardWildChangeList", {
        tubiaoPath = "WinningWizard_free_tubiao.csb",
        tubiaoWidth = 35,
    })
    self.m_centerLabCsb:findChild("Node_turn_1"):addChild(self.m_wildChangeList)
end
function WinningWizardSpecialReelView:updateWildChangeListPosY(_freeType)
    local newParentName = string.format("Node_turn_%d", _freeType)
    local newParent     = self.m_centerLabCsb:findChild(newParentName)
    if nil == newParent then
        return
    end

    util_changeNodeParent(newParent, self.m_wildChangeList)
end
function WinningWizardSpecialReelView:resetWildChangeList()
    self.m_wildChangeList:updateWildChangeList({}, false)
end
--[[
    15个插槽
]]
function WinningWizardSpecialReelView:initSlotList()
    self.m_slotList = {}
    for _slotIndex=1,self.SLOTDATA.count do
        local csb    = util_createAnimation("WinningWizard_fazhen_cao.csb")
        local parentName = string.format("Node_cao%d", _slotIndex)
        local parent = self:findChild(parentName) 
        parent:addChild(csb)
        self.m_slotList[_slotIndex] = csb
    end
    self:reSetSlotReward()
end
--重置插槽的奖励展示
function WinningWizardSpecialReelView:reSetSlotReward()
    for i,_slot in ipairs(self.m_slotList) do
        _slot:findChild("free_freeTimes"):setVisible(false)
        _slot:findChild("free_winMultiple"):setVisible(false)
        _slot:findChild("free_wildChange"):setVisible(false)
        for _symbolType=0,6 do
            local nodeName = string.format("symbol_%d", _symbolType)
            _slot:findChild(nodeName):setVisible(false)
        end
    end
    self:reSetSlotAnim()
end
--最后一个播期待
function WinningWizardSpecialReelView:playSlotExpectAnim(_posData)
    if #_posData ~= 14 then
        return
    end
    for iCol,_slotCsb in ipairs(self.m_slotList) do
        local bool = false
        for i,_reelIndex in ipairs(_posData) do
           if iCol == _reelIndex+1 then
                bool = true
                break
           end
        end
        if not bool then
            _slotCsb:runCsbAction("idle3", true)
            break
        end
    end
end
--
function WinningWizardSpecialReelView:reSetSlotAnim()
    for iCol,_slotCsb in ipairs(self.m_slotList) do
        _slotCsb:runCsbAction("idle1")
    end
end
-- sc播完触发, 如果bonus集满了, 那么也播触发
-- 没集满只播抖动
function WinningWizardSpecialReelView:playBonusActionFrame(_fun)
    local fsExtraData = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    local buffList    = fsExtraData.buff or {}
    local bAction     = #buffList >= self.SLOTDATA.count
    local delayTime   = 0
    local iRow        = 1
    for i,_buffData in ipairs(buffList) do
        local iCol     = _buffData[1] + 1
        local lastNode = self.m_respinView:getWinningWizardSymbolNode(iRow, iCol)
        if bAction then
            lastNode:runAnim("actionframe", false, function()
                lastNode:runAnim("shark", true)
            end)
            delayTime = lastNode:getAniamDurationByName("actionframe") + lastNode:getAniamDurationByName("shark")
        else
            lastNode:runAnim("shark", true)
            delayTime = lastNode:getAniamDurationByName("actionframe")
        end
    end
    if bAction then
        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_bonusSymbol_actionframe)
    end

    self.m_machine:levelPerformWithDelay(self, delayTime, _fun)
end
-- 获取插槽内的循环时间线名称
function WinningWizardSpecialReelView:getSlotIdleNameByCount(_count)
    local idleName = (_count + 1 == self.SLOTDATA.count) and "idleframe3" or "idleframe2"
    return idleName
end
function WinningWizardSpecialReelView:openSlotReward(_fun)
    local fsExtraData = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    local buffList    = fsExtraData.buff or {}
    self.m_buffList   = clone(buffList)
    self:reSetSlotReward()
    self:setSlotRingOrder(false)
    --free次数增加
    self:openSlotReward_freeTimes(self.m_buffList, function()
        --free时那些图标会变wild
        self:openSlotReward_wildChange(self.m_buffList, function()
            --free结算乘倍
            self:openSlotReward_winMultiple(self.m_buffList, function()
                self.m_machine:levelPerformWithDelay(self, 0.5, _fun)
            end)
        end)
    end)
end
function WinningWizardSpecialReelView:openSlotReward_freeTimes(_buffList, _fun)
    local buffList = self:getBuffByKey(_buffList, self.CenterLabData.freeTypeKey_freeTimes)
    local bTrigger = #buffList > 0
    if bTrigger then
        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_bonusSymbol_showBuff)

        local iRow     = 1
        local freeType = 4
        local disappearTime = 0
        
        for i,_buffData in ipairs(buffList) do
            local iCol  = _buffData[1] + 1
            local slotCsb   = self.m_slotList[iCol]
            --刷新次数
            slotCsb:findChild("free_freeTimes"):setVisible(true)
            local labTimes = slotCsb:findChild("m_lb_freeTimes")
            labTimes:setString(string.format("+%d", _buffData[3]))
            self.m_machine:updateLabelSize({label=labTimes, sx=1, sy=1}, 51)
            --bonus消失 -> buff出现
            disappearTime = self:playBonusSymbolDisappear(iCol, iRow)
        end
        self.m_machine:levelPerformWithDelay(self, disappearTime, function()
            gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_buffCollect_freeTimes)
            local flyTime = 0
            for i,_buffData in ipairs(buffList) do
                local iCol  = _buffData[1] + 1
                --飞行
                flyTime = self:playSlotRewardFly({
                    iCol = iCol,
                    freeType = freeType,
                })
            end
            self.m_machine:levelPerformWithDelay(self, flyTime, function()
                gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_buffCollectFeedback_freeTimes)
                --收集反馈
                self:playSlotRewardCollectAnim(freeType, function()
                    self:updateCenterLabFreeTimesNoParams()
                end, _fun)
            end)
        end)
    else
        _fun()
    end
end
function WinningWizardSpecialReelView:openSlotReward_wildChange(_buffList, _fun)
    local buffList = self:getBuffByKey(_buffList, self.CenterLabData.freeTypeKey_wildChange)
    local bTrigger = #buffList > 0
    if bTrigger then
        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_bonusSymbol_showBuff)
        local symbolList = {}
        local iRow = 1
        local disappearTime = 0
        local freeType = 2
        for i,_buffData in ipairs(buffList) do
            local iCol  = _buffData[1] + 1
            local slotCsb   = self.m_slotList[iCol]
            --刷新图标
            slotCsb:findChild("free_wildChange"):setVisible(true)
            local symbolNode = slotCsb:findChild(string.format("symbol_%d",  _buffData[3]))
            symbolNode:setVisible(true)
            --bonus消失
            disappearTime = self:playBonusSymbolDisappear(iCol, iRow)
            table.insert(symbolList, _buffData[3])
        end
        self.m_machine:levelPerformWithDelay(self, disappearTime, function()
            gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_buffCollect_wildChange)
            local flyTime = 0
            for i,_buffData in ipairs(buffList) do
                local iCol  = _buffData[1] + 1
                --飞行
                flyTime = self:playSlotRewardFly({
                    iCol = iCol,
                    freeType = freeType,
                })
            end
            self.m_machine:levelPerformWithDelay(self, flyTime, function()
                gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_buffCollectFeedback_wildChange)

                self.m_wildChangeList:updateWildChangeList(symbolList, false)
                --wild列表的Y坐标修改
                self:updateWildChangeListPosY(freeType)
                --buff上移，新buff淡入
                local animTime = self:setCenterLabStatus(freeType)
                --收集反馈
                self:playSlotRewardCollectAnim(freeType, function()
                end, _fun)
            end)
        end)
    else
        _fun()
    end
end
function WinningWizardSpecialReelView:openSlotReward_winMultiple(_buffList, _fun)
    local buffList = self:getBuffByKey(_buffList, self.CenterLabData.freeTypeKey_winMultiple)
    local bTrigger = #buffList > 0
    if bTrigger then
        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_bonusSymbol_showBuff)
        local allWinMultiple = 0
        local iRow = 1
        local disappearTime = 0
        local freeType = self:getFreeTypeByBuffList(_buffList)
        freeType = 1 == freeType and freeType or 3 

        for i,_buffData in ipairs(buffList) do
            local iCol  = _buffData[1] + 1
            local slotCsb   = self.m_slotList[iCol]
            --刷新乘倍
            slotCsb:findChild("free_winMultiple"):setVisible(true)
            local labNode = slotCsb:findChild("m_lb_winMultiple")
            labNode:setString(string.format("X%d", _buffData[3]))
            self.m_machine:updateLabelSize({label=labNode, sx=1, sy=1}, 51)
            --bonus消失
            disappearTime = self:playBonusSymbolDisappear(iCol, iRow)
            allWinMultiple = allWinMultiple + _buffData[3]
        end
        self.m_machine:levelPerformWithDelay(self, disappearTime, function()
            gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_buffCollect_winMultiple)

            local flyTime = 0
            for i,_buffData in ipairs(buffList) do
                local iCol  = _buffData[1] + 1
                --飞行
                flyTime = self:playSlotRewardFly({
                    iCol = iCol,
                    freeType = freeType,
                })
            end
            self.m_machine:levelPerformWithDelay(self, flyTime, function()
                gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_buffCollectFeedback_winMultiple)

                --buff上移，新buff淡入
                local animTime = self:setCenterLabStatus(freeType, function()
                    if 1 == freeType then
                        --wild列表的Y坐标修改
                        self:updateWildChangeListPosY(freeType)
                    end
                end)
                self:updateCenterLabWinMultipleNumber(allWinMultiple)
                --收集反馈
                self.m_machine:levelPerformWithDelay(self, 9/60, function()
                    self:playSlotRewardCollectAnim(freeType, function()
                    end, _fun)
                end)
            end)
        end)
    else
        _fun()
    end
end

function WinningWizardSpecialReelView:getBuffByKey(_buffList, _buffKey)
    local dataList = {}
    for i,_buffData in ipairs(_buffList) do
        if _buffKey == _buffData[2] then
            table.insert(dataList, _buffData)
        end
    end
    return dataList
end
function WinningWizardSpecialReelView:getBuffByCol(_buffList, _iCol)
    for i,_buffData in ipairs(_buffList) do
        if _iCol == _buffData[1] + 1 then
            return _buffData
        end
    end
    return nil
end

--bonus图标反转后消失为空白bonus+buff插槽出现
function WinningWizardSpecialReelView:playBonusSymbolDisappear(_iCol, _iRow)
    local lastNode = self.m_respinView:getWinningWizardSymbolNode(_iRow, _iCol)
    local symbolType = lastNode.p_symbolType
    if symbolType ~= self.m_machine.SYMBOL_TopReel_Bonus then
        return 0
    end
    local animName = "actionframe1"
    local buffData = self:getBuffByCol(self.m_buffList, _iCol)
    if nil ~= buffData then
        local animNameList = {
            [self.CenterLabData.freeTypeKey_freeTimes]   = "actionframe1",
            [self.CenterLabData.freeTypeKey_wildChange]  = "actionframe2",
            [self.CenterLabData.freeTypeKey_winMultiple] = "actionframe3",
        }
        animName = animNameList[buffData[2]] or animName
    end
    -- bonus消失 55帧
    lastNode:runAnim(animName, false, function()
        performWithDelay(lastNode,function()
            --切换空白bonus
            self.m_machine:changeWinningWizardSlotsNodeType(lastNode, self.m_machine.SYMBOL_TopReel_Blank)
            --解除锁定
            local reSpinNode = self.m_respinView:getRespinNode(_iRow, _iCol)
            reSpinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
            reSpinNode:setFirstSlotNode(lastNode)
        end, 0)
    end)
    -- bnuff出现 25帧
    self.m_machine:levelPerformWithDelay(self, 15/60, function()
        local slotCsb   = self.m_slotList[_iCol]
        slotCsb:runCsbAction("switch", false)
    end)

    return 54/60
end
--bonus粒子飞往中央
function WinningWizardSpecialReelView:playSlotRewardFly(_params)
    local iCol     = _params.iCol
    local freeType = _params.freeType
    local iRow = 1
    local slotCsb  = self.m_slotList[iCol]
    local startPos = util_convertToNodeSpace(slotCsb, self)
    local endNode  = self.m_centerLabCsb:findChild(string.format("Node_free%d_tx", freeType)) 
    local endPos   = util_convertToNodeSpace(endNode, self)
    --飞行粒子
    local flyCsb   = util_createAnimation("WinningWizard_Bonus_twlizi.csb")
    self:addChild(flyCsb, self.NodeOrder.Fly)
    flyCsb:setPosition(startPos)
    local particleNode = flyCsb:findChild("Particle_1")
    particleNode:setVisible(true)
    particleNode:stopSystem()
    particleNode:setPositionType(0)
    particleNode:setDuration(-1)
    particleNode:resetSystem()
    local flyTime = 30/60
    flyCsb:runAction(cc.Sequence:create(
        cc.MoveTo:create(flyTime, endPos),
        cc.CallFunc:create(function()
            particleNode:stopSystem()
            util_setCascadeOpacityEnabledRescursion(particleNode, true)
            particleNode:runAction(cc.FadeOut:create(0.5))
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
    return flyTime
end
--[[
    buff收集反馈
]]
function WinningWizardSpecialReelView:initSlotRewardCollectAnim()
    self.m_rewardCollectAnim = util_createAnimation("WinningWizard_fazhen_zhonjian_bd.csb")
    self:addChild(self.m_rewardCollectAnim, self.NodeOrder.CollectAnim)
    self.m_rewardCollectAnim:setVisible(false)
end
function WinningWizardSpecialReelView:playSlotRewardCollectAnim(_freeType, _switchFn, _endFn)
    self.m_rewardCollectAnim:stopAllActions()
    --刷新坐标
    local nodeName  = string.format("Node_free%d_tx", _freeType)
    local targetNode = self.m_centerLabCsb:findChild(nodeName)
    local pos = util_convertToNodeSpace(targetNode, self.m_rewardCollectAnim:getParent())
    self.m_rewardCollectAnim:setPosition(pos)
    self.m_rewardCollectAnim:setVisible(true)
    local animName = 4==_freeType and "actionframe1" or "actionframe"
    self.m_rewardCollectAnim:runCsbAction(animName)
    --42帧
    performWithDelay(self.m_rewardCollectAnim,function()
        _switchFn()
        performWithDelay(self.m_rewardCollectAnim,function()
            _endFn()
            self.m_rewardCollectAnim:setVisible(false)
        end, 27/60)
    end, 15/60)
end
--[[
    15个插槽的圆环遮盖
]]
function WinningWizardSpecialReelView:initSlotRing()
    local parent = self:findChild("Node_reSpinNode") 
    self.m_slotRingList = {}
    for _slotIndex=1,self.SLOTDATA.count do
        local csb    = util_createAnimation("WinningWizard_fazhen_cao_huan.csb")
        parent:addChild(csb, 100)
        self.m_slotRingList[_slotIndex] = csb
        local caoNode = self:findChild(string.format("Node_cao%d", _slotIndex))
        local pos = util_convertToNodeSpace(caoNode, parent)
        csb:setPosition(pos)
    end
end
--没触发玩法时用顶部圆环遮挡滚动，触发后圆环要切换到底层级被buff遮挡
function WinningWizardSpecialReelView:setSlotRingOrder(_bTop)
    for i,_csb in ipairs(self.m_slotRingList) do
        _csb:findChild("sp_frame"):setVisible(_bTop)
    end
    for i,_csb in ipairs(self.m_slotList) do
        _csb:findChild("sp_frame"):setVisible(not _bTop)
    end
end
--[[
    圆形滚轴看作reSpin
    1行15列
]]
function WinningWizardSpecialReelView:initWinningWizardRespinView()
    --用来处理延时取消
    self.m_reSpinActNode = self:findChild("Node_reSpinNode")

    local reSpinViewPath = "CodeWinningWizardSrc.WinningWizardReSpin.WinningWizardRespinView"
    local reSpinNodePath = "CodeWinningWizardSrc.WinningWizardReSpin.WinningWizardRespinNode"
    self.m_respinView = util_createView(reSpinViewPath, reSpinNodePath)
    self.m_respinView:setMachine(self.m_machine)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self.m_machine:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self.m_machine:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_reSpinActNode:addChild(self.m_respinView)
    local endTypes = self:getRespinLockTypes()
    local randomTypes = self:getRespinRandomTypes()
    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    local width = self.SLOTDATA.symbolHeight
    self.m_respinView:initRespinSize(width, width, width, width)
    local respinNodeInfo = self:reateRespinNodeInfo()
    self.m_respinView:initRespinElement(
        respinNodeInfo,
        1,
        15,
        function()
        end
    )
    --设置滚动参数
    self:initReSpinReelRunData()
    --存一些变量
    self.m_respinView.m_bJump = false
end
-- 根据本关卡实际小块数量填写
function WinningWizardSpecialReelView:getRespinRandomTypes()
    local symbolList = {
        self.m_machine.SYMBOL_TopReel_Bonus,
        self.m_machine.SYMBOL_TopReel_Blank,
        -- self.m_machine.SYMBOL_TopReel_BlackImprint,
    }
    return symbolList
end
-- 根据本关卡实际锁定小块数量填写
function WinningWizardSpecialReelView:getRespinLockTypes()
    local symbolList = {
        {type = self.m_machine.SYMBOL_TopReel_Bonus, runEndAnimaName = "buling", bRandom = false},
    }
    return symbolList
end
-- 使用工程上的挂点坐标
function WinningWizardSpecialReelView:reateRespinNodeInfo()
    local respinNodeInfo = {}
    for iCol=1,self.SLOTDATA.count do
        for iRow=1,1 do
            local node = self:findChild(string.format("Node_cao%d", iCol))
            local pos   = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
            local tag   = self.m_machine:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            local order = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            local symbolNodeInfo = {
                status    = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type      = self.m_machine.SYMBOL_TopReel_BlackImprint,
                Zorder    = order,
                Tag       = tag,
                Pos       = pos,
                ArrayPos  = {iY=iCol, iX=iRow}
            }
            table.insert(respinNodeInfo, symbolNodeInfo)
        end
    end
    return respinNodeInfo
end
--
function WinningWizardSpecialReelView:initReSpinReelRunData()
    --滚动间隔
    self.m_respinView:setBaseColInterVal(0)
end
function WinningWizardSpecialReelView:setReSpinReelRunData(_bQuickRun, _startCol)
    local baseSpeed  = self.m_machine:getMoveSpeedBySpinMode(NORMAL_SPIN_MODE)
    local quickSpeed =  self.m_machine.m_configData.p_reelLongRunSpeed
    local speed = _bQuickRun and quickSpeed or baseSpeed
    speed       = speed * self.SLOTDATA.speedScale
    local respinNodes = self.m_respinView.m_respinNodes   
    if _bQuickRun then
        for i,_reSpinNode in ipairs(respinNodes) do
            local baseCol = self:getBaseColByReSpinCol(_reSpinNode.p_colIndex)
            if baseCol >= _startCol then
                _reSpinNode:setRunSpeed(speed)
            end
        end
    else
        for i,_reSpinNode in ipairs(respinNodes) do
            _reSpinNode:setRunSpeed(speed)
        end
    end
end
function WinningWizardSpecialReelView:getBaseColByReSpinCol(respinCol)
    for _baseCol,_reSpinColList in ipairs(self.SLOTDATA.baseColToReSpinCol) do
        for i,_reSpinCol in ipairs(_reSpinColList) do
            if _reSpinCol == respinCol then
                return _baseCol
            end
        end
    end
    return 1
end

--设置reSpin棋盘
function WinningWizardSpecialReelView:setReSpinReelByPosData(_posData)
    --[[
        列表内只存放 固定的bonus坐标
        _posData = {0, 1, 2}
    ]]
    local reel     = self:getReSpinReelByPosData(_posData)
    local idleName = self:getSlotIdleNameByCount(#_posData) 
    local iRow = 1
    for iCol=1,self.SLOTDATA.count do
        local reSpinNode = self.m_respinView:getRespinNode(iRow, iCol)
        local lastNode   = self.m_respinView:getWinningWizardSymbolNode(iRow, iCol)
        local symbolType = reel[1][iCol]
        local bLock      = self.m_respinView:getTypeIsEndType(symbolType)
        local iStatus    = bLock and RESPIN_NODE_STATUS.LOCK or RESPIN_NODE_STATUS.IDLE
        self.m_machine:changeWinningWizardSlotsNodeType(lastNode, symbolType)
        reSpinNode:setRespinNodeStatus(iStatus)
        if bLock then
            local worldPos = lastNode:getParent():convertToWorldSpace(cc.p(lastNode:getPositionX(), lastNode:getPositionY()))
            local pos = self.m_respinView:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self.m_respinView, lastNode, 0)
            lastNode:setTag(self.m_respinView.REPIN_NODE_TAG)
            lastNode:setPosition(pos)
            lastNode:runAnim(idleName, true)
        else
            reSpinNode:setFirstSlotNode(lastNode)
        end
    end
end
function WinningWizardSpecialReelView:getReSpinReelByPosData(_posData)
    local reel = {}
    local lineIndex = 1
    reel[lineIndex] = {}
    for iCol=1,self.SLOTDATA.count do
        reel[lineIndex][iCol] = self.m_machine.SYMBOL_TopReel_BlackImprint
    end
    for i,_reelIndex in ipairs(_posData) do
        local iCol = _reelIndex + 1
        reel[lineIndex][iCol] = self.m_machine.SYMBOL_TopReel_Bonus
    end

    return  reel
end
function WinningWizardSpecialReelView:getReSpinReelStopRunData(_posData)
    local storedData = {}
    local unStoredData = {}
    local iRow = 1
    for iCol=1,self.SLOTDATA.count do
        local bLock      = false
        local symbolType = self.m_machine.SYMBOL_TopReel_BlackImprint
        for i,_reelIndex in ipairs(_posData) do
            if _reelIndex + 1 == iCol then
                bLock = true
                symbolType = self.m_machine.SYMBOL_TopReel_Bonus
            end
        end
        local pos = {iX = iRow, iY = iCol, type = symbolType}

        if bLock then
            storedData[#storedData + 1] = pos
        else
            unStoredData[#unStoredData + 1] = pos
        end
    end

    return storedData,unStoredData
end

--根据住轮盘的滚动模式 刷新reSpinReel的状态
function WinningWizardSpecialReelView:upDateReSpinReelStatus()
    local bFree = self.m_machine.m_bProduceSlots_InFreeSpin
    if bFree then
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
    else
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    end
end

--reSpinReel滚动
function WinningWizardSpecialReelView:beginReSpinReelMove()
    local reelStatus = self.m_respinView:getouchStatus()
    if reelStatus ~= ENUM_TOUCH_STATUS.ALLOW then
        return
    end
    self.m_machine:addWinningWizardReelDownTimes()

    --滚动速度
    self:setReSpinReelRunData(false)
    local mainMachineCfg = self.m_machine.m_configData
    if mainMachineCfg.p_reelBeginJumpTime > 0 then
        self.m_respinView.m_bJump = true
        self:addJumoActionAfterReel(function()
            self.m_respinView.m_bJump = false
            self.m_respinView:startMove()
        end)
    else
        self.m_respinView:startMove()
    end
end
function WinningWizardSpecialReelView:addJumoActionAfterReel(_fun)
    local mainMachineCfg = self.m_machine.m_configData
    --添加一个回弹效果
    local jumpTime  = mainMachineCfg.p_reelBeginJumpTime
    local jumpHight = self.SLOTDATA.symbolHeight / 6
    local iRow = 1
    for iCol=1,self.SLOTDATA.count do
        local reSpinNode = self.m_respinView:getRespinNode(iRow, iCol)
        local nodeStatus = reSpinNode:getRespinNodeStatus()
        local bLock = nodeStatus == RESPIN_NODE_STATUS.LOCK
        if not bLock then
            local lastNode = self.m_respinView:getWinningWizardSymbolNode(iRow, iCol)
            local pos      = cc.p(lastNode:getPosition())
            local actJump  = cc.JumpTo:create(jumpTime, pos, jumpHight, 1)
            lastNode:runAction(actJump)
        end
    end
    performWithDelay(self.m_reSpinActNode,function()
        _fun()
    end, jumpTime)
end
function WinningWizardSpecialReelView:resetAllLastNodePos()
    local iRow = 1
    for iCol=1,self.SLOTDATA.count do
        local reSpinNode = self.m_respinView:getRespinNode(iRow, iCol)
        local nodeStatus = reSpinNode:getRespinNodeStatus()
        local bLock = nodeStatus == RESPIN_NODE_STATUS.LOCK
        if not bLock then
            local lastNode = self.m_respinView:getWinningWizardSymbolNode(iRow, iCol)
            lastNode:stopAllActions()
            lastNode:setPosition(cc.p(0, 0))
        end
    end
end

function WinningWizardSpecialReelView:stopReSpinReelMove()
    local bFree = self.m_machine.m_bProduceSlots_InFreeSpin
    local reelStatus = self.m_respinView:getouchStatus()
    if bFree and reelStatus ~= ENUM_TOUCH_STATUS.RUN then
        return
    end
    local bonusPosData = self.m_machine:getCurBetBonusPosData()
    local storedNodeInfo,unStoredReels = self:getReSpinReelStopRunData(bonusPosData)
    --还没跳完数据就返回了
    if self.m_respinView.m_bJump and reelStatus ~= ENUM_TOUCH_STATUS.RUN then
        self.m_reSpinActNode:stopAllActions()
        self.m_respinView.m_bJump = false
        self:resetAllLastNodePos()
        self.m_respinView:startMove()
        self:setRunEndInfo(storedNodeInfo, unStoredReels)
    else
        self:setRunEndInfo(storedNodeInfo, unStoredReels)
    end
end
function WinningWizardSpecialReelView:reSpinViewQuickStop()
    local bFree = self.m_machine.m_bProduceSlots_InFreeSpin
    if bFree then
        return
    end

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        self.m_respinView:quicklyStop()
    elseif self.m_respinView.m_bJump then
        local bonusPosData = self.m_machine:getCurBetBonusPosData()
        local storedNodeInfo,unStoredReels = self:getReSpinReelStopRunData(bonusPosData)
        self.m_reSpinActNode:stopAllActions()
        self.m_respinView.m_bJump = false
        self:resetAllLastNodePos()
        self.m_respinView:startMove()
        self:setRunEndInfo(storedNodeInfo, unStoredReels)
        self.m_respinView:quicklyStop()
    end
end

function WinningWizardSpecialReelView:setRunEndInfo(storedNodeInfo, unStoredReels)
    local reelRunDatas = self.m_machine.m_configData.p_reelRunDatas
    local respinNodes  = self.m_respinView.m_respinNodes
    for i,_repsinNode in ipairs(respinNodes) do
        local baseCol = self:getBaseColByReSpinCol(_repsinNode.p_colIndex)
        local reelRunData = self.m_machine.m_reelRunInfo[baseCol]
        local reelRunLength = reelRunData:getReelRunLen()
        --滚动的倍数比例(主轮盘和顶部轮盘的比例)
        local runMultiple = self.m_machine.m_SlotNodeH/self.SLOTDATA.symbolHeight
        local runLong = math.ceil(reelRunLength * runMultiple * self.SLOTDATA.speedScale) 
        --固定
        for ii,_data in ipairs(storedNodeInfo) do
            if _repsinNode.p_rowIndex == _data.iX and _repsinNode.p_colIndex == _data.iY then
                _repsinNode:setRunInfo(runLong, _data.type)
          end
        end
        --非固定
        for ii,_data in ipairs(unStoredReels) do
            if _repsinNode.p_rowIndex == _data.iX and _repsinNode.p_colIndex == _data.iY then
                _repsinNode:setRunInfo(runLong, _data.type)
            end
        end
    end
end

function WinningWizardSpecialReelView:reSpinReelDown()
    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    self.m_machine:reelDownNotifyPlayGameEffect()
end

--[[
    free断线重连
]]
function WinningWizardSpecialReelView:freeReconnectionUpdateBuffList()
    local fsExtraData = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    local buffList    = fsExtraData.buff or {}
    local freeType    = self:getFreeTypeByBuffList(buffList)

    self:setCenterLabStatus(freeType)
    self:setSlotRingOrder(false)
    local iRow = 1
    --将buff区域转换为空图标
    for i,_buffData in ipairs(buffList) do
        local iCol  = _buffData[1] + 1
        local lastNode = self.m_respinView:getWinningWizardSymbolNode(iRow, iCol)
        --切换空白bonus
        self.m_machine:changeWinningWizardSlotsNodeType(lastNode, self.m_machine.SYMBOL_TopReel_Blank)
    end
    --free次数
    local freeTimesList = self:getBuffByKey(buffList, self.CenterLabData.freeTypeKey_freeTimes)
    for i,_buffData in ipairs(freeTimesList) do
        local iCol  = _buffData[1] + 1
        local slotCsb   = self.m_slotList[iCol]
        --刷新次数
        slotCsb:findChild("free_freeTimes"):setVisible(true)
        local labTimes = slotCsb:findChild("m_lb_freeTimes")
        labTimes:setString(string.format("+%d", _buffData[3]))
        self.m_machine:updateLabelSize({label=labTimes, sx=1, sy=1}, 51)
        slotCsb:runCsbAction("idle2")
    end
    self:updateCenterLabFreeTimesNoParams()
    --free wild变化
    local wildChangeList = self:getBuffByKey(buffList, self.CenterLabData.freeTypeKey_wildChange)
    local symbolList = {}
    for i,_buffData in ipairs(wildChangeList) do
        local iCol  = _buffData[1] + 1
        local slotCsb   = self.m_slotList[iCol]
        --刷新图标
        slotCsb:findChild("free_wildChange"):setVisible(true)
        local symbolNode = slotCsb:findChild(string.format("symbol_%d",  _buffData[3]))
        slotCsb:runCsbAction("idle2")
        symbolNode:setVisible(true)
        table.insert(symbolList, _buffData[3])
    end
    self.m_wildChangeList:updateWildChangeList(symbolList, false)
    self:updateWildChangeListPosY(freeType)
    --free结算乘倍
    local winMultipleList = self:getBuffByKey(buffList, self.CenterLabData.freeTypeKey_winMultiple)
    local allWinMultiple  = 0
    for i,_buffData in ipairs(winMultipleList) do
        local iCol  = _buffData[1] + 1
        local slotCsb   = self.m_slotList[iCol]
        --刷新乘倍
        local labNode = slotCsb:findChild("m_lb_winMultiple")
        labNode:setString(string.format("X%d", _buffData[3]))
        self.m_machine:updateLabelSize({label=labNode, sx=1, sy=1}, 51)
        slotCsb:runCsbAction("idle2")
        slotCsb:findChild("free_winMultiple"):setVisible(true)

        allWinMultiple  = allWinMultiple + _buffData[3]
    end
    self:updateCenterLabWinMultipleNumber(allWinMultiple)
end
return WinningWizardSpecialReelView