--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-11 16:13:57
--
local PublicConfig = require "DazzlingDiscoPublicConfig"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseMiniReelMachine = require "Levels.BaseReel.BaseMiniReelMachine"
local DazzlingDiscoMiniReelMachine = class("DazzlingDiscoMiniReelMachine", BaseMiniReelMachine)

local MAX_COL_NUM       =       11
local MID_COL_NUM       =       9
local MIN_COL_NUM       =       7
local MAX_ROW_NUM       =       7
local MID_ROW_NUM       =       6
local MIN_ROW_NUM       =       5

local MIN_STOP_COUNT    =       16      --最低停轮数量

local DEFAULT_SIZE      =       CCSizeMake(787,432)

local SLOT_NODE_SCALE   =       0.4286

local DYNAMIC_CHANGE_SPEED      =       700 --升行速度


local HUGE_WIN_MULTIPLE  =   2000 --大赢倍数

DazzlingDiscoMiniReelMachine.SHOW_LEADER_WIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --显示选中玩家赢钱
DazzlingDiscoMiniReelMachine.SHOW_LINES_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --显示连线

DazzlingDiscoMiniReelMachine.SYMBOL_SCORE_LONG_WILD = 301  --长条wild

function DazzlingDiscoMiniReelMachine:ctor()
    DazzlingDiscoMiniReelMachine.super.ctor(self)

    self.m_randPos = -1
    self.m_isAllWins = false
    self.m_lineFrames = {}  --连线框
    self.m_isBgBonusIdle = false

    self.m_scheduleCallFuncs = {}
end

function DazzlingDiscoMiniReelMachine:onEnter()
    DazzlingDiscoMiniReelMachine.super.onEnter(self)
end

function DazzlingDiscoMiniReelMachine:onExit()
    --停止计时器
    self.m_scheduleNode:unscheduleUpdate()
    self:stopReelSchedule()
    DazzlingDiscoMiniReelMachine.super.onExit(self)
end

function DazzlingDiscoMiniReelMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_mainMachine = data.machine 
    self.m_parentView = data.parentView

    self.m_machineRootScale = self.m_mainMachine.m_machineRootScale


    --滚动节点缓存列表
    self.cacheNodeMap = {}

    

    --init
    self:initGame()
end

function DazzlingDiscoMiniReelMachine:initGame()


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end

--[[
    @desc: 处理MINI轮子的初始化， 去掉了很多主轮子的内容
    time:2020-07-13 20:33:27
]]
function DazzlingDiscoMiniReelMachine:initMachine()
    self.m_moduleName = self:getModuleName()
    self.m_machineModuleName = self.m_moduleName
    self.m_reelRunAnima = {}

    self:initMachineCSB() -- 创建关卡csb信息

    self:updateBaseConfig() -- 更新关卡config.csv的配置信息
    self:updateMachineData() -- 更新滚动轮子指向、 以及更新每列的ReelColumnData
    self:initSymbolCCbNames() -- 更新最基础的信号名字
    self:initMachineData() -- 在BaseReelMachine类里面实现

    self:updateReelInfoWithMaxColumn() -- 计算最高的一列
    self:drawReelArea() -- 绘制裁剪区域

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function DazzlingDiscoMiniReelMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "DazzlingDisco"
end

function DazzlingDiscoMiniReelMachine:getMachineConfigName()

    return "DazzlingDiscoMiniMachineConfig.csv"
end

function DazzlingDiscoMiniReelMachine:getReelNode()
    return "CodeDazzlingDiscoBonusGame.DazzlingDiscoReelNode"
end

--小块
function DazzlingDiscoMiniReelMachine:getBaseReelGridNode()
    return "CodeDazzlingDiscoBonusGame.DazzlingDiscoMiniSlotsNode"
end

--本列停止 判断下列是否有长滚
function DazzlingDiscoMiniReelMachine:getNextReelIsLongRun(reelCol)
    
    return false
end

function DazzlingDiscoMiniReelMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false

    return isTriggerLongRun
end

---
--将滚动数据重置回来
function DazzlingDiscoMiniReelMachine:resetReelRunInfo()

end

function DazzlingDiscoMiniReelMachine:clearLineAndFrame()
    
end

---
-- 显示所有的连线框
--
function DazzlingDiscoMiniReelMachine:showAllFrame(winLines)
    
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function DazzlingDiscoMiniReelMachine:showLineFrameByIndex(winLines, frameIndex)
    
end

function DazzlingDiscoMiniReelMachine:clearFrames_Fun()
    
end

function DazzlingDiscoMiniReelMachine:playEffectNotifyChangeSpinStatus()
    
end

---
-- 根据类型获取对应节点
--
function DazzlingDiscoMiniReelMachine:getSlotNodeBySymbolType(symbolType)
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
    reelNode:setMachine(self)
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

function DazzlingDiscoMiniReelMachine:checkIsPlayReelDownSound(_iCol)
    if self:getGameSpinStage() == QUICK_RUN then
        local Col = self:getQuickStopBeginCol()
        if Col then
            if _iCol == Col then
                return true
            end
        end 

        return false
    else
        local reelCsbNode = self.m_reelCsbNodes[_iCol]
        if reelCsbNode then
            if reelCsbNode:isVisible() then
                return true
            else 
                return false
            end
        end
        return true
    end
end

---
-- 每个reel条滚动到底
function DazzlingDiscoMiniReelMachine:slotOneReelDown(reelCol)
    if self.m_parentView.m_isExitWatching then
        return
    end
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false

    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    local isNeedPlayDownSound = true
    --wild列不播停止音效
    if self.m_isAllWins and selfData and selfData.wildCols then
        local wildCols = selfData.wildCols
        for i,colIndex in ipairs(wildCols) do
            if colIndex + 1 == reelCol then
                isNeedPlayDownSound = false
                break
            end
        end
    end

    if isNeedPlayDownSound then
        self:playReelDownSound(reelCol, self.m_reelDownSound)
    end

    --检测播放落地动画
    self:checkPlayBulingAni(reelCol)

    --检测滚动是否全部停止
    local stopCount = 0
    for iCol,parentData in ipairs(self.m_slotParents) do
        if parentData.isDone then
            stopCount = stopCount + 1
        end
    end

    --滚动彻底停止
    if stopCount >= MAX_COL_NUM then
        local delayTime = self.m_configData.p_reelResTime
        self:delayCallBack(delayTime,function()
            if self.m_parentView.m_isExitWatching then
                return
            end
            self:stopReelSchedule()
            self:slotReelDown()
        end)
    end

    --检测是否普通列都已停轮
    if self.m_isBigWin and not self.m_isAllWins and not self.m_isShowAllSymbol then
        local isBaseReelDown = true
        for k,csbNode in pairs(self.m_reelCsbNodes) do
            local reelNode = csbNode.m_reelNode
            if not reelNode.m_parentData.isDone then
                isBaseReelDown = false
                break
            end
        end

        self.m_allSymbols = {}
        self.m_headFrame = {}
        if isBaseReelDown then
            self:showAllLineSymbols()
        end
    end
    

    if reelCol == 1 and self.m_isBgBonusIdle then
        self.m_mainMachine:changeBgAni("bonus4")
        self.m_isBgBonusIdle = false
    end

    return isTriggerLongRun
end

