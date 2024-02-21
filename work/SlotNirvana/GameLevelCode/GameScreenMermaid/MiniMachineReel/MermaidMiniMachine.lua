---
-- xcyy
-- 2018-12-18 
-- MermaidMiniMachine.lua
--
--

local BaseMiniFastMachine = require "Levels.BaseMiniFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local MermaidSlotFastNode = require "CodeMermaidSrc.MermaidSlotFastNode"


local MermaidMiniMachine = class("MermaidMiniMachine", BaseMiniFastMachine)


MermaidMiniMachine.m_machineIndex = nil -- csv 文件模块名字

MermaidMiniMachine.gameResumeFunc = nil
MermaidMiniMachine.gameRunPause = nil

-- 构造函数
function MermaidMiniMachine:ctor()
    BaseMiniFastMachine.ctor(self)

    
end

function MermaidMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    self.m_LocalData_p_winLines = {}

    --init
    self:initGame()
end

function MermaidMiniMachine:initGame()


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MermaidMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Mermaid"
end

function MermaidMiniMachine:getMachineConfigName()

    local str = "Mini"

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MermaidMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)


    return ccbName
end

---
-- 读取配置文件数据
--
function MermaidMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelMermaidMiniReelConfig.lua")
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

--[[
    @desc: 读取轮盘配置信息
    time:2020-07-11 18:55:11
]]
function MermaidMiniMachine:readReelConfigData()
    --轮盘
    self.m_ScatterShowCol = self.m_configData.p_scatterShowCol --标识哪一列会出现scatter 
    self.m_validLineSymNum = self.m_configData.p_validLineSymNum --触发sf，bonus需要的数量
    self:setReelEffect(self.m_configData.p_reelEffectRes)--配置快滚效果资源名称
    self.m_changeLineFrameTime = self.m_configData.p_changeLineFrameTime --连线框播放时间
end

function MermaidMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("Mermaid_reel_lunpan.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function MermaidMiniMachine:initMachine()
    self.m_moduleName = "Mermaid" -- self:getModuleName()

    BaseMiniFastMachine.initMachine(self)
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function MermaidMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniFastMachine:getPreLoadSlotNodes()
    -- loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_SYMBOL, count = 3}



    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function MermaidMiniMachine:addSelfEffect()

    local lines = self.m_parent.m_LocalData_p_winLines or {}
    local fslines = self.m_parent.m_FsMiniReel.m_LocalData_p_winLines or {}


    if self.m_parent:checkAddFsLightCoins( fslines ) then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.m_parent.Fs_Light_AddCoins_Top_EFFECT -- 动画类型
    end

    if self.m_parent:checkAddFsLightCoins( lines ) then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.m_parent.Fs_Light_AddCoins_Down_EFFECT -- 动画类型
    end

    if self.m_parent.m_FsMiniReel:checkAddFsTimes( ) then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.m_parent.Fs_AddTimes_Top_EFFECT -- 动画类型
    end

    if self.m_parent:checkAddFsTimes( ) then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.m_parent.Fs_AddTimes_Down_EFFECT -- 动画类型
    end

end


function MermaidMiniMachine:beginFsJpCollectAction( )
    
    local baseJp = {}

    for iRow = self.m_iReelRowNum,1,-1  do
        local fixSymbol = self:getFixSymbol(1, iRow, SYMBOL_NODE_TAG)
        if fixSymbol and self.m_parent:isFixSymbol(fixSymbol.p_symbolType ) then
            table.insert(baseJp,fixSymbol)
        end
    end
    
    local bigSymbol = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)
    if bigSymbol and self.m_parent:isBigFixSymbol( bigSymbol.p_symbolType ) then
        table.insert(baseJp,bigSymbol)
    end

    for iRow = self.m_iReelRowNum,1,-1  do
        local fixSymbol = self:getFixSymbol(5, iRow, SYMBOL_NODE_TAG)
        if fixSymbol and self.m_parent:isFixSymbol(fixSymbol.p_symbolType ) then
            table.insert(baseJp,fixSymbol)
        end
    end

    return baseJp

end


function MermaidMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end


