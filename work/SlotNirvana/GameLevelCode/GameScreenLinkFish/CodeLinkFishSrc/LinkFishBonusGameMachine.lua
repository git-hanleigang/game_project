---
-- island
-- 2018年6月4日
-- LinkFishBonusGameMachine.lua
-- 
-- 玩法：
-- 


local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local CollectData = require "data.slotsdata.CollectData"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local LinkFishBonusGameMachine = class("LinkFishBonusGameMachine", BaseSlotoManiaMachine)

-- 锁定两种信号类型，只是对应不同倍数
LinkFishBonusGameMachine.m_bnBase1Type = 101
LinkFishBonusGameMachine.m_bnBase2Type = 102

LinkFishBonusGameMachine.SYMBOL_FIX_MINI = 103       
LinkFishBonusGameMachine.SYMBOL_FIX_MINOR = 104
LinkFishBonusGameMachine.SYMBOL_FIX_MAJOR = 105


-- 构造函数
function LinkFishBonusGameMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
	--init
	self:initGame()
end

function LinkFishBonusGameMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
end  

function LinkFishBonusGameMachine:initUI()

    
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin  then
            return
        end
        local index = util_random(1,4)
        local soundName = "LinkFishSounds/music_LinkFish_last_win_" .. index .. ".mp3"
        local soundTime = 1
        if index == 1 then
            soundTime = 2
        elseif index == 2 then
            soundTime = 3
        elseif index == 3 then
            soundTime = 3
        end
        globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function LinkFishBonusGameMachine:initMachine( )

    self.m_moduleName = self:getModuleName()


    self.m_machineModuleName = self.m_moduleName

    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("LinkFish/BonusGameMachine.csb")
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

    self:slotsReelRunData(self.m_configData.p_reelRunDatas,self.m_configData.p_bInclScatter
    ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
    ,self.m_configData.p_bPlayBonusAction)
end

function LinkFishBonusGameMachine:initMachineData()
    

    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName.."_Datas"
    
    

    
    -- 设置bet index

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    self:checkHasBigSymbol()
end

---
-- 读取配置文件数据
--
function LinkFishBonusGameMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(),"LevelLinkFishConfig.lua")
    end
end


---
-- 清空掉产生的数据
--
function LinkFishBonusGameMachine:clearSlotoData()
    
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
function LinkFishBonusGameMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "LinkFish"  
end

function LinkFishBonusGameMachine:getNetWorkModuleName()
    return "PandaBlessV2"
end

-- 重写 getSlotNodeWithPosAndType 方法
function LinkFishBonusGameMachine:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)


    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType,iRow,iCol,isLastSymbol)

    -- symbolType == self.SYMBOL_FIX_CHIP or 
    if symbolType == self.m_bnBase1Type
        or symbolType == self.m_bnBase2Type 
        or symbolType == self.SYMBOL_FIX_MINI       
        or symbolType == self.SYMBOL_FIX_MINOR 
        or symbolType == self.SYMBOL_FIX_MAJOR
        or symbolType == self.SYMBOL_FIX_GRAND 
    then
        --下帧调用 才可能取到 x y值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
        reelNode:runAction(callFun)
    end
    return reelNode
end

function LinkFishBonusGameMachine:getReSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil
    
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return nil
    end

    local pos = self:getRowAndColByPos(idNode)
    local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if type < 1000 then
        if score == 50 then
            score = "MINI"
        elseif score == 100 then
            score = "MINOR"
        elseif score == 1000 then
            score = "MAJOR"
        end
    end
    return score
end

function LinkFishBonusGameMachine:setSpecialNodeScore(sender,parma)
    local symbolNode = parma[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --获取分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
            end
            
        end

        if symbolNode then
            symbolNode:runAnim("idleframe",true)
        end

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
            end
        end
        if symbolNode then
            symbolNode:runAnim("idleframe",true)
        end
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function LinkFishBonusGameMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.m_bnBase1Type or symbolType == self.m_bnBase2Type then
        return "Socre_LinkFish_Chip"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_LinkFish_Mini"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_LinkFish_Minor"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_LinkFish_Major"
    end

    return nil
end

function LinkFishBonusGameMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if self.m_bProduceSlots_InFreeSpin then
        if symbolType == self.m_bnBase1Type then
            score = self.m_configData:getBnFSPro1()
        elseif symbolType == self.m_bnBase2Type then
            score = self.m_configData:getBnFSPro2()
        end
    else
        if symbolType == self.m_bnBase1Type then
            score = self.m_configData:getBnBasePro1()
        elseif symbolType == self.m_bnBase2Type then
            score = self.m_configData:getBnBasePro2()
        end
    end
 

    return score
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function LinkFishBonusGameMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.m_bnBase1Type,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.m_bnBase2Type,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINI,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MAJOR,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

function LinkFishBonusGameMachine:slotOneReelDown(reelCol)    
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol)   
end

