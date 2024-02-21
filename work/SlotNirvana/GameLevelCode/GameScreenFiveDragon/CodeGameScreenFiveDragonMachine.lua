---
-- xcyy
-- 2018年5月11日
-- CodeGameScreenFiveDragonMachine.lua
--
-- 玩法： 五龙关卡
--

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseMachine = require "Levels.BaseMachine"
local FiveDragonSlotsNode = require "CodeFiveDragonSrc.FiveDragonSlotsNode"
local CodeGameScreenFiveDragonMachine = class("CodeGameScreenFiveDragonMachine", BaseSlotoManiaMachine)

CodeGameScreenFiveDragonMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenFiveDragonMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenFiveDragonMachine.FEATURE_SYMBOL = 101

CodeGameScreenFiveDragonMachine.FEATURE_ANIMA_NODE = 1000

CodeGameScreenFiveDragonMachine.m_featureEffect = GameEffect.EFFECT_SELF_EFFECT + 1

CodeGameScreenFiveDragonMachine.WILD_MUTIPPLE_ANIMATION = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

CodeGameScreenFiveDragonMachine.m_bTriggerFeature = nil --是否触发玩法
CodeGameScreenFiveDragonMachine.m_FeatureSymbolInfos = nil --触发时 featuresymbol位置

CodeGameScreenFiveDragonMachine.m_FeatureFsTimes = nil --触发时 featuresymbol位置

CodeGameScreenFiveDragonMachine.m_FeatureView = nil

CodeGameScreenFiveDragonMachine.m_winSoundsId = nil

CodeGameScreenFiveDragonMachine.m_iSuperBonusFlag = 10

-- 构造函数
function CodeGameScreenFiveDragonMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_winSoundsId = nil
    self.m_TriggerFeature = false
    self.m_FeatureSymbolInfos = {}
    self.m_isFeatureOverBigWinInFree = true

    --init
    self:initGame()
end

function CodeGameScreenFiveDragonMachine:initGame()
    self.m_animNameIds = {9, 11, 0, 1, 2, 3, 4, 5, 6, 7, 8}

    self.m_lightScore = 0

    self.m_RESPIN_WAIT_TIME = 3

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end

            local winAmonut = params[1]
            if type(winAmonut) == "number" then
                local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
                local winRatio = winAmonut / lTatolBetNum
                local soundName = nil
                if winRatio > 0 then
                    if winRatio <= 1 then
                        soundName = "FiveDragonSounds/music_FiveDragon_WinPrize_1.mp3"
                    elseif winRatio > 1 and winRatio <= 3 then
                        soundName = "FiveDragonSounds/music_FiveDragon_WinPrize_2.mp3"
                    elseif winRatio > 3 then
                        soundName = "FiveDragonSounds/music_FiveDragon_WinPrize_3.mp3"
                    end
                end

                if soundName ~= nil then
                    gLobalSoundManager:setBackgroundMusicVolume(0.4)
                    self.m_winSoundsId =
                        gLobalSoundManager:playSound(
                        soundName,
                        false,
                        function()
                            gLobalSoundManager:setBackgroundMusicVolume(1)
                        end
                    )
                end
            end
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    --初始化基本数据
    self:initMachine(self.m_moduleName)

    self:runCsbAction("normal")

    self.m_hasBigSymbol = false
end

function CodeGameScreenFiveDragonMachine:initUI(data)
    self:initFreeSpinBar()

    self.m_csbOwner["Node_6"]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    --FiveDragonFeatureView node
    self.m_csbOwner["darkBg"]:setVisible(false)
    self.m_csbOwner["darkBg"]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self.m_bonusSchedule = util_createView("CodeFiveDragonSrc.FiveDragonBonusSchedule")
    self.m_bonusSchedule:setMachine(self)
    self.m_csbOwner["Node_BET"]:addChild(self.m_bonusSchedule)

    -- self:addClick(self.m_csbOwner["click"])
    self.m_bCanClick = true

    self.m_csbOwner["FiveDragon_famre_long2_4"]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_csbOwner["show_tip"]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    self.m_lowBetIcon = util_createView("CodeFiveDragonSrc.FiveDragonLowerBetIcon", self)
    self.m_csbOwner["Node_low_bet"]:addChild(self.m_lowBetIcon)
    self.m_csbOwner["Node_low_bet"]:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    self.m_Tips = util_createView("CodeFiveDragonSrc.FiveDragonTips")
    self.m_csbOwner["show_tip"]:addChild(self.m_Tips)
    self.m_Tips:showTip()
end

function CodeGameScreenFiveDragonMachine:clickFunc(sender)
end

