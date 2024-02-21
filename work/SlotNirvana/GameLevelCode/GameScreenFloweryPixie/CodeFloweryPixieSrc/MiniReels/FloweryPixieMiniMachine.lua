---
-- xcyy
-- 2018-12-18 
-- FloweryPixieMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local SlotParentData = require "data.slotsdata.SlotParentData"
local FloweryPixieSlotFastNode = require "CodeFloweryPixieSrc.FloweryPixieSlotFastNode"


local FloweryPixieMiniMachine = class("FloweryPixieMiniMachine", BaseMiniMachine)


FloweryPixieMiniMachine.SYMBOL_BONUS_ONE = 94   -- 普通Bonus
FloweryPixieMiniMachine.SYMBOL_BONUS_TWO = 95 -- 获得奖励的Bonus
FloweryPixieMiniMachine.SYMBOL_SCATTER_GLOD = 97  -- 金色Scatter
FloweryPixieMiniMachine.SYMBOL_MYSTER_ONE = 105  
FloweryPixieMiniMachine.SYMBOL_MYSTER_TWO = 106  
FloweryPixieMiniMachine.SYMBOL_SCORE_10 = 9 
FloweryPixieMiniMachine.SYMBOL_SCATTER_WILD = 98  -- Scatter变成的wild



FloweryPixieMiniMachine.m_machineIndex = nil -- csv 文件模块名字

FloweryPixieMiniMachine.gameResumeFunc = nil
FloweryPixieMiniMachine.gameRunPause = nil

FloweryPixieMiniMachine.BONUS_FS_WILD_LOCK_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 12 -- 自定义动画的标识

FloweryPixieMiniMachine.m_scatterPlayArray = nil

local Main_Reels = 1



-- 构造函数
function FloweryPixieMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    
end

function FloweryPixieMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_maxReelIndex = data.maxReelIndex 

    self.m_lockWildList = {}
    self.m_oldlockWildList = {}
    self.m_scatterPlayArray = {}

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    

    --init
    self:initGame()
end

function FloweryPixieMiniMachine:initGame()


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function FloweryPixieMiniMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i == 1 then
            soundPath = "FloweryPixieSounds/FloweryPixie_scatter_down1.mp3"
        elseif i == 2 then
            soundPath = "FloweryPixieSounds/FloweryPixie_scatter_down2.mp3"
        else
            soundPath = "FloweryPixieSounds/FloweryPixie_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FloweryPixieMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FloweryPixie"
end

function FloweryPixieMiniMachine:getMachineConfigName()

    local str = "Mini"


    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FloweryPixieMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function FloweryPixieMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelFloweryPixieConfig.lua")
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function FloweryPixieMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName
    self:createCsbNode("FloweryPixie_FS_reel.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function FloweryPixieMiniMachine:initMachine()
    self.m_moduleName = "FloweryPixie" -- self:getModuleName()

    BaseMiniMachine.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function FloweryPixieMiniMachine:addSelfEffect()

    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        local feature = self.m_parent.m_runSpinResultData.p_features
        if feature and #feature > 1 and feature[2] == 1 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 7
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUS_FS_WILD_LOCK_EFFECT -- 动画类型
            
        end
    end 
end


function FloweryPixieMiniMachine:MachineRule_playSelfEffect(effectData)
    
    if effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT  then
        
    end

    return true
end




function FloweryPixieMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end



---
-- 每个reel条滚动到底
function FloweryPixieMiniMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage( ) ~= QUICK_RUN or self.m_hasBigSymbol == true ) then
        self:creatReelRunAnimation(reelCol + 1)
    end


    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            if self.m_machineIndex == Main_Reels then
                gLobalSoundManager:playSound(self.m_reelDownSound)  
            end
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        if self.m_machineIndex == Main_Reels then
            gLobalSoundManager:playSound(self.m_reelDownSound)  
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
                reelEffectNode[1]:setVisible(false)
                -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
                --     self:reductionReel(reelCol)
                -- end
            end
        end

        -- 出发了长滚动则不允许点击快停按钮
        if isTriggerLongRun == true then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        end
end



function FloweryPixieMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function FloweryPixieMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_parent then
        self.m_parent:FSReelShowSpinNotify( self.m_maxReelIndex )
    end

end

function FloweryPixieMiniMachine:quicklyStopReel(colIndex)

    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
    
        BaseMiniMachine.quicklyStopReel(self, colIndex) 
 
    end
