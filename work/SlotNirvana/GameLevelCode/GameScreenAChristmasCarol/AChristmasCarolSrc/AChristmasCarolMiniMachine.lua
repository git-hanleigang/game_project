---
-- xcyy
-- 2018-12-18 
-- AChristmasCarolMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local AChristmasCarolMiniMachine = class("AChristmasCarolMiniMachine", BaseMiniMachine)

AChristmasCarolMiniMachine.m_machineIndex = nil -- csv 文件模块名字

AChristmasCarolMiniMachine.gameResumeFunc = nil
AChristmasCarolMiniMachine.gameRunPause = nil

local Main_Reels = 1

-- 构造函数
function AChristmasCarolMiniMachine:ctor()
    AChristmasCarolMiniMachine.super.ctor(self)

end

function AChristmasCarolMiniMachine:initData_( data )
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_maxReelIndex = data.maxReelIndex 
    self.m_isMiniMachine = true
    self.m_isPlayUpdateRespinNums = true --是否播放刷新respin次数
    self.m_isPlayBarOver = true

    --滚动节点缓存列表
    self.cacheNodeMap = {}
    --init
    self:initGame()
end

function AChristmasCarolMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function AChristmasCarolMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "AChristmasCarol"
end

function AChristmasCarolMiniMachine:getMachineConfigName()

    return "AChristmasCarolConfig.csv"
end

-- 继承底层respinView
function AChristmasCarolMiniMachine:getRespinView()
    return self.m_parent:getRespinView()