function CodeGameScreenFiveDragonMachine:perLoadSLotNodes()
    for i = 1, 10 do
        local node = FiveDragonSlotsNode:create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        self.m_reelNodePool[#self.m_reelNodePool + 1] = node
    end
end

---
-- 根据类型获取对应节点
--
function CodeGameScreenFiveDragonMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        local node = FiveDragonSlotsNode:create()
        node:retain()
        reelNode = node
        release_print("创建了node")
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)

    reelNode:initSlotNodeByCCBName(ccbName, symbolType)

    return reelNode
end

function CodeGameScreenFiveDragonMachine:showOrHideTips()
    if self.m_bCanClick == false then
        return
    end
    if self.m_bCanClick == true then
        self.m_bCanClick = false
        if self.m_Tips:getIsShow() then
            self.m_Tips:HideTip(
                function()
                    self.m_bCanClick = true
                end
            )
        else
            self.m_Tips:showTip(
                function()
                    self.m_bCanClick = true
                end
            )
        end
    end
end

function CodeGameScreenFiveDragonMachine:createFsBar()
    self.m_FreeSpinBar = util_createView("CodeFiveDragonSrc.FiveDragonFreeSpinBar")
    self.m_csbOwner["node_fs_bar"]:addChild(self.m_FreeSpinBar)
    util_setCsbVisible(self.m_FreeSpinBar, false)
end

function CodeGameScreenFiveDragonMachine:remvoeFsBar()
    self.m_FreeSpinBar:stopAllActions()
    self.m_FreeSpinBar:removeFromParent()
end

function CodeGameScreenFiveDragonMachine:getReelHeight()
    return 535
end

function CodeGameScreenFiveDragonMachine:getReelWidth()
    return 1100
end

function CodeGameScreenFiveDragonMachine:scaleMainLayer()
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
        if self.m_isPadScale then
            mainScale = mainScale + 0.05
        end
        local offsetY = -15
        local isIpad = false
        local ratio = display.height/display.width
        if  ratio >= 768/1024 then
            mainScale = 0.92
            isIpad = true
            offsetY = -18
        elseif ratio < 768/1024 and ratio >= 640/960 then
            mainScale = 1
            offsetY = -10
        elseif ratio >= 768/1228 and ratio < 768/1024 then
            mainScale = 1.02
            offsetY = -22
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        if display.width < self:getReelWidth() then
            if not isIpad then
                local posY = self:getReelHeight() * (1 - mainScale) * 0.5
                self.m_machineNode:setPositionY(-posY - 6)
            else
                self.m_machineNode:setPositionY(offsetY)
            end
        else
            local posY = mainHeight * (1 - mainScale) * 0.5
            self.m_machineNode:setPositionY(-posY + offsetY)
        end
    end
end
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFiveDragonMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FiveDragon"
end

function CodeGameScreenFiveDragonMachine:getNetWorkModuleName()
    return "FiveDragonV2"
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFiveDragonMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if symbolType == self.SYMBOL_SCORE_10 then
        ccbName = "Socre_FiveDragon_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        ccbName = "Socre_FiveDragon_11"
    elseif symbolType == self.FEATURE_SYMBOL then
        ccbName = "FiveDragon_M"
    elseif symbolType == self.FEATURE_ANIMA_NODE then
        ccbName = "FiveDragon_DragonDrop"
    end

    return ccbName
end

-- function CodeGameScreenFiveDragonMachine:getBounsScatterDataZorder(symbolType)
--     local order = 0
--     if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
--         order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
--     elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
--         order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
--     elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
--         order = REEL_SYMBOL_ORDER.REEL_ORDER_2
--     elseif symbolType == self.FEATURE_SYMBOL then
--         order = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 100
--     else
--         order = REEL_SYMBOL_ORDER.REEL_ORDER_1
--     end
--     return order
-- end

function CodeGameScreenFiveDragonMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col, isLastSymbol)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        reelNode:setLineAnimName(nil)
    end

    return reelNode
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFiveDragonMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine:getPreLoadSlotNodes()
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}
    loadNode[#loadNode + 2] = {symbolType = self.SYMBOL_SCORE_11, count = 2}
    loadNode[#loadNode + 3] = {symbolType = self.FEATURE_SYMBOL, count = 8}
    loadNode[#loadNode + 4] = {symbolType = self.FEATURE_ANIMA_NODE, count = 5}
    return loadNode
end

------------------------------------------------------------------------

----------------------------- 玩法处理 -----------------------------------
---
-- 盘面数据生成之后 计算连线前
-- 改变轮盘数据
---

-- 检测是否是触发scatter动画的列
function CodeGameScreenFiveDragonMachine:checkColForScatterAction(col)
    local scatterCol = {}
    local isShow = false

    for iCol = 1, self.m_iReelColumnNum do
        local hasFeatureSymbol = false
        for iRow = 1, self.m_iReelRowNum do
            if self.m_stcValidSymbolMatrix[iRow][iCol] == self.FEATURE_SYMBOL then
                hasFeatureSymbol = true
                break
            end
        end
        if hasFeatureSymbol == true and #scatterCol == iCol - 1 then
            table.insert(scatterCol, iCol)
        end
    end

    for k, v in pairs(scatterCol) do
        if col == v then
            isShow = true
        end
    end

    return isShow
end

-- 数据生成之后
-- 改变轮盘ui块生成列表 (可以作用于贴长条等 特殊显示逻辑中) --
function CodeGameScreenFiveDragonMachine:MachineRule_InterveneReelList()
    for index = 1, #self.m_reelSlotsList do
        local lastColumnSymbol = self.m_reelSlotsList[index]
        for i = 1, self.m_iReelRowNum do
            local symbolData = lastColumnSymbol[#lastColumnSymbol - i + 1]
            if symbolData.p_symbolType == self.FEATURE_SYMBOL then
                if self:checkColForScatterAction(index) then
                    symbolData.m_reelDownAnima = "buing"
                else
                    symbolData.m_reelDownAnima = "idleframe"
                end
            end
        end
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFiveDragonMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFiveDragonMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    -- gLobalSoundManager:stopAudio(self.m_winSoundsId)
    -- self.m_winSoundsId = nil
    return false
end

---
-- 轮盘停止时调用
-- 改变轮盘滚动后的数据等
function CodeGameScreenFiveDragonMachine:MachineRule_stopReelChangeData()
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFiveDragonMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --bugly0906: 刷新free累计次数，触发时不在此处刷新
    if selfData.triggerTimes and selfData.triggerTimes~=self.m_iSuperBonusFlag then
        self.m_triggerFreeSpinTimes = selfData.triggerTimes
    end
    
    if self.m_triggerFreeSpinTimes == self.m_iSuperBonusFlag then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.WILD_MUTIPPLE_ANIMATION -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFiveDragonMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.WILD_MUTIPPLE_ANIMATION then
        self:multipleWild(effectData)
    end

    return true
end

function CodeGameScreenFiveDragonMachine:multipleWild(effectData)
    for i = 1, self.m_iReelRowNum, 1 do
        local symbol = self:getReelParent(3):getChildByTag(self:getNodeTag(3, i, SYMBOL_NODE_TAG))
        if i == self.m_iReelRowNum then
            symbol:runAnim(
                "number",
                false,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            )
        else
            symbol:runAnim("number")
        end
        symbol:setLineAnimName("actionframe2")
        symbol:getCcbProperty("multiple_2"):setVisible(false)
        symbol:getCcbProperty("multiple_3"):setVisible(false)
        symbol:getCcbProperty("multiple_5"):setVisible(false)
        symbol:getCcbProperty("multiple_" .. self.m_runSpinResultData.p_selfMakeData.multiple):setVisible(true)
    end
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenFiveDragonMachine:levelFreeSpinEffectChange()
    local objectOne = {}
    objectOne[1] = "changeFreespin"
    objectOne[2] = false
    objectOne[3] = function()
        local objectTwo = {}
        objectTwo[1] = "freespin"
        objectTwo[2] = true
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, objectTwo)
    end
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, objectOne)
    -- self.m_FreeSpinBar:setVisible(true)
end

-- 滚动结束调用
function CodeGameScreenFiveDragonMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self, reelCol)

    if self:checkColForScatterAction(reelCol) then
        gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_goin_lightning.mp3")
    end
end

function CodeGameScreenFiveDragonMachine:slotReelDown()
    BaseMachine.slotReelDown(self)
    -- self.m_csbOwner["show_tip"]:removeAllChildren()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenFiveDragonMachine:levelFreeSpinOverChangeEffect(content)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "changeNomal")
end

