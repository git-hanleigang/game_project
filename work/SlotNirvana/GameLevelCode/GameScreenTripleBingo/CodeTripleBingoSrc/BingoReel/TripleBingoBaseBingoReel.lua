--[[
    基础bingo棋盘
]]
local TripleBingoBaseBingoReel = class("TripleBingoBaseBingoReel", util_require("base.BaseView"))

--棋盘相关配置
TripleBingoBaseBingoReel.ReelConfig = {
    iCol = 5,
    iRow = 5,
    symbolScale = 0.75,
}

function TripleBingoBaseBingoReel:initUI(_data)
    --[[
        _data = {
            machine        = mainMachine
            bingoReelIndex = 1
            symbolType     = 94
        }
    ]]
    self.m_machine = _data.machine
    self.m_initData = _data

    self.m_lineFrameList = {}

    self:createCsbNode("TripleBingo_Bingoqipan.csb")
    self:updateReelBg(self.m_initData.bingoReelIndex)
    self:initBingoSymbolList()
    self:initLockAnim()
    self:initBingoTip()
    self:initResetEffect()
    self:initBongoLineEffect()
end
--[[
    棋盘时间线
]]
function TripleBingoBaseBingoReel:playBingoReelIdleAnim()
    -- self:runCsbAction("")
end


--[[
    背景底板
]]
function TripleBingoBaseBingoReel:updateReelBg(_bingoReelIndex)
    for _index=1,3 do
        local bVisible = _index == _bingoReelIndex
        local bgNode = self:findChild(string.format("Node_bingo%d", _index))
        bgNode:setVisible(bVisible)
        local darkbg = self:findChild(string.format("Node_suoding_%d", _index))
        bgNode:setVisible(bVisible)
    end
end

--[[
    图标
]]
function TripleBingoBaseBingoReel:initBingoSymbolList()
    self.m_symbolParent = self:findChild(string.format("Node_bingoSymbol_%d", self.m_initData.bingoReelIndex))
    local spReel0      = self:findChild("sp_reel_0")
    local reelSize     = spReel0:getContentSize()
    local symbolHeight = math.floor(reelSize.height / self.ReelConfig.iRow)
    
    self.m_bingoSymbolSize = cc.size(reelSize.width, symbolHeight)
    self.m_bingoSymbolList = {}
    for _index=1,25 do
        local reelPos = _index - 1
        local fixPos  = self.m_machine:getRowAndColByPos(reelPos)
        local bCenter = 3 == fixPos.iY and 3 == fixPos.iX
        local symbol  = self:createBingoSymbol(self.m_initData.symbolType, fixPos.iY, fixPos.iX)
        local zorder = 0
        if bCenter then
            zorder = 100
        end
        self.m_symbolParent:addChild(symbol,zorder)
        symbol:setScale(self.ReelConfig.symbolScale)
        self.m_bingoSymbolList[_index] = symbol
    end
end
function TripleBingoBaseBingoReel:createBingoSymbol(_symbolType, _iCol, _iRow)
    local symbol  = self.m_machine:createSymbolAniNode(self.m_initData.symbolType)
    --创建时存一些变量
    symbol.p_cloumnIndex = _iCol
    symbol.p_rowIndex    = _iRow
    symbol.m_reelPos     = self.m_machine:getPosReelIdx(_iRow, _iCol)
    --根据图标类型初始化
    self.m_machine:upDateBonusSkin(symbol)
    self:addSpineSymbolNode(symbol)

    return symbol
end
function TripleBingoBaseBingoReel:addSpineSymbolNode(_symbol,_addNode)
    --[[
        三种bingo图标结构
            Socre_TripleBingo_Bonus
                cc.Node     挂一层普通节点便于删除所有子节点
                    Socre_TripleBingo_BingoBonus_L1_%s 这一层根据类型修改(金币、jackpot、金币+jackpot、玩法)
    ]]
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    if not self.m_machine:isFixSymbol(symbolType) then
        return
    end
    local slotName = "shuzi2"
    local animNode = _symbol:checkLoadCCbNode()
    local spineNode = animNode.m_spineNode or (_symbol.m_symbolType and animNode) 
    if not tolua.isnull(animNode.m_slotNode) then
        util_spineRemoveBindNode(spineNode, animNode.m_slotNode)
    end
    animNode.m_slotNode = cc.Node:create()
    if _addNode then
        animNode.m_slotNode:addChild(_addNode)
    end
    util_spinePushBindNode(spineNode, slotName, animNode.m_slotNode)
    