function MermaidMiniMachine:onEnter()
    BaseMiniFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MermaidMiniMachine:checkNotifyUpdateWinCoin( )


    local lines = self.m_parent.m_runSpinResultData.p_winLines

    if #lines > 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end 


    local coins  =  self.m_parent.m_actLastWinCoins
     local currCoins = self.m_parent.m_iOnceSpinLastWin
     local serverCoins = self.m_parent.m_serverWinCoins
     if self.m_parent:getCurrSpinMode() ~= FREE_SPIN_MODE  then
        coins  = nil
     end
     if coins  then
        currCoins = globalData.slotRunData.lastWinCoin - coins 
     end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{currCoins,isNotifyUpdateTop})
    
    


end

function MermaidMiniMachine:slotReelDown()
    BaseMiniFastMachine.slotReelDown(self) 
    self.m_parent:setDownTimes( 1 )
end


---
-- 每个reel条滚动到底
function MermaidMiniMachine:slotOneReelDown(reelCol)
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


    -- if  self:getGameSpinStage() ~= QUICK_RUN  then
    -- gLobalSoundManager:playSound(self.m_reelDownSound)
    -- end

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

end

function MermaidMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end

function MermaidMiniMachine:quicklyStopReel()

    
    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        BaseMiniFastMachine.quicklyStopReel(self)
    end
    
end

function MermaidMiniMachine:onExit()
    BaseMiniFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function MermaidMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function MermaidMiniMachine:addJumoActionAfterReel(slotParent,slotParentBig,colIndex )

    local icol = colIndex

    --添加一个回弹效果
        local action0 =
        cc.JumpTo:create(
        self.m_configData.p_reelBeginJumpTime,
        cc.p(slotParent:getPositionX(), slotParent:getPositionY()),
        self.m_configData.p_reelBeginJumpHight,
        1
    )

    local sequece =
        cc.Sequence:create(
        {
            action0,
            cc.CallFunc:create(
                function()
                    self:registerReelSchedule()

                    if icol == 2 or icol == 4 then
                        self.m_slotParents[icol].isReeling = false
                        self.m_slotParents[icol].isResActionDone = true
                    end
                end
            )
        }
    )

    slotParent:runAction(sequece)
    if slotParentBig then
        slotParentBig:runAction(action0:clone())
    end
end



