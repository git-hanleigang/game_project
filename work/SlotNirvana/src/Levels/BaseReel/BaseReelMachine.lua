---
--island
--2022年6月20日
--BaseReelMachine.lua
--
-- 这里实现老虎机的所有UI表现相关联的，而各个关卡更多的关心这里的内容

local ReelLineInfo = require "data.levelcsv.ReelLineInfo"
local SlotsReelData = require "data.slotsdata.SlotsReelData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local GameEffectData = require "data.slotsdata.GameEffectData"
local ReSpinNode = require "Levels.RespinNode"
local CollectData = require "data.slotsdata.CollectData"
local SpinResultData = require "data.slotsdata.SpinResultData"

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local SlotsReelRunData = require "data.slotsdata.SlotsReelRunData"
local SlotParentData = require "data.slotsdata.SlotParentData"

local BaseReelNode = require "Levels.BaseReel.BaseReelNode"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseMachine = require "Levels.BaseMachine"
local BaseReelMachine = class("BaseReelMachine", BaseSlotoManiaMachine)


-- 构造函数
function BaseReelMachine:ctor()
    BaseReelMachine.super.ctor(self)
    self.m_baseReelNodes = {}
    --落地提层的特殊图标列表
    self.m_spcial_symbol_list = {}

    self.m_isLongRun = false

    self.m_scatter_down = {}
    self.m_bonus_down = {}
end

function BaseReelMachine:onExit()
    BaseReelMachine.super.onExit(self) -- 必须调用不予许删除
end

---
-- 清理掉 所有slot node 节点
function BaseReelMachine:clearSlotNodes()
    for nodeIndex = #self.m_reelNodePool, 1, -1 do
        local node = self.m_reelNodePool[nodeIndex]
        if not tolua.isnull(node) then
            node:clear()

            node:removeAllChildren() -- 必须加上这个，否则ccb的节点无法卸载，因为未加入到显示列表

            node:release()
        end
        self.m_reelNodePool[nodeIndex] = nil
    end
    self.m_reelNodePool = nil

    for key, v in pairs(self.m_reelAnimNodePool) do
        for nodeIndex = #v, 1, -1 do
            local node = v[nodeIndex]
            if not tolua.isnull(node) then
                node:clear()

                node:removeAllChildren() -- 必须加上这个，否则ccb的节点无法卸载，因为未加入到显示列表

                node:release()
            end
            v[nodeIndex] = nil
        end
        self.m_reelAnimNodePool[key] = nil
    end
    self.m_reelAnimNodePool = nil

    -- 清空掉所有遮罩提示的 SlotNode
    local nodeLen = #self.m_lineSlotNodes
    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        if not tolua.isnull(lineNode) then -- TODO 补丁
            if lineNode.clear ~= nil then
                lineNode:clear()
            end

            if lineNode:getReferenceCountEx() > 1 then
                lineNode:release()
            end

            if lineNode:getParent() ~= nil then
                lineNode:removeFromParent()
            end
        end
    end

    for i = #self.m_lineSlotNodes, 1, -1 do
        self.m_lineSlotNodes[i] = nil
    end
end

function BaseReelMachine:onEnter()
    BaseReelMachine.super.onEnter(self) -- 必须调用不予许删除
end

---
-- 进入关卡
--
function BaseReelMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        if hasFeature then
            local reels = self.m_runSpinResultData.p_reels
            local lastList = {}
            for iRow = 1,#reels do
                table.insert(lastList,1,reels[iRow][iCol])
            end
            reelNode:setSymbolList(lastList)
        end
        reelNode:initSymbolNode(hasFeature)
    end

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

function BaseReelMachine:initNoneFeature()
    if globalData.GameConfig:checkSelectBet() then
        local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if questConfig and questConfig.m_IsQuestLogin then
            --quest进入也使用服务器bet
        else
            if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest()then
                --quest进入也使用服务器bet
            else
                self.m_initBetId = -1
            end
        end
    end

    self:checkUpateDefaultBet()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function BaseReelMachine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end


