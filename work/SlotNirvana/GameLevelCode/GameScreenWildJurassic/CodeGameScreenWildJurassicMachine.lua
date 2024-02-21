---
-- island li
-- 2019年1月26日
-- CodeGameScreenWildJurassicMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "WildJurassicPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenWildJurassicMachine = class("CodeGameScreenWildJurassicMachine", BaseSlotoManiaMachine)

CodeGameScreenWildJurassicMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWildJurassicMachine.SYMBOL_BIG_WILD= TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2   -- 自定义的小块类型
CodeGameScreenWildJurassicMachine.WILD_CHANGE_BIGWILD = GameEffect.EFFECT_SELF_EFFECT - 1 -- 连续4个小wild 合成一个大wild
CodeGameScreenWildJurassicMachine.WILD_CHANGE_BIGWILD_OLD = GameEffect.EFFECT_SELF_EFFECT - 2 -- wildrespin 玩法存在旧的锁定列

-- 构造函数
function CodeGameScreenWildJurassicMachine:ctor()
    CodeGameScreenWildJurassicMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_lightScore = 0
    self.m_isQuicklyStop = false --是否点击快停
    self.m_bigWildNodeList = {} --存储大wild
    self.m_isTriggerLongRunCol = 6 --触发快滚的时候 用来判断的标识
    self.m_isPlayShake = false
    self.m_firstReelRunCol = 0 -- 本次spin首个快滚的列
    self.m_isPlayWildBulingSoundIndex = 1
    self.m_isPlayChangeBigWildSound = true
    self.m_isPlayWildLinesSound = true -- 判断播放wild连线音效 值播放一次
    self.m_isPlayWildRespinSoundIndex = 1

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

	--init
	self:initGame()
end

function CodeGameScreenWildJurassicMachine:initGame()
	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWildJurassicMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WildJurassic"  
end

function CodeGameScreenWildJurassicMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- wildrespin 开始弹板
    self.m_wildRespin = util_spineCreate("ReSpinStart", true, true)
    self:findChild("Node_respin"):addChild(self.m_wildRespin)
    self.m_wildRespin:setVisible(false)

    -- free过场动画
    self.m_guochangFreeEffect1 = util_spineCreate("Socre_WildJurassic_Wild2",true,true)
    self:findChild("Node_guochang"):addChild(self.m_guochangFreeEffect1, 10)
    self.m_guochangFreeEffect1:setVisible(false)

    self.m_guochangFreeEffect2 = util_spineCreate("Socre_WildJurassic_Wild3",true,true)
    self:findChild("Node_guochang1"):addChild(self.m_guochangFreeEffect2, 10)
    self.m_guochangFreeEffect2:setVisible(false)

    -- 大赢动画
    self.m_bigwinEffect = util_spineCreate("WildJurassic_DY", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigwinEffect)
    self.m_bigwinEffect:setVisible(false)

    -- 主界面提示
    self.m_midNode = util_createAnimation("WildJurassic_mid.csb")
    self:findChild("Node_mid"):addChild(self.m_midNode)
    self.m_midNode:runCsbAction("idle", true)
    self:setMidScale()
    
    self:setReelBg(1)
end

--[[
    调整主界面提醒node 大小
]]
function CodeGameScreenWildJurassicMachine:setMidScale( )
    local ratio = display.height/display.width
    if ratio > 768/1370 then
        self.m_midNode:setScale(1)
    else
        self.m_midNode:setScale(0.74)
        self.m_midNode:setPositionY(-10)
    end
end

function CodeGameScreenWildJurassicMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    -- base背景 spine
    local baseBg = util_spineCreate("GameScreenWildJurassicBg1", true, true)
    gameBg:findChild("Base"):addChild(baseBg) 
    util_spinePlay(baseBg,"idleframe",true)

    -- free背景 spine
    local freeBg = util_spineCreate("GameScreenWildJurassicBg2", true, true)
    gameBg:findChild("FG"):addChild(freeBg) 
    util_spinePlay(freeBg,"idleframe",true)

    self.m_gameBg = gameBg
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2free
]]
function CodeGameScreenWildJurassicMachine:setReelBg(_BgIndex)
    if _BgIndex == 1 then
        self:findChild("Reel_base"):setVisible(true)
        self:findChild("Reel_FG"):setVisible(false)

        self.m_gameBg:findChild("Base"):setVisible(true)
        self.m_gameBg:findChild("FG"):setVisible(false)
    elseif _BgIndex == 2 then
        self:findChild("Reel_base"):setVisible(false)
        self:findChild("Reel_FG"):setVisible(true)

        self.m_gameBg:findChild("Base"):setVisible(false)
        self.m_gameBg:findChild("FG"):setVisible(true)
    end
end

--[[
    创建free 计数条
]]
function CodeGameScreenWildJurassicMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("FGbar")
        self.m_baseFreeSpinBar = util_createView("CodeWildJurassicSrc.WildJurassicFreespinBarView", {machine = self})
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
    end
end

function CodeGameScreenWildJurassicMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_midNode:setVisible(false)
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:runCsbAction("start",false)
end

function CodeGameScreenWildJurassicMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end

    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:runCsbAction("over",false,function()
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
        self.m_midNode:setVisible(true)
    end)
end

function CodeGameScreenWildJurassicMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_enterGame)
    end,0.4,self:getModuleName())
end

function CodeGameScreenWildJurassicMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWildJurassicMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenWildJurassicMachine:addObservers()
    CodeGameScreenWildJurassicMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

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

        local soundName = nil
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_WildJurassic_freeLineFrame_"..soundIndex] 
        else
            soundName = self.m_publicConfig.SoundConfig["sound_WildJurassic_baseLineFrame_"..soundIndex] 
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenWildJurassicMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWildJurassicMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWildJurassicMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BIG_WILD  then
        return "Socre_WildJurassic_Wild2"
    end

    return nil
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
]]
function CodeGameScreenWildJurassicMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "WildJurassicSounds/sound_WildJurassic_scatter_buling.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWildJurassicMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenWildJurassicMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BIG_WILD,count = 2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------
-- 断线重连 
function CodeGameScreenWildJurassicMachine:MachineRule_initGame(  )

    if self.m_bProduceSlots_InFreeSpin then
        self:setReelBg(2)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
end

--[[
    进入关卡 处理一下断线respin
]]
function CodeGameScreenWildJurassicMachine:enterLevel( )
    CodeGameScreenWildJurassicMachine.super.enterLevel(self)

    self:enterLevelByWildRespin()
end

--[[
    重新进入关卡的时候 处理wildrespin
]]
function CodeGameScreenWildJurassicMachine:enterLevelByWildRespin( )
    -- 断线重连 处理一下respin玩法
    if self.m_runSpinResultData and self.m_runSpinResultData.p_reSpinCurCount then
        local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
        if reSpinCurCount > 0 then
            -- 处理大信号信息
            if self.m_hasBigSymbol == true then
                self.m_bigSymbolColumnInfo = {}
            else
                self.m_bigSymbolColumnInfo = nil
            end

            -- wildrespin 玩法 进入关卡的时候 小块变成长条
            local selfData = self.m_runSpinResultData.p_selfMakeData
            if selfData and selfData.mergeWildColOld and #selfData.mergeWildColOld > 0 then
                for indexCol = 1, #selfData.mergeWildColOld do
                    local wildChangeColOld = selfData.mergeWildColOld[indexCol] + 1
                    local targSp = self:getFixSymbol(wildChangeColOld, 1, SYMBOL_NODE_TAG)
                    -- 创建一个固定的长条
                    self:createBigWildByReel(targSp, wildChangeColOld)

                    -- wildrespin 玩法旧的长条覆盖住的小块 变成长条 用于显示连线
                    self:changeBigWildByReel(wildChangeColOld)
                end
            end

            if selfData and selfData.mergeWildCol and #selfData.mergeWildCol > 0 then
                for indexCol = 1, #selfData.mergeWildCol do
                    local wildChangeCol = selfData.mergeWildCol[indexCol] + 1
                    local targSp = self:getFixSymbol(wildChangeCol, 1, SYMBOL_NODE_TAG)
                    -- 创建一个固定的长条
                    self:createBigWildByReel(targSp, wildChangeCol)
        
                    -- wildrespin 玩法旧的长条覆盖住的小块 变成长条 用于显示连线
                    self:changeBigWildByReel(wildChangeCol)
                end
            end
        end
    end
end
--
--单列滚动停止回调
--
function CodeGameScreenWildJurassicMachine:slotOneReelDown(reelCol)    
    CodeGameScreenWildJurassicMachine.super.slotOneReelDown(self,reelCol) 
   
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        if self.m_firstReelRunCol == 0 then
            self.m_firstReelRunCol = reelCol

        end
    end
    if reelCol == self.m_iReelColumnNum then
        if 0 ~= self.m_firstReelRunCol then
            if not self.m_isQuicklyStop then
                self:stopcatterExpectAnim()
            end
            self.m_firstReelRunCol = 0
        end
    end
end

function CodeGameScreenWildJurassicMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    
    local isPlayWildBulingSound = true
    -- 出现连续4个wild 需要播放落地动画
    local selfData = self.m_runSpinResultData.p_selfMakeData
    for k, _slotNode in pairs(slotNodeList) do
        local curCol = _slotNode.p_cloumnIndex
        if selfData and selfData.mergeWildCol and #selfData.mergeWildCol > 0 then
            for indexCol = 1, #selfData.mergeWildCol do
                local wildChangeCol = selfData.mergeWildCol[indexCol] + 1
                if curCol == wildChangeCol then
                    if _slotNode then
                        _slotNode:runAnim("buling", false, function()
                        end)

                        if isPlayWildBulingSound then
                            isPlayWildBulingSound = false
                            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_WildJurassic_wild_buling_"..self.m_isPlayWildBulingSoundIndex])
                            self.m_isPlayWildBulingSoundIndex = self.m_isPlayWildBulingSoundIndex + 1
                            if self.m_isPlayWildBulingSoundIndex > 4 then
                                self.m_isPlayWildBulingSoundIndex = 1
                            end
                        end
                    end
                end
            end
        end
    end

    CodeGameScreenWildJurassicMachine.super.playSymbolBulingAnim(self, slotNodeList, speedActionTable)