--[[
    显示所有大赢线上的连线
]]
function DazzlingDiscoMiniReelMachine:showAllLineSymbols()
    self.m_hugeWinSound = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_high_reward_light)
    self.m_isShowAllSymbol = true
    --显示遮黑
    self:showNormalReelBlackLayer()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local lineGroup = selfData.winLinesGroup
    local userMultiple = selfData.userMultiple
    local iconPos = {}
    local headPos = {}
    for pos,lineData in pairs(lineGroup) do
        if userMultiple and userMultiple[pos] and userMultiple[pos] >= HUGE_WIN_MULTIPLE then
            for i,v in ipairs(lineData) do
                local icons = v.icons
                for i,icon in ipairs(icons) do
                    iconPos[icon] = true
                end
            end
            headPos[#headPos + 1] = pos
        end
    end

    for posIndex,v in pairs(iconPos) do
        local symbolNode = self:getSymbolByPosIndex(posIndex)
        if symbolNode then
            
            local reelNode = self:getReelNodeByPosIndex(posIndex)
            symbolNode.m_reelNode = reelNode
            reelNode:changeSymbolToTop(symbolNode)
            self.m_allSymbols[#self.m_allSymbols + 1] = symbolNode
        end
    end

    --
    for k,posIndex in pairs(headPos) do
        local posData = self:getRowAndColByPos(posIndex)
        local iCol,iRow = posData.iY,posData.iX
        local headCsbNode
        if iCol == 1 then
            headCsbNode = self.m_headReelCsbNodes[1]
        else
            headCsbNode = self.m_headReelCsbNodes[3]
        end

        local csbPos = util_convertToNodeSpace(headCsbNode,self.m_clipParent)
        local targetPos = cc.p(csbPos.x + self.m_SlotNodeW,csbPos.y + self.m_SlotNodeH * (iRow - 1) * SLOT_NODE_SCALE)

        local lightAni = util_createAnimation("DazzlingDisco_lianxiansekuai3.csb")
        self.m_clipParent:addChild(lightAni,posIndex)
        lightAni:setPosition(targetPos)
        self.m_headFrame[#self.m_headFrame + 1] = lightAni
        lightAni:runCsbAction("actionframe",true)

        local ani = util_createAnimation("DazzlingDisco_lianxiansekuai2.csb")
        self.m_clipParent:addChild(ani,posIndex + 100)
        ani:setPosition(targetPos)
        self.m_headFrame[#self.m_headFrame + 1] = ani
    end
end

--[[
    清理所有大赢线上的连线
]]
function DazzlingDiscoMiniReelMachine:clearAllLineSymbols()
    --把小块放回去
    if self.m_allSymbols and #self.m_allSymbols > 0 then
        for i,symbolNode in ipairs(self.m_allSymbols) do
            local reelNode = symbolNode.m_reelNode
            if reelNode then
                reelNode:resetSymbolZOrder(symbolNode)
            end
            
        end
        self.m_allSymbols = {}
    end

    if self.m_headFrame and #self.m_headFrame > 0 then
        for k,frame in pairs(self.m_headFrame) do
            frame:removeFromParent()
        end
        self.m_headFrame = {}
    end
end

---
-- 获取最高的那一列
--
function DazzlingDiscoMiniReelMachine:updateReelInfoWithMaxColumn()
    local fReelMaxHeight = 0
    self.m_clipParent = self:findChild("Node_parent")

    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    local reelCsbNode = self.m_reelCsbNodes[1]
    local reel = reelCsbNode:findChild("sp_reel_0")
    local reelSize = reel:getContentSize()
    local scaleX = reel:getScaleX()
    local scaleY = reel:getScaleY()

    reelSize.width = reelSize.width * scaleX
    reelSize.height = reelSize.height * scaleY

    slotW = slotW + reelSize.width

    slotH = lMax(slotH, reelSize.height)

    self.m_fReelWidth = reelSize.width
    self.m_fReelHeigth = reelSize.height
    self.m_SlotNodeW = self.m_fReelWidth * SLOT_NODE_SCALE
    self.m_SlotNodeH = self.m_fReelHeigth / 4
end


--绘制多个裁切区域
function DazzlingDiscoMiniReelMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    
    self.m_slotParents = {}
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    local createReel = function(reelCsbNode,iCol)
        local reel = reelCsbNode:findChild("sp_reel_0")
        local reelSize = reel:getContentSize()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY
        

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(iCol)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local parentData = SlotParentData:new()
        parentData.cloumnIndex = iCol
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum
        parentData.startX = reelSize.width * 0.5
        parentData.reelWidth = reelSize.width
        parentData.reelHeight = reelSize.height
        parentData.slotNodeW = self.m_SlotNodeW
        parentData.slotNodeH = self.m_SlotNodeH
        parentData:reset()
        self.m_slotParents[iCol] = parentData

        local clipNode  
        clipNode = util_require(self:getReelNode()):create({
            parentData = parentData,      --列数据
            configData = self.m_configData,      --列配置数据
            doneFunc = handler(self,self.slotOneReelDown),        --列停止回调
            createSymbolFunc = handler(self,self.getSlotNodeWithPosAndType),--创建小块
            pushSlotNodeToPoolFunc = handler(self,self.pushSlotNodeToPoolBySymobolType),--小块放回缓存池
            updateGridFunc = handler(self,self.updateReelGridNode),  --小块数据刷新回调
            checkAddSignFunc = handler(self,self.checkAddSignOnSymbol), --小块添加角标回调
            direction = 0,      --0纵向 1横向 默认纵向
            colIndex = iCol,
            bigReelNode = self.m_bigReelNodeLayer,
            machine = self      --必传参数
        })
        reelCsbNode:findChild("Node_1"):addChild(clipNode,50)
        self.m_baseReelNodes[iCol] = clipNode
        reelCsbNode.m_reelNode = clipNode
        clipNode.m_csbNode = reelCsbNode
        reelCsbNode:runCsbAction("idle")
        clipNode:createChangeSymbolAni()
    end

    for iCol = 1, #self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[iCol]
        createReel(reelCsbNode,iCol)
    end

    for index = 1,#self.m_headReelCsbNodes do
        local reelCsbNode = self.m_headReelCsbNodes[index]
        createReel(reelCsbNode,#self.m_reelCsbNodes + index)
        reelCsbNode.m_reelNode:setIsHeadReel(true)
    end
end

--[[
    显示普通列压黑层
]]
function DazzlingDiscoMiniReelMachine:showNormalReelBlackLayer()
    for iCol = 1, #self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[iCol]
        local reelNode = reelCsbNode.m_reelNode
        reelNode:showBlackLayer()
    end
end

--[[
    显示压黑层
]]
function DazzlingDiscoMiniReelMachine:showBlackLayer()
    for iCol = 1, #self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[iCol]
        local reelNode = reelCsbNode.m_reelNode
        reelNode:showBlackLayer()
    end

    for index = 1,#self.m_headReelCsbNodes do
        local reelCsbNode = self.m_headReelCsbNodes[index]
        local reelNode = reelCsbNode.m_reelNode
        reelNode:showBlackLayer()
    end
end

--[[
    隐藏压黑层
]]
function DazzlingDiscoMiniReelMachine:hideBlackLayer(func)
    for iCol = 1, #self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[iCol]
        local reelNode = reelCsbNode.m_reelNode
        reelNode:hideBlackLayer()
    end

    for index = 1,#self.m_headReelCsbNodes do
        local reelCsbNode = self.m_headReelCsbNodes[index]
        local reelNode = reelCsbNode.m_reelNode
        reelNode:hideBlackLayer()
    end

    self:delayCallBack(0.3,func)
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function DazzlingDiscoMiniReelMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_mainMachine:MachineRule_GetSelfCCBName(symbolType)
    
    return ccbName
end


function DazzlingDiscoMiniReelMachine:addObservers()
    DazzlingDiscoMiniReelMachine.super.addObservers(self)
end

---
-- 读取配置文件数据
--
function DazzlingDiscoMiniReelMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
end

function DazzlingDiscoMiniReelMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("DazzlingDisco_social_qipan.csb")
    

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    self:initUI()
end

function DazzlingDiscoMiniReelMachine:initUI()

    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    --滚轮刷帧节点
    self.m_reelScheduleNode = cc.Node:create()
    self:addChild(self.m_reelScheduleNode)

    --当前行列数
    self.m_iReelColumnNum = MIN_COL_NUM
    self.m_iReelRowNum = MIN_ROW_NUM

    self.m_maxColNum = self.m_iReelColumnNum
    self.m_maxRowNum = self.m_iReelRowNum

    self.m_reelCsbNodes = {}
    self.m_headReelCsbNodes = {}
    for iCol = 1,11 do
        local csbNode = util_createAnimation("DazzlingDisco_social_qipan_reel.csb")

        if iCol >= MAX_COL_NUM - 3 then
            self.m_headReelCsbNodes[#self.m_headReelCsbNodes + 1] = csbNode
        else
            self.m_reelCsbNodes[#self.m_reelCsbNodes + 1] = csbNode
        end

        self:findChild("Node_parent"):addChild(csbNode)

        if iCol <= self.m_iReelColumnNum - 4 then
            local reelName = "Node_"..self.m_iReelColumnNum.."_"..iCol
            local parentNode =  self:findChild(reelName)
            local pos = util_convertToNodeSpace(parentNode,self:findChild("Node_parent"))
            csbNode:setPosition(pos)
        else
            csbNode:setVisible(false)
        end
    end


    for index = 1,4 do
        local csbNode = self.m_headReelCsbNodes[index]
        local reelName = "Node_"..self.m_iReelColumnNum.."_"..(self.m_iReelColumnNum - 4 + index)
        local parentNode =  self:findChild(reelName)
        local pos = util_convertToNodeSpace(parentNode,self:findChild("Node_parent"))
        csbNode:setPosition(pos)
        csbNode:setVisible(true)
    end
    

    --创建横向滚轮
    self.m_reel_horizontal = self:createSpecialReelHorizontal()
    self:findChild("Node_parent"):addChild(self.m_reel_horizontal,100)
    self.m_reel_horizontal:setVisible(false)

    self.m_lineFrameNode = cc.Node:create()
    self:findChild("Node_parent"):addChild(self.m_lineFrameNode,150)

end

--[[
    开启定时器
]]
function DazzlingDiscoMiniReelMachine:startReelSchedule()
    self:stopReelSchedule()
    self.m_reelScheduleNode:onUpdate(function(dt)

        if globalData.slotRunData.gameRunPause then
            return
        end

        for colIndex,callFunc in pairs(self.m_scheduleCallFuncs) do
            if type(callFunc) == "function" then
                callFunc(dt)
            end
        end
    end)
end

--[[
    停止定时器
]]
function DazzlingDiscoMiniReelMachine:stopReelSchedule()
    self.m_reelScheduleNode:unscheduleUpdate()
end

--[[
    注册定时器回调
]]
function DazzlingDiscoMiniReelMachine:registScheduleCallBack(colIndex,func)
    self.m_scheduleCallFuncs[colIndex] = func
end

--[[
    取消定时器回调
]]
function DazzlingDiscoMiniReelMachine:unRegistScheduleCallBack(colIndex)
    self.m_scheduleCallFuncs[colIndex] = nil
end

--[[
    清空定时器回调
]]
function DazzlingDiscoMiniReelMachine:clearScheduleCallBack()
    self.m_scheduleCallFuncs = {}
end

--[[
    创建特殊轮子-横向
]]
function DazzlingDiscoMiniReelMachine:createSpecialReelHorizontal()
    local sp_wheel = self:findChild("Node_parent")
    local wheelSize = CCSizeMake(108 * MAX_COL_NUM,600)
    local reelData = {301,100,100}
    local reelNode =  util_require("CodeDazzlingDiscoBonusGame.DazzlingDiscoSpecialReelNodeHorizontal"):create({
        parentData = {
            reelDatas = reelData,
            beginReelIndex = 1,
            slotNodeW = 108,
            slotNodeH = 600,
            reelHeight = wheelSize.height,
            reelWidth = wheelSize.width,
            isDone = false
        },      --列数据
        configData = {
            p_reelMoveSpeed = 800,
            p_rowNum = 11,
            p_reelBeginJumpTime = 0.2,
            p_reelBeginJumpHight = 20,
            p_reelResTime = 0.15,
            p_reelResDis = 4,
            p_reelRunDatas = {62}
        },      --列配置数据
        doneFunc = function()--列停止回调
            
        end,        
        createSymbolFunc = function(symbolType, rowIndex, colIndex, isLastNode)--创建小块
            local symbolNode
            if symbolType == self.SYMBOL_SCORE_LONG_WILD then
                symbolNode = util_spineCreate("Socre_DazzlingDisco_Wild3",true,true)
                util_spinePlay(symbolNode,"idleframe",true)
                --更新头像
                if self.m_leaderData then
                    local headItems = {}
                    for index = 1,5 do
                        local item = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoSpotHeadItem",{index = self.m_randPos + 1,parent = self.m_parentView})
                        util_spinePushBindNode(symbolNode,"touxiang"..(index + 1),item)
                        item:updateHead(self.m_leaderData)
                        item:findChild("Node_coins"):setVisible(false)
                        item:setVisible(index == 1)
                        headItems[index] = item
                    end
                    symbolNode.m_headItems = headItems
                end
            else
                symbolNode = cc.Node:create()
            end
            
            symbolNode.m_isLastSymbol = isLastNode
            return symbolNode
        end,
        pushSlotNodeToPoolFunc = function(symbolType,symbolNode)
            
        end,--小块放回缓存池
        updateGridFunc = function(symbolNode)
            
        end,  --小块数据刷新回调
        direction = 1,      --0纵向 1横向 默认纵向
        colIndex = 1,
        machine = self      --必传参数
    })

    return reelNode
end

--[[
    重置界面
]]
function DazzlingDiscoMiniReelMachine:resetView()
    local isMinReel = false
    if self.m_iReelColumnNum == MIN_COL_NUM and self.m_iReelRowNum == MIN_ROW_NUM then
        isMinReel = true
    end

    --当前行列数
    self.m_iReelColumnNum = MIN_COL_NUM
    self.m_iReelRowNum = MIN_ROW_NUM

    self.m_leaderData = nil

    self.m_maxColNum = self.m_iReelColumnNum
    self.m_maxRowNum = self.m_iReelRowNum

    self.m_reel_horizontal:setVisible(false)
    self.m_reel_horizontal:setPositionY(0)
    self.m_reel_horizontal:removeAllSymbol()

    self.m_isBgBonusIdle = false

    self.m_lineFrameNode:removeAllChildren()
    

    --修改父节点位置
    local parent = self:findChild("Node_parent")
    parent:setPositionY(0)
    parent:setScale(1)

    --修改背景大小
    local sp_bg = self:findChild("di")
    sp_bg:setContentSize(DEFAULT_SIZE)
    sp_bg:setScale(1)

    local reelSize = CCSizeMake(self.m_fReelWidth,self.m_fReelHeigth)

    for colIndex = 1,#self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[colIndex]
        local reelNode = reelCsbNode.m_reelNode

        reelNode:resetSize(reelSize) 
        reelNode:changeColIndex(colIndex)
        reelNode:resetViewStatus()

        --重置位置
        if colIndex <= self.m_iReelColumnNum - 4 then
            local reelName = "Node_"..self.m_iReelColumnNum.."_"..colIndex
            local parentNode =  self:findChild(reelName)
            local pos = util_convertToNodeSpace(parentNode,self:findChild("Node_parent"))
            reelCsbNode:setPosition(pos)
            reelCsbNode:setVisible(true)
        else
            reelCsbNode:setVisible(false)
        end
    end

    for index = 1,#self.m_headReelCsbNodes do
        local reelCsbNode = self.m_headReelCsbNodes[index]
        local reelNode = reelCsbNode.m_reelNode

        local reelName = "Node_"..self.m_iReelColumnNum.."_"..(self.m_iReelColumnNum - 4 + index)
        local parentNode =  self:findChild(reelName)
        local pos = util_convertToNodeSpace(parentNode,self:findChild("Node_parent"))
        reelCsbNode:setPosition(pos)
        reelCsbNode:setVisible(true)

        reelNode:resetSize(reelSize) 
        reelNode:changeColIndex(self.m_iReelColumnNum + index)
        reelNode:resetViewStatus()

        --头像列重置假滚列表
        reelNode:resetReelDatas()
        if not isMinReel then
            reelNode:initSymbolNode(false)
        end
    end

    self:setVisible(true)
end

function DazzlingDiscoMiniReelMachine:parseResultData(data)
    self.m_runSpinResultData:parseResultData(data, self.m_lineDataPool)

    --获取当前赢钱倍数
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_isBigWin = false
    if selfData and selfData.userMultiple then
        for k,multiple in pairs(selfData.userMultiple) do
            if multiple >= HUGE_WIN_MULTIPLE then
                self.m_isBigWin = true
                break
            end
        end
    end
end

--[[
    检测是否为最小轮盘
]]
function DazzlingDiscoMiniReelMachine:checkIsMinReel()
    if self.m_iReelColumnNum == MIN_COL_NUM and self.m_iReelRowNum == MIN_ROW_NUM then
        return true
    end
    return false
end


function DazzlingDiscoMiniReelMachine:beginMiniReel()
    self:startReelSchedule()

    self.m_isShowAllSymbol = false
    self.m_allSymbols = {}
    self:resetReelDataAfterReel()
    self:checkChangeBaseParent()
    local endCount = 0
    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        reelNode:resetReelDatas()
        reelNode:startMove()
    end

    local reels = self.m_runSpinResultData.p_reels
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.randomPos then
        self.m_maxColNum = #reels[1]
        self.m_isAllWins = true
        self.m_randPos = selfData.randomPos

        self.m_leaderData = self.m_parentView:getHeadDataByPosIndex(self.m_randPos)
    else
        self.m_maxColNum = #reels[1] + 4
        self.m_isAllWins = false
        self.m_randPos = -1
    end
    
    self.m_maxRowNum = #reels

    

    if self.m_iReelColumnNum < self.m_maxColNum then
        --转动2s后开始展示扩列与升行
        self:delayCallBack(2,function(  )
            if self.m_parentView.m_isExitWatching then
                return
            end
            self.m_parentView:showSuperReelTip(function(  )
                self:showExtraReel()
            end)
        end)
    else
        self:showExtraReel()
    end
end

--[[
    扩列动画
]]
function DazzlingDiscoMiniReelMachine:showExtraReelAni(tarColNum,func)
    if self.m_parentView.m_isExitWatching then
        return
    end
    local scaleNode = self:findChild("Node_3x"..tarColNum)
    local sp_bg = self:findChild("di")

    --目标缩放
    local tarScale = scaleNode:getScale()
    local curScale = self.m_clipParent:getScale()
    
    --目标背景大小
    local targetWidth = DEFAULT_SIZE.width + (tarColNum - MIN_COL_NUM) * self.m_SlotNodeW

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_extra_reel_ani)
    self.m_scheduleNode:onUpdate(function(dt)

        if self.m_parentView.m_isExitWatching then
            return
        end

        if globalData.slotRunData.gameRunPause then
            return
        end
        local offset = dt * DYNAMIC_CHANGE_SPEED
        local scaleOffset = 0.01

        curScale  = curScale - scaleOffset

        --计算当前缩放
        if curScale <= tarScale then
            curScale = tarScale
        end

        --计算背景大小
        local curSize = sp_bg:getContentSize()
        curSize.width = curSize.width + offset * 2
        if curSize.width >= targetWidth then
            curSize.width = targetWidth
        end

        self.m_clipParent:setScale(curScale)
        sp_bg:setScale(curScale)
        sp_bg:setContentSize(curSize)

        local offsetX = offset

        --只移动头像列
        for index = 1,4 do
            local reelCsbNode = self.m_headReelCsbNodes[index]
            local reelNode = reelCsbNode.m_reelNode

            --计算边界值
            if reelCsbNode.m_offsetX + offsetX >= self.m_fReelWidth * SLOT_NODE_SCALE then
                offsetX = 0
            end

            if offsetX == 0 then
                local parent = self:findChild("Node_"..tarColNum.."_"..(tarColNum - 4 + index))
                local pos = util_convertToNodeSpace(parent,self:findChild("Node_parent"))
                reelCsbNode:setPosition(pos)
                reelCsbNode.m_offsetX = self.m_fReelWidth * SLOT_NODE_SCALE
            else
                local curPosX = reelCsbNode:getPositionX()
                if index <= 2 then
                    curPosX = curPosX - offset
                else
                    curPosX = curPosX + offset
                end

                reelCsbNode:setPositionX(curPosX)
                reelCsbNode.m_offsetX = reelCsbNode.m_offsetX + offset
            end
        end


        if offsetX == 0 then
            self.m_clipParent:setScale(tarScale)
            sp_bg:setScale(tarScale)
            curSize.width = targetWidth
            sp_bg:setContentSize(curSize)
            --停止计时器
            self.m_scheduleNode:unscheduleUpdate()
            if type(func) == "function" then
                func()
            end
        end
        
    end)
end

--[[
    重置滚动长度
]]
function DazzlingDiscoMiniReelMachine:resetRunLen()
    --最后4列单独拿出来
    for index = 1,4 do
        local reelCsbNode = self.m_headReelCsbNodes[index]
        local reelNode = reelCsbNode.m_reelNode
        --设置停轮数量
        if self.m_isAllWins and index <= 2 then
            local runLen = MIN_STOP_COUNT + 3 * (index - 1)
            --设置停轮数量
            reelNode:setRunLen(runLen)
        else
            local runLen = MIN_STOP_COUNT + 3 * (self.m_iReelColumnNum - 5 + index)
            if not self.m_isAllWins and self.m_isBigWin then
                runLen = runLen + MIN_STOP_COUNT
            end
            --设置停轮数量
            reelNode:setRunLen(runLen)
        end
    end

    --其他列正常切换
    for colIndex = 1,#self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[colIndex]
        local reelNode = reelCsbNode.m_reelNode
        if colIndex <= self.m_iReelColumnNum - 4 then
            -- 设置停轮数量
            if self.m_isAllWins then
                local runLen = MIN_STOP_COUNT + 3 * (colIndex + 1)
                --设置停轮数量
                reelNode:setRunLen(runLen)
            else
                local runLen = MIN_STOP_COUNT + 3 * (colIndex - 1)
                --设置停轮数量
                reelNode:setRunLen(runLen)
            end
        else
            reelNode:setRunLen(MIN_STOP_COUNT)
        end
    end
end

--[[
    展示额外的列
]]
function DazzlingDiscoMiniReelMachine:showExtraReel()
    if self.m_parentView.m_isExitWatching then
        return
    end
    --已经阔到最大列
    if self.m_iReelColumnNum == self.m_maxColNum then
        self:resetRunLen()
        self:showExtraRow()
        return
    end

    if not self.m_isBgBonusIdle then
        self.m_mainMachine:changeBgAni("bonus3")
        self.m_isBgBonusIdle = true
    end


    local tarColNum = MIN_COL_NUM
    if self.m_iReelColumnNum == MIN_COL_NUM then
        tarColNum = MID_COL_NUM
    elseif self.m_iReelColumnNum == MID_COL_NUM then
        tarColNum = MAX_COL_NUM
    end

    local curScale = self.m_clipParent:getScale()

    for index = 1,4 do
        local reelCsbNode = self.m_headReelCsbNodes[index]
        local reelNode = reelCsbNode.m_reelNode
        reelCsbNode.m_offsetX = 0
    end

    --其他列正常切换
    for colIndex = 1,#self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[colIndex]
        local reelNode = reelCsbNode.m_reelNode
        reelCsbNode.m_offsetX = 0
        if colIndex <= tarColNum - 4 then

            reelCsbNode:setVisible(true)
            local parentIndex = colIndex - 1
            if parentIndex == 0  then
                parentIndex = self.m_iReelColumnNum - 2
            elseif parentIndex == self.m_iReelColumnNum - 4 + 1 then
                parentIndex = self.m_iReelColumnNum - 1
            end
            local parent = self:findChild("Node_"..self.m_iReelColumnNum.."_"..parentIndex)
            local pos = util_convertToNodeSpace(parent,self:findChild("Node_parent"))
            reelCsbNode:setPosition(pos)

            --第一列和最后一列隐藏滚动点
            if colIndex == 1 or colIndex == tarColNum - 4 then
                reelNode:hideRollNodes()
            end
        end
    end

    self.m_iReelColumnNum = tarColNum

    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_extra_reel_tip)
    --扩列提示
    self.m_parentView:showReelChangeTip(1,false,function()
        
    end)

    self:delayCallBack(0.5,function()
        if self.m_parentView.m_isExitWatching then
            return
        end
        self:showExtraReelAni(tarColNum,function(  )
            if self.m_parentView.m_isExitWatching then
                return
            end
            --设置最终位置
            for index = 1,4 do
                local reelCsbNode = self.m_headReelCsbNodes[index]
                local reelNode = reelCsbNode.m_reelNode
    
                local parent = self:findChild("Node_"..tarColNum.."_"..(tarColNum - 4 + index))
                local pos = util_convertToNodeSpace(parent,self:findChild("Node_parent"))
                reelCsbNode:setPosition(pos)
            end
    
            for colIndex = 1,#self.m_reelCsbNodes do
                local reelCsbNode = self.m_reelCsbNodes[colIndex]
                local reelNode = reelCsbNode.m_reelNode
                if colIndex <= tarColNum - 4 then
                    local parent = self:findChild("Node_"..tarColNum.."_"..colIndex)
                    local pos = util_convertToNodeSpace(parent,self:findChild("Node_parent"))
                    reelCsbNode:setPosition(pos)
    
                    -- 第一列和最后一列播动画
                    if colIndex == 1 or colIndex == tarColNum - 4 then
                        reelNode:showRollNodes()
                        reelNode:runChangeSymbolAni()
                    end
                end
            end
    
            self:delayCallBack(3,function(  )
                if self.m_parentView.m_isExitWatching then
                    return
                end
                --继续扩列
                self:showExtraReel()
            end)
        end)
    end)
end

--[[
    升行
]]
function DazzlingDiscoMiniReelMachine:showExtraRow()
    if self.m_parentView.m_isExitWatching then
        return
    end
    if self.m_iReelRowNum >= self.m_maxRowNum then
        if self.m_isAllWins then
            -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_everybody_wins)
            --替换头像假滚列表
            self:changeHeadReelData(function()
                if self.m_parentView.m_isExitWatching then
                    return
                end
                self:showRandHead()
            end)
            
        else
            --设置结果数据
            self:setEndData()
        end
        return
    end

    if not self.m_isBgBonusIdle then
        self.m_isBgBonusIdle = true
        self.m_mainMachine:changeBgAni("bonus3")
    end


    local addRowCount = self.m_maxRowNum - self.m_iReelRowNum

    local sp_bg = self:findChild("di")
    local bgScale = sp_bg:getScale()
    local bg_size = sp_bg:getContentSize()

    local end_bg_size = CCSizeMake(bg_size.width,bg_size.height + addRowCount * self.m_SlotNodeH * SLOT_NODE_SCALE)

    local curReelHeight = self.m_reelCsbNodes[1].m_reelNode.m_reelSize.height

    local reelSize = CCSizeMake(self.m_fReelWidth,curReelHeight + addRowCount * self.m_SlotNodeH)

    --每帧回调
    local perFunc = function(dt)
        if self.m_parentView.m_isExitWatching then
            return
        end
        local offset = math.floor(DYNAMIC_CHANGE_SPEED * dt) * SLOT_NODE_SCALE / 2 
        bg_size = sp_bg:getContentSize()
        bg_size = CCSizeMake(bg_size.width,bg_size.height + offset * 2)
        if bg_size.height > end_bg_size.height then
            bg_size.height = end_bg_size.height
        end
        sp_bg:setContentSize(bg_size)



        local parent = self:findChild("Node_parent")
        local posY = parent:getPositionY()
        posY = posY - offset * bgScale
        parent:setPositionY(posY)

        local horPosY = self.m_reel_horizontal:getPositionY()
        horPosY = horPosY + offset
        self.m_reel_horizontal:setPositionY(horPosY)
    end

    --结束回调
    local endFunc = function()
        if self.m_parentView.m_isExitWatching then
            return
        end
        sp_bg:setContentSize(end_bg_size)

        local parent = self:findChild("Node_parent")
        local posY = -(self.m_iReelRowNum - MIN_ROW_NUM) * self.m_SlotNodeH * SLOT_NODE_SCALE / 2 * bgScale
        parent:setPositionY(posY)

        self.m_reel_horizontal:setPositionY(-posY + 23)

        self:delayCallBack(2,function(  )
            if self.m_parentView.m_isExitWatching then
                return
            end
            --继续升行
            self:showExtraRow()
        end)
        
    end

    --扩列提示
    self.m_parentView:showReelChangeTip(2,false,function(  )
        
    end)

    self:delayCallBack(0.5,function()
        if self.m_parentView.m_isExitWatching then
            return
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_extra_row_ani)
        for colIndex = 1,#self.m_reelCsbNodes do
            local reelCsbNode = self.m_reelCsbNodes[colIndex]
    
            local reelNode = reelCsbNode.m_reelNode
    
            --升行特效
            reelNode:changeReelHeightAni()
    
            if colIndex == 1 then
                reelNode:setDynamicSize(reelSize,perFunc)
                reelNode:setDynamicEndFunc(endFunc)
            else
                reelNode:setDynamicSize(reelSize)
            end
    
            reelNode:setChangeSizeSpeed(DYNAMIC_CHANGE_SPEED) 
        end
    
        for index = 1,#self.m_headReelCsbNodes do
            local reelCsbNode = self.m_headReelCsbNodes[index]
    
            local reelNode = reelCsbNode.m_reelNode
            --升行特效
            reelNode:changeReelHeightAni()
    
            reelNode:setDynamicSize(reelSize)
            reelNode:setChangeSizeSpeed(DYNAMIC_CHANGE_SPEED) 
        end
        self.m_iReelRowNum = self.m_maxRowNum
    end)
end

--[[
    修改头像列假滚列表
]]
function DazzlingDiscoMiniReelMachine:changeHeadReelData(func)
    if self.m_parentView.m_isExitWatching then
        return
    end
    for index = 1,#self.m_headReelCsbNodes do
        local reelCsbNode = self.m_headReelCsbNodes[index]
        local reelNode = reelCsbNode.m_reelNode

        reelNode:resetReelDataByNormal()

        if index <= 2 then
            reelNode:changeColIndex(index)
        else
            reelNode:changeColIndex(MAX_COL_NUM - 4 + index)
        end

        reelNode:runChangeSymbolAni()
    end

    for index = 1,#self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[index]
        local reelNode = reelCsbNode.m_reelNode

        reelNode:resetReelDataByNormal()
    end

    --最大列提示
    self.m_parentView:showReelChangeTip(1,true,function()
        self:delayCallBack(3,function(  )
            if self.m_parentView.m_isExitWatching then
                return
            end
            --音浪动画
            self.m_parentView:runSoundbyteAni(function(  )
                if type(func) == "function" then
                    func()
                end
            end)    
        end)
        
        
    end)

    --背景播触发动画
    self.m_mainMachine:triggerBonusSpineAni()

    --修改列索引
    for colIndex = 1,#self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[colIndex]
        local reelNode = reelCsbNode.m_reelNode
        reelNode:changeColIndex(colIndex + 2)
    end
end

--[[
    显示随机的头像
]]
function DazzlingDiscoMiniReelMachine:showRandHead()
    if self.m_parentView.m_isExitWatching then
        return
    end
    self:setVisible(false)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_parentView:showRandomHead(selfData.randomPos,function()
        if self.m_parentView.m_isExitWatching then
            return
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_long_wild)
        self.m_parentView:showSubTitleAni("wild",false,nil,function(  )
            if self.m_parentView.m_isExitWatching then
                return
            end
            self:setVisible(true)
            self.m_reel_horizontal:setVisible(true)
            self.m_reel_horizontal:startMove()
            self.m_hor_soundID = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_horizontal_reel)

            self.m_reel_horizontal.m_doneFunc = function()
                if self.m_parentView.m_isExitWatching then
                    return
                end
                --设置结果数据
                self:setEndData()
                if self.m_hor_soundID then
                    gLobalSoundManager:stopAudio(self.m_hor_soundID)
                    self.m_hor_soundID = nil
                end
            end

            local lastList = {}
            --先全部变为空信号
            for index = 1,MAX_COL_NUM do
                lastList[index] = 100
            end
            --再把真实数据插进去
            for i,colIndex in ipairs(selfData.wildCols) do
                lastList[MAX_COL_NUM - colIndex] = self.SYMBOL_SCORE_LONG_WILD
            end

            self.m_reel_horizontal:setSymbolList(lastList)
            self.m_reel_horizontal:setIsWaitNetBack(false)
        end)
        
    end)

    
end



--[[
    设置结束数据
]]
function DazzlingDiscoMiniReelMachine:setEndData()
    local reels = self.m_runSpinResultData.p_reels
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local extraReels = selfData.extraReels

    local offset = 0
    if self.m_isAllWins then --全赢所有列均为普通小块
        offset = 2
    
        --设置头像列数据(前两列为轮盘前两列,后两列为轮盘最后两列)
        for index = 1,#self.m_headReelCsbNodes do
            local reelNode = self.m_headReelCsbNodes[index].m_reelNode
            reelNode:setIsWaitNetBack(false)
            local lastList = {}
            if index <= 2 then
                for iRow = 1,#reels do
                    local symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
                    if reels[iRow] and reels[iRow][index] then
                        symbolType = reels[iRow][index]
                    end
                    table.insert(lastList,1,symbolType)
                end
            else
                for iRow = 1,#reels do
                    local symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
                    if reels[iRow] and reels[iRow][index + 7] then
                        symbolType = reels[iRow][index + 7]
                    end
                    table.insert(lastList,1,symbolType)
                end
            end
            reelNode:setSymbolList(lastList)
        end
    else
        --设置头像列数据
        for index = 1,#self.m_headReelCsbNodes do
            local reelNode = self.m_headReelCsbNodes[index].m_reelNode
            reelNode:setIsWaitNetBack(false)
            local lastList = {}
            local reelData = extraReels[index]
            for iRow = 1,#reelData do
                local symbolType = self.m_mainMachine.SYMBOL_SCORE_HEAD
                
                table.insert(lastList,1,symbolType)
            end
            reelNode:setSymbolList(lastList)
        end
    end

    --设置普通列停轮数据
    for iCol,csbNode in ipairs(self.m_reelCsbNodes) do
        local reelNode = csbNode.m_reelNode
        reelNode:setIsWaitNetBack(false)
        local lastList = {}
        for iRow = 1,#reels do
            local symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
            if reels[iRow] and reels[iRow][iCol + offset] then
                symbolType = reels[iRow][iCol + offset]
            end
            table.insert(lastList,1,symbolType)
        end
        reelNode:setSymbolList(lastList)
    end
    
    
end

function DazzlingDiscoMiniReelMachine:addSelfEffect()
    -- 更改乘倍进度
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.SHOW_LINES_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.SHOW_LINES_EFFECT -- 动画类型

    if self.m_isAllWins then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.SHOW_LEADER_WIN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SHOW_LEADER_WIN_EFFECT -- 动画类型
        
    end
end

function DazzlingDiscoMiniReelMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.SHOW_LINES_EFFECT then --显示连线
        self:showWinLines(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.SHOW_LEADER_WIN_EFFECT then --显示选中玩家赢钱
        self:showLeaderWins(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    return true
end

--[[
    显示连线
]]
function DazzlingDiscoMiniReelMachine:showWinLines(func)
    if self.m_parentView.m_isExitWatching then
        return
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.winLinesGroup then
        if type(func) == "function" then
            func()
        end
        return
    end

    self.m_mainMachine:changeBgAni("showLine")

    if self.m_isAllWins then
        --全线显示
        local lineGroup = selfData.winLinesGroup
        local iconPos = {}
        for pos,lineData in pairs(lineGroup) do
            
            for i,v in ipairs(lineData) do
                local icons = v.icons
                for i,icon in ipairs(icons) do
                    iconPos[icon] = true
                end
            end
        end
        --显示压黑层
        self:showBlackLayer()

        self:showAllLines(iconPos,function(  )
            if self.m_parentView.m_isExitWatching then
                return
            end
            --隐藏压黑层
            self:hideBlackLayer(function()
                
            end)
            self.m_mainMachine:changeBgAni("bonus")
            if type(func) == "function" then
                func()
            end
        end)
    else
        if self.m_hugeWinSound then
            gLobalSoundManager:stopAudio(self.m_hugeWinSound)
            self.m_hugeWinSound = nil
        end
        self:clearAllLineSymbols()
        

        local lineGroup = selfData.winLinesGroup
        local lineList = {}
        for pos,lineData in pairs(lineGroup) do
            local iconPos = {}
            for i,v in ipairs(lineData) do
                local icons = v.icons
                for i,icon in ipairs(icons) do
                    iconPos[icon] = true
                end
            end
            
            lineList[#lineList + 1] = {
                pos = tonumber(pos),
                iconPos = iconPos
            }
        end

        lineList = self:sortLineList(lineList)
        
        --显示压黑层
        self:showBlackLayer()
        --逐线显示
        self:showNextLine(lineList,1,function(  )
            if self.m_parentView.m_isExitWatching then
                return
            end
            --隐藏压黑层
            self:hideBlackLayer(function()
                if type(func) == "function" then
                    func()
                end
            end)
            self.m_mainMachine:changeBgAni("bonus")
        end)
    end
end

--[[
    连线数据排序(按先左后右排序)
]]
function DazzlingDiscoMiniReelMachine:sortLineList(lineList)
    local list1,list2 = {},{}
    for i,lineData in ipairs(lineList) do
        local pos = lineData.pos
        local posData = self:getRowAndColByPos(pos)
        local iCol,iRow = posData.iY,posData.iX
        if iCol == 1 then
            list1[#list1 + 1] = lineData 
        else
            list2[#list2 + 1] = lineData 
        end
    end

    table.sort(list1,function(a,b)
        return a.pos < b.pos
    end)

    table.sort(list2,function(a,b)
        return a.pos < b.pos
    end)

    local newList = {}
    for i,lineData in ipairs(list1) do
        newList[#newList + 1] = lineData
    end

    for i,lineData in ipairs(list2) do
        newList[#newList + 1] = lineData
    end

    return newList
end

--[[
    显示所有连线
]]
function DazzlingDiscoMiniReelMachine:showAllLines(iconPos,func)
    --把未参与连线的整列wild放到压黑层下面
    self:showWildUnderBlack(iconPos,function(  )
        if self.m_parentView.m_isExitWatching then
            return
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_all_wins_light)
        self.m_mainMachine:triggerBonusSpineAni()
        local symbolList = {}
        for posIndex,v in pairs(iconPos) do
            local symbolNode = self:getSymbolByPosIndex(posIndex)
            if symbolNode then
                self:createLineFrame(symbolNode,false)
                if self:checkIndexInWildCol(posIndex) then

                else
                    local reelNode = self:getReelNodeByPosIndex(posIndex)
                    symbolNode.m_reelNode = reelNode
                    reelNode:changeSymbolToTop(symbolNode)
                    symbolList[#symbolList + 1] = symbolNode

                    symbolNode:runAnim("actionframe",false,function(  )
                        symbolNode:runAnim("idle")
                    end)
                end
                
            end
        end

        self:delayCallBack(2,function()
            for i,symbolNode in ipairs(symbolList) do
                local reelNode = symbolNode.m_reelNode
                reelNode:resetSymbolZOrder(symbolNode)
            end
            self.m_lineFrameNode:removeAllChildren()
            if type(func) == "function" then
                func()
            end
        end)
    end)
end

--[[
    将未连线的整列wild放到压黑层下面
]]
function DazzlingDiscoMiniReelMachine:showWildUnderBlack(iconPos,func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.wildCols then
        return
    end
    local outLinesCol = clone(selfData.wildCols)
    local inLinesCol = {}

    for posIndex,v in pairs(iconPos) do
        local posData = self:getRowAndColByPos(posIndex)
        local iCol,iRow = posData.iY,posData.iX

        for index,colIndex in ipairs(outLinesCol) do
            if iCol == colIndex + 1 then
                table.remove(outLinesCol,index)
                inLinesCol[iCol] = true
                break
            end
        end

        if #outLinesCol == 0 then
            break
        end
    end

    if #outLinesCol > 0 then
        for i,colIndex in ipairs(outLinesCol) do
            local iCol = colIndex + 1
            local reelNode = self:getReelNodeByCol(iCol)
            reelNode:showLongWild(self.m_leaderData)

            local symbol = self.m_reel_horizontal:getSymbolByRow(MAX_COL_NUM - iCol + 1)
            if symbol then
                symbol:setVisible(false)
            end
            
        end
    end

    local delayTime = 0
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_long_wild_show_all_head)
    for colIndex,v in pairs(inLinesCol) do
        local symbol = self.m_reel_horizontal:getSymbolByRow(MAX_COL_NUM - colIndex + 1)
        if symbol then
            if symbol.m_headItems then
                delayTime = 50 / 60
                for i,item in ipairs(symbol.m_headItems) do
                    self:delayCallBack((i - 1)* 0.1,function()
                        item:setVisible(true)
                        item:runHitAni()
                    end)
                    
                end
                
                self:delayCallBack(delayTime + 0.1 * (#symbol.m_headItems - 1),function(  )
                    util_spinePlay(symbol,"actionframe")
                    util_spineEndCallFunc(symbol,"actionframe",function(  )
                        util_spinePlay(symbol,"idleframe")
                    end)
                end)
                
            end
        end
    end

    self:delayCallBack(delayTime + 0.5,func)
end

--[[
    检测索引是否在整列wild中
]]
function DazzlingDiscoMiniReelMachine:checkIndexInWildCol(posIndex)
    local posData = self:getRowAndColByPos(posIndex)
    local iCol,iRow = posData.iY,posData.iX
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.wildCols then
        for i,colIndex in ipairs(selfData.wildCols) do
            if iCol == colIndex + 1 then
                return true
            end
        end
    end

    return false
end

--[[
    逐条显示连线
]]
function DazzlingDiscoMiniReelMachine:showNextLine(list,index,func)
    if self.m_parentView.m_isExitWatching then
        return
    end
    if index > #list then
        if type(func) == "function" then
            func()
        end
        return
    end

    local symbolList = {}
    local lineData = list[index]
    local iconPos = lineData.iconPos
    

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local userMultiple = selfData.userMultiple or {}
    local isSelfWin = false

    --获取该线上对应的头像小块
    local winCoins = 0
    local posIndex = lineData.pos
    local posData = self:getRowAndColByPos(posIndex)
    local iCol,iRow = posData.iY,posData.iX
    local headNodes = {}
    if iCol == 1 then
        for index = 1,2 do
            local reelCsbNode = self.m_headReelCsbNodes[index]
            local reelNode = reelCsbNode.m_reelNode
            local symbolNode = reelNode:getSymbolByRow(iRow)
            if symbolNode then
                headNodes[#headNodes + 1] = symbolNode
                symbolList[#symbolList + 1] = symbolNode
                symbolNode.m_reelNode = reelNode
                --将小块放到压黑层上层
                reelNode:changeSymbolToTop(symbolNode)

                --玩家点位信息
                local headData = symbolNode.m_headData
                --统计该线自己赢钱
                if headData.udid == globalData.userRunData.userUdid then
                    -- isSelfWin = true
                    if selfData and selfData.userWinCoins then
                        local coins = selfData.userWinCoins[tostring(headData.position)] or 0
                        winCoins = winCoins + coins
                    end
                end
            end
        end
        
    elseif iCol == self.m_iReelColumnNum - 4 then
        for index = 1,2 do
            local reelCsbNode = self.m_headReelCsbNodes[#self.m_headReelCsbNodes - index + 1]
            local reelNode = reelCsbNode.m_reelNode
            local symbolNode = reelNode:getSymbolByRow(iRow)
            if symbolNode then
                headNodes[#headNodes + 1] = symbolNode
                symbolList[#symbolList + 1] = symbolNode
                symbolNode.m_reelNode = reelNode
                reelNode:changeSymbolToTop(symbolNode)

                --玩家点位信息
                local headData = symbolNode.m_headData
                --统计该线自己赢钱
                if headData.udid == globalData.userRunData.userUdid then
                    -- isSelfWin = true
                    if selfData and selfData.userWinCoins then
                        local coins = selfData.userWinCoins[tostring(headData.position)] or 0
                        winCoins = winCoins + coins
                    end
                end
            end
        end
    end

    for posIndex,v in pairs(iconPos) do
        local symbolNode = self:getSymbolByPosIndex(posIndex)
        local reelNode = self:getReelNodeByPosIndex(posIndex)
        if symbolNode then
            symbolNode.m_reelNode = reelNode
            reelNode:changeSymbolToTop(symbolNode)

            symbolList[#symbolList + 1] = symbolNode
            self:createLineFrame(symbolNode,isSelfWin)
            local aniName = isSelfWin and "actionframe" or "actionframe4"
            symbolNode:runAnim(aniName,false,function(  )
                symbolNode:runAnim("idle")
            end)
        end
    end

    for i,headNode in ipairs(headNodes) do
        self:createLineFrame(headNode,isSelfWin)
    end

    local multiple = userMultiple[tostring(posIndex)] or 0
    local isBigWin = multiple >= HUGE_WIN_MULTIPLE
    if winCoins > 0 then
        self.m_parentView:showSelfWinCoins(winCoins,isBigWin)
    elseif isBigWin then
        self.m_parentView:showHugeWin()
    end

    local delayTime = isSelfWin and 2 or 1.5
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_win_lines)
    self:delayCallBack(delayTime,function()
        if self.m_parentView.m_isExitWatching then
            return
        end
        for i,symbolNode in ipairs(symbolList) do
            local reelNode = symbolNode.m_reelNode
            reelNode:resetSymbolZOrder(symbolNode)
        end
        self.m_lineFrameNode:removeAllChildren()
        self:showNextLine(list,index + 1,func)
    end)
end

--[[
    创建连线框
]]
function DazzlingDiscoMiniReelMachine:createLineFrame(symbolNode,isSelfWin)
    local aniName = isSelfWin and "actionframe" or "actionframe4"
    local pos = util_convertToNodeSpace(symbolNode,self.m_lineFrameNode)
    local aniNode = util_createAnimation("WinFrameDazzlingDisco.csb")
    self.m_lineFrameNode:addChild(aniNode)
    aniNode:setScale(SLOT_NODE_SCALE)
    aniNode:setPosition(pos)
    aniNode:runCsbAction(aniName,true)

    local aniBg = util_createAnimation("WinFrameDazzlingDisco_0.csb")
    local rollNode = symbolNode:getParent()
    rollNode:addChild(aniBg,20)
    aniBg:runCsbAction(aniName,false,function(  )
        aniBg:removeFromParent()
    end)
end

--[[
    显示选中玩家赢钱
]]
function DazzlingDiscoMiniReelMachine:showLeaderWins(func)
    local winCoins,totalWins = self:getLeaderWinCoins()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local randPos = selfData.randomPos
    if self.m_parentView.m_isExitWatching then
        return
    end

    self:setVisible(false)
    self.m_parentView:showLeaderWins(winCoins,totalWins,randPos,function()
        if self.m_parentView.m_isExitWatching then
            return
        end
        if type(func) == "function" then
            func()
        end
    end)

    
end

--[[
    获取选中玩家赢钱
]]
function DazzlingDiscoMiniReelMachine:getLeaderWinCoins()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local randPos = selfData.randomPos
    local userData = self.m_parentView:getHeadDataByPosIndex(randPos)

    local winCoins,totalWins = 0,0
    if selfData and selfData.userWinCoinMap then
        local userWinCoinMap = selfData.userWinCoinMap
        local data = userWinCoinMap[userData.udid] or {}
        
        winCoins = data.coins or 0

        for k,data in pairs(selfData.userWinCoinMap) do
            totalWins = totalWins + data.multiple
        end
    end

    if selfData.specialWheelMultiply then
        totalWins = selfData.specialWheelMultiply
    end
    
    return winCoins,totalWins
end

--[[
    获取自身赢钱
]]
function DazzlingDiscoMiniReelMachine:getSelfWinCoins(udid)
    local selfData = self.m_runSpinResultData.p_selfMakeData

    local winCoins = 0
    if selfData and selfData.userWinCoinMap then
        local userWinCoinMap = selfData.userWinCoinMap
        local data = userWinCoinMap[udid] or {}
        
        winCoins = data.coins or 0
    end
    return winCoins
end

--[[
    根据索引获取滚动层
]]
function DazzlingDiscoMiniReelMachine:getReelNodeByPosIndex(posIndex)
    local posData = self:getRowAndColByPos(posIndex)
    local iCol,iRow = posData.iY,posData.iX

    return self:getReelNodeByCol(iCol)
end

--[[
    根据列获取滚动层
]]
function DazzlingDiscoMiniReelMachine:getReelNodeByCol(colIndex)
    for index,csbNode in ipairs(self.m_reelCsbNodes) do
        local reelNode = csbNode.m_reelNode
        if reelNode.m_colIndex == colIndex then
            return reelNode
        end
    end

    for index = 1,#self.m_headReelCsbNodes do
        local reelNode = self.m_headReelCsbNodes[index].m_reelNode
        if reelNode.m_colIndex == colIndex then
            return reelNode
        end
        
    end

    return nil
end

--[[
    获取小块
]]
function DazzlingDiscoMiniReelMachine:getFixSymbol(iCol, iRow,iTag)
    local reelNode = self:getReelNodeByCol(iCol)
        
    local symbolNode
    if reelNode then
        symbolNode = reelNode:getSymbolByRow(iRow)
    end
    return symbolNode
end

---
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function DazzlingDiscoMiniReelMachine:getRowAndColByPos(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum
    if not self.m_isAllWins then
        colCount = self.m_iReelColumnNum - 4
    end

    local rowIndex = self.m_iReelRowNum - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex, iY = colIndex}
end

function DazzlingDiscoMiniReelMachine:playEffectNotifyNextSpinCall()

    self.m_mainMachine:changeBgAni("bonus")
    self.m_gameEffects = {}
    
    

    self.m_parentView:runNextSpin()
end

function DazzlingDiscoMiniReelMachine:updateReelGridNode(symbolNode)
    if not tolua.isnull(symbolNode) and symbolNode.p_symbolType then
        if symbolNode.p_symbolType == self.m_mainMachine.SYMBOL_SCORE_HEAD then
            local sp_head = symbolNode:getCcbProperty("sp_head")
            local collectIndex = math.random(1,60)
            if symbolNode.m_isLastSymbol then
                local rowIndex = symbolNode.p_rowIndex
                local colIndex = symbolNode.p_cloumnIndex - 7
                local extraReels = self.m_runSpinResultData.p_selfMakeData.extraReels
                local reelData = extraReels[colIndex]
                collectIndex = reelData[#reelData - rowIndex + 1]
            end
            local isMe = false
            local headData = self.m_parentView:getHeadDataByPosIndex(collectIndex)
            if headData then
                isMe =(globalData.userRunData.userUdid == headData.udid)
                symbolNode.m_headData = headData
                self.m_parentView:updateHead(sp_head,headData)

                local coins = headData.coins
                local lbl_coins = symbolNode:getCcbProperty("m_lb_coins")
                if lbl_coins then
                    lbl_coins:setString(util_formatCoins(coins,4))
                    local info1={label=lbl_coins,sx=1,sy=1}
                    self:updateLabelSize(info1,160)
                end
            end
            local sp_bg_other = symbolNode:getCcbProperty("sp_bg_other")
            if sp_bg_other then
                sp_bg_other:setVisible(not isMe)
            end

            local sp_bg_me = symbolNode:getCcbProperty("sp_bg_me")
            if sp_bg_me then
                sp_bg_me:setVisible(isMe)
            end

        elseif symbolNode.m_isLastSymbol and symbolNode.p_symbolType ~= self.m_mainMachine.SYMBOL_SCORE_HEAD then
            symbolNode:runAnim("idleframe")
        end
        
    end
end

--[[
    显示动画
]]
function DazzlingDiscoMiniReelMachine:showAni(func)
    self:runCsbAction("start",false,func)
    self:hideBlackLayer()
    for iCol = 1, #self.m_reelCsbNodes do
        local reelCsbNode = self.m_reelCsbNodes[iCol]
        reelCsbNode:runCsbAction("idle")
    end

    for index = 1,#self.m_headReelCsbNodes do
        local reelCsbNode = self.m_headReelCsbNodes[index]
        reelCsbNode:runCsbAction("idle")
    end

    for i,reelNode in ipairs(self.m_baseReelNodes) do
        reelNode:forEachRollNode(function(rollNode,bigRollNode,iRow)
            if rollNode then
                local symbolNode = reelNode:getSymbolByRollNode(rollNode)
                if symbolNode then
                    symbolNode:runAnim("idleframe")
                end
            end
        end)
    end
end

return DazzlingDiscoMiniReelMachine