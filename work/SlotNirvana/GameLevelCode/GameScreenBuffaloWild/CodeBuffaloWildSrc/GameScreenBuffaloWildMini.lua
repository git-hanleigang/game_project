---
-- island li
-- 2019年1月26日
-- GameScreenBuffaloWildMini.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local GameScreenBuffaloWildMini = class("GameScreenBuffaloWildMini", BaseSlotoManiaMachine)

GameScreenBuffaloWildMini.SYMBOL_TYPE_BUFFALO_COIN = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  + 1
GameScreenBuffaloWildMini.SYMBOL_TYPE_NINE = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
GameScreenBuffaloWildMini.SYMBOL_TYPE_TEN = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1  + 1


GameScreenBuffaloWildMini.m_updateCoin = nil
GameScreenBuffaloWildMini.m_parent = nil -- 父类
-- 构造函数
function GameScreenBuffaloWildMini:ctor()
    BaseSlotoManiaMachine.ctor(self)
end

function GameScreenBuffaloWildMini:initData_( data )
    
    self.m_machineIndex = data.index
    self.m_parent = data.parent
    self.m_reelDownCallback = data.func
    self.m_collectList = {}
    self.m_bIsUnlock = false
    self.m_bHasFiveOfKind = false
    self.m_lockWildCol = {}
    self.m_vecLockWilds = {}
    self.m_spinWinCount = 0
    --滚动节点缓存列表
    self.cacheNodeMap = {}
    self:initGame()
end

function GameScreenBuffaloWildMini:initGame()

	--初始化基本数据
    self:initMachine(self.m_moduleName)
end  

function GameScreenBuffaloWildMini:initLock(machineNum, unlockSetHearts)
    if self.m_machineIndex > machineNum then
        if self.m_lock == nil then
            local data = {}
            data.wheelNum = self.m_machineIndex
            local num = unlockSetHearts[self.m_machineIndex]
            data.collectNum = num
            self.m_lock = util_createView("CodeBuffaloWildSrc.BuffaloWildUnlockWords", data)
            self:addChild(self.m_lock,100)
        end
        self.m_lock:setVisible(true)
        self.m_bIsUnlock = false
    else
        self.m_bIsUnlock = true
    end

    self.m_nodeWinWords = self:findChild("winWords")
    self.m_nodeWinWords:setVisible(false)
    self.m_labWinCoin = self:findChild("winCoin")
    self.m_labWinCoin:setString("")
    self.m_labWinCoin:setVisible(false)
    self.m_spinWinCount = 0

    self.m_iCurrReelCol = self.m_iReelColumnNum
end

function GameScreenBuffaloWildMini:initMachine( )

    self.m_moduleName = self:getModuleName()

    self.m_machineModuleName = self.m_moduleName

    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("BuffaloWild/GameScreenBuffaloWildMini.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
    self:updateBaseConfig()
    
    self:updateMachineData()
    self:initMachineData()
    self:initSymbolCCbNames()

    self:drawReelArea()

    self:updateReelInfoWithMaxColumn()
    self:initReelEffect()

    self:slotsReelRunData(self.m_configData.p_reelRunDatas, false
    ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
    ,self.m_configData.p_bPlayBonusAction)
end

---
-- 读取配置文件数据
--
function GameScreenBuffaloWildMini:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
end


---
-- 清空掉产生的数据
--
function GameScreenBuffaloWildMini:clearSlotoData()
    
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
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameScreenBuffaloWildMini:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BuffaloWild"  
end

----------------------------- 玩法处理 -----------------------------------


function GameScreenBuffaloWildMini:addSelfEffect()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParentChildNode(iCol, iRow)
            if node then
                if node.p_symbolType == self.SYMBOL_TYPE_BUFFALO_COIN then
                    self.m_collectList[#self.m_collectList + 1] = node
                end
            end
        end
    end
end

function GameScreenBuffaloWildMini:MachineRule_playSelfEffect(effectData)
    return true
end

function GameScreenBuffaloWildMini:playEffectNotifyNextSpinCall( )
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_collectList, self.m_bHasFiveOfKind)
    end
end

function GameScreenBuffaloWildMini:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas

end

function GameScreenBuffaloWildMini:beginReel()
    self.m_bHasFiveOfKind = false
    -- self.m_labWinCoin:setString("")
    if self.m_updateCoinHandlerID ~= nil then
        self.m_labWinCoin:setString(util_formatCoins(self.m_spinWinCount, 30))   
        self:updateLabelSize({label = self.m_labWinCoin,sx = 0.8,sy = 0.8}, 175) 
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)  
        self.m_updateCoinHandlerID = nil
    end
    for i = 1, #self.m_lockWildCol, 1 do
        local iCol = self.m_lockWildCol[i]
        local colParent = self:getReelParent(iCol)
        colParent:setVisible(false)
    end

    BaseSlotoManiaMachine.beginReel(self)

    self:beginNewReel()
