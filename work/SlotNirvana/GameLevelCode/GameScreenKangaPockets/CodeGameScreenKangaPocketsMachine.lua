--[[
玩法:  
    base:
        收集金币bonus:
            收集滚动出现的金币bonus直接给钱。
    bonus:
        多福多彩:
            滚动出现指定bonus图标后触发。
            获得至少一个jackpot奖励后结束。
    free:
        三个sc或者freeBonus图标触发。
]]
local KangaPocketsPublicConfig = require "KangaPocketsPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenKangaPocketsMachine = class("CodeGameScreenKangaPocketsMachine", BaseNewReelMachine)

CodeGameScreenKangaPocketsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenKangaPocketsMachine.SYMBOL_9 = 9
CodeGameScreenKangaPocketsMachine.SYMBOL_10 = 10
CodeGameScreenKangaPocketsMachine.SYMBOL_Bonus_Coins = 93
CodeGameScreenKangaPocketsMachine.SYMBOL_Bonus_Free  = 94
CodeGameScreenKangaPocketsMachine.SYMBOL_Bonus_Pick  = 95

CodeGameScreenKangaPocketsMachine.EFFECT_BonusBuling             = GameEffect.EFFECT_SELF_EFFECT - 10    --6个以上bonus落地，角色大拇指

CodeGameScreenKangaPocketsMachine.EFFECT_Bonus_OpenBonusSymbol   = GameEffect.EFFECT_LINE_FRAME + 1    --打开金币图标
CodeGameScreenKangaPocketsMachine.EFFECT_Bonus_OpenFeatureSymbol = GameEffect.EFFECT_LINE_FRAME + 2    --打开玩法图标
CodeGameScreenKangaPocketsMachine.EFFECT_Bonus_Pick              = GameEffect.EFFECT_LINE_FRAME + 3    --多福多彩


CodeGameScreenKangaPocketsMachine.JackpotName = {
    Grand = "grand",
    Major = "major",
    Minor = "minor",
    Mini = "mini",
}

-- 构造函数
function CodeGameScreenKangaPocketsMachine:ctor()
    CodeGameScreenKangaPocketsMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    --bonus界面缩放
    self.m_bonusGameScale = 1

    self.m_spinRestMusicBG = true
    -- 预告中奖标记
    self.m_isPlayWinningNotice = false
    -- 本次spin首次播放快滚框
    self.m_firstReelRunCol = 0
    -- 本次spin bonus图标数量
    self.m_spinBonusCount = 0
    -- 翻转bonus前停止连线
    self.m_stopLineFrame = false
    -- 第五列是否有图标播放了buling
    self.m_lastReelPlayBuling = false


    --init
    self:initGame()
end

function CodeGameScreenKangaPocketsMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end 
--
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenKangaPocketsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "KangaPockets"  
end




function CodeGameScreenKangaPocketsMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_jackpotBar = util_createView("CodeKangaPocketsSrc.KangaPocketsJackPotBarView", {machine = self})
    self:findChild("Node_Jackpot"):addChild(self.m_jackpotBar)

    self.m_freeBar = util_createView("CodeKangaPocketsSrc.KangaPocketsFreespinBarView")
    self:findChild("Node_freeBar"):addChild(self.m_freeBar)
    self.m_freeBar:setVisible(false)

    self.m_bonusGame = util_createView("CodeKangaPocketsSrc.KangaPocketsBonus.KangaPocketsBonusView", self)
    self:findChild("Node_bonus"):addChild(self.m_bonusGame)
    self.m_bonusGame:setVisible(false)

    self.m_kangaPocketsRole = util_createView("CodeKangaPocketsSrc.KangaPocketsRoleSpine", {})
    self:findChild("Node_roleSpine_up"):addChild(self.m_kangaPocketsRole)
    self.m_kangaPocketsRole:playIdleAnim()

    self.m_bonusGuoChangSpine = util_spineCreate("KangaPockets_guochang",true,true)
    self:addChild(self.m_bonusGuoChangSpine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_bonusGuoChangSpine:setVisible(false)

    self.m_bonusBgSpine = util_spineCreate("KangaPockets_guochang",true,true)
    self.m_gameBg:findChild("bonus"):addChild(self.m_bonusBgSpine)

    self.m_reelMask = self:findChild("Panel_reelMask")
    self.m_reelMask:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_MASK) 
    self.m_reelMask:setVisible(false)
    
    self.m_openBonusSkip = util_createView("CodeKangaPocketsSrc.KangaPocketsOpenBonusSkip", self)
    self:findChild("Node_openBonusSkip"):addChild(self.m_openBonusSkip)
    self.m_openBonusSkip:setVisible(false)

    util_setCascadeOpacityEnabledRescursion(self.m_gameBg, true)

    self.m_bonusGame:setScale(self.m_bonusGameScale)
    self.m_bonusBgSpine:setScale(self.m_bonusGameScale)
    self.m_bonusGuoChangSpine:setScale(self.m_bonusGameScale)

    self:changeReelBg("base", false)
end
function CodeGameScreenKangaPocketsMachine:getBottomUINode()
    return "CodeKangaPocketsSrc.KangaPocketsGameBottomNode"
end

--
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenKangaPocketsMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_9 then 
        return "Socre_KangaPockets_10"
    end
    if symbolType == self.SYMBOL_10 then 
        return "Socre_KangaPockets_11"
    end

    if symbolType == self.SYMBOL_Bonus_Coins then 
        return "Socre_KangaPockets_Bonus"
    end
    if symbolType == self.SYMBOL_Bonus_Free then 
        return "Socre_KangaPockets_Bonus"
    end
    if symbolType == self.SYMBOL_Bonus_Pick then 
        return "Socre_KangaPockets_Bonus"
    end

    return nil
end
--
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenKangaPocketsMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenKangaPocketsMachine.super.getPreLoadSlotNodes(self)
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_9,count =  2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Bonus_Coins,count =  2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Bonus_Free,count =  2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Bonus_Pick,count =  2}
    return loadNode
end

--[[
    界面挂件
]]
function CodeGameScreenKangaPocketsMachine:changeReelBg(_model, _playAnim)
    local bBase  = "base" == _model
    local bfree  = "free" == _model
    local bBonus = "bonus" == _model

    if _playAnim then
        --卷轴
        self:findChild("Reel_base"):setVisible(bBase)
        self:findChild("Reel_free"):setVisible(bfree)
        --背景
        self:findChild("Node_baseFree"):setVisible(not bBonus)
        if not bBonus then
            self.m_gameBg:findChild("Node_switch"):setVisible(true)
            local baseNode = self.m_gameBg:findChild("base")
            local freeNode = self.m_gameBg:findChild("free")
            self.m_gameBg:findChild("switch_base"):setVisible(baseNode:isVisible())
            self.m_gameBg:findChild("switch_free"):setVisible(freeNode:isVisible())
            baseNode:setVisible(bBase)
            freeNode:setVisible(bfree)
            self.m_gameBg:runCsbAction("switch", false, function()
                self.m_gameBg:findChild("Node_switch"):setVisible(false)
            end)
        end
        self.m_gameBg:findChild("bonus"):setVisible(bBonus)
        self:findChild("Node_baseFree"):setVisible(not bBonus)
    else
        --卷轴
        self:findChild("Reel_base"):setVisible(bBase)
        self:findChild("Reel_free"):setVisible(bfree)
        --背景
        self.m_gameBg:findChild("Node_switch"):setVisible(false)
        self:findChild("Node_baseFree"):setVisible(not bBonus)
        if not bBonus then
            self.m_gameBg:findChild("base"):setVisible(bBase)
            self.m_gameBg:findChild("free"):setVisible(bfree)
        end
        self.m_gameBg:findChild("bonus"):setVisible(bBonus)
    end
end

function CodeGameScreenKangaPocketsMachine:enterGamePlayMusic(  )
    self:playEnterGameSound(KangaPocketsPublicConfig.sound_KangaPockets_enterLevel)
end

function CodeGameScreenKangaPocketsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    local bgPos = util_convertToNodeSpace(self.m_bonusBgSpine, self)
    self.m_bonusGuoChangSpine:setScale(self.m_machineRootScale)
    self.m_bonusGuoChangSpine:setPosition(bgPos)

    CodeGameScreenKangaPocketsMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    -- 重连修改bonus图标展示
    if self.m_bProduceSlots_InFreeSpin then
        self:reconnectChangeBonusSymbol()
    end
end

function CodeGameScreenKangaPocketsMachine:initGridList()
    CodeGameScreenKangaPocketsMachine.super.initGridList(self)
    if not self:checkHasFeature() then
        self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
            local symbolType = _slotsNode.p_symbolType
            if symbolType == self.SYMBOL_Bonus_Coins then
                _slotsNode:runAnim("idleframe2", false)
                -- 第一个参数坐标不重要
                self:upDateBonusSymbolShow(_slotsNode, {0, 10})
            elseif symbolType == self.SYMBOL_Bonus_Free then
                _slotsNode:runAnim("idleframe2", false)
                -- 第一个参数坐标不重要
                self:upDateBonusSymbolShow(_slotsNode, {0, 10})
            end

            --修改滚动图标层级
            local symbolOrder = self:getBounsScatterDataZorder(symbolType)
            local showOrder = symbolOrder - _slotsNode.p_rowIndex
            _slotsNode.p_showOrder = showOrder
            _slotsNode.m_showOrder = showOrder
            _slotsNode:setLocalZOrder(showOrder)
        end)
    end
end
function CodeGameScreenKangaPocketsMachine:addObservers()
    CodeGameScreenKangaPocketsMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            -- 数值把钱一起给了,不存在金币bonus和多福多彩bonus时 播放连线
            local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
            local creditIcons   = selfData.creditIcons or {}
            local bonusPos      = selfData.bonusPos or {}
            local lineCoins = self:getClientWinCoins()
            if #creditIcons + #bonusPos < 1 then
                return
            end
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end
        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = KangaPocketsPublicConfig[string.format("sound_KangaPockets_freeLineFrame_%d", soundIndex)]
        else
            soundName = KangaPocketsPublicConfig[string.format("sound_KangaPockets_lineFrame_%d", soundIndex)]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenKangaPocketsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenKangaPocketsMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

--
--设置bonus scatter 层级
function CodeGameScreenKangaPocketsMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenKangaPocketsMachine.super.getBounsScatterDataZorder(self, symbolType)

    if symbolType ==  self.SYMBOL_Bonus_Coins or 
        symbolType ==  self.SYMBOL_Bonus_Free or
        symbolType ==  self.SYMBOL_Bonus_Pick then

        return REEL_SYMBOL_ORDER.REEL_ORDER_3
    end

    return order
end

--[[
    断线重连 
]]
function CodeGameScreenKangaPocketsMachine:MachineRule_initGame(  )
    if self.m_bProduceSlots_InFreeSpin then
        local collectLeftCount  = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        if collectLeftCount ~= collectTotalCount then
            --切换展示
            self.m_freeBar:changeFreeSpinByCount()
            self.m_freeBar:setVisible(true)
            self:changeReelBg("free", false)
        end
    end

end
function CodeGameScreenKangaPocketsMachine:reconnectChangeBonusSymbol()
    local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
    local creditIcons   = selfData.creditIcons or {}
    local bonusPos      = selfData.bonusPos or {}
    local bonusFree     = selfData.freeSpinIcons or {}

    local fnChangeBonusSymbol = function(_iconData)
        local slotsPos  = _iconData[1]
        local fixPos    = self:getRowAndColByPos(slotsPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

        slotsNode:getCcbProperty("sp_colorBg_1"):setVisible(false)
        slotsNode:getCcbProperty("Particle_1"):setVisible(false)
        slotsNode:getCcbProperty("Particle_1"):stopSystem()

        local switchBg,switchParticle = self:upDateBonusSymbolShow(slotsNode, _iconData)

        slotsNode:runAnim("idleframe2", false)
        if slotsNode.p_symbolType == self.SYMBOL_Bonus_Coins then
        elseif slotsNode.p_symbolType == self.SYMBOL_Bonus_Free then
            switchBg:setVisible(true)
            switchParticle:setPositionType(0)
            switchParticle:setDuration(-1)
            switchParticle:stopSystem()
            switchParticle:resetSystem()
            switchParticle:setVisible(true)
        elseif slotsNode.p_symbolType == self.SYMBOL_Bonus_Pick then
            switchBg:setVisible(false)
            switchParticle:setVisible(false)
            switchParticle:stopSystem()
        end
    end

    for i,_iconData in ipairs(creditIcons) do
        fnChangeBonusSymbol(_iconData)
    end
    for i,_slotsPos in ipairs(bonusPos) do
        local iconData  = {_slotsPos}
        fnChangeBonusSymbol(iconData)
    end
    for i,_iconData in ipairs(bonusFree) do
        fnChangeBonusSymbol(_iconData)
    end
end

--[[
    Spin逻辑开始时触发
]]
-- 用于延时滚动轮盘等
function CodeGameScreenKangaPocketsMachine:MachineRule_SpinBtnCall()
    self:stopLinesWinSound()
    self:setMaxMusicBGVolume( )
    self:beginReelStopAllBonusParticle()
    -- 重置一些标记
    self.m_firstReelRunCol = 0
    self.m_stopLineFrame = false
    self.m_lastReelPlayBuling = false

    return false
end

-- 需要关卡重写的方法
function CodeGameScreenKangaPocketsMachine:operaSpinResultData(param)
	CodeGameScreenKangaPocketsMachine.super.operaSpinResultData(self,param)

	-- 预告中奖标记 方法内判断是否播放条件后直接播放，返回一个布尔标记
	self.m_isPlayWinningNotice = self:playYugaoAnim()
end
function CodeGameScreenKangaPocketsMachine:playYugaoAnim()
    local selfData   = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusCoins = selfData.creditIcons or {}
    local bonusPick  = selfData.bonusPos or {}
    local bonusFree  = selfData.freeSpinIcons or {}
    local bonusCount = #bonusCoins + #bonusPick + #bonusFree
    local probability = 7 >= math.random(1, 10)
    local bPlayYugao  = bonusCount >= 8 and probability

    if bPlayYugao then
        local soundName = KangaPocketsPublicConfig[string.format("sound_KangaPockets_yuGao_%d", math.random(1, 2))]
        gLobalSoundManager:playSound(soundName)
        self:runCsbAction("yugao", false)
        self.m_kangaPocketsRole:playYuGaoAnim()
        return true
    end

    return false
end
-- 关卡重写方法
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenKangaPocketsMachine:MachineRule_ResetReelRunData()
    if self.m_isPlayWinningNotice then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            local preRunLen = reelRunData.initInfo.reelRunLen
            -- 底层算好的滚动长度
            local runLen = reelRunData:getReelRunLen()
            
            reelRunData:setReelRunLen(preRunLen)
            reelRunData:setReelLongRun(false)
            reelRunData:setNextReelLongRun(false)

            -- 提取某一列所有内容， 一些老关在创建最终信号小块时会以此列表作为最终信号的判断条件
            local columnSlotsList = self.m_reelSlotsList[iCol]  
            -- 新的关卡父类可能没有这个变量
            if columnSlotsList then

                local curRunLen = reelRunData:getReelRunLen()
                local iRow = columnData.p_showGridCount
                -- 将 老的最终列表 依次放入 新的最终列表 对应索引处
                local maxIndex = runLen + iRow
                for checkRunIndex = maxIndex,1,-1 do
                    local checkData = columnSlotsList[checkRunIndex]
                    if checkData == nil then
                        break
                    end
                    columnSlotsList[checkRunIndex] = nil
                    columnSlotsList[curRunLen + iRow - (maxIndex - checkRunIndex)] = checkData
                end

            end
            
        end
    end
end
-- 需要关卡重写的方法
function CodeGameScreenKangaPocketsMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    -- 将下一步的逻辑包裹一下
    local nextFun = function()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end

    -- 判断本次spin的预告中奖标记
    if self.m_isPlayWinningNotice then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            nextFun()
            waitNode:removeFromParent()
        -- 预告中奖时间线长度
        end, 90/60)
    else
        nextFun()
    end
