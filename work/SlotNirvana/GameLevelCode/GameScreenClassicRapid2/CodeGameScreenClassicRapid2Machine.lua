---
-- island li
-- 2019年1月26日
-- CodeGameScreenClassicRapid2Machine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = require "Levels.BaseMachine"

local CodeGameScreenClassicRapid2Machine = class("CodeGameScreenClassicRapid2Machine", BaseSlotoManiaMachine)

CodeGameScreenClassicRapid2Machine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenClassicRapid2Machine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenClassicRapid2Machine.SYMBOL_FIRE_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE
CodeGameScreenClassicRapid2Machine.SYMBOL_FIRE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4
CodeGameScreenClassicRapid2Machine.SYMBOL_MYSTER = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenClassicRapid2Machine.SYMBOL_START_x1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenClassicRapid2Machine.SYMBOL_START_x2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenClassicRapid2Machine.SYMBOL_START_x3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenClassicRapid2Machine.SYMBOL_START_x5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenClassicRapid2Machine.SYMBOL_START_x235 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13 --93 106

CodeGameScreenClassicRapid2Machine.SYMBOL_CLASSIC_SCORE_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenClassicRapid2Machine.SYMBOL_CLASSIC_SCORE_7 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenClassicRapid2Machine.SYMBOL_CLASSIC_SCORE_BAR_3 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3
CodeGameScreenClassicRapid2Machine.SYMBOL_CLASSIC_SCORE_BAR_2 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 4
CodeGameScreenClassicRapid2Machine.SYMBOL_CLASSIC_SCORE_BAR_1 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 5
CodeGameScreenClassicRapid2Machine.SYMBOL_CLASSIC_SCORE_CHERRY = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 6
CodeGameScreenClassicRapid2Machine.SYMBOL_CLASSIC_SCORE_WHEEL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

CodeGameScreenClassicRapid2Machine.ClassicRapid_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

CodeGameScreenClassicRapid2Machine.m_betLevel = nil -- betlevel 0 1 2
CodeGameScreenClassicRapid2Machine.SYMBOL_MYSTER_FreeSpin_GEAR = {}
CodeGameScreenClassicRapid2Machine.SYMBOL_MYSTER_Normal_GEAR = {}
CodeGameScreenClassicRapid2Machine.SYMBOL_MYSTER_NAME = {}
CodeGameScreenClassicRapid2Machine.m_bProduceSlots_RunSymbol = 0
CodeGameScreenClassicRapid2Machine.m_jackPotTipsList = {}

CodeGameScreenClassicRapid2Machine.m_classicMachine = nil
CodeGameScreenClassicRapid2Machine.m_avgBet = 0

local DESIGN_HEIGHT = 1450
local FIT_HEIGHT_MAX = 1233
local FIT_HEIGHT_MIN = 1136