end
function TripleBingoBaseBingoReel:upDateAllBingoSymbol()
    for _index,_symbol in ipairs(self.m_bingoSymbolList) do
        local reelPos = _index - 1
        local reward = self.m_machine:getBingoSymbolReward(self.m_initData.bingoReelIndex, reelPos)
        local bCenter = self:isBingoCenterSymbol(_symbol)
        if bCenter or (reward.socre and reward.socre > 0) or reward.jackpot then
            _symbol:setVisible(true)
            self:upDateBingoSymbolType(_symbol)
        else
            _symbol:setVisible(false)
        end
    end
end

function TripleBingoBaseBingoReel:resetAllAnimaton()
    for _index,_symbol in ipairs(self.m_bingoSymbolList) do
        local reelPos = _index - 1
        local reward = self.m_machine:getBingoSymbolReward(self.m_initData.bingoReelIndex, reelPos)
        if not tolua.isnull(_symbol) then
            _symbol:setVisible(false)
            local animNode    = _symbol:checkLoadCCbNode()
            local slotCsb     = animNode.m_slotCsb
            if not tolua.isnull(slotCsb) then
                slotCsb:stopAllActions()
                slotCsb:runCsbAction("idleframe")
            end
            _symbol:resetTimeAnim()
        end
    end
end


function TripleBingoBaseBingoReel:upDateBingoSymbolType(_symbol)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    if not self.m_machine:isFixSymbol(symbolType) then
        return
    end

    local bCenter = self:isBingoCenterSymbol(_symbol)
    local reward = self.m_machine:getBingoSymbolReward(self.m_initData.bingoReelIndex, _symbol.m_reelPos)
    local imgType = self.m_initData.centerSymbolType
    if not bCenter  then
        imgType = reward.symbolType
    end
    --绑定csb
    self:upDateBingoSymbolBindCsb(_symbol, nil)
    --刷新金币
    if self.m_machine:isCoinsBindSymbol(reward.symbolType) then
        local animNode = _symbol:checkLoadCCbNode()
        self:upDateBingoSymbolScore(animNode.m_slotCsb, reward.socre)
    end

    --高倍播循环idle
    local bHigh = self.m_machine:checkBingoSymbolHigh(self.m_initData.bingoReelIndex, _symbol.p_cloumnIndex, _symbol.p_rowIndex)
    self.m_machine:upDateBingoSymbolIdle(_symbol, bCenter, bHigh)

    if bCenter then
        local animNode = _symbol:checkLoadCCbNode()
        local slotCsb     = animNode.m_slotCsb
        if not tolua.isnull(slotCsb) then
            slotCsb:runCsbAction("idleframe2",true)
        end
    end
end

function TripleBingoBaseBingoReel:upDateBingoSymbolBindCsb(_symbol, _bonusReward)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    if not self.m_machine:isFixSymbol(symbolType) then
        return
    end
    local animNode = _symbol:checkLoadCCbNode()
    local slotNode = animNode.m_slotNode
    local imgType = self.m_initData.centerSymbolType

    if _bonusReward then
        imgType = _bonusReward.symbolType
    elseif not self:isBingoCenterSymbol(_symbol) then
        local reward = self.m_machine:getBingoSymbolReward(self.m_initData.bingoReelIndex, _symbol.m_reelPos)
        imgType = reward.symbolType
    end

    --绑定csb
    local bindName = tostring(imgType)
    local csb      = slotNode:getChildByName(bindName)
    local resName = self.m_machine:getBindImgName(imgType)
    local csbName = string.format("%s.csb", resName)
    local csbNew = util_createAnimation(csbName) 
    csbNew:setName(bindName)
    animNode.m_slotCsb = csbNew
    --创建时存一下变量
     if not csb then
        animNode.m_slotCsb.m_score = 0
    else
        animNode.m_slotCsb.m_score = csb.m_score
    end
    self:addSpineSymbolNode(_symbol,csbNew)