end

function FloweryPixieMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function FloweryPixieMiniMachine:removeObservers()
    BaseMiniMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end



function FloweryPixieMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function FloweryPixieMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    BaseMiniMachine.beginReel(self)

end


-- 消息返回更新数据
function FloweryPixieMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function FloweryPixieMiniMachine:enterLevel( )
    BaseMiniMachine.enterLevel(self)
end

function FloweryPixieMiniMachine:enterLevelMiniSelf( )

    BaseMiniMachine.enterLevel(self)
    
end

function FloweryPixieMiniMachine:dealSmallReelsSpinStates( )
    
end



-- 处理特殊关卡 遮罩层级
function FloweryPixieMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end



---
--设置bonus scatter 层级
function FloweryPixieMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parent:getBounsScatterDataZorder(symbolType )

end



function FloweryPixieMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function FloweryPixieMiniMachine:checkGameResumeCallFun( )
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

function FloweryPixieMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FloweryPixieMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function FloweryPixieMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

---
-- 根据类型获取对应节点
--
function FloweryPixieMiniMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
        
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    reelNode:setMachine(self )
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
    
end

function FloweryPixieMiniMachine:getBaseReelGridNode()
    return "CodeFloweryPixieSrc.FloweryPixieSlotFastNode"
end


---
-- 清空掉产生的数据
--
function FloweryPixieMiniMachine:clearSlotoData()
    
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then

        for i=#self.m_lineDataPool,1,-1 do
            self.m_lineDataPool[i] = nil
        end

    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function FloweryPixieMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function FloweryPixieMiniMachine:clearCurMusicBg( )
    
end


function FloweryPixieMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()



    if self.m_parent then
        self.m_parent:FSReelDownNotify( self.m_maxReelIndex  )
    end
end

function FloweryPixieMiniMachine:restLockWildZOrder( )
    for i = #self.m_oldlockWildList, 1, -1 do
        local wild = self.m_oldlockWildList[i]
        wild:setLocalZOrder(self:getBounsScatterDataZorder(self.SYMBOL_SCATTER_WILD - wild.p_rowIndex ))

    end
end

function FloweryPixieMiniMachine:removeAllReelsNode( notCreate)

    self:stopAllActions()
    self:clearWinLineEffect()

    -- 新滚动移除所有小块
    self:removeAllGridNodes()

    for i = #self.m_oldlockWildList, 1, -1 do
        local wild = self.m_oldlockWildList[i]
        if wild and wild.updateLayerTag then
            wild:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end
        wild:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(wild.p_symbolType,wild)
        table.remove(self.m_oldlockWildList, i)
    end

    self.m_oldlockWildList= {}


    self:randomSlotNodes()

 

    

end

function FloweryPixieMiniMachine:initRandomSlotNodes()
    
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()

end




function FloweryPixieMiniMachine:restSelfGameEffects( restType  )

    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects , 1 do

            local effectData = self.m_gameEffects[i]
    
            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_selfEffectType

                if effectType == restType then

                    effectData.p_isPlay = true
                    self:playGameEffect()
                    return 
                end
                
            end

        end
    end
    
end

function FloweryPixieMiniMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)

    self:clearFrames_Fun()


    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()

        self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
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

                if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or
                   lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then

                    if #winLines == 1 then
                        break
                    end

                    frameIndex = frameIndex + 1
                    if frameIndex > #winLines  then
                        frameIndex = 1
                    end
                else
                    break
                end
            end
            -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
            -- 所以打上一个判断
            if frameIndex > #winLines  then
                frameIndex = 1
            end

            self:showLineFrameByIndex(winLines,frameIndex)

            frameIndex = frameIndex + 1
        end, self.m_changeLineFrameTime,self:getModuleName())

    end

    self:showAllFrame(winLines)
    if #winLines > 1 then
        showLienFrameByIndex()
    end

end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData: 
    @return:
]]
function FloweryPixieMiniMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
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

    return symbolType

end

 --  --- -- -- -- --  --  --- -- -- -- -- --  --- -- -- -- -- --  --- -- -- -- -- --  --- -- -- -- --
--增加提示节点
function FloweryPixieMiniMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)
            -- 多个scatter的处理
            if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_SCATTER_GLOD or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            end
        end
    end -- end for i=1,#nodes
    return tipSlotNoes
end