end

function CodeGameScreenKangaPocketsMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType

    if node.m_isLastSymbol == true and node.p_rowIndex <= self.m_iReelRowNum then
        if symbolType ==  self.SYMBOL_Bonus_Coins or symbolType ==  self.SYMBOL_Bonus_Free or symbolType ==  self.SYMBOL_Bonus_Pick then
            local bBonusCoins = symbolType ==  self.SYMBOL_Bonus_Coins
            -- 背景光
            -- node:getCcbProperty("sp_colorBg_1"):setVisible(false)
            node:getCcbProperty("sp_colorBg_2"):setVisible(false)
            node:getCcbProperty("sp_colorBg_3"):setVisible(false)
            -- 粒子
            -- node:getCcbProperty("Particle_1"):setVisible(false)
            node:getCcbProperty("Particle_2"):setVisible(false)
            node:getCcbProperty("Particle_3"):setVisible(false)
            --奖励节点
            node:getCcbProperty("Node_coins"):setVisible(false)
            node:getCcbProperty("Node_free"):setVisible(false)
            node:getCcbProperty("Node_pick"):setVisible(false)

            --打开金色背景光
            node:getCcbProperty("sp_colorBg_1"):setVisible(true)
            local particle_1 = node:getCcbProperty("Particle_1")
            particle_1:setPositionType(0)
            particle_1:setDuration(-1)
            particle_1:stopSystem()
            particle_1:resetSystem()
            particle_1:setVisible(true)
        end
    end

    --修改滚动图标层级
    local symbolOrder = self:getBounsScatterDataZorder(symbolType)
    local showOrder = symbolOrder
    if node.m_isLastSymbol == true and node.p_rowIndex <= self.m_iReelRowNum then
        showOrder = symbolOrder - node.p_rowIndex
    end
    node.p_showOrder = showOrder
    node.m_showOrder = showOrder
    node:setLocalZOrder(showOrder)
end
--
--单列滚动停止回调
--
function CodeGameScreenKangaPocketsMachine:slotOneReelDown(reelCol)    
    CodeGameScreenKangaPocketsMachine.super.slotOneReelDown(self,reelCol) 
   
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        if self.m_firstReelRunCol == 0 then
            self.m_firstReelRunCol = reelCol
            self:playScatterExpectAnim(reelCol)
        end
    end

    if reelCol == self.m_iReelColumnNum then
        self.m_firstReelRunCol = 0
        self:stopScatterExpectAnim()
    end
end
function CodeGameScreenKangaPocketsMachine:playScatterExpectAnim(_col, _row)
    local scatterParent = self:findChild("Node_scatterExpect")

    if not _row then
        for _iCol=1,_col-1 do
            for _iRow=1,self.m_iReelRowNum do
                local slotsNode = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
                if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and not slotsNode.m_playBuling then
                    local scatterSpine = util_spineCreate("Socre_KangaPockets_Scatter",true,true)
                    scatterParent:addChild(scatterSpine)
                    scatterSpine:setPosition(util_convertToNodeSpace(slotsNode, scatterParent))
                    util_spinePlay(scatterSpine, "idleframe3", true)
                end
            end
        end
    else
        local slotsNode = self:getFixSymbol(_col, _row, SYMBOL_NODE_TAG)
        local scatterSpine = util_spineCreate("Socre_KangaPockets_Scatter",true,true)
        scatterParent:addChild(scatterSpine)
        scatterSpine:setPosition(util_convertToNodeSpace(slotsNode, scatterParent))
        util_spinePlay(scatterSpine, "idleframe3", true)
    end
    
end
function CodeGameScreenKangaPocketsMachine:stopScatterExpectAnim()
    local scatterParent = self:findChild("Node_scatterExpect")
    scatterParent:removeAllChildren()
end
function CodeGameScreenKangaPocketsMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
function CodeGameScreenKangaPocketsMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if soundPath then
                    self:playBulingSymbolSounds(iCol, soundPath, nil)
                end
            end
        end
    end
end
function CodeGameScreenKangaPocketsMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        CodeGameScreenKangaPocketsMachine.super.playSymbolBulingAnim(self, slotNodeList, speedActionTable)
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            if self:checkSymbolBulingAnimPlay(_slotNode) then
                _slotNode.m_playBuling = true

                if _slotNode.p_cloumnIndex == self.m_iReelColumnNum then
                    self.m_lastReelPlayBuling = true
                end
            else
                -- local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
                -- -- 是否是最终信号
                -- if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --     if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                --         _slotNode:runAnim("idleframe2", true)
                --     end
                -- end
            end
        end
    end
    CodeGameScreenKangaPocketsMachine.super.playSymbolBulingAnim(self, slotNodeList, speedActionTable)
end
function CodeGameScreenKangaPocketsMachine:symbolBulingEndCallBack(_slotNode)
    _slotNode.m_playBuling = nil

    local symbolType = _slotNode.p_symbolType
    local iCol = _slotNode.p_cloumnIndex
    local iRow = _slotNode.p_rowIndex
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if 0 ~= self.m_firstReelRunCol then
            self:playScatterExpectAnim(iCol, iRow)
        end
        -- _slotNode:runAnim("idleframe2", true)
    end
end

--[[
    @desc: 计算每条应前线
    time:2020-07-21 20:48:31
    @return:
]]
function CodeGameScreenKangaPocketsMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenKangaPocketsMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end
---------------------------------------------------------------------------


--[[
    FreeSpin相关
]]
---
-- 显示free spin
function CodeGameScreenKangaPocketsMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    --!!!取消连线音效
    self:stopLinesWinSound()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    -- 触发free时如果不是sc触发的 sc不能播触发,且sc提前提层后，需要手动获取提层后的小块
    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            lineValue.iLineSymbolNum = #lineValue.vecValidMatrixSymPos
            table.remove(self.m_reelResultLines, i)
            break
        end
    end
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local parent = slotNode:getParent()
                    if parent ~= self.m_clipParent then
                        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                    end
                end
                
            end
        end
    end

    if scatterLineValue ~= nil then
        -- 播放提示时播放音效
        -- self:playScatterTipMusicEffect()
        --!!! 播放提示时播放音效
        local soundName = KangaPocketsPublicConfig.sound_KangaPockets_scatter_actionframe
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            soundName = KangaPocketsPublicConfig.sound_KangaPockets_scatter_actionframe_freeMore
        else
            -- 停掉背景音乐
            self:clearCurMusicBg()
        end
        gLobalSoundManager:playSound(soundName)
        --
        local delayTime = 0
        for i,_symPosData in ipairs(scatterLineValue.vecValidMatrixSymPos) do
            slotNode = self:getFixSymbol(_symPosData.iY, _symPosData.iX, SYMBOL_NODE_TAG)
            slotNode:runAnim("actionframe")
            local duration = slotNode:getAniamDurationByName("actionframe")
            delayTime = util_max(delayTime, duration)
        end
        self:levelPerformWithDelay(self, delayTime, function()
            self:showFreeSpinView(effectData)
        end)
    else
        local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusFree     = selfData.freeSpinIcons or {}
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            -- 停掉背景音乐
            self:clearCurMusicBg()
            gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_scatter_actionframe)
        else
        end
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenKangaPocketsMachine:playEffect_bonusOpenSymbol_freeSpinIcons(_fun)
    local selfData  = self.m_runSpinResultData.p_selfMakeData
    local bonusFree  = selfData.freeSpinIcons or {}

    if #bonusFree < 1 then
        _fun()
        return
    end

    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_collectBonusOver)
    self.m_kangaPocketsRole:playCollectBonusYuGaoAnim(function()
        gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_collectBonus)
        self.m_kangaPocketsRole:playCollectBonusSymbolStartAnim(_fun)
        -- 一起收集
        for i,_iconData in ipairs(bonusFree) do
            local slotsPos  = _iconData[1]
            local fixPos    = self:getRowAndColByPos(slotsPos)
            local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            self:playBonusSymbolCollectAnim(_iconData, function()
            end)
        end
    end)
