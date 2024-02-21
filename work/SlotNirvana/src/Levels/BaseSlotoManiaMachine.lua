---
-- island
-- 2018年4月2日
-- BaseSlotoManiaMachine.lua
-- FIX IOS 139
--
--
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = require "Levels.BaseMachine"
local BaseSlots = require "Levels.BaseSlots"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SpinResultData = require "data.slotsdata.SpinResultData"

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local CollectData = require "data.slotsdata.CollectData"

local json = require "json"

--关卡界面继承于BaseMachine
local BaseSlotoManiaMachine = class("BaseSlotoManiaMachine", BaseMachine)

GD.SLOTO_FEATURE = {
    FEATURE_FREESPIN = 1,
    FEATURE_FREESPIN_FS = 2, -- freespin 中再次触发fs
    FEATURE_RESPIN = 3, -- 触发respin 玩法
    FEATURE_MINI_GAME_COLLECT = 4, -- 收集玩法小游戏
    FEATURE_MINI_GAME_OTHER = 5, -- 其它小游戏
    FEATURE_JACKPOT = 6 -- 触发 jackpot
}

GD.SLOTO_DEFAULT_SYMBOL = 20000 -- 如果配置了此类型到对应表中那么表明， 其他类型均用此来处理

--定义成员变量
BaseSlotoManiaMachine.m_spinResultName = nil -- spin 结果名字
BaseSlotoManiaMachine.m_spinFileIndex = nil -- spin 结文件索引

BaseSlotoManiaMachine.m_runSpinResultData = nil -- 当前spin 运行结果

-- BaseSlotoManiaMachine.m_runNexSpinResultData = nil -- 下一次数据，用来临时计算使用
BaseSlotoManiaMachine.m_featureData = nil -- 用户操作数据
BaseSlotoManiaMachine.m_configData = nil -- 关卡配置数据
BaseSlotoManiaMachine.m_initBetId = nil -- 之前关卡退出时的total bet

BaseSlotoManiaMachine.m_lineDataPool = nil -- 赢钱线数据池
BaseSlotoManiaMachine.m_gameLineType = nil
BaseSlotoManiaMachine.m_lineCount = nil -- 线数量

--- 进入关卡时请求的 spin 和 feature 数据，用来恢复退出关卡时的进度
BaseSlotoManiaMachine.m_initSpinData = nil
BaseSlotoManiaMachine.m_initFeatureData = nil

BaseSlotoManiaMachine.m_collectDataList = nil --收集数据

BaseSlotoManiaMachine.m_isJackpotEnable = nil --本关卡是否启用jackpot
BaseSlotoManiaMachine.m_jackpotList = nil --jackpot累积值

BaseSlotoManiaMachine.m_waitChangeReelTime = nil

BaseSlotoManiaMachine.m_bQuestComplete = nil ---本关起quest是否完成

BaseSlotoManiaMachine.m_questView = nil

BaseSlotoManiaMachine.m_preVipLevel = nil
BaseSlotoManiaMachine.m_preVipPoints = nil

BaseSlotoManiaMachine.m_gameCrazeBuff = nil

BaseSlotoManiaMachine.m_iBetLevel = nil -- 高低bet数据传输变量 高低bet玩法只需修改此变量

BaseSlotoManiaMachine.m_randomSymbolIndex = nil -- 游戏进入随机轮盘小块索引
BaseSlotoManiaMachine.m_randomSymbolSwitch = nil -- 游戏进入随机轮盘小块索引开关
BaseSlotoManiaMachine.b_gameTipFlag = false -- 预告中奖标识

-- 构造函数
function BaseSlotoManiaMachine:ctor()
    print("BaseSlotoManiaMachine:ctor")

    BaseMachine.ctor(self)

    self.m_bQuestComplete = false
    globalData.slotRunData.totalFreeSpinCount = 0
    self.m_lineDataPool = {}
    self.m_lineCount = 50
    self.m_iBetLevel = nil
    self.m_randomSymbolIndex = nil
    self.m_randomSymbolSwitch = false
    self.b_gameTipFlag = false -- 预告中奖标识

    self.m_runSpinResultData = SpinResultData.new()
    self.m_featureData = SpinFeatureData.new()
end

function BaseSlotoManiaMachine:getSlotNodeBySymbolType(symbolType)
    return BaseMachine.getSlotNodeBySymbolType(self, symbolType)
end

function BaseSlotoManiaMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    return BaseMachine.getSlotNodeWithPosAndType(self, symbolType, row, col, isLastSymbol)
end

function BaseSlotoManiaMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    globalData.slotRunData.gameModuleName = self.m_moduleName
    globalData.slotRunData.gameNetWorkModuleName = self:getNetWorkModuleName()
    if globalData.slotRunData.isDeluexeClub == true then
        globalData.slotRunData.gameNetWorkModuleName = globalData.slotRunData.gameNetWorkModuleName .. "_H"
    end
    globalData.slotRunData.lineCount = self.m_lineCount
    BaseMachine.initMachine(self)
end

function BaseSlotoManiaMachine:getValidSymbolMatrixArray()
    return table_createTwoArr(self.m_iReelRowNum, self.m_iReelColumnNum, TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function BaseSlotoManiaMachine:initMachineData()
    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName .. "_Datas"

    globalData.slotRunData.gameModuleName = self.m_moduleName

    -- 设置bet index

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

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

function BaseSlotoManiaMachine:getMachineConfigName()
    return self.m_moduleName .. "Config.csv"
end

function BaseSlotoManiaMachine:getMachineConfigParseLuaName()

    return  nil -- "Level" .. self.m_moduleName.."Config.lua"
end

--更新基础数据
--4.赋值区(LevelConfigData)
function BaseSlotoManiaMachine:updateBaseConfig()
    --读取csv配置
    self:readCSVConfigData()
    --基础
    self:readBaseConfigData()
    --轮盘
    self:readReelConfigData()
    --音乐
    self:readSoundConfigData()
    --类型
    self:readTypeConfigData()
end

---
-- 读取配置文件数据
--
function BaseSlotoManiaMachine:readCSVConfigData()
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(),self:getMachineConfigParseLuaName())
    end
    globalData.slotRunData.levelConfigData = self.m_configData
end
--[[
    @desc: 读取基础配置信息
    time:2020-07-11 18:54:31
    @return:
]]
function BaseSlotoManiaMachine:readBaseConfigData()
    --关卡线数
    self.m_lineCount = self.m_configData.p_lineCount
    --是否为满线关卡
    self.m_isAllLineType = self.m_configData.p_isAllLineType
    --轮盘列数
    self.m_iReelColumnNum = self.m_configData.p_columnNum
    --轮盘行数
    self.m_iReelRowNum = self.m_configData.p_rowNum
    --轮盘宽度
    self.m_reelWidth = self.m_configData.p_reelWidth
    --轮盘高度
    self.m_reelHeight = self.m_configData.p_reelHeight
end
--[[
    @desc: 读取轮盘配置信息
    time:2020-07-11 18:55:11
]]
function BaseSlotoManiaMachine:readReelConfigData()
    self.m_ScatterShowCol = self.m_configData.p_scatterShowCol --标识哪一列会出现scatter
    self.m_validLineSymNum = self.m_configData.p_validLineSymNum --触发sf，bonus需要的数量
    self:setReelEffect(self.m_configData.p_reelEffectRes)
    --配置快滚效果资源名称
    self:setReelBgEffect(self.m_configData.p_reelBgEffectRes)
    --配置快滚背景效果资源名称
    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() or 3 --连线框播放时间
end