function BaseReelMachine:initFeatureInfo(spinData, featureData)
end

---
-- 只有有上一轮数据时 才会调用
--
function BaseReelMachine:MachineRule_initGame(spinData)
end

--进入关卡获取服务器收集数据 需要计算上次spinData是否存在收集操作添加收集的值 isTriggerCollect
function BaseReelMachine:initCollectInfo(spinData, lastTotalBet, isTriggerCollect)
end

--进入关卡获取服务器jackpot数据
function BaseReelMachine:initJackpotInfo(jackpotPool, lastBetId)
end

--新滚动使用
function BaseReelMachine:updateReelGridNode(symblNode)

end

function BaseReelMachine:initMachine()
    self.m_moduleName = self:getModuleName()
    
    globalData.slotRunData.gameModuleName = self.m_moduleName
    globalData.slotRunData.gameNetWorkModuleName = self:getNetWorkModuleName()
    if globalData.slotRunData.isDeluexeClub == true then
        globalData.slotRunData.gameNetWorkModuleName = globalData.slotRunData.gameNetWorkModuleName .. "_H"
    end
    globalData.slotRunData.lineCount = self.m_lineCount
    self.m_machineModuleName = self.m_moduleName

    self:initMachineCSB() -- 创建关卡csb信息

    self:updateBaseConfig() -- 更新关卡config.csv的配置信息
    self:updateMachineData() -- 更新滚动轮子指向、 以及更新每列的ReelColumnData
    self:initSymbolCCbNames() -- 更新最基础的信号名字
    self:initMachineData() -- 在BaseReelMachine类里面实现

    self:changeViewNodePos() -- 不同关卡适配
    self:updateReelInfoWithMaxColumn() -- 计算最高的一列
    self:drawReelArea() -- 绘制裁剪区域

    self:initMachineUI() -- 初始化老虎机所有UI


    self:initReelEffect()

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )

    self:initSystemInfo() -- 初始化系统化信息：log、 活动栏 等等
end

--绘制多个裁切区域
function BaseReelMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    
    self.m_slotParents = {}
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for iCol = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (iCol - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
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
        self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        self.m_baseReelNodes[iCol] = clipNode
        clipNode:setPosition(cc.p(posX,posY))
    end

    --等裁切层加在父节点上之后再刷新大信号位置,否则坐标无法转化
    self:refreshBigRollNodePos()
end

--[[
    刷新大信号层滚动点位置
]]
function BaseReelMachine:refreshBigRollNodePos()
    for iCol = 1,#self.m_baseReelNodes do
        self.m_baseReelNodes[iCol]:forEachRollNode(function(rollNode,bigRollNode,rowIndex)
            if bigRollNode and rollNode then
                self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,iCol,rowIndex)
            end
        end)
    end
end

---
-- 获取最高的那一列
--
function BaseReelMachine:updateReelInfoWithMaxColumn()
    local fReelMaxHeight = 0
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()

    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for iCol = 1, self.m_iReelColumnNum, 1 do
        local colNodeName = "sp_reel_" .. (iCol - 1)
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
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
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

        self.m_clipReelSize = cc.size(slotW, slotH)
        --创建压黑层
        self:createBlackLayer(cc.size(slotW, slotH)) 

        --大信号层
        self.m_bigReelNodeLayer = util_require(self:getBigReelNode()):create({
            size = cc.size(slotW, slotH)
        })
        self.m_clipParent:addChild(self.m_bigReelNodeLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 50)
        self.m_bigReelNodeLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())

    end

    local iColNum = self.m_iReelColumnNum
    for iCol = 1, iColNum, 1 do
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))

        local reelSize = reelNode:getContentSize()
        local unitPos = cc.p(reelNode:getPositionX(), reelNode:getPositionY())
        unitPos = reelNode:getParent():convertToWorldSpace(unitPos)

        local pos = self.m_slotEffectLayer:convertToNodeSpace(unitPos)

        self.m_reelColDatas[iCol].p_slotColumnPosX = pos.x
        self.m_reelColDatas[iCol].p_slotColumnPosY = pos.y
        self.m_reelColDatas[iCol].p_slotColumnWidth = reelSize.width
        self.m_reelColDatas[iCol].p_slotColumnHeight = reelSize.height

        if reelSize.height > fReelMaxHeight then
            fReelMaxHeight = reelSize.height
            self.m_fReelWidth = reelSize.width
        end
    end

    self.m_fReelHeigth = fReelMaxHeight
    self.m_SlotNodeW = self.m_fReelWidth
    self.m_SlotNodeH = self.m_fReelHeigth / self.m_iReelRowNum

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = math.floor(columnData.p_slotColumnHeight / self.m_SlotNodeH + 0.5) -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end