function MermaidMiniMachine:beginReel()
    self:resetReelDataAfterReel()
    local slotsParents = self.m_slotParents
    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        
        local reelDatas = self:checkUpdateReelDatas(parentData)
        
        self:checkReelIndexReason(parentData)
        self:resetParentDataReel(parentData)
        
        self:createSlotNextNode(parentData)
        if self.m_configData.p_reelBeginJumpTime > 0 then
            self:addJumoActionAfterReel(slotParent,slotParentBig,i)
        else
            self:registerReelSchedule()

            if i == 2 or i == 4 then
                self.m_slotParents[i].isReeling = false
                self.m_slotParents[i].isResActionDone = true
            end
        end
       --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
       self:foreachSlotParent(
            i,
            function(index, realIndex, child)
                if child.__cname ~= nil and child.__cname == "SlotsNode" then
                    child:resetReelStatus()
                end
                if child.p_layerTag ~= nil and child.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE then
                    --将该节点放在 .m_clipParent
                    child:removeFromParent()
                    local posWorld = slotParent:convertToWorldSpace(cc.p(child:getPositionX(), child:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    child:setPosition(cc.p(pos.x, pos.y))
                    self.m_clipParent:addChild(child, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + child.m_showOrder)
                end
            end
        )
    end
    -- 处理特殊信号
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if child.__cname ~= nil and child.__cname == "SlotsNode" then
            child:resetReelStatus()
        end
        if child.p_layerTag ~= nil and child.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            --将该节点放在 .m_clipParent
            local showOrder = child.m_showOrder or self:getBounsScatterDataZorder(child.p_symbolType)
            local colIndex = child.p_cloumnIndex
            local childSlotParent = slotsParents[colIndex].slotParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(child:getPositionX(), child:getPositionY()))
            local pos = childSlotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            child:removeFromParent()
            child:resetReelStatus()
            child:setPosition(cc.p(pos.x, pos.y))
            local slotParentBig = slotsParents[colIndex].slotParentBig
            if slotParentBig and  self.m_configData:checkSpecialSymbol(child.p_symbolType) then
                slotParentBig:addChild(child,showOrder - child.p_rowIndex)
            else
                childSlotParent:addChild(child,showOrder - child.p_rowIndex)
            end
        end
    end
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end


-- 本地保存一份赢钱线
function MermaidMiniMachine:parseLocalWinLines( data )

    self.m_LocalData_p_winLines = {}

    if data.lines ~= nil then
        for i = 1, #data.lines do
            local lineData = data.lines[i]
            
                local winLineData = {} 
                winLineData.p_id = lineData.id
                winLineData.p_amount = lineData.amount
                winLineData.p_iconPos = lineData.icons
                winLineData.p_type = lineData.type
                winLineData.p_multiple = lineData.multiple
                self.m_LocalData_p_winLines[#self.m_LocalData_p_winLines + 1] = winLineData


        end
    end
end


function MermaidMiniMachine:removeFsJpPosIndex( result )


    if result.lines ~= nil then

        for i = #result.lines , 1 , -1 do
            local lineData = result.lines[i]

            if self.m_parent:isFixSymbol(lineData.type) or self.m_parent:isBigFixSymbol(lineData.type) then
                table.remove(result.lines,i)
            end
        end

    end

    
end
-- 消息返回更新数据
function MermaidMiniMachine:netWorkCallFun(spinResult)



    self:parseLocalWinLines( spinResult )
    self:removeFsJpPosIndex( spinResult )


    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function MermaidMiniMachine:enterLevel( )

    self.m_hasBigSymbol = true
    self.m_bCreateResNode = false
    
    self:changeReelDataBySpinMode( 1 )

    BaseMiniFastMachine.enterLevel(self)

    
end

function MermaidMiniMachine:dealSmallReelsSpinStates( )
   
end



-- 处理特殊关卡 遮罩层级
function MermaidMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function MermaidMiniMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = self.m_parent:getBounsScatterDataZorder(symbolType)

    return order

end

function MermaidMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function MermaidMiniMachine:checkGameResumeCallFun( )
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


function MermaidMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MermaidMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function MermaidMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

--小块
function MermaidMiniMachine:getBaseReelGridNode()
    return "CodeMermaidSrc.MermaidSlotFastNode"
end

---
-- 清空掉产生的数据
--
function MermaidMiniMachine:clearSlotoData()
    
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
function MermaidMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function MermaidMiniMachine:clearCurMusicBg( )
    
end



-- 根据网络数据获得respinBonus小块的分数
function MermaidMiniMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    if storedIcons == nil then
        return 0
    end

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end

    if idNode and idNode == -1 then
        return score
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType == self.m_parent.SYMBOL_SMALL_FIX_MINI then
        score = "MINI"
    elseif symbolType == self.m_parent.SYMBOL_SMALL_FIX_MINOR  then
        score = "MINOR"
    elseif symbolType == self.m_parent.SYMBOL_SMALL_FIX_MAJOR  then
        score = "MAJOR"
    elseif symbolType == self.m_parent.SYMBOL_SMALL_FIX_GRAND  then
        score = "GRAND"
    end

    return score
end

function MermaidMiniMachine:randomDownRespinSymbolScore(symbolType,iCol)
    local score = 1
    
    if symbolType == self.m_parent.SYMBOL_SMALL_FIX_BONUS then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        if  iCol then
            
            if iCol == 1 or iCol == 5 then
                score = self.m_configData:getFS_15_FixSymbolPro()
            else
                score = self.m_configData:getFS_234_FixSymbolPro()
                
            end

        else
            score = self.m_configData:getFixSymbolPro()
        end
    elseif symbolType == self.m_parent.SYMBOL_BIG_FIX_BONUS then

        score = self.m_configData:getFS_234_FixSymbolPro()
        
    end


    return score
end

-- 给respin小块进行赋值
function MermaidMiniMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.m_parent.SYMBOL_SMALL_FIX_BONUS then
        return
    end

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

            local labRed = symbolNode:getCcbProperty("m_lb_score_0")
            local labBlue = symbolNode:getCcbProperty("m_lb_score")
            if labBlue then
                labBlue:setVisible(false)    
            end

            if labRed then
                labRed:setVisible(false)   
            end
            
            if score >= self.m_parent.m_respinCollectBet then
                
                if labRed then
                    labRed:setVisible(true)   
                end

            else
                if labBlue then
                    labBlue:setVisible(true)    
                end
            end

            
            score = score * lineBet
            score = util_formatCoins(score, 3)

            if labRed then
                labRed:setString(score)
            end

            if labBlue then
                labBlue:setString(score)
            end

        end

        

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType,symbolNode.p_cloumnIndex) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil   then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                local labRed = symbolNode:getCcbProperty("m_lb_score_0")
                local labBlue = symbolNode:getCcbProperty("m_lb_score")
                if labBlue then
                    labBlue:setVisible(false)    
                end

                if labRed then
                    labRed:setVisible(false)   
                end
                
                if score >= self.m_parent.m_respinCollectBet then
                    
                    if labRed then
                        labRed:setVisible(true)   
                    end

                else
                    if labBlue then
                        labBlue:setVisible(true)    
                    end
                end

                
                score = score * lineBet
                score = util_formatCoins(score, 3)

                if labRed then
                    labRed:setString(score)
                end

                if labBlue then
                    labBlue:setString(score)
                end
                
            end
        end
        
        
    end

end


function MermaidMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniFastMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if symbolType == self.m_parent.SYMBOL_SMALL_FIX_BONUS then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end

    if symbolType == self.m_parent.SYMBOL_BIG_FIX_BONUS then
        -- 给respinBonus 大块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setBigSpecialNodeScore),{node})
        self:runAction(callFun)
    end


    if self.m_parent:isBigNormalSymbol( symbolType ) then
        -- 给respinBonus 大块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setBigNormalNodeData),{node})
        self:runAction(callFun)
    end
    


    return node