--[[
    @desc: 读取音乐、音效配置信息
    time:2020-07-11 18:55:11
]]
function BaseSlotoManiaMachine:readSoundConfigData()
    --背景音乐
    self:setBackGroundMusic(self.m_configData.p_musicBg)
    --fs背景音乐
    self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)
    --respin背景
    self:setRsBackGroundMusic(self.m_configData.p_musicReSpinBg)
    --scatter提示音
    self.m_ScatterTipMusicPath = self.m_configData.p_soundScatterTip
    --bonus提示音
    self.m_BonusTipMusicPath = self.m_configData.p_soundBonusTip
    --下落音
    self:setReelDownSound(self.m_configData.p_soundReelDown)
    --快停下落音
    self:setQuickStopReelDownSound(self.m_configData.p_soundReelDownQuickStop)
    --快滚音效
    self:setReelRunSound(self.m_configData.p_reelRunSound)
end
--[[
    @desc: 读取类型配置信息， 主要是slots 处理部分逻辑
    time:2020-07-11 18:55:11
]]
function BaseSlotoManiaMachine:readTypeConfigData()
    self.m_enumWildType = self.m_configData.p_enumWildType --wild类型
    self.m_iRandomSmallSymbolTypeNum = self.m_configData.p_randomSmallSymbolNum --从0到9进行随机
    self.m_bigSymbolInfos = self.m_configData.p_bigSymbolTypeCounts --大信号类型
    self.m_iRandomScatter = true -- 是否随机scatter
    self.m_iRandomBonus = false -- 是否随机bonus
    self.m_iRandomWild = true -- 是否随机 wild
end

function BaseSlotoManiaMachine:freeRequest()
    performWithDelay(
        self,
        function()
            self:requestSpinResult()
        end,
        0.5
    ) 
end

function BaseSlotoManiaMachine:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:freeRequest()
    else
        self:requestSpinResult()
    end

    self.m_isWaitingNetworkData = true

    self:setGameSpinStage(WAITING_DATA)
    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() == RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false, true})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function BaseSlotoManiaMachine:requestSpinResult()
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin(  ) then

                self.m_topUI:updataPiggy(betCoin)
                isFreeSpin = false
    end
    
    self:updateJackpotList()
    
    self:setSpecialSpinStates(false )

    -- 拼接 collect 数据， jackpot 数据
    local messageData = self:getSpinMessageData()
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function BaseSlotoManiaMachine:getSpinMessageData()
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    return messageData
end

--[[
    @desc: 获取消息来后等待的时间， 也就是说直到滚动时间结束，轮盘不允许点击快停
    目前只是应用在普通模式， respin 模式暂时不处理
    time:2018-06-15 11:54:13
    return time
]]
function BaseSlotoManiaMachine:getWaitTimeWithReelStop()
    return 0
end

--添加滚轴停止等待时间
function BaseSlotoManiaMachine:setWaitChangeReelTime(time)
    self.m_waitChangeReelTime = time
end

---
--根据关卡玩法重新设置滚动信息
function BaseSlotoManiaMachine:MachineRule_ResetReelRunData()
    BaseSlotoManiaMachine.super.MachineRule_ResetReelRunData(self)
    if self.b_gameTipFlag then
        for i = 1, #self.m_reelRunInfo do
            local runInfo = self.m_reelRunInfo[i]
            runInfo:setReelRunLen(runInfo.initInfo.reelRunLen)
            runInfo:setNextReelLongRun(runInfo.initInfo.bReelRun)      
            runInfo:setReelLongRun(true)
        end
    end
end

-- 播放预告中奖统一接口
-- 子类重写接口
function BaseSlotoManiaMachine:showFeatureGameTip(_func)
    local isShow = false

    if isShow then
        -- 播放预告动画,播放完毕后调用func
        self.b_gameTipFlag = true
        if _func then
            _func()
        end 
    else
        if _func then
            _func()
        end 
    end
end

--[[
    播放预告中奖概率
    GD.SLOTO_FEATURE = {
        FEATURE_FREESPIN = 1,
        FEATURE_FREESPIN_FS = 2, -- freespin 中再次触发fs
        FEATURE_RESPIN = 3, -- 触发respin 玩法
        FEATURE_MINI_GAME_COLLECT = 4, -- 收集玩法小游戏
        FEATURE_MINI_GAME_OTHER = 5, -- 其它小游戏
        FEATURE_JACKPOT = 6 -- 触发 jackpot
    }
]]
function BaseSlotoManiaMachine:getFeatureGameTipChance(_probability)
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 then
        -- 出现预告动画概率默认为30%
        local probability = 30
        if _probability then
            probability = _probability
        end
        local isNotice = (math.random(1, 100) <= probability) 
        return isNotice
    end
    
    return false
end


--[[
    获取停轮前假滚时间
]]
function BaseSlotoManiaMachine:getRunTimeBeforeReelDown()
    --获取滚动速度
    local moveSpeed = self.m_configData.p_reelMoveSpeed
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_configData.p_fsReelMoveSpeed then
        moveSpeed = self.m_configData.p_fsReelMoveSpeed
    end
    --获取滚动距离
    local runLen = self.m_configData.p_reelRunDatas[1]
    local distance = self.m_SlotNodeH * runLen
    local delayTime = distance / moveSpeed

    return delayTime
end


function BaseSlotoManiaMachine:updateNetWorkData()
    self:showFeatureGameTip(
        function()
            gLobalDebugReelTimeManager:recvStartTime()

            local isReSpin = self:updateNetWorkData_ReSpin()
            if isReSpin == true then
                return
            end
            self:produceSlots()

            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end

            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end
    )
end

--[[
    @desc: 检测是否需要延迟处理网络消息
    time:2020-07-20 18:19:37
    @return:
]]
function BaseSlotoManiaMachine:checkWaitOperaNetWorkData()
    --存在等待时间延后调用下面代码
    if self.m_waitChangeReelTime and self.m_waitChangeReelTime > 0 then
        scheduler.performWithDelayGlobal(
            function()
                self.m_waitChangeReelTime = nil
                self:updateNetWorkData()
            end,
            self.m_waitChangeReelTime,
            self:getModuleName()
        )
        return true
    end
    return false
end

function BaseSlotoManiaMachine:updateNetWorkData_ReSpin()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
        self:produceSlots()
        self:getRandomList()

        self:stopRespinRun()
        return true
    end
    return false
end
--[[
    @desc: 检测是否有大信号
    time:2020-07-21 17:03:06
    @return:
]]
function BaseSlotoManiaMachine:checkHasBigSymbolWithNetWork()
    local lastNodeIsBigSymbol = false
    local maxDiff = 0
    for i = 1, #self.m_slotParents do
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH
        -- print(i .. "列，不考虑补偿计算的移动距离 " ..  moveL)

        local preY, isLastBigSymbol, realChildCount = self:checkLastSymbolInfo(slotParent, slotParentBig)

        if isLastBigSymbol == true then
            lastNodeIsBigSymbol = true
        end
        local parentY = slotParent:getPositionY()
        -- 按照逻辑处理来说， 各列的moveDiff非长条模式是相同的，长条模式需要将剩余的补齐
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
        if realChildCount == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
            moveDiff = 0
        end
        moveL = moveL + moveDiff

        parentData.moveDistance = parentY - moveL
        parentData.moveL = moveL
        parentData.moveDiff = moveDiff
        parentData.preY = preY

        maxDiff = util_max(maxDiff, math.abs(moveDiff))

        -- self:createSlotNextNode(parentData)
    end

    return lastNodeIsBigSymbol, maxDiff
end