-- 特殊信号下落时播放的音效
function FloweryPixieMiniMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then
        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil
        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_SCATTER_GLOD then
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end
            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry["auto"]
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            end
        end
        if soundPath then
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( iCol,soundPath,slotNode.p_symbolType )
            else
                gLobalSoundManager:playSound(soundPath)
            end
            
        end
    end
end

function FloweryPixieMiniMachine:checkIsInLongRun(col, symbolType)
    local scatterShowCol = self.m_ScatterShowCol

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GLOD then
        if scatterShowCol ~= nil then
            if self:getInScatterShowCol(col) then
                return true
            else 
                return false
            end
        end
    end

    return true
end

---
-- 检测上次feature 数据
--
function FloweryPixieMiniMachine:checkNetDataFeatures()

    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                for posIndex = 1 , #lineData.p_iconPos do
                    local pos = lineData.p_iconPos[posIndex] 

                    local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                    local colIndex = pos % self.m_iReelColumnNum + 1

                    local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GLOD then
                        checkEnd = true
                        local lineInfo = self:getReelLineInfo()
                        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER

                        for addPosIndex = 1 , #lineData.p_iconPos do

                            local posData = lineData.p_iconPos[addPosIndex]
                            local rowColData = self:getRowAndColByPos(posData)
                            lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData

                        end

                        lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                        self.m_reelResultLines = {}
                        self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                        break
                    end
                end
                if checkEnd == true then
                    break
                end

            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})

            -- self:sortGameEffects( )
            -- self:playGameEffect()

        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then  -- respin 玩法一并通过respinCount 来进行判断处理
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            
            -- if self.m_initFeatureData.p_status=="CLOSED" then
            --     return
            -- end

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})


            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                for posIndex = 1 , #lineData.p_iconPos do
                    local pos = lineData.p_iconPos[posIndex] 

                    local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                    local colIndex = pos % self.m_iReelColumnNum + 1

                    local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                        checkEnd = true
                        local lineInfo = self:getReelLineInfo()
                        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS

                        for addPosIndex = 1 , #lineData.p_iconPos do

                            local posData = lineData.p_iconPos[addPosIndex]
                            local rowColData = self:getRowAndColByPos(posData)
                            lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData

                        end

                        lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                        self.m_reelResultLines = {}
                        self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                        break
                    end
                end
                if checkEnd == true then
                    break
                end

            end

            -- self:sortGameEffects( )
            -- self:playGameEffect()


        end
    end

end

function FloweryPixieMiniMachine:lineLogicEffectType(winLineData, lineInfo,iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData,lineInfo)
            
    if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or enumSymbolType == self.SYMBOL_SCATTER_GLOD then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
            
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

--[[
    @desc: 对比 winline 里面的所有线， 将相同的线 进行合并，
    这个主要用来处理， winLines 里面会存在两条一样的触发 fs的线，其中一条线winAmount为0，另一条
    有值， 这中情况主要使用与
    time:2018-08-16 19:30:23
    @return:  只保留一份 scatter 赢钱的线，如果存在允许scatter 赢钱的话
]]
function FloweryPixieMiniMachine:compareScatterWinLines(winLines)

    local scatterLines = {}
    local winAmountIndex = -1
    for i=1,#winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.p_iconPos
        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        for posIndex=1,#iconsPos do
            local posData = iconsPos[posIndex]
            
            local rowColData = self:getRowAndColByPos(posData)
                
            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
                break  -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end

        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or enumSymbolType == self.SYMBOL_SCATTER_GLOD then
            scatterLines[#scatterLines + 1] = {i,winLineData.p_amount}
            if winLineData.p_amount > 0 then
                winAmountIndex = i
            end
        end
    end


    if #scatterLines > 0 and winAmountIndex > 0 then
        for i=#scatterLines,1,-1 do
            local lineData = scatterLines[i]
            if lineData[2] == 0 then
                table.remove(winLines,lineData[1])
            end
        end
    end


end

-- ------ ------ ------ ------ ------ ------ ------ ------ ------ ----
-- ---- 快滚相关 修改
function FloweryPixieMiniMachine:getMaxContinuityBonusCol( )
    local maxColIndex = 0

    local isContinuity = true

    for iCol = 1, self.m_iReelColumnNum do
        local bonusNum = 0

        for iRow = 1, self.m_iReelRowNum do

            local IColData = self.m_runSpinResultData.p_reels[iRow]
            if IColData then
                local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]
                if symbolType then
                    
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GLOD then
                        bonusNum = bonusNum + 1
                        if isContinuity then
                            maxColIndex = iCol
                        end
                    end

                end
                
            end
            
        
        end
        if bonusNum == 0 then
            isContinuity = false
            break
        end
    end

    return maxColIndex