end
function CodeGameScreenKangaPocketsMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_freeMoreView_auto)
            local freeMoreView = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                -- 次数栏反馈
                self.m_freeBar:playAddTimesAnim(function()
                    self:hideReelMask(function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                end)
            end,true)
            local spineParent = freeMoreView:findChild("Node_spine")
            local spineAnim   = util_spineCreate("KangaPockets_FreeSpinStart_2",true,true)
            spineParent:addChild(spineAnim)
            util_spinePlay(spineAnim, "start", false)
            util_spineEndCallFunc(spineAnim, "start", function()
                util_spinePlay(spineAnim, "idle", true)
            end)
        else
            self.m_kangaPocketsRole:playFreeStartLeaveAnim(function()
                self.m_kangaPocketsRole:setVisible(false)
                self.m_kangaPocketsRole:setPositionX(0)
                --切换展示
                self.m_freeBar:changeFreeSpinByCount()
                self.m_freeBar:setVisible(true)
                gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_freeStartView_start)
                local freeStartView = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_freeStartView_over)
                    self:changeReelBg("free", true)
                    self:levelPerformWithDelay(self, 21/60, function()
                        self.m_kangaPocketsRole:playFreeStartBackAnim(function()
                            self:hideReelMask(function()
                                self:triggerFreeSpinCallFun()
                                effectData.p_isPlay = true
                                self:playGameEffect()    
                            end)
                        end)
                        self.m_kangaPocketsRole:setVisible(true)
                    end)
                end)

                local spineParent = freeStartView:findChild("Node_spine")
                local spineAnim   = util_spineCreate("KangaPockets_FreeSpinStart_2",true,true)
                spineParent:addChild(spineAnim)
                util_spinePlay(spineAnim, "start", false)
                util_spineEndCallFunc(spineAnim, "start", function()
                    util_spinePlay(spineAnim, "idle", true)
                end)
            end)
        end
    end

    self:levelPerformWithDelay(self, 0.5, function()
        self:playEffect_bonusOpenSymbol_freeSpinIcons(function()
            showFSView()
        end)
    end)