end
-- 继承底层respinNode
function AChristmasCarolMiniMachine:getRespinNode()
    return self.m_parent:getRespinNode()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function AChristmasCarolMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function AChristmasCarolMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function AChristmasCarolMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("AChristmasCarol_respin_double_sets.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    self:initReSpinBar()

    -- respin grand框
    self.m_respinGrandBarView = util_createView("AChristmasCarolSrc.AChristmasCarolRespinGrandBar", {machine = self})
    self:findChild("Node_respinbar"):addChild(self.m_respinGrandBarView)
end

--[[
    @desc: 
    author:{author}
    time:2023-03-17 12:23:32
    @return:
]]
function AChristmasCarolMiniMachine:playReelStartEffect(_func)
    self.m_parent:delayCallBack(36 / 60, function()
        for ParticleIndex = 1, 4 do
            if self:findChild("Particle_"..ParticleIndex) then
                self:findChild("Particle_"..ParticleIndex):resetSystem()
            end
        end
    end)

    self.m_parent:delayCallBack(60 / 60, function()
        if _func then
            _func()
        end
    end)
end

function AChristmasCarolMiniMachine:initReSpinBar()
    local node_bar = self:findChild("Node_respin_spinnum")
    self.m_respinBarView = util_createView("AChristmasCarolSrc.AChristmasCarolRespinBar", {machine = self.m_parent})
    node_bar:addChild(self.m_respinBarView)
    self.m_respinBarView:setVisible(false)
end

--[[
    刷新当前respin剩余次数
]]
function AChristmasCarolMiniMachine:changeReSpinUpdateUI(curCount, _isComeIn)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    if totalCount <= 0 then
        if self.m_modeType[1] == 1 then
            totalCount = 4
        else
            totalCount = 3
        end
    end
    self.m_isPlayBarOver = true
    self.m_respinBarView:updateRespinCount(curCount, totalCount, _isComeIn)
end

function AChristmasCarolMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    AChristmasCarolMiniMachine.super.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function AChristmasCarolMiniMachine:addSelfEffect()
 
end

function AChristmasCarolMiniMachine:MachineRule_playSelfEffect(effectData)

    return true
end

function AChristmasCarolMiniMachine:onEnter()
    AChristmasCarolMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

-- function AChristmasCarolMiniMachine:addObservers()

--     AChristmasCarolMiniMachine.super.addObservers(self)

--     gLobalNoticManager:addObserver(
--         self,
--         function(Target, params)
--             Target:MachineRule_respinTouchSpinBntCallBack()
--         end,
--         ViewEventType.RESPIN_TOUCH_SPIN_BTN
--     )
    
-- end

function AChristmasCarolMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end

function AChristmasCarolMiniMachine:playEffectNotifyChangeSpinStatus( )

end

function AChristmasCarolMiniMachine:quicklyStopReel(colIndex)

end

function AChristmasCarolMiniMachine:onExit()
    AChristmasCarolMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function AChristmasCarolMiniMachine:removeObservers()
    AChristmasCarolMiniMachine.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function AChristmasCarolMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage( WAITING_DATA )
end

function AChristmasCarolMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    AChristmasCarolMiniMachine.super.beginReel(self)
end

-- 消息返回更新数据
function AChristmasCarolMiniMachine:netWorkCallFun(spinResult)

end

function AChristmasCarolMiniMachine:enterLevel( )
    AChristmasCarolMiniMachine.super.enterLevel(self)
end

function AChristmasCarolMiniMachine:enterLevelMiniSelf( )

    AChristmasCarolMiniMachine.super.enterLevel(self)
    
end

function AChristmasCarolMiniMachine:dealSmallReelsSpinStates( )
    
end

-- 处理特殊关卡 遮罩层级
function AChristmasCarolMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function AChristmasCarolMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parent:getBounsScatterDataZorder(symbolType )

end

function AChristmasCarolMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function AChristmasCarolMiniMachine:checkGameResumeCallFun( )
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

function AChristmasCarolMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function AChristmasCarolMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function AChristmasCarolMiniMachine:resumeMachine()
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
function AChristmasCarolMiniMachine:clearSlotoData()
    
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
function AChristmasCarolMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function AChristmasCarolMiniMachine:clearCurMusicBg( )
    
end

function AChristmasCarolMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()
end

--[[
    刷新小块
]]
function AChristmasCarolMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    end
end

--[[
    判断是否为bonus小块
]]
function AChristmasCarolMiniMachine:isFixSymbol(symbolType)
    return self.m_parent:isFixSymbol(symbolType)
end

-- 给respin小块进行赋值
function AChristmasCarolMiniMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType then
        return
    end

    local score = 0
    local type = nil
    if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        score,type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
    else
        score,type = self.m_parent:randomDownRespinSymbolScore(symbolNode.p_symbolType)
    end

    if symbolNode and symbolNode.p_symbolType then
        symbolNode.m_score = score
        local symbolType = symbolNode.p_symbolType

        self.m_parent:showBonusJackpotOrCoins(symbolNode, score, type)

        if symbolType == self.m_parent.SYMBOL_BASE_BONUS1 or symbolType == self.m_parent.SYMBOL_BASE_BONUS2 or symbolType == self.m_parent.SYMBOL_BASE_BONUS3 then
            if self.m_parent:getGameSpinStage() > IDLE and self.m_parent:getGameSpinStage() ~= QUICK_RUN then
                symbolNode:runAnim("idleframe2", true)
            end
        end
    end
end

-- 根据网络数据获得respinBonus小块的分数
function AChristmasCarolMiniMachine:getReSpinSymbolScore(id, isCurRespin)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if isCurRespin then
        storedIcons = rsExtraData.storedIcons or {}
    end
    local score = 0
    local type = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            type = values[3]
        end
    end

    return score,type
end

function AChristmasCarolMiniMachine:initRespinView(endTypes, randomTypes)
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
            self:reSpinEffectChange()
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function AChristmasCarolMiniMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if symbolType < self.m_parent.SYMBOL_BASE_BONUS1 then
                symbolType = self.m_parent.SYMBOL_EMPTY
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_parent.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_parent.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end

function AChristmasCarolMiniMachine:triggerChangeRespinNodeInfo(respinNodeInfo)
    local reExtra = self.m_runSpinResultData.p_rsExtraData or {}
    local curStoredIcons = {}
    local isNext = true
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self.m_parent:getFixSymbol(iCol,iRow)
            if symbolNode and (symbolNode.p_symbolType == self.m_parent.SYMBOL_RESPIN_BONUS1 or symbolNode.p_symbolType == self.m_parent.SYMBOL_RESPIN_BONUS2) then
                isNext = false
                break
            end
        end
    end
    if isNext then
        for _, _data in ipairs(reExtra.storedIcons_up) do
            local isNeed = true
            for _, _base_data in ipairs(reExtra.base_storedIcons) do
                if _data[1] == _base_data[1] then
                    isNeed = false
                end
            end
            if isNeed then
                table.insert(curStoredIcons, _data)
            end
        end
        for _, _data in ipairs(curStoredIcons) do
            local pos = self.m_parent:getRowAndColByPos(_data[1])
            for _, _respinInfo in ipairs(respinNodeInfo) do
                if pos.iX == _respinInfo.ArrayPos.iX and pos.iY == _respinInfo.ArrayPos.iY then
                    _respinInfo.Type = self.m_parent.SYMBOL_EMPTY1
                end
            end
        end
    end

    if self.m_runSpinResultData.p_rsExtraData.collect and #self.m_runSpinResultData.p_rsExtraData.collect > 0 then
        for _, _data in ipairs(self.m_runSpinResultData.p_rsExtraData.collect) do
            local fixPos = self.m_parent:getRowAndColByPos(_data[1])
            for _, _respinInfo in ipairs(respinNodeInfo) do
                if fixPos.iX == _respinInfo.ArrayPos.iX and fixPos.iY == _respinInfo.ArrayPos.iY then
                    _respinInfo.Type = self.m_parent.SYMBOL_EMPTY
                end
            end
        end
    end
end

--[[
    处理spin结果数据
]]
function AChristmasCarolMiniMachine:setSpinResultData(result)
    self.m_runSpinResultData = clone(result)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_runSpinResultData.p_reels = selfMakeData.reels
    self.m_runSpinResultData.p_storedIcons = rsExtraData.storedIcons_up
    self.m_runSpinResultData.p_rsExtraData.five = rsExtraData.five_up
    self.m_runSpinResultData.p_reSpinCurCount = rsExtraData.reSpinCurCount
    if self.m_parent.m_modeType[1] == 1 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 4
    else
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end
end

---判断结算
function AChristmasCarolMiniMachine:reSpinReelDown(addNode)
    self:setGameSpinStage(STOP_RUN)
    
    self.m_parent:reSpinReelDown()

    if self.m_runSpinResultData.p_reSpinCurCount > 0 then
        -- self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    else
        if self.m_isPlayBarOver then
            self.m_isPlayBarOver = false
            self.m_respinBarView:playBarOverEffect(self.m_runSpinResultData.p_reSpinsTotalCount)
            self.m_respinGrandBarView:playResetEffect()
        end
    end
end

--开始滚动
function AChristmasCarolMiniMachine:startReSpinRun()
    self.m_isPlayUpdateRespinNums = true
    if self.m_runSpinResultData.p_reSpinCurCount <= 0 then
        self:reSpinReelDown()
        return
    end
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end

    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end
    self.m_respinView:startMove()
end

function AChristmasCarolMiniMachine:respinOver()
    -- self:setReelSlotsNodeVisible(true)

    -- self:removeRespinNode()
    self:triggerReSpinOverCallFun(0)
end

function AChristmasCarolMiniMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_preReSpinStoredIcons = nil
    
    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0
end

--[[
    respin单列停止
]]
function AChristmasCarolMiniMachine:respinOneReelDown(colIndex,isQuickStop)
    self.m_parent:respinOneReelDown(colIndex,isQuickStop)
end

--[[
    检测播放bonus落地音效
]]
function AChristmasCarolMiniMachine:checkPlayBonusDownSound(_node)
    self.m_parent:checkPlayBonusDownSound(_node, self.m_parent:isHaveSpeBonusByReels(self.m_runSpinResultData.p_reels))
end

--[[
    显示集满列的动画
]]
function AChristmasCarolMiniMachine:showJiManEffect(_isUpReel, _col)
    self.m_parent:showJiManEffect(_isUpReel, _col)
end

return AChristmasCarolMiniMachine