end

--改变下落音效
function FloweryPixieMiniMachine:changeReelDownAnima(parentData)
    if parentData.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or parentData.symbolType == self.SYMBOL_SCATTER_GLOD then
        if not self.m_addSounds then
            self.m_addSounds = {}
        end
        if self:getMaxContinuityBonusCol() >= parentData.cloumnIndex  then
            local soundIndex = 1
            if parentData.cloumnIndex == 1 then
                soundIndex = 1
            elseif parentData.cloumnIndex > 1 and parentData.cloumnIndex < self:getMaxContinuityBonusCol() then
                soundIndex = 2
            else
                soundIndex = 3
            end
            parentData.reelDownAnima = "buling"
            local sameCol = self.m_parent:getTwoFsReelsSameCol( )
            if parentData.cloumnIndex <= sameCol then
                if self.m_machineIndex == Main_Reels then
                    if not self.m_addSounds[parentData.cloumnIndex] then
                        self.m_addSounds[parentData.cloumnIndex] = true
                        parentData.reelDownAnimaSound = self.m_scatterBulingSoundArry[soundIndex] -- "FloweryPixieSounds/FloweryPixie_scatter_down.mp3"
                    end
                end
            else
                if not self.m_addSounds[parentData.cloumnIndex] then
                    self.m_addSounds[parentData.cloumnIndex] = true
                    parentData.reelDownAnimaSound = self.m_scatterBulingSoundArry[soundIndex] -- "FloweryPixieSounds/FloweryPixie_scatter_down.mp3"
                end
            end
            if parentData.symbolType == self.SYMBOL_SCATTER_GLOD then
                parentData.reelDownAnima = "buling2"
            end
        end
        parentData.order = REEL_SYMBOL_ORDER.REEL_ORDER_3 + (( self.m_iReelRowNum - parentData.rowIndex )*10 + parentData.cloumnIndex)
    end
end

-- --设置滚动状态
local runStatus =
{
    DUANG = 1,
    NORUN = 2,
}

--返回本组下落音效和是否触发长滚效果
function FloweryPixieMiniMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then
        showColTemp = showCol
    else
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end

    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum >= 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 2  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[1] then
        if nodeNum >= 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum > 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end


--设置bonus scatter 信息
function FloweryPixieMiniMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column] -- 快滚信息
    local runLen = reelRunData:getReelRunLen() -- 本列滚动长度
    local allSpecicalSymbolNum = specialSymbolNum -- bonus或者scatter的数量（上一轮，判断后得到的）
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType) -- 获得是否进行长滚逻辑和播放长滚动画（true为进行或播放）

    local soundType = runStatus.DUANG
    local nextReelLong = false

    -- scatter 列数限制 self.m_ScatterShowCol 为空则默认为 五列全参与长滚 在：getRunStatus判断
    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then

    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    -- for 这里的代码块只是为了添加scatter或者bonus快滚停止时 的音效和动画
    for row = 1, iRow do
        local targetSymbolType = self:getSymbolTypeForNetData(column,row,runLen)
        if targetSymbolType == symbolType or targetSymbolType == self.SYMBOL_SCATTER_GLOD then

            local bPlaySymbolAnima = bPlayAni

            allSpecicalSymbolNum = allSpecicalSymbolNum + 1

            if bRun == true then

                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

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
    return  allSpecicalSymbolNum, bRunLong
end


function FloweryPixieMiniMachine:setReelRunInfo( )
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0

    local addLens = false

    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        if bRunLong == true then --如果上一列长滚
            longRunIndex = longRunIndex + 1 -- 长滚统计加1

            local runLen = self:getLongRunLen(col, longRunIndex) -- 获得本列的长滚动长度
            local preRunLen = reelRunData:getReelRunLen() -- 获得本列普通滚动长度
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen) -- 设置本列滚动长度为快滚长度
        else
            if addLens == true then
                self.m_reelRunInfo[col]:setReelLongRun(false)
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 9)
                self:setLastReelSymbolList()
            end
        end

        local runLen = reelRunData:getReelRunLen()

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        -- bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)
        local maxCol =  self:getMaxContinuityBonusCol()
        if  col > maxCol then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
        elseif maxCol == col  then
            if bRunLong then
                addLens = true
            end
        end

    end --end  for col=1,iColumn do