end
function CodeGameScreenKangaPocketsMachine:showFreeSpinStart(_times, _fun, _isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = _times

    local freeStartView = util_createView("CodeKangaPocketsSrc.KangaPocketsFreeStartView")
    freeStartView:initViewData(self, freeStartView.DIALOG_TYPE_FREESPIN_START, _fun, freeStartView.AUTO_TYPE_NOMAL, nil)
    freeStartView:updateOwnerVar(ownerlist)

    gLobalViewManager:showUI(freeStartView)
    return freeStartView
end
function CodeGameScreenKangaPocketsMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        --!!! 只要存在金币bonus和多福多彩bonus就不算赢钱等待时间
        local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
        local creditIcons   = selfData.creditIcons or {}
        local bonusPos      = selfData.bonusPos or {}
        if #creditIcons + #bonusPos < 1 then
            delayTime = delayTime + self:getWinCoinTime()
        end
        --!!! 只要存在金币bonus和多福多彩bonus就不算赢钱等待时间

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenKangaPocketsMachine:isLastFreeSpin()
    local collectLeftCount  = globalData.slotRunData.freeSpinCount
    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
    local bLast = self.m_bProduceSlots_InFreeSpin and collectLeftCount ~= collectTotalCount and 0 == collectLeftCount
    return bLast 
end
function CodeGameScreenKangaPocketsMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_freeOverView_start)
    local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    local fsCount    = self.m_runSpinResultData.p_freeSpinsTotalCount
    local view = self:showFreeSpinOver( 
        util_formatCoins(fsWinCoins, 50), 
        fsCount,
        function()
            --切换展示
            self.m_freeBar:setVisible(false)
            self:changeReelBg("base", true)
            self:triggerFreeSpinOverCallFun()
        end
    )
    view:updateLabelSize({label=view:findChild("m_lb_coins"), sx=1,   sy=1},   764)
    view:updateLabelSize({label=view:findChild("m_lb_num"),   sx=0.8, sy=0.8}, 108)
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenKangaPocketsMachine:addSelfEffect()
    if self:isTriggerBonusBuling() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BonusBuling
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BonusBuling 
    end
    if self:isTriggerBonusOpenSymbol() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_Bonus_OpenBonusSymbol
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_Bonus_OpenBonusSymbol 
    end

    if self:isTriggerOpenFeatureSymbol() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_Bonus_OpenFeatureSymbol
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_Bonus_OpenFeatureSymbol 
    end
    
    if self:isTriggerBonusGame() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_Bonus_Pick
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_Bonus_Pick 
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenKangaPocketsMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_Bonus_OpenBonusSymbol then
        self:showReelMask(self.m_spinBonusCount, function()
            self:playEffect_openBonusSymbol(function()
                self:playCreditIconsCollectAnim(function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end)  
        end)  
    elseif effectData.p_selfEffectType == self.EFFECT_Bonus_Pick then
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_collectBonusOver)
        self.m_kangaPocketsRole:playCollectBonusYuGaoAnim(function()
            self:playEffect_collectBonusSymbol(function()
                self:playEffect_bonusGame(function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_Bonus_OpenFeatureSymbol then
        self:playEffect_bonusOpenSymbol_featureIcons(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BonusBuling then
        self:playEffect_BonusBuling(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    return true
end

function CodeGameScreenKangaPocketsMachine:showLineFrame()
    local lineWinCoins  = self:getClientWinCoins()
    self.m_iOnceSpinLastWin = lineWinCoins
    local bottomWinCoin = self:getnKangaPocketsCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + lineWinCoins)

    CodeGameScreenKangaPocketsMachine.super.showLineFrame(self)
end
function CodeGameScreenKangaPocketsMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    --!!!有金币bonus和多福多彩bonus时，连线事件不更新顶栏赢钱
    local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
    local creditIcons   = selfData.creditIcons or {}
    local bonusPos      = selfData.bonusPos or {}
    if #creditIcons + #bonusPos > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end
--[[
    棋盘加压暗，在滚出了>=6个Bonus时，开始FortuneCoin结算时要压暗棋盘，并将Bonus图标提层显示，结算完成时取消压暗，压暗需要渐隐渐现
]]
function CodeGameScreenKangaPocketsMachine:showReelMask(_symbolCount, _fun)
    local delayTime = 0
    if not self.m_stopLineFrame and self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
        delayTime = 1.1
    end

    if self.m_reelMask:isVisible() or _symbolCount < 6 then
        self:levelPerformWithDelay(self, delayTime, function()
            if 0 ~= delayTime then
                self.m_stopLineFrame = true
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()
            end
            _fun()
        end)
        return
    end
    -- sc取消提层
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        local symbolType = _slotsNode.p_symbolType
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local scParent = _slotsNode:getParent()
            if scParent == self.m_clipParent then
                _slotsNode:putBackToPreParent()
            end
        end
    end)

    self:levelPerformWithDelay(self, delayTime, function()
        if 0 ~= delayTime then
            self.m_stopLineFrame = true
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
        end
        -- darkstart
        self.m_reelMask:setOpacity(0)
        self.m_reelMask:setVisible(true)
        self.m_reelMask:runAction(cc.Sequence:create(
            cc.FadeTo:create(21/60, 255 * 0.8),
            cc.CallFunc:create(function()
                _fun()
            end)
        ))
    end)
end
function CodeGameScreenKangaPocketsMachine:hideReelMask(_fun)
    if not self.m_reelMask:isVisible() then
        if _fun then
            _fun()
        end
        return
    end
    -- darkover
    self.m_reelMask:runAction(cc.Sequence:create(
        cc.FadeOut:create(21/60),
        cc.CallFunc:create(function()
            self.m_reelMask:setVisible(false)
            if _fun then
                _fun()
            end
        end)
    ))
end


--[[
    在滚出了>=6个Bonus后，人物角色播放动画
]]
function CodeGameScreenKangaPocketsMachine:isTriggerBonusBuling()
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}
    local creditIcons = selfData.creditIcons or {}
    local bonusPos    = selfData.bonusPos or {}
    local bonusFree   = selfData.freeSpinIcons or {}
    local bonusCount  = #creditIcons + #bonusPos + #bonusFree
    return bonusCount >= 6
end
function CodeGameScreenKangaPocketsMachine:playEffect_BonusBuling(_fun)
    self.m_kangaPocketsRole:playBonusBulingAnim(_fun)
end

--[[
    打开bonus图标
]]
function CodeGameScreenKangaPocketsMachine:isTriggerBonusOpenSymbol()
    local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
    local creditIcons   = selfData.creditIcons or {}
    local bonusPos      = selfData.bonusPos or {}
    local bonusFree     = selfData.freeSpinIcons or {}
    self.m_spinBonusCount = #creditIcons + #bonusPos + #bonusFree

    local bonusSortList = self:getBonusSymbolSortList()
    return #bonusSortList > 0
end
function CodeGameScreenKangaPocketsMachine:getBonusSymbolSortList()
    local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
    local creditIcons   = selfData.creditIcons or {}
    local bonusPos      = selfData.bonusPos or {}
    local bonusFree     = selfData.freeSpinIcons or {}

    local sortList = {}
    for i,_iconData in ipairs(creditIcons) do
        table.insert(sortList, _iconData)
    end
    for i,_iPos in ipairs(bonusPos) do
        table.insert(sortList, {_iPos})
    end
    for i,_iconData in ipairs(bonusFree) do
        table.insert(sortList, _iconData)
    end
    table.sort(sortList, function(_dataA, _dataB)
        local fixPosA    = self:getRowAndColByPos(_dataA[1])
        local fixPosB    = self:getRowAndColByPos(_dataB[1])
        if fixPosA.iY ~= fixPosB.iY then
            return fixPosA.iY < fixPosB.iY
        end
        if fixPosA.iX ~= fixPosB.iX then
            return fixPosA.iX > fixPosB.iX
        end
        return false
    end)

    return sortList
end
function CodeGameScreenKangaPocketsMachine:playEffect_openBonusSymbol(_fun)
    self.m_openBonusSkip:setVisible(true)
    self.m_bottomUI:setSkipBonusBtnVisible(true)
    self.m_openBonusSkip:setSkipCallBack(function()
        gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_commonClick)
        
        self.m_openBonusSkip:stopAllActions()
        self.m_openBonusSkip:clearSkipCallBack()
        self.m_openBonusSkip:setVisible(false)
        self.m_bottomUI:setSkipBonusBtnVisible(false)
        -- 立即刷新所有bonus图标
        self:skipOpenBonusSymbolUpDateReel()
        _fun()
    end)

    local bonusSortList = self:getBonusSymbolSortList()
    -- 依次翻开所有金币
    local animTime = 60/60
    local interval = 0.5
    for i,_iconData in ipairs(bonusSortList) do
        local iconData  = _iconData
        local slotsPos  = iconData[1]
        local fixPos    = self:getRowAndColByPos(slotsPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local delayTime = (i - 1) * interval
        local bFeature  = slotsNode.p_symbolType ~= self.SYMBOL_Bonus_Coins
        performWithDelay(self.m_openBonusSkip,function()
            if bFeature then 
                gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_firstOpenFeatureBonus)
                slotsNode:runAnim("actionframe", false, nil)
                performWithDelay(slotsNode,function()
                    slotsNode:runAnim("idleframe_loop", true)
                end, animTime)
            else
                gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_openCoinBonus)
                self:playBonusSymbolOpenAnim(slotsNode, iconData, function()
                end)
            end
        end, delayTime)
    end
    -- 下一步
    local delayTime = (#bonusSortList-1) * interval + animTime
    performWithDelay(self.m_openBonusSkip, function()
        self.m_openBonusSkip:clearSkipCallBack()
        self.m_openBonusSkip:setVisible(false)
        self.m_bottomUI:setSkipBonusBtnVisible(false)
        _fun()
    end, delayTime)
end
--跳过首次翻开bonus流程后立刻刷新轮盘
function CodeGameScreenKangaPocketsMachine:skipOpenBonusSymbolUpDateReel()
    local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
    local creditIcons   = selfData.creditIcons or {}
    local bonusPos      = selfData.bonusPos or {}
    local bonusFree     = selfData.freeSpinIcons or {}

    local fnChangeBonusSymbol = function(_iconData)
        local slotsPos  = _iconData[1]
        local fixPos    = self:getRowAndColByPos(slotsPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local switchBg,switchParticle = self:upDateBonusSymbolShow(slotsNode, _iconData)

        slotsNode:getCcbProperty("sp_colorBg_1"):setVisible(true)
        local particle = slotsNode:getCcbProperty("Particle_1")
        particle:setPositionType(0)
        particle:setDuration(-1)
        particle:stopSystem()
        particle:resetSystem()
        particle:setVisible(true)

        if slotsNode.p_symbolType == self.SYMBOL_Bonus_Coins then
            slotsNode:runAnim("idleframe2", false)
        elseif slotsNode.p_symbolType == self.SYMBOL_Bonus_Free or slotsNode.p_symbolType == self.SYMBOL_Bonus_Pick then
            if "idleframe_loop" ~= slotsNode.m_currAnimName or true ~= slotsNode.m_slotAnimaLoop then
                slotsNode:runAnim("idleframe_loop", true)
            end
            slotsNode:getCcbProperty("Node_free"):setVisible(false)
            slotsNode:getCcbProperty("Node_pick"):setVisible(false)
        end
    end
    -- 三组bonus
    for i,_iconData in ipairs(creditIcons) do
        fnChangeBonusSymbol(_iconData)
    end
    for i,_slotsPos in ipairs(bonusPos) do
        local iconData  = {_slotsPos}
        fnChangeBonusSymbol(iconData)
    end
    for i,_iconData in ipairs(bonusFree) do
        fnChangeBonusSymbol(_iconData)
    end
end
function CodeGameScreenKangaPocketsMachine:playCreditIconsCollectAnim(_fun)
    local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
    local creditIcons   = selfData.creditIcons or {}
    local bonusPos      = selfData.bonusPos or {}
    local bonusFree     = selfData.freeSpinIcons or {}

    local winCoins = 0
    -- 金币上所有的钱数
    for i,_iconData in ipairs(creditIcons) do
        local multip   = tonumber(_iconData[2])
        local betValue = globalData.slotRunData:getCurTotalBet()
        local coins = betValue * multip
        winCoins = winCoins + coins
    end
    -- 金币Bonus大于0，多福多彩Bonus小于1，如果会触发大赢，应该在金币收到口袋里的一瞬间开始播大赢
    -- 暂时不要这个效果了，只注释判断条件，防止之后又改回来
    local bBonusCoinsBigWin = false
    -- if #bonusPos < 1 then 
    --     local spinWinCoins = self:getClientWinCoins() + winCoins
    --     bBonusCoinsBigWin = nil ~= self:getWinEffect(spinWinCoins)
    -- end
    -- 下一步
    local fnNext = function()
        if not self:isLastFreeSpin() and not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) and #bonusPos < 1 then
            self.m_iOnceSpinLastWin = winCoins
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{winCoins, self.EFFECT_Bonus_Pick})
            self:sortGameEffects()
        else
            local lineWinCoins  = self:getClientWinCoins()
            self.m_iOnceSpinLastWin = winCoins + lineWinCoins
        end

        local collectLeftCount  = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        if (not self.m_bProduceSlots_InFreeSpin or collectLeftCount == collectTotalCount) and #bonusPos < 1 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        end

        if bBonusCoinsBigWin then
            _fun()
            if #bonusPos < 1 and #bonusFree < 1 then
                self:hideReelMask()
            end
        elseif #bonusPos < 1 and #bonusFree < 1 then
            self:hideReelMask(_fun)
        else
            _fun()
        end
    end
    --底栏金币
    local bottomWinCoin = self:getnKangaPocketsCurBottomWinCoins()
    local lastWinCoin   = bottomWinCoin + winCoins
    self:setLastWinCoin(lastWinCoin)
    local lineWinCoins  = self:getClientWinCoins()
    local allWinCoins   = lineWinCoins + lastWinCoin
    -- 飞行动作
    for i,_iconData in ipairs(creditIcons) do
        local iconData  = _iconData
        local bJump = 1 == i
        self:playBonusSymbolCollectAnim(iconData, function()
            if bJump then
                --底栏金币 跳动时间<=1s直接修改变脸就行
                -- 超过1s,不为特殊大赢的收集回调内要等到金币跳动时间
                self.m_bottomUI.m_changeLabJumpTime = 0.8
                self:updateBottomUICoins(0, winCoins, nil, true, false)
                self.m_bottomUI.m_changeLabJumpTime = nil
            end
        end)
    end
    -- 是否有金币被收集
    if #creditIcons > 0 then
        gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_collectBonus)
        --飞行结束
        local flyTime       = 51/60
        self:levelPerformWithDelay(self, flyTime, function()
            --隐藏棋盘上金币bonus的背景光和粒子
            self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
                local symbolType = _slotsNode.p_symbolType
                if symbolType == self.SYMBOL_Bonus_Coins then
                    _slotsNode:getCcbProperty("sp_colorBg_1"):setVisible(false)
                    _slotsNode:getCcbProperty("Particle_1"):setVisible(false)
                    _slotsNode:getCcbProperty("Particle_1"):stopSystem()
                end
            end)
            -- 飞行结束直接触发下一步流程
            if bBonusCoinsBigWin then 
                fnNext()
            end
        end)
        -- 是否为特殊大赢
        if bBonusCoinsBigWin then 
            self.m_kangaPocketsRole:playCollectBonusSymbolStartAnim(nil)
        else
            -- 不为特殊大赢的收集
            self.m_kangaPocketsRole:playCollectBonusSymbolStartAnim(fnNext)
        end
    else
        fnNext()
    end