function BaseReelMachine:getReelNode()
    return "Levels.BaseReel.BaseReelNode"
end

function BaseReelMachine:getBigReelNode()
    return "Levels.BaseReel.BaseReelBigNode"
end

--[[
    创建压黑层
]]
function BaseReelMachine:createBlackLayer(size)
    --压黑层
    self.m_blackLayer = ccui.Layout:create()
    self.m_blackLayer:setContentSize(size)
    self.m_blackLayer:setAnchorPoint(cc.p(0, 0))
    self.m_blackLayer:setTouchEnabled(false)
    self.m_clipParent:addChild(self.m_blackLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 20)
    self.m_blackLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
    self.m_blackLayer:setBackGroundColor(cc.c3b(0, 0, 0))
    self.m_blackLayer:setBackGroundColorOpacity(180)
    self.m_blackLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    self.m_blackLayer:setVisible(false)
end

--[[
    显示压黑层
]]
function BaseReelMachine:showBlackLayer()
    self.m_blackLayer:setVisible(true)
    self.m_blackLayer:stopAllActions()
    util_nodeFadeIn(self.m_blackLayer,0.2,0,180)
end

--[[
    隐藏压黑层
]]
function BaseReelMachine:hideBlackLayer( )
    self.m_blackLayer:stopAllActions()
    util_fadeOutNode(self.m_blackLayer,0.2,function(  )
        self.m_blackLayer:setVisible(false)
    end)
end

---
-- 获取界面上的小块
--
function BaseReelMachine:getReelParentChildNode(iCol, iRow, symbolTag)
    return self:getFixSymbol(iCol, iRow, symbolTag)
end

---
--
function BaseReelMachine:addObservers()
    BaseReelMachine.super.addObservers(self) -- 必须调用不予许删除
end

--
function BaseReelMachine:removeObservers()
    gLobalNoticManager:removeAllObservers(self)
end


function BaseReelMachine:enterGamePlayMusic()

end


-----
---创建一行小块 用于一列落下时 上边条漏出空隙过大
function BaseReelMachine:createResNode(parentData, lastNode)
    
end

--[[
    播放落地动画
]]
function BaseReelMachine:playCustomSpecialSymbolDownAct(slotNode)
    
end


function BaseReelMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        if lineNode ~= nil then
            self.m_lineSlotNodes[lineNodeIndex] = nil
            local nZOrder = lineNode.p_showOrder

            local colIndex = lineNode.p_cloumnIndex
            --将小块放回原层级
            self.m_baseReelNodes[colIndex]:putSymbolBackToRollNode(lineNode.p_rowIndex,lineNode,nZOrder)

            lineNode:runIdleAnim()
        end
    end
end

function BaseReelMachine:clearWinLineEffect()
    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)

        self.m_showLineHandlerID = nil
    end

    self:clearLineAndFrame()

    -- 改变lineSlotNodes 的层级
    self:resetMaskLayerNodes()
end

