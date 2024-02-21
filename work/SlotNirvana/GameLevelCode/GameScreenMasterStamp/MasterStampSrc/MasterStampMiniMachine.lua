---
-- xcyy
-- 2018-12-18
-- MasterStampMiniMachine.lua
--
--

local miniSlotReelMachine = require "MasterStampSrc.miniSlotReelMachine"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local MasterStampMiniMachine = class("MasterStampMiniMachine", miniSlotReelMachine)

MasterStampMiniMachine.m_machineIndex = nil -- csv 文件模块名字
MasterStampMiniMachine.gameResumeFunc = nil
MasterStampMiniMachine.gameRunPause = nil

local Main_Reels = 3
local MainReelId = 1

-- 构造函数
function MasterStampMiniMachine:ctor()
    miniSlotReelMachine.ctor(self)
    self.m_isInitSlotsNode = true
end

function MasterStampMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_machine = data.parent
    self.m_reelId = data.reelId
    self.m_maxReelIndex = data.maxReelIndex
    self.m_csbPath = data.csbPath

    --init
    self:initGame()
end

function MasterStampMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function MasterStampMiniMachine:MachineRule_newInitGame()
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MasterStampMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MasterStamp"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MasterStampMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function MasterStampMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    globalData.slotRunData.levelConfigData = self.m_configData
end

function MasterStampMiniMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("MasterStamp/GameScreenMasterStamp_3x5.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

function MasterStampMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    miniSlotReelMachine.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function MasterStampMiniMachine:addSelfEffect()
end

function MasterStampMiniMachine:MachineRule_playSelfEffect(effectData)
    return true
end

function MasterStampMiniMachine:onEnter()
    miniSlotReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MasterStampMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function MasterStampMiniMachine:insterReelResultLines()
    miniSlotReelMachine.insterReelResultLines(self)
end

function MasterStampMiniMachine:reelDownNotifyChangeSpinStatus() 
    
end

function MasterStampMiniMachine:reelDownNotifyPlayGameEffect()
    miniSlotReelMachine.reelDownNotifyPlayGameEffect(self)
    self.m_machine:setFsAllRunDown(1)
end

function MasterStampMiniMachine:playEffectNotifyChangeSpinStatus()
    
end

function MasterStampMiniMachine:quicklyStopReel(colIndex)
    miniSlotReelMachine.quicklyStopReel(self, colIndex)
end

function MasterStampMiniMachine:showLineFrame()
    miniSlotReelMachine.showLineFrame(self)
end

function MasterStampMiniMachine:onExit()
    miniSlotReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function MasterStampMiniMachine:removeObservers()
    miniSlotReelMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function MasterStampMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

function MasterStampMiniMachine:beginMiniReel()
    self.m_isInitSlotsNode = false
    miniSlotReelMachine.beginReel(self)
end

-- 消息返回更新数据
function MasterStampMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    self:createFsMoveKuang(
        function()
            self:updateNetWorkData()  
        end
    )
end

function MasterStampMiniMachine:enterLevel()
end

function MasterStampMiniMachine:enterLevelMiniSelf()
    miniSlotReelMachine.enterLevel(self)
end

function MasterStampMiniMachine:dealSmallReelsSpinStates()
    self.m_machine:setFsAllSpinStates(1)
end

-- 轮盘停止回调(自己实现)
function MasterStampMiniMachine:setDownCallFunc(func)
    self.m_reelDownCallback = func
end

function MasterStampMiniMachine:playEffectNotifyNextSpinCall()
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end

-- 处理特殊关卡 遮罩层级
function MasterStampMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
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

---
--设置bonus scatter 层级
function MasterStampMiniMachine:getBounsScatterDataZorder(symbolType)
    return self.m_machine:getBounsScatterDataZorder(symbolType)
end

function MasterStampMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines
end

function MasterStampMiniMachine:checkGameResumeCallFun()
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

function MasterStampMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MasterStampMiniMachine:pauseMachine()
    self.gameRunPause = true
end

function MasterStampMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

function MasterStampMiniMachine:initRandomSlotNodes()
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()
end

---
-- 清空掉产生的数据
--
function MasterStampMiniMachine:clearSlotoData()
    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then
        for i = #self.m_lineDataPool, 1, -1 do
            self.m_lineDataPool[i] = nil
        end
    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function MasterStampMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function MasterStampMiniMachine:clearCurMusicBg()
end

function MasterStampMiniMachine:updateReelGridNode(node)
end
function MasterStampMiniMachine:playReelDownSound(_iCol, _path)
    if self.m_reelId == 1 then
        MasterStampMiniMachine.super.playReelDownSound(self, _iCol, "MasterStampSounds/music_MasterStamp_Reel_stop.mp3")
    end
end
function MasterStampMiniMachine:slotOneReelDown(reelCol)
    MasterStampMiniMachine.super.slotOneReelDown(self, reelCol)
end

-- 添加固定随机wild
function MasterStampMiniMachine:initFixWild(rowId, wildColId)
    local isLock = true

    local fixPos = {iRow = rowId, iCol = wildColId}
    local targSp = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iRow, fixPos.iCol, true)