end

-- 按顺序翻开除了金币bonus以外的bonus图标
function CodeGameScreenKangaPocketsMachine:isTriggerOpenFeatureSymbol()
    local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusPos      = selfData.bonusPos or {}
    local bonusFree     = selfData.freeSpinIcons or {}

    return #bonusPos > 0 or #bonusFree > 0
end
function CodeGameScreenKangaPocketsMachine:playEffect_bonusOpenSymbol_featureIcons(_fun)
    local selfData   = self.m_runSpinResultData.p_selfMakeData
    local bonusCoins = selfData.creditIcons or {}
    local bonusPick  = selfData.bonusPos or {}
    local bonusFree  = selfData.freeSpinIcons or {}

    self:showReelMask(self.m_spinBonusCount, function()
        local maxPos = self.m_iReelColumnNum * self.m_iReelRowNum - 1
        local slotsPos  = 0
        local delayTime = 0
        local animTime  = 60/60
        while slotsPos <= maxPos  do
            -- 从上到下从左到右
            local fixPos    = self:getRowAndColByPos(slotsPos)
            local nextSlotsPos = slotsPos + 1
            if fixPos.iX > 1 then
                local nextRow = fixPos.iX - 1
                nextSlotsPos = (self.m_iReelRowNum - nextRow) * self.m_iReelColumnNum + fixPos.iY - 1
            elseif fixPos.iY < self.m_iReelColumnNum then
                local nextCol = fixPos.iY + 1
                local nextRow = self.m_iReelRowNum
                nextSlotsPos = (self.m_iReelRowNum - nextRow) * self.m_iReelColumnNum + nextCol - 1
            end
    
            local bOpen = false
            local iconData = {}
            -- 打开该位置的bonus图标
            if not bOpen then
                for i,_iPos in ipairs(bonusPick) do
                    iconData = {_iPos}
                    if slotsPos == iconData[1] then
                        bOpen = true
                        break
                    end
                end
            end
            if not bOpen then
                for i,_iconData in ipairs(bonusFree) do
                    iconData = _iconData
                    if slotsPos == iconData[1] then
                        bOpen = true
                        break
                    end
                end
            end
            if bOpen then
                local fixPos    = self:getRowAndColByPos(slotsPos)
                local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                self:levelPerformWithDelay(self, delayTime, function()
                    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_openFeatureBonus)
                    slotsNode:stopAllActions()
                    self:playBonusSymbolOpenAnim(slotsNode, iconData, function()
                    end)
                end)
                delayTime = delayTime + animTime
            end
            slotsPos = nextSlotsPos
        end
    
        local bonusCount      = #bonusPick + #bonusFree
        local nextFnDelayTime = bonusCount * animTime
        self:levelPerformWithDelay(self, nextFnDelayTime, function()
            _fun()
        end)
    end)
    
end

function CodeGameScreenKangaPocketsMachine:playBonusSymbolOpenAnim(_bonusSymbol, _iconData, _fun)
    local switchBg,switchParticle = self:upDateBonusSymbolShow(_bonusSymbol, _iconData)
    local symbolType   = _bonusSymbol.p_symbolType
    local openAnimName = symbolType == self.SYMBOL_Bonus_Coins and "actionframe2" or "actionframe3"
    _bonusSymbol:runAnim(openAnimName, false, _fun)
    self:levelPerformWithDelay(self, 9/60, function()
        if switchBg then
            _bonusSymbol:getCcbProperty("sp_colorBg_1"):setVisible(false)
            switchBg:setVisible(true)
        end
        if switchParticle then
            _bonusSymbol:getCcbProperty("Particle_1"):setVisible(false)
            _bonusSymbol:getCcbProperty("Particle_1"):stopSystem()

            switchParticle:setVisible(true)
            switchParticle:setPositionType(0)
            switchParticle:setDuration(-1)
            switchParticle:stopSystem()
            switchParticle:resetSystem()
        end
    end)
end

function CodeGameScreenKangaPocketsMachine:upDateBonusSymbolShow(_bonusSymbol, _iconData)
    --移除静态图
    _bonusSymbol:checkLoadCCbNode()
    if _bonusSymbol.p_symbolImage ~= nil and _bonusSymbol.p_symbolImage:getParent() ~= nil then
        _bonusSymbol.p_symbolImage:removeFromParent()
        _bonusSymbol.p_symbolImage = nil
    end
    --区分奖励
    local switchBg = nil
    local switchParticle = nil
    if _bonusSymbol.p_symbolType == self.SYMBOL_Bonus_Coins then
        local multip    = tonumber(_iconData[2])
        local betValue  = globalData.slotRunData:getCurTotalBet()
        local winCoins  = betValue * multip
        local labCoins1  = _bonusSymbol:getCcbProperty("m_lb_coins_1")
        local labCoins2  = _bonusSymbol:getCcbProperty("m_lb_coins_2")
        labCoins1:setVisible(false)
        labCoins2:setVisible(false)
        local labData  = {label=labCoins2,sx=1.2,sy=1.2,width=125}
        if multip >= 2.5 then
            labData  = {label=labCoins1,sx=1.1,sy=1.1,width=156}
        end
        labData.label:setString(util_formatCoins(winCoins, 3))
        self:updateLabelSize(labData, labData.width)
        labData.label:setVisible(true)
        _bonusSymbol:getCcbProperty("Node_coins"):setVisible(true)
    elseif _bonusSymbol.p_symbolType == self.SYMBOL_Bonus_Free then
        local freeTimes    = tonumber(_iconData[2])
        local labNum = _bonusSymbol:getCcbProperty("m_lb_num")
        labNum:setString(freeTimes)
        _bonusSymbol:getCcbProperty("Node_free"):setVisible(true)
        switchBg = _bonusSymbol:getCcbProperty("sp_colorBg_3")
        switchParticle = _bonusSymbol:getCcbProperty("Particle_3")
    elseif _bonusSymbol.p_symbolType == self.SYMBOL_Bonus_Pick then
        _bonusSymbol:getCcbProperty("Node_pick"):setVisible(true)
        switchBg = _bonusSymbol:getCcbProperty("sp_colorBg_2")
        switchParticle = _bonusSymbol:getCcbProperty("Particle_2")
    end
    return switchBg,switchParticle