function BaseReelMachine:beginReel()
    self:resetReelDataAfterReel()
    self:checkChangeBaseParent()

    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end

    local endCount = 0
    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        local moveSpeed = self:getMoveSpeedBySpinMode(self:getCurrSpinMode())
        for iCol = 1,#self.m_baseReelNodes do
            local reelNode = self.m_baseReelNodes[iCol]
            local parentData = self.m_slotParents[iCol]
            parentData.moveSpeed = moveSpeed
            reelNode:changeReelMoveSpeed(moveSpeed)
        end
        reelNode:resetReelDatas()
        reelNode:startMove(function()
            endCount = endCount + 1
            if endCount >= #self.m_baseReelNodes then
                self:requestSpinReusltData()
            end
        end)
    end
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function BaseReelMachine:resetReelDataAfterReel()
    self.m_waitChangeReelTime = 0

    --落地提层的特殊图标列表
    self.m_spcial_symbol_list = {}

    --重置快滚状态
    self.m_isLongRun = false

    --添加线上打印
    local logName = self:getModuleName()
    if logName then
        release_print("beginReel ... GameLevelName = " .. logName)
    else
        release_print("beginReel ... GameLevelName = nil")
    end

    self:stopAllActions()
    -- self:requestSpinReusltData() -- 临时注释掉
    self:beforeCheckSystemData()
    -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
    self.m_nScatterNumInOneSpin = 0
    self.m_nBonusNumInOneSpin = 0

    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SET_SPIN_BTN_ORDER,{false,gLobalViewManager:getViewLayer() })
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        self.m_gameEffects[i] = nil
    end

    self:clearWinLineEffect()

    self.m_showLineFrameTime = nil

    self:resetreelDownSoundArray()
    self:resetsymbolBulingSoundArray()
    if self.m_videoPokeMgr then
        self.m_videoPokeMgr:setInitIconStates(true)
    end
end



--beginReel时尝试修改层级
function BaseReelMachine:checkChangeClipParent(parentData)
    
end

--beginReel时尝试修改层级
function BaseReelMachine:checkChangeBaseParent()
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if childs[i].resetReelStatus ~= nil then
            childs[i]:resetReelStatus()
        end
        if  type(childs[i].isSlotsNode) == "function" and childs[i]:isSlotsNode() then
            if not childs[i].p_showOrder then
                childs[i].p_showOrder = self:getBounsScatterDataZorder(childs[i].p_symbolType)
            end

            local nZOrder = childs[i].p_showOrder

            local colIndex = childs[i].p_cloumnIndex

            --将小块放回原层级
            self:putSymbolBackToPreParent(childs[i])
            
            -- self.m_baseReelNodes[colIndex]:putSymbolBackToRollNode(childs[i].p_rowIndex,childs[i],nZOrder)
        end
    end
end

---
-- 老虎机滚动结束调用
function BaseReelMachine:slotReelDown()
    self:setGameSpinStage(STOP_RUN)
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex
    self.b_gameTipFlag = false
    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end

    
    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()

    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()

    if self.m_videoPokeMgr then
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local iconPos = selfdata.iconLocs
        local isFullCollect = selfdata.isFullCollect
        self.m_videoPokeMgr:playVideoPokerIconFly(iconPos, isFullCollect, self)
    end

    self.m_bonus_down = {}
    self.m_scatter_down = {}

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_SLOTS_STOP)
end

function BaseReelMachine:checkRestSlotNodePos()
    
end

--[[
    @desc: 读取轮盘配置信息
    time:2020-07-11 18:55:11
]]
function BaseReelMachine:readReelConfigData()
    BaseReelMachine.super.readReelConfigData(self)
    if not next(self.m_ScatterShowCol) then
        self.m_ScatterShowCol = {1,2,3,4,5}
    end
end

