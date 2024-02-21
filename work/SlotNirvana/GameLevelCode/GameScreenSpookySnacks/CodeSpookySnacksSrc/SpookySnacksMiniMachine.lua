---
-- xcyy
-- 2018-12-18 
-- SpookySnacksMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"

local SpookySnacksMiniMachine = class("SpookySnacksMiniMachine", BaseMiniMachine)

SpookySnacksMiniMachine.SYMBOL_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3--96
SpookySnacksMiniMachine.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2--95
SpookySnacksMiniMachine.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1--94
SpookySnacksMiniMachine.SYMBOL_SCORE_BLANK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7--100

SpookySnacksMiniMachine.m_machineIndex = nil -- csv 文件模块名字

SpookySnacksMiniMachine.gameResumeFunc = nil
SpookySnacksMiniMachine.gameRunPause = nil

SpookySnacksMiniMachine.isChangeRespinBonus3 = false


local Main_Reels = 1

-- 构造函数
function SpookySnacksMiniMachine:ctor()
    SpookySnacksMiniMachine.super.ctor(self)

end

function SpookySnacksMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machine = data.machine
    self.m_machineIndex = data.index
    self.m_machineRootScale = data.machine.m_machineRootScale

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function SpookySnacksMiniMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("SpookySnacksMiniConfig.csv", "LevelSpookySnacksMiniConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function SpookySnacksMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "SpookySnacks"
end

--小块
-- function SpookySnacksMiniMachine:getBaseReelGridNode()
--     return "CodeBlackFridaySrc.BlackFridaySlotNode"
-- end

function SpookySnacksMiniMachine:getMachineConfigName()

    local str = "Mini"


    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function SpookySnacksMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)
    return ccbName

end

---
-- 读取配置文件数据
--
function SpookySnacksMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function SpookySnacksMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("SpookySnacks/GameScreenSpookySnacksMini.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode

    --光效层
    self.m_lightEffectNode = cc.Node:create()
    self:findChild("Node_1"):addChild(self.m_lightEffectNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    
end
---
--
function SpookySnacksMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    SpookySnacksMiniMachine.super.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function SpookySnacksMiniMachine:addSelfEffect()
 
end


function SpookySnacksMiniMachine:MachineRule_playSelfEffect(effectData)
    
    -- if effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT  then
        
    -- end

    return true
end

function SpookySnacksMiniMachine:onEnter()
    -- if self.m_machine.m_isNeedChangeNode then
    --     return
    -- end

    SpookySnacksMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function SpookySnacksMiniMachine:addObservers()

    SpookySnacksMiniMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:MachineRule_respinTouchSpinBntCallBack()
        end,
        ViewEventType.RESPIN_TOUCH_SPIN_BTN
    )
    
end

function SpookySnacksMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function SpookySnacksMiniMachine:playEffectNotifyChangeSpinStatus( )


end

function SpookySnacksMiniMachine:quicklyStopReel(colIndex)


end

function SpookySnacksMiniMachine:onExit()
    -- if self.m_machine.m_isNeedChangeNode then
    --     return
    -- end
    SpookySnacksMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function SpookySnacksMiniMachine:removeObservers()
    SpookySnacksMiniMachine.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end



function SpookySnacksMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage( WAITING_DATA )
    if self.m_machineIndex == 1 then
        self.m_machine.m_isGetIndexMini = false
        self.m_machine:requestSpinReusltData()

        self.m_machine.m_isPlayRespinGoldSiverSound = false
    end
end


function SpookySnacksMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    SpookySnacksMiniMachine.super.beginReel(self)

end


-- 消息返回更新数据
function SpookySnacksMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:initMiniReelDataMini(self.m_runSpinResultData.p_rsExtraData["reels"..self.m_machineIndex])
    self.m_runSpinResultData.p_winLines = {}
    self:updateNetWorkData()
end

function SpookySnacksMiniMachine:enterLevel( )
    SpookySnacksMiniMachine.super.enterLevel(self)
end

function SpookySnacksMiniMachine:enterLevelMiniSelf( )

    SpookySnacksMiniMachine.super.enterLevel(self)
    
end

function SpookySnacksMiniMachine:dealSmallReelsSpinStates( )
    
end

-- 处理特殊关卡 遮罩层级
function SpookySnacksMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function SpookySnacksMiniMachine:getBounsScatterDataZorder(_symbolType )
   
    return self.m_machine:getBounsScatterDataZorder(_symbolType )

end

function SpookySnacksMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function SpookySnacksMiniMachine:checkGameResumeCallFun( )
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

function SpookySnacksMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function SpookySnacksMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function SpookySnacksMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end



---
-- 清空掉产生的数据
--
function SpookySnacksMiniMachine:clearSlotoData()
    
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
function SpookySnacksMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function SpookySnacksMiniMachine:clearCurMusicBg( )
    
end


function SpookySnacksMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()
end

--[[
    reSpin相关
]]
-- 继承底层respinView
function SpookySnacksMiniMachine:getRespinView()
    return "CodeSpookySnacksSrc.SpookySnacksRespinView"
end
-- 继承底层respinNode
function SpookySnacksMiniMachine:getRespinNode()
    return "CodeSpookySnacksSrc.SpookySnacksRespinNode"
end

--结束移除小块调用结算特效
function SpookySnacksMiniMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    -- self:playChipCollectAnim()
end

-- 根据本关卡实际小块数量填写
function SpookySnacksMiniMachine:getRespinRandomTypes( )
    local symbolList = { 
        self.SYMBOL_BONUS1,
        self.SYMBOL_BONUS2,
        self.SYMBOL_BONUS3,
        self.SYMBOL_SCORE_BLANK}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function SpookySnacksMiniMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS1, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_BONUS2, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_BONUS3, runEndAnimaName = "buling", bRandom = true},
    }

    return symbolList