end

function MasterStampMiniMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function MasterStampMiniMachine:getPreLoadSlotNodes()
    local loadNode = MasterStampMiniMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.m_machineNode.SYMBOL_SCORE_10, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_machineNode.SYMBOL_SCORE_11, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_machineNode.SYMBOL_SCORE_12, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_machineNode.SYMBOL_FIX_BONUS, count = 12}

    return loadNode
end

function MasterStampMiniMachine:createFsMoveKuang(func)
    local currReelNum = self.m_machine.m_reelNum
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local specialSignals = selfData.specialSignals
    if not specialSignals then
        performWithDelay(
            self,
            function()
                if func then
                    func()
                end
            end,
            self.m_machine.m_wildMoveTime
        )
        return
    end
    local animList = {
        ["reel1"] = {{21,-21}},
        ["reel2"] = {{21,-21}, {21,-21}},
        ["reel3"] = {{-21,-21}, {21,21}, {21,21}},
        ["reel4"] = {{-21,-21}, {-21,-21}, {21,21}, {21,21}}
    }
    local kaungCutNum = animList["reel" .. currReelNum][self.m_reelId]

    if specialSignals then
        if self.m_machine.m_isPlayMoveWildReelId == self.m_reelId then
            gLobalSoundManager:playSound("MasterStampSounds/music_MasterStamp_Bonus_za.mp3")
        end
        
        for i = 1, #specialSignals do
            local wildData = specialSignals[i]
            local iRow = self.m_iReelRowNum - wildData[1]
            local iCol = wildData[2] + 1
            local targSp = self:getSlotNodeWithPosAndType(self.m_machine.SYMBOL_FIX_BONUS, iRow, iCol)
            local pos = self:getPosReelIdx(iRow, iCol)
            if targSp then
                targSp.m_baseBoolFlag = true
                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                local linePos = {}
                linePos[#linePos + 1] = {iX = iRow, iY = iCol}
                targSp.m_bInLine = true
                targSp:setLinePos(linePos)
                targSp:runAnim("kuang", true)
                self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1, self:getNodeTag(iCol, iRow, SYMBOL_FIX_NODE_TAG)) -- 为了参与连线

                local newPos = 0
                if pos > 10 then
                    newPos = pos + kaungCutNum[1]
                else
                    newPos = pos + kaungCutNum[2]
                end

                local position =  self:getBaseReelsTarSpPos(newPos )
                targSp:setPosition(cc.p(position))

                local positionEnd = self:getBaseReelsTarSpPos(pos)

                local actList = {}
                actList[#actList + 1 ] = cc.DelayTime:create(0.1)
                actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                    util_playScaleToAction(targSp, 1, 1.35)
                end)
                actList[#actList + 1 ] = cc.MoveTo:create(1,cc.p(positionEnd))
                actList[#actList + 1 ] = cc.ScaleTo:create(0.2,1)
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    targSp:runAnim("bonus_wild",false)
                end)
                if i == #specialSignals then
                    actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                        if func then
                            func()
                        end
                    end)
                end
                local sq = cc.Sequence:create(actList)
                targSp:runAction(sq) 
            end      
        end
    end
end

function MasterStampMiniMachine:getBaseReelsTarSpPos(index)
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
    return targSpPos
end

return MasterStampMiniMachine