end
function TripleBingoBaseBingoReel:upDateBingoSymbolScore(_labCsb, _score)
    local labCoins = _labCsb:findChild("m_lb_coins")
    if not labCoins or not _score then
        return
    end
    local sScore = util_formatCoins(_score, 3)
    labCoins:setString(sScore)
    _labCsb.m_score = _score
    self:updateLabelSize({label = labCoins, sx = 0.3, sy = 0.3}, 283)
end
function TripleBingoBaseBingoReel:bingoSymbolJumpCoins(_labCsb, _curCoins, _targetCoins, _time)
    local offsetValue = _targetCoins - _curCoins
    if offsetValue <= 0 then
        return
    end
    local coinRiseNum =  offsetValue / (_time * 60)
    local sRandomCoinRiseNum   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = math.ceil(tonumber(sRandomCoinRiseNum))  
    _labCsb:stopAllActions()
    schedule(_labCsb, function()
        _curCoins = _curCoins + coinRiseNum
        _curCoins = LongNumber.min(_targetCoins, _curCoins)
        self:upDateBingoSymbolScore(_labCsb, _curCoins)
        if toLongNumber(_curCoins) >= toLongNumber(_targetCoins) then
            _labCsb:stopAllActions()
        end
    end,0.008)
end

function TripleBingoBaseBingoReel:stopBingoSymbolJumpCoins(_labCsb, _targetCoins)
    _labCsb:stopAllActions()
    self:upDateBingoSymbolScore(_labCsb, _targetCoins)
end

--中心图标触发
function TripleBingoBaseBingoReel:playCenterSymbolTriggerAnim(_fun)
    local symbol = self:getBingoReelFixSymbol(3, 3)
    symbol:runAnim("actionframe2", false)
    self.m_machine:levelPerformWithDelay(self, 60/30, _fun)
end

--中心图标展示奖励
function TripleBingoBaseBingoReel:upDateBingoCenterSymbolReward()
    local iCol = 3
    local iRow = 3
    local symbol = self:getBingoReelFixSymbol(iCol, iRow)
    local reward = self.m_machine:getBingoSymbolReward(self.m_initData.bingoReelIndex, symbol.m_reelPos)
    symbol:runAnim("switch", false, function()
        local bHigh = self.m_machine:checkBingoSymbolHigh(self.m_initData.bingoReelIndex, symbol.p_cloumnIndex, symbol.p_rowIndex)
        self.m_machine:upDateBingoSymbolIdle(symbol, false, bHigh)
    end)
    self.m_machine:levelPerformWithDelay(self, 15/30, function()
        --绑定csb
        self:upDateBingoSymbolBindCsb(symbol, reward)
        --刷新金币
        if self.m_machine:isCoinsBindSymbol(reward.symbolType) then
            local animNode = symbol:checkLoadCCbNode()
            self:upDateBingoSymbolScore(animNode.m_slotCsb, reward.socre)
        end
    end)
end

--获取bingo棋盘图标
function TripleBingoBaseBingoReel:getBingoReelFixSymbol(_iCol, _iRow)
    for i,_symbol in ipairs(self.m_bingoSymbolList) do
        if _iCol == _symbol.p_cloumnIndex and _iRow == _symbol.p_rowIndex then
            return _symbol
        end
    end
    return nil
end
--坐标
function TripleBingoBaseBingoReel:onEnterUpDateBingoSymbolPos()
    local parent   = self.m_symbolParent
    for i,_symbol in ipairs(self.m_bingoSymbolList) do
        local reelPos   = i-1
        local fixPos    = self.m_machine:getRowAndColByPos(reelPos)
        local spReel    = self:findChild(string.format("sp_reel_%d", fixPos.iY-1))
        local reelSize  = spReel:getContentSize()
        local startPos  = util_convertToNodeSpace(spReel, parent)
        local symbolPosX = startPos.x + 0.5 * self.m_bingoSymbolSize.width
        local symbolPosY = startPos.y + (fixPos.iX - 1 + 0.5) * self.m_bingoSymbolSize.height
        _symbol:setPosition(symbolPosX, symbolPosY)
    end
end