end
function CodeGameScreenKangaPocketsMachine:upDateBonusCsbShow(_bonusCsb, _symbolType,_iconData)
    --区分奖励
    local switchBg = nil
    local switchParticle = nil
    if _symbolType == self.SYMBOL_Bonus_Coins then
        local multip    = tonumber(_iconData[2])
        local betValue  = globalData.slotRunData:getCurTotalBet()
        local winCoins  = betValue * multip
        local labCoins1  = _bonusCsb:findChild("m_lb_coins_1")
        local labCoins2  = _bonusCsb:findChild("m_lb_coins_2")
        labCoins1:setVisible(false)
        labCoins2:setVisible(false)
        local labData  = {label=labCoins2,sx=1.2,sy=1.2,width=125}
        if multip >= 2.5 then
            labData  = {label=labCoins1,sx=1.1,sy=1.1,width=156}
        end
        labData.label:setString(util_formatCoins(winCoins, 3))
        self:updateLabelSize(labData, labData.width)
        labData.label:setVisible(true)
        _bonusCsb:findChild("Node_coins"):setVisible(true)
    elseif _symbolType == self.SYMBOL_Bonus_Free then
        local freeTimes    = tonumber(_iconData[2])
        local labNum = _bonusCsb:findChild("m_lb_num")
        labNum:setString(freeTimes)
        _bonusCsb:findChild("Node_free"):setVisible(true)
        switchBg = _bonusCsb:findChild("sp_colorBg_3")
        switchParticle = _bonusCsb:findChild("Particle_3")
    elseif _symbolType == self.SYMBOL_Bonus_Pick then
        _bonusCsb:findChild("Node_pick"):setVisible(true)
        switchBg = _bonusCsb:findChild("sp_colorBg_2")
        switchParticle = _bonusCsb:findChild("Particle_2")
    end
    return switchBg,switchParticle
end

function CodeGameScreenKangaPocketsMachine:playBonusSymbolCollectAnim(_iconData, _fun)
    local iPos      = _iconData[1]

    local fixPos    = self:getRowAndColByPos(iPos)
    local slotsNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
    local flyTime  = 30/60
    local startPos = util_convertToNodeSpace(slotsNode, self)
    local endPos   = util_convertToNodeSpace(self:findChild("Node_collect"), self)
    
    -- 飞行节点
    local flyNode = util_createAnimation("Socre_KangaPockets_Bonus.csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    flyNode:setVisible(false)
    flyNode:setScale(self.m_machineRootScale)
    local startPos = util_convertToNodeSpace(slotsNode, self)
    flyNode:setPosition(startPos)
    --奖励节点
    local switchBg,switchParticle = self:upDateBonusCsbShow(flyNode, slotsNode.p_symbolType,_iconData)
    -- 附加粒子
    local particleCsb = util_createAnimation("Socre_KangaPockets_Bonus_lizi.csb")
    flyNode:findChild("Node_lizi"):addChild(particleCsb)
    local particle1 = particleCsb:findChild("particle_1")
    particle1:setPositionType(0)
    -- 飞行动作
    local distance    = math.sqrt((endPos.x - startPos.x) * (endPos.x - startPos.x) + (endPos.y - startPos.y) * (endPos.y - startPos.y))
    local radius      = distance/2
    local flyAngle    = util_getAngleByPos(startPos, endPos)
    local offsetAngle = endPos.x > startPos.x and 90 or -90
    local pos1 = cc.p( util_getCirclePointPos(startPos.x, startPos.y, radius, flyAngle + offsetAngle) )
    local pos2 = cc.p( util_getCirclePointPos(endPos.x, endPos.y, radius/2, flyAngle + offsetAngle) )
    flyNode:runCsbAction("fly", false)
    flyNode:setVisible(true)
    flyNode:runAction(cc.Sequence:create(
        cc.DelayTime:create(21/60),
        cc.BezierTo:create(flyTime, {pos1, pos2, endPos}),
        cc.CallFunc:create(function()
            _fun()
            flyNode:findChild("root"):setVisible(false)

            particle1:stopSystem()
            util_setCascadeOpacityEnabledRescursion(particle1, true)
            particle1:runAction(cc.FadeOut:create(0.5))
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
end

function CodeGameScreenKangaPocketsMachine:beginReelStopAllBonusParticle()
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        local symbolType = _slotsNode.p_symbolType
        if symbolType == self.SYMBOL_Bonus_Coins or symbolType == self.SYMBOL_Bonus_Pick or symbolType == self.SYMBOL_Bonus_Free then
            local particle_1 = _slotsNode:getCcbProperty("Particle_1")
            local particle_2 = _slotsNode:getCcbProperty("Particle_2")
            local particle_3 = _slotsNode:getCcbProperty("Particle_3")
            if particle_1 then
                particle_1:setVisible(false)
                particle_1:stopSystem()
            end
            if particle_2 then
                particle_2:setVisible(false)
                particle_2:stopSystem()
            end
            if particle_3 then
                particle_3:setVisible(false)
                particle_3:stopSystem()
            end
        end
    end)
end
-- 多福多彩玩法
function CodeGameScreenKangaPocketsMachine:isTriggerBonusGame()
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotData = selfData.jackpot
    if nil ~= jackpotData then
        return true
    end

    return false
end
function CodeGameScreenKangaPocketsMachine:playEffect_collectBonusSymbol(_fun)
    local selfData    = self.m_runSpinResultData.p_selfMakeData
    local bonusPick  = selfData.bonusPos or {}
    local bonusFree  = selfData.freeSpinIcons or {}

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_collectPickBonus)
    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_collectBonus)

    self.m_kangaPocketsRole:playCollectBonusSymbolStartAnim(_fun)
    for i,_bonusPos in ipairs(bonusPick) do
        local iconData = {_bonusPos}
        local slotsPos  = iconData[1]
        local fixPos    = self:getRowAndColByPos(slotsPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        self:playBonusSymbolCollectAnim(iconData, function()
        end)  
    end
end
function CodeGameScreenKangaPocketsMachine:playEffect_bonusGame(_fun)
    local selfData  = self.m_runSpinResultData.p_selfMakeData
    local creditIcons   = selfData.creditIcons or {}
    local bonusPick  = selfData.bonusPos or {}
    local bonusFree  = selfData.freeSpinIcons or {}

    local jackpot   = selfData.jackpot
    local bonusData = {} 
    bonusData.index = 1
    bonusData.process = clone(jackpot.process)
    bonusData.extraProcess = clone(jackpot.extraProcess)
    bonusData.jackpotBoost = clone(jackpot.jackpotBoost)
    bonusData.jackpotList  = {}
    local winCoins = 0
    if nil ~= jackpot.jackpotWinAmount then
        local jpList = {
            {4, self.JackpotName.Mini},
            {3, self.JackpotName.Minor},
            {2, self.JackpotName.Major},
            {1, self.JackpotName.Grand},
        }
        for _index,_jpData in ipairs(jpList) do
            local coins = jackpot.jackpotWinAmount[_jpData[2]] 
            if nil ~= coins then
                winCoins    = winCoins + coins
                table.insert(bonusData.jackpotList, {name = _jpData[2], index = _jpData[1], coins = coins})
            end
            
        end
    end
    local betValue = globalData.slotRunData:getCurTotalBet()
    for i,_iconData in ipairs(creditIcons) do
        local iconData = _iconData
        local multip   = tonumber(iconData[2])
        local coins    = betValue * multip
        winCoins = winCoins + coins
    end

    -- -- 停止播放背景音乐
    -- self:clearCurMusicBg()
    -- 两层过场一起播
    util_spinePlay(self.m_bonusBgSpine, "actionframe_guochang2", false)
    util_spineEndCallFunc(self.m_bonusBgSpine, "actionframe_guochang2", function()
        util_spinePlay(self.m_bonusBgSpine, "idleframe", true)
    end)

    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGame_guoChang)
    self:playBonusGuoChangAnim("actionframe_guochang",
        function()
            --切换展示
            self:changeReelBg("bonus", true)
            self.m_bonusGame:resetUi()
            self.m_bonusGame:setVisible(true)
            if #bonusFree < 1 then
                self.m_reelMask:setVisible(false)
            end
        end,
        function()
            -- 隐藏玩法bonus图标的背景光和粒子
            for i,_bonusPos in ipairs(bonusPick) do
                local fixPos    = self:getRowAndColByPos(_bonusPos)
                local bonusSymbol =  self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                --目前断线重连不会，触发多福多彩，这两步加载CCB没用，防止之后改为可以断线重连先加上吧
                bonusSymbol:checkLoadCCbNode()
                if bonusSymbol.p_symbolImage ~= nil and bonusSymbol.p_symbolImage:getParent() ~= nil then
                    bonusSymbol.p_symbolImage:removeFromParent()
                    bonusSymbol.p_symbolImage = nil
                end
                local particle_2 = bonusSymbol:getCcbProperty("Particle_2")
                particle_2:setVisible(false)
                particle_2:stopSystem()
                bonusSymbol:getCcbProperty("sp_colorBg_2"):setVisible(false)
            end
            -- 重置背景音乐
            self:resetMusicBg(nil, KangaPocketsPublicConfig.music_KangaPockets_bonus)
            self:setMaxMusicBGVolume()
            self.m_bonusGame:startGame(bonusData, function()
                self:showJackpotView(1, bonusData.jackpotList, function()
                    local collectLeftCount  = globalData.slotRunData.freeSpinCount
                    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
                    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_bonusGameOver_guoChang)
                    self:playBonusGuoChangAnim("actionframe_guochang", 
                        function()
                            --切换展示
                            local model = "base"
                            if self.m_bProduceSlots_InFreeSpin and collectLeftCount ~= collectTotalCount then
                                model = "free"
                            end
                            self:changeReelBg(model, false)
                            self.m_bonusGame:setVisible(false)
                        end,
                        function()
                            if not self:isLastFreeSpin() and not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{winCoins, self.EFFECT_Bonus_Pick})
                                self:sortGameEffects()
                            else
                                local lineWinCoins  = self:getClientWinCoins()
                                self.m_iOnceSpinLastWin = winCoins + lineWinCoins
                            end
                            local musicName = KangaPocketsPublicConfig.music_KangaPockets_base
                            if self.m_bProduceSlots_InFreeSpin and collectLeftCount ~= collectTotalCount then
                                musicName = KangaPocketsPublicConfig.music_KangaPockets_free
                            end
                            self:resetMusicBg(nil, musicName)
                            if not self.m_bProduceSlots_InFreeSpin or collectLeftCount == collectTotalCount  then
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                            end
                            _fun()
                        end
                    )
                end)
            end)
        end
    )