function BaseSlotoManiaMachine:checkLastSymbolInfo(slotParent, slotParentBig)
    local childs = slotParent:getChildren()
    if slotParentBig then
        local newChilds = slotParentBig:getChildren()
        for j = 1, #newChilds do
            childs[#childs + 1] = newChilds[j]
        end
    end

    local preY = 0
    local isLastBigSymbol = false
    local realChildCount = #childs

    for childIndex = 1, #childs do
        local child = childs[childIndex]
        local isVisible = child:isVisible()
        local childY = child:getPositionY()
        local topY = nil
        local nodeH = child.p_slotNodeH or 144
        if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
            local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
            topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            isLastBigSymbol = true
        else
            topY = childY + nodeH * 0.5
            isLastBigSymbol = false
        end

        if topY < preY and isLastBigSymbol == false then
            isLastBigSymbol = false
        end

        preY = util_max(preY, topY)
    end

    return preY, isLastBigSymbol, realChildCount
end

function BaseSlotoManiaMachine:operaBigSymbolWithNetWork(maxDiff)
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        if #slotParent:getChildren() == 0 and #slotParentBig:getChildren() == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
            parentData.moveDiff = maxDiff
        end

        local parentY = slotParent:getPositionY()
        local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH

        moveL = moveL + maxDiff

        -- 补齐到长条高度
        local diffDis = maxDiff - math.abs(parentData.moveDiff)

        if diffDis > 0 then
            self:operaBigSymbolAddCounts(diffDis, columnData, parentData)
        end

        parentData.moveDistance = parentY - moveL

        parentData.moveL = moveL
        parentData.moveDiff = nil
        self:createSlotNextNode(parentData)
    end
end

function BaseSlotoManiaMachine:operaBigSymbolAddCounts(diffDis, columnData, parentData)
    local nodeCount = math.floor(diffDis / columnData.p_showGridH)
    local slotParent = parentData.slotParent
    for addIndex = 1, nodeCount do
        local symbolType = self:getNormalSymbol(parentData.cloumnIndex)
        local node = self:getSlotNodeWithPosAndType(symbolType, 1, 1, false)
        node.p_slotNodeH = columnData.p_showGridH
        local posY = parentData.preY + (addIndex - 1) * columnData.p_showGridH + columnData.p_showGridH * 0.5
        node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
        node:setPositionY(posY)

        slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    end
end

function BaseSlotoManiaMachine:operaNormalSymbolWithNetWork()
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        self:createSlotNextNode(parentData)
    end
end

function BaseSlotoManiaMachine:dealSmallReelsSpinStates()
    if not self.b_gameTipFlag then
        if self:getOperaNetWorkStopBtnResetStatus() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
        end
    end
end
--可重写-数据返回时是否可以恢复stop按钮状态
function BaseSlotoManiaMachine:getOperaNetWorkStopBtnResetStatus()
   if self.b_gameTipFlag then
       return false
   end
   return true
end

function BaseSlotoManiaMachine:operaNetWorkData()
    self:dealSmallReelsSpinStates()

    local lastNodeIsBigSymbol, maxDiff = self:checkHasBigSymbolWithNetWork()

    -- 检测假数据滚动时最后一个格子是否为 bigSymbol，
    -- 如果是那么其他列补齐到与最大bigsymbol同样的高度
    if lastNodeIsBigSymbol == true then
        self:operaBigSymbolWithNetWork(maxDiff)
    else
        self:operaNormalSymbolWithNetWork()
    end

    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

---
-- 重写计算数据和 连线的函数, 直接从数据表中读取
function BaseSlotoManiaMachine:MachineRule_RestartProbabilityCtrl()
    -- 计算结果数据
    self:MachineRule_network_ProbabilityCtrl()
    self:MachineRule_network_InterveneSymbolMap()
    -- 计算连线数据
    self:netWorklineLogicCalculate()
    self:MachineRule_afterNetWorkLineLogicCalculate()
end
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function BaseSlotoManiaMachine:MachineRule_network_InterveneSymbolMap()
end

---
-- 初始化轮盘界面, 已进入游戏时初始化
--
function BaseSlotoManiaMachine:initMachineGame()
end
--[[
    @desc: 检测是否更改默认 bet
    time:2019-01-04 18:01:55
    @return:
]]
function BaseSlotoManiaMachine:checkUpateDefaultBet()
    --------------- cxc ---------------
    -- 2021-01-13 21:39:05 关闭bet 选择功能
    -- local hasFeature = self:checkHasFeature() -- 有没有特殊玩法
    -- local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    -- local bQuestEnter = false -- 是不是Quest进入的关卡
    -- if questConfig and questConfig.m_IsQuestLogin then
    --     bQuestEnter = true
    -- end
    -- local bChooseBetOpen = globalData.GameConfig:checkChooseBetOpen() --选择bet界面功能是否开启
    -- -- 没有特殊玩法 并且 选择玩家通过 了bet选择页面进来 (不使用服务器bet值)
    -- if not hasFeature and bChooseBetOpen and not bQuestEnter then
    --     return
    -- end
    --------------- cxc ---------------

    --  玩家没有通过 选择界面bet进来的 还使用之前服务器存储的上一个betId (Quest 或者 关卡有特殊玩法 )
    if self.m_initBetId ~= -1 then
        local hasBet = globalData.slotRunData:checkBetIdxInList(self.m_initBetId)
        if hasBet == true then
            local isCoinPusherEnterLevel = G_GetMgr(ACTIVITY_REF.CoinPusher):isCoinPusherEnterLevel()
            local isEgyptCoinPusherEnterLevel = G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):isCoinPusherEnterLevel()
            if (not isCoinPusherEnterLevel) and (not isEgyptCoinPusherEnterLevel) then
                globalData.slotRunData.iLastBetIdx = self.m_initBetId
            end
        end
    end
end

--[[
    @desc: 检测上次轮盘状态
    time:2019-01-04 18:18:53
    @return: 是否需要播放 playGameEffect()
]]
function BaseSlotoManiaMachine:checkNetDataCloumnStatus()
    local featureDatas = self.m_initSpinData.p_features
    local hasFreepinFeature = false
    local hasBonusGame = false
    if featureDatas ~= nil then
        for i = 1, #featureDatas do
            local featureId = featureDatas[i]
            if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then
                -- 表明触发了更多 freespin
                if self.m_initSpinData.p_freeSpinsTotalCount > self.m_initSpinData.p_freeSpinsLeftCount then
                    self:triggerFreeSpinCallFun()
                end
                self.m_bProduceSlots_InFreeSpin = true
                hasFreepinFeature = true
                local params = {self:getLastWinCoin(), false, false}
                params[self.m_stopUpdateCoinsSoundIndex] = true
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                break
            end
            if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                hasBonusGame = true
            end
        end
    end
    local isPlayGameEff = false

    -- 判断是否继续触发respin玩法  ，， 由于freespin 和 respin 是不会同时触发的，所以分开处理
    isPlayGameEff = self:checkTriggerInReSpin() or hasBonusGame

    -- local isTriggerEffect = false
    -- if isPlayGameEff == true  then
    --     if not hasBonusGame then
    --         isTriggerEffect = true
    --         self:playGameEffect()
    --     end
    -- end

    return isPlayGameEff
end
--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function BaseSlotoManiaMachine:checkTriggerInReSpin()
    local isPlayGameEff = false
    if self.m_initSpinData.p_reSpinsTotalCount ~= nil and self.m_initSpinData.p_reSpinsTotalCount > 0 and self.m_initSpinData.p_reSpinCurCount > 0 then
        --手动添加freespin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        local reSpinEffect = GameEffectData.new()
        reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
        reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

        self.m_isRunningEffect = true

        if self.checkControlerReelType and self:checkControlerReelType() then
            globalMachineController.m_isEffectPlaying = true
        end

        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function BaseSlotoManiaMachine:checkTriggerFsOver()
    if self.m_initSpinData.p_freeSpinsLeftCount == 0 then
        return true
    end
    return false