function TripleBingoBaseBingoReel:isBingoCenterSymbol(_symbol)
    local bCenter = 3 == _symbol.p_cloumnIndex and 3 == _symbol.p_rowIndex
    return bCenter
end
--[[
    锁定
]]
function TripleBingoBaseBingoReel:initLockAnim()
    self.m_lockParent = self:findChild(string.format("Node_suoding_%d", self.m_initData.bingoReelIndex))
    if not self.m_lockParent or self.m_initData.bingoReelIndex == 1 then 
        return 
    end

    --解锁图层
    self.m_panelClick = self:findChild("Panel_click")
    self:addClick(self.m_panelClick)

    --默认锁定
    self.m_lockSpine = util_spineCreate("TripleBingo_Bingoqipan", true, true)
    self.m_lockParent:addChild(self.m_lockSpine)
    self.m_lockParent:setVisible(false)
    local skinName = 2 == self.m_initData.bingoReelIndex and "lanse" or "fense"
    self.m_lockSpine:setSkin(skinName)
    self:playLockIdleAnim()
end
function TripleBingoBaseBingoReel:playLockIdleAnim()
    if not self.m_lockParent or self.m_initData.bingoReelIndex == 1 then 
        return 
    end

    self.m_panelClick:setVisible(true)

    local animName = "idlefreame2"
    util_spinePlay(self.m_lockSpine, animName, true)
end
function TripleBingoBaseBingoReel:playLockSpineAnim(_bLock, _fun)
    local animName  = _bLock and "suoding" or "jiesuo"
    local delayTime = _bLock and 36/30 or 15/30
    util_spinePlay(self.m_lockSpine, animName, false)
    performWithDelay(self.m_lockSpine, _fun, delayTime)
    --遮罩
    local maskAnimName = _bLock and "darkstart" or "darkover"
    self:runCsbAction(maskAnimName, false)
end

function TripleBingoBaseBingoReel:upDateLockAnimState(_iBetLevel, _bAnim)
    local isLock = nil
    if not self.m_lockSpine or  self.m_initData.bingoReelIndex == 1 then 
        return 
    end
    
    local bLock = self.m_lockParent:isVisible()
    local newLockState = _iBetLevel + 1 < self.m_initData.bingoReelIndex 
    if bLock ~= newLockState then
        self.m_lockSpine:stopAllActions()
        self.m_lockParent:setVisible(true)
        if _bAnim then
            isLock = newLockState
            self:playLockSpineAnim(newLockState, function()
                self:setLockAnimShow(newLockState)
            end)
        else
            --直接刷新锁定dile
            self:setLockAnimShow(newLockState)
        end
    end
    return isLock
end
function TripleBingoBaseBingoReel:setLockAnimShow(_bLock)
    if _bLock then
        self:playLockIdleAnim()
    else
        self.m_panelClick:setVisible(false)
        self.m_lockParent:setVisible(false)
    end
end


--默认按钮监听回调
function TripleBingoBaseBingoReel:clickFunc(sender)
    --选择bet档位界面
    if self.m_machine:isCanOpenChooseView() then
        self.m_panelClick:setVisible(false)
        self.m_machine:changeBetMultiply(self.m_initData.bingoReelIndex, true)
    end
end
--[[
    bingo达成提示
]]
function TripleBingoBaseBingoReel:initBingoTip()
    self.m_bingoTipSpine = util_spineCreate("TripleBingo_Bingo", true, true)
    self:findChild("Node_bingoTip"):addChild(self.m_bingoTipSpine)
    self.m_bingoTipSpine:setVisible(false)
    local skinCfg = {
        [self.m_machine.FIXBONUS_TYPE_LEVEL1] = "huang", 
        [self.m_machine.FIXBONUS_TYPE_LEVEL2] = "lan",
        [self.m_machine.FIXBONUS_TYPE_LEVEL3] = "fen",
    }
    local skinName = skinCfg[self.m_initData.symbolType]
    self.m_bingoTipSpine:setSkin(skinName)
