---
-- xcyy
-- 2018-12-18 
-- FarmMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"


local FarmMiniMachine = class("FarmMiniMachine", BaseMiniMachine)



FarmMiniMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  

FarmMiniMachine.SYMBOL_FIX_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE   
FarmMiniMachine.SYMBOL_FIX_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
FarmMiniMachine.SYMBOL_FIX_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 -- 金色瓜

FarmMiniMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5
FarmMiniMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4
FarmMiniMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3


FarmMiniMachine.m_machineIndex = nil -- csv 文件模块名字

FarmMiniMachine.gameResumeFunc = nil
FarmMiniMachine.gameRunPause = nil


local Three_Five_Reels = 3
local Four_Five_Reels = 4

local MainReelId = 1


-- 构造函数
function FarmMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    
end

function FarmMiniMachine:initData_( data )


    self.gameResumeFunc = nil
    self.gameRunPause = nil
    
    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_reelId = data.reelId
    self.m_csbPath = data.csbPath
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function FarmMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FarmMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Farm"
end

function FarmMiniMachine:getMachineConfigName()

    local str = ""

    if self.m_machineIndex == Three_Five_Reels then 
        str = "Mini"
    end

    return self.m_moduleName.. str .. "Config"..".csv"
end

-- 根据网络数据获得respinBonus小块的分数
function FarmMiniMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
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
        -- assert(score, "根据网络数据获得respinBonus小块的分数 是空的")
        -- 如果是空 那就用 self.SYMBOL_FIX_BONUS_1 随机的
        return self:randomDownRespinSymbolScore(self.SYMBOL_FIX_BONUS_1)
    end


    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    

    if symbolType == self.SYMBOL_FIX_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR  then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR  then
        score = "MAJOR"
    end

    return score
end

-- 给respin小块进行赋值
function FarmMiniMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score,3,nil,nil,true)
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
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score,3,nil,nil,true)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
                symbolNode:runAnim("idleframe",true)
            end

        end
        
    end

end

function FarmMiniMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_BONUS_1 or 
        symbolType == self.SYMBOL_FIX_BONUS_2 or 
        symbolType == self.SYMBOL_FIX_BONUS_3 then

            
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end


    return score
end

function FarmMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if  symbolType == self.SYMBOL_FIX_BONUS_1 or 
    symbolType == self.SYMBOL_FIX_BONUS_3 or 
    symbolType == self.SYMBOL_FIX_BONUS_2 then
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        -- self:runAction(callFun)
        self:setSpecialNodeScore(self,{node})
    end
end

function FarmMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if  symbolType == self.SYMBOL_FIX_BONUS_1 or 
        symbolType == self.SYMBOL_FIX_BONUS_3 or 
        symbolType == self.SYMBOL_FIX_BONUS_2 then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FarmMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if symbolType == self.SYMBOL_FIX_BONUS_1  then
        return "Socre_Farm_Bouns"
    elseif symbolType == self.SYMBOL_FIX_BONUS_3  then
        return "Socre_Farm_Bouns"
        
    elseif symbolType == self.SYMBOL_FIX_BONUS_2  then
        return "Socre_Farm_Bouns2"
    elseif symbolType == self.SYMBOL_SCORE_10  then
        return "Socre_Farm_10"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_Farm_Bouns_Major"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_Farm_Bouns_Minor"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_Farm_Bouns_Mini"
    end
 
    return ccbName
end

function FarmMiniMachine:getlevelConfigName( )
    local levelConfigName = "LevelFarmConfig.lua"

    if self.m_machineIndex == Three_Five_Reels then 
        levelConfigName = "LevelFarmMiniConfig.lua"
    end

    return levelConfigName

end


---
-- 读取配置文件数据
--
function FarmMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(),self:getlevelConfigName())
    end
    self.m_configData:setGameLevel( self )

    globalData.slotRunData.levelConfigData = self.m_configData
end

--[[
    @desc: 读取音乐、音效配置信息
    time:2020-07-11 18:55:11
]]
function FarmMiniMachine:readSoundConfigData( )
    --音乐
    self:setBackGroundMusic(self.m_configData.p_musicBg)--背景音乐
    self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)--fs背景音乐
    self:setRsBackGroundMusic(self.m_configData.p_musicReSpinBg)--respin背景
    self.m_ScatterTipMusicPath = self.m_configData.p_soundScatterTip --scatter提示音
    self.m_BonusTipMusicPath = self.m_configData.p_soundBonusTip --bonus提示音
    if self.m_reelId == MainReelId then
        self:setReelDownSound(self.m_configData.p_soundReelDown)--下落音
    end

    self:setReelRunSound(self.m_configData.p_reelRunSound)--快滚音效
end

function FarmMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    local csbName = "Farm/" .. self.m_csbPath .. ".csb"
    self:createCsbNode(csbName)
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function FarmMiniMachine:initMachine()
    self.m_moduleName = "Farm" -- self:getModuleName()

    BaseMiniMachine.initMachine(self)

end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function FarmMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()
    
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS_3,count =  2}
    

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINI,count =  2}

    

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function FarmMiniMachine:addSelfEffect()

end


function FarmMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end

function FarmMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end


function FarmMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end

function FarmMiniMachine:reelDownNotifyChangeSpinStatus()
  
    -- 发送freespin停止回调
    if self.m_reelId == MainReelId then
        gLobalNoticManager:postNotification("FarmReelDownInFS")
    end
    