end

function SpookySnacksMiniMachine:showRespinView()

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()

    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)

end

function SpookySnacksMiniMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()
    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            if self.m_machineIndex == 1 then 
                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                
            end
            
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--ReSpin开始改变UI状态
function SpookySnacksMiniMachine:changeReSpinStartUI(respinCount)
    self.m_machine:changeReSpinStartUI(respinCount)
end

--ReSpin刷新数量
function SpookySnacksMiniMachine:changeReSpinUpdateUI(curCount)
    if self.m_machineIndex == 1 then 
        print("当前展示位置信息  %d ", curCount)
        self.m_machine:changeReSpinUpdateUI(curCount,false)
    end
end

--ReSpin结算改变UI状态
function SpookySnacksMiniMachine:changeReSpinOverUI()

end

-- --重写组织respinData信息
function SpookySnacksMiniMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        
        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

function SpookySnacksMiniMachine:initMiniReelData(_data)
    self.m_runSpinResultData.p_reels = _data.reels
    self.m_runSpinResultData.p_storedIcons = _data.storedIcons
    self.m_runSpinResultData.p_pos = _data.pos
    self.m_runSpinResultData.p_reSpinCurCount = 3
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]
            if symbolType < self.SYMBOL_BONUS1 or symbolType == self.m_machine.SYMBOL_BONUS4 then
                self.m_runSpinResultData.p_reels[iRow][iCol] = self.SYMBOL_SCORE_BLANK
            end
            if symbolType == self.SYMBOL_BONUS3 then
                self.m_runSpinResultData.p_reels[iRow][iCol] = self.SYMBOL_BONUS1
            end
        end
    end
end

function SpookySnacksMiniMachine:initMiniReelDataMini(_data)
    self.m_runSpinResultData.p_reels = _data.reels
    self.m_runSpinResultData.p_storedIcons = _data.storedIcons
    self.m_runSpinResultData.p_pos = _data.pos
end