end

function CodeGameScreenWildJurassicMachine:symbolBulingEndCallBack(_slotNode)
    local symbolType = _slotNode.p_symbolType
    local bScatter = symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER

    if bScatter then
        self:playSymbolIdleLoopAnim(_slotNode)
    end
    --期待动画
    if bScatter then 
        if 0 ~= self.m_firstReelRunCol then
            local iCol = _slotNode.p_cloumnIndex
            local iRow = _slotNode.p_rowIndex
            if iCol == self.m_firstReelRunCol then
                self:playScatterExpectAnim(iCol, nil)
            elseif iCol > self.m_firstReelRunCol then
                self:playScatterExpectAnim(iCol, iRow)
            end
        end
    end
end

--期待动画 播放/停止
function CodeGameScreenWildJurassicMachine:playScatterExpectAnim(_iCol, _iRow)
    local animName = "idleframe3"
    if not _iRow then
        for iCol=1,_iCol do
            for iRow=1,self.m_iReelRowNum do
                local slotsNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotsNode and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then 
                    slotsNode:runAnim(animName, true)
                end
            end
        end
    else
        local slotsNode = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
        if slotsNode and slotsNode.p_symbolType then
            slotsNode:runAnim(animName, true)
        end
    end 
end

function CodeGameScreenWildJurassicMachine:stopcatterExpectAnim()
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local slotsNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotsNode and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then 
                self:playSymbolIdleLoopAnim(slotsNode)
            end
        end
    end
end

function CodeGameScreenWildJurassicMachine:playSymbolIdleLoopAnim(_slotNode)
    _slotNode:runAnim("idleframe2", true)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWildJurassicMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWildJurassicMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

----------- FreeSpin相关
---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenWildJurassicMachine:showBonusAndScatterLineTip(lineValue, callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=symPosData.iX})
        if slotNode == nil then
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX)
        end

        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]
                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=bigSymbolInfo.startRowIndex})
                        break
                    end
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

-- FreeSpinstart
function CodeGameScreenWildJurassicMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_freeMore_start)

            self:showFreeSpinMoreAutoNomal( self.m_runSpinResultData.p_freeSpinNewCount,function()
                self.m_baseFreeSpinBar:playAddNumsEffect()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:playGuoChangFree(function()

                    self:setReelBg(2)
                    self:triggerFreeSpinCallFun()
                end, function()
                    effectData.p_isPlay = true
                    self:playGameEffect()  
                end, true)     
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.3)

end

-- 显示free spin
function CodeGameScreenWildJurassicMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self:stopLinesWinSound()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    
    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            self:playScatterTipMusicEffect()
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_scatter_trigger_free)
        end
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

---------------------------------弹版----------------------------------
function CodeGameScreenWildJurassicMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local view = nil

    if isAuto then
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_WildJurassic_click
    view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_WildJurassic_free_start_xiaoshi
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_free_start_chuxian)

    return view

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenWildJurassicMachine:showFreeSpinOverView()
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:playGuoChangFree(function()
                self:triggerFreeSpinOverCallFun()
                self:setReelBg(1)
            end, function()

            end, false)
    end)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_WildJurassic_click
    view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_WildJurassic_free_over_xiaoshi
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_free_over_chuxian)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.88,sy=1},847)
end