end



function FarmMiniMachine:playEffectNotifyChangeSpinStatus( )

    self.m_parent:setFsAllRunDown( 1)
end

function FarmMiniMachine:reelDownNotifyPlayGameEffect()
    self:playGameEffect()
end

----
-- 检测处理effect 结束后的逻辑
--
function FarmMiniMachine:operaEffectOver()
    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = false
    end

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    -- self:playEffectNotifyChangeSpinStatus()

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end


function FarmMiniMachine:quicklyStopReel(colIndex)

    BaseMiniMachine.quicklyStopReel(self, colIndex)
end

function FarmMiniMachine:onExit()
    BaseSlots.onExit(self)
    self:removeObservers()

    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
        self.m_showLineHandlerID = nil
    end

    self.m_gameEffects = {}

    self:clearFrameNodes()
    self:clearSlotNodes()
    -- 卸载金边
    for i, v in pairs(self.m_reelRunAnima) do
        local reelNode = v[1]
        local reelAct = v[2]

        if not tolua.isnull(reelNode) then
            if reelNode:getParent() ~= nil then
                reelNode:removeFromParent()
            end
            reelNode:release()
        end

        if not tolua.isnull(reelAct) then
            reelAct:release()
        end
        self.m_reelRunAnima[i] = nil
    end
    if self.m_reelRunAnimaBG ~= nil then
        for i, v in pairs(self.m_reelRunAnimaBG) do
            local reelNode = v[1]
            local reelAct = v[2]

            if not tolua.isnull(reelNode) then
                if reelNode:getParent() ~= nil then
                    reelNode:removeFromParent()
                end
                reelNode:release()
            end

            if not tolua.isnull(reelAct) then
                reelAct:release()
            end
            self.m_reelRunAnimaBG[i] = nil
        end
    end

    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:unscheduleUpdate()
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
    end

    if self.m_respinNodeInfo ~= nil and #self.m_respinNodeInfo > 0 then
        for k = 1, #self.m_respinNodeInfo do
            local node = self.m_respinNodeInfo[k].node
            if not tolua.isnull(node) then
                node:removeFromParent()
            end
        end
    end
    self.m_respinNodeInfo = {}

    self:clearLayerChildReferenceCount()

end



function FarmMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function FarmMiniMachine:beginMiniReel()

    BaseMiniMachine.beginReel(self)

end


-- 消息返回更新数据
function FarmMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function FarmMiniMachine:enterLevel( )
    
end

function FarmMiniMachine:enterLevelMiniSelf( )

    BaseMiniMachine.enterLevel(self)
    
end



function FarmMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end


-- 轮盘停止回调(自己实现)
function FarmMiniMachine:setDownCallFunc(func )
    self.m_reelDownCallback = func
end

function FarmMiniMachine:playEffectNotifyNextSpinCall( )
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end



-- 处理特殊关卡 遮罩层级
function FarmMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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

-- 是不是 respinBonus小块
function FarmMiniMachine:isFixSymbol(symbolType)


    if symbolType == self.SYMBOL_FIX_BONUS_1 or 
        symbolType == self.SYMBOL_FIX_BONUS_2 or 
        symbolType == self.SYMBOL_FIX_BONUS_3 or 
        
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR  then
            return true
    end
    return false
end

---
--设置bonus scatter 层级
function FarmMiniMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

function FarmMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function FarmMiniMachine:checkGameResumeCallFun( )
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


function FarmMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FarmMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function FarmMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end


--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData: 
    @return:
]]
function FarmMiniMachine:getResNodeSymbolType( parentData )
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

    -- 根据玩法强制改变 某列为 wild
    if self:checkIsWildCol(colIndex ) then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    end

    return symbolType

end


function FarmMiniMachine:initRandomSlotNodes()
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()
end

function FarmMiniMachine:checkIsWildCol(colIndex )
    local isIn = false

    local selfdata = self.m_parent.m_runSpinResultData.p_selfMakeData or {}

    local m_wildCols = selfdata.wildReels or {}


    for i=1,#m_wildCols do
        local wildCol = m_wildCols[i] + 1
        if wildCol == colIndex then
            isIn = true

            return isIn
        end
    end

    return isIn
end

---
-- 从参考的假数据中获取数据
--
function FarmMiniMachine:getRandomReelType(colIndex,reelDatas)
    
    if reelDatas == nil or #reelDatas == 0 then
        return self:getNormalSymbol(colIndex)
    end
    local reelLen = #reelDatas
    while true do
        local symbolType = reelDatas[util_random(1,reelLen)]

        -- 根据玩法强制改变 某列为 wild
        if self:checkIsWildCol(colIndex ) then
            symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        end

        return symbolType
    end
    return nil
end


function FarmMiniMachine:lineLogicWinLines( )
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        
        self:compareScatterWinLines(winLines)

        for i=1,#winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo,iconsPos)
            
            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())
            
            if lineInfo.iLineSymbolNum >=5 then
                isFiveOfKind=true
            end

            local iconsPosNew = winLineData.p_iconPosNew -- 其他副轮盘
            if iconsPosNew and #iconsPosNew >= 5 then
                isFiveOfKind=true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end

    end

    return isFiveOfKind
end

function FarmMiniMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()
    
    local isFiveOfKind = self:lineLogicWinLines()
    
end

return FarmMiniMachine