-- 根据网络数据获得respinBonus小块的分数
function SpookySnacksMiniMachine:getReSpinSymbolScore(_id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = nil
    local idNode = nil
    local symbolType = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == _id then
            score = values[3]
            if values[4] then
                score = values[4]
            else
                score = score * lineBet
            end
            symbolType = values[2]
            idNode = values[1]
        end
    end

    if symbolType == self.SYMBOL_BONUS3 then
        score = 1 * lineBet
    end

    if score == nil then
       return 1 * lineBet
    end

    

    return score
end


function SpookySnacksMiniMachine:randomDownRespinSymbolScore(_symbolType)
    local score = nil
    
    if _symbolType == self.SYMBOL_BONUS1 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_machine.m_configData:getFixSymbolPro()
    end
    local lineBet = globalData.slotRunData:getCurTotalBet()
    score = score * lineBet
    return score
end

--新滚动使用
function SpookySnacksMiniMachine:updateReelGridNode(_symblNode)
    local symbolType = _symblNode.p_symbolType
    if symbolType == self.SYMBOL_BONUS1 then
        -- local aniNode = _symblNode:checkLoadCCbNode()     
        -- local spine = aniNode.m_spineNode
        -- if spine and not tolua.isnull(spine.m_bindCsbNode) then

        --     util_spineRemoveBindNode(spine,spine.m_bindCsbNode)
        --     spine.m_bindCsbNode = nil
        -- end
        self.m_machine:setSpecialNodeScore(self,{_symblNode, self.m_machineIndex})
    end

    if symbolType == self.SYMBOL_BONUS3 then
        -- self.m_machine:setSpecialNodeBonus3(self,{_symblNode})
    end
    if _symblNode.p_symbolType ~= self.SYMBOL_SCORE_BLANK then
        _symblNode:setScale(0.75)
    end
    -- if _symblNode.m_isLastSymbol == true then
        
    -- else
    --     if self.m_machine.isChangeRespinBonus3 and symbolType == self.SYMBOL_BONUS3 then
    --         self.m_machine:changeSymbolType(_symblNode,self.SYMBOL_SCORE_BLANK,true)
    --         _symblNode:setScale(1)
    --     end
    -- end
    
end

-- 延时函数
function SpookySnacksMiniMachine:waitWithDelay(time, endFunc)
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

---判断结算
function SpookySnacksMiniMachine:reSpinReelDown(addNode)
    if self.m_machine.m_isGetIndexMini == false then
        self.m_machine:getIndexReelMiniNoJiMan()
    end
    self.m_machine.m_isGetIndexMini = true
    
    --检测是否所有轮盘都已经停轮
    if self.m_machine:isAllRespinViewDown() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self:waitWithDelay(0.5,function()
            self.m_machine:reSpinSelfReelDown(addNode)
        end)
    end
    
end

--[[
    检测respin是否停轮
]]
function SpookySnacksMiniMachine:isRespinViewDown()
    return self.m_respinView.m_isRepinDown
end

--开始下次ReSpin
function SpookySnacksMiniMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        self.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end
    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
                self:startReSpinRun()
            end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
end

function SpookySnacksMiniMachine:changeBonusType(isChangeRespinBonus3)
    self.isChangeRespinBonus3 = isChangeRespinBonus3
end

function SpookySnacksMiniMachine:changeActNodeZOrder(symbolNode,oldParent,oldPosition,isChange)
    if isChange then
        --播放动画时，切换层级
        local nodePos = util_convertToNodeSpace(symbolNode,self)
        util_changeNodeParent(self, symbolNode, 1000 + symbolNode.p_cloumnIndex * 10 - symbolNode.p_rowIndex)
        symbolNode:setPosition(nodePos)
    else
        util_changeNodeParent(oldParent, symbolNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + symbolNode.p_cloumnIndex * 10 - symbolNode.p_rowIndex)
        symbolNode:setPosition(oldPosition)
    end
end


return SpookySnacksMiniMachine