CodeGameScreenClassicRapid2Machine.m_outLines = nil
CodeGameScreenClassicRapid2Machine.m_outLineInitLock = nil
CodeGameScreenClassicRapid2Machine.jackpotMappingList = {5, 4, 3, 2, 1}
CodeGameScreenClassicRapid2Machine.m_IsBonusCollectFull = false
CodeGameScreenClassicRapid2Machine.m_IsInClassic = false
-- 构造函数
function CodeGameScreenClassicRapid2Machine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_betLevel = nil

    self.SYMBOL_MYSTER_Normal_GEAR = {5, 10, 10, 15, 10, 10, 10, 10, 10, 10} -- 假滚 mystery1 权重
    self.SYMBOL_MYSTER_FreeSpin_GEAR = {10, 10, 10, 10, 10, 10, 10, 10, 10, 10} -- 假滚 mystery2 权重
    self.SYMBOL_MYSTER_NAME = {9, 8, 7, 6, 5, 4, 3, 2, 1, 0}
    self.m_bProduceSlots_RunSymbol = self.SYMBOL_MYSTER_NAME[math.random(1, #self.SYMBOL_MYSTER_NAME)]
    self.m_jackPotTipsList = {}
    self.m_classicMachine = nil
    self.m_outLines = true
    self.m_avgBet = 0
    self.m_outLineInitLock = true

    self.m_winSoundsId = nil
    --init
    self:initGame()
end

function CodeGameScreenClassicRapid2Machine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ClassicRapid2Config.csv", "LevelClassicRapid2Config.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenClassicRapid2Machine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        if i < 2 then
            soundPath = "ClassicRapid2Sounds/classRapid_scatterBuling11.mp3"
        elseif i == 2 then
            soundPath = "ClassicRapid2Sounds/classRapid_scatterBuling22.mp3"
        else
            soundPath = "ClassicRapid2Sounds/classRapid_scatterBuling33.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenClassicRapid2Machine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ClassicRapid2"
end

function CodeGameScreenClassicRapid2Machine:getNetWorkModuleName()
    return "ClassicRapid"
end

function CodeGameScreenClassicRapid2Machine:scaleMainLayer()
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
    local classicNode = self:findChild("classicNode")
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            -- util_csbScale(classicNode, mainScale)
            -- classicNode:setScale(mainScale)

            self.m_machineRootScale = mainScale
        end
    else
        -- if self.m_isPadScale then
        --     mainScale = mainScale * 0.82
        -- end
        -- if  display.height/display.width >= 768/1024 then
        --     mainScale = 0.80
        -- elseif display.height/display.width < 768/1024 and display.height/display.width >= 640/960 then
        --     mainScale = 0.90
        -- end
        -- util_csbScale(self.m_machineNode, mainScale)
        -- self.m_machineRootScale = mainScale
        -- self.m_machineNode:setPositionY(mainPosY - 5)
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY - 5)
    end
end

function CodeGameScreenClassicRapid2Machine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:runCsbAction("idle", true)

    -- jackpotbar
    self.m_jackPorBar = util_createView("CodeClassicRapid2Src.ClassicRapid2JackPotBarView")
    self:findChild("jackpot1"):addChild(self.m_jackPorBar)
    self.m_jackPorBar:initMachine(self)

    self.m_jackpotLock = util_createView("CodeClassicRapid2Src.ClassicRapid2JackPotLockView", self)
    self:findChild("jackpot2"):addChild(self.m_jackpotLock)

    self:initFreeSpinBar() -- FreeSpinbar
    self.m_ClassicRapidFreespinBarView = util_createView("CodeClassicRapid2Src.ClassicRapid2FreespinBarView")
    self:findChild("freespinbar"):addChild(self.m_ClassicRapidFreespinBarView)
    self.m_baseFreeSpinBar = self.m_ClassicRapidFreespinBarView
    self.m_baseFreeSpinBar:setVisible(false)

    for i = 1, 5 do
        local name = "bar" .. i
        local barname = "TopBar" .. i
        self[barname] = util_createView("CodeClassicRapid2Src.ClassicRapid2ReelsTopBarView", i, self)
        self:findChild(name):addChild(self[barname], -1)
        self:findChild(name):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE)
    end

    self.m_CollectFreeSpinView = util_createView("CodeClassicRapid2Src.ClassicRapid2CollectFreeSpinView")
    self:findChild("jindutiao"):addChild(self.m_CollectFreeSpinView)
    self.m_CollectFreeSpinView:initMachine(self)

    self.m_changeScene = util_spineCreate("ClassicRapid2_guochang", false, true)
    self:addChild(self.m_changeScene, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    -- self.m_changeScene:setPosition(cc.p(0,0))
    self.m_changeScene:setPosition(cc.p(display.width / 2, display.height / 2))

    self.m_changeScene:setVisible(false)
    -- self.m_changeScene:setScale(0.5)
    local pro = display.height / display.width
    if pro > 2 then
    -- self.m_changeScene:setScale(0.7)
    end

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end
            if self.m_classicMachine then
                return
            end
            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
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
            elseif winRate > 3 and winRate <= 6 then
                soundIndex = 3
                soundTime = 3
            elseif winRate > 6 then
                soundIndex = 3
                soundTime = 3
            end
            local soundName = "ClassicRapid2Sounds/classRapid_winSound" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenClassicRapid2Machine:getBottomUINode()
    return "CodeClassicRapid2Src.ClassicRapid2_GameBottomNode"
end

function CodeGameScreenClassicRapid2Machine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_enterLevel.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    -- if not self.isInBonus then
                    self:resetMusicBg()
                    self:setMinMusicBGVolume()

                    -- end
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenClassicRapid2Machine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenClassicRapid2Machine:normalSpinBtnCall()
    if self.m_IsInClassic then
        return
    end

    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    self.m_CollectFreeSpinView:hideTip()
    BaseSlotoManiaMachine.normalSpinBtnCall(self)
end

function CodeGameScreenClassicRapid2Machine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upateBetLevel()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CodeGameScreenClassicRapid2Machine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenClassicRapid2Machine:MachineRule_GetSelfCCBName(symbolType)
    if self.SYMBOL_SCORE_10 == symbolType then
        return "Socre_ClassicRapid2_10"
    elseif self.SYMBOL_FIRE_WILD == symbolType then
        return "Socre_ClassicRapid2_rapid2"
    elseif self.SYMBOL_MYSTER == symbolType then
        return "Socre_ClassicRapid2_1"
    elseif self.SYMBOL_FIRE == symbolType then
        return "Socre_ClassicRapid2_rapid1"
    elseif self.SYMBOL_START_x1 == symbolType then
        return "Socre_ClassicRapid2_Bonus1"
    elseif self.SYMBOL_START_x2 == symbolType then
        return "Socre_ClassicRapid2_Bonus2"
    elseif self.SYMBOL_START_x3 == symbolType then
        return "Socre_ClassicRapid2_Bonus3"
    elseif self.SYMBOL_START_x5 == symbolType then
        return "Socre_ClassicRapid2_Bonus5"
    elseif self.SYMBOL_START_x235 == symbolType then
        return "Socre_ClassicRapid2_Bonus235"
    end

    if self.SYMBOL_CLASSIC_SCORE_WILD == symbolType then
        return "Socre_ClassicRapid2_Classical_Wild"
    elseif self.SYMBOL_CLASSIC_SCORE_7 == symbolType then
        return "Socre_ClassicRapid2_Classical_9"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_3 == symbolType then
        return "Socre_ClassicRapid2_Classical_8"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_2 == symbolType then
        return "Socre_ClassicRapid2_Classical_7"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_1 == symbolType then
        return "Socre_ClassicRapid2_Classical_6"
    elseif self.SYMBOL_CLASSIC_SCORE_CHERRY == symbolType then
        return "Socre_ClassicRapid2_Classical_5"
    elseif self.SYMBOL_CLASSIC_SCORE_WHEEL == symbolType then
        return "Socre_ClassicRapid2_Classical_Spin"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenClassicRapid2Machine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIRE_WILD, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_MYSTER, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIRE, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_START_x1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_START_x2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_START_x3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_START_x5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_START_x235, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_WILD, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_7, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_CHERRY, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_WHEEL, count = 2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenClassicRapid2Machine:restLeveldData()
    if self.m_IsBonusCollectFull then
        self:upateBetLevel(self.m_avgBet)
    else
        self:upateBetLevel()
    end

    self.m_CollectFreeSpinView:updateBarVisible()

    self:randomMyster()
end

-- 断线重连
function CodeGameScreenClassicRapid2Machine:MachineRule_initGame()
    self.m_reconnect = true
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local selfMakeData = self.m_runSpinResultData.p_selfMakeData
        if selfMakeData and selfMakeData.freeSpinCount and selfMakeData.freeSpinCount == 10 then
            self.m_IsBonusCollectFull = true
            self.m_bottomUI:showAverageBet()
        end
        self:changeState(1)
        self.m_CollectFreeSpinView:setVisible(false)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenClassicRapid2Machine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self, reelCol)

    -- local isHaveFixSymbol = false
    local isPlayJackpotBuling = false
    for k = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[k][reelCol]
        if self:isSymbolBuling(symbolType) then
            -- isHaveFixSymbol = true
            local symbolNode = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, k, SYMBOL_NODE_TAG))
            if self:isSymbolStart(symbolType) then
                symbolNode:runAnim("buling")

                local soundPath = "ClassicRapid2Sounds/classRapid_bonusBuling.mp3"

                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds(reelCol, soundPath)
                else
                    -- respinbonus落地音效
                    gLobalSoundManager:playSound(soundPath)
                end
            elseif symbolType == self.SYMBOL_FIRE_WILD or symbolType == self.SYMBOL_FIRE then
                if self:checkTriggerJackpot(reelCol) then
                    symbolNode:runAnim("buling")
                    if not isPlayJackpotBuling then
                        isPlayJackpotBuling = true

                        local soundPath = "ClassicRapid2Sounds/classRapid_jackpotBuling.mp3"

                        if self.playBulingSymbolSounds then
                            self:playBulingSymbolSounds(reelCol, soundPath)
                        else
                            -- respinbonus落地音效
                            gLobalSoundManager:playSound(soundPath)
                        end
                    end
                end
            end
        end
    end

    -- if isHaveFixSymbol == true  then
    --     gLobalSoundManager:playSound("ClassicRapid2Sounds/music_Charms_Bonus_Down.mp3")

    -- end
end

function CodeGameScreenClassicRapid2Machine:checkTriggerJackpot(reelCol)
    if reelCol == 5 then
        local beforeNum = 0
        for i = 1, reelCol - 1 do
            for k = 1, self.m_iReelRowNum do
                local symbolType = self.m_stcValidSymbolMatrix[k][i]
                if symbolType == self.SYMBOL_FIRE_WILD or symbolType == self.SYMBOL_FIRE then
                    beforeNum = beforeNum + 1
                end
            end
        end
        if beforeNum > 2 then
            return true
        end
        return false
    else
        return true
    end