end

function FloweryPixieMiniMachine:ChangeScatterNode( )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)

            if targSp then
                local symbolType = targSp.p_symbolType

                if symbolType == self.SYMBOL_SCATTER_GLOD or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- Scatter变成的wild then
                    symbolType = self.SYMBOL_SCORE_10
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType),symbolType)
                    targSp:changeSymbolImage(self:getSymbolCCBNameByType(self, symbolType) )
                    targSp:setLocalZOrder(self:getBounsScatterDataZorder(symbolType ))
                    targSp:runAnim("idleframe")
                end
                
            end
        end
    end
end


-- 小轮盘玩法处理
function FloweryPixieMiniMachine:CreateSlotNodeByData()


    

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getReelParentChildNode(iCol, iRow )
            local symbolType = self.m_parent:getSpinResultReelsType(iCol, iRow) 
            local isChange = true
            
            -- if targSp and targSp.p_symbolType ~= symbolType  then

            --     isChange = true
                
            --     if symbolType == self.SYMBOL_BONUS_ONE or symbolType == self.SYMBOL_BONUS_TWO then
            --         isChange = false

            --         if targSp.p_symbolType == self.SYMBOL_SCATTER_GLOD or targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            --             isChange = true
            --         end
            --     end

                

            -- end

            if targSp and isChange then
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType),symbolType)
                targSp:changeSymbolImage(self:getSymbolCCBNameByType(self, symbolType) )
                targSp:setLocalZOrder(self:getBounsScatterDataZorder(symbolType ) - targSp.p_rowIndex  )
                
                if targSp.p_symbolType == self.SYMBOL_SCATTER_GLOD then
                    targSp:runAnim("idleframe2",true)
                else
                    targSp:runAnim("idleframe",true)
                end
            end
            
            
        end
    end


    
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- 锁定玩法处理
-- 金色scatter 固定玩法
function FloweryPixieMiniMachine:initFsLockWild(wildPosList)

    if wildPosList and #wildPosList > 0 then

        for k, v in pairs(wildPosList) do
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp =  self:getReelParentChildNode(fixPos.iY, fixPos.iX) 

            if targSp then
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCATTER_WILD),self.SYMBOL_SCATTER_WILD)
                
                targSp:changeSymbolImage(self:getSymbolCCBNameByType(self, self.SYMBOL_SCATTER_WILD) )

                targSp:runAnim("idleframe2")
               
                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE


                local linePos = {}
                linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                targSp.m_bInLine = true
                targSp:setLinePos(linePos)
                targSp:setLocalZOrder(self:getBounsScatterDataZorder(self.SYMBOL_SCATTER_WILD )  - fixPos.iX   )

                targSp = self:setSymbolToClipReel(targSp.p_cloumnIndex, targSp.p_rowIndex, targSp.p_symbolType)

                table.insert( self.m_oldlockWildList,targSp)
                
            end

            
        end
    end

    self:restLockWildZOrder( )

end

function FloweryPixieMiniMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
        local linePos = {}
        linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = true
        targSp:setLinePos(linePos)
    end
    return targSp
end

function FloweryPixieMiniMachine:GoldScatterTurnLockWild( wildPosList ,func,aniName )
    
    if wildPosList and #wildPosList > 0 then


        if aniName ~= "buling" then
            gLobalSoundManager:playSound("FloweryPixieSounds/FloweryPixie_reel_ScatterToWIld.mp3")
        end
        
        
        for k, v in pairs(wildPosList) do
            local callFunc = nil
            if k == 1 then
                callFunc = function(  )
                    if func then
                        func()
                    end
                end
            end

            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp =  self:getReelParentChildNode(fixPos.iY, fixPos.iX) 

            if targSp then
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCATTER_WILD),self.SYMBOL_SCATTER_WILD)
                
                targSp:changeSymbolImage(self:getSymbolCCBNameByType(self, self.SYMBOL_SCATTER_WILD) )

                targSp:runAnim(aniName,false,function(  )
                    
                    if callFunc then
                        callFunc()
                    end
                end)
                
                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE


                local linePos = {}
                linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                targSp.m_bInLine = true
                targSp:setLinePos(linePos)
                targSp:setLocalZOrder(self:getBounsScatterDataZorder(self.SYMBOL_SCATTER_WILD )  - fixPos.iX  )

                targSp = self:setSymbolToClipReel(targSp.p_cloumnIndex, targSp.p_rowIndex, targSp.p_symbolType)

                table.insert( self.m_oldlockWildList,targSp)

                if aniName == "buling" then
                    local nodeKuang = util_createAnimation("Socre_FloweryPixie_wild_kuang.csb")
                    self:findChild("Node_1"):addChild(nodeKuang,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE  - v - 5 )
                    local beginPos = util_getConvertNodePos(targSp,nodeKuang)
                    nodeKuang:setPosition(cc.p(beginPos))
                    nodeKuang:runCsbAction("actionframe",false,function(  )

                        if nodeKuang:getParent() then
                            nodeKuang:removeFromParent()
                        end
                        
                    end)
                end
                

            end

            
        end
    end

    self:restLockWildZOrder( )