end


function GameScreenBuffaloWildMini:operaNetWorkData()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                                        {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
    for i = #self.m_vecLockWilds, 1, -1 do
        local wild = self.m_vecLockWilds[i]
        local animation = wild:getSlotsNodeAnima()
        if animation ~= "idleframe2" then
            wild:runAnim("idleframe2", true)
        end
    end

end

function GameScreenBuffaloWildMini:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function GameScreenBuffaloWildMini:requestSpinReusltData()
    -- do nothing 
    self.m_isWaitingNetworkData = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
        {SpinBtn_Type.BtnType_Spin,false})

end

function GameScreenBuffaloWildMini:setFSReelDataIndex(index)
    self.m_fsReelDataIndex = index
end

function GameScreenBuffaloWildMini:unlock(func)
    performWithDelay(self, function()
        self.m_lock:setVisible(false)
    end, 1.25)
    self.m_bIsUnlock = true
    local effect, act = util_csbCreate("BuffaloWild_reel_change.csb")
    self:addChild(effect, 100)
    util_csbPlayForKey(act, "actionframe", false, function()
        if func ~= nil then
            func()
        end
        effect:removeFromParent()
    end, 20)
end

function GameScreenBuffaloWildMini:initRandomSlotNodes()
    self.m_initGridNode = true
    for i = #self.m_lockWildCol, 1, -1 do
        local iCol = self.m_lockWildCol[i]
        local colParent = self:getReelParent(iCol)
        colParent:setVisible(true)
        table.remove(self.m_lockWildCol, i)
    end
    self:clearWinLineEffect()
    self:removeAllReelsNode()
    --新滚动使用移除所有小块
    self:removeAllGridNodes()
    for colIndex=1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, colIndex)
        local resulSymbol = {}
        local index = math.random(1, #reelData)
        for i = 1, resultLen, 1 do
            index = index + 1
            if index > #reelData then
                index = 1 
            end
            resulSymbol[i] = reelData[index]
        end

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex=1,resultLen do
            
            local symbolType = resulSymbol[resultLen - (rowIndex - 1)]

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = reelColData.p_showGridH      
            
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
            if not node:getParent() then
                parentData.slotParent:addChild(node,node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder - rowIndex)
                node:setVisible(true)
            end
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * reelColData.p_showGridH + halfNodeH )

        end
    end
    self:initGridList()
end

function GameScreenBuffaloWildMini:initSlotNode(data)
    --新滚动使用移除所有小块
    self:removeAllGridNodes()
    self.m_initGridNode = true
    self.m_runSpinResultData.p_reels = data.reels
    for colIndex=self.m_iReelColumnNum,  1, -1 do

        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum  -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false 

        while rowIndex >= 1 do

            local rowDatas = data.reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            
            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end

            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            if not node:getParent() then
                parentData.slotParent:addChild(node,REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
            else
                node:setTag(REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder)
                node:setLocalZOrder(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setVisible(true)
            end
            node.p_slotNodeH = columnData.p_showGridH
            node.p_showOrder = showOrder
            node.p_symbolType = symbolType
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (changeRowIndex - 1) * columnData.p_showGridH + halfNodeH )    
            rowIndex = rowIndex - stepCount
        end  -- end while

    end
    if data.freespin.fsWinCoins ~= nil and data.freespin.fsWinCoins > 0 then
        self.m_spinWinCount = data.freespin.fsWinCoins
        self.m_labWinCoin:setString(util_formatCoins(self.m_spinWinCount, 30))
        self:updateLabelSize({label = self.m_labWinCoin,sx = 0.8,sy = 0.8}, 175)
        self.m_nodeWinWords:setVisible(true)
        self.m_labWinCoin:setVisible(true)
    end
    self:initGridList()
end

function GameScreenBuffaloWildMini:removeAllReelsNode()
    for i = #self.m_vecLockWilds, 1, -1 do
        local wild = self.m_vecLockWilds[i]
        if wild and wild.updateLayerTag then
            wild:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end
        wild:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(wild.p_symbolType,wild)
        table.remove(self.m_vecLockWilds, i)
    end
end

function GameScreenBuffaloWildMini:operaQuicklyStopReel( )
    if self.m_bIsUnlock ~= true then
        return
    end
    BaseSlotoManiaMachine.operaQuicklyStopReel(self)
end

function GameScreenBuffaloWildMini:setWheelLock()
    self.m_bIsUnlock = false
end

function GameScreenBuffaloWildMini:enterLevel()
   
end

function GameScreenBuffaloWildMini:enterGamePlayMusic(  )
    
end

function GameScreenBuffaloWildMini:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function GameScreenBuffaloWildMini:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
end

function GameScreenBuffaloWildMini:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    self:clearCacheMap()
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameScreenBuffaloWildMini:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_TYPE_BUFFALO_COIN then
        return "Socre_BuffaloWild_Bonus"
    elseif symbolType == self.SYMBOL_TYPE_NINE  then
        return "Socre_BuffaloWild_11"
    elseif symbolType == self.SYMBOL_TYPE_TEN  then
        return "Socre_BuffaloWild_10"  
    end
    return nil
end
---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function GameScreenBuffaloWildMini:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_NINE, count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_TEN, count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_BUFFALO_COIN, count =  2}


    return loadNode
end

function GameScreenBuffaloWildMini:lockWild(lockCol)
    self:clearWinLineEffect()
    for i = 1, #lockCol, 1 do
        self.m_iCurrReelCol = self.m_iCurrReelCol - 1
        local iCol = lockCol[i]
        self.m_lockWildCol[#self.m_lockWildCol + 1] = iCol
        
        for iRow = 1, self.m_iReelRowNum, 1 do
            local targSp =  self:getReelParentChildNode(iCol, iRow)
            local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol , iRow, SYMBOL_NODE_TAG))
            if not targSp then
                targSp = clipSp
            end
            if targSp then
                if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    local ccbName = self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    targSp:changeCCBByName(ccbName,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    targSp:initSlotNodeByCCBName(ccbName,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                end
                targSp.p_idleIsLoop = true
                targSp:runAnim("idleframe2", true)
                targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                self.m_vecLockWilds[#self.m_vecLockWilds + 1] = targSp
            end
        end
    end
end

function GameScreenBuffaloWildMini:lockWildAnimation(lockCol)
    self:clearWinLineEffect()
    if self.m_lockWildCol ~= nil and #self.m_lockWildCol > 0 then
        for i = 1, #self.m_lockWildCol, 1 do
            local iCol = self.m_lockWildCol[i]
            local targSp = nil
            for i = 1, #self.m_vecLockWilds, 1 do
                local wild = self.m_vecLockWilds[i]
                if wild.p_cloumnIndex == iCol and wild.p_rowIndex == 2 then
                    targSp = wild
                    break
                end
            end
            local effect, act = util_csbCreate("WinFrameBuffaloWild_wild_saoguang.csb")
            self.m_clipParent:addChild(effect, 80000)
            local pos = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
            pos = self.m_clipParent:convertToNodeSpace(pos)
            effect:setPosition(pos)
            util_csbPlayForKey(act, "run", false, function()
                effect:removeFromParent()
            end)
        end
    end
    if lockCol == nil then
        return
    end
    for i = 1, #lockCol, 1 do
        self.m_iCurrReelCol = self.m_iCurrReelCol - 1
        local iCol = lockCol[i]
        self.m_lockWildCol[#self.m_lockWildCol + 1] = iCol
        local targSp = self:getReelParentChildNode(iCol, 2)
        local effect, act = util_csbCreate("WinFrameBuffaloWild_wild_saoguang.csb")
        targSp:getParent():addChild(effect, 80000)
        effect:setPosition(targSp:getPositionX(), targSp:getPositionY())
        performWithDelay(self, function()
            for iRow = 1, self.m_iReelRowNum, 1 do
                local targSp =  self:getReelParentChildNode(iCol, iRow)
                local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol , iRow, SYMBOL_NODE_TAG))
                if not targSp then
                    targSp = clipSp
                end
                if targSp then
                    if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        local targSpColIndex = targSp.p_cloumnIndex
                        local symbolNodeList = self.cacheNodeMap[targSpColIndex]
                        if symbolNodeList == nil then
                            symbolNodeList = {}
                            self.cacheNodeMap[targSpColIndex] = symbolNodeList
                        end
                        local wild = self:getCacheNode(targSpColIndex)
                        if wild == nil then
                            wild = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                            targSp:getParent():addChild(wild)
                        else
                            wild:setVisible(true)
                            wild:setLocalZOrder(0)
                            wild:setTag(0)
                            local ccbName = self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                            wild:changeCCBByName(ccbName,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                            wild:initSlotNodeByCCBName(ccbName,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                        end
                        wild:setPosition(targSp:getPositionX(), targSp:getPositionY())
                        wild.p_cloumnIndex = targSpColIndex
                        wild.p_rowIndex = targSp.p_rowIndex
                        wild.m_isLastSymbol = targSp.m_isLastSymbol
                        wild.cacheFlag = false
                        
                        targSp:reset()
                        targSp:setTag(-1)
                        targSp.cacheFlag = true
                        targSp:setVisible(false)
                        table.insert(symbolNodeList,targSp)
                        targSp = wild
                    end
                    targSp.p_idleIsLoop = true
                    targSp:runAnim("idleframe2", true)
                    targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
                    targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                    targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                    targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                    self.m_vecLockWilds[#self.m_vecLockWilds + 1] = targSp
                end
            end
        end, 1 / 3)
        util_csbPlayForKey(act, "run", false, function()
            effect:removeFromParent()
        end)
    end
end

function GameScreenBuffaloWildMini:normalSpinBtnCall()

end

function GameScreenBuffaloWildMini:spinResultCallFun(param)
end

function GameScreenBuffaloWildMini:checkNotifyUpdateWinCoin()
    if self.m_runSpinResultData.p_winAmount and self.m_runSpinResultData.p_winAmount > 0 then
        if self.m_nodeWinWords:isVisible() == false then
            self.m_nodeWinWords:setVisible(true)
            self.m_labWinCoin:setVisible(true)
        end
        local winCoin = self.m_runSpinResultData.p_winAmount
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local showTime = 2
        if winRate <= 1 then
            showTime = 1
        elseif winRate > 1 and winRate <= 3 then
            showTime = 1.5
        elseif winRate > 3 and winRate <= 6 then
            showTime = 2.5
        elseif winRate > 6 then
            showTime = 4
        end
        
        local coinRiseNum =  winCoin / (showTime * 60)  -- 每秒60帧

        local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
        coinRiseNum = tonumber(str)
        

        coinRiseNum = math.floor(coinRiseNum ) 
        if self.m_curSpinCount == nil then
            
        end
        
        local curSpinCount = self.m_spinWinCount
        self.m_spinWinCount = self.m_runSpinResultData.p_fsWinCoins
        if self.m_spinWinCount == 0 then
            print("error")
        end
        self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

            curSpinCount = curSpinCount + coinRiseNum
    
            if curSpinCount >= self.m_spinWinCount then
                curSpinCount = self.m_spinWinCount
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            end
    
            self.m_labWinCoin:setString(util_formatCoins(curSpinCount, 30))
            self:updateLabelSize({label = self.m_labWinCoin,sx = 0.8,sy = 0.8}, 175)
        end)
    end
end

function GameScreenBuffaloWildMini:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) 
    and 
    (self:getGameSpinStage( ) ~= QUICK_RUN 
    or self.m_hasBigSymbol == true
    )
    then
        self:creatReelRunAnimation(reelCol + 1)
    end


    if self.m_reelDownSoundPlayed  then

        if self.m_machineIndex == 1 and reelCol <= self.m_iCurrReelCol then
            self:playReelDownSound(reelCol,self.m_reelDownSound )
        end

    else
        if self.m_machineIndex == 1 and reelCol <= self.m_iCurrReelCol then
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
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    -- bonus 落地音效
    local hasBonus = false
    for k = 1, self.m_iReelRowNum do
        if self.m_stcValidSymbolMatrix[k][reelCol] == self.SYMBOL_TYPE_BUFFALO_COIN then
            hasBonus = true
            local symbolNode =  self:getFixSymbol(reelCol,k,SYMBOL_NODE_TAG)
            if symbolNode then
                symbolNode:runAnim("buling")
            end
        end
    end
    if hasBonus == true then

        local soundPath = "BuffaloWildSounds/sound_buffalo_wild_bonus_down.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            -- respinbonus落地音效
            gLobalSoundManager:playSound(soundPath)
        end

    end
end

function GameScreenBuffaloWildMini:calculateLastWinCoin()

end

function GameScreenBuffaloWildMini:addLastWinSomeEffect() -- add big win or mega win
    if self:checkHasEffectType(GameEffect.EFFECT_FIVE_OF_KIND) == true then 
        self.m_bHasFiveOfKind = false
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == true then
        self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    end
end

function GameScreenBuffaloWildMini:reelDownNotifyChangeSpinStatus()
    -- do nothing 滚动停止不通知
end

function GameScreenBuffaloWildMini:playEffectNotifyChangeSpinStatus( )
end

function GameScreenBuffaloWildMini:staticsTasksSpinData()
end
function GameScreenBuffaloWildMini:staticsTasksNetWinAmount()
end
function GameScreenBuffaloWildMini:staticsTasksEffect()
end
function GameScreenBuffaloWildMini:showPaytableView()
end

function GameScreenBuffaloWildMini:setCurrSpinMode( spinMode )
    self.m_currSpinMode = spinMode
end
function GameScreenBuffaloWildMini:getCurrSpinMode( )
    return self.m_currSpinMode
end

function GameScreenBuffaloWildMini:setGameSpinStage( spinStage )
    self.m_currSpinStage = spinStage
end
function GameScreenBuffaloWildMini:getGameSpinStage( )
    return self.m_currSpinStage
end

function GameScreenBuffaloWildMini:setLastWinCoin( winCoin )
    self.m_lastWinCoin = winCoin
end
function GameScreenBuffaloWildMini:getLastWinCoin(  )
    return self.m_lastWinCoin
end



function GameScreenBuffaloWildMini:MachineRule_afterNetWorkLineLogicCalculate()
--    if self.m_parent then
--         globalData.slotRunData.freeSpinCount = self.m_parent.m_runSpinResultData.p_freeSpinsLeftCount
--         globalData.slotRunData.totalFreeSpinCount = self.m_parent.m_runSpinResultData.p_freeSpinsTotalCount   
--    end
    
    
end








function GameScreenBuffaloWildMini:foreachSlotParent(colIndex,callBack)
    local slotParentData = self.m_slotParents[colIndex]
    local realIndex = 0
    local index = 0
    if slotParentData ~= nil then
        local slotParent = slotParentData.slotParent
        local childs = slotParent:getChildren()
        while index < #childs do
            index = index + 1
            local node = childs[index]
            if not node.cacheFlag then
                realIndex = realIndex + 1
                if callBack ~= nil then
                    local flag = callBack(index,realIndex,node)
                    if flag then
                        break
                    end
                end
            end
        end
    end
    return index,realIndex
end

---
-- 重置列的 local zorder
--
function GameScreenBuffaloWildMini:resetCloumnZorder(col)
    if col < 1 or col > self.m_iReelColumnNum then
        return
    end
    local parentData = self.m_slotParents[col]
    local slotParent = parentData.slotParent
    local totalOrder = 0
    self:foreachSlotParent(col,
    function(index,realIndex,slotNode)
        totalOrder = totalOrder + slotNode:getLocalZOrder()
    end)
    slotParent:getParent():setLocalZOrder(totalOrder)
end

function GameScreenBuffaloWildMini:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_resTopTypes
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType

end

--小块
function GameScreenBuffaloWildMini:getBaseReelGridNode()
    return "CodeBuffaloWildSrc.SlotsNodeMiniReels"
end

function GameScreenBuffaloWildMini:checkControlerReelType( )
    return false
end

return GameScreenBuffaloWildMini