end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function BaseSlotoManiaMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end

    local isInFs = false
    if
        hasFreepinFeature == false and self.m_initSpinData.p_freeSpinsTotalCount ~= nil and self.m_initSpinData.p_freeSpinsTotalCount > 0 and
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or (hasReSpinFeature == true or hasBonusFeature == true))
     then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs == true then
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:setCurrSpinMode(FREE_SPIN_MODE)

        if self:checkTriggerFsOver() then
            local fsOverEffect = GameEffectData.new()
            fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
        end

        -- 发送事件显示赢钱总数量
        local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

---
-- 检测上次feature 数据
--
function BaseSlotoManiaMachine:checkNetDataFeatures()
    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            -- self:sortGameEffects( )
            -- self:playGameEffect()
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true

            if self.checkControlerReelType and self:checkControlerReelType() then
                globalMachineController.m_isEffectPlaying = true
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]

                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1

                        local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER

                            for addPosIndex = 1, #lineData.p_iconPos do
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
                end
                if checkEnd == true then
                    break
                end
            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then -- respin 玩法一并通过respinCount 来进行判断处理
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            -- if self.m_initFeatureData.p_status=="CLOSED" then
            --     return
            -- end

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true

            if self.checkControlerReelType and self:checkControlerReelType() then
                globalMachineController.m_isEffectPlaying = true
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]

                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1

                        local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS

                            for addPosIndex = 1, #lineData.p_iconPos do
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

--[[
    初始轮盘
]]
function BaseSlotoManiaMachine:initRandomSlotNodes()
    if type(self.m_configData.isHaveInitReel) == "function" and self.m_configData:isHaveInitReel() then
        self:initSlotNodes()
    else
        if self.m_currentReelStripData == nil then
            self:randomSlotNodes()
        else
            self:randomSlotNodesByReel()
        end
    end
end

--[[
    根据配置初始轮盘
]]
function BaseSlotoManiaMachine:initSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local initDatas = self.m_configData:getInitReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        local startIndex = 1
        --大信号数量
        local bigSymbolCount = 0
        for rowIndex = 1, rowCount do
            local symbolType = initDatas[startIndex]
            startIndex = startIndex + 1
            if startIndex > #initDatas then
                startIndex = 1
            end

            --判断是否是否属于需要隐藏
            local isNeedHide = false
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                bigSymbolCount = bigSymbolCount + 1
                if bigSymbolCount > 1 then
                    isNeedHide = true
                    symbolType = 0
                end

                if bigSymbolCount == self.m_bigSymbolInfos[symbolType] then
                    bigSymbolCount = 0
                end
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if isNeedHide then
                node:setVisible(false)
            end

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

function BaseSlotoManiaMachine:randomSlotNodesByReel()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1, resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]
            util_printLog("当前随机的信号值:"..symbolType)
            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType)

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

function BaseSlotoManiaMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)

            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            util_printLog("当前随机的信号值:"..symbolType)

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            --            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

---- lighting 断线重连时，随机转盘数据
function BaseSlotoManiaMachine:respinModeChangeSymbolType()
    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
        local storedIcons = self.m_initSpinData.p_storedIcons
        if storedIcons == nil or #storedIcons <= 0 then
            return
        end

        local function isInArry(iRow, iCol)
            for k = 1, #storedIcons do
                local fix = self:getRowAndColByPos(storedIcons[k][1])
                if fix.iX == iRow and fix.iY == iCol then
                    return true
                end
            end
            return false
        end

        for iRow = 1, #self.m_initSpinData.p_reels do
            local rowInfo = self.m_initSpinData.p_reels[iRow]
            for iCol = 1, #rowInfo do
                if isInArry(#self.m_initSpinData.p_reels - iRow + 1, iCol) == false then
                    rowInfo[iCol] = xcyy.SlotsUtil:getArc4Random() % util_min(8, self.m_iRandomSmallSymbolTypeNum)
                end
            end
        end
    end
end

function BaseSlotoManiaMachine:getinitSlotRowDatatByNetData(_columnData)
    local rowCount = _columnData.p_showGridCount --#self.m_initSpinData.p_reels
    local rowNum = _columnData.p_showGridCount
    local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。

    return rowCount, rowNum, rowIndex
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function BaseSlotoManiaMachine:initCloumnSlotNodesByNetData()
    self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount, rowNum, rowIndex = self:getinitSlotRowDatatByNetData(columnData)

        local isHaveBigSymbolIndex = false

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType)

            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP = true
                end
                for checkRowIndex = changeRowIndex + 1, rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if checkIndex == rowNum then
                                -- body
                                isUP = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

            -- grid.m_reelBottom

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) - changeRowIndex

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
                node:setVisible(true)
            end

            -- node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            node:runIdleAnim()
            rowIndex = rowIndex - stepCount
            print("999999999999")
        end -- end while
        
    end

    print("999999999999111111111111")
end

---
-- 从参考的假数据中获取数据
--
function BaseSlotoManiaMachine:getRandomReelType(colIndex, reelDatas)
    if reelDatas == nil or #reelDatas == 0 then
        return self:getNormalSymbol(colIndex)
    end
    local reelLen = #reelDatas

    if self.m_randomSymbolSwitch then
        -- 根据滚轮真实假滚数据初始化轮子信号小块
        if self.m_randomSymbolIndex == nil then
            self.m_randomSymbolIndex = util_random(1, reelLen)
        end
        self.m_randomSymbolIndex = self.m_randomSymbolIndex + 1
        if self.m_randomSymbolIndex > reelLen then
            self.m_randomSymbolIndex = 1
        end

        local symbolType = reelDatas[self.m_randomSymbolIndex]
        return symbolType
    else
        while true do
            local symbolType = reelDatas[util_random(1, reelLen)]
            return symbolType
        end
    end

    return nil
end