--[[
    获取长滚距离
]]
function BaseReelMachine:getLongRunLen(col, index)
    local len = 0
    local scatterShowCol = self.m_ScatterShowCol
    local lastColLens = 0
    if self.m_reelRunInfo[col - 1] then
        lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    end 
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if scatterShowCol ~= nil then
        if self:getInScatterShowCol(col) then 
            local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

        elseif col > scatterShowCol[#scatterShowCol] then
            local reelRunData = self.m_reelRunInfo[col - 1]
            local diffLen = self.m_reelRunInfo[2]:getReelRunLen() - self.m_reelRunInfo[1]:getReelRunLen()
            local lastRunLen = reelRunData:getReelRunLen()
            len = lastRunLen + diffLen
            self.m_reelRunInfo[col]:setReelLongRun(false)
        end
    end
    if len == 0 then
        if self:getInScatterShowCol(col) then
            local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
        else
            local diffLen = self.m_reelRunInfo[2]:getReelRunLen() - self.m_reelRunInfo[1]:getReelRunLen()
            len = lastColLens + diffLen
        end
        
    end
    return len
end

function BaseReelMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false

    --长滚效果
    local reelRunData = self.m_reelRunInfo[reelCol]

    local nodeData = reelRunData:getSlotsNodeInfo()

    -- 处理长滚动
    if reelRunData:getNextReelLongRun() == true and self:checkQuickStopStage() then
        isTriggerLongRun = true -- 触发了长滚动

        for i = reelCol + 1, self.m_iReelColumnNum do
            --添加金边
            if i == reelCol + 1 and self:getInScatterShowCol(reelCol + 1) then
                if self.m_reelRunInfo[i]:getReelLongRun() then
                    self:creatReelRunAnimation(i)
                end
            end
            --后面列停止加速移动
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end
    return isTriggerLongRun
end

---
-- 每个reel条滚动到底
function BaseReelMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and self:checkQuickStopStage() then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

    --检测播放落地动画
    self:checkPlayBulingAni(reelCol)

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        if not self.m_isLongRun then
            self.m_isLongRun = true
        end
        self:triggerLongRunChangeBtnStates()

        for iCol = 1,#self.m_baseReelNodes do
            local reelNode = self.m_baseReelNodes[iCol]
            local parentData = self.m_slotParents[iCol]
            reelNode:changeReelMoveSpeed(parentData.moveSpeed)
        end
        
    end

    --检测滚动是否全部停止
    local stopCount = 0
    for iCol,parentData in ipairs(self.m_slotParents) do
        if parentData.isDone then
            stopCount = stopCount + 1
        end
    end

    --滚动彻底停止
    if stopCount >= self.m_iReelColumnNum then
        local delayTime = self.m_configData.p_reelResTime
        self:delayCallBack(delayTime,function()
            self:slotReelDown()
        end)
        
    end

    return isTriggerLongRun
end

--[[
    存到特殊图标列表
]]
function BaseReelMachine:pushToSpecialSymbolList(symbolNode)
    if tolua.isnull(symbolNode) then
        return
    end
    --落地提层的特殊图标列表
    if not self.m_spcial_symbol_list[tostring(symbolNode.p_symbolType)] then
        self.m_spcial_symbol_list[tostring(symbolNode.p_symbolType)] = {}
    end
    local list = self.m_spcial_symbol_list[tostring(symbolNode.p_symbolType)]

    list[#list + 1] = symbolNode
end

--[[
    检测播放落地动画
]]
function BaseReelMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        
        if symbolNode and symbolNode.p_symbolType then
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then
                
                self:pushToSpecialSymbolList(symbolNode)
                
                --提层
                if symbolCfg[1] then
                    local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                    symbolNode:setPositionY(curPos.y)

                    --回弹
                    local actList = {}
                    local moveTime = self.m_configData.p_reelResTime
                    local dis = self.m_configData.p_reelResDis
                    local pos = cc.p(curPos)
                    local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                    local action2 = cc.MoveTo:create(moveTime / 2,pos)
                    actList = {action1,action2}
                    symbolNode:runAction(cc.Sequence:create(actList))
                end

                if self:checkSymbolBulingAnimPlay(symbolNode) then
                    --2.播落地动画
                    symbolNode:runAnim(
                        symbolCfg[2],
                        false,
                        function()
                            self:symbolBulingEndCallBack(symbolNode)
                        end
                    )
                    --bonus落地音效
                    if self:isFixSymbol(symbolNode.p_symbolType) then
                        self:checkPlayBonusDownSound(colIndex)
                    end
                    --scatter落地音效
                    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self:checkPlayScatterDownSound(colIndex)
                    end
                end
            end
            
        end
    end
end

-- 有特殊需求判断的 重写一下
function BaseReelMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self:isFixSymbol(_slotNode.p_symbolType) then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

--[[
    检测播放bonus落地音效
]]
function BaseReelMachine:checkPlayBonusDownSound(colIndex)
    if not self.m_bonus_down[colIndex] then
        --播放bonus
        self:playBonusDownSound(colIndex)
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_bonus_down[iCol] = true
        end
    else
        self.m_bonus_down[colIndex] = true
    end
end

--[[
    检测播放scatter落地音效
]]
function BaseReelMachine:checkPlayScatterDownSound(colIndex)
    if not self.m_scatter_down[colIndex] then
        --播放bonus
        self:playScatterDownSound(colIndex)
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_scatter_down[iCol] = true
        end
    else
        self.m_scatter_down[colIndex] = true
    end
end


--[[
    播放bonus落地音效
]]
function BaseReelMachine:playBonusDownSound(colIndex)
    
end

--[[
    播放scatter落地音效
]]
function BaseReelMachine:playScatterDownSound(colIndex)
    
end

--[[
    判断是否为bonus小块(需要在子类重写)
]]
function BaseReelMachine:isFixSymbol(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        return true
    end
    
    return false
end



---
-- 点击快速停止reel
--
function BaseReelMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")
    if self:getGameSpinStage() == QUICK_RUN then
        return
    end
    self.m_bClickQuickStop = true
    self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。

    for iCol,parentData in ipairs(self.m_slotParents) do
        --还未停止的列执行快停
        if not parentData.isDone then
            self.m_baseReelNodes[iCol]:quickStop()
        end
    end
end

--[[
    @desc: 计算快停时 当前滚动出来的轮盘各列分别需要向上补充的信号个数， 最大那一列不需要补充
    time:2019-03-28 15:57:22
    @return:  返回一个各列需要补充个数的数组，
]]
function BaseReelMachine:getFillTopNodeCountWithQuickStop()
    
end

--[[
    @desc: 处理轮盘滚动中的快停，
    在快停前先检测各列需要补偿的nodecount 数量，一次来补齐各个高度同时需要考虑向下补偿的数量，这种处理
    主要是为了兼容长条模式
    time:2019-03-14 14:54:47
    @return:
]]
function BaseReelMachine:operaQuicklyStopReel()
    
end

function BaseReelMachine:createFinalResultRemoveAllSlotNode(_slotParent, _slotParentBig)
    
end

function BaseReelMachine:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)
    
end

--设置长滚信息
function BaseReelMachine:setReelRunInfo()
    
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
        
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            local reelNode = self.m_baseReelNodes[col]
            reelNode:setRunLen(runLen)

            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        end
        
        local runLen = reelRunData:getReelRunLen()
        
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)

    end --end  for col=1,iColumn do

end




--隐藏盘面信息
function BaseReelMachine:setReelSlotsNodeVisible(status)
    --先把提层的都放回原层
    self:checkChangeBaseParent()
    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        reelNode:setVisible(status)
    end

    self.m_bigReelNodeLayer:setVisible(status)
end

---------------------------------------------removeRespinNode start
--respin结束 移除respin小块对应位置滚轴中的小块
function BaseReelMachine:checkRemoveReelNode(node)
    local symbolNode = self:getFixSymbol(node.p_cloumnIndex,node.p_rowIndex)
    if symbolNode and symbolNode.p_symbolType then
        symbolNode:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(symbolNode.p_symbolType, symbolNode)
    end
end

--裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
function BaseReelMachine:changeBaseParent(slotNode)
    if tolua.isnull(slotNode) or not slotNode.p_symbolType or not slotNode.p_cloumnIndex then
        --小块不存在 没有类型 或者没有所在列跳过
        return
    end
    local nZOrder = slotNode.p_showOrder

    local colIndex = slotNode.p_cloumnIndex
    slotNode:setTag(self:getNodeTag(slotNode.p_cloumnIndex,slotNode.p_rowIndex,SYMBOL_NODE_TAG))
    --将小块放回原层级
    self.m_baseReelNodes[colIndex]:putSymbolBackToRollNode(slotNode.p_rowIndex,slotNode,nZOrder)
end

--[[
    获取小块
]]
function BaseReelMachine:getFixSymbol(iCol, iRow,iTag)
    if not iTag then
        iTag = SYMBOL_NODE_TAG
    end

    local symbolNode = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
    if symbolNode == nil and (iCol >= 1 and iCol <= self.m_iReelColumnNum) then
        symbolNode = self.m_baseReelNodes[iCol]:getSymbolByRow(iRow)
    end
    return symbolNode
end

--[[
    获取连线中的小块
]]
function BaseReelMachine:getSymbolInLineNode(iCol,iRow)
    if self.m_lineSlotNodes and #self.m_lineSlotNodes > 0 then
        for index = 1,#self.m_lineSlotNodes do
            local slotNode = self.m_lineSlotNodes[index]
            if self.m_bigSymbolInfos and self.m_bigSymbolInfos[slotNode.p_symbolType] then
                local longCount = self.m_bigSymbolInfos[slotNode.p_symbolType]
                local longInfo = slotNode.m_longInfo
                if longInfo then
                    longCount = longInfo.curCount
                end
                --位于长条小块索引中间的直接返回长条小块
                if slotNode.p_cloumnIndex == iCol and iRow >= slotNode.p_rowIndex and  iRow <= slotNode.p_rowIndex + longCount - 1 then
                    return slotNode
                end
            end
            if slotNode.p_cloumnIndex == iCol and slotNode.p_rowIndex == iRow then
                return slotNode
            end
        end
    end

    return nil
end

--[[
    根据索引获取小块
]]
function BaseReelMachine:getSymbolByPosIndex(posIndex)
    local posData = self:getRowAndColByPos(posIndex)
    local iCol,iRow = posData.iY,posData.iX

    local symbolNode = self:getFixSymbol(iCol,iRow)
    return symbolNode
end

function BaseReelMachine:getFsTriggerSlotNode(parentData, symPosData)

    local slotNode = self:getFixSymbol(symPosData.iY,symPosData.iX)
    return slotNode
end


function BaseReelMachine:updateNetWorkData()
    BaseReelMachine.super.updateNetWorkData(self)
end

function BaseReelMachine:operaNetWorkData()
    local reels = self.m_runSpinResultData.p_reels

    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        reelNode:setIsWaitNetBack(false)
        local lastList = {}
        for iRow = 1,#reels do
            table.insert(lastList,1,reels[iRow][iCol])
        end
        reelNode:setSymbolList(lastList)
    end

    self:dealSmallReelsSpinStates()

    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

function BaseReelMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
    if startIndex == nil then
        startIndex = 1
    end
    if endIndex == nil then
        endIndex = #winLines
    end

    if bChangeToMask == nil then
        bChangeToMask = true
    end

    local function checkAddLineSlotNode(slotNode)
        if slotNode ~= nil then
            local isHasNode = false
            for checkIndex = 1, #self.m_lineSlotNodes do
                local checkNode = self.m_lineSlotNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end
            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end
            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex = startIndex, endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then
            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i = 1, frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local iCol = symPosData.iY
                local iRow = symPosData.iX

                local reelNode = self.m_baseReelNodes[symPosData.iY]
                local isInLong,longInfo = false,nil
                if reelNode then
                    isInLong,longInfo = reelNode:checkIsInLongByInfo(iRow)
                    if isInLong and longInfo then
                        iRow = longInfo.startIndex
                    end
                end


                local slotNode = self:getSymbolInLineNode(iCol,iRow)
                if not slotNode then
                    slotNode = self:getFixSymbol(iCol,iRow)
                end

                checkAddLineSlotNode(slotNode)

                if slotNode and slotNode.p_symbolType then
                    if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                        self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                    end
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function BaseReelMachine:changeToMaskLayerSlotNode(slotNode)
    if not slotNode or not slotNode.p_symbolType then
        return
    end
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex * 10

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    
    -- 切换图层
    if slotNode.m_longInfo then
        self:createLongClipNode(slotNode)
    else
        local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
        pos = self.m_clipParent:convertToNodeSpace(pos)
        slotNode:setPosition(pos.x, pos.y)
        util_changeNodeParent(self.m_clipParent, slotNode, self:getMaskLayerSlotNodeZorder(slotNode) + slotNode.p_showOrder)
    end
end

--[[
    长条小块提层时需单独创建一个裁切层
]]
function BaseReelMachine:createLongClipNode(slotNode)
    local clipNode = ccui.Layout:create()
    clipNode:setAnchorPoint(cc.p(0, 0))
    clipNode:setTouchEnabled(false)
    clipNode:setSwallowTouches(false)

    local longClipSize = CCSizeMake(self.m_clipReelSize.width * 1.2,self.m_clipReelSize.height)

    local reelPos = cc.p(self.m_csbOwner["sp_reel_0"]:getPosition())
    clipNode:setPosition(cc.p(reelPos.x -(longClipSize.width * 0.1),reelPos.y))

    clipNode:setContentSize(longClipSize)
    clipNode:setClippingEnabled(true)
    self.m_clipParent:addChild(clipNode, self:getMaskLayerSlotNodeZorder(slotNode) + slotNode.p_showOrder)
    slotNode:changeParentToOtherNode(clipNode)
    slotNode.m_longClipNode = clipNode
end

--[[
    延迟回调
]]
function BaseReelMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

---
-- 初始化轮盘界面, 已进入游戏时初始化
--
function BaseReelMachine:initMachineGame()
end

--[[
    @desc: 根据symbolType
    time:2019-03-20 15:12:12
    --@symbolType:
	--@row:
    --@col:
    --@isLastSymbol:
    @return:
]]
function BaseReelMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol,isNotNeedUpdate)
    if isLastSymbol == nil then
        isLastSymbol = false
    end
    local symblNode = self:getSlotNodeBySymbolType(symbolType)
    symblNode.p_cloumnIndex = col
    symblNode.p_rowIndex = row
    symblNode.m_isLastSymbol = isLastSymbol
    if row and col then
        symblNode:setTag(self:getNodeTag(col,row,SYMBOL_NODE_TAG))

    end
    
    if not isNotNeedUpdate then
        self:updateReelGridNode(symblNode)
    end

    if type(self.checkAddSignOnSymbol) == "function" then
        self:checkAddSignOnSymbol(symblNode)
    end
    
    return symblNode