end
-- 展示jackpot弹板
function CodeGameScreenKangaPocketsMachine:showJackpotView(_index, _list, _fun)
    local jackpotData = _list[_index]
    if not jackpotData then
        _fun()
        return
    end
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(jackpotData.coins, jackpotData.index)
    local jackPotWinView = util_createView("CodeKangaPocketsSrc.KangaPocketsJackPotView", jackpotData)
    jackPotWinView:setBtnClickFunc(function()
        self.m_bonusGame.m_jackpotBar:stopProgressFinishAnim(jackpotData.index)
    end)
    jackPotWinView:setOverAniRunFunc(function()
        self:showJackpotView(_index+1, _list, _fun)
    end)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self)
    jackPotWinView:findChild("root"):setScale(self.m_machineRootScale * 0.9)
    -- 刷新底栏
    local bottomWinCoin = self:getnKangaPocketsCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + jackpotData.coins)
    self:updateBottomUICoins(0, jackpotData.coins, nil, true, false)
    --
    local sounsList = {
        [1] = KangaPocketsPublicConfig.sound_KangaPockets_jackpotView_grand,
        [2] = KangaPocketsPublicConfig.sound_KangaPockets_jackpotView_major,
        [3] = KangaPocketsPublicConfig.sound_KangaPockets_jackpotView_minor,
        [4] = KangaPocketsPublicConfig.sound_KangaPockets_jackpotView_mini,
    }
    local soundName = sounsList[jackpotData.index]
    gLobalSoundManager:playSound(soundName)
end
-- @_fun1:切换展示 @_fun2:过场结束
function CodeGameScreenKangaPocketsMachine:playBonusGuoChangAnim(_animName, _fun1, _fun2)
    self.m_bonusGuoChangSpine:setVisible(true)
    util_spinePlay(self.m_bonusGuoChangSpine, _animName, false)

    self:levelPerformWithDelay(self, 51/30, function()
        _fun1()
    end)
    self:levelPerformWithDelay(self, 102/30, function()
        self.m_bonusGuoChangSpine:setVisible(false)
        _fun2()
    end)
end

-- 重写此函数 一点要调用 BaseMachine.reelDownNotifyPlayGameEffect(self) 而不是 self:playGameEffect()
function CodeGameScreenKangaPocketsMachine:reelDownNotifyPlayGameEffect()
    --策划要求:只要第五列出buling,事件进行一律等待0.5s保证落地动画播放完毕
    local delayTime = self.m_lastReelPlayBuling and 0.5 or 0
    self:levelPerformWithDelay(self, delayTime, function()
        self:playGameEffect()
    end)
end
function CodeGameScreenKangaPocketsMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    CodeGameScreenKangaPocketsMachine.super.slotReelDown(self)
end

function CodeGameScreenKangaPocketsMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end


--[[
    一些工具
]]
-- 循环处理轮盘小块
function CodeGameScreenKangaPocketsMachine:baseReelSlotsNodeForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if isJumpFun then
                return
            end
        end
    end
end
-- 延时
function CodeGameScreenKangaPocketsMachine:levelPerformWithDelay(_parent, _time, _fun)
    if _time <= 0 then
        _fun()
        return
    end

    local waitNode = cc.Node:create()
    _parent:addChild(waitNode)
    performWithDelay(waitNode,function()
        _fun()
        waitNode:removeFromParent()
    end, _time)

    return waitNode
end
--获取底栏金币
function CodeGameScreenKangaPocketsMachine:getnKangaPocketsCurBottomWinCoins()
    local winCoin = 0

    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
        if "" == sCoins then
            return winCoin
        end
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end
--更新底栏金币
function CodeGameScreenKangaPocketsMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end
-- 循环处理轮盘小块
function CodeGameScreenKangaPocketsMachine:baseReelSlotsNodeForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if isJumpFun then
                return
            end
        end
    end
end

--[[
    底层重写
]]
-- function CodeGameScreenKangaPocketsMachine:showEffect_NewWin(effectData, winType)
--     CodeGameScreenKangaPocketsMachine.super.showEffect_NewWin(self, effectData, winType)
    
--     -- 大赢时只存在金币bonus
--     local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
--     local creditIcons   = selfData.creditIcons or {}
--     local bonusPos      = selfData.bonusPos or {}
--     local bonusFree     = selfData.freeSpinIcons or {}
--     if #creditIcons <= 0 or #bonusPos > 0 then
--         --播放人物spine动画
--         self.m_kangaPocketsRole:playBigWinAnim()
--     end
-- end

function CodeGameScreenKangaPocketsMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local cfgReelHeight = self:getReelHeight()
    local cfgReelWidth  = self:getReelWidth()
    local hScale = mainHeight / cfgReelHeight
    local wScale = winSize.width / cfgReelWidth
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        --1.78
        if display.width / display.height >= 1370/768 then
        --1.59
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 0.96
            self.m_bonusGameScale = 1.05
        --1.5
        elseif display.width / display.height >= 960/640 then
            mainScale = mainScale * 0.92
            self.m_bonusGameScale = 1.1
        --1.33
        elseif display.width / display.height >= 1024/768 then
            mainScale = mainScale * 0.92
            self.m_bonusGameScale = 1.1
        end

        mainScale = math.min(1, mainScale)
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

return CodeGameScreenKangaPocketsMachine