---
-- 处理spin 结果轮盘数据
--
function BaseSlotoManiaMachine:MachineRule_network_ProbabilityCtrl()
    local rowCount = #self.m_runSpinResultData.p_reels
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            local symbolType = rowDatas[colIndex]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_NIL_TYPE then
                symbolType = nil
            end

            --bugly调试日志
            if not self.m_stcValidSymbolMatrix[rowCount - rowIndex + 1] then
                local modelName = self:getModuleName()
                local str = modelName..":rowCount = "..rowCount.." rowIndex = "..rowIndex
                if self.m_stcValidSymbolMatrix then
                    str = str.." arryLength = "..(#self.m_stcValidSymbolMatrix)
                else
                    str = str.."self.m_stcValidSymbolMatrix is nil"
                end
                release_print(str)
            end
            self.m_stcValidSymbolMatrix[rowCount - rowIndex + 1][colIndex] = symbolType
        end
    end

    -- 处理大信号信息
    if self.m_hasBigSymbol == true then
        self.m_bigSymbolColumnInfo = {}
    else
        self.m_bigSymbolColumnInfo = nil
    end

    local iColumn = self.m_iReelColumnNum
    local iRow = self.m_iReelRowNum

    for colIndex = 1, iColumn do
        local rowIndex = 1

        while true do
            if rowIndex > iRow then
                break
            end
            local symbolType = self.m_stcValidSymbolMatrix[rowIndex][colIndex]
            -- 判断是否有大信号内容
            if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil then
                local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG, changeRows = {}}

                local colDatas = self.m_bigSymbolColumnInfo[colIndex]
                if colDatas == nil then
                    colDatas = {}
                    self.m_bigSymbolColumnInfo[colIndex] = colDatas
                end

                colDatas[#colDatas + 1] = bigInfo

                local symbolCount = self.m_bigSymbolInfos[symbolType]

                local hasCount = 1

                bigInfo.changeRows[#bigInfo.changeRows + 1] = rowIndex

                for checkIndex = rowIndex + 1, iRow do
                    local checkType = self.m_stcValidSymbolMatrix[checkIndex][colIndex]
                    if checkType == symbolType then
                        hasCount = hasCount + 1

                        bigInfo.changeRows[#bigInfo.changeRows + 1] = checkIndex
                    else
                        break
                    end
                    if symbolCount == hasCount then
                        break
                    end
                end

                if symbolCount == hasCount or rowIndex > 1 then -- 表明从对应索引开始的
                    bigInfo.startRowIndex = rowIndex
                else
                    bigInfo.startRowIndex = rowIndex - (symbolCount - hasCount)
                end

                rowIndex = rowIndex + hasCount - 1 -- 跳过上面有的
            end -- end if ~= nil

            rowIndex = rowIndex + 1
        end
    end
end
--[[
    @desc: 重置连线计算前的数据
    time:2020-07-21 20:35:38
    @return:
]]
function BaseSlotoManiaMachine:resetDataWithLineLogic()
    self:checkAndClearVecLines()
    self.m_iFreeSpinTimes = 0

    --计算连线之前将 计算连线中添加的动画效果移除 (防止重新计算连线后效果播放错误)
    self:removeEffectByType(GameEffect.EFFECT_FREE_SPIN)
    self:removeEffectByType(GameEffect.EFFECT_BONUS)
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end
--[[
    @desc: 计算每条应前线
    time:2020-07-21 20:48:31
    @return:
]]
function BaseSlotoManiaMachine:lineLogicWinLines()
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        self:compareScatterWinLines(winLines)

        for i = 1, #winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo, iconsPos)

            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())

            if lineInfo.iLineSymbolNum >= 5 then
                isFiveOfKind = true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end
    end

    return isFiveOfKind
end

function BaseSlotoManiaMachine:lineLogicEffectType(winLineData, lineInfo, iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData, lineInfo)

    if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

--[[
    @desc: 根据服务器返回的消息， 添加对应的feature 类型
    time:2018-12-04 17:34:04
    @return:
]]
function BaseSlotoManiaMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()

    local isFiveOfKind = self:lineLogicWinLines()

    if isFiveOfKind then
        self:addAnimationOrEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

    -- 根据features 添加具体玩法
    self:MachineRule_checkTriggerFeatures()
    self:staticsQuestEffect()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function BaseSlotoManiaMachine:MachineRule_afterNetWorkLineLogicCalculate()
    if self.m_videoPokeMgr then
       -- videoPoker 数据解析
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        self.m_videoPokeMgr.m_runData:parseData( selfdata ) 
    end
    
end

--[[
    @desc: 计算单线
    time:2018-08-16 19:35:49
    --@lineData: 
    @return:
]]
function BaseSlotoManiaMachine:getWinLineSymboltType(winLineData, lineInfo)
    local iconsPos = winLineData.p_iconPos
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for posIndex = 1, #iconsPos do
        local posData = iconsPos[posIndex]

        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData -- 连线元素的 pos信息

        local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
            enumSymbolType = symbolType
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
function BaseSlotoManiaMachine:compareScatterWinLines(winLines)
    local scatterLines = {}
    local winAmountIndex = -1
    for i = 1, #winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.p_iconPos
        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        for posIndex = 1, #iconsPos do
            local posData = iconsPos[posIndex]

            local rowColData = self:getRowAndColByPos(posData)
            print("rowColData.iX ===" .. rowColData.iX .. ",rowColData.iY == " .. rowColData.iY)
            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
                break -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end

        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            scatterLines[#scatterLines + 1] = {i, winLineData.p_amount}
            if winLineData.p_amount > 0 then
                winAmountIndex = i
            end
        end
    end

    if #scatterLines > 0 and winAmountIndex > 0 then
        for i = #scatterLines, 1, -1 do
            local lineData = scatterLines[i]
            if lineData[2] == 0 then
                table.remove(winLines, lineData[1])
            end
        end
    end
end

---
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function BaseSlotoManiaMachine:getRowAndColByPos(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = self.m_iReelRowNum - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex, iY = colIndex}
end

---
-- 获取信号类型
function BaseSlotoManiaMachine:getSpinResultReelsType(iCol, iRow)
    local rowCount = #self.m_runSpinResultData.p_reelsData
    local rowDatas = self.m_runSpinResultData.p_reelsData[rowCount - iRow + 1]
    if not rowDatas then
        return nil
    end
    local symbolType = rowDatas[iCol]
    return symbolType
end
---
-- -- 获取信号类型
-- function BaseSlotoManiaMachine:getSpinResultSpecialType(iCol, iRow)
--     return 0
-- end

function BaseSlotoManiaMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and #self.m_runSpinResultData.p_features > 0 then
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i = 1, featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的，
            -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
                featureID = SLOTO_FEATURE.FEATURE_FREESPIN
            end
            if featureID ~= 0 then
                if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                    self:addAnimationOrEffectType(GameEffect.EFFECT_FREE_SPIN)

                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)

                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount
                    else
                        -- 默认情况下，freesipn 触发了既获得fs次数，有玩法的继承此函数获得次数
                        globalData.slotRunData.totalFreeSpinCount = 0
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    end

                    globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + self.m_iFreeSpinTimes
                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then -- 触发respin 玩法
                    globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                    if self:getCurrSpinMode() == RESPIN_MODE then
                    else
                        local respinEffect = GameEffectData.new()
                        respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                        respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                        if globalData.slotRunData.iReSpinCount == 0 and #self.m_runSpinResultData.p_storedIcons == 15 then
                            respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                        end
                        self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then -- 其他小游戏
                    -- 添加 BonusEffect
                    self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end
            end
        end
    end
end

---
-- 解析行为数据
--
function BaseSlotoManiaMachine:parseFeatureData()
    local resultData = nil

    self.m_featureData:parseFeatureData(resultData)
end

function BaseSlotoManiaMachine:getSymbolWinRate(enumLineInfo, symbolType, lineSymbolNum)
    assert(enumLineInfo ~= nil, "enumLineInfo is nil")
    -- 只需要根据每条赢钱线的数据来判断具体是几倍
    return enumLineInfo.lineSymbolRate
end

function BaseSlotoManiaMachine:spinBtnEnProc()
    --TODO 处理repeat逻辑

    if self.m_isChangeBGMusic then
        gLobalSoundManager:playFreeSpinBackMusic(self:getFreeSpinMusicBG())
        self.m_isChangeBGMusic = false
    end

    if CC_NEWS_PERIOD_SHOW then
        self:newsPeriodShow()
    end

    self:beginReel()
end

function BaseSlotoManiaMachine:slotReelDown()
    BaseMachine.slotReelDown(self)
    self.b_gameTipFlag = false
end

function BaseSlotoManiaMachine:beginReel()
    BaseMachine.beginReel(self)
end

function BaseSlotoManiaMachine:checkHasBonus()
    return false
end
function BaseSlotoManiaMachine:checkHasScatter()
    return false
end
function BaseSlotoManiaMachine:checkHasSmallWildSymbol()
    return false
end

function BaseSlotoManiaMachine:onEnter()
    BaseSlotoManiaMachine.super.onEnter(self)

    self:enterLevel()

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params ~= nil then
                self:updateNotifyFsTopCoins(params)
            end
        end,
        "updateNotifyFsTopCoins"
    )

    -- 暂时这么写，这个函数应该写在enterGamePlayMusic，但是enterGamePlayMusic被子方法覆盖了
    -- self:resetCurBgMusicName()
    self:enterGamePlayMusic()

    --消息推送刷新
    scheduler.performWithDelayGlobal(
        function()
            globalNotifyNodeManager:timeUpdate()
        end,
        1,
        self.m_moduleName
    )

    -- gLobalNoticManager:addObserver(self,function(params)
    --     if self.resumeMachine then
    --         self:resumeMachine()
    --     end
    -- end ,ViewEventType.NOTIFY_BUYTIP_CLOSE)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params then
                self.m_freeSpinOverCurrentTime = params
            end
        end,
        ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.m_levelUpSaleFunc then
                self.m_levelUpSaleFunc()
                self.m_levelUpSaleFunc = nil
            end
        end,
        ViewEventType.NOTIFY_BUYTIP_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:checkAddQuestDoneEffectType()
        end,
        ViewEventType.NOTIFY_QUEST_DONE_ADDEFF
    )