end

--respin结束 把respin小块放回对应滚轴位置
function BaseReelMachine:checkChangeRespinFixNode(node)
    node.p_showOrder = 0
    --将小块放回原层级
    self:changeBaseParent(node)
end

--[[
    变更小块信号值
]]
function BaseReelMachine:changeSymbolType(symbolNode,symbolType,notNeedPutBack)
    if not tolua.isnull(symbolNode) then
        if symbolNode.p_symbolImage then
            symbolNode.p_symbolImage:removeFromParent()
            symbolNode.p_symbolImage = nil
        end

    
        local symbolName = self:getSymbolCCBNameByType(self,symbolType)
        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType), symbolType)
        symbolNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self,symbolType))

        symbolNode.p_symbolType = symbolType

        symbolNode.p_showOrder = self:getBounsScatterDataZorder(symbolType)

        if not notNeedPutBack then
            --将小块放回原层级
            self:changeBaseParent(symbolNode)
        end
        
    end
end

--[[
    将小块放回原父节点
]]
function BaseReelMachine:putSymbolBackToPreParent(symbolNode)
    if not tolua.isnull(symbolNode) and symbolNode.p_symbolType then
        self:changeBaseParent(symbolNode)
    end
end



--重写获取真实数据
function BaseReelMachine:getSymbolTypeForNetData(iCol, iRow, iLen)
    return self.m_stcValidSymbolMatrix[iRow][iCol]
end
--[[
    舍弃父类的一些接口功能
]]
--这个接口会递增 beginReelIndex 的数据导致假滚断层
function BaseReelMachine:produceReelSymbolList()
end


return BaseReelMachine