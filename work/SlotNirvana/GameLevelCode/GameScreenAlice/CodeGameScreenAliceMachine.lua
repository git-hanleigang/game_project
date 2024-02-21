---
-- island li
-- 2019年1月26日
-- CodeGameScreenAliceMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local CodeGameScreenAliceMachine = class("CodeGameScreenAliceMachine", BaseFastMachine)

CodeGameScreenAliceMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenAliceMachine.SYMBOL_SCORE_10 = 9 -- 自定义的小块类型
CodeGameScreenAliceMachine.SYMBOL_SCORE_11 = 10

CodeGameScreenAliceMachine.CHANGE_SYMBOL_2_WILD = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenAliceMachine.COLLECT_RABBIT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识

CodeGameScreenAliceMachine.m_gameInfoMap = {}
CodeGameScreenAliceMachine.m_isLastSpecialGame = nil
CodeGameScreenAliceMachine.m_hideNpcOver = nil
CodeGameScreenAliceMachine.m_idleNpcOver = nil
CodeGameScreenAliceMachine.m_reelRunAnimaBG = nil

CodeGameScreenAliceMachine.ALICE_ANIMATION_TIMES = 3
CodeGameScreenAliceMachine.QUEEN_RUN_SOLDIER_NUM = 15

CodeGameScreenAliceMachine.ALICE_GAME_WEIGHT = {1, 5, 5, 1, 0}
CodeGameScreenAliceMachine.ALICE_GAME_WEIGHT_TOTAL = 12

CodeGameScreenAliceMachine.m_showMapFlag = nil

-- 构造函数
function CodeGameScreenAliceMachine:ctor()
    self.m_reelRunAnimaBG = {}
    BaseFastMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    
    --init
    self:initGame()
end

function CodeGameScreenAliceMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("AliceConfig.csv", "LevelAliceConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenAliceMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Alice"
end

function CodeGameScreenAliceMachine:initUI()
    self.m_reelRunSound = "AliceSounds/sound_Alice_quick_run.mp3"
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_AliceView = util_createView("CodeAliceSrc.AliceView")
    -- self:findChild("xxxx"):addChild(self.m_AliceView)

    self.m_gameMapLayer = util_createView("CodeAliceSrc.AliceMapLayer", self)
    self:addChild(self.m_gameMapLayer, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
    self.m_gameMapLayer:setVisible(false)

    self.m_collectProgress = util_createView("CodeAliceSrc.AliceCollectProgress", self)
    self:findChild("progress"):addChild(self.m_collectProgress)

    self.m_npcQueen = util_spineCreate("Alice_queen", true, true)
    self:findChild("Node_queen"):addChild(self.m_npcQueen)
    self:showQueenAnmation()

    self.m_npcAlice = util_spineCreate("Alice_alice", true, true)
    self:findChild("Node_alice"):addChild(self.m_npcAlice)
    self:showAliceAnmation()

    self.m_npcAliceHeart = util_spineCreate("Alice_alice_hongxin", true, true)
    self:findChild("Node_alice_heart"):addChild(self.m_npcAliceHeart)
    self.m_npcAliceHeart:setVisible(false)

    self.m_npcMagic = util_spineCreate("Alice_maozi", true, true)
    self:findChild("Node_magic"):addChild(self.m_npcMagic)
    self:showMagicAnmation()

    self.m_nodeMagicHat = util_createView("CodeAliceSrc.AliceMagicHat")
    self:findChild("Node_magic"):addChild(self.m_nodeMagicHat)
    self.m_nodeMagicHat:setPosition(-219, 80)
    self.m_nodeMagicHat:setVisible(false)

    self.m_shadeLayer = self:findChild("shade")
    self.m_shadeLayer:setVisible(false)
    self.m_shadeLayer:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    self.m_shadeLayer:setOpacity(0)

    self:creatReelAliceAnimation()
    self:hideNpcGameBg()

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
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
            elseif winRate > 3 then
                soundIndex = 3
            end
            gLobalSoundManager:setBackgroundMusicVolume(0.4)
            local soundName = "AliceSounds/sound_Alice_last_win_" .. soundIndex .. ".mp3"
            local winSoundsId =
                gLobalSoundManager:playSound(
                soundName,
                false,
                function()
                    gLobalSoundManager:setBackgroundMusicVolume(1)
                end
            )
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenAliceMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = "AliceSounds/sound_Alice_scatter_down" .. i .. ".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenAliceMachine:scaleMainLayer()
    BaseFastMachine.scaleMainLayer(self)
    local ratio = display.height / display.width
    if ratio >= 768 / 1024 then
        local mainScale = 0.85
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
        local mainScale = 0.9 - 0.05 * ((ratio - 640 / 960) / (768 / 1024 - 640 / 960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

function CodeGameScreenAliceMachine:hideNpcGameBg()
    self.m_gameBg:findChild("alice_bg"):setVisible(false)
    self.m_gameBg:findChild("queen_bg"):setVisible(false)
    self.m_gameBg:findChild("magic_bg"):setVisible(false)
end

function CodeGameScreenAliceMachine:showAliceAnmation(hideFlag)
    if self.m_isLastSpecialGame ~= nil and self.m_aliceIdleCall ~= nil then
        if hideFlag == nil then
            self.m_idleNpcOver = true
        end
        if self.m_hideNpcOver == true and self.m_idleNpcOver then
            self.m_aliceIdleCall()
            self.m_aliceIdleCall = nil
            self.m_hideNpcOver = false
            self.m_idleNpcOver = false
        end
    else
        util_spinePlay(self.m_npcAlice, "idle", false)
        util_spineEndCallFunc(
            self.m_npcAlice,
            "idle",
            function()
                -- if self.m_aliceIdleCall ~= nil and self.m_isLastSpecialGame == nil then
                --     self.m_aliceIdleCall()
                --     self.m_aliceIdleCall = nil
                -- else
                self:showAliceAnmation()
                -- end
            end
        )
    end
end

function CodeGameScreenAliceMachine:showQueenAnmation(hideFlag)
    if self.m_isLastSpecialGame ~= nil and self.m_queenIdleCall ~= nil then
        if hideFlag == nil then
            self.m_idleNpcOver = true
        end
        if self.m_hideNpcOver == true and self.m_idleNpcOver then
            self.m_queenIdleCall()
            self.m_queenIdleCall = nil
            self.m_hideNpcOver = false
            self.m_idleNpcOver = false
        end
    else
        util_spinePlay(self.m_npcQueen, "idle", false)
        util_spineEndCallFunc(
            self.m_npcQueen,
            "idle",
            function()
                -- if self.m_queenIdleCall ~= nil then
                --     self.m_queenIdleCall()
                --     self.m_queenIdleCall = nil
                -- else
                self:showQueenAnmation()
                -- end
            end
        )
    end
end

function CodeGameScreenAliceMachine:showMagicAnmation(hideFlag)
    if self.m_isLastSpecialGame ~= nil and self.m_magicIdleCall ~= nil then
        if hideFlag == nil then
            self.m_idleNpcOver = true
        end
        if self.m_hideNpcOver == true and self.m_idleNpcOver then
            self.m_magicIdleCall()
            self.m_magicIdleCall = nil
            self.m_hideNpcOver = false
            self.m_idleNpcOver = false
        end
    else
        util_spinePlay(self.m_npcMagic, "idle", false)
        util_spineEndCallFunc(
            self.m_npcMagic,
            "idle",
            function()
                -- if self.m_magicIdleCall ~= nil then
                --     self.m_magicIdleCall()
                --     self.m_magicIdleCall = nil
                -- else
                self:showMagicAnmation()
                -- end
            end
        )
    end
end

function CodeGameScreenAliceMachine:normalBgmControl()
    self:resetMusicBg()
    self:reelsDownDelaySetMusicBGVolume()
end

function CodeGameScreenAliceMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            if
                self.m_gameInfoMap ~= nil and self.m_gameInfoMap.initPosition ~= nil and self.m_gameInfoMap.triggerBonusGame ~= true and self.m_gameInfoMap.triggerWheel ~= true and
                    self.m_showMapFlag ~= true
             then
                gLobalSoundManager:playSound("AliceSounds/sound_Alice_enter.mp3")
            end

            scheduler.performWithDelayGlobal(
                function()
                    if
                        self.m_gameInfoMap ~= nil and self.m_gameInfoMap.initPosition ~= nil and self.m_gameInfoMap.triggerBonusGame ~= true and self.m_gameInfoMap.triggerWheel ~= true and
                            self.m_showMapFlag ~= true
                     then
                        self:normalBgmControl()
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

function CodeGameScreenAliceMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    if self.m_gameInfoMap == nil or self.m_gameInfoMap.initPosition == nil then
        self.m_bChooseGame = true
        self:showGameMap(nil, true)
        self.m_gameMapLayer:initIconBeforeGame()
    else
        self.m_collectProgress:initProgress(self.m_gameInfoMap)
        self.m_gameMapLayer:initMapUI(self.m_gameInfoMap)

        if self.m_gameInfoMap.triggerBonusGame then
            self.m_gameMapLayer:setVisible(true)
            self.m_gameMapLayer:reconnetBonusGame(self.m_gameInfoMap, self.m_initFeatureData)
        elseif self.m_gameInfoMap.triggerWheel then
            self.m_gameMapLayer:setVisible(true)
            self.m_gameMapLayer:reconnetWheel(self.m_gameInfoMap)
        end
    end
end

function CodeGameScreenAliceMachine:addObservers()
    BaseFastMachine.addObservers(self)
end

function CodeGameScreenAliceMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    for i, v in pairs(self.m_reelRunAnimaBG) do
        local reelNode = v[1]
        local reelAct = v[2]
        if reelNode:getParent() ~= nil then
            reelNode:removeFromParent()
        end

        reelNode:release()
        reelAct:release()

        self.m_reelRunAnimaBG[i] = v
    end

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenAliceMachine:clickProgress()
    if
        self.m_bProduceSlots_InFreeSpin == true or (self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE) or
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or
            self:getCurrSpinMode() == AUTO_SPIN_MODE
     then
        return
    end

    self:showGameMap()
end

function CodeGameScreenAliceMachine:showGameMap(func, isQuiet)
    if isQuiet ~= true then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_map_appear.mp3")
    end
    self.m_currentMusicBgName = "AliceSounds/music_Alice_map_bg.mp3"
    gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)

    if func == nil then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
    self.m_gameMapLayer:setVisible(true)
    self.m_gameMapLayer:showGameMap(func, self.m_gameInfoMap)

    self.m_showMapFlag = true
    self:removeSoundHandler()
    gLobalSoundManager:setBackgroundMusicVolume(1)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenAliceMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Alice_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_Alice_11"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenAliceMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenAliceMachine:MachineRule_initGame()
end

-- bonus小游戏断线重连
function CodeGameScreenAliceMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" then
        self:playGameEffect()
        return
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenAliceMachine:slotOneReelDown(reelCol)
    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end
    BaseFastMachine.slotOneReelDown(self, reelCol)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenAliceMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal_fs")
    self:runCsbAction(
        "animation0",
        false,
        function()
            self:runCsbAction("idle2")
        end
    )
    self.m_collectProgress:setVisible(false)
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenAliceMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "fs_normal")
    self:runCsbAction(
        "animation1",
        false,
        function()
            self:runCsbAction("idle1")
        end
    )
end
---------------------------------------------------------------------------

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenAliceMachine:showFreeSpinView(effectData)
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_pop_window.mp3")

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            )
            performWithDelay(
                self,
                function()
                    self.m_collectProgress:setVisible(false)
                end,
                0.5
            )
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        0.5
    )
end

function CodeGameScreenAliceMachine:showFreeSpinOverView()
    local fsOverView = function()
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_fs_over.mp3")
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound("AliceSounds/sound_Alice_pop_window.mp3")

                local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
                local view =
                    self:showFreeSpinOver(
                    strCoins,
                    self.m_runSpinResultData.p_freeSpinsTotalCount,
                    function()
                        self:triggerFreeSpinOverCallFun()
                    end
                )
                local node = view:findChild("m_lb_coins")
                view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)

                performWithDelay(
                    self,
                    function()
                        self.m_collectProgress:setVisible(true)
                    end,
                    0.5
                )
            end,
            1.5
        )
    end

    if self.m_isLastSpecialGame ~= nil then
        self:resetNpcPos()
        performWithDelay(
            self,
            function()
                fsOverView()
                self.m_isLastSpecialGame = nil
            end,
            0.8
        )
    else
        fsOverView()
    end
end

function CodeGameScreenAliceMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                lineNode:removeFromParent()
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                preParent:addChild(lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:runIdleAnim()
            -- lineNode:runAnim("idleframe2")
            end
        end
    end
end

function CodeGameScreenAliceMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(
        function()
            -- self:resetMaskLayerNodes()
            callFun()
        end,
        util_max(2, animTime),
        self:getModuleName()
    )
end

function CodeGameScreenAliceMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        local animName = slotNode:getLineAnimName()
        slotNode:runAnim(animName)
    end
    return slotNode
end

function CodeGameScreenAliceMachine:resetNpcPos()
    if self.m_isLastSpecialGame == "alice" then
        util_spinePlay(self.m_npcQueen, "start")
        util_spineEndCallFunc(
            self.m_npcQueen,
            "start",
            function()
                self:showQueenAnmation()
            end
        )

        util_spinePlay(self.m_npcMagic, "start")
        util_spineEndCallFunc(
            self.m_npcMagic,
            "start",
            function()
                self:showMagicAnmation()
            end
        )
    end

    if self.m_isLastSpecialGame == "queen" then
        util_spinePlay(self.m_npcAlice, "start")
        util_spineEndCallFunc(
            self.m_npcAlice,
            "start",
            function()
                self:showAliceAnmation()
            end
        )

        util_spinePlay(self.m_npcMagic, "start")
        util_spineEndCallFunc(
            self.m_npcMagic,
            "start",
            function()
                self:showMagicAnmation()
            end
        )
    end

    if self.m_isLastSpecialGame == "magic" then
        self.m_nodeMagicHat:setVisible(false)
        self.m_nodeMagicHat:hideSymbol(
            function()
                util_spinePlay(self.m_npcMagic, "actionframe2")
                util_spineEndCallFunc(
                    self.m_npcMagic,
                    "actionframe2",
                    function()
                        util_spinePlay(self.m_npcAlice, "start")
                        util_spineEndCallFunc(
                            self.m_npcAlice,
                            "start",
                            function()
                                self:showAliceAnmation()
                            end
                        )

                        util_spinePlay(self.m_npcQueen, "start")
                        util_spineEndCallFunc(
                            self.m_npcQueen,
                            "start",
                            function()
                                self:showQueenAnmation()
                            end
                        )

                        self:showMagicAnmation()
                    end
                )
            end
        )
    end

    if self.m_isLastSpecialGame ~= nil then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_npc_appear.mp3")
        if self.m_bProduceSlots_InFreeSpin == true then
            gLobalNoticManager:postNotification(
                ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,
                {
                    "play_fs",
                    false,
                    function()
                        self:hideNpcGameBg()
                    end
                }
            )
        else
            gLobalNoticManager:postNotification(
                ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,
                {
                    "play_normal",
                    false,
                    function()
                        self:hideNpcGameBg()
                    end
                }
            )
        end
        self:resetMusicBg()
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenAliceMachine:MachineRule_SpinBtnCall()
    self:removeSoundHandler()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    self:resetNpcPos()

    return false -- 用作延时点击spin调用
end

function CodeGameScreenAliceMachine:requestSpinResult()
    local delayTime = 0
    if self.m_isLastSpecialGame ~= nil then
        delayTime = 2
        if self.m_isLastSpecialGame == "magic" then
            delayTime = 3
        end
        self.m_isLastSpecialGame = nil
    end
    performWithDelay(
        self,
        function()
            BaseSlotoManiaMachine.requestSpinResult(self)
        end,
        delayTime
    )
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenAliceMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenAliceMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenAliceMachine:addSelfEffect()
    if
        self.m_runSpinResultData.p_selfMakeData.replaceMysterySignal == nil and self.m_runSpinResultData.p_selfMakeData.replaceColumns == nil and
            self.m_runSpinResultData.p_selfMakeData.replacePositions == nil and
            self.m_bProduceSlots_InFreeSpin ~= true
     then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node then
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                        if not self.m_collectList then
                            self.m_collectList = {}
                        end
                        self.m_collectList[#self.m_collectList + 1] = node
                    end
                end
            end
        end
    end

    if self.m_collectList and #self.m_collectList > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_RABBIT
    end

    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.replaceMysterySignal ~= nil then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CHANGE_SYMBOL_2_WILD -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenAliceMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.CHANGE_SYMBOL_2_WILD then
        self:changeSymbol2Wild(effectData)
    elseif effectData.p_selfEffectType == self.COLLECT_RABBIT then
        self:collectRabbit(effectData)
    end

    return true
end

function CodeGameScreenAliceMachine:changeSymbol2Wild(effectData)
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_magic_change_wild.mp3")
    local changeType = self.m_runSpinResultData.p_selfMakeData.replaceMysterySignal
    for iRow = 1, self.m_iReelRowNum, 1 do
        for iCol = 1, self.m_iReelColumnNum, 1 do
            if self.m_stcValidSymbolMatrix[iRow][iCol] == changeType then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                local wild = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                local slotParent = targSp:getParent()
                local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
                local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                self.m_clipParent:addChild(wild, REEL_SYMBOL_ORDER.REEL_ORDER_3, targSp:getTag())
                wild:setPosition(pos.x, pos.y)
                wild.p_cloumnIndex = targSp.p_cloumnIndex
                wild.p_rowIndex = targSp.p_rowIndex
                wild.m_isLastSymbol = targSp.m_isLastSymbol
                wild.m_showOrder = targSp.m_showOrder
                wild.p_layerTag = targSp.p_layerTag
                local columnData = self.m_reelColDatas[wild.p_cloumnIndex]
                wild.p_slotNodeH = columnData.p_showGridH
                local linePos = {}
                linePos[#linePos + 1] = {iX = iRow, iY = iCol}
                wild:setTag(self:getNodeTag(wild.p_cloumnIndex, wild.p_rowIndex, SYMBOL_NODE_TAG))
                wild.m_bInLine = true
                wild:setLinePos(linePos)
                wild:setVisible(false)

                local effect = util_spineCreate("Socre_Alice_Wild2", true, true)
                self.m_clipParent:addChild(effect, REEL_SYMBOL_ORDER.REEL_ORDER_3 + 1)
                effect:setPosition(pos.x, pos.y)
                util_spinePlay(effect, "actionframe_guang1")
                util_spineEndCallFunc(
                    effect,
                    "actionframe_guang1",
                    function()
                        wild:setVisible(true)
                        effect:setVisible(false)
                        performWithDelay(
                            self,
                            function()
                                effect:removeFromParent()
                            end,
                            0.1
                        )
                    end
                )

                performWithDelay(
                    self,
                    function()
                        util_setCascadeOpacityEnabledRescursion(targSp, true)
                        targSp:runAction(cc.FadeOut:create(0.3))
                    end,
                    1
                )
            end
        end
    end
    performWithDelay(
        self,
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        2
    )
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenAliceMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenAliceMachine:initGameStatusData(gameData)
    if gameData.gameConfig.extra ~= nil then
        self.m_gameInfoMap = gameData.gameConfig.extra.map
    end
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end

function CodeGameScreenAliceMachine:initCloumnSlotNodesByNetData()
    if self.m_initSpinData.p_reels == nil then
        if globalData.GameConfig:checkSelectBet() then
            local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            if questConfig and questConfig.m_IsQuestLogin then
                --quest进入也使用服务器bet
            else
                if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest() then
                    --quest进入也使用服务器bet
                else
                    self.m_initBetId = -1
                end
            end
        end
        self:checkUpateDefaultBet()
        -- 直接使用 关卡bet 选择界面的bet 来使用
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
        self:initRandomSlotNodes()
    else
        BaseFastMachine.initCloumnSlotNodesByNetData(self)
    end
end

----
--- 处理spin 成功消息
--
function CodeGameScreenAliceMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" and self.m_bChooseGame ~= true and self.m_haveWheel ~= true then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end

    self.m_gameInfoMap = spinData.result.selfData.map
    if self.m_bChooseGame == true then
        self.m_bChooseGame = false
        self.m_gameMapLayer:openGameEffect(true, self.m_gameInfoMap)
    end

    if self.m_haveWheel == true then
        local index = spinData.result.selfData.select + 1
        self.m_wheelView:initCallBack(
            function()
                if index == 1 then
                    gLobalSoundManager:setBackgroundMusicVolume(1)
                end
                self.m_haveWheel = false
                self.m_wheelView:removeFromParent()
                self.m_wheelView = nil
                self.m_gameMapLayer:wheelRotationOver(self.m_gameInfoMap, index)
                self.m_collectProgress:initProgress(self.m_gameInfoMap)
            end
        )
        self.m_wheelView:wheelResultCallFun(index)
    end
end

function CodeGameScreenAliceMachine:updateNetWorkData()
    local delayTime = 0
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.replaceColumns ~= nil then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_npc_disappear.mp3")
        util_spinePlay(self.m_npcQueen, "over", false)
        util_spinePlay(self.m_npcMagic, "over", false)
        util_spineEndCallFunc(
            self.m_npcMagic,
            "over",
            function()
                self.m_hideNpcOver = true
                self:showAliceAnmation(true)
            end
        )

        self.m_isLastSpecialGame = "alice"
        self.m_aliceIdleCall = function()
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_alice_kiss.mp3")
            util_spinePlay(self.m_npcAlice, "actionframe", false)
            self.m_npcAliceHeart:setVisible(true)
            util_spinePlay(self.m_npcAliceHeart, "actionframe", false)
            util_spineEndCallFunc(
                self.m_npcAlice,
                "actionframe",
                function()
                    self:showAliceAnmation()
                    self.m_npcAliceHeart:setVisible(false)
                    self:triggerAliceGame()
                end
            )
        end
    elseif self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.replacePositions ~= nil then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_npc_disappear.mp3")
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_queen_magic.mp3")
        util_spinePlay(self.m_npcAlice, "over", false)
        util_spinePlay(self.m_npcMagic, "over", false)
        util_spineEndCallFunc(
            self.m_npcMagic,
            "over",
            function()
                self.m_hideNpcOver = true
                self:showQueenAnmation(true)
            end
        )
        self.m_isLastSpecialGame = "queen"
        self.m_queenIdleCall = function()
            util_spinePlay(self.m_npcQueen, "actionframe", false)
            util_spineEndCallFunc(
                self.m_npcQueen,
                "actionframe",
                function()
                    self:showQueenAnmation()
                    self:triggerQueenGame()
                end
            )
        end
    elseif self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.replaceMysterySignal ~= nil then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_npc_disappear.mp3")
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_magic.mp3")
        util_spinePlay(self.m_npcAlice, "over", false)
        util_spinePlay(self.m_npcQueen, "over", false)
        util_spineEndCallFunc(
            self.m_npcQueen,
            "over",
            function()
                self.m_hideNpcOver = true
                self:showMagicAnmation(true)
            end
        )
        self.m_isLastSpecialGame = "magic"
        self.m_magicIdleCall = function()
            util_spinePlay(self.m_npcMagic, "actionframe", false)
            util_spineEndCallFunc(
                self.m_npcMagic,
                "actionframe",
                function()
                    util_spinePlay(self.m_npcMagic, "idle2", true)
                    self:triggerMagicGame()
                end
            )
        end
    else
        BaseSlotoManiaMachine.updateNetWorkData(self)
    end
    if self.m_isLastSpecialGame ~= nil then
        self.m_gameBg:findChild(self.m_isLastSpecialGame .. "_bg"):setVisible(true)
        if self.m_bProduceSlots_InFreeSpin == true then
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "fs_play")
        else
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal_play")
        end
        self:removeSoundHandler()
        gLobalSoundManager:setBackgroundMusicVolume(1)
        self.m_currentMusicBgName = "AliceSounds/music_Alice_" .. self.m_isLastSpecialGame .. "_game.mp3"
        gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
    end

    -- scheduler.performWithDelayGlobal(function()
    --     BaseSlotoManiaMachine.updateNetWorkData(self)
    -- end, delayTime, self:getModuleName())
end

function CodeGameScreenAliceMachine:getRandColNum()
    local random = util_random(1, self.ALICE_GAME_WEIGHT_TOTAL)
    local col = 1
    local preValue = 0
    for i = 1, #self.ALICE_GAME_WEIGHT, 1 do
        preValue = preValue + self.ALICE_GAME_WEIGHT[i]
        if random <= preValue then
            col = i
            break
        end
    end
    return col
end

function CodeGameScreenAliceMachine:triggerAliceGame()
    self.m_shadeLayer:setVisible(true)
    self.m_shadeLayer:runAction(cc.FadeIn:create(0.5))
    for i = 1, self.ALICE_ANIMATION_TIMES, 1 do
        performWithDelay(
            self,
            function()
                local randomColNum = self:getRandColNum()
                local vecCol = {1, 2, 3, 4, 5}
                if i == self.ALICE_ANIMATION_TIMES then
                    vecCol = self.m_runSpinResultData.p_selfMakeData.replaceColumns
                    self:hideReelAliceEffect()
                    for col = 1, #vecCol, 1 do
                        self:showReelAliceEffect(vecCol[col])
                        if col == #vecCol then
                            performWithDelay(
                                self,
                                function()
                                    if self.m_shadeLayer:isVisible() == true then
                                        self.m_shadeLayer:runAction(
                                            cc.Sequence:create(
                                                cc.FadeOut:create(0.5),
                                                cc.CallFunc:create(
                                                    function()
                                                        self.m_shadeLayer:setVisible(false)
                                                    end
                                                )
                                            )
                                        )
                                    end
                                    self:hideReelAliceEffect()
                                    self:changeColWild()
                                end,
                                0.5
                            )
                            performWithDelay(
                                self,
                                function()
                                    BaseSlotoManiaMachine.updateNetWorkData(self)
                                end,
                                0.5
                            )
                        end
                    end
                else
                    self:hideReelAliceEffect()
                    while randomColNum > 0 do
                        local index = math.random(1, #vecCol)
                        local col = vecCol[index]
                        table.remove(vecCol, index)
                        self:showReelAliceEffect(col)
                        randomColNum = randomColNum - 1
                    end
                end
            end,
            (i - 1) * 0.5
        )
    end
end

function CodeGameScreenAliceMachine:changeColWild()
    local vecCol = self.m_runSpinResultData.p_selfMakeData.replaceColumns
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_change_wild.mp3")
    for i = 1, #vecCol, 1 do
        local col = vecCol[i]
        for row = 1, self.m_iReelRowNum, 1 do
            local pos = {iX = row, iY = col}
            local nodePos = self:getClipParentPos(pos)
            local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
            local symbol = self:getSlotNodeBySymbolType(symbolType)
            self.m_clipParent:addChild(symbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 10)
            symbol:setPosition(nodePos)
            symbol.p_cloumnIndex = pos.iY
            symbol.p_rowIndex = pos.iX
            symbol.m_isLastSymbol = true
            local linePos = {}
            linePos[#linePos + 1] = {iX = symbol.p_rowIndex, iY = symbol.p_cloumnIndex}
            symbol:setTag(self:getNodeTag(symbol.p_cloumnIndex, symbol.p_rowIndex, SYMBOL_NODE_TAG))
            symbol.m_bInLine = true
            symbol:setLinePos(linePos)
            symbol:runAnim("actionframe_guang2")
        end
    end
end

function CodeGameScreenAliceMachine:showReelAliceEffect(col)
    self.m_reelAliceAnima[col]:setVisible(true)
end

function CodeGameScreenAliceMachine:hideReelAliceEffect()
    if self.m_reelAliceAnima ~= nil then
        for reelCol = 1, #self.m_reelAliceAnima, 1 do
            local reelEffectNode = self.m_reelAliceAnima[reelCol]

            if reelEffectNode ~= nil then
                reelEffectNode:setVisible(false)
            end
        end
    end
end

function CodeGameScreenAliceMachine:creatReelAliceAnimation()
    if self.m_reelAliceAnima == nil then
        self.m_reelAliceAnima = {}
    end

    local csbName = "Alice_Wild_hongxin.csb"

    for col = 1, self.m_iReelColumnNum, 1 do
        local reelEffectNode, effectAct = util_csbCreate(csbName)
        self.m_slotEffectLayer:addChild(reelEffectNode)
        self.m_reelAliceAnima[col] = reelEffectNode
        reelEffectNode:setVisible(false)
        self:setLongAnimaInfo(reelEffectNode, col)
        util_csbPlayForKey(effectAct, "actionframe", true)
    end
end

function CodeGameScreenAliceMachine:triggerQueenGame()
    self.m_shadeLayer:setVisible(true)
    self.m_shadeLayer:runAction(cc.FadeIn:create(0.5))
    local animationTotalTime = 0
    local distance = 100
    local pos = self:getRowAndColByPos(0)
    local iX = 90
    local iY = self.m_SlotNodeH * (pos.iX - 0.5)
    local colNodeName = "sp_reel_" .. (pos.iY - 1)
    local reel = self:findChild(colNodeName)
    local reelPos = cc.p(iX, iY)
    local worldPos = reel:convertToWorldSpace(reelPos)

    worldPos.y = worldPos.y - self.m_SlotNodeH * 0.5
    local vecY = {worldPos.y - self.m_SlotNodeH * 2, worldPos.y - self.m_SlotNodeH, worldPos.y}
    local soldierX = display.width + distance
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_soldier_run.mp3")
    local vecPos = self.m_runSpinResultData.p_selfMakeData.replacePositions
    local speed = 500
    for i = 1, #vecPos, 1 do
        local index = vecPos[i]
        local delayTime = math.random(0, 9) * 0.15
        local pos = self:getRowAndColByPos(index)
        local soldier = util_spineCreate("Alice_queen_xiaobing", true, true)
        self:addChild(soldier, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        soldier:setPosition(soldierX, vecY[pos.iX])
        animationTotalTime = math.max(animationTotalTime, delayTime)
        performWithDelay(
            self,
            function()
                local iX = 90
                local iY = self.m_SlotNodeH * (pos.iX - 0.5)
                local colNodeName = "sp_reel_" .. (pos.iY - 1)
                local reel = self:findChild(colNodeName)
                local reelPos = cc.p(iX, iY - self.m_SlotNodeH * 0.5)
                local worldPos = reel:convertToWorldSpace(reelPos)
                util_spinePlay(soldier, "actionframe", true)
                local runTime = cc.pGetDistance(worldPos, cc.p(soldierX, vecY[pos.iX])) / speed
                local moveTo = cc.MoveTo:create(runTime, worldPos)
                soldier:runAction(
                    cc.Sequence:create(
                        moveTo,
                        cc.CallFunc:create(
                            function()
                                performWithDelay(
                                    self,
                                    function()
                                        self:changePosWild(pos)
                                        soldier:removeFromParent()
                                    end,
                                    0.2
                                )
                            end
                        )
                    )
                )
            end,
            delayTime
        )
    end
    for i = #vecPos + 1, self.QUEEN_RUN_SOLDIER_NUM, 1 do
        local delayTime = math.random(0, 9) * 0.12
        local soldier = util_spineCreate("Alice_queen_xiaobing", true, true)
        self:addChild(soldier, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        soldier:setPosition(soldierX, vecY[math.random(1, 3)])
        animationTotalTime = math.max(animationTotalTime, delayTime)
        performWithDelay(
            self,
            function()
                local worldPos = cc.p(-distance, soldier:getPositionY())
                util_spinePlay(soldier, "actionframe", true)
                local runTime = cc.pGetDistance(worldPos, cc.p(soldierX, vecY[pos.iX])) / speed
                local moveTo = cc.MoveTo:create(runTime, worldPos)
                soldier:runAction(
                    cc.Sequence:create(
                        moveTo,
                        cc.CallFunc:create(
                            function()
                                soldier:removeFromParent()
                            end
                        )
                    )
                )
            end,
            delayTime
        )
    end
    animationTotalTime = animationTotalTime + (display.width + distance * 2) / speed
    performWithDelay(
        self,
        function()
            self.m_shadeLayer:runAction(
                cc.Sequence:create(
                    cc.FadeOut:create(0.5),
                    cc.CallFunc:create(
                        function()
                            self.m_shadeLayer:setVisible(false)
                        end
                    )
                )
            )
            BaseSlotoManiaMachine.updateNetWorkData(self)
        end,
        animationTotalTime
    )
end

function CodeGameScreenAliceMachine:changePosWild(pos)
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_change_wild.mp3")
    local nodePos = self:getClipParentPos(pos)
    local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    local symbol = self:getSlotNodeBySymbolType(symbolType)
    self.m_clipParent:addChild(symbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 10)
    symbol:setPosition(nodePos)
    symbol.p_cloumnIndex = pos.iY
    symbol.p_rowIndex = pos.iX
    symbol.m_isLastSymbol = true
    local linePos = {}
    linePos[#linePos + 1] = {iX = symbol.p_rowIndex, iY = symbol.p_cloumnIndex}
    symbol:setTag(self:getNodeTag(symbol.p_cloumnIndex, symbol.p_rowIndex, SYMBOL_NODE_TAG))
    symbol.m_bInLine = true
    symbol:setLinePos(linePos)
    symbol:runAnim("actionframe_guang2")
    -- self.m_vecExtraWild[#self.m_vecExtraWild + 1] = symbol
end

function CodeGameScreenAliceMachine:triggerMagicGame()
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_magic_symbol_change.mp3")
    self.m_nodeMagicHat:setVisible(true)
    self.m_nodeMagicHat:showMagicAnimation(
        self.m_runSpinResultData.p_selfMakeData.replaceMysterySignal,
        function()
            BaseSlotoManiaMachine.updateNetWorkData(self)
        end
    )
end

function CodeGameScreenAliceMachine:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)
    self:hideReelAliceEffect()
    -- self:checkTriggerOrInSpecialGame(function(  )
    --     self:reelsDownDelaySetMusicBGVolume( )
    -- end)
end

function CodeGameScreenAliceMachine:playEffectNotifyNextSpinCall()
    BaseMachineGameEffect.playEffectNotifyNextSpinCall(self)

    if self.m_isLastSpecialGame ~= nil then
        return
    end

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenAliceMachine:getClipParentPos(pos)
    local iX = 90
    local iY = self.m_SlotNodeH * (pos.iX - 0.5)
    local colNodeName = "sp_reel_" .. (pos.iY - 1)
    local reel = self:findChild(colNodeName)
    local reelPos = cc.p(iX, iY)
    local worldPos = reel:convertToWorldSpace(reelPos)
    local nodePos = self.m_clipParent:convertToNodeSpace(worldPos)

    return nodePos
end

function CodeGameScreenAliceMachine:collectRabbit(effectData)
    local mapData =  self.m_runSpinResultData.p_selfMakeData.map
    --数据不存在
    if not mapData then 
        effectData.p_isPlay = true
        self:playGameEffect()
        return
    end
    local endPos = self.m_collectProgress:getCollectEndPos()
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_rabbit_fly.mp3")
    local isTriggerBonus = self.m_runSpinResultData.p_selfMakeData.map.triggerWheel or self.m_runSpinResultData.p_selfMakeData.map.triggerBonusGame
    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))

        -- local startPos = node:getParent():convertToWorldSpace(node:getPosition())
        -- local newStartPos = self:convertToNodeSpace(startPos)
        -- local coins = cc.ParticleSystemQuad:create("Effect/GoldExpress_Bonus_Trail.plist")
        -- node:runAnim("shouji",false,function()
        -- end)
        local coins, act = util_csbCreate("Alice_progress_tuzi.csb")

        local isLastSymbol = coins.m_isLastSymbol
        if i == 1 then
            isLastSymbol = true
        end
        coins.m_isLastSymbol = isLastSymbol
        self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        -- coins:setScale(self.m_machineRootScale)
        coins:setPosition(startPos)

        util_csbPlayForKey(act, "animation", false)
        performWithDelay(
            self,
            function()
                if isTriggerBonus ~= true and isLastSymbol == true then
                    performWithDelay(
                        self,
                        function()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end,
                        0
                    )
                end
            end,
            0.2
        )
        -- coins:runAnim("shouji")

        scheduler.performWithDelayGlobal(
            function()
                -- local pecent = self:getProgressPercent()
                local collectNum = self.m_runSpinResultData.p_selfMakeData.map.collectSignalNum
                local maxNum = self.m_runSpinResultData.p_selfMakeData.map.max
                local bez = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
                local callback = function()
                    coins:removeFromParent()
                    gLobalSoundManager:playSound("AliceSounds/sound_Alice_rabbit_down.mp3")
                    if isLastSymbol == true then
                        self.m_collectProgress:updatePercent(
                            collectNum,
                            maxNum,
                            function()
                                if isTriggerBonus == true and isLastSymbol == true then
                                    -- gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_collectfull.mp3")
                                    self.m_collectProgress:completedAnim(
                                        function()
                                            performWithDelay(
                                                self,
                                                function()
                                                    self:showGameMap(
                                                        function()
                                                            effectData.p_isPlay = true
                                                            self:playGameEffect()
                                                        end
                                                    )
                                                end,
                                                1
                                            )
                                        end
                                    )
                                end
                            end
                        )
                    end
                end
                coins:runAction(cc.Sequence:create(bez, cc.CallFunc:create(callback)))
            end,
            0.2,
            self:getModuleName()
        )
        table.remove(self.m_collectList, i)
    end
end

function CodeGameScreenAliceMachine:getProgressPercent()
    local percent = self.m_runSpinResultData.p_selfMakeData.map.collectSignalNum * 100 / self.m_runSpinResultData.p_selfMakeData.map.max
    return percent
end

function CodeGameScreenAliceMachine:showWheel()
    self.m_haveWheel = true
    self.m_wheelView = util_createView("CodeAliceSrc.AliceWheelView", self.m_gameInfoMap.wheel)
    self.m_gameMapLayer:findChild("windows"):addChild(self.m_wheelView)
    self.m_wheelView:setPosition(-display.width * 0.5, -display.height * 0.5)
end

function CodeGameScreenAliceMachine:updateGameIcon()
    self.m_collectProgress:updateGameIcon(self.m_gameInfoMap)
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenAliceMachine:showEffect_Bonus(effectData)
    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

function CodeGameScreenAliceMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    self:setLongAnimaInfo(reelEffectNode, col)

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    local reelEffectNodeBG = nil
    local reelActBG = nil
    if self.m_reelRunAnimaBG[col] == nil then
        reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
    else
        local reelBGObj = self.m_reelRunAnimaBG[col]

        reelEffectNodeBG = reelBGObj[1]
        reelActBG = reelBGObj[2]
    end

    reelEffectNodeBG:setScaleX(1)
    reelEffectNodeBG:setScaleY(1)

    if self.m_bProduceSlots_InFreeSpin == true then
        util_getChildByName(reelEffectNodeBG, "normal"):setVisible(false)
        util_getChildByName(reelEffectNodeBG, "fs"):setVisible(true)
    else
        util_getChildByName(reelEffectNodeBG, "normal"):setVisible(true)
        util_getChildByName(reelEffectNodeBG, "fs"):setVisible(false)
    end

    reelEffectNodeBG:setVisible(true)
    util_csbPlayForKey(reelActBG, "ationframe", true)

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    local soundName = self.m_reelRunSound
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(soundName)
end

function CodeGameScreenAliceMachine:createReelEffectBG(col)
    local csbName = self.m_reelEffectName .. "_bg.csb"
    local reelEffectNode, effectAct = util_csbCreate(csbName)

    reelEffectNode:retain()
    effectAct:retain()

    self:findChild("reel_bg"):addChild(reelEffectNode, 1)
    reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
    self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

return CodeGameScreenAliceMachine
