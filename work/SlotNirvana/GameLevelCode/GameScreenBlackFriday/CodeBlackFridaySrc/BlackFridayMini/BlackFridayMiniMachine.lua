---
-- xcyy
-- 2018-12-18 
-- BlackFridayMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"

local BlackFridayMiniMachine = class("BlackFridayMiniMachine", BaseMiniMachine)

BlackFridayMiniMachine.SYMBOL_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3--96
BlackFridayMiniMachine.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2--95
BlackFridayMiniMachine.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1--94
BlackFridayMiniMachine.SYMBOL_SCORE_BLANK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7--100

BlackFridayMiniMachine.m_machineIndex = nil -- csv 文件模块名字

BlackFridayMiniMachine.gameResumeFunc = nil
BlackFridayMiniMachine.gameRunPause = nil


local Main_Reels = 1

-- 构造函数
function BlackFridayMiniMachine:ctor()
    BlackFridayMiniMachine.super.ctor(self)

end

function BlackFridayMiniMachine:initData_( data )

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

function BlackFridayMiniMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("BlackFridayMiniConfig.csv", "LevelBlackFridayMiniConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function BlackFridayMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BlackFriday"
end

--小块
-- function BlackFridayMiniMachine:getBaseReelGridNode()
--     return "CodeBlackFridaySrc.BlackFridaySlotNode"
-- end

function BlackFridayMiniMachine:getMachineConfigName()

    local str = "Mini"


    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function BlackFridayMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)
    return ccbName

end

---
-- 读取配置文件数据
--
function BlackFridayMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function BlackFridayMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("BlackFriday/GameScreenBlackFridayMini.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode

    --光效层
    self.m_lightEffectNode = cc.Node:create()
    self:findChild("Node_1"):addChild(self.m_lightEffectNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    
end
---
--
function BlackFridayMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    BlackFridayMiniMachine.super.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function BlackFridayMiniMachine:addSelfEffect()
 
end


function BlackFridayMiniMachine:MachineRule_playSelfEffect(effectData)
    
    -- if effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT  then
        
    -- end

    return true
end

function BlackFridayMiniMachine:onEnter()
    -- if self.m_machine.m_isNeedChangeNode then
    --     return
    -- end

    BlackFridayMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function BlackFridayMiniMachine:addObservers()

    BlackFridayMiniMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:MachineRule_respinTouchSpinBntCallBack()
        end,
        ViewEventType.RESPIN_TOUCH_SPIN_BTN
    )
    
end

function BlackFridayMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function BlackFridayMiniMachine:playEffectNotifyChangeSpinStatus( )


end

function BlackFridayMiniMachine:quicklyStopReel(colIndex)


end

function BlackFridayMiniMachine:onExit()
    -- if self.m_machine.m_isNeedChangeNode then
    --     return
    -- end
    BlackFridayMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function BlackFridayMiniMachine:removeObservers()
    BlackFridayMiniMachine.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end



function BlackFridayMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage( WAITING_DATA )
    if self.m_machineIndex == 1 then
        self.m_machine.m_isGetIndexMini = false
        self.m_machine:requestSpinReusltData()

        self.m_machine.m_isPlayRespinGoldSiverSound = false
    end
end


function BlackFridayMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    BlackFridayMiniMachine.super.beginReel(self)

end


-- 消息返回更新数据
function BlackFridayMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:initMiniReelDataMini(self.m_runSpinResultData.p_rsExtraData["reels"..self.m_machineIndex])
    self.m_runSpinResultData.p_winLines = {}
    self:updateNetWorkData()
end

function BlackFridayMiniMachine:enterLevel( )
    BlackFridayMiniMachine.super.enterLevel(self)
end

function BlackFridayMiniMachine:enterLevelMiniSelf( )

    BlackFridayMiniMachine.super.enterLevel(self)
    
end

function BlackFridayMiniMachine:dealSmallReelsSpinStates( )
    
end

-- 处理特殊关卡 遮罩层级
function BlackFridayMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function BlackFridayMiniMachine:getBounsScatterDataZorder(_symbolType )
   
    return self.m_machine:getBounsScatterDataZorder(_symbolType )

end

function BlackFridayMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function BlackFridayMiniMachine:checkGameResumeCallFun( )
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

function BlackFridayMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function BlackFridayMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function BlackFridayMiniMachine:resumeMachine()
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
function BlackFridayMiniMachine:clearSlotoData()
    
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
function BlackFridayMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function BlackFridayMiniMachine:clearCurMusicBg( )
    
end


function BlackFridayMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()
end

--[[
    reSpin相关
]]
-- 继承底层respinView
function BlackFridayMiniMachine:getRespinView()
    return "CodeBlackFridaySrc.BlackFridayMini.BlackFridayRespinView"
end
-- 继承底层respinNode
function BlackFridayMiniMachine:getRespinNode()
    return "CodeBlackFridaySrc.BlackFridayMini.BlackFridayRespinNode"
end

--结束移除小块调用结算特效
function BlackFridayMiniMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    -- self:playChipCollectAnim()
end

-- 根据本关卡实际小块数量填写
function BlackFridayMiniMachine:getRespinRandomTypes( )
    local symbolList = { 
        self.SYMBOL_BONUS1,
        self.SYMBOL_BONUS2,
        self.SYMBOL_BONUS3,
        self.SYMBOL_SCORE_BLANK}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function BlackFridayMiniMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS1, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_BONUS2, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_BONUS3, runEndAnimaName = "buling", bRandom = true},
    }

    return symbolList
end

function BlackFridayMiniMachine:showRespinView()

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()

    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)

end

function BlackFridayMiniMachine:initRespinView(endTypes, randomTypes)
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
function BlackFridayMiniMachine:changeReSpinStartUI(respinCount)
    self.m_machine:changeReSpinStartUI(respinCount)
end

--ReSpin刷新数量
function BlackFridayMiniMachine:changeReSpinUpdateUI(curCount)
    if self.m_machineIndex == 1 then 
        print("当前展示位置信息  %d ", curCount)
        self.m_machine:changeReSpinUpdateUI(curCount,false)
    end
end

--ReSpin结算改变UI状态
function BlackFridayMiniMachine:changeReSpinOverUI()

end

-- --重写组织respinData信息
function BlackFridayMiniMachine:getRespinSpinData()
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

function BlackFridayMiniMachine:initMiniReelData(_data)
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
        end
    end
end

function BlackFridayMiniMachine:initMiniReelDataMini(_data)
    self.m_runSpinResultData.p_reels = _data.reels
    self.m_runSpinResultData.p_storedIcons = _data.storedIcons
    self.m_runSpinResultData.p_pos = _data.pos
end

-- 根据网络数据获得respinBonus小块的分数
function BlackFridayMiniMachine:getReSpinSymbolScore(_id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local score = nil
    local idNode = nil
    local symbolType = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == _id then
            score = values[3]
            if values[4] then
                score = values[4]
            end
            symbolType = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end

    return score
end


function BlackFridayMiniMachine:randomDownRespinSymbolScore(_symbolType)
    local score = nil
    
    if _symbolType == self.SYMBOL_BONUS1 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_machine.m_configData:getFixSymbolPro()
    end

    return score
end

--新滚动使用
function BlackFridayMiniMachine:updateReelGridNode(_symblNode)
    local symbolType = _symblNode.p_symbolType
    if symbolType == self.SYMBOL_BONUS1 then
        self.m_machine:setSpecialNodeScore(self,{_symblNode, self.m_machineIndex})
    end

    if symbolType == self.SYMBOL_BONUS3 then
        self.m_machine:setSpecialNodeBonus3(self,{_symblNode})
    end

    _symblNode:setScale(0.75)
end

-- 延时函数
function BlackFridayMiniMachine:waitWithDelay(time, endFunc)
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
function BlackFridayMiniMachine:reSpinReelDown(addNode)
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
function BlackFridayMiniMachine:isRespinViewDown()
    return self.m_respinView.m_isRepinDown
end

--开始下次ReSpin
function BlackFridayMiniMachine:runNextReSpinReel()
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

return BlackFridayMiniMachine