function CodeGameScreenFiveDragonMachine:getInitFeatureViewData()
    local storeIcons = self:getLockScatterPos() -- self.m_runSpinResultData.p_storedIcons
    local respinNodeInfo = {}

    for i = 1, #storeIcons do
        local icon = storeIcons[i]
        local posArray = self:getRowAndColByPos(icon[1])

        local columnData = self.m_reelColDatas[posArray.iY]
        local height = columnData.p_showGridH

        --二维坐标
        local arrayPos = {posArray.iX, posArray.iY}
        --世界坐标
        local pos, reelHeight, reelWidth = self:getReelPos(posArray.iY)
        pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
        pos.y = pos.y + (posArray.iX - 0.5) * height * self.m_machineRootScale

        local nodeInfo = {
            Pos = pos,
            ArrayPos = arrayPos,
            EndValue = icon[2]
        }

        respinNodeInfo[#respinNodeInfo + 1] = nodeInfo
    end
    return respinNodeInfo
end

function CodeGameScreenFiveDragonMachine:setFeatureVisibel(isVisivle)
    local storeIcons = self:getLockScatterPos() -- self.m_runSpinResultData.p_storedIcons
    for i = 1, #storeIcons do
        local icon = storeIcons[i]
        local posArray = self:getRowAndColByPos(icon[1])
        local targSp = self:getReelParent(posArray.iY):getChildByTag(self:getNodeTag(posArray.iY, posArray.iX, SYMBOL_NODE_TAG))
        targSp:setVisible(isVisivle)
    end
end

function CodeGameScreenFiveDragonMachine:playAddDragonAnima()
    self.m_csbOwner["darkBg"]:setVisible(false)

    local getColDelayTime = function(col)
        if col == 1 or col == 5 then
            return 2
        elseif col == 2 or col == 4 then
            return 1
        else
            return 0
        end
    end

    for i = 1, self.m_iReelColumnNum do
        local addSymbols = {}
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local childs = self:getReelParent(i):getChildren()
        local pos = {}
        local addSymbolMaxPos = {}
        for j = 1, #childs do
            local nodeSymbol = childs[j]
            if nodeSymbol.p_rowIndex ~= nil then
                local nodePosY = nodeSymbol:getPositionY()
                if #addSymbolMaxPos == 0 then
                    addSymbolMaxPos.x = nodeSymbol:getPositionX()
                    addSymbolMaxPos.y = nodePosY
                else
                    if addSymbolMaxPos.y < nodePosY then
                        addSymbolMaxPos.x = nodeSymbol:getPositionX()
                        addSymbolMaxPos.y = nodePosY
                    end
                end

                --添加 h1 信号
                local addSymbol = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)

                addSymbol:setPosition(nodeSymbol:getPosition())
                self:getReelParent(i):addChild(addSymbol)
                addSymbol.p_slotNodeH = halfH
                addSymbol:setLocalZOrder(nodeSymbol:getLocalZOrder())
                addSymbol:setVisible(false)
                addSymbols[#addSymbols + 1] = addSymbol

                if nodeSymbol.p_rowIndex > 2 then
                    local newPosY = nodePosY + halfH * 7
                    -- nodeSymbol:setPositionY(newPosY)
                    local moveAction = cc.MoveTo:create(1, cc.p(nodeSymbol:getPositionX(), newPosY))
                    local seq =
                        cc.Sequence:create(
                        moveAction,
                        cc.CallFunc:create(
                            function(sender)
                                sender:setVisible(false)
                            end
                        ),
                        nil
                    )
                    nodeSymbol:runAction(seq)
                else
                    if nodeSymbol.p_rowIndex == 2 then
                        pos.y = nodeSymbol:getPositionY() + halfH
                        pos.x = nodeSymbol:getPositionX()
                    end

                    local newPosY = nodePosY - halfH * 7
                    local moveAction = cc.MoveTo:create(1, cc.p(nodeSymbol:getPositionX(), newPosY))
                    local seq =
                        cc.Sequence:create(
                        moveAction,
                        cc.CallFunc:create(
                            function(sender)
                                sender:setVisible(false)
                            end
                        ),
                        nil
                    )
                    nodeSymbol:runAction(seq)
                end
            end

            for z = 1, 15 do
                local addSymbol = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
                addSymbol:setPosition(cc.p(addSymbolMaxPos.x, addSymbolMaxPos.y + halfH * 2 * z))
                self:getReelParent(i):addChild(addSymbol)
                addSymbol:setVisible(false)
                addSymbol.p_slotNodeH = halfH
                addSymbols[#addSymbols + 1] = addSymbol
            end
        end

        local idleCount = 2
        performWithDelay(
            self,
            function()
                if i == 1 then
                    gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_DragonDrop.mp3") -- 龙跳音效
                end
                local featureAnima = self:getSlotNodeBySymbolType(self.FEATURE_ANIMA_NODE, "FiveDragon_DragonDrop")
                -- featureAnima.m_csbAct:setTimeSpeed(2)
                pos.y = pos.y - 30 --调动画
                featureAnima:setPosition(pos)
                self:getReelParent(i):addChild(featureAnima)

                featureAnima:runAnim(
                    "start",
                    false,
                    function()
                        self:playFeatureAnima(
                            featureAnima,
                            idleCount,
                            function()
                                featureAnima:runAnim(
                                    "over",
                                    false,
                                    function()
                                        performWithDelay(
                                            self,
                                            function()
                                                for i = 1, #addSymbols do
                                                    local node = addSymbols[i]
                                                    node:setVisible(true)
                                                end
                                                featureAnima:setVisible(false)
                                                featureAnima:removeFromParent()
                                                featureAnima:stopAllActions()
                                                self:pushSlotNodeToPoolBySymobolType(self.FEATURE_ANIMA_NODE, featureAnima)
                                            end,
                                            1
                                        )
                                    end
                                )
                            end
                        )
                    end
                )
            end,
            getColDelayTime(i) * 0.15
        )
    end
end

function CodeGameScreenFiveDragonMachine:playFeatureAnima(featureAnima, time, callFun)
    featureAnima:runAnim(
        "idleframe",
        false,
        function()
            if time > 0 then
                self.playFeatureAnima(self, featureAnima, time - 1, callFun)
            else
                callFun()
            end
        end
    )
end

function CodeGameScreenFiveDragonMachine:playFeatureSymbolAnima()
    if self.m_triggerFreeSpinTimes == nil or self.m_triggerFreeSpinTimes == 0 then
        return
    end
    local storeIcons = self:getLockScatterPos() -- self.m_runSpinResultData.p_storedIcons
    for i = 1, #storeIcons do
        local icon = storeIcons[i]
        local posArray = self:getRowAndColByPos(icon[1])
        local targSp = self:getReelParent(posArray.iY):getChildByTag(self:getNodeTag(posArray.iY, posArray.iX, SYMBOL_NODE_TAG))
        targSp:runAnim("actionframe")
        --freespin内再触发freespin 不播放收集效果
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            if self.m_iBetLevel == 1 then
                local startPos = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPosition()))
                local endPos = self.m_bonusSchedule:getCurrLanternPos(self.m_triggerFreeSpinTimes)
                local particle = cc.ParticleSystemQuad:create("FireDrangon_bet_yellowdian.plist")
                self:addChild(particle, 1000000)
                particle:setPosition(startPos)
                local moveTo = cc.MoveTo:create(0.5, endPos)

                particle:runAction(
                    cc.Sequence:create(
                        moveTo,
                        cc.CallFunc:create(
                            function()
                                if i == #storeIcons then
                                    performWithDelay(
                                        self,
                                        function()
                                            self.m_bonusSchedule:collect(self.m_triggerFreeSpinTimes)
                                        end,
                                        0.3
                                    )
                                end
                                particle:stopSystem()
                                performWithDelay(
                                    self,
                                    function()
                                        particle:removeFromParent(true)
                                    end,
                                    0.5
                                )
                            end
                        )
                    )
                )
            end
        end
    end