end

function MermaidMiniMachine:setBigNormalNodeData(sender,param  )
    
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType  then
        return
    end


    if symbolNode.m_isLastSymbol and symbolNode.m_isLastSymbol == true then
        symbolNode.m_bInLine = true
        local linePos = {}
    
        for colIndex = 2, 4 do
            for rowIndex = 1, self.m_iReelRowNum do
                linePos[#linePos + 1] = {iX = rowIndex, iY = colIndex}
            end
        end
        symbolNode:setLinePos(linePos)
    end
            
end

function MermaidMiniMachine:setBigSpecialNodeScore(sender,param )
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.m_parent.SYMBOL_BIG_FIX_BONUS then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore( -1 ) --获取分数（网络数据）-1 代表的是大信号
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()

            local labRed = symbolNode:getCcbProperty("m_lb_score_0")
            local labBlue = symbolNode:getCcbProperty("m_lb_score")
            if labBlue then
                labBlue:setVisible(false)    
            end

            if labRed then
                labRed:setVisible(false)   
            end
            
            if score >= self.m_parent.m_respinCollectBet and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE  then
                
                if labRed then
                    labRed:setVisible(true)   
                end

            else
                if labBlue then
                    labBlue:setVisible(true)    
                end
            end

            
            score = score * lineBet
            score = util_formatCoins(score, 3)

            if labRed then
                labRed:setString(score)
            end

            if labBlue then
                labBlue:setString(score)
            end

        end

        

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType,symbolNode.p_cloumnIndex) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil   then
                local lineBet = globalData.slotRunData:getCurTotalBet()

                local labRed = symbolNode:getCcbProperty("m_lb_score_0")
                local labBlue = symbolNode:getCcbProperty("m_lb_score")
                if labBlue then
                    labBlue:setVisible(false)    
                end

                if labRed then
                    labRed:setVisible(false)   
                end
                
                if score >= self.m_parent.m_respinCollectBet and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE  then
                    
                    if labRed then
                        labRed:setVisible(true)   
                    end

                else
                    if labBlue then
                        labBlue:setVisible(true)    
                    end
                end

                
                score = score * lineBet
                score = util_formatCoins(score, 3)

                if labRed then
                    labRed:setString(score)
                end

                if labBlue then
                    labBlue:setString(score)
                end
            end
        end
        
        
    end
    
end



function MermaidMiniMachine:changeReelDataBySpinMode( spinModeType )
    if spinModeType == 1 then
        local columnData = self.m_reelColDatas[3]
        columnData:updateShowColCount(1)

        columnData = self.m_reelColDatas[2]
        columnData:updateShowColCount(0)

        columnData = self.m_reelColDatas[4]
        columnData:updateShowColCount(0)

        -- 将第三列设置为行的整倍数，因为每行都是一个占满行的大信号
        local runData= {self.m_configData.p_reelRunDatas[1],self.m_configData.p_reelRunDatas[2],
                            self.m_configData.p_reelRunDatas[3] / self.m_iReelRowNum ,self.m_configData.p_reelRunDatas[4],
                                self.m_configData.p_reelRunDatas[5]}
        self:slotsReelRunData(runData,self.m_configData.p_bInclScatter
            ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
                ,self.m_configData.p_bPlayBonusAction)
    elseif spinModeType == 2 then
        local columnData = self.m_reelColDatas[3]
        columnData:updateShowColCount(self.m_iReelRowNum)

        columnData = self.m_reelColDatas[2]
        columnData:updateShowColCount(self.m_iReelRowNum)

        columnData = self.m_reelColDatas[4]
        columnData:updateShowColCount(self.m_iReelRowNum)

        self:slotsReelRunData(self.m_configData.p_reelRunDatas,self.m_configData.p_bInclScatter
            ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
                ,self.m_configData.p_bPlayBonusAction)
    end