end

function BaseSlotoManiaMachine:checkAddQuestDoneEffectType()
    if self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE) == false then
        local questEffect = GameEffectData:create()
        questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
        questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
        self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
    end
end

--[[
    @desc: 重新添加关卡 中 questEffectType 的触发顺序
           一些关卡 需要 将quest 放到最后，自己的各种玩法播完之后再调用 quest的
    author: cxc
    time:2021-06-30 20:57:50
]]
function BaseSlotoManiaMachine:afreshAddQuestDoneEffectType()
    local bQuestOpen = false

    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig then
        -- quest
        bQuestOpen = true
    end

    if not bQuestOpen then
        return
    end

    -- 有的关卡自己重写了这个方法
    -- self:checkAddQuestDoneEffectType()
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == false then
        local questEffect = GameEffectData:create()
        questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
        questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
        self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
    end
end

function BaseSlotoManiaMachine:enterQuestTipCallBack()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    self:enterLevel()
    --5秒后播放 收起动画
    self.m_questView:delayHideDescribe(3)
end

function BaseSlotoManiaMachine:showEnterLevelQuestTip()
end

function BaseSlotoManiaMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            self:resetMusicBg()
        end,
        0.45,
        self.m_moduleName
    )
end

function BaseSlotoManiaMachine:initQuesetLevelView()
end

function BaseSlotoManiaMachine:checkInitSpinWithEnterLevel()
    local isTriggerEffect = false
    local isPlayGameEffect = false

    if self.m_initSpinData ~= nil then
        -- 检测上次的feature 信息

        if self.m_initFeatureData == nil then
            -- 检测是否要触发 feature
            self:checkNetDataFeatures()
        end

        isPlayGameEffect = self:checkNetDataCloumnStatus()
        local isPlayFreeSpin = self:checkTriggerINFreeSpin()

        isPlayGameEffect = isPlayGameEffect or isPlayFreeSpin --self:checkTriggerINFreeSpin()
        if isPlayGameEffect and self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
            -- 这里只是用来检测是否 触发了 bonus ，如果触发了那么不调用数据生成
            isTriggerEffect = true
        end

        ----- 以下是检测初始化当前轮盘 ----
        self:checkInitSlotsWithEnterLevel()
    end

    return isTriggerEffect, isPlayGameEffect
end

function BaseSlotoManiaMachine:checkInitSlotsWithEnterLevel()
    local isTriggerCollect = false
    if self.m_initFeatureData ~= nil then
        isTriggerCollect = true
        -- 只处理纯粹feature 的类型， 如果有featureData 表明已经处于进行中了， 则直接弹出小游戏或者其他面板显示对应进度
        -- 如果上次退出时，处于feature中那么初始化各个关卡的feature 内容，
        self:initFeatureInfo(self.m_initSpinData, self.m_initFeatureData)
    end

    self:MachineRule_initGame(self.m_initSpinData)

    --初始化收集数据
    if self.m_collectDataList ~= nil then
        self:initCollectInfo(self.m_initSpinData, self.m_initBetId, isTriggerCollect)
    end

    if self.m_jackpotList ~= nil then
        self:initJackpotInfo(self.m_jackpotList, self.m_initBetId)
    end
end

---
-- 进入关卡
--
function BaseSlotoManiaMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

function BaseSlotoManiaMachine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self:initCloumnSlotNodesByNetData()
end

function BaseSlotoManiaMachine:initNoneFeature()
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

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    self:initRandomSlotNodes()
end

--[[
    @desc: 断线重连时处理 是否有feature 
    time:2019-01-04 17:19:32
    @return:
]]
function BaseSlotoManiaMachine:checkHasFeature()
    local hasFeature = false

    if self.m_initSpinData ~= nil and self.m_initSpinData.p_features ~= nil and #self.m_initSpinData.p_features > 0 then
        for i = 1, #self.m_initSpinData.p_features do
            local featureID = self.m_initSpinData.p_features[i]
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN or featureID == SLOTO_FEATURE.FEATURE_RESPIN or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                hasFeature = true
            end
        end
    end

    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        hasFeature = true
    end

    return hasFeature
end

---
-- 只有有上一轮数据时 才会调用
--
function BaseSlotoManiaMachine:MachineRule_initGame(spinData)
end

function BaseSlotoManiaMachine:initFeatureInfo(spinData, featureData)
end

-----------------------------------COLLECT START------------------------
--进入关卡获取服务器收集数据 需要计算上次spinData是否存在收集操作添加收集的值 isTriggerCollect
function BaseSlotoManiaMachine:initCollectInfo(spinData, lastTotalBet, isTriggerCollect)
end

--第一次进入本关卡初始化本关收集数据 如果数据格式不同子类重写这个方法
function BaseSlotoManiaMachine:BaseMania_initCollectDataList()
    --收集数组
    self.m_collectDataList = {}
    --默认总数
    local pools = {100, 20}
    for i = 1, 2 do
        self.m_collectDataList[i] = CollectData.new()
        self.m_collectDataList[i].p_collectTotalCount = pools[i]
        self.m_collectDataList[i].p_collectLeftCount = 0
        self.m_collectDataList[i].p_collectCoinsPool = 0
        self.m_collectDataList[i].p_collectChangeCount = 0
    end
end

--更新收集数据 addCount增加的数量  addCoins增加的奖金
function BaseSlotoManiaMachine:BaseMania_updateCollect(addCount, addCoins, index)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index]) == "table" then
        self.m_collectDataList[index].p_collectLeftCount = self.m_collectDataList[index].p_collectLeftCount + addCount
        self.m_collectDataList[index].p_collectCoinsPool = self.m_collectDataList[index].p_collectCoinsPool + addCoins
        self.m_collectDataList[index].p_collectChangeCount = addCount
    end
end
--获得收集数据
function BaseSlotoManiaMachine:BaseMania_getCollectData(index)
    if not index then
        index = 1
    end
    return self.m_collectDataList[index]
end
--是否触发收集小游戏
function BaseSlotoManiaMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index].p_collectLeftCount >= self.m_collectDataList[index].p_collectTotalCount then
        return true
    end
end
--收集完成重置收集进度
function BaseSlotoManiaMachine:BaseMania_completeCollectBonus(index, totalCount)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index]) == "table" then
        self.m_collectDataList[index].p_collectTotalCount = totalCount or 200
        self.m_collectDataList[index].p_collectLeftCount = 0
        self.m_collectDataList[index].p_collectCoinsPool = 0
        self.m_collectDataList[index].p_collectChangeCount = 0
    end