end
function TripleBingoBaseBingoReel:playBingoTip(_fun)
    self.m_bingoTipSpine:setVisible(true)
    local animName = "auto"
    util_spinePlay(self.m_bingoTipSpine, animName, false)
    util_spineEndCallFunc(self.m_bingoTipSpine, animName, function()
        self.m_bingoTipSpine:setVisible(false)
        _fun()
    end)
    self.m_machine:levelDeviceVibrate(6, "bonus")
end

--[[
    随机初始化bingo棋盘
]]
function TripleBingoBaseBingoReel:playInitCoinsAnim(_initCoinsData)
    local delayTime = 0
    local curBet   = globalData.slotRunData:getCurTotalBet()
    for _sReelPos,_sCoins in pairs(_initCoinsData) do
        local reelPos = tonumber(_sReelPos)
        local fixPos  = self.m_machine:getRowAndColByPos(reelPos)
        local bingoReelSymbol = self:getBingoReelFixSymbol(fixPos.iY, fixPos.iX)
        local reward = {} 
        reward.socre      = tonumber(_sCoins)
        reward.symbolType = self.m_machine:getBingoSymbolType(self.m_initData.bingoReelIndex, reward.jackpot, reward.socre)
        self:upDateBingoSymbolBindCsb(bingoReelSymbol, reward)
        --刷新金币
        if self.m_machine:isCoinsBindSymbol(reward.symbolType) then
            local animNode = bingoReelSymbol:checkLoadCCbNode()
            self:upDateBingoSymbolScore(animNode.m_slotCsb, reward.socre)
        end
        local bHigh       = true --self.m_machine:isHighBonusMulti(reward.socre / curBet)
        local animName    = bHigh and "start2" or "start"
        bingoReelSymbol:runAnim(animName, false)
        bingoReelSymbol:setVisible(true)
        delayTime = math.max(delayTime, (bHigh and 15/30 or 18/30))
    end

    return delayTime
end


--[[
    期待动画
]]
function TripleBingoBaseBingoReel:getBingoReelExpectAnimParent()
    --后期有层级要求在这里处理
    return self:findChild(string.format("Node_expectSpine_%d", self.m_initData.bingoReelIndex))
end
--[[
    bingo线
]]
--放大棋盘
function TripleBingoBaseBingoReel:playBigStartAnim(_fun)
    self:runCsbAction("bigstart", false, function()
        self:runCsbAction("bigidle", true)
        _fun()
    end)
    local pos = {cc.p(0,-78),cc.p(78,0),cc.p(-78,0)}
    local time = util_csbGetAnimTimes(self.m_csbAct, "bigstart", 60)
    util_playMoveByAction(self:findChild("root"), time, pos[self.m_initData.bingoReelIndex])
end
function TripleBingoBaseBingoReel:playOverAnim(_fun)
    self:runCsbAction("bigover", false, function()
        _fun()
    end)
    local pos = {cc.p(0,78),cc.p(-78,0),cc.p(78,0)}
    local time = util_csbGetAnimTimes(self.m_csbAct, "bigstart", 60)
    util_playMoveByAction(self:findChild("root"), time, pos[self.m_initData.bingoReelIndex])

end

-- 棋盘连线时压暗未参与连线的图标
function TripleBingoBaseBingoReel:playNoeLineSymbolDarkAnim(_linePos, _fun)
    for i,_symbol in ipairs(self.m_bingoSymbolList) do
        if not _linePos[tostring(_symbol.m_reelPos)] then
            _symbol:runAnim("darkstart", false)
            local animNode = _symbol:checkLoadCCbNode()
            local slotCsb = animNode.m_slotCsb
            if slotCsb then
                slotCsb:runCsbAction("darkstart", false) 
            end
        end
    end
    
    local delayTime = 12/30
    if _fun then
        self.m_machine:levelPerformWithDelay(self, delayTime, _fun)
    end
    return delayTime
end

--[[
    连线效果
]]
function TripleBingoBaseBingoReel:initBongoLineEffect()
    --bingo连线效果
    self.m_bingoLineSpine = util_spineCreate("TripleBingo_bigwin_ui", true, true)
    self:findChild("Node_fenwei"):addChild(self.m_bingoLineSpine)
    self.m_bingoLineSpine:setVisible(false)