-- free过场动画
function CodeGameScreenWildJurassicMachine:playGuoChangFree(_func1, _func2, _isStart)

    if _isStart then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_guochang_baseToFree)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_guochang_freeToBase)
    end

    self.m_guochangFreeEffect1:setVisible(true)
    self.m_guochangFreeEffect2:setVisible(true)
    util_spinePlay(self.m_guochangFreeEffect1, "guochang", false)
    util_spinePlay(self.m_guochangFreeEffect2, "guochang", false)

    -- 第10帧 切掉棋盘
    self:waitWithDelay(10/30,function()
        self:findChild("root1"):setVisible(false)
        if self.m_baseFreeSpinBar:isVisible() then
            self.m_baseFreeSpinBar:setVisible(false)
        end
    end)

    -- 第56帧 显示棋盘 切换背景
    self:waitWithDelay(56/30,function()
        --修改恐龙层级 到棋盘之上
        util_changeNodeParent(self:findChild("Node_guochang1"), self.m_guochangFreeEffect1)
        self:findChild("root1"):setVisible(true)
        if _func1 then
            _func1()
        end
    end)

    -- 第66帧 过场结束
    self:waitWithDelay(66/30,function()
        self.m_guochangFreeEffect1:setVisible(false)
        self.m_guochangFreeEffect2:setVisible(false)
        --恢复恐龙层级
        util_changeNodeParent(self:findChild("Node_guochang"), self.m_guochangFreeEffect1)
        if _func2 then
            _func2()
        end
    end)
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenWildJurassicMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("CodeWildJurassicSrc.WildJurassicDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end

    -- if self.m_root then
    --     self.m_root:addChild(view,999999)
    --     local wordPos=view:getParent():convertToWorldSpace(cc.p(view:getPosition()))
    --     local curPos=self.m_root:convertToNodeSpace(wordPos)
    --     view:setPosition(cc.pSub(cc.p(0,0),wordPos))
    -- else
    gLobalViewManager:showUI(view)
    -- end

    return view
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWildJurassicMachine:MachineRule_SpinBtnCall()
    self.m_firstReelRunCol = 0

    self:setMaxMusicBGVolume()
   
    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenWildJurassicMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenWildJurassicMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWildJurassicMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 出现连续4个小wild 需要合成一个大wild的时候
    if selfData and selfData.mergeWildCol and #selfData.mergeWildCol > 0 then
        self.m_mergeWildCol = selfData.mergeWildCol
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.WILD_CHANGE_BIGWILD
        selfEffect.p_selfEffectType = self.WILD_CHANGE_BIGWILD
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    end
    
    if selfData and selfData.mergeWildColOld and #selfData.mergeWildColOld > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.WILD_CHANGE_BIGWILD_OLD
        selfEffect.p_selfEffectType = self.WILD_CHANGE_BIGWILD_OLD
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWildJurassicMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.WILD_CHANGE_BIGWILD_OLD then
        self:showEffect_changeBigWildByReel(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.WILD_CHANGE_BIGWILD then
        self:waitWithDelay(21/30, function()
            self:showEffect_changeBigWild(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end

	return true
end

--[[
    wildrespin 玩法存在旧的锁定列
    把锁定列下面的小块直接 变成长条
]]
function CodeGameScreenWildJurassicMachine:showEffect_changeBigWildByReel(_func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.mergeWildColOld and #selfData.mergeWildColOld > 0 then
        for indexCol = 1, #selfData.mergeWildColOld do
            local wildChangeColOld = selfData.mergeWildColOld[indexCol] + 1
            -- wildrespin 玩法旧的长条覆盖住的小块 变成长条 用于显示连线
            self:changeBigWildByReel(wildChangeColOld)
        end

        -- 存在长条 停止滚动的时候隐藏起来
        -- 便于显示连线
        for i=1,#self.m_bigWildNodeList do
            local node = self.m_bigWildNodeList[i]
            if node then
                node:setVisible(false)
            end
        end
    end
    
    if _func then
        _func()
    end
end

--[[
    4个小wild 合成一个大wild
]]
function CodeGameScreenWildJurassicMachine:showEffect_changeBigWild(_func)
    
    for indexCol = 1, #self.m_mergeWildCol do
        local wildChangeCol = self.m_mergeWildCol[indexCol] + 1
        
        local targSp = self:getFixSymbol(wildChangeCol, 1, SYMBOL_NODE_TAG)

        -- 创建一个固定的长条
        local bigWildNode = self:createBigWildByReel(targSp, wildChangeCol)
        if bigWildNode then
            self:changeBigWildByReel(wildChangeCol, true, bigWildNode, function()
                if indexCol == #self.m_mergeWildCol then
                    self:waitWithDelay(0.5,function()
                        if _func then
                            _func()
                        end
                    end)
                end
            end)
        else
            if indexCol == #self.m_mergeWildCol then
                self:waitWithDelay(0.5,function()
                    if _func then
                        _func()
                    end
                end)
            end
        end
    end
end

--[[
    处理棋盘上 某一列小块变成长条
    wildrespin 玩法不是最新滚动出来的长条 修改下棋盘小块为长条 用于连线
    _isPLayEffect 表示是否播放合成长条的相关动画
]]
function CodeGameScreenWildJurassicMachine:changeBigWildByReel(_col, _isPLayEffect, _bigWildNode, _func)
    local bigWildNode = nil

    local maxZOrder = 0
    local nodeList = {}
    for j = 1, self.m_iReelRowNum , 1 do
        local node =  self:getFixSymbol(_col , j, SYMBOL_NODE_TAG)
        if node and node.p_symbolType then
            if _isPLayEffect then
                node:runAnim("switch", false)
            end
            table.insert(nodeList,node)
            if maxZOrder <  node:getLocalZOrder() then
                maxZOrder = node:getLocalZOrder()
            end
        end
    end

    -- 把这一列的长条信息添加到存储数据中
    self:addBigSymbolInfo( _col )

    bigWildNode = self:getSlotNodeWithPosAndType(self.SYMBOL_BIG_WILD, 1, _col)

    bigWildNode.m_bInLine = true

    local linePos = {}
    for lineRowIndex = 1, self.m_iReelRowNum do
        linePos[#linePos + 1] = {
            iX = lineRowIndex,
            iY = _col
        }
    end

    bigWildNode:setLinePos(linePos)
    
    local funcCallBack = function()
        bigWildNode:runAnim("idleframe2", true)
        for index = 1,#nodeList do
            local node = nodeList[index]
            if node then
                self:moveDownCallFun(node, node.p_cloumnIndex) 
            end
        end
    end

    local targSp = self:getFixSymbol(_col, 1, SYMBOL_NODE_TAG)
    if targSp and targSp.p_symbolType and targSp.p_symbolType ~= self.SYMBOL_BIG_WILD then
        local reelParent = self:getReelParent(_col)

        reelParent:addChild(bigWildNode, targSp:getLocalZOrder(), targSp:getTag())
        bigWildNode:setPosition(targSp:getPositionX(), targSp:getPositionY())
        
        if _isPLayEffect then
            _bigWildNode:setVisible(true)
            
            -- 合图音效 
            if self.m_isPlayChangeBigWildSound then
                self.m_isPlayChangeBigWildSound = false
                if self:getCurrSpinMode() == RESPIN_MODE then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_wildRespin_changeBig)
                else
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_wild_changeBig)
                end
            end

            util_spinePlay(_bigWildNode, "switch", false)
            util_spineEndCallFunc(_bigWildNode,"switch",function ()
                util_spinePlay(_bigWildNode, "idleframe2", true)
            end)
            -- 棋盘震动
            if not self.m_isPlayShake then
                self.m_isPlayShake = true
                self:playShakeRootEffect()
            end

            bigWildNode:runAnim("switch",false,function()
                _bigWildNode:setVisible(false)
                funcCallBack()
                if _func then
                    _func()
                end
            end)
        else
            funcCallBack()
        end
    else
        if _func then
            _func()
        end
    end
end

--[[
    棋盘震动
]]
function CodeGameScreenWildJurassicMachine:playShakeRootEffect( )
    self:runCsbAction("switch", false)
    self:changeScatterParent()
    self:waitWithDelay(50/30,function()
        self:shakeRootNode()
    end)
end

--[[
    提层的scatter放回
]]
function CodeGameScreenWildJurassicMachine:changeScatterParent( )
    -- 对于已经提层的scatter 播放弹板的时候 放回棋盘
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    targSp:setPosition(util_convertToNodeSpace(targSp, self.m_slotParents[iCol].slotParent))
                    --将小块放回原层级
                    self:changeBaseParent(targSp)
                end
            end
        end
    end
end

function CodeGameScreenWildJurassicMachine:addBigSymbolInfo( icol )
    -- 处理大信号信息
    if not self.m_bigSymbolColumnInfo then
        self.m_bigSymbolColumnInfo = {}
    end

    local iColumn = self.m_iReelColumnNum
    local iRow = self.m_iReelRowNum

    local rowIndex = 1

    while true do
        if rowIndex > iRow then
            break
        end

        local symbolType = self.SYMBOL_BIG_WILD
        -- 判断是否有大信号内容
        if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil  then

            local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG,changeRows = {}}
            
            local colDatas = self.m_bigSymbolColumnInfo[icol]
            if colDatas == nil then
                colDatas = {}
                self.m_bigSymbolColumnInfo[icol] = colDatas
            end           

            colDatas[#colDatas + 1] = bigInfo     

            local symbolCount = self.m_bigSymbolInfos[symbolType]

            local hasCount = symbolCount

            bigInfo.changeRows[#bigInfo.changeRows + 1] = rowIndex


            if symbolCount == hasCount or rowIndex > 1 then  -- 表明从对应索引开始的
                bigInfo.startRowIndex = rowIndex
            else

                bigInfo.startRowIndex = rowIndex - (symbolCount - hasCount)
            end

            rowIndex = rowIndex + hasCount - 1  -- 跳过上面有的

        end -- end if ~= nil 

        rowIndex = rowIndex + 1
    end
end

--[[
    创建一个固定在棋盘上的长条
]]
function CodeGameScreenWildJurassicMachine:createBigWildByReel(_node, _col)
    local bigWildNode = nil
    if _node then
        bigWildNode = util_spineCreate("Socre_WildJurassic_Wild2", true, true)
        self:findChild("Node_bigwild"):addChild(bigWildNode)
        util_spinePlay(bigWildNode,"idleframe2",true)
        bigWildNode:setVisible(false)
        bigWildNode.m_bigWildCol = _col

        bigWildNode:setPosition(util_convertToNodeSpace(_node, self:findChild("Node_bigwild")))
        table.insert(self.m_bigWildNodeList, bigWildNode)
    end
    return bigWildNode
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenWildJurassicMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenWildJurassicMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

---
-- 触发respin 玩法
--
function CodeGameScreenWildJurassicMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    -- self:clearCurMusicBg()
    
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        if self:getIsBigWildByLines() then
            self:playBigWildIdleByLine()
        end

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
        end
    end

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        local delayTime = 1
        if self:getIsBigWildByLines() then
            delayTime = 2.5
        end
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            delayTime,
            self:getModuleName()
        )
    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

--[[
    弹respin 弹板之前长条参与连线的话 连线结束 不播静帧 播动态idle
]]
function CodeGameScreenWildJurassicMachine:playBigWildIdleByLine( )
    for i=1,#self.m_bigWildNodeList do
        local node = self.m_bigWildNodeList[i]
        if node then
            util_spinePlay(node, "idleframe2", true)
            local symbolNode = self:getFixSymbol(node.m_bigWildCol, 1, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType then
                symbolNode:runAnim("idleframe2", true)
            end
        end
    end
    
end

------------  respin 代码 这个respin就是不是单个小格滚动的那种 
function CodeGameScreenWildJurassicMachine:showRespinView(effectData)
    --触发respin
    --先播放动画 再进入respin
    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = false

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:clearWinLineEffect()
    -- wild的连线音效 直接切掉
    if self.m_playWildSoundId then
        gLobalSoundManager:stopAudio(self.m_playWildSoundId)
        self.m_playWildSoundId = nil
    end

    -- base下进入wildrespin 清理赢钱
    if not self.m_bProduceSlots_InFreeSpin then
        --清空赢钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    end

    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end

    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_WildJurassic_wildRespin_start"..self.m_isPlayWildRespinSoundIndex])
    self.m_isPlayWildRespinSoundIndex = self.m_isPlayWildRespinSoundIndex + 1
    if self.m_isPlayWildRespinSoundIndex > 2 then
        self.m_isPlayWildRespinSoundIndex = 1
    end

    self.m_wildRespin:setVisible(true)
    util_spinePlay(self.m_wildRespin,"actionframe",false)
    util_spineEndCallFunc(self.m_wildRespin,"actionframe",function ()
        self.m_wildRespin:setVisible(false)

        effectData.p_isPlay = true
        self:playEffectNotifyNextSpinCall()
    end)
end

---
-- 点击spin 按钮开始执行老虎机逻辑
--
function CodeGameScreenWildJurassicMachine:normalSpinBtnCall()
    --暂停中点击了spin不自动开始下一次
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.normalSpinBtnCall then
                self:normalSpinBtnCall()
            end
        end
        return
    end

    print("触发了 normalspin")

    local time1 = xcyy.SlotsUtil:getMilliSeconds()

    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    local isContinue = true
    if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE then
        if self.m_showLineFrameTime ~= nil then
            local waitTime = time1 - self.m_showLineFrameTime
            if waitTime < (self.m_lineWaitTime * 1000) then
                isContinue = false --时间不到，spin无效
            end
        end
    end

    if not isContinue then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        return
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    -- 引导打点：进入关卡-4.点击spin
    if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskStart1) then
        gLobalSendDataManager:getLogGuide():sendGuideLog(1, 4)
    end
    --新手引导相关
    local isComplete = globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskStart1, true)
    if isComplete then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_TIPS, {1, false})
    end
    if self.m_isWaitingNetworkData == true then -- 真实数据未返回，所以不处理点击
        return
    end

    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)

        self.m_showLineHandlerID = nil
    end

    local time2 = xcyy.SlotsUtil:getMilliSeconds()
    release_print("normalSpinBtnCall 消耗时间1 .. " .. (time2 - time1))

    if self:getGameSpinStage() == WAIT_RUN then
        return
    end

    self:firstSpinRestMusicBG()

    local isWaitCall = self:MachineRule_SpinBtnCall()
    if isWaitCall == false then
        self:callSpinBtn()
    else
        self:setGameSpinStage(WAIT_RUN)
    end

    local timeend = xcyy.SlotsUtil:getMilliSeconds()

    release_print("normalSpinBtnCall 消耗时间4 .. " .. (timeend - time1) .. " =========== ")