function LinkFishBonusGameMachine:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)
    
end

---------------------------------------------------------------------------

function LinkFishBonusGameMachine:beginReel()

    BaseSlotoManiaMachine.beginReel(self)

    self:setGameSpinStage( GAME_MODE_ONE_RUN )

end

function LinkFishBonusGameMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function LinkFishBonusGameMachine:requestSpinReusltData()
    -- do nothing 
        self.m_isWaitingNetworkData = true

end
---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function LinkFishBonusGameMachine:initCloumnSlotNodesByNetData()

    BaseSlotoManiaMachine.initCloumnSlotNodesByNetData(self)

end

function LinkFishBonusGameMachine:enterLevel()
   
end

function LinkFishBonusGameMachine:initSlotNode(reels)
    self.m_runSpinResultData.p_reels = reels
    for colIndex=self.m_iReelColumnNum,  1, -1 do

        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum  -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false 

        while rowIndex >= 1 do

            local rowDatas = reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            
            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType)
            
            parentData.slotParent:addChild(node,
                REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)

            node.p_symbolType = symbolType
--            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (changeRowIndex - 1) * columnData.p_showGridH + halfNodeH )
            node:runIdleAnim()      
            rowIndex = rowIndex - stepCount
        end  -- end while

    end
end

function LinkFishBonusGameMachine:initFixWild(lockWild)
    local vecFixWild = lockWild
    if vecFixWild == nil then
        return
    end
    for i = 1, #vecFixWild, 1 do
        local fixPos = self:getRowAndColByPos(vecFixWild[i])
        local targSp =  self:getReelParentChildNode(fixPos.iY, fixPos.iX)
        if targSp then
            if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local wild = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                targSp:getParent():addChild(wild)
                wild:setPosition(targSp:getPositionX(), targSp:getPositionY())
                wild.p_cloumnIndex = targSp.p_cloumnIndex
                wild.p_rowIndex = targSp.p_rowIndex
                wild.m_isLastSymbol = targSp.m_isLastSymbol
                targSp:removeFromParent()
                local symbolType = targSp.p_symbolType
                self:pushSlotNodeToPoolBySymobolType(symbolType, targSp)
                targSp = nil
                targSp = wild
            end
            targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

            if self.m_vecFixWild == nil then
                self.m_vecFixWild = {}
            end
            self.m_vecFixWild[#self.m_vecFixWild + 1] = targSp
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
        end
    end
end

function LinkFishBonusGameMachine:setFSReelDataIndex(index)
    self.m_fsReelDataIndex = index
end

function LinkFishBonusGameMachine:setStoredIcons(storedIcons)
    self.m_runSpinResultData.p_storedIcons = storedIcons
end

function LinkFishBonusGameMachine:enterGamePlayMusic(  )
    
end

function LinkFishBonusGameMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
end

function LinkFishBonusGameMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
end

function LinkFishBonusGameMachine:onExit()
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function LinkFishBonusGameMachine:checkNotifyUpdateWinCoin( )
    -- do nothing mini 轮子不在通知赢钱线的变化了
end

function LinkFishBonusGameMachine:calculateLastWinCoin()
end

function LinkFishBonusGameMachine:addLastWinSomeEffect() -- add big win or mega win
end

function LinkFishBonusGameMachine:reelDownNotifyChangeSpinStatus()
    -- do nothing 滚动停止不通知
end

function LinkFishBonusGameMachine:playEffectNotifyChangeSpinStatus( )
end

function LinkFishBonusGameMachine:playEffectNotifyNextSpinCall( )
end

function LinkFishBonusGameMachine:staticsTasksSpinData()
end
function LinkFishBonusGameMachine:staticsTasksNetWinAmount()
end
function LinkFishBonusGameMachine:staticsTasksEffect()
end

function LinkFishBonusGameMachine:setCurrSpinMode( spinMode )
    self.m_currSpinMode = spinMode
end
function LinkFishBonusGameMachine:getCurrSpinMode( )
    return self.m_currSpinMode
end

function LinkFishBonusGameMachine:setGameSpinStage( spinStage )
    self.m_currSpinStage = spinStage
end
function LinkFishBonusGameMachine:getGameSpinStage( )
    return self.m_currSpinStage
end

function LinkFishBonusGameMachine:setLastWinCoin( winCoin )
    self.m_lastWinCoin = winCoin
end
function LinkFishBonusGameMachine:getLastWinCoin(  )
    return self.m_lastWinCoin
end

return LinkFishBonusGameMachine