end
local L_ABS = math.abs
function CodeGameScreenClassicRapid2Machine:reelSchedulerCheckColumnReelDown(parentData, parentY, slotParent, halfH)
    local timeDown = 0
    --
    --停止reel
    if L_ABS(parentY - parentData.moveDistance) < 0.1 then -- 浮点数精度问题
        if parentData.isDone ~= true then
            timeDown = 0
            if self.m_bClickQuickStop ~= true or self.m_iBackDownColID == parentData.cloumnIndex then
                parentData.isDone = true
            elseif self.m_bClickQuickStop == true and self:getGameSpinStage() ~= QUICK_RUN then
                return
            end

            local quickStopDistance = 0
            if self:getGameSpinStage() == QUICK_RUN or self.m_bClickQuickStop == true then
                quickStopDistance = self.m_quickStopBackDistance
            end
            slotParent:stopAllActions()
            self:slotOneReelDown(parentData.cloumnIndex)
            slotParent:setPosition(cc.p(slotParent:getPositionX(), parentData.moveDistance - quickStopDistance))

            local slotParentBig = parentData.slotParentBig
            if slotParentBig then
                slotParentBig:stopAllActions()
                slotParentBig:setPosition(cc.p(slotParentBig:getPositionX(), parentData.moveDistance - quickStopDistance))
                self:removeNodeOutNode(slotParentBig, true, halfH, parentData.cloumnIndex)
            end
            if self:getGameSpinStage() == QUICK_RUN and self.m_hasBigSymbol == false then
            --播放滚动条落下的音效
            -- if parentData.cloumnIndex == self.m_iReelColumnNum then

            -- gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            end
            -- release_print("滚动结束 .." .. 1)
            --移除屏幕下方的小块
            self:removeNodeOutNode(slotParent, true, halfH, parentData.cloumnIndex)
            local speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
            if slotParentBig then
                local seq = cc.Sequence:create(speedActionTable)
                slotParentBig:runAction(seq:clone())
            end

            timeDown = timeDown + (addTime + 0.1) -- 这里补充0.1 主要是因为以免计算出来的结果不够一帧的时间， 造成 action 执行和stop reel 有误差

            local tipSlotNoes = nil
            local nodeParent = parentData.slotParent
            local nodes = nodeParent:getChildren()
            if slotParentBig then
                local nodesBig = slotParentBig:getChildren()
                for i = 1, #nodesBig do
                    nodes[#nodes + 1] = nodesBig[i]
                end
            end
            tipSlotNoes = {}
            for i = 1, #nodes do
                local slotNode = nodes[i]
                local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

                if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
                    --播放关卡中设置的小块效果
                    self:playCustomSpecialSymbolDownAct(slotNode)

                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            slotNode:runAnim("idleframe", true)
                        end

                        if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                            tipSlotNoes[#tipSlotNoes + 1] = slotNode
                        end

                    --                            break
                    end
                --                        end
                end
            end -- end for i=1,#nodes


            if tipSlotNoes ~= nil then
                local nodeParent = parentData.slotParent
                for i = 1, #tipSlotNoes do
                    local slotNode = tipSlotNoes[i]

                    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_SPECIAL_BONUS)
                    self:playScatterBonusSound(slotNode)
                    slotNode:runAnim("buling")
                    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
                    self:specialSymbolActionTreatment(slotNode)
                end -- end for
            end
             
            self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)
            
            local actionFinishCallFunc =
                cc.CallFunc:create(
                function()
                    parentData.isResActionDone = true
                    if self.m_bClickQuickStop == true then
                        self:quicklyStopReel(parentData.cloumnIndex)
                    end
                    print("滚动彻底停止了")
                    self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                end
            )

            speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

            slotParent:runAction(cc.Sequence:create(speedActionTable))
            timeDown = timeDown + self.m_reelDownAddTime
        end
    end -- end if L_ABS(parentY - parentData.moveDistance) < 0.1

    return timeDown
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenClassicRapid2Machine:specialSymbolActionTreatment(node)
    if not node then
        return
    end

    node:runAnim(
        "buling",
        false,
        function()
            node:runAnim("idleframe", true)
        end
    )
end

function CodeGameScreenClassicRapid2Machine:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)
    -- self:removeSoundHandler( )
    -- self:checkTriggerOrInSpecialGame(function(  )
    --     self:reelsDownDelaySetMusicBGVolume( )
    -- end)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenClassicRapid2Machine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal_freespin")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenClassicRapid2Machine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin_normal")
end
---------------------------------------------------------------------------

---
-- 显示free spin
function CodeGameScreenClassicRapid2Machine:showEffect_FreeSpin(effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

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

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_scatter_trigger.mp3")

    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                gLobalSoundManager:stopAllAuido() -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end
----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenClassicRapid2Machine:showFreeSpinView(effectData)
    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_freespin_start.mp3")
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            self.m_CollectFreeSpinView:updateBarVisible(true)
            performWithDelay(
                self,
                function()
                    gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_freespin_start.mp3")
                    self:showFreeSpinStart(
                        self.m_iFreeSpinTimes,
                        function()
                            self:playChangeScene(
                                function()
                                    self:changeState(1)
                                    self.m_CollectFreeSpinView:setVisible(false)
                                    --
                                    if self.m_IsBonusCollectFull then
                                        self.m_bottomUI:showAverageBet()
                                        --显示avergaebet的时候 无视bet强行解锁 所以的jackpot
                                        self:upateBetLevel(self.m_avgBet)
                                    end
                                    self:triggerFreeSpinCallFun()
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                end,
                                0.3
                            )
                        end
                    )
                end,
                1.6
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

function CodeGameScreenClassicRapid2Machine:showFreeSpinStart(num, func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    if selfMakeData and selfMakeData.freeSpinCount and selfMakeData.freeSpinCount == 10 then
        self.m_IsBonusCollectFull = true
        return self:showDialog("FreeSpinStart2", ownerlist, func)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenClassicRapid2Machine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    if self.m_IsBonusCollectFull then
        return self:showDialog("FreeSpinOver2", ownerlist, func)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    end

    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenClassicRapid2Machine:changeClassOverFreeSpinOverBigWinEffect()
    if self.m_gameEffects then
        local effectLen = #self.m_gameEffects
        local isStop = false
        local isFreespinOver = false

        for i = 1, effectLen, 1 do
            local effectData = self.m_gameEffects[i]
            local effectType = effectData.p_effectType

            if effectData.p_isPlay ~= true then
                if effectType == GameEffect.EFFECT_FREE_SPIN_OVER then
                    isFreespinOver = true
                end
            end

            if isFreespinOver then
                local bigwinOver = false
                if effectType == GameEffect.EFFECT_EPICWIN then
                    bigwinOver = true
                elseif effectType == GameEffect.EFFECT_MEGAWIN then
                    bigwinOver = true
                elseif effectType == GameEffect.EFFECT_NORMAL_WIN then
                    bigwinOver = true
                elseif effectType == GameEffect.EFFECT_BIGWIN then
                    bigwinOver = true
                end

                if bigwinOver then
                    isFreespinOver = false
                    isStop = true

                    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
                    local fLastWinBetNumRatio = self.m_llBigOrMegaNum / lTatolBetNum

                    local iBigWinLimit = self.m_BigWinLimitRate
                    local iMegaWinLimit = self.m_MegaWinLimitRate
                    local iEpicWinLimit = self.m_HugeWinLimitRate
                    if fLastWinBetNumRatio >= iEpicWinLimit then
                        self.m_gameEffects[i].p_effectType = GameEffect.EFFECT_EPICWIN
                    elseif fLastWinBetNumRatio >= iMegaWinLimit then
                        self.m_gameEffects[i].p_effectType = GameEffect.EFFECT_MEGAWIN
                    elseif fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
                        self.m_gameEffects[i].p_effectType = GameEffect.EFFECT_BIGWIN
                    end
                end
            end

            if isStop == true then
                break
            end
        end
    end
end

function CodeGameScreenClassicRapid2Machine:showFreeSpinOverView()
    gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_freespin_over.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
    local fsOverCoins = self.m_runSpinResultData.p_fsWinCoins
    self.m_llBigOrMegaNum = fsOverCoins
    self:changeClassOverFreeSpinOverBigWinEffect()

    local strCoins = util_formatCoins(fsOverCoins, 11)

    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:playChangeScene(
                function()
                    if self.m_IsBonusCollectFull then
                        self.m_CollectFreeSpinView:hideAllLittleNode()
                        self.m_IsBonusCollectFull = nil
                        self.m_bottomUI:hideAverageBet()
                        self:upateBetLevel()
                    end
                    self:changeState(0)
                    self.m_CollectFreeSpinView:setVisible(true)
                end,
                0.3,
                function()
                    self:triggerFreeSpinOverCallFun()
                    self:resetMusicBg()
                end
            )
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1.1, sy = 1.1}, 644)
end

function CodeGameScreenClassicRapid2Machine:triggerFreeSpinOverCallFun()
    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    if self.postFreeSpinOverTriggerBigWIn then
        self:postFreeSpinOverTriggerBigWIn(_coins)
    end

    self:checkQuestDoneGameEffect()

    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
        print("222self.m_bProduceSlots_InFreeSpin = false")
    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    self:levelFreeSpinOverChangeEffect()
    self:hideFreeSpinBar()

    self:resetMusicBg()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenClassicRapid2Machine:MachineRule_SpinBtnCall()
    -- gLobalSoundManager:setBackgroundMusicVolume(1)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.m_outLines = false

    self:randomMyster()

    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenClassicRapid2Machine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenClassicRapid2Machine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end

--------------------添加动画

function CodeGameScreenClassicRapid2Machine:checkAddJackPotEffect()
    self.m_jackPotTipsList = {}
    local jackpotNum = 0
    local maxRow = #self.m_runSpinResultData.p_reelsData
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if targSp then
                if targSp.p_symbolType == self.SYMBOL_FIRE_WILD or targSp.p_symbolType == self.SYMBOL_FIRE then
                    jackpotNum = jackpotNum + 1
                    self.m_jackPotTipsList[jackpotNum] = targSp
                end
            end
        end
    end

    if jackpotNum < 3 then
        self.m_jackPotTipsList = nil
    else
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.ClassicRapid_JACKPOT_EFFECT
    end
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenClassicRapid2Machine:addSelfEffect()
    -- 检测是否添加jackPot动画
    self:checkAddJackPotEffect()
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == true and self.m_bProduceSlots_InFreeSpin then
        self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    end
end

--检测是否可以增加quest 完成事件
function CodeGameScreenClassicRapid2Machine:checkQuestDoneGameEffect()
    -- cxc 2021年07月01日10:23:51 quest需要检查下有没有新手quest
    if self.afreshAddQuestDoneEffectType then
        self:afreshAddQuestDoneEffectType()
        return
    end
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not questConfig then
        return
    end
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == false then
        local questEffect = GameEffectData:create()
        questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
        questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
        self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
    end
end

-- ClassicRapidJackPot玩法
function CodeGameScreenClassicRapid2Machine:ClassicRapidJackPotAct(effectData)
    local function clearLine()
        self:clearWinLineEffect()

        if self.m_isShowMaskLayer == true then
            self:resetMaskLayerNodes()
        -- 隐藏所有的遮罩 layer
        end
    end

    if self.m_jackPotTipsList and #self.m_jackPotTipsList > 0 then
        local count = #self.m_jackPotTipsList
        if count > 9 then
            count = 9
        end

        --jackpot加钱逻辑
        local index = 10 - count
        local score = self:BaseMania_getJackpotScore(index)
        clearLine()

        if count >= 3 then
            -- gLobalSoundManager:playSound("ClassicRapid2Sounds/music_ClassicRapid_jackPot_Tip.mp3")
            for _, targSp in ipairs(self.m_jackPotTipsList) do
                targSp:runAnim("actionframe", true)
            end
        end

        self.m_jackPotTipsList = nil

        if count >= 5 then
            local jpScore = score
            if self.m_runSpinResultData.p_selfMakeData then
                if self.m_runSpinResultData.p_selfMakeData.jackpotWinCoins then
                    jpScore = self.m_runSpinResultData.p_selfMakeData.jackpotWinCoins
                end
            end
            -- self.m_jackPorBar:showjackPotAction(count,true )
            -- gLobalSoundManager:playSound("ClassicRapid2Sounds/music_ClassicRapid_Bonusrapid_win.mp3")
            local result = self.m_jackpotLock:showjackPotAction(count)
            self.m_jackPorBar:showjackPotAction(result)
            gLobalSoundManager:pauseBgMusic()

            performWithDelay(
                self,
                function()
                    self.m_jackpotLock:clearAnim()
                    self.m_jackPorBar:clearAnim()
                    self:showJackPot(
                        jpScore,
                        index,
                        function()
                            -- self:resetMusicBg()
                            -- 通知UI钱更新
                            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                                -- freeSpin下特殊玩法的算钱逻辑
                                if #self.m_vecGetLineInfo == 0 then
                                    print("没有赢钱线，得手动加钱")

                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, true})
                                else
                                    print("在算线钱的时候就已经把特殊玩法赢的钱加到总钱了，所以不用更新钱")
                                end
                            else
                                if #self.m_vecGetLineInfo == 0 then
                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, true})

                                    if not self.m_bProduceSlots_InFreeSpin then
                                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                                    end
                                end
                            end
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end,
                4
            )
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
end

function CodeGameScreenClassicRapid2Machine:playChangeScene(callBack, time, overCallback)
    gLobalSoundManager:setBackgroundMusicVolume(0)
    gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_changescene.mp3")

    self.m_changeScene:setVisible(true)
    -- 过场动画
    util_spinePlay(self.m_changeScene, "actionframe")
    performWithDelay(
        self,
        function()
            --构造盘面数据0
            self.m_changeScene:setVisible(false)
            if overCallback then
                overCallback()
            end
        end,
        2
    )

    performWithDelay(
        self,
        function()
            --构造盘面数据
            if callBack then
                callBack()
            end
        end,
        time
    )

    -- performWithDelay(self,function()
    --     self:resetMusicBg(true)
    --     gLobalSoundManager:setBackgroundMusicVolume(1)
    -- end,3)
end
function CodeGameScreenClassicRapid2Machine:showJackPot(coins, num, func)
    gLobalSoundManager:setBackgroundMusicVolume(0)

    local view = util_createView("CodeClassicRapid2Src.ClassicRapid2JackPotWinView", 1)

    local courFunc = function()
        gLobalSoundManager:setBackgroundMusicVolume(1)

        if func then
            func()
        end
    end

    view:initViewData(coins, num, courFunc)
    gLobalViewManager:showUI(view)
end

function CodeGameScreenClassicRapid2Machine:showWheelJackPot(coins, index, func)
    local view = util_createView("CodeClassicRapid2Src.ClassicRapid2JackPotWinView", 2)

    gLobalSoundManager:setBackgroundMusicVolume(0)

    local courFunc = function()
        gLobalSoundManager:setBackgroundMusicVolume(1)

        if func then
            func()
        end
    end

    view:initWheelViewData(coins, index, courFunc)
    gLobalViewManager:showUI(view)
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenClassicRapid2Machine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.ClassicRapid_JACKPOT_EFFECT then
        -- gLobalSoundManager:stopAudio()
        self:ClassicRapidJackPotAct(effectData)
    end
    -- if effectData.p_selfEffectType == self.SYMBOL_FIX_SYMBOL then

    --     self:winNormalBonusEffect(effectData)

    -- elseif effectData.p_selfEffectType == self.SYMBOL_MID_LOCK then
    --     self:MID_LOCK_BonusEffect( effectData)
    -- elseif effectData.p_selfEffectType == self.SYMBOL_MID_LOCK_TIP then
    --     self:MID_LOCK_BonusTipEffect( effectData)

    -- elseif effectData.p_selfEffectType == self.SYMBOL_ADD_WILD then
    --     self:ADD_WILD_BonusEffect(effectData )
    -- elseif effectData.p_selfEffectType == self.SYMBOL_TWO_LOCK then
    --     self:TWO_LOCK_BonusEffect( effectData)
    -- elseif effectData.p_selfEffectType == self.SYMBOL_Double_BET then
    --     self:Double_BET_BonusEffect(effectData )
    -- elseif effectData.p_selfEffectType == self.SYMBOL_FIX_GRAND then
    --     self:winJackPotBonusEffect(effectData)

    -- elseif effectData.p_selfEffectType == self.SYMBOL_RespinOver then
    --     self:respinOverBonusEffect(effectData)
    --     self:checkQuestDoneGameEffect()
    -- elseif effectData.p_selfEffectType == self.SYMBOL_OneBonusOver then
    --     self:playOneBonusGameOver( effectData)
    -- elseif effectData.p_selfEffectType == self.SYMBOL_OneBonusStart then
    --     self:playOneBonusGameStart( effectData)
    -- elseif effectData.p_selfEffectType == self.SYMBOL_Bonus_Spin then
    --     self:playNextBonusSpin( effectData)
    -- end
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenClassicRapid2Machine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

--小块
function CodeGameScreenClassicRapid2Machine:getBaseReelGridNode()
    return "CodeClassicRapid2Src.ClassicRapidSlotNode"
end

function CodeGameScreenClassicRapid2Machine:getBetLevel()
    return self.m_betLevel
end

function CodeGameScreenClassicRapid2Machine:requestSpinResult()
    if self.m_classicMachine then
        return
    end
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.m_reconnect = false
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_SPIN_PROGRESS, data = self.m_collectDataList, jackpot = self.m_jackpotList, betLevel = self:getBetLevel()}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

--服务器没有基础值初始化一份
function CodeGameScreenClassicRapid2Machine:updateJackpotList()
    self.m_jackpotList = {}
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if jackpotPools ~= nil and #jackpotPools > 0 then
        for index, poolData in pairs(jackpotPools) do
            local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(poolData, false, globalData.slotRunData:getCurTotalBet())
            if self.m_IsBonusCollectFull and self.m_avgBet ~= 0 then
                totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(poolData, false, self.m_avgBet)
            end
            self.m_jackpotList[index] = totalScore - baseScore
        end
    end
end

function CodeGameScreenClassicRapid2Machine:updatJackPotLock(level)
    if self.m_betLevel == nil or self.m_betLevel ~= level then
        self.m_betLevel = level

        self.m_jackPorBar:updateLock(self.m_betLevel, self.m_outLineInitLock)
        self.m_jackpotLock:updateLock(self.m_betLevel, self.m_outLineInitLock)
    -- gLobalSoundManager:playSound("DiscoFeverSounds/sound_DiscoFever_unlock.mp3")
    end
end

function CodeGameScreenClassicRapid2Machine:unlockHigherBet(_level)
    local features = self.m_runSpinResultData.p_features or {}

    if
        self.m_bProduceSlots_InFreeSpin == true or (self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE) or
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or
            self:getCurrSpinMode() == AUTO_SPIN_MODE or
            self.m_classicMachine or
            self:getCurrSpinMode() == FREE_SPIN_MODE or
            self:getCurrSpinMode() == RESPIN_MODE or
            #features >= 2
     then
        return
    end

    local level = _level - 1
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if self.m_betLevel and level <= self.m_betLevel then
        return
    end

    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    if self.m_specialBets == nil then
        return
    end

    local betGear = self.m_specialBets[level].p_totalBetValue

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= betGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenClassicRapid2Machine:upateBetLevel(_curBetCoins)
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    if self.m_specialBets == nil then
        return
    end

    local betCoin = _curBetCoins or globalData.slotRunData:getCurTotalBet()
    local level = 0

    for k, v in pairs(self.m_specialBets) do
        local betleveCoin = v.p_totalBetValue
        if betCoin >= betleveCoin then
            level = k
        else
            break
        end
    end

    if level == nil then
        level = 0
    end

    if self.m_betLevel then
        if level == 0 then
        elseif level == 1 and self.m_betLevel < level then
            gLobalSoundManager:playSound("ClassicRapid2Sounds/classicRapid_unLockJackpot1.mp3")
        elseif level == 2 and self.m_betLevel < level then
            gLobalSoundManager:playSound("ClassicRapid2Sounds/classicRapid_unLockJackpot2.mp3")
        elseif level == 3 and self.m_betLevel < level then
            gLobalSoundManager:playSound("ClassicRapid2Sounds/classicRapid_unLockJackpot3.mp3")
        elseif level == 4 and self.m_betLevel < level then
            gLobalSoundManager:playSound("ClassicRapid2Sounds/classicRapid_unLockJackpot4.mp3")
        end
    end

    

    -- local coins1 = self.m_specialBets[#self.m_specialBets].p_totalBetValue
    -- local coins2 = self.m_specialBets[#self.m_specialBets - 1].p_totalBetValue
    -- local coins3 = self.m_specialBets[#self.m_specialBets - 2].p_totalBetValue
    -- local coins4 = self.m_specialBets[#self.m_specialBets - 3].p_totalBetValue
    -- local list = {coins4,coins3,coins2,coins1}

    local list = {}
    for index = 1,4 do
        local betData = self.m_specialBets[#self.m_specialBets - (index - 1)]
        local coins = 0
        if betData then
            coins = betData.p_totalBetValue
        end
        table.insert(list,1,coins)
    end
    -- self.m_jackPorBar:updateLocklab(coins1,coins2,coins3 )
    self.m_jackpotLock:updateLocklab(list)
    self:updatJackPotLock(level)

    self:updateTopLittleBarLock(list)

    if self.m_outLineInitLock then
        self.m_outLineInitLock = false
    end
end

function CodeGameScreenClassicRapid2Machine:updateTopLittleBarLock(list)
    local betLevel = self:getBetLevel()
    if betLevel then
        local tempLv = 5 - betLevel
        for i = 1, 5 do
            local barname = "TopBar" .. i
            local littleBar = self[barname]
            if littleBar then
                if i < 5 then
                    littleBar:showUnLockBet(list[5 - i])
                    if i >= tempLv then
                        littleBar:showUnLock(betLevel, self.m_outLineInitLock)
                    else
                        littleBar:showLock(betLevel)
                    end
                else
                    littleBar:showUnLock(betLevel, self.m_outLineInitLock)
                end
            end
        end
    end
end

-- ---- Myster 处理
function CodeGameScreenClassicRapid2Machine:randomMyster()
    local index = self:getProMysterIndex(self.SYMBOL_MYSTER_Normal_GEAR)
    if self.m_bProduceSlots_InFreeSpin == true then
        index = self:getProMysterIndex(self.SYMBOL_MYSTER_FreeSpin_GEAR)
    end

    self.m_bProduceSlots_RunSymbol = self.SYMBOL_MYSTER_NAME[index]

    self.m_configData:setMysterSymbol(self.m_bProduceSlots_RunSymbol)
end

function CodeGameScreenClassicRapid2Machine:getProMysterIndex(array)
    local index = 1
    local Gear = 0
    local tableGear = {}
    for k, v in pairs(array) do
        Gear = Gear + v
        table.insert(tableGear, Gear)
    end

    local randomNum = math.random(1, Gear)

    for kk, vv in pairs(tableGear) do
        if randomNum <= vv then
            return kk
        end
    end

    return index
end

function CodeGameScreenClassicRapid2Machine:dealVisibleVideoReels(states)
    -- self.m_gameBg:setVisible(states)
    self:findChild("root_0"):setVisible(states)
    -- self.m_bottomUI:setVisible(states)
end
function CodeGameScreenClassicRapid2Machine:changeState(states)
    -- self.m_gameBg:setVisible(states)

    if states == 0 then
        self.m_gameBg:runCsbAction("idle1", true)
    elseif states == 1 then
        self.m_gameBg:runCsbAction("idle2", true)
    elseif states == 2 then
        self.m_gameBg:runCsbAction("idle1", true)
    end
end

function CodeGameScreenClassicRapid2Machine:createClassicMachine()
    self:playChangeScene(
        function()
            self.m_classicMachine:setVisible(true)

            self.m_bottomUI:updateWinCount("")
            self.m_classicMachine:startPlay()

            self:clearWinLineEffect()
            self:resetMaskLayerNodes()
            self:changeState(0)

            self:dealVisibleVideoReels(false)
        end,
        0.3
    )
end

function CodeGameScreenClassicRapid2Machine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")
    if self.m_classicMachine ~= nil then
        return
    end
    BaseSlotoManiaMachine.quicklyStopReel(self, colIndex)
end

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenClassicRapid2Machine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self.m_classicMachine then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
            -- self:getRandomList()
            -- self:stopRespinRun()
            end
        else
        end
        return true
    end
    return false
end

---
-- 处理spin 返回结果
function CodeGameScreenClassicRapid2Machine:spinResultCallFun(param)
    BaseSlotoManiaMachine.spinResultCallFun(self, param)

    self.m_avgBet = 0
    if param and param[1] then
        local spinData = param[2]
        -- print(cjson.encode(param[2]))
        if spinData.result then
            if spinData.result.freespin then
                if spinData.result.freespin.extra then
                    if spinData.result.freespin.extra.avgBet then
                        self.m_avgBet = spinData.result.freespin.extra.avgBet
                    end
                end
            end
        end
    end
end

--属于顶部jackpot触发图标
function CodeGameScreenClassicRapid2Machine:isSymbolStart(symbolType)
    local result = false

    if self.SYMBOL_START_x1 == symbolType then
        result = true
    elseif self.SYMBOL_START_x2 == symbolType then
        result = true
    elseif self.SYMBOL_START_x3 == symbolType then
        result = true
    elseif self.SYMBOL_START_x5 == symbolType then
        result = true
    elseif self.SYMBOL_START_x235 == symbolType then
        result = true
    end

    return result
end
--包含buling动画图标
function CodeGameScreenClassicRapid2Machine:isSymbolBuling(symbolType)
    local result = false

    if self.SYMBOL_START_x1 == symbolType then
        result = true
    elseif self.SYMBOL_START_x2 == symbolType then
        result = true
    elseif self.SYMBOL_START_x3 == symbolType then
        result = true
    elseif self.SYMBOL_START_x5 == symbolType then
        result = true
    elseif self.SYMBOL_START_x235 == symbolType then
        result = true
    elseif self.SYMBOL_FIRE_WILD == symbolType then
        result = true
    elseif self.SYMBOL_FIRE == symbolType then
        result = true
    end

    return result
end
function CodeGameScreenClassicRapid2Machine:startFly(callback)
    if self.m_flyIndex == nil then
        self.m_flyIndex = 1
    end

    local temp = self.m_flyList[self.m_flyIndex]
    --参数 行 列
    local state = 9
    if self.m_ColList[temp[2]] == nil then
        self.m_ColList[temp[2]] = 1
        state = 0
    end
    local targSp = self:getReelParent(temp[2]):getChildByTag(self:getNodeTag(temp[2], temp[1], SYMBOL_NODE_TAG))

    local startPos = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPosition()))
    local barname = "TopBar" .. self.jackpotMappingList[temp[2]]
    local endPos = self[barname]:getParent():convertToWorldSpace(cc.p(self[barname]:getPosition()))
    if state == 0 then
        self[barname]:changeState(
            state,
            function()
                self[barname]:showSpinTime(0)
            end
        )
    end

    self:runFlyAction(
        0.1,
        0.4,
        startPos,
        endPos,
        function()
            -- if state == 0 then
            local barname_1 = barname

            self[barname_1]:changeState(
                9,
                function()
                    self.m_flyIndex = self.m_flyIndex + 1
                    if self.m_flyIndex <= #self.m_flyList then
                        self:startFly(callback)
                    else
                        performWithDelay(
                            self,
                            function()
                                self.m_flyIndex = 1
                                if callback then
                                    callback()
                                end
                            end,
                            0.5
                        )
                    end
                end,
                function()
                    local nextCount = self[barname_1].m_curIndex + 1
                    self[barname_1]:showSpinTime(nextCount)
                end
            )
            -- end
        end
    )
end
function CodeGameScreenClassicRapid2Machine:runFlyAction(time, flyTime, startPos, endPos, callback)
    gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_jackpotcollect.mp3")

    local node2 = cc.ParticleSystemQuad:create("effect/shouji_lizi.plist")
    node2:setVisible(false)
    self:addChild(node2, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node2:setPosition(startPos)

    local actionList2 = {}
    actionList2[#actionList2 + 1] = cc.DelayTime:create(time)
    actionList2[#actionList2 + 1] =
        cc.CallFunc:create(
        function()
            node2:setVisible(true)
        end
    )
    actionList2[#actionList2 + 1] = cc.MoveTo:create(flyTime, endPos)
    actionList2[#actionList2 + 1] =
        cc.CallFunc:create(
        function()
            node2:setVisible(false)
            node2:removeFromParent()
        end
    )
    node2:runAction(cc.Sequence:create(actionList2))

    local node = util_createAnimation("ClassiCrapid_wheel_shouji.csb")
    node:playAction(
        "animation0",
        false,
        function()
            node:setVisible(false)
            node:removeFromParent()
        end
    )
    node:setVisible(false)
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    node:setPosition(startPos)

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:setVisible(true)
        end
    )
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, endPos)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
        end
    )
    node:runAction(cc.Sequence:create(actionList))

    local node3 = cc.Node:create()

    self:addChild(node3, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node3:setPosition(startPos)

    local actionList3 = {}
    actionList3[#actionList3 + 1] = cc.DelayTime:create(flyTime + time)
    actionList3[#actionList3 + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
            node3:removeFromParent()
        end
    )

    node3:runAction(cc.Sequence:create(actionList3))
end
function CodeGameScreenClassicRapid2Machine:classicOverResetView()
    for i = 1, 5 do
        local barname = "TopBar" .. self.jackpotMappingList[i]
        self[barname]:showSpinTime(0, 0)
        self[barname]:changeState(
            -1,
            function()
            end
        )
    end

    if self.m_IsBonusCollectFull then
        self:upateBetLevel(self.m_avgBet)
    else
        self:upateBetLevel()
    end
end

function CodeGameScreenClassicRapid2Machine:showEffect_Respin(effectData)
    -- 停掉背景音乐
    -- self:clearCurMusicBg()
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            -- if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE then
            --将该节点放在 .m_clipParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(), childs[i]:getPositionY()))
            local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            childs[i]:removeFromParent()
            childs[i]:setPosition(cc.p(pos.x, pos.y))
            self.m_slotParents[childs[i].p_cloumnIndex].slotParent:addChild(childs[i])
            -- end
        end
    end

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            1,
            self:getModuleName()
        )
    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

-- function CodeGameScreenClassicRapid2Machine:dealSmallReelsSpinStates( )
--     if not self.m_bProduceSlots_InFreeSpin then
--         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
--                                         {SpinBtn_Type.BtnType_Stop,true})
--     end
-- end

-- respin
function CodeGameScreenClassicRapid2Machine:showRespinView()
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end
    self.m_flyList = {}
    if not self.m_reconnect then
        for icol = 1, self.m_iReelColumnNum do
            for irow = 1, self.m_iReelRowNum do
                local symbolType = self.m_stcValidSymbolMatrix[irow][icol]
                --icol
                if self:isSymbolStart(symbolType) then
                    self.m_flyList[#self.m_flyList + 1] = {irow, icol}
                end
            end
        end
    else
        local countsList = self.m_runSpinResultData.p_selfMakeData.classCounts
        local countsTotalList = self.m_runSpinResultData.p_selfMakeData.classTotalCounts
        for i = 1, #countsList do
            if countsTotalList[i] > 0 then
                local barname = "TopBar" .. self.jackpotMappingList[i]
                self[barname]:showSpinTime(countsList[i], countsTotalList[i])
                if countsList[i] > 0 then
                    self[barname]:changeState(
                        0,
                        function()
                            self[barname]:changeState(1)
                        end
                    )
                else
                    self[barname]:changeState(
                        6,
                        function()
                            self[barname]:changeState(7)
                        end
                    )
                end
            end
        end
    end
    local ActionFunc = function()
        local data = {}
        data.parent = self
        data.betlevel = self:getBetLevel()
        data.paytable = self.m_runSpinResultData.p_selfMakeData.classicWinCoins[self.m_betLevel + 1]
        data.wheels = self.m_runSpinResultData.p_selfMakeData.wheels
        data.parentResultData = self.m_runSpinResultData
        data.effectData = nil
        local uiW, uiH = self.m_topUI:getUISize()
        local uiBW, uiBH = self.m_bottomUI:getUISize()
        data.height = uiH + uiBH

        self.m_IsInClassic = true
        performWithDelay(
            self,
            function()
                self:classicSlotStartView(
                    function()
                        self.m_classicMachine = util_createView("GameScreenClassicRapid2.GameScreenClassicRapid2ClassicSlots", data)
                        self:findChild("classicNode"):addChild(self.m_classicMachine)
                        --GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1  classicNode
                        self.m_classicMachine:setPosition(cc.p(685, 384 - 15))
                        self.m_classicMachine:setVisible(false)

                        performWithDelay(
                            self,
                            function()
                                self:createClassicMachine()
                            end,
                            0.1
                        )
                    end
                )
            end,
            1.5
        )
    end

    local flyEndFun = function()
        -- 播放 respinbonus buling 动画

        local isCalled = false
        gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_bonusTrigger.mp3")

        for icol = 1, self.m_iReelColumnNum do
            for irow = 1, self.m_iReelRowNum do
                local symbolType = self.m_stcValidSymbolMatrix[irow][icol]
                if self:isSymbolStart(symbolType) then
                    local node = self:getReelParent(icol):getChildByTag(self:getNodeTag(icol, irow, SYMBOL_NODE_TAG))
                    -- node:runAnim("actionframe",false,function(  )
                    -- end)
                    node:setVisible(false)
                    if isCalled then
                        self:createOneActionSymbol(
                            node,
                            icol,
                            "actionframe",
                            true,
                            function()
                                node:setVisible(true)
                            end
                        )
                    else
                        isCalled = true
                        self:createOneActionSymbol(
                            node,
                            icol,
                            "actionframe",
                            true,
                            function()
                                node:setVisible(true)
                                if ActionFunc then
                                    ActionFunc()
                                end
                            end
                        )
                    end
                end
            end
        end

        if self.m_outLines then
            self.m_outLines = false
            ActionFunc()
        end
    end
    if #self.m_flyList > 0 then
        self.m_ColList = {}
        self:startFly(
            function()
                flyEndFun()
            end
        )
    else
        flyEndFun()
    end
end

-- 创建一个reels上层的特殊显示信号信号
function CodeGameScreenClassicRapid2Machine:createOneActionSymbol(endNode, colNum, actionName, Spine, callBackFunc)
    if not endNode or not endNode.m_ccbName then
        return
    end

    local fatherNode = endNode
    -- endNode:setVisible(true)

    local isSpine = Spine

    local node = nil
    local callFunc = callBackFunc

    if isSpine then
        node = util_spineCreate(endNode.m_ccbName, true, true)
    else
        node = util_createAnimation(endNode.m_ccbName .. ".csb")
    end

    local func = function()
        if callFunc then
            callFunc()
        end
    end

    if isSpine then
        print("回调------------------- isSpine   ")
        util_spinePlay(node, actionName, false)

        util_spineEndCallFunc(
            node,
            actionName,
            function()
                node:setVisible(false)
                -- local barname =  "TopBar"..colNum
                -- self[barname]:changeState(0,function()
                --     self[barname]:changeState(1)
                -- end)

                if func then
                    func()
                end
                performWithDelay(
                    self,
                    function()
                        node:removeFromParent()
                    end,
                    0.1
                )
            end
        )
    else
        node:playAction(
            actionName,
            false,
            function()
                node:setVisible(false)
                if func then
                    func()
                end

                -- local barname =  "TopBar"..colNum
                -- self[barname]:changeState(0,function()
                --     self[barname]:changeState(1)
                -- end)

                performWithDelay(
                    self,
                    function()
                        node:removeFromParent()
                    end,
                    0.1
                )
            end
        )
    end

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("root"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    self:findChild("root"):addChild(node, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + endNode.p_rowIndex)
    node:setPosition(pos)

    return node
end

function CodeGameScreenClassicRapid2Machine:callSpinBtn()
    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1
    -- freespin时不做钱的计算
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and betCoin > totalCoin then
        self:removeSoundHandler()
        self:checkTriggerOrInSpecialGame(
            function()
                self:reelsDownDelaySetMusicBGVolume()
            end
        )
    end

    BaseMachine.callSpinBtn(self)
end

function CodeGameScreenClassicRapid2Machine:playEffectNotifyNextSpinCall()
    self:removeSoundHandler()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if (self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE) then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

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
                -- self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
end

function CodeGameScreenClassicRapid2Machine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    self:restLeveldData()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

function CodeGameScreenClassicRapid2Machine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    if self:checkHasRespinFeature() then
        self:initRandomSlotNodes()
    else
        self:initCloumnSlotNodesByNetData()
    end
end

--[[
    @desc: 断线重连时处理 是否有feature
    time:2019-01-04 17:19:32
    @return:
]]
function CodeGameScreenClassicRapid2Machine:checkHasRespinFeature()
    local hasFeature = false

    if self.m_initSpinData ~= nil and self.m_initSpinData.p_features ~= nil and #self.m_initSpinData.p_features > 0 then
        for i = 1, #self.m_initSpinData.p_features do
            local featureID = self.m_initSpinData.p_features[i]
            if featureID == SLOTO_FEATURE.FEATURE_RESPIN then
                hasFeature = true
            end
        end
    end

    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)

    if self:getCurrSpinMode() == RESPIN_MODE then
        hasFeature = true
    end

    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
        hasFeature = true
    end

    return hasFeature
end

function CodeGameScreenClassicRapid2Machine:classicSlotOverView(coinsNum)
    local coins = coinsNum
    -- if self.m_runSpinResultData then
    --     if self.m_runSpinResultData.p_resWinCoins then
    --         coins = self.m_runSpinResultData.p_resWinCoins
    --     end
    --  end
    self:checkFeatureOverTriggerBigWin(coinsNum, GameEffect.EFFECT_RESPIN)

    --  self.m_classicOverSoundId = gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_classicOver.mp3")

    local view = util_createView("CodeClassicRapid2Src/ClassicRapid2ClassicOverView")
    gLobalViewManager:showUI(view)
    view:initViewData(
        coins,
        function()
            performWithDelay(
                self,
                function()
                    -- if self.m_classicOverSoundId then
                    --     gLobalSoundManager:stopAudio(self.m_classicOverSoundId)
                    -- end
                    self:classicOverResetView()

                    if not self.m_bProduceSlots_InFreeSpin then
                        local curTotalCoin = globalData.userRunData.coinNum
                        globalData.coinsSoundType = 1
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, curTotalCoin)
                    end

                    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

                    self:triggerReSpinOverCallFun(0)
                end,
                0.02
            )
        end
    )

    -- local view = self:showDialog("Classical_Over", nil,function()

    -- end)
    -- local node=view:findChild("m_lb_coins")
    -- node:setString(util_formatCoins(coins, 50))
    -- view:updateLabelSize({label=node,sx=1.1,sy=1.1},677)
end

function CodeGameScreenClassicRapid2Machine:triggerReSpinOverCallFun(score)
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    performWithDelay(
        self,
        function()
            self:playChangeScene(
                function()
                    -- self:playEffectNotifyChangeSpinStatus()
                    self:removeSoundHandler()
                    self:checkTriggerOrInSpecialGame(
                        function()
                            self:reelsDownDelaySetMusicBGVolume()
                        end
                    )
                    performWithDelay(
                        self,
                        function()
                            self.m_IsInClassic = false
                            self.m_classicMachine:removeFromParent()
                            self.m_classicMachine = nil

                            -- self.m_classicMachine:setVisible(false)
                            self:dealVisibleVideoReels(true)
                            if self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
                                local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins
                                if fsWinCoins then
                                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoins))
                                end

                                self:changeState(1)
                            else
                                self:checkQuestDoneGameEffect()
                                self:changeState(0)
                            end

                            self:updateBaseConfig()

                            self:updateMachineData()
                            self:initSymbolCCbNames()
                            self:initMachineData()

                            self:addQuestDoneEffect()
                        end,
                        0.2
                    )
                end,
                0.3,
                function()
                    performWithDelay(
                        self,
                        function()
                            local coins = nil
                            if self.m_bProduceSlots_InFreeSpin then
                                coins = self:getLastWinCoin() or 0
                            else
                                coins = self.m_serverWinCoins or 0
                            end
                            if self.postReSpinOverTriggerBigWIn then
                                self:postReSpinOverTriggerBigWIn(coins)
                            end

                            self:playGameEffect()
                        end,
                        0.1
                    )
                    util_nextFrameFunc(
                        function()
                            self:resetMusicBg()
                        end
                    )
                end
            )
        end,
        1
    )

    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0
    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

function CodeGameScreenClassicRapid2Machine:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin =
                    scheduler.performWithDelayGlobal(
                    function(delay)
                        self:normalSpinBtnCall()
                    end,
                    0.5,
                    self:getModuleName()
                )
            end
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end

    self:removeSoundHandler()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end
-- function CodeGameScreenClassicRapid2Machine:dealGameEffect()
--     for i=1,#self.m_gameEffects do
--         local effectData = self.m_gameEffects[i]
--         if effectData.p_isPlay ~= true then
--             local effectType = effectData.p_effectType
--             if effectType == GameEffect.EFFECT_FREE_SPIN_OVER then
--                 effectData.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
--             end
--         end
--     end
-- end
function CodeGameScreenClassicRapid2Machine:initMachineData()
    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName .. "_Datas"

    globalData.slotRunData.gameModuleName = self.m_moduleName

    -- 设置bet index

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    -- 配置全局信息，供外部使用
    globalData.slotRunData.levelGetAnimNodeCallFun = function(symbolType, ccbName)
        return self:getAnimNodeFromPool(symbolType, ccbName)
    end
    globalData.slotRunData.levelPushAnimNodeCallFun = function(animNode, symbolType)
        self:pushAnimNodeToPool(animNode, symbolType)
    end

    self:checkHasBigSymbol()
end

function CodeGameScreenClassicRapid2Machine:classicSlotStartView(func)
    self.m_classicStartSoundId = gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_classicStart.mp3")
    gLobalSoundManager:pauseBgMusic()
    local view =
        self:showDialog(
        "Classical_Start",
        nil,
        function()
            if self.m_classicStartSoundId then
                gLobalSoundManager:stopAudio(self.m_classicStartSoundId)
            end
            if func then
                func()
            end
        end
    )
end

function CodeGameScreenClassicRapid2Machine:lineLogicEffectType(winLineData, lineInfo, iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData, lineInfo)

    local validLineSymNum = self.m_validLineSymNum

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        validLineSymNum = 2
    end

    if iconsPos ~= nil and #iconsPos >= validLineSymNum then
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

function CodeGameScreenClassicRapid2Machine:initGameStatusData(gameData)
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
    self.m_avgBet = 0
    if gameData then
        if gameData.spin then
            if gameData.spin.freespin then
                if gameData.spin.freespin.extra then
                    if gameData.spin.freespin.extra.avgBet then
                        self.m_avgBet = gameData.spin.freespin.extra.avgBet
                    end
                end
            end
        end
    end
end

function CodeGameScreenClassicRapid2Machine:BaseMania_updateJackpotScore(index, totalBet)
    if not totalBet then
        totalBet = globalData.slotRunData:getCurTotalBet()
    end

    if self.m_IsBonusCollectFull and self.m_avgBet ~= 0 then
        totalBet = self.m_avgBet
    end

    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools[index] then
        return 0
    end
    local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index], true, totalBet)

    return totalScore
end

function CodeGameScreenClassicRapid2Machine:checkSelfRemoveGameEffectType(effectType)
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return
    end

    for i = effectLen, 1, -1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType then
            table.remove(self.m_gameEffects, i)
        end
    end
end

function CodeGameScreenClassicRapid2Machine:addQuestDoneEffect()
    if self.m_gameEffects == nil then
        return
    end

    self:checkSelfRemoveGameEffectType(GameEffect.EFFECT_QUEST_DONE)

    local questEffect = GameEffectData:create()
    questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
    questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
    self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
end

function CodeGameScreenClassicRapid2Machine:checkAddQuestDoneEffectType()
    if self.m_classicMachine == nil then
        if self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE) == false then
            local questEffect = GameEffectData:create()
            questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
            questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
            self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
        end
    end
end

return CodeGameScreenClassicRapid2Machine