end

--接收到数据开始停止滚动
function CodeGameScreenWildJurassicMachine:stopRespinRun()
    print("已经得到了数据")
end

--ReSpin开始改变UI状态
function CodeGameScreenWildJurassicMachine:changeReSpinStartUI(respinCount)
   
end

--ReSpin刷新数量
function CodeGameScreenWildJurassicMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenWildJurassicMachine:changeReSpinOverUI()

end

function CodeGameScreenWildJurassicMachine:showEffect_RespinOver(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    self:removeRespinNode()
    self:showRespinOverView(effectData)

    return true
end

function CodeGameScreenWildJurassicMachine:showRespinOverView(effectData)
    -- 移除固定在棋盘上的长条wild
    for i=1,#self.m_bigWildNodeList do
        local node = self.m_bigWildNodeList[i]
        if node and not tolua.isnull(node) then
            node:removeFromParent()
            node = nil
        end
    end
    self.m_bigWildNodeList = {}

    effectData.p_isPlay = true
    self:triggerReSpinOverCallFun(self.m_lightScore)
    self.m_lightScore = 0
end

function CodeGameScreenWildJurassicMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== respin  server=" .. self.m_serverWinCoins .. "    client=" .. score .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, true})
    else
        coins = self.m_serverWinCoins or 0

        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

function CodeGameScreenWildJurassicMachine:MachineRule_respinTouchSpinBntCallBack()
    if globalData.slotRunData.gameSpinStage == IDLE and globalData.slotRunData.currSpinMode == RESPIN_MODE then 
        -- 处于等待中， 并且free spin 那么提前结束倒计时开始执行spin

        release_print("STR_TOUCH_SPIN_BTN 触发了 free mode")
        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
        release_print("btnTouchEnd 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
    else
        if self.m_bIsAuto == false then
            release_print("STR_TOUCH_SPIN_BTN 触发了 normal")
            gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
            release_print("btnTouchEnd m_bIsAuto == false 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
        end
    end 

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN  then  -- 表明滚动了起来。。
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP)
    end
end


function CodeGameScreenWildJurassicMachine:playEffectNotifyNextSpinCall( )
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

        if self:getIsBigWildByLines() then
            if delayTime < 2.5 then
                delayTime = 2.5
            end
        end

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
        local delayTime = 0.5
        if self:getIsBigWildByLines() then
            if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinsTotalCount and 
            self.m_runSpinResultData.p_reSpinCurCount ~= self.m_runSpinResultData.p_reSpinsTotalCount then
                delayTime = 2.5
            end
        end

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenWildJurassicMachine:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            local delayTime = 0.5
            if self:getIsBigWildByLines() then
                delayTime = 2.5
            end

            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin =
                    scheduler.performWithDelayGlobal(
                    function(delay)
                        self:normalSpinBtnCall()
                    end,
                    delayTime,
                    self:getModuleName()
                )
            end
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end
end

function CodeGameScreenWildJurassicMachine:slotReelDown( )
    local features = self.m_runSpinResultData.p_features or {}
    local scatterNum = 0
    for iCol=1,self.m_iReelColumnNum-1 do
        for iRow=1,self.m_iReelRowNum do
            local slotsNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotsNode and slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then 
                scatterNum = scatterNum + 1
            end
        end
    end

    -- 在scatter快滚 没有触发free玩法 停轮的时候 50%播放
    if scatterNum == 2 and not self.m_isQuicklyStop and #features < 2 then
        local random = math.random(1,10)
        if random < 6 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_quickRun_noTriggerFree)
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenWildJurassicMachine.super.slotReelDown(self)

end

function CodeGameScreenWildJurassicMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    延时函数
]]
function CodeGameScreenWildJurassicMachine:waitWithDelay(time, endFunc)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(endFunc) == "function" then
                endFunc()
            end
        end,
        time
    )

    return waitNode
end

function CodeGameScreenWildJurassicMachine:beginReel()
    -- 处理大信号信息
    if self.m_hasBigSymbol == true then
        self.m_bigSymbolColumnInfo = {}
    else
        self.m_bigSymbolColumnInfo = nil
    end

    -- 存在长条 滚动的时候显示出来
    for i=1,#self.m_bigWildNodeList do
        local node = self.m_bigWildNodeList[i]
        if node then
            node:setVisible(true)
        end
    end

    -- 下次spin的时候 连线音效没播完直接切掉
    if self.m_winSoundsId then 
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    -- wild的连线音效 直接切掉
    if self.m_playWildSoundId then
        gLobalSoundManager:stopAudio(self.m_playWildSoundId)
        self.m_playWildSoundId = nil
    end

    -- 再次spin的时候 重置一次数据
    self.m_isQuicklyStop = false
    self.m_isPlayShake = false
    self.m_isPlayChangeBigWildSound = true
    self.m_isPlayWildLinesSound = true
    CodeGameScreenWildJurassicMachine.super.beginReel(self)
end

---
-- 点击快速停止reel
--
function CodeGameScreenWildJurassicMachine:quicklyStopReel(colIndex)
    self.m_isQuicklyStop = true
    CodeGameScreenWildJurassicMachine.super.quicklyStopReel(self, colIndex)
end

function CodeGameScreenWildJurassicMachine:notifyClearBottomWinCoin()
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    end
    -- 不在区分是不是在 freespin下了 2019-05-08 20:56:44
end

function CodeGameScreenWildJurassicMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if self.m_runSpinResultData.p_reSpinsTotalCount and self.m_runSpinResultData.p_reSpinCurCount and
        self.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_runSpinResultData.p_reSpinCurCount > 0 then
            -- 次数为1 就表示触发的时候
        if not self.m_bProduceSlots_InFreeSpin and self.m_runSpinResultData.p_reSpinsTotalCount == 1 then
            isNotifyUpdateTop = true
        else
            isNotifyUpdateTop = false
        end
    end

    -- if self:getCurrSpinMode() == RESPIN_MODE then
    --     if self.m_bProduceSlots_InFreeSpin == false then
    --         globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_resWinCoins + globalData.slotRunData.lastWinCoin
    --     end
    -- end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenWildJurassicMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = self:getClipParentChildShowOrder(slotNode)
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    -- 切换图层
    -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)

    -- 策划需求长条播放连线动画的时候 层级要高于连线框
    if slotNode.p_symbolType == self.SYMBOL_BIG_WILD then
        util_changeNodeParent(self.m_clipParent, slotNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
    else
        util_changeNodeParent(self.m_clipParent, slotNode, self:getMaskLayerSlotNodeZorder(slotNode) + slotNode.p_showOrder)
    end

    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

--[[
    计算连线里面是否有大信号
    有大信号的话 需要最少播放一遍大信号连线动画之后 在下次spin
    大信号连线时长为2.5秒
]]
function CodeGameScreenWildJurassicMachine:getIsBigWildByLines( )
    for i = 1, #self.m_reelResultLines do
        local linesDate = self.m_reelResultLines[i]
        if linesDate and linesDate.vecValidMatrixSymPos then
            for j, rowAndCol in ipairs(linesDate.vecValidMatrixSymPos) do
                local targSp = self:getFixSymbol(rowAndCol.iY, rowAndCol.iX, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == self.SYMBOL_BIG_WILD then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--[[
    适配
]]
function CodeGameScreenWildJurassicMachine:scaleMainLayer()
    CodeGameScreenWildJurassicMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.78
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.85 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.92 - 0.06*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.93 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

--[[
    棋盘震动
    合图长条 开始吼叫的时候 震动
    50帧开始 70帧结束
]]
function CodeGameScreenWildJurassicMachine:shakeRootNode( )

    local changePosY = 5
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i = 1,3 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y - changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)
end

--[[
    @desc: 处理用户的spin赢钱信息
    time:2020-07-10 17:50:08
]]
function CodeGameScreenWildJurassicMachine:operaWinCoinsWithSpinResult(param)
    local spinData = param[2]
    local userMoneyInfo = param[3]
    self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
    --发送测试赢钱数
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN, self.m_serverWinCoins)
    globalData.userRate:pushCoins(self.m_serverWinCoins)

    if spinData.result.freespin.freeSpinsTotalCount == 0 then
        local bWildRespin = self:getCurrSpinMode() == RESPIN_MODE
        if bWildRespin then
            self:setLastWinCoin(spinData.result.respin.resWinCoins)
        else
            self:setLastWinCoin(spinData.result.winAmount)
        end
    else
        self:setLastWinCoin(spinData.result.freespin.fsWinCoins)
    end
    globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