end


---
--添加金边
function FloweryPixieMiniMachine:creatReelRunAnimation(col)
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

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")
    reelEffectNode:setOpacity(255)
    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--绘制多个裁切区域
function FloweryPixieMiniMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNode.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNodeBig.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE+1000000)
        else
            clipNode = cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
        clipNode:setTag(CLIP_NODE_TAG + i)
        -- slotParentNode:setVisible(false)

        

        local parentData = SlotParentData:new()
        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
            parentData.slotParentBig = slotParentNodeBig
        end
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        -- self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        -- self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)

        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)
        
        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")


        
    end
end

function FloweryPixieMiniMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                if child.p_slotNodeH == nil then -- 打个补丁
                    child.p_slotNodeH = self.m_SlotNodeH
                end
                topY = childY + child.p_slotNodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end

function FloweryPixieMiniMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()

        local nodeLen = #self.m_lineSlotNodes
        for lineNodeIndex = nodeLen, 1, -1 do
            local lineNode = self.m_lineSlotNodes[lineNodeIndex]
            -- node = lineNode
            if lineNode ~= nil then -- TODO 打的补丁， 临时这样
                local preParent = lineNode.p_preParent
                if preParent ~= nil then
                    lineNode:runIdleAnim()
                end
            end
        end

        self:resetMaskLayerNodes()
        callFun()
    end,util_max(67/30,animTime),self:getModuleName())
end


---
-- 显示free spin
function FloweryPixieMiniMachine:showSelfEffect_FreeSpin(func)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
           
            if func then
                func()
            end
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue

    else
        if func then
            func()
        end
        
    end

    return true
end


function FloweryPixieMiniMachine:getScatterLineValue( )
    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            break
        end
    end

    return scatterLineValue
end

function FloweryPixieMiniMachine:specialSymbolActionTreatment( node )
    if node.p_symbolType and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or node.p_symbolType == self.SYMBOL_SCATTER_GLOD ) then
        node:runAnim("buling",false,function(  )
            node:runAnim("idleframe",true)
        end)
    end
end

function FloweryPixieMiniMachine:getAnimNodeFromPool(symbolType, ccbName)
    if not symbolType then
        release_print("AnimNodeFromPool error not symbolType!!!    ccbName:"..ccbName)
        return nil
    end
    if ccbName == nil then
        ccbName = self:getSymbolCCBNameByType(self, symbolType)
    end

    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}
        self.m_reelAnimNodePool[symbolType] = reelPool
    end

    if #reelPool == 0 then
        -- 扩展支持 spine 的元素
        local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
        local node = nil
        if spineSymbolData ~= nil then
            node = SlotsSpineAnimNode:create()
            node.m_defaultAnimLoop = true
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:initSpineInfo(spineSymbolData[1],spineSymbolData[2])
            node:runDefaultAnim()
        else
            node = SlotsAnimNode:create()
            node.m_defaultAnimLoop = true
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:runDefaultAnim()
        end

        return node
    else
        local node = reelPool[1] -- 存内存池取出来
        table.remove(reelPool, 1)
        node:runDefaultAnim()

        -- print("从尺子里面拿 SlotsAnimNode")

        return node
    end
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function FloweryPixieMiniMachine:showLineFrameByIndex(winLines,frameIndex)

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s","")

        return
    end

    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then

            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then

            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end

        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i=1,frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <=  hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue,symPosData)
        end
        node:setPosition(cc.p(posX,posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
               self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe",true)
        else
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end

    end

    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    slotsNode:runLineAnim()
                end
            end
        end
    end

end

return FloweryPixieMiniMachine