end
-----------------------------------COLLECT END------------------------

-----------------------------------JACKPOT START------------------------
--进入关卡获取服务器jackpot数据
function BaseSlotoManiaMachine:initJackpotInfo(jackpotPool, lastBetId)
end

--服务器没有基础值初始化一份
function BaseSlotoManiaMachine:updateJackpotList()
    self.m_jackpotList = {}
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if jackpotPools ~= nil and #jackpotPools > 0 then
        for index, poolData in pairs(jackpotPools) do
            local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(poolData, false, globalData.slotRunData:getCurTotalBet())
            self.m_jackpotList[index] = totalScore - baseScore
        end
    end
end

--启用jackpot累积功能 isUnJackpot=true为关闭累积功能
function BaseSlotoManiaMachine:BaseMania_jackpotEnable(isUnJackpot)
    self.m_isJackpotEnable = not isUnJackpot
end
--获得jackpot奖金 index从大到小 例4个jackpot关卡： 1-grand 2-major 3-minior 4-mini
-- @return 返回0表示 没有对应档位
function BaseSlotoManiaMachine:BaseMania_getJackpotScore(index, totalBet)
    if not totalBet then
        totalBet = globalData.slotRunData:getCurTotalBet()
    end
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools[index] or not self.m_jackpotList[index] then
        return 0
    end
    local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index], true, totalBet)
    --使用spin当时的jackpot来计算奖励
    totalScore = baseScore + self.m_jackpotList[index]
    return totalScore
end

function BaseSlotoManiaMachine:BaseMania_updateJackpotScore(index, totalBet)
    if not totalBet then
        totalBet = globalData.slotRunData:getCurTotalBet()
    end
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools or not jackpotPools[index] then
        return 0
    end
    local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index], true, totalBet)
    return totalScore
end

--完成后重置jackpot
function BaseSlotoManiaMachine:BaseMania_resetJackpot(index, totalBet)
    if not totalBet then
        totalBet = globalData.slotRunData:getCurTotalBet()
    end
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if jackpotPools and jackpotPools[index] and jackpotPools[index].p_configData then
        globalData.jackpotRunData:resetJackpotPool(jackpotPools[index], jackpotPools[index].p_configData)
    end
end
-----------------------------------JACKPOT END------------------------

function BaseSlotoManiaMachine:triggerFreeSpin()
end

function BaseSlotoManiaMachine:addObservers()
    BaseMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local delayTime = 0
            if self.m_startSpinTime then
                local nowTime = xcyy.SlotsUtil:getMilliSeconds()
                local waitTime = nowTime - self.m_startSpinTime
                if waitTime < (self.m_startSpinWaitTime * 1000) then
                    delayTime = (self.m_startSpinWaitTime * 1000) - (nowTime - self.m_startSpinTime)
                end
            end

            

            if delayTime > 0 then
                performWithDelay(
                    self,
                    function()
                        self:spinResultCallFun(params)
                        --检测添加标数据
                        if params[1] and params[2].action == "SPIN" then
                            
                            -- util_nextFrameFunc(function(  )
                                if not tolua.isnull(self) then
                                    self:randomAddSignPos()
                                end
                            -- end)
                        end
                        -- 通知Quest 检测是否添加Complete Quest事件
                        gLobalNoticManager:postNotification(ViewEventType.CHECK_QUEST_WITH_SPINRESULT)
                    end,
                    delayTime / 1000
                )
            else
                self:spinResultCallFun(params)
                --检测添加标数据
                if params[1] and params[2].action == "SPIN" then
                    -- util_nextFrameFunc(function(  )
                        if not tolua.isnull(self) then
                            self:randomAddSignPos()
                        end
                    -- end)
                    
                end
                -- 通知Quest 检测是否添加Complete Quest事件
                gLobalNoticManager:postNotification(ViewEventType.CHECK_QUEST_WITH_SPINRESULT)
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showPaytableView(params)
        end,
        ViewEventType.NOTIFY_PAYTABLEVIEW_OPEN
    )
end
function BaseSlotoManiaMachine:checkTestConfigType(param)
    if DEBUG == 2 then
        if param[1] == true then
            local spinData = param[2]
            if spinData and spinData.configType then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_CONFIG_TYPE, spinData.configType)
            end
        end
    end
end

---
-- 检测处理respin  和 special reel的逻辑
--
function BaseSlotoManiaMachine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
                self:getRandomList()

                self:stopRespinRun()

                self:setGameSpinStage(GAME_MODE_ONE_RUN)

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
            end
        else
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
        return true
    end
    return false
end
----
--- 处理spin 成功消息
--
function BaseSlotoManiaMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
        local params = {}
        params.rewaedFSData = self.m_rewaedFSData
        params.states = "spinResult"
        gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_CHANGE_TIME, params)
    end
    if spinData.action == "SPIN" then

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end
---
-- 处理spin 返回消息的数据结构
--
function BaseSlotoManiaMachine:operaSpinResultData(param)
    local spinData = param[2]

    self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
end

---
-- spin 结束后处理用户的信息
--
function BaseSlotoManiaMachine:operaUserInfoWithSpinResult(param)
    local spinData = param[2]

    globalData.seqId = spinData.sequenceId
    self:operaUserLevelUpInfo()
    self:operaWinCoinsWithSpinResult(param)
    self:operaUserLevelUpWithSpinResult(param)
    self.m_gameCrazeBuff = spinData.gameCrazyBuff or false
end
--[[
    @desc: 处理用户的spin赢钱信息
    time:2020-07-10 17:50:08
]]
function BaseSlotoManiaMachine:operaWinCoinsWithSpinResult(param)
    local spinData = param[2]
    local userMoneyInfo = param[3]
    self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
    --发送测试赢钱数
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN, self.m_serverWinCoins)
    globalData.userRate:pushCoins(self.m_serverWinCoins)

    if spinData.result.freespin.freeSpinsTotalCount == 0 then
        self:setLastWinCoin(spinData.result.winAmount)
    else
        self:setLastWinCoin(spinData.result.freespin.fsWinCoins)
    end
    globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
end

--[[
    @desc: 处理用户spin消息后的用户升级信息
    time:2020-07-10 17:48:07
]]
function BaseSlotoManiaMachine:operaUserLevelUpWithSpinResult(param)
    if self.m_spinIsUpgrade == true then
        local sendData = {}

        local betCoin = globalData.slotRunData:getCurTotalBet()

        sendData.exp = betCoin * self.m_expMultiNum

        -- 存储一下VIP的原始等级
        self.m_preVipLevel = globalData.userRunData.vipLevel
        self.m_preVipPoints = globalData.userRunData.vipPoints
    end
end

function BaseSlotoManiaMachine:operaUserLevelUpInfo()
    print("------ 玩家spin 得到结果之后 需要调用这个方法回来 处理升级对应的操作")
    --调用父类之前的方法
    self:calculateSpinDataV2()

    --增加新手任务进度
    self:checkIncreaseNewbieTask()
end

----
--- 处理spin 失败消息
--
function BaseSlotoManiaMachine:checkOpearSpinFaild(param)
    --给与弹板玩家提示。。
    local errorInfo = {}
    if param[2] then
        errorInfo.errorCode = param[2]
    end

    if param[3] then
        errorInfo.errorMsg = param[3]
    end

    gLobalViewManager:showReConnect(true, nil, errorInfo)
    -- 发消息恢复，界面上显示的钱
    -- self.m_spinResultCoin = 0
    self.m_spinNextLevel = 0
    self.m_spinNextProVal = 0
    globalData.coinsSoundType = 1
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum) -- 立即更改金币数量
    -- 立即还原
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_EXP_PRO, {0})
end

---
-- 处理spin 返回结果
function BaseSlotoManiaMachine:spinResultCallFun(param)
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime
    -- 把spin数据写到文件 便于找数据bug
    if param[1] == true then
        if device.platform == "mac"  then 
            if param[2] and param[2].result then
                release_print("消息返回胡来了")
                print(cjson.encode(param[2].result))
            end
        end
        dumpStrToDisk(param[2].result, "------------> result = ", 50)
    else
        dumpStrToDisk({"false"}, "------------> result = ", 50)
    end
    self:checkTestConfigType(param)
    local isOpera = self:checkOpearReSpinAndSpecialReels(param) -- 处理respin逻辑
    if isOpera == true then
        return
    end

    if param[1] == true then -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else -- 处理spin失败
        self:checkOpearSpinFaild(param)
    end
end

---
-- 初始化上次游戏状态数据
--
function BaseSlotoManiaMachine:initGameStatusData(gameData)
    if not globalData.userRate then
        local UserRate = require "data.UserRate"
        globalData.userRate = UserRate:create()
    end
    globalData.userRate:enterLevel(self:getModuleName())
    if gameData.gameConfig ~= nil and gameData.gameConfig.isAllLine ~= nil then
        self.m_isAllLineType = gameData.gameConfig.isAllLine
    end

    -- spin
    -- feature
    -- sequenceId
    local operaId = gameData.sequenceId

    self.m_initBetId = (gameData.betId or -1)

    local spin = gameData.spin
    -- spin = nil
    local freeGameCost = gameData.freeGameCost
    local feature = gameData.feature
    local collect = gameData.collect
    local jackpot = gameData.jackpot
    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum ---gameData.totalWinCoins
    self.m_freeSpinOffSetCoins = 0
    --gameData.totalWinCoins
    self:setLastWinCoin(totalWinCoins)

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin, self.m_lineDataPool, self.m_symbolCompares, feature)
        self.m_initSpinData = self.m_runSpinResultData
    end
    if feature ~= nil then
        self.m_initFeatureData = SpinFeatureData.new()
        if feature.bonus then
            if feature.bonus then
                -- if feature.bonus.status == "CLOSED" and feature.bonus.content ~= nil then
                --     local bet = feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1]
                --     feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1] = - bet
                -- end
                feature.choose = feature.bonus.choose
                feature.content = feature.bonus.content
                feature.extra = feature.bonus.extra
                feature.status = feature.bonus.status
            end
        end
        self.m_initFeatureData:parseFeatureData(feature)
    -- self.m_initFeatureData:setAllLine(self.m_isAllLineType)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost
        local params = {}
        params.rewaedFSData = self.m_rewaedFSData
        params.states = "init"
        gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_CHANGE_TIME, params)
    end

    if collect and type(collect) == "table" and #collect > 0 then
        for i = 1, #collect do
            self.m_collectDataList[i]:parseCollectData(collect[i])
        end
    end
    if jackpot and type(jackpot) == "table" and #jackpot > 0 then
        self.m_jackpotList = jackpot
    end
    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    if gameData.gameConfig ~= nil and gameData.gameConfig.bonusReels ~= nil then
        self.m_runSpinResultData["p_bonusReels"] = gameData.gameConfig.bonusReels
    end

    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    self.m_gameCrazeBuff = gameData.gameCrazyBuff or false

    if self.m_videoPokeMgr then
       -- videoPoker 数据解析
        if gameData.gameConfig.extra then
            self.m_videoPokeMgr.m_runData:parseData( gameData.gameConfig.extra ) 
        end
    end
    
    

    self:initMachineGame()
end

function BaseSlotoManiaMachine:onExit()
    BaseMachine.onExit(self) -- 必须调用不予许删除

    self:clearSlotoData()
    globalData.userRate:leaveLevel()
    scheduler.unschedulesByTargetName("BaseSlotoManiaMachine")
    -- self:stopTimeOut()
end

---
-- 清空掉产生的数据
--
function BaseSlotoManiaMachine:clearSlotoData()
    -- 清空掉全局信息
    globalData.slotRunData.levelConfigData = nil
    globalData.slotRunData.levelGetAnimNodeCallFun = nil
    globalData.slotRunData.levelPushAnimNodeCallFun = nil

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

function BaseSlotoManiaMachine:getPreLoadSlotNodes()
    return BaseMachine.getPreLoadSlotNodes(self)
end

function BaseSlotoManiaMachine:removeObservers()
    BaseMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function BaseSlotoManiaMachine:BaseMania_getLineBet()
    local betValue = globalData.slotRunData:getLineBet()
    return betValue
end

---------------------------------弹版----------------------------------
function BaseSlotoManiaMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function BaseSlotoManiaMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end
--特殊三条时间线start idle over  自动播放
function BaseSlotoManiaMachine:showFreeSpinMoreAutoNomal(num, func)
    local function newFunc()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
            self:resetMusicBg(true)
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_NOMAL)
end

function BaseSlotoManiaMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function BaseSlotoManiaMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func, BaseDialog.AUTO_TYPE_ONLY)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

function BaseSlotoManiaMachine:showReSpinOver(coins, func, index)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func, nil, index)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

--暂时未处理
function BaseSlotoManiaMachine:showJackpot(index, path, func)
    local ownerlist = {}
    local coins = self:BaseMania_getJackpotScore(index)
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    ownerlist["m_sp_icon"] = path
    -- self:showDialog(BaseDialog.DIALOG_TYPE_JACKPOT,ownerlist,func,BaseDialog.AUTO_TYPE_NOMAL,index)
    return self:showDialog(BaseDialog.DIALOG_TYPE_JACKPOT, ownerlist, func, nil, index)
    --也可以这样写 self:showDialog("Jackpot",ownerlist,BaseDialog.AUTO_TYPE_ONLY,index)
end
--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function BaseSlotoManiaMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("Levels.BaseDialog")
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

--freespin中更新右上角赢钱
function BaseSlotoManiaMachine:updateNotifyFsTopCoins(addCoins)
    if addCoins then
        self.m_freeSpinOffSetCoins = self.m_freeSpinOffSetCoins + addCoins
    end
    local coins = self.m_freeSpinStartCoins + self.m_freeSpinOffSetCoins
    print("updateNotifyFsTopCoins topcoins= " .. coins)
    print("updateNotifyFsTopCoins allcoins= " .. globalData.userRunData.coinNum)
    globalData.coinsSoundType = 1
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, coins)
end

function BaseSlotoManiaMachine:getPayTableCsbPath()
    return "PayTableLayer" .. self.m_moduleName .. ".csb"
end

-- 显示paytableview 界面
function BaseSlotoManiaMachine:showPaytableView()
    local csbFileName = self:getPayTableCsbPath()

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    if view then
        view:setOverFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                gLobalViewManager:viewResume(
                    function()
                        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
                    end
                )
            end
        )
        if view:findChild("root") then
            view:findChild("root"):setScale(self.m_machineRootScale)
        end
        
    end
end

function BaseSlotoManiaMachine:onKeyBack()
    local view =
        gLobalViewManager:showDialog(
        "Dialog/ExitGame_Lobby.csb",
        function()
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        end, nil, nil, nil
    )
    view:setLocalZOrder(40000)
end
--兼容新代码
function BaseSlotoManiaMachine:initGridList()
end
return BaseSlotoManiaMachine