end

function CodeGameScreenFiveDragonMachine:showFreeSpinView(effectData)
    local FeatureOverCallFunc = function()
        self:remvoeFsBar()
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_View_Open.mp3")

        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:runCsbAction("tanchuangStart")
            local moreView =
                self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    self.m_csbOwner["darkBg"]:setVisible(false)

                    self:runCsbAction("tanchuangOver")
                    self:resetMusicBg(true)
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            )
            -- if self.m_triggerFreeSpinTimes == self.m_iSuperBonusFlag then
            --     moreView:findChild("title"):setString("SUPER FREE GAMES")
            --     moreView:findChild("title_1"):setString("SUPER FREE GAMES")
            -- end
            performWithDelay(self, function( )
                moreView:findChild("Particle_1"):stopSystem()
                moreView:findChild("Particle_1"):resetSystem()
            end, 0.5)
        else
            self:runCsbAction("tanchuangStart")

            local startView = self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    self.m_csbOwner["darkBg"]:setVisible(false)
                    self:runCsbAction(
                        "tanchuangOver",
                        false,
                        function()
                            -- self:runCsbAction("actionframe1", false)
                        end
                    )
                    self:playAddDragonAnima()

                    performWithDelay(
                        self,
                        function()
                            self:clearCurMusicBg()

                            gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_View_Open.mp3")

                            self:runCsbAction("tanchuangStart")
                            local view = util_createAnimation("FiveDragon_MoreSymblos.csb")
                            gLobalViewManager:showUI(view)
                            -- view:setScale(self.m_machineRootScale)
                            view.onKeyBack = function()
                            end
                            view:runCsbAction(
                                "AOTU",
                                false,
                                function()
                                    self:resetMusicBg(true)
                                    self:runCsbAction(
                                        "tanchuangOver",
                                        false,
                                        function()
                                            self:runCsbAction("actionframe1", false)
                                        end
                                    )
                                    self:triggerFreeSpinCallFun()
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                    view:stopAllActions()
                                    view:removeFromParent()
                                end
                            )
                        end,
                        10
                    )
                end
            )

            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(waitNode, function( )
                waitNode:removeFromParent()
                if not tolua.isnull(startView) then
                    startView:findChild("Particle_1"):stopSystem()
                    startView:findChild("Particle_1"):resetSystem()
                end
                
            end,0.5)
        end
        self:setFeatureVisibel(true)
        self.m_FeatureView:removeFromParent()
    end

    local playFsBarUpdateOverAnima = function()
        gLobalSoundManager:playSound("FiveDragonSounds/sound_FiveDragon_Num_freeBar_boom.mp3")
        self.m_FreeSpinBar:runCsbAction(
            "over",
            false,
            function()
                -- local actionMove = cc.MoveTo:create(0.2, cc.p(self.m_FreeSpinBar:getPositionX(), self.m_FreeSpinBar:getPositionY() - 200))
                -- self.m_FreeSpinBar:runAction(actionMove)
                performWithDelay(
                    self,
                    function()
                        gLobalSoundManager:playSound("FiveDragonSounds/sound_FiveDragon_Num_boom.mp3")
                    end,
                    0.2
                )

                self.m_FreeSpinBar:runCsbAction(
                    "Settlement",
                    false,
                    function()
                        -- FeatureOverCallFunc()
                    end
                )

                performWithDelay(
                    self,
                    function()
                        FeatureOverCallFunc()
                    end,
                    0.7
                )
            end
        )
    end

    local ShowFsBarAnima = function()
        util_setCsbVisible(self.m_FreeSpinBar, true)
        self.m_FreeSpinBar:setPositionY(0)

        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self.m_FreeSpinBar:changeFsCount(0) -- globalData.slotRunData.freeSpinCount - self.m_iFreeSpinTimes
        else
            self.m_FreeSpinBar:changeFsCount(0)
        end

        self.m_FreeSpinBar:setUpEndCallBackFun(
            function()
                playFsBarUpdateOverAnima()
            end
        )
        -- 小块弹框出现
        gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_LittleBit_View.mp3")

        self.m_FreeSpinBar:runCsbAction(
            "start",
            false,
            function()
                if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                    -- globalData.slotRunData.freeSpinCount
                    local endTimes = self.m_iFreeSpinTimes
                    if self.m_runSpinResultData.p_freeSpinNewCount then
                        endTimes = self.m_runSpinResultData.p_freeSpinNewCount
                    end
                    self.m_FreeSpinBar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinNewCount)
                else
                    self.m_FreeSpinBar:updateFreespinCount(self.m_iFreeSpinTimes)
                end
            end
        )
    end

    self:clearCurMusicBg() -- 暂停背景音乐

    self:playFeatureSymbolAnima()

    local function showFeatureView()
        self:createFsBar()
        self:setFeatureVisibel(false)
        self.m_FeatureView = util_createView("CodeFiveDragonSrc.FiveDragonFeatureView")
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local SignalTypeArray = {1, 2, 3}
            self.m_FeatureView:setSignalTypeArray(SignalTypeArray)
        end
        local featureInitData = self:getInitFeatureViewData()
        self.m_csbOwner["clip_node"]:addChild(self.m_FeatureView, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) --  self.m_clipParent
        self.m_FeatureView:initFeatureUI(featureInitData, self)
        self.m_FeatureView:setOverCallBackFun(
            function()
                performWithDelay(
                    self,
                    function()
                        ShowFsBarAnima()
                    end,
                    0.1
                )
            end
        )
    end

    performWithDelay(
        self,
        function()
            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_View_Open.mp3")

                local view = util_createAnimation("FiveDragon/FiveDragon_FreeSpinAgain.csb")
                self:findChild("root"):addChild(view)
                -- view:setScale(self.m_machineRootScale)
                view.onKeyBack = function()
                end
                self:runCsbAction("tanchuangStart")
                view:runCsbAction(
                    "AOTU",
                    false,
                    function()
                        self:runCsbAction("tanchuangOver")
                        showFeatureView()
                        view:removeFromParent()
                    end
                )
            else
                gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_View_Open.mp3")

                local view = util_createAnimation("FiveDragon/FiveDragon_FreeSpinStack.csb")
                self:findChild("root"):addChild(view)
                if self.m_triggerFreeSpinTimes == self.m_iSuperBonusFlag then
                    view:findChild("title"):setString("SUPER FREE GAMES")
                    view:findChild("title_1"):setString("SUPER FREE GAMES")
                end
                -- view:setScale(self.m_machineRootScale)
                view.onKeyBack = function()
                end
                self:runCsbAction("tanchuangStart")
                view:runCsbAction(
                    "AOTU",
                    false,
                    function()
                        self:runCsbAction("tanchuangOver")
                        showFeatureView()
                        view:removeFromParent()
                    end
                )
            end
        end,
        6
    )
end

function CodeGameScreenFiveDragonMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_View_Open.mp3")
    print("showFreeSpinOverView")
    self:runCsbAction("tanchuangStart")
    self.m_fsReelDataIndex = 0
    local view =
        self:showFreeSpinOver(
        globalData.slotRunData.lastWinCoin,
        globalData.slotRunData.totalFreeSpinCount,
        function()
            self:triggerFreeSpinOverCallFun()
            self:runCsbAction(
                "tanchuangOver",
                false,
                function()
                    self:runCsbAction("actionframe2", false)
                end
            )
            if self.m_triggerFreeSpinTimes == self.m_iSuperBonusFlag then
                self.m_triggerFreeSpinTimes = 0
                self.m_bonusSchedule:reset()
                self.m_bottomUI:hideAverageBet()
            end
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node,sx = 1,sy = 1},716)

    
    
    performWithDelay(view, function( )
        view:findChild("Particle_1"):stopSystem()
        view:findChild("Particle_1"):resetSystem()
    end, 0.5)
end


function CodeGameScreenFiveDragonMachine:showEffect_FreeSpin(effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    local endTimes = 0
    if self.m_runSpinResultData.p_freeSpinNewCount then
        endTimes = self.m_runSpinResultData.p_freeSpinNewCount
    end
    gLobalNoticManager:postNotification(ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM, endTimes)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if self.m_bProduceSlots_InFreeSpin then
        scheduler.performWithDelayGlobal(
            function(delay)
                self:clearCurMusicBg()
            end,
            4.5,
            self:getModuleName()
        )

        gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_custom_enter_fs.mp3")

        --2秒后播放下轮动画
        scheduler.performWithDelayGlobal(
            function(delay)
                self:showFreeSpinView(effectData)
            end,
            1,
            self:getModuleName()
        )
    else
        --
        self:showFreeSpinView(effectData)
    end
    if self.m_iBetLevel == 1 and self.m_runSpinResultData.p_selfMakeData ~= nil then
        if self.m_triggerFreeSpinTimes < self.m_runSpinResultData.p_selfMakeData.triggerTimes then
            self.m_triggerFreeSpinTimes = self.m_runSpinResultData.p_selfMakeData.triggerTimes
        end
        if self.m_triggerFreeSpinTimes == self.m_iSuperBonusFlag then
            self.m_bottomUI:showAverageBet()
            self.m_fsReelDataIndex = 1
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_CONFIG_TYPE, self.m_runSpinResultData.p_selfMakeData.avgBet)
        end
    end
    self:clearCurMusicBg()
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

---------------------------------------------------------------------------

function CodeGameScreenFiveDragonMachine:requestSpinResult()
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
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenFiveDragonMachine:showLowerBetIcon()
    self.m_lowBetIcon:show()
end

function CodeGameScreenFiveDragonMachine:hideLowerBetIcon()
    self.m_lowBetIcon:hide()
end

function CodeGameScreenFiveDragonMachine:showLowerBetTip()
    local tip, act = util_csbCreate("FiveDragon_tips.csb")
    local parent = self.m_bottomUI:findChild("bet_eft")
    tip:setPositionY(74)
    parent:addChild(tip)
    util_csbPlayForKey(
        act,
        "AUTO",
        false,
        function()
            tip:removeFromParent(true)
        end
    )
end

function CodeGameScreenFiveDragonMachine:showLowerBetLayer(showTip)
    local view = util_createView("CodeFiveDragonSrc.FiveDragonLowerBetDialog", self, showTip)
    view:findChild("lab_bet"):setString(util_formatCoins(self.m_BetChooseGear, 30))
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CodeGameScreenFiveDragonMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        self.m_iBetLevel = 1
    else
        self.m_iBetLevel = 0
    end
end

function CodeGameScreenFiveDragonMachine:unlockHigherBet()
    if
        self.m_bProduceSlots_InFreeSpin == true or (self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE) or
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or
            self:getCurrSpinMode() == AUTO_SPIN_MODE
     then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_BetChooseGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenFiveDragonMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    self:updateBetLevel()
    self.m_bonusSchedule:initStatus(self.m_iBetLevel, self.m_triggerFreeSpinTimes)

    if self.m_bProduceSlots_InFreeSpin ~= true then
        performWithDelay(
            self,
            function()
                if self.m_iBetLevel == 0 then
                    self:showLowerBetLayer(true)
                end
            end,
            0.2
        )
    end
end

function CodeGameScreenFiveDragonMachine:MachineRule_initGame(initSpinData)
    self.m_bIsReconnect = true
    if self.m_bProduceSlots_InFreeSpin == true and self.m_triggerFreeSpinTimes == self.m_iSuperBonusFlag then
        self.m_fsReelDataIndex = 1
        self.m_bottomUI:showAverageBet()
    end
    if self.m_bProduceSlots_InFreeSpin == true then
        if  self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
            self:runCsbAction("actionframe1")
        end
    end
end

function CodeGameScreenFiveDragonMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_goin.mp3")

            scheduler.performWithDelayGlobal(
                function()
                    self:resetMusicBg()
                    -- self:setMinMusicBGVolume()
                end,
                4,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenFiveDragonMachine:initGameStatusData(gameData)
    if gameData.gameConfig ~= nil and gameData.gameConfig.init ~= nil and gameData.gameConfig.init.triggerTimes ~= nil then
        self.m_triggerFreeSpinTimes = gameData.gameConfig.init.triggerTimes
    else
        self.m_triggerFreeSpinTimes = 0
    end

    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end

function CodeGameScreenFiveDragonMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    -- 如果需要改变父类事件监听函数，则在此处修改(具体哪些监听看父类的addObservers)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local perBetLevel = self.m_iBetLevel
            self:updateBetLevel()
            if perBetLevel > self.m_iBetLevel then
                -- self:showLowerBetTip()
                self.m_bonusSchedule:lock()
                self:showLowerBetIcon()
            elseif perBetLevel < self.m_iBetLevel then
                self.m_bonusSchedule:unlock()
                gLobalSoundManager:playSound("FiveDragonSounds/sound_FiveDragon_unlock_highbet.mp3")
                self:hideLowerBetIcon()
            end
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:unlockHigherBet()
        end,
        ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET
    )
end

function CodeGameScreenFiveDragonMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
    end
    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenFiveDragonMachine:removeObservers()
    BaseSlotoManiaMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function CodeGameScreenFiveDragonMachine:clearSlotChilds(childs)
    for childIndex = 1, #childs, 1 do
        local node = childs[childIndex]
        if not tolua.isnull(node) then
            if node.clear ~= nil then
                node:clear()
            end

            if node.stopAllActions == nil then
                release_print("__cname  is nil")
                if node.__cname ~= nil then
                    release_print("报错的node 类型为" .. node.__cname)
                elseif tolua.type(node) ~= nil then
                    release_print("报错的node 类型为" .. tostring(tolua.type(node)))
                end
            end

            if node.stopAllActions then
                node:stopAllActions()
            end
            
            node:removeAllChildren()
            --                printInfo("xcyy node referencecount %d",node:getReferenceCount())
            if node:getReferenceCount() > 1 then
                node:release()
            end
            release_print("__cname end")
        end
    end
end

-- 获得锁住的的scatter位置
function CodeGameScreenFiveDragonMachine:getLockScatterPos()
    local storeIcons = {}
    for k, v in pairs(self.m_runSpinResultData.p_fsExtraData) do
        local array = {}
        array[#array + 1] = tonumber(k)
        array[#array + 1] = tonumber(v)
        table.insert(storeIcons, array)
    end
    return storeIcons
end

function CodeGameScreenFiveDragonMachine:lineLogicWinLines( )
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        
        self:compareScatterWinLines(winLines)

        for i=1,#winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo,iconsPos)
            
            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())
            
            if lineInfo.iLineSymbolNum >= 5 and lineInfo.enumSymbolType ~= self.FEATURE_SYMBOL then
                isFiveOfKind = true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end

    end

    return isFiveOfKind
end
---
--设置bonus scatter 层级
function CodeGameScreenFiveDragonMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.FEATURE_SYMBOL then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order
end

function CodeGameScreenFiveDragonMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    BaseMachine.playEffectNotifyNextSpinCall(self)
end
-- 背景音乐点击spin后播放
function CodeGameScreenFiveDragonMachine:normalSpinBtnCall()
    BaseMachine.normalSpinBtnCall(self)
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    if self.m_Tips and self.m_Tips:getIsShow() then
        self.m_Tips:HideTip()
    end
end

return CodeGameScreenFiveDragonMachine