end
function TripleBingoBaseBingoReel:playBongoLineEffect()
    local animName = "actionframe_bingo"
    self.m_bingoLineSpine:setVisible(true)
    util_spinePlay(self.m_bingoLineSpine, animName, false)
    util_spineEndCallFunc(self.m_bingoLineSpine, animName, function()
        self.m_bingoLineSpine:setVisible(false)
    end)
end

--展示连线框 播一次图标连线
function TripleBingoBaseBingoReel:playLineFrameAndSymbol(_bingoLines, _linePos, _fun)
    self:playBongoLineEffect()
    --图标
    for i,_symbol in ipairs(self.m_bingoSymbolList) do
        if _linePos[tostring(_symbol.m_reelPos)] then
            _symbol:runAnim("actionframe", false)
        end
    end
    --连线框
    local framePos = {}
    for i,_lineData in ipairs(_bingoLines) do
        local fixPos1 = self.m_machine:getRowAndColByPos(_lineData[1])
        local fixPos3 = self.m_machine:getRowAndColByPos(_lineData[3])
        local animName = self:getLineFrameAnimName(fixPos1, fixPos3)
        local posNode  = self:getBingoReelFixSymbol(fixPos3.iY, fixPos3.iX)
        local lineFrameSpine = self:createLineFrame()
        lineFrameSpine:setPosition( util_convertToNodeSpace(posNode, lineFrameSpine:getParent()) )
        util_spinePlay(lineFrameSpine, animName, false)
    end

    self.m_machine:levelPerformWithDelay(self, 45/30, function()
        --bingo提示
        self:playBingoTip(_fun)
    end)
end
function TripleBingoBaseBingoReel:createLineFrame()
    local lineFrameSpine = nil
    for i,v in ipairs(self.m_lineFrameList) do
        if not v:isVisible() then
            v:setVisible(true)
            lineFrameSpine = v
        end
    end
    if not lineFrameSpine then
        lineFrameSpine = util_spineCreate("TripleBingo_bingokuang", true, true)
        self:findChild("Node_lineFrame"):addChild(lineFrameSpine)
        table.insert(self.m_lineFrameList, lineFrameSpine)
    end
    return lineFrameSpine
end
function TripleBingoBaseBingoReel:getLineFrameAnimName(_fixPosA, _fixPosB)
    --[[
        actionframe2 : 0-100帧  横向
        actionframe3 : 0-100帧 竖向
        actionframe4 : 0-100帧 左上角链接右下角
        actionframe1 : 0-100帧 左下角链接右上角
    ]]
    if _fixPosA.iX == _fixPosB.iX then
        return "actionframe2"
    end
    if _fixPosA.iY == _fixPosB.iY then
        return "actionframe3"
    end
    if 1 == _fixPosA.iY then
        return "actionframe4"
    elseif 5 == _fixPosA.iY then
        return "actionframe1"
    end
    
    return "actionframe2"
end
function TripleBingoBaseBingoReel:hideLineFrameAnim()
    for i,v in ipairs(self.m_lineFrameList) do
        if v:isVisible() then
            v:setVisible(false)
        end
    end
end

--[[
    连线后spin重置收集区域
]]
function TripleBingoBaseBingoReel:initResetEffect()
    self.m_resetCsb = util_createAnimation("TripleBingo_Bingoqipan_tx.csb")
    self:findChild("Node_tx"):addChild(self.m_resetCsb)
    self.m_resetCsb:setVisible(false)
end
function TripleBingoBaseBingoReel:spinClearBingoLineSymbol(_func)
    local particleNode = self.m_resetCsb:findChild("Particle_1")
    particleNode:stopAllActions()
    util_setCascadeOpacityEnabledRescursion(particleNode, true)
    self.m_resetCsb:setVisible(true)
    particleNode:resetSystem()
    self.m_resetCsb:runCsbAction("actionframe", false, function()
    end)
    
    self.m_machine:levelPerformWithDelay(self, 33/60, function()
        self:upDateAllBingoSymbol()
        if _func then
            _func()
        end
        particleNode:stopSystem()
        particleNode:runAction(cc.Sequence:create(
            cc.DelayTime:create(1),
            cc.CallFunc:create(function()
                self.m_resetCsb:setVisible(false)
            end)
        ))
    end)
end

return TripleBingoBaseBingoReel