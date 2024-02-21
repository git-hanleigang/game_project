---
-- xcyy
-- 2018-12-18
-- FrogPrinceMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"

local FrogPrinceMiniMachine = class("FrogPrinceMiniMachine", BaseMiniMachine)

FrogPrinceMiniMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1


FrogPrinceMiniMachine.m_machineIndex = nil -- csv 文件模块名字

FrogPrinceMiniMachine.gameResumeFunc = nil
FrogPrinceMiniMachine.gameRunPause = nil

local MainReelId = 1

FrogPrinceMiniMachine.m_lastWinCoin = nil

-- 构造函数
function FrogPrinceMiniMachine:ctor()
    BaseMiniMachine.ctor(self)
end

function FrogPrinceMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent
    self.m_reelId = data.index
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function FrogPrinceMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FrogPrinceMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FrogPrinceMini"
end

function FrogPrinceMiniMachine:getMachineConfigName()
    local str = "Mini"

    return self.m_moduleName .. str .. "Config" .. ".csv"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FrogPrinceMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_FrogPrince_10"
    end

    return ccbName
end


function FrogPrinceMiniMachine:getlevelConfigName()
    local levelConfigName = "LevelFrogPrinceMiniConfig.lua"

    return levelConfigName
end

---
-- 读取配置文件数据
--
function FrogPrinceMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), self:getlevelConfigName())
    end
    self.m_configData:initMachine(self)

    globalData.slotRunData.levelConfigData = self.m_configData
end

--[[
    @desc: 读取音乐、音效配置信息
    time:2020-07-11 18:55:11
]]
function FrogPrinceMiniMachine:readSoundConfigData( )
    --音乐
    self:setBackGroundMusic(self.m_configData.p_musicBg)--背景音乐
    self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)--fs背景音乐
    self:setRsBackGroundMusic(self.m_configData.p_musicReSpinBg)--respin背景
    self.m_ScatterTipMusicPath = self.m_configData.p_soundScatterTip --scatter提示音
    self.m_BonusTipMusicPath = self.m_configData.p_soundBonusTip --bonus提示音
    if self.m_reelId == MainReelId then
        self:setReelDownSound(self.m_configData.p_soundReelDown)
    --下落音
    end

    self:setReelRunSound(self.m_configData.p_reelRunSound)--快滚音效
end

function FrogPrinceMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    local csbName = "GameScreenFrogPrince_rl_mini.csb"
    self:createCsbNode(csbName)
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

function FrogPrinceMiniMachine:initMachine()
    self.m_moduleName = "FrogPrince" -- self:getModuleName()
    BaseMiniMachine.initMachine(self)
    self:runCsbAction("idle")
end

function FrogPrinceMiniMachine:initReconnectLockReels(LockReels)
    self.m_LockReels = {}
    for i, v in ipairs(LockReels) do
        local col = v + 1
        local lowPos = self:getNodePosByColAndRow(col, 1)
        local heightPos = self:getNodePosByColAndRow(col, 4)
        local pos = cc.p(lowPos.x, (lowPos.y + heightPos.y) / 2)
        local changWild = util_spineCreate("Socre_FrogPrince_Changtiao_Wild", true, true)
        changWild:setPosition(pos)
        local reelData = {}
        reelData.col = col
        reelData.changWild = changWild
        table.insert(self.m_LockReels, reelData)
        self.m_slotParents[col].slotParent:setVisible(false)
        self.m_clipParent:addChild(changWild, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 99)
    end
end

function FrogPrinceMiniMachine:initLockReels(LockReels)
    self.m_LockReels = {}
    for i, v in ipairs(LockReels) do
        local col = v + 1
        local lowPos = self:getNodePosByColAndRow(col, 1)
        local heightPos = self:getNodePosByColAndRow(col, 4)
        local pos = cc.p(lowPos.x, (lowPos.y + heightPos.y) / 2)
        local changWildEffect = util_createAnimation("Socre_FrogPrince_Wild_hetu_0.csb")
        changWildEffect:setPosition(pos)
        self.m_clipParent:addChild(changWildEffect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
        changWildEffect:playAction(
            "actionframe",
            false,
            function()
                local changeWildEffect = util_createAnimation("Socre_FrogPrince_Wild_hetu.csb")
                changeWildEffect:setPosition(pos)
                self.m_clipParent:addChild(changeWildEffect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 98)
                changeWildEffect:playAction(
                    "actionframe",
                    false,
                    function()
                        changWildEffect:removeFromParent()
                        changeWildEffect:removeFromParent()
                        self.m_slotParents[col].slotParent:setVisible(false)
                    end
                )
                performWithDelay(
                    self,
                    function()
                        local changWild = util_spineCreate("Socre_FrogPrince_Changtiao_Wild", true, true)
                        changWild:setPosition(pos)
                        local reelData = {}
                        reelData.col = col
                        reelData.changWild = changWild
                        table.insert(self.m_LockReels, reelData)
                        self.m_clipParent:addChild(changWild, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 99)
                        -- util_spinePlay(changWild, "actionframe", false)
                    end,
                    0.3
                )
            end
        )
    end
end

function FrogPrinceMiniMachine:getLockReel(_col)
    for i = 1, #self.m_LockReels do
        local reelData = self.m_LockReels[i]
        if reelData.col == _col then
            return true
        end
    end
    return false
end

function FrogPrinceMiniMachine:getNodePosByColAndRow(col, row)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function FrogPrinceMiniMachine:initMiniReelsUi()
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function FrogPrinceMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

function FrogPrinceMiniMachine:addSelfEffect()
end

function FrogPrinceMiniMachine:MachineRule_playSelfEffect(effectData)
    return true
end

function FrogPrinceMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end


function FrogPrinceMiniMachine:slotReelDown()
    BaseMiniMachine.slotReelDown(self)
end

function FrogPrinceMiniMachine:IsHaveChangWild(_col)
    for i = 1, #self.m_LockReels do
        local reelData = self.m_LockReels[i]
        if reelData.col == _col then
            return true
        end
    end
    return false
end

---
-- 每个reel条滚动到底
function FrogPrinceMiniMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            if self:getGameSpinStage() ~= QUICK_RUN and self.m_reelId == MainReelId then
                if self:getLockReel(reelCol) == false then
                    gLobalSoundManager:playSound(self.m_reelDownSound)
                end
            end
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        if self:getGameSpinStage() ~= QUICK_RUN and self.m_reelId == MainReelId then
            if self:getLockReel(reelCol) == false then
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        end
    end

    

    

    if self:IsHaveChangWild(reelCol) then
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
             --self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, iRow, SYMBOL_NODE_TAG))
            if targSp then
                targSp:setVisible(false)
            end
        end
    end
    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        if self.m_reelId == MainReelId then
            if self:getLockReel(reelCol) == false then
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

function FrogPrinceMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function FrogPrinceMiniMachine:reelDownNotifyChangeSpinStatus()
    -- 发送freespin停止回调
    if self.m_reelId == MainReelId then
        if self.m_parent then
            self.m_parent:slotReelDownInFS()
        end
    end
end

function FrogPrinceMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_parent:setFsAllRunDown(1)
end


function FrogPrinceMiniMachine:quicklyStopReel(colIndex)
    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        BaseMiniMachine.quicklyStopReel(self, colIndex)
    end
end

function FrogPrinceMiniMachine:onExit()
    BaseMachineGameEffect.onExit(self) -- 必须调用不予许删除
    --停止背景音乐
    self:removeObservers()

    self:clearFrameNodes()
    self:clearSlotNodes()
    -- gLobalSoundManager:stopBackgroudMusic()
    -- 卸载金边
    for i, v in pairs(self.m_reelRunAnima) do
        local reelNode = v[1]
        local reelAct = v[2]

        if not tolua.isnull(reelNode) then
            if reelNode:getParent() ~= nil then
                reelNode:removeFromParent()
            end
            reelNode:release()
        end

        if not tolua.isnull(reelAct) then
            reelAct:release()
        end
        self.m_reelRunAnima[i] = nil
    end
    if self.m_reelRunAnimaBG ~= nil then
        for i, v in pairs(self.m_reelRunAnimaBG) do
            local reelNode = v[1]
            local reelAct = v[2]

            if not tolua.isnull(reelNode) then
                if reelNode:getParent() ~= nil then
                    reelNode:removeFromParent()
                end
                reelNode:release()
            end

            if not tolua.isnull(reelAct) then
                reelAct:release()
            end
            self.m_reelRunAnimaBG[i] = nil
        end
    end

    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:unscheduleUpdate()
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
    end

    if self.m_respinNodeInfo ~= nil and #self.m_respinNodeInfo > 0 then
        for k = 1, #self.m_respinNodeInfo do
            local node = self.m_respinNodeInfo[k].node
            if not tolua.isnull(node) then
                node:removeFromParent()
            end
        end
    end
    self.m_respinNodeInfo = {}
    -- clear view childs

    self:removeSoundHandler( )
    scheduler.unschedulesByTargetName(self:getModuleName())
    if self.clearLayerChildReferenceCount then
        self:clearLayerChildReferenceCount()
    end
end

function FrogPrinceMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
end

function FrogPrinceMiniMachine:beginMiniReel()
    BaseMiniMachine.beginReel(self)
    for i = 1, #self.m_LockReels do
        local reelData = self.m_LockReels[i]
        util_spinePlay(reelData.changWild, "idleframe", false)
    end
end

-- 消息返回更新数据
function FrogPrinceMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)

    self:updateNetWorkData()
end

function FrogPrinceMiniMachine:enterLevel()
    BaseMiniMachine.enterLevel(self)
end

function FrogPrinceMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end

-- 轮盘停止回调(自己实现)
function FrogPrinceMiniMachine:setDownCallFunc(func)
    self.m_reelDownCallback = func
end

function FrogPrinceMiniMachine:playEffectNotifyNextSpinCall()
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end

-- 处理特殊关卡 遮罩层级
function FrogPrinceMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    local maxzorder = 0
    local zorder = 0
    for i = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder > maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

function FrogPrinceMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function FrogPrinceMiniMachine:checkGameResumeCallFun( )
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end


function FrogPrinceMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FrogPrinceMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function FrogPrinceMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

function FrogPrinceMiniMachine:initRandomSlotNodes()
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()
end
function FrogPrinceMiniMachine:randomSlotNodes()
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getFsReelDatasByColumnIndex(0,colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end
            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                -- 添加到显示列表
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = showOrder

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
end
function FrogPrinceMiniMachine:addLastWinSomeEffect() -- add big win or mega win
    if self.m_reelId == MainReelId then
    -- BaseMiniMachine.addLastWinSomeEffect(self)
    end
end


function FrogPrinceMiniMachine:lineLogicWinLines( )
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
            
            if lineInfo.iLineSymbolNum >=5 then
                isFiveOfKind=true
            end

            local iconsPosNew = winLineData.p_iconPosNew -- 其他副轮盘
            if iconsPosNew and #iconsPosNew >= 5 then
                isFiveOfKind = true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end

    end

    return isFiveOfKind
end

function FrogPrinceMiniMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()
    
    local isFiveOfKind = self:lineLogicWinLines()
    
end

-- 设置自定义游戏事件
function FrogPrinceMiniMachine:restSelfEffect(selfEffect)
    for i = 1, #self.m_gameEffects, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType and effectData.p_selfEffectType == selfEffect then
            effectData.p_isPlay = true
            self:playGameEffect()

            break
        end
    end
end

---
--设置bonus scatter 层级
function FrogPrinceMiniMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
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

function FrogPrinceMiniMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                -- self:clearFrames_Fun()
                if frameIndex > #winLines  then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
    
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                        self:showAllFrame(winLines)
                        self:playInLineNodes()
                        showLienFrameByIndex()
                    end
                    return
                end
                self:playInLineNodesIdle()
                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end
                    -- print("showLine ... ")
                    local lineData = winLines[frameIndex]

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    table.insert(self.m_LockReels, reelData)
    for i = 1, #self.m_LockReels do
        local reelData = self.m_LockReels[i]
        if self:checkChangWildInLinesByCol(reelData.col) then
            util_spinePlay(reelData.changWild, "actionframe", true)
        end
    end

    self:showAllFrame(winLines)
    if #winLines > 1 then
        showLienFrameByIndex()
    end
end

--赢钱线是否在长条wild 上
function FrogPrinceMiniMachine:checkChangWildInLinesByCol(_col)
    local winLines = self.m_runSpinResultData.p_winLines
    if winLines and #winLines > 0 then
        for i = 1, #winLines do
            local lineData = winLines[i]
            if lineData.p_iconPos and #lineData.p_iconPos > 0 then
                for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                    local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                    local checkEnd = false
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]
                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
                        if _col == colIndex then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

return FrogPrinceMiniMachine