end


---
-- 轮盘停止时调用
-- 改变轮盘滚动后的数据等
function MermaidMiniMachine:MachineRule_stopReelChangeData()

    self.m_bCreateResNode = false
end

function MermaidMiniMachine:randomSlotNodes()
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            while true do
                if symbolType ~= self.m_parent.SYMBOL_BIG_SCATTER then
                    break
                end
                symbolType = self:getRandomReelType(colIndex,reelDatas)
            end

            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex,symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                -- 添加到显示列表
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = showOrder

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
end

function MermaidMiniMachine:randomSlotNodesByReel()
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        

        for rowIndex = 1, rowCount do --  只改了这一行
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

            while true do
                if symbolType ~= self.m_parent.SYMBOL_BIG_SCATTER then
                    break
                end
                symbolType = self:getRandomReelType(colIndex,reelDatas)
            end

            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getCacheNode(colIndex,symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
end


function MermaidMiniMachine:showAllFrame(winLines)

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then

            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then

            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            -- end

        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s","")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i=1,frameNum do

            local symPosData = lineValue.vecValidMatrixSymPos[i]


            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then

                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen( )

                local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5

                local showGridH = columnData.p_showGridH 

                showGridH = self.m_reelColDatas[1].p_showGridH 
                
                local posY = showGridH * symPosData.iX - showGridH * 0.5 + columnData.p_slotColumnPosY

                local node = self:getFrameWithPool(lineValue,symPosData)
                node:setPosition(cc.p(posX,posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

            end

        end
    end

end

function MermaidMiniMachine:showLineFrameByIndex(winLines,frameIndex)

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s","")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then

            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then

            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end

        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i=1,frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
        local showGridH = columnData.p_showGridH 
        
        showGridH = self.m_reelColDatas[1].p_showGridH 
        
        local posY = showGridH * symPosData.iX - showGridH * 0.5 + columnData.p_slotColumnPosY
        
        local node = nil
        if i <=  hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue,symPosData)
        end
        node:setPosition(cc.p(posX,posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
               self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe",true)
        else
            node:runAnim("actionframe",true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end

    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function MermaidMiniMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

    for iCol = 1, self.m_iReelColumnNum do


        local isPlay = true

        --某列数据
        local lastColumnSymbol = self.m_reelSlotsList[iCol]
        --某列最后一组数据 应该只有一组数据
        for k, reels in pairs(lastColumnSymbol) do

            if self.m_parent:isBigFixSymbol( reels.p_symbolType ) or self.m_parent:isFixSymbol( reels.p_symbolType ) then
                
                
                reels.m_reelDownAnima = "buling"
                
                if isPlay then
                    isPlay = false
                    
                    if self.m_parent:checkReelSymbolType(iCol, reels.p_symbolType ) then
                        if reels.p_symbolType == self.m_parent.SYMBOL_SMALL_FIX_BONUS or reels.p_symbolType == self.m_parent.SYMBOL_BIG_FIX_BONUS then
                   
                            reels.m_reelDownAnimaSound = "MermaidSounds/music_Mermaid_FixBonus_down.mp3" 
                        
                        else
                            
                            reels.m_reelDownAnimaSound = "MermaidSounds/music_Mermaid_JpBonus_down.mp3" 
                        
                        end
                    end

                    if self.m_parent:checkReelHaveBigScatter(iCol ) then
                        reels.m_reelDownAnimaSound = nil
                    end
                    

                end
                
            elseif reels.p_symbolType == self.m_parent.SYMBOL_BIG_SCATTER then

                reels.m_reelDownAnima = "buling"

                if self.m_parent:checkReelSymbolType(iCol, reels.p_symbolType ) then
                    reels.m_reelDownAnimaSound = "MermaidSounds/music_Mermaid_Big_Scatter_Down.mp3"  
                end

            end


        end

    end
    
end

function MermaidMiniMachine:getClipWidthRatio(colIndex)
    if colIndex == 3 then
        return 1.5
    else
        return self.m_clipWidtRatio or 1
    end
end


function MermaidMiniMachine:playEffectNotifyChangeSpinStatus( )


    self.m_parent:setNormalAllRunDown(1 )

end

function MermaidMiniMachine:checkAddFsTimes( )
    
    local bigSymbol = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)

    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then


        if bigSymbol and bigSymbol.p_symbolType ==  self.m_parent.SYMBOL_BIG_SCATTER then
            return bigSymbol
        end
        

    end

    return nil
end

function MermaidMiniMachine:getJackpotScoreFromNet( netPos )
    local lines = self.m_LocalData_p_winLines or {} 
    local coins = 0
    for i=1,#lines do
        local lineInfo = lines[i]

        if netPos == - 1 then
            if lineInfo.p_iconPos and #lineInfo.p_iconPos == 0  then
                if lineInfo.p_amount then
                    coins = lineInfo.p_amount
                end
            end 
            
        else
            if lineInfo.p_iconPos and #lineInfo.p_iconPos == 1  then
                if lineInfo.p_iconPos[1] == netPos then
                    coins = lineInfo.p_amount
                end
            end 
        end
        
    end

    return coins
end


function MermaidMiniMachine:changeReelSymbolNode(  )
    


    local bigSymbol = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)
    if bigSymbol then

        if bigSymbol.p_symbolType == self.m_parent.SYMBOL_SMALL_FIX_GRAND then
            local changeType = self.m_parent:getOneBigSymbol( )
            bigSymbol:changeCCBByName(self.m_parent:MachineRule_GetSelfCCBName(changeType),changeType)
        end
       
    end



end

function MermaidMiniMachine:checkReelHaveBigScatter(CurrICol )
    

    for iRow = 1, self.m_iReelRowNum do

        local nodeType = self.m_stcValidSymbolMatrix[iRow][CurrICol] 
        if nodeType and nodeType == self.m_parent.SYMBOL_BIG_SCATTER then
            return true
        end
    end


    return false
end

function MermaidMiniMachine:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)

    local childs = slotParent:getChildren()
    if slotParentBig then
        local newChilds = slotParentBig:getChildren()
        for i=1,#newChilds do
            childs[#childs+1]=newChilds[i]
        end
    end

    for childIndex = 1, #childs do

        local child = childs[childIndex]
        self:moveDownCallFun(child, parentData.cloumnIndex)
    end

    local index = 1

    while index <= columnData.p_showGridCount do -- 只改了这 为了适应freespin
        self:createSlotNextNode(parentData)
        local symbolType = parentData.symbolType
        local node = self:getCacheNode(parentData.cloumnIndex, symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
            local slotParentBig = parentData.slotParentBig
            -- 添加到显示列表
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, parentData.order, parentData.tag)
            else
                slotParent:addChild(node, parentData.order, parentData.tag)
            end
        else
            local tmpSymbolType = self:convertSymbolType(symbolType)
            node:setVisible(true)
            node:setLocalZOrder(parentData.order)
            node:setTag(parentData.tag)
            local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
            node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
        end
        
        local posY = columnData.p_showGridH * (parentData.rowIndex - 0.5) - parentPosY

        node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

        node.p_cloumnIndex = parentData.cloumnIndex
        node.p_rowIndex = parentData.rowIndex
        node.m_isLastSymbol = parentData.m_isLastSymbol

        node.p_slotNodeH = columnData.p_showGridH
        node.p_symbolType = parentData.symbolType
        node.p_preSymbolType = parentData.preSymbolType
        node.p_showOrder = parentData.order

        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
        node.p_layerTag = parentData.layerTag
        node:setTag(parentData.tag)
        node:setLocalZOrder(parentData.order)

        node:runIdleAnim()
        -- node:setVisible(false)
        if parentData.isLastNode == true then -- 本列最后一个节点移动结束
            -- 执行回弹, 如果不执行回弹判断是否执行
            parentData.isReeling = false
            -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
            -- 创建一个假的小块 在回滚停止后移除

            self:createResNode(parentData, node)
        end

        if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
            local addCount = self.m_bigSymbolInfos[parentData.symbolType]
            index = addCount + node.p_rowIndex
        else
            index = index + 1
        end
    end


end

return MermaidMiniMachine
