---
-- island li
-- 2019年1月26日
-- CodeGameScreenFiestaDeMuertosMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine" -- BaseFastMachine
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local FiestaDeMuertosSlotsNode = require "CodeFiestaDeMuertosSrc.FiestaDeMuertosSlotsNode"
local CodeGameScreenFiestaDeMuertosMachine = class("CodeGameScreenFiestaDeMuertosMachine", BaseNewReelMachine)

--设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

CodeGameScreenFiestaDeMuertosMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFiestaDeMuertosMachine.SYMBOL_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 普通bonus
CodeGameScreenFiestaDeMuertosMachine.SYMBOL_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 -- 转盘bonus
CodeGameScreenFiestaDeMuertosMachine.SYMBOL_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3 -- 人物

CodeGameScreenFiestaDeMuertosMachine.BONUS_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 普通bonus收集点数

-- 构造函数
function CodeGameScreenFiestaDeMuertosMachine:ctor()
    BaseNewReelMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_spinWinCount = 0
    self.m_Bonus2Num = 0
    self.m_Bonus1Num = 0
    self.m_nowBottomCoins = 0
    self.m_bCollect = false
    --init
    self:initGame()
end

function CodeGameScreenFiestaDeMuertosMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFiestaDeMuertosMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FiestaDeMuertos"
end

function CodeGameScreenFiestaDeMuertosMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
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
        local ratio = display.height / display.width
        if ratio >= 768 / 1024 then
            mainScale = 0.90
        elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
            mainScale = 0.95 - 0.05 * ((ratio - 640 / 960) / (768 / 1024 - 640 / 960))
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end
end

function CodeGameScreenFiestaDeMuertosMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    self.m_jackpotBar = util_createView("CodeFiestaDeMuertosSrc.FiestaDeMuertosJackPotBarView")
    self.m_jackpotBar:initMachine(self)
    self:findChild("FiestaDeMuertos_jackpot"):addChild(self.m_jackpotBar)

    -- 创建过场
    self.m_guochang = util_createAnimation("FiestaDeMuertos_guochang.csb")
    self:addChild(self.m_guochang, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guochang:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochang:setVisible(false)

    self.m_RunDi = {}
    for i = 1, 5 do
        local longRunDi = util_createAnimation("WinFrameFiestaDeMuertos_run_bg.csb")
        self:findChild("reelNode"):addChild(longRunDi, 1)
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_" .. (i - 1)):getPosition()))
        longRunDi:setVisible(false)
        table.insert(self.m_RunDi, longRunDi)
    end

    self.m_Bonus3RunDi = util_createAnimation("FrameFiestaDeMuertos_Bonus_run_bg.csb")
    self:findChild("reelNode"):addChild(self.m_Bonus3RunDi, 1)
    self.m_Bonus3RunDi:setPosition(cc.p(self:findChild("sp_reel_4"):getPosition()))
    self.m_Bonus3RunDi:setVisible(false)

    self:createBonusReelEffect()

    self.m_gameBg:runCsbAction("Bg", true)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为三挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 1
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 2
            elseif winRate > 3 then
                soundIndex = 3
                soundTime = 3
            end

            local soundName = "FiestaDeMuertosSounds/sound_FiestaDeMuertos_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenFiestaDeMuertosMachine:changeJackpotBar(bChange)
    if bChange then
        self:findChild("FiestaDeMuertos_jackpot"):setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    else
        self:findChild("FiestaDeMuertos_jackpot"):setLocalZOrder(0)
    end
end

function CodeGameScreenFiestaDeMuertosMachine:createBonusReelEffect()
    self.m_bonusReelEffectNode, self.m_bonusReeleffectAct = util_csbCreate("FrameFiestaDeMuertos_Bonus_run.csb")
    -- util_csbPlayForKey(self.m_bonusReeleffectAct,"run",true)
    self.m_clipParent:addChild(self.m_bonusReelEffectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_bonusReelEffectNode:setPosition(cc.p(self:findChild("sp_reel_4"):getPosition()))
    self.m_bonusReelEffectNode:setVisible(false)
end

function CodeGameScreenFiestaDeMuertosMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:changeFreeSpinByCount()
end

--type = 0 是点数  type = 1 是jackpot ；type = 2 是乘倍
function CodeGameScreenFiestaDeMuertosMachine:getWinMulOrJackpot(_winType)
    local data = self.m_runSpinResultData.p_selfMakeData
    local dataList = {}
    local isHave = false
    if data and data.hits then
        for i, v in ipairs(data.hits) do
            local _type = v.type
            if _type == _winType then
                isHave = true
                local data = {}
                data.index = i
                data.name = v.name
                data.position = v.position
                data.value = v.value
                data.coins = v.coins
                table.insert(dataList, data)
            end
        end
    end

    return isHave, dataList
end
--小块
function CodeGameScreenFiestaDeMuertosMachine:getBaseReelGridNode()
    return "CodeFiestaDeMuertosSrc.FiestaDeMuertosSlotsNode"
end

---
--添加金边
function CodeGameScreenFiestaDeMuertosMachine:creatReelRunAnimation(col)
    if col == self.m_iReelColumnNum then
        BaseNewReelMachine.creatReelRunAnimation(self, col)

        if self.m_RunDi[col] ~= nil then
            local reelEffectNodeBg = self.m_RunDi[col]
            reelEffectNodeBg:setVisible(true)
        end
    end
end

function CodeGameScreenFiestaDeMuertosMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.isInBonus then
                        self:resetMusicBg()
                    end
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenFiestaDeMuertosMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenFiestaDeMuertosMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
end

function CodeGameScreenFiestaDeMuertosMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenFiestaDeMuertosMachine:getBottomUINode()
    return "CodeFiestaDeMuertosSrc.FiestaDeMuertosGameBottomNode"
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFiestaDeMuertosMachine:MachineRule_GetSelfCCBName(symbolType)
    if self.SYMBOL_BONUS_1 == symbolType then
        return "Socre_FiestaDeMuertos_Bonus1"
    elseif self.SYMBOL_BONUS_2 == symbolType then
        return "Socre_FiestaDeMuertos_Bonus2"
    elseif self.SYMBOL_BONUS_3 == symbolType then
        return "Socre_FiestaDeMuertos_Bonus3"
    end

    return nil
end

function CodeGameScreenFiestaDeMuertosMachine:showMaskLayer()
    if not self.m_MaskLayer then
        self.m_MaskLayer = util_createAnimation("FiestaDeMuertos_Mask.csb")
        local reel = self:findChild("reelNode")
        local posWorld = reel:getParent():convertToWorldSpace(cc.p(reel:getPosition()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        self.m_MaskLayer:setPosition(pos)
        self.m_clipParent:addChild(self.m_MaskLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 5)
    end
    self.m_MaskLayer:setVisible(true)
    self.m_MaskLayer:runCsbAction("show")
end
---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFiestaDeMuertosMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenFiestaDeMuertosMachine:MachineRule_initGame()
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
        if self.m_bProduceSlots_InFreeSpin == true then
            local resultData = self.m_runSpinResultData
            self.m_nowBottomCoins = resultData.p_fsWinCoins + self:getAllBonusPointNum()
        else
            self.m_nowBottomCoins = self:getAllBonusPointNum()
        end
        if self.m_nowBottomCoins > 0 then
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_nowBottomCoins))
        end
    end
end

function CodeGameScreenFiestaDeMuertosMachine:showDarkLayer()
    local nowHeight = self.m_iReelRowNum * self.m_SlotNodeH
    local nowWidth = 730
    if not self.m_DarkLayer then
        self.m_DarkLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 200))
        self.m_DarkLayer:setContentSize(nowWidth, nowHeight)
        local reel = self:findChild("sp_reel_0")
        local posWorld = reel:getParent():convertToWorldSpace(cc.p(reel:getPosition()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        self.m_DarkLayer:setPosition(pos)
        self.m_clipParent:addChild(self.m_DarkLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 5)
    end
    self.m_DarkLayer:setVisible(true)
end

function CodeGameScreenFiestaDeMuertosMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "FiestaDeMuertosSounds/sound_FiestaDeMuertos_scatter_ground.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenFiestaDeMuertosMachine:getScatterBeginCol( )
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol] 
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                return iCol
            end
        end
        
    end

    return self.m_iReelColumnNum
     
end
function CodeGameScreenFiestaDeMuertosMachine:isPlayTipAnima(matrixPosY, matrixPosX, node)
    local isplay =  CodeGameScreenFiestaDeMuertosMachine.super.isPlayTipAnima(self,matrixPosY, matrixPosX, node)
    if self:getScatterBeginCol( ) ~= 1 then
        isplay = false
    end
   
    return isplay
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenFiestaDeMuertosMachine:specialSymbolActionTreatment( node)
    -- print("dada")

    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

        if node then
            node:runAnim("buling",false,function()
                node:runAnim("idle2", true)                
            end)
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenFiestaDeMuertosMachine:slotOneReelDown(reelCol)
    --Scatter  play "buling" animation
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if targSp then
            local symbolType = targSp.p_symbolType
            if  symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_3 then
                if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    targSp = self:setSymbolToClipReel(reelCol, iRow, symbolType)
                end
                if targSp then
                    targSp:runAnim(
                        "buling",
                        false,
                        function()
                            if symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_3 then
                                targSp:runAnim("idleframe", true)
                            end
                        end
                    )
                end

                local soundPath = nil


                if symbolType == self.SYMBOL_BONUS_1 then
                    self.m_Bonus1Num = self.m_Bonus1Num + 1
                    soundPath = "FiestaDeMuertosSounds/sound_FiestaDeMuertos_Bonus_ground.mp3"
                elseif symbolType == self.SYMBOL_BONUS_2 then
                    self.m_Bonus2Num = self.m_Bonus2Num + 1
                    soundPath = "FiestaDeMuertosSounds/sound_FiestaDeMuertos_Bonus_ground.mp3"
                elseif symbolType == self.SYMBOL_BONUS_3 then
                    if self.m_Bonus2Num > 0 or self.m_Bonus1Num > 1 then
                        soundPath = "FiestaDeMuertosSounds/sound_FiestaDeMuertos_Bonus3_ground.mp3"
                    end
                end
                if soundPath then
                    if self.playBulingSymbolSounds then
                        self:playBulingSymbolSounds( reelCol,soundPath )
                    else
                        gLobalSoundManager:playSound(soundPath)
                    end
                end
                
            end
        end
    end
    if reelCol > 4 then
        local rundi = self.m_RunDi[reelCol]
        if rundi:isVisible() then
            rundi:setVisible(false)
        end
        if self.m_Bonus3RunDi:isVisible() then
            self.m_Bonus3RunDi:setVisible(false)
        end
        if self.m_bonusReelEffectNode:isVisible() then
            self.m_bonusReelEffectNode:setVisible(false)
        end
        if self.m_DarkLayer then
            self.m_DarkLayer:setVisible(false)
        end
    end

    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        if self.m_Bonus2Num > 0 then
            self:showBonusLongRunEffect()
        else
            self:creatReelRunAnimation(reelCol + 1)
        end
    end

    if self.m_reelDownSoundPlayed then
        self:playReelDownSound(reelCol,self.m_reelDownSound )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end


    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    return isTriggerLongRun
end

function CodeGameScreenFiestaDeMuertosMachine:showBonusLongRunEffect()
    self.m_bonusReelEffectNode:setVisible(true)
    util_csbPlayForKey(self.m_bonusReeleffectAct, "run", true)
    if self.m_Bonus3RunDi then
        self.m_Bonus3RunDi:setVisible(true)
    end
    self:showDarkLayer()
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--本列停止 判断下列是否有长滚
function CodeGameScreenFiestaDeMuertosMachine:getNextReelIsLongRun(reelCol)
    if reelCol == self.m_iReelColumnNum then
        local bHaveLongRun = false
        for i = 1, reelCol do
            local reelRunData = self.m_reelRunInfo[i]
            if reelRunData:getNextReelLongRun() == true then
                bHaveLongRun = true
                break
            end
        end
        if self:isLongRun(reelCol) and bHaveLongRun and self.m_reelRunInfo[reelCol]:getNextReelLongRun() == false then
            return true
        end
    end
    return false
end

function CodeGameScreenFiestaDeMuertosMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFiestaDeMuertosMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "FreespinBG")
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenFiestaDeMuertosMachine:showFreeSpinView(effectData)
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_fs_trigger.mp3")

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_tip_show.mp3")
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_guochang.mp3")
            self.m_guochang:setVisible(true)
            performWithDelay(
                self,
                function()
                    self.m_gameBg:runCsbAction("FreespinBG", false)
                    self:playSymbolAction(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, "idle2", true)
                end,
                18 / 30
            )
            local particle1 = self.m_guochang:findChild("Particle_1")
            particle1:resetSystem()
            self.m_guochang:runCsbAction(
                "actionframe",
                false,
                function()
                    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_tip_show.mp3")
                    self:showFreeSpinStart(
                        self.m_iFreeSpinTimes,
                        function()
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end
            )
        end
    end

    --提高scatter 层级
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                targSp = self:setSymbolToClipReel(iCol, iRow, targSp.p_symbolType)
                targSp:runAnim(
                    "actionframe",
                    false,
                    function()
                        -- targSp:runAnim("idle2", true)
                    end
                )
            end
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        4
    )
end

function CodeGameScreenFiestaDeMuertosMachine:playSymbolAction(_type, _animaName, _loop)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType == _type then
                targSp:runAnim(_animaName, _loop)
            end
        end
    end
end

function CodeGameScreenFiestaDeMuertosMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_fs_over.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_guochang.mp3")
            self.m_guochang:setVisible(true)
            performWithDelay(
                self,
                function()
                    self.m_gameBg:runCsbAction("Bg", true)
                    self:hideFreeSpinBar()
                end,
                18 / 30
            )
            local particle1 = self.m_guochang:findChild("Particle_1")
            particle1:resetSystem()
            self.m_guochang:runCsbAction(
                "actionframe",
                false,
                function()
                    self:triggerFreeSpinOverCallFun()
                end
            )
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFiestaDeMuertosMachine:MachineRule_SpinBtnCall()
    self.m_Bonus2Num = 0
    self.m_Bonus1Num = 0
    self.m_nowBottomCoins = 0
    self.m_bCollect = false
    self.m_collectList = {}
    self.m_playAnimIndex = 0
    if self.m_MaskLayer and self.m_MaskLayer:isVisible() then
        self.m_MaskLayer:setVisible(false)
    end
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenFiestaDeMuertosMachine:slotReelDown()
    BaseNewReelMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

-- function CodeGameScreenFiestaDeMuertosMachine:playEffectNotifyNextSpinCall()
--     self:checkTriggerOrInSpecialGame(
--         function()
--             self:reelsDownDelaySetMusicBGVolume()
--         end
--     )
--     self:playEffectNotifyNextSpinCall()
-- end

function CodeGameScreenFiestaDeMuertosMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()
        if self.m_bCollect then
            return
        end
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                if self.m_bCollect then
                    return
                end
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
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFiestaDeMuertosMachine:addSelfEffect()
    -- 自定义动画创建方式
    local bonusType = self.m_runSpinResultData.p_selfMakeData.bonusType
    self.m_collectList = {}
    if bonusType == 1 or bonusType == 2 then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node then
                    local symbolType = node.p_symbolType
                    if symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 then
                        local nodeData = {}
                        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                        local reelsIndex = self:getPosReelIdx(iRow, iCol)
                        local point = self:getPointNum(reelsIndex)
                        nodeData.startPos = startPos
                        nodeData.symbolType = symbolType
                        nodeData.node = node
                        nodeData.point = point
                        self.m_collectList[#self.m_collectList + 1] = nodeData
                    end
                end
            end
        end

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUS_COLLECT_EFFECT -- 动画类型
    end
end
--是否触发bonus玩法
function CodeGameScreenFiestaDeMuertosMachine:isTriggerBonusGame()
    local isIn = false
    local features = self.m_runSpinResultData.p_features
    if features then
        for k, v in pairs(features) do
            if v == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                isIn = true
            end
        end
    end
    return isIn
end
-- 播放玩法动画
function CodeGameScreenFiestaDeMuertosMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.BONUS_COLLECT_EFFECT then
        self.m_effectData = effectData
        scheduler.performWithDelayGlobal(
            function()
                self:playBonusPointCollectEffect()
            end,
            0.5,
            self:getModuleName()
        )
    end
    return true
end

function CodeGameScreenFiestaDeMuertosMachine:playBonusPointCollectEffect()
    --bonus3 效果 弹琴
    self:playSymbolAction(self.SYMBOL_BONUS_3, "actionframe_jixing", true)

    self:showMaskLayer() --显示黑色遮罩
    -- gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_Bonus_trigger1.mp3")

    self.m_bonusLoop = gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_Bonus_loop.mp3", true)
    gLobalSoundManager:setBackgroundMusicVolume(0)

    --开始收集
    scheduler.performWithDelayGlobal(
        function()
            -- if self:isCanClickSpin() then
            --     self.m_effectData.p_isPlay = true
            --     self:playGameEffect()
            -- end
            self.m_bCollect = true
            if self.m_bProduceSlots_InFreeSpin == true then
                self.m_nowBottomCoins = globalData.slotRunData.lastWinCoin - self.m_runSpinResultData.p_winAmount
            else
                self.m_nowBottomCoins = 0
            end
            self.m_playAnimIndex = 1
            self.m_winPoint = 0
            self:playCollectAnim()
        end,
        1,
        self:getModuleName()
    )
end

--是否可以点击spin
function CodeGameScreenFiestaDeMuertosMachine:isCanClickSpin()
    if not self:isTriggerBonusGame() and #self.m_reelResultLines == 0 and self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == false then
        return true
    end
    return false
end

--播放bonus 收集效果
function CodeGameScreenFiestaDeMuertosMachine:playNextBonusCollect()
    if self.m_bCollect == false then
        self:stopBonusLoopSound()
        return
    end

    if self.m_playAnimIndex == #self.m_collectList then
        scheduler.performWithDelayGlobal(
            function()
                self:playSymbolAction(self.SYMBOL_BONUS_3, "idleframe", false)
                self.m_bCollect = false
                self:stopBonusLoopSound()
                self.m_bottomUI.coinBottomEffectNode:setVisible(false)

                if not self:isTriggerBonusGame() then
                    if self.m_MaskLayer and self.m_MaskLayer:isVisible() then
                        self.m_MaskLayer:setVisible(false)
                    end
                    --检查是否触发bigwin 没有的话添加效果
                    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
                    else
                        local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
                        if hasFsOverEffect == false then
                            local totalCoins = self.m_runSpinResultData.p_winAmount
                            self:checkFeatureOverTriggerBigWin(totalCoins, GameEffect.EFFECT_BONUS)
                            if self.m_bProduceSlots_InFreeSpin ~= true then
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                            end
                        end
                    end
                end

                if self:isTriggerBonusGame() then --触发bonus 延迟1秒
                    scheduler.performWithDelayGlobal(
                        function()
                            if self.m_effectData then
                                self.m_effectData.p_isPlay = true
                                self:playGameEffect()
                                self.m_effectData = nil
                            end
                        end,
                        1,
                        self:getModuleName()
                    )
                else
                    if self.m_effectData then
                        self.m_effectData.p_isPlay = true
                        self:playGameEffect()
                        self.m_effectData = nil
                    end
                end
            end,
            0.5,
            self:getModuleName()
        )
        -- end

        return
    end
    self.m_playAnimIndex = self.m_playAnimIndex + 1
    self:playCollectAnim()
end

function CodeGameScreenFiestaDeMuertosMachine:stopBonusLoopSound()
    self:playSymbolAction(self.SYMBOL_BONUS_3, "actionframe_jixingover", false)
    if self.m_bonusLoop then
        gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_Bonus_loop_over.mp3")
        gLobalSoundManager:stopAudio(self.m_bonusLoop)
        self.m_bonusLoop = nil
    end
end
function CodeGameScreenFiestaDeMuertosMachine:playCollectAnim()
    if self.m_playAnimIndex > #self.m_collectList then
        return
    end
    local data = self.m_collectList[self.m_playAnimIndex]
    local startPos = data.startPos
    self.m_winPoint = data.point
    local endWorldPos = self.m_bottomUI:getCoinWinNode():getParent():convertToWorldSpace(cc.p(self.m_bottomUI:getCoinWinNode():getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
    local node = data.node
    --变暗
    if not tolua.isnull(node) then
        node:runAnim(
            "actionframe",
            false,
            function()
                if node.p_symbolType == self.SYMBOL_BONUS_2 then
                    node:runAnim("idleframe1", true)
                end
            end
        )
        node:playBonusSymbolLabAction("jiesuan")
    end
    -- 添加飞行轨迹
    local effectLabel = self:ceateParticleEffect()
    effectLabel:setPosition(startPos.x, startPos.y - 45)
    effectLabel:setScale(2)
    self:addChild(effectLabel, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    local action_time = 12 / 30
    local bezier = {}
    local action
    if node.p_cloumnIndex < 3 then
        bezier[1] = cc.p(startPos.x - startPos.x / 2 - 50, startPos.y + 30)
        bezier[2] = cc.p(endPos.x - endPos.x / 3 - 30, endPos.y - 50)
        bezier[3] = endPos
        action = cc.BezierTo:create(action_time, bezier)
    elseif node.p_cloumnIndex == 3 then
        action = cc.MoveTo:create(action_time, endPos)
    elseif node.p_cloumnIndex > 3 then
        bezier[1] = cc.p(startPos.x + startPos.x / 2, startPos.y + 30)
        bezier[2] = cc.p(endPos.x + endPos.x / 3 - 30, endPos.y - 50)
        bezier[3] = endPos
        action = cc.BezierTo:create(action_time, bezier)
    end

    local scaleTo1 = cc.ScaleTo:create(action_time / 2, self.m_machineRootScale * 1.5)
    local scaleTo2 = cc.ScaleTo:create(action_time / 2, self.m_machineRootScale * 0.6)
    local spwan = cc.Spawn:create(action, cc.Sequence:create(scaleTo1, scaleTo2))
    local call_set =
        cc.CallFunc:create(
        function(sender)
            scheduler.performWithDelayGlobal(
                function()
                    sender:removeFromParent()
                end,
                4 / 30,
                self:getModuleName()
            )
            if self.m_bCollect == false then
                self:stopBonusLoopSound()
                return
            end
            self:playCoinWinEffectUI()
            local winCoin = self.m_winPoint
            self.m_nowBottomCoins = self.m_nowBottomCoins + winCoin
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_nowBottomCoins))
        end
    )
    if self.m_bCollect == false then
        self:stopBonusLoopSound()
        return
    end
    local seq = cc.Sequence:create({spwan, call_set})
    effectLabel:runAction(seq)
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_par_collect.mp3")
    scheduler.performWithDelayGlobal(
        function()
            self:playNextBonusCollect()
        end,
        15 / 30,
        self:getModuleName()
    )
end

function CodeGameScreenFiestaDeMuertosMachine:createMoveSymbol(symbolType)
    local node = FiestaDeMuertosSlotsNode:create()
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    node:initSlotNodeByCCBName(ccbName, symbolType)
    return node
end

--bonus碰撞特效
function CodeGameScreenFiestaDeMuertosMachine:playSymbolBombEffect(endPos, func)
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_Bonus_bomb.mp3")
    local bomb = util_createAnimation("FiestaDeMuertos_Bonus_heti.csb")
    bomb:setPosition(endPos)
    self:addChild(bomb, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 3)
    bomb:runCsbAction(
        "actionframe",
        false,
        function()
            bomb:removeFromParent()
        end
    )
    scheduler.performWithDelayGlobal(
        function()
            if func then
                func()
            end
        end,
        15 / 30,
        self:getModuleName()
    )
end

function CodeGameScreenFiestaDeMuertosMachine:playBonusMusicBgm()
    self.m_currentMusicBgName = "FiestaDeMuertosSounds/music_FiestaDeMuertos_wheel_bgm.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

-- 根据Bonus Game 每关做的处理
function CodeGameScreenFiestaDeMuertosMachine:showBonusGameView(effectData)
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_Bonus_trigger2.mp3")
    local moveSymbol = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                local symbolType = node.p_symbolType
                if symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_3 then
                    node = self:setSymbolToClipReel(iCol, iRow, symbolType)
                    if symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_3 then
                        table.insert(moveSymbol, node)
                        node:runAnim("actionframe1", false)
                        if symbolType == self.SYMBOL_BONUS_2 then
                            node:playBonusSymbolLabAction("actionframe")
                        end
                    end
                end
            end
        end
    end
    --显示遮罩
    if not self.m_MaskLayer then
        self:showMaskLayer()
    end
    --碰撞效果
    performWithDelay(
        self,
        function()
            local num = 0
            for i = 1, #moveSymbol do
                local node = moveSymbol[i]
                if node and node.p_symbolType then
                    local symbolType = node.p_symbolType
                    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                    local endPos = self:findChild("flyEnd"):getParent():convertToWorldSpace(cc.p(self:findChild("flyEnd"):getPosition()))
                    local targSp = self:createMoveSymbol(symbolType)
                    if targSp and symbolType == self.SYMBOL_BONUS_2 then
                        local row = node.p_rowIndex
                        local col = node.p_cloumnIndex
                        local reelsIndex = self:getPosReelIdx(row, col)
                        local point = self:getPointNum(reelsIndex)
                        targSp:setBonusLabNum(point)
                    end
                    targSp:setPosition(startPos)
                    self:addChild(targSp, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                    targSp:runAction(
                        cc.Sequence:create(
                            cc.MoveTo:create(0.5, endPos),
                            cc.CallFunc:create(
                                function(sender)
                                    sender:removeFromParent()
                                    if util_resetChildReferenceCount then
                                        util_resetChildReferenceCount(sender)
                                    end
                                    if num == #moveSymbol then
                                        num = num + 1
                                        self:playSymbolBombEffect(
                                            endPos,
                                            function()
                                                self.m_effectData = effectData
                                                self:showBonusWheel()
                                            end
                                        )
                                    end
                                end
                            )
                        )
                    )
                    num = num + 1
                end
            end
        end,
        2.2
    )
end

function CodeGameScreenFiestaDeMuertosMachine:showBonusWheel()
    -- 轮盘网络数据
    local data = {}
    self.m_bonusWheel = util_createView("CodeFiestaDeMuertosSrc.FiestaDeMuertosWheelView", data)
    local callback = function()
        self:clearCurMusicBg()
        self:playBonusWinEffect()
    end
    self.m_winMulNum = 0
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_show_wheel.mp3")
    self.m_bonusWheel:runCsbAction(
        "show",
        false,
        function()
            self.m_bonusWheel.m_bIsTouchEnabled = true
            self:playBonusMusicBgm()
            if self.m_MaskLayer then
                self.m_MaskLayer:runCsbAction(
                    "over",
                    false,
                    function()
                        self.m_MaskLayer:setVisible(false)
                    end
                )
            end
            self:changeJackpotBar(true)
            self.m_bonusWheel:runCsbAction("idleframe", true)
            self.m_bonusWheel:createWheelFinger()
        end
    )
    self.m_bonusWheel:initMachine(self)
    self.m_bonusWheel:initCallBack(callback)
    self:findChild("FiestaDeMuertos_zhuanlun"):addChild(self.m_bonusWheel)
end

-- @desc: 播放bonus 中奖效果
function CodeGameScreenFiestaDeMuertosMachine:playBonusWinEffect()
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_wheel_win.mp3")
    self:setWheelMulLab()
    self.m_bonusWheel:runCsbAction(
        "actionframe1",
        false,
        function()
            self.m_bonusWheel:runCsbAction("dark", false)
            performWithDelay(
                self,
                function()
                    local isWinMul, mulList = self:getWinMulOrJackpot(2)
                    if isWinMul then
                        self:playMulMoveEff(mulList)
                    else
                        local isWinJackpot, jackPotList = self:getWinMulOrJackpot(1)
                        if isWinJackpot then
                            self:playShowJackpotEff(jackPotList)
                        else
                            self:playWheelLabWin()
                        end
                    end
                end,
                1.5
            )
        end
    )
end
--转盘遮罩时 有乘倍的 提升层级
function CodeGameScreenFiestaDeMuertosMachine:setWheelMulLab()
    local isWinMul, mulList = self:getWinMulOrJackpot(2)
    self.m_wheelMulLab = {}
    if isWinMul then
        for i = 1, #mulList do
            local data = mulList[i]
            local moveLab = self:createWheelMulLab(data)
            local _index = data.position + 1
            local lab = self.m_bonusWheel:getWheelLabByIndex(_index)
            lab:setVisible(false)
            local startPos = lab:getParent():convertToWorldSpace(cc.p(lab:getPosition()))
            moveLab:setPosition(startPos)
            self:addChild(moveLab, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 10 - i)
            self.m_wheelMulLab[i] = moveLab
        end
    end
end

function CodeGameScreenFiestaDeMuertosMachine:createWheelMulLab(data)
    local num = data.index
    local moveLab = util_createView("CodeFiestaDeMuertosSrc.FiestaDeMuertosWheelLab", "MulLab")
    moveLab:setLab(data.name)
    moveLab:setScale(self.m_machineRootScale)
    if num == 1 then
        moveLab:setRotation(-65)
    elseif num == 2 then
        moveLab:setRotation(-32.5)
    elseif num == 4 then
        moveLab:setRotation(32.5)
    elseif num == 5 then
        moveLab:setRotation(65)
    end
    return moveLab
end

function CodeGameScreenFiestaDeMuertosMachine:playMulMoveEff(dataList)
    self.m_mulDataList = dataList
    self.m_playMulIndex = 1
    self.m_winMulNum = 0
    self:playOneMulMove()
end

--结算轮盘乘倍
function CodeGameScreenFiestaDeMuertosMachine:playOneMulMove()
    if self.m_playMulIndex > #self.m_mulDataList then
        local isWinJackpot, jackPotList = self:getWinMulOrJackpot(1)
        self.m_wheelMulLab = {}
        if isWinJackpot then
            self:playShowJackpotEff(jackPotList)
        else
            self:playWheelLabWin()
        end
        return
    end

    local data = self.m_mulDataList[self.m_playMulIndex]
    local num = data.index --中奖对应的位置

    local moveLab = self.m_wheelMulLab[self.m_playMulIndex]
    moveLab:runCsbAction("actionframe")

    local endNode = self:findChild("bonusMulNode")
    local endWorldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
    local ratio = display.height / display.width
    if ratio >= 768 / 1024 then
        endPos.x = endPos.x - 20
    end
    local speedActionTable = {}
    if num == 1 or num == 2 or num == 4 or num == 5 then
        speedActionTable[#speedActionTable + 1] = cc.Spawn:create(cc.MoveTo:create(0.5, endPos), cc.RotateTo:create(0.5, 0))
    else
        speedActionTable[#speedActionTable + 1] = cc.MoveTo:create(0.5, endPos)
    end
    speedActionTable[#speedActionTable + 1] =
        cc.CallFunc:create(
        function(sender)
            moveLab:runAction(
                cc.Sequence:create(
                    cc.CallFunc:create(
                        function(sender)
                            self.m_winMulNum = self.m_winMulNum + data.value
                            self:showBonusWinMulLab(self.m_winMulNum)
                            sender:removeFromParent()
                            self.m_playMulIndex = self.m_playMulIndex + 1
                            self:playOneMulMove()
                        end
                    )
                )
            )
        end
    )
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_wheel_lab_move.mp3")
    moveLab:runAction(cc.Sequence:create(speedActionTable))
end

--显示乘倍总数
function CodeGameScreenFiestaDeMuertosMachine:showBonusWinMulLab(num)
    local labNum = num .. "X"
    if not self.m_winMulLab then
        self.m_winMulLab = util_createView("CodeFiestaDeMuertosSrc.FiestaDeMuertosWheelLab", "MulLab")
        self.m_winMulLab:setScale(self.m_machineRootScale)
        local endNode = self:findChild("bonusMulNode")
        local endWorldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
        local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
        local ratio = display.height / display.width
        if ratio >= 768 / 1024 then
            endPos.x = endPos.x - 20
        end
        self.m_winMulLab:setPosition(endPos)
        self:addChild(self.m_winMulLab, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 5)
    end
    self.m_winMulLab:setLab(labNum)
    self.m_winMulLab:runCsbAction("diejia")
end

--link乘倍移动到结算弹板
function CodeGameScreenFiestaDeMuertosMachine:playWinMulLabMove()
    local endNode = self.m_bonusWinView:findChild("Node_chengbei")
    local endWorldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
    if self.m_winMulLab then
        gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_bonus_over_jump.mp3")
        gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_wheel_lab_down.mp3")
        self.m_winMulLab:runAction(cc.Sequence:create(cc.MoveTo:create(10 / 30, endPos)))
        self.m_winMulLab:runCsbAction(
            "jiesuan",
            false,
            function()
                self.m_bonusWinView:showWinMulLab(self.m_winMulNum, self.m_machineRootScale)
                self.m_winMulLab:removeFromParent()
                self.m_winMulLab = nil
            end
        )
        self.m_bonusWinView:runCsbAction("chengbei")
    end
end

--结算轮盘赢钱点数
function CodeGameScreenFiestaDeMuertosMachine:playWheelLabWin()
    local isWin, dataList = self:getWinMulOrJackpot(0)
    self.m_labDataList = dataList
    self.m_playLabIndex = 1
    self:playWheelLabCollectEff()
end

function CodeGameScreenFiestaDeMuertosMachine:playWheelLabCollectEff()
    if self.m_playLabIndex > #self.m_labDataList then
        scheduler.performWithDelayGlobal(
            function()
                self:showWheelWinView()
            end,
            15 / 30,
            self:getModuleName()
        )
        return
    end
    local endWorldPos = self.m_bottomUI:getCoinWinNode():getParent():convertToWorldSpace(cc.p(self.m_bottomUI:getCoinWinNode():getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))

    local data = self.m_labDataList[self.m_playLabIndex]
    local _index = data.position + 1
    local lab = self.m_bonusWheel:getWheelLabByIndex(_index)
    lab:runCsbAction("actionframe")
    local startPos = lab:getParent():convertToWorldSpace(cc.p(lab:getPosition()))
    local effectLabel = self:ceateParticleEffect()

    effectLabel:setPosition(startPos.x, startPos.y)
    self:addChild(effectLabel, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_par_collect.mp3")
    effectLabel:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.5, endPos),
            cc.CallFunc:create(
                function(sender)
                    scheduler.performWithDelayGlobal(
                        function()
                            sender:removeFromParent()
                        end,
                        3 / 30,
                        self:getModuleName()
                    )
                    self:playCoinWinEffectUI()
                    local winCoin = data.value * globalData.slotRunData:getCurTotalBet() / 30
                    self.m_nowBottomCoins = self.m_nowBottomCoins + winCoin
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_nowBottomCoins))
                    self.m_playLabIndex = self.m_playLabIndex + 1
                    self:playWheelLabCollectEff()
                end
            )
        )
    )
end

--播放jackpot弹板效果
function CodeGameScreenFiestaDeMuertosMachine:playShowJackpotEff(dataList)
    self.m_jackpotDataList = dataList
    self.m_playJackpotIndex = 1
    self:showOneJackpot()
end

--jackpot 弹板依次显示
function CodeGameScreenFiestaDeMuertosMachine:showOneJackpot()
    if self.m_playJackpotIndex > #self.m_jackpotDataList then
        self:playWheelLabWin()
        return
    end

    local data = self.m_jackpotDataList[self.m_playJackpotIndex]
    local _index = data.position + 1
    local lab = self.m_bonusWheel:getWheelLabByIndex(_index)
    lab:runCsbAction("actionframe")
    local winCoin = data.coins
    scheduler.performWithDelayGlobal(
        function()
            self:showJackpotWin(
                data.name,
                winCoin,
                function()
                    self.m_nowBottomCoins = self.m_nowBottomCoins + winCoin
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_nowBottomCoins))
                    self.m_playJackpotIndex = self.m_playJackpotIndex + 1
                    self:showOneJackpot()
                end
            )
        end,
        40 / 30,
        self:getModuleName()
    )
end
--type = 0 是点数  type = 1 是jackpot
function CodeGameScreenFiestaDeMuertosMachine:getWheelWinCoins()
    local data = self.m_runSpinResultData.p_selfMakeData
    local num = 0
    if data and data.hits then
        for i, v in ipairs(data.hits) do
            local _type = v.type
            if _type == 0 or _type == 1 then
                num = num + v.coins
            end
        end
    end
    return num
end
--bonus 结算界面
function CodeGameScreenFiestaDeMuertosMachine:showWheelWinView()
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_tip_show.mp3")
    local resultData = self.m_runSpinResultData
    local coinsData = {}
    --盘面赢钱
    local allPoint = self:getAllBonusPointNum()
    coinsData.linkCoins = allPoint
    --转盘赢钱
    local wheelWin = self:getWheelWinCoins()
    coinsData.wheelCoins = wheelWin
    --总赢钱
    local totalCoins = resultData.p_bonusWinCoins
    if self.m_winMulNum > 0 then
        totalCoins = coinsData.linkCoins + coinsData.wheelCoins
    end
    coinsData.totalCoins = totalCoins
    self.m_bonusWinView = util_createView("CodeFiestaDeMuertosSrc.FiestaDeMuertosWheelOverView")
    gLobalViewManager:showUI(self.m_bonusWinView)
    if self.m_winMulLab then
        self.m_winMulLab:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_EFFECT)
    end
    self.m_bonusWinView:initViewData(
        coinsData,
        function()
            if self.m_winMulNum > 0 then
                self:playWinMulLabMove()
            else
                self.m_bonusWinView.m_click = false
            end
        end,
        function()
            self:removeBonusWheel()
            self.m_bonusWinView = nil
        end
    )
end

--移除轮盘
function CodeGameScreenFiestaDeMuertosMachine:removeBonusWheel()
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_wheel_over.mp3")
    self.m_bonusWheel:runCsbAction(
        "over",
        false,
        function()
            self:resetMusicBg()
            gLobalSoundManager:setBackgroundMusicVolume(1)
            self:changeJackpotBar(false)
            self.m_bonusWheel:removeFromParent(true)
            self.m_bonusWheel = nil
            local resultData = self.m_runSpinResultData
            local totalCoins = 0
            local bonusWinCoins = 0
            if self.m_bProduceSlots_InFreeSpin == true then
                totalCoins = resultData.p_fsWinCoins
            else
                totalCoins = resultData.p_bonusWinCoins
            end
            globalData.slotRunData.lastWinCoin = totalCoins
            bonusWinCoins = resultData.p_bonusWinCoins
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalCoins))
            if self.m_bProduceSlots_InFreeSpin ~= true then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            end
            local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
            if hasFsOverEffect == false then
                self:checkFeatureOverTriggerBigWin(bonusWinCoins, GameEffect.EFFECT_BONUS)
            end

            self.m_effectData.p_isPlay = true
            self:playGameEffect()
        end
    )
end

--获取bonus对应点数
function CodeGameScreenFiestaDeMuertosMachine:getPointNum(reelsIndex)
    local num = 1
    local points = self.m_runSpinResultData.p_selfMakeData.points
    if points and type(points) == "table" then
        for k, v in pairs(points) do
            local index = tonumber(k)
            if reelsIndex == index then
                num = tonumber(v)
                break
            end
        end
    end
    return num
end

--获取所有bonus上的点数总和
function CodeGameScreenFiestaDeMuertosMachine:getAllBonusPointNum()
    local num = 0
    local points = self.m_runSpinResultData.p_selfMakeData.points
    if points and type(points) == "table" then
        for k, v in pairs(points) do
            num = num + tonumber(v)
        end
    end
    return num
end

--设置最后停止的小块上bonus对应的点数
function CodeGameScreenFiestaDeMuertosMachine:updateReelGridNode(node)
    local isLastSymbol = node.m_isLastSymbol
    local symbolType = node.p_symbolType
    if isLastSymbol == true and (symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2) then
        local row = node.p_rowIndex
        local col = node.p_cloumnIndex
        local reelsIndex = self:getPosReelIdx(row, col)
        local point = self:getPointNum(reelsIndex)
        node:setBonusLabNum(point)
    end
end

--获得服务器bet的jackpot累计值
function CodeGameScreenFiestaDeMuertosMachine:getWheelJackpotList()
    local jackpotList = {}
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if jackpotPools ~= nil and #jackpotPools > 0 then
        for index, poolData in pairs(jackpotPools) do
            local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(poolData, false, totalBet)
            jackpotList[index] = totalScore - baseScore
        end
    end
    return jackpotList
end

function CodeGameScreenFiestaDeMuertosMachine:showJackpotWin(jackPot, coins, func)
    gLobalSoundManager:playSound("FiestaDeMuertosSounds/sound_FiestaDeMuertos_tip_show.mp3")
    local jackPotWinView = util_createView("CodeFiestaDeMuertosSrc.FiestaDeMuertosJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(jackPot, coins, self, func)
end

function CodeGameScreenFiestaDeMuertosMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return true
    elseif symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_3 then
        return true
    end
end

--设置长滚信息
function CodeGameScreenFiestaDeMuertosMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    for col = 1, iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true and col == 5 then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        end
        if globalData.slotRunData.currSpinMode == RESPIN_MODE and col == 5 then
            reelRunData:setReelRunLen(36)
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(self.SYMBOL_BONUS_2, col, bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenFiestaDeMuertosMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column, row, runLen) == symbolType then
            if symbolType == self.SYMBOL_BONUS_2 then
                soundType = runStatus.DUANG
                nextReelLong = true
                bRun = true
                bPlayAni = true
            end
            local bPlaySymbolAnima = bPlayAni

            allSpecicalSymbolNum = allSpecicalSymbolNum + 1

            if bRun == true then
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
                if symbolType == self.SYMBOL_BONUS_2 then
                    soundType = runStatus.DUANG
                    nextReelLong = true
                end
                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)
            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效

                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenFiestaDeMuertosMachine:checkIsInLongRun(col, symbolType)
    local scatterShowCol = self.m_ScatterShowCol

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if scatterShowCol ~= nil then
            if self:getInScatterShowCol(col) then
                return true
            else
                return false
            end
        end
    end

    if symbolType == self.SYMBOL_BONUS_2 then
        return true
    end

    return true
end

--设置bonus scatter 层级
function CodeGameScreenFiestaDeMuertosMachine:getBounsScatterDataZorder(symbolType)
    local order = BaseNewReelMachine.getBounsScatterDataZorder(self, symbolType)
    if symbolType == self.SYMBOL_BONUS_1 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_BONUS_2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 1
    elseif symbolType == self.SYMBOL_BONUS_3 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 2
    end
    return order
end

function CodeGameScreenFiestaDeMuertosMachine:getResNodeSymbolType(parentData)
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    if symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_3 then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8
    end

    return symbolType
end

function CodeGameScreenFiestaDeMuertosMachine:ceateParticleEffect()
    local effectLabel = util_csbCreate("FiestaDeMuertos_collect.csb")
    local particle1 = effectLabel:getChildByName("Particle_1")
    local particle2 = effectLabel:getChildByName("Particle_2")
    particle1:setPositionType(0)
    particle1:setDuration(1)
    particle2:setPositionType(0)
    particle2:setDuration(1)
    return effectLabel
end

function CodeGameScreenFiestaDeMuertosMachine:showRespinView(effectData)
    --先播放动画 再进入respin
    self:clearCurMusicBg()
    self:clearWinLineEffect()
    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true
    effectData.p_isPlay = true
    self:playGameEffect()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
end

function CodeGameScreenFiestaDeMuertosMachine:showRespinOverView(effectData)
    if self.m_bProduceSlots_InFreeSpin == true then
        self:setCurrSpinMode(FREE_SPIN_MODE)
    else
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
    end
    self.m_specialReels = false
    effectData.p_isPlay = true
    self:playGameEffect()
end

function CodeGameScreenFiestaDeMuertosMachine:beginReel()
    self:resetReelDataAfterReel()

    local slotsParents = self.m_slotParents
    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local reelDatas = self:checkUpdateReelDatas(parentData)

        self:checkReelIndexReason(parentData)
        self:resetParentDataReel(parentData)

        self:createSlotNextNode(parentData)
        if globalData.slotRunData.currSpinMode == RESPIN_MODE then
            --respin 前4列不上弹
            if i > 4 and self.m_configData.p_reelBeginJumpTime > 0 then
                self:addJumoActionAfterReel(slotParent, slotParentBig)
            else
                self:registerReelSchedule()
            end
        else
            if self.m_configData.p_reelBeginJumpTime > 0 then
                self:addJumoActionAfterReel(slotParent, slotParentBig)
            else
                self:registerReelSchedule()
            end
        end
        self:checkChangeClipParent(parentData)
    end
    self:checkChangeBaseParent()
    BaseNewReelMachine.beginNewReel(self)
    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        self:showBonusLongRunSymboltoClip()
        self:showBonusLongRunEffect()
        --触发respin后 1-4列不滚动
        for i = 1, 4 do
            self.m_slotParents[i].isReeling = false
            self.m_slotParents[i].isResActionDone = true
        end
        for i = 1, #self.m_reels do
            if globalData.slotRunData.currSpinMode == RESPIN_MODE and i < #self.m_reels then
                self.m_reels[i].m_isReelDone = true
            end
        end
    end
end

function CodeGameScreenFiestaDeMuertosMachine:showBonusLongRunSymboltoClip()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 then
                    targSp = self:setSymbolToClipReel(iCol, iRow, symbolType)
                    if targSp then
                        if symbolType == self.SYMBOL_BONUS_2 then
                            targSp:runAnim("idleframe", true)
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenFiestaDeMuertosMachine:MachineRule_respinTouchSpinBntCallBack()
    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP)
    end
end

function CodeGameScreenFiestaDeMuertosMachine:updateNetWorkData_ReSpin()
    return false
end

function CodeGameScreenFiestaDeMuertosMachine:checkOpearReSpinAndSpecialReels(param)
    return false
end

function CodeGameScreenFiestaDeMuertosMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    if self.m_nowBottomCoins > 0 then
        if self.m_bProduceSlots_InFreeSpin == true then
            self.m_iOnceSpinLastWin = globalData.slotRunData.lastWinCoin - self.m_nowBottomCoins
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop, true, self.m_nowBottomCoins})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenFiestaDeMuertosMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
    if winAmonut == nil then
        return
    end
    -- feature == GameEffect.EFFECT_BONUS 去掉了
    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i = 1, #self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert(self.m_gameEffects, i + 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, i + 2, effectData)
                break
            end
        end
        if isAddEffect == false then
            for i = 1, #self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut

                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert(self.m_gameEffects, i + 1, delayEffect)

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert(self.m_gameEffects, i + 2, effectData)
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert(self.m_gameEffects, 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, 2, effectData)
            end
        end
    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()
end

return CodeGameScreenFiestaDeMuertosMachine