end

--获取底栏金币
function CodeGameScreenWildJurassicMachine:getCurBottomWinCoins()
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

function CodeGameScreenWildJurassicMachine:getBottomUINode()
    return "CodeWildJurassicSrc.WildJurassicGameBottomNode"
end

---------------- 连线的时候 是否有 wild bigwild 参与连线
---------------- 有的话 需要播放音效
---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenWildJurassicMachine:playInLineNodes()
    CodeGameScreenWildJurassicMachine.super.playInLineNodes(self)
    if self.m_lineSlotNodes == nil then
        return
    end

    if self.m_isPlayWildLinesSound then
        self.m_isPlayWildLinesSound = false
        self.m_playWildSoundId = self:playWildOrBigWildSound(self.m_lineSlotNodes, false)
    end
end

--[[
    连线里 查看是否有wild bigwild
]]
function CodeGameScreenWildJurassicMachine:getHaveByLineSlotNodes(_lineSlotNodes)
    local haveWild = false
    local haveBigWild = false
    for i = 1, #_lineSlotNodes do
        local slotsNode = _lineSlotNodes[i]
        if slotsNode ~= nil then
            if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                haveWild = true
            end
            if slotsNode.p_symbolType == self.SYMBOL_BIG_WILD then
                haveBigWild = true
            end
        end
    end
    return haveWild, haveBigWild
end

--[[
    播放wild 或者 bigwild 连线时候的音效
]]
function CodeGameScreenWildJurassicMachine:playWildOrBigWildSound(_lineSlotNodes, _isLoop)
    local soundId = nil
    local haveWild, haveBigWild = self:getHaveByLineSlotNodes(_lineSlotNodes)
    if haveBigWild then
        soundId = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_bigWild_lines, _isLoop)
    else
        if haveWild then
            soundId = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_Wild_lines, _isLoop)
        end
    end
    return soundId
end

function CodeGameScreenWildJurassicMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenWildJurassicMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenWildJurassicMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    -- free玩法的最后 一次 不播放大赢
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_runSpinResultData and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            self.m_isAddBigWinLightEffect = false
        end
    end
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenWildJurassicMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
        local posY = self.m_bottomUI.m_bigWinLabCsb:getPositionY()
        posY = posY + 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    else
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.6)
    end
    
    
    --通用底部跳字动效
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    local params = {
        overCoins  = winCoins,
        jumpTime   = 1.2,
        animName   = "actionframe3",
    }
    self:playBottomBigWinLabAnim(params)
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenWildJurassicMachine:showBigWinLight(_func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_WildJurassic_yugao)

    self.m_bigwinEffect:setVisible(true)

    local actionName = "actionframe"

    util_spinePlay(self.m_bigwinEffect,actionName)
    util_spineEndCallFunc(self.m_bigwinEffect,actionName,function()
        self.m_bigwinEffect:setVisible(false)

        -- 如果连线没播完大赢出来了，切断连线中奖音效
        self:stopLinesWinSound()

        -- wild的连线音效 直接切掉
        if self.m_playWildSoundId then
            gLobalSoundManager:stopAudio(self.m_playWildSoundId)
            self.m_playWildSoundId = nil
        end
        
        if _func then
            _func()
        end
    end)

    self:runCsbAction("zhen", false)

end

return CodeGameScreenWildJurassicMachine






