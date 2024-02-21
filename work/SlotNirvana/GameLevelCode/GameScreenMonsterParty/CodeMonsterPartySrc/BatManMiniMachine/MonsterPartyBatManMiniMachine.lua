---
-- xcyy
-- 2018-12-18 
-- MonsterPartyBatManMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local MonsterPartySlotFastNode = require "CodeMonsterPartySrc.MonsterPartySlotFastNode"


local MonsterPartyBatManMiniMachine = class("MonsterPartyBatManMiniMachine", BaseMiniMachine)


MonsterPartyBatManMiniMachine.m_runCsvData = nil
MonsterPartyBatManMiniMachine.m_machineIndex = nil -- csv 文件模块名字

MonsterPartyBatManMiniMachine.gameResumeFunc = nil
MonsterPartyBatManMiniMachine.gameRunPause = nil

MonsterPartyBatManMiniMachine.FS_LockWild_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

function MonsterPartyBatManMiniMachine:getBaseReelGridNode()
    return "CodeMonsterPartySrc.MonsterPartySlotFastNode"
end
-- 构造函数
function MonsterPartyBatManMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    
end

function MonsterPartyBatManMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_maxReelIndex = data.maxReelIndex 

    self.m_lockWildList = {}
    self.m_oldlockWildList = {}

    

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function MonsterPartyBatManMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MonsterPartyBatManMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MonsterParty"
end

function MonsterPartyBatManMiniMachine:getMachineConfigName()

    local str = "BatMini"

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MonsterPartyBatManMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType) 

    

    return ccbName
end

---
-- 读取配置文件数据
--
function MonsterPartyBatManMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelMonsterPartyConfig.lua")
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function MonsterPartyBatManMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("MonsterParty_FS_reel5x5.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end
--
---
--
function MonsterPartyBatManMiniMachine:initMachine()
    self.m_moduleName =  self:getModuleName()

    
    BaseMiniMachine.initMachine(self)
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function MonsterPartyBatManMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()
   
    
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function MonsterPartyBatManMiniMachine:addSelfEffect()


    if self.m_parent:checkIsAddFsWildLock( )then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FS_LockWild_EFFECT -- 动画类型
    end

end


function MonsterPartyBatManMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end



function MonsterPartyBatManMiniMachine:reelDownNotifyPlayGameEffect( )
    self:playGameEffect()



    if self.m_parent then
        self.m_parent:FSReelDownNotify( self.m_maxReelIndex  )
    end
end

function MonsterPartyBatManMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MonsterPartyBatManMiniMachine:checkNotifyUpdateWinCoin( )

    -- 这里作为freespin下 吸血鬼 连线时通知钱数更新的接口

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end 

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_parent.m_serverWinCoins,isNotifyUpdateTop})


end


function MonsterPartyBatManMiniMachine:getVecGetLineInfo( )
    return self.m_runSpinResultData.p_winLines
end

function MonsterPartyBatManMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_parent then
        self.m_parent:FSReelShowSpinNotify( self.m_maxReelIndex )
    end

end


function MonsterPartyBatManMiniMachine:quicklyStopReel(colIndex)

    


    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        
        local selfData = self.m_parent.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        if freeSpinType == self.m_parent.FS_GAME_TYPE_m_batMan then

            BaseMiniMachine.quicklyStopReel(self, colIndex) 

        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_wolfMan then
            
        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_ghostGirl then
            
        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_greenMan then
            
        end

        
    end

    
end

function MonsterPartyBatManMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function MonsterPartyBatManMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function MonsterPartyBatManMiniMachine:beginMiniReel()
    for k,wild in pairs(self.m_oldlockWildList) do
        wild:setVisible(true)
    end
    BaseMiniMachine.beginReel(self)

end


-- 消息返回更新数据
function MonsterPartyBatManMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function MonsterPartyBatManMiniMachine:enterLevel( )
    BaseMiniMachine.enterLevel(self)
end

function MonsterPartyBatManMiniMachine:enterLevelMiniSelf( )

    BaseMiniMachine.enterLevel(self)
    
end



function MonsterPartyBatManMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end



-- 处理特殊关卡 遮罩层级
function MonsterPartyBatManMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function MonsterPartyBatManMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parent:getBounsScatterDataZorder(symbolType ) 

end


function MonsterPartyBatManMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end



function MonsterPartyBatManMiniMachine:checkGameResumeCallFun( )
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


function MonsterPartyBatManMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MonsterPartyBatManMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function MonsterPartyBatManMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

---
-- 根据类型获取对应节点
--
function MonsterPartyBatManMiniMachine:getSlotNodeBySymbolType(symbolType)
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
    reelNode:setMachine(self )
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end


---
-- 清空掉产生的数据
--
function MonsterPartyBatManMiniMachine:clearSlotoData()
    
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

function MonsterPartyBatManMiniMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)

    self:clearFrames_Fun()


    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()

        self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
            -- self:clearFrames_Fun()
            if frameIndex > #winLines  then
                frameIndex = 1
                if self.m_showLineHandlerID ~= nil then

                    scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                    self.m_showLineHandlerID = nil
                    self:showAllFrame(winLines)
                    self:playInLineNodes()
                    showLienFrameByIndex()
                end
                return
            end
            self:playInLineNodesIdle()
            -- 跳过scatter bonus 触发的连线
            while true do
                if frameIndex > #winLines then
                    break
                end
                -- print("showLine ... ")
                local lineData = winLines[frameIndex]

                if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or
                   lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then

                    if #winLines == 1 then
                        break
                    end

                    frameIndex = frameIndex + 1
                    if frameIndex > #winLines  then
                        frameIndex = 1
                    end
                else
                    break
                end
            end
            -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
            -- 所以打上一个判断
            if frameIndex > #winLines  then
                frameIndex = 1
            end

            self:showLineFrameByIndex(winLines,frameIndex)

            frameIndex = frameIndex + 1
        end, self.m_changeLineFrameTime,self:getModuleName())

    end

    self:showAllFrame(winLines)
    if #winLines > 1 then
        showLienFrameByIndex()
    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function MonsterPartyBatManMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function MonsterPartyBatManMiniMachine:clearCurMusicBg( )
    
end


-- 初始化 锁定wild
function MonsterPartyBatManMiniMachine:initFsLockWild(wildPosList)

    if wildPosList and #wildPosList > 0 then

        for k, v in pairs(wildPosList) do
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp =  self:getReelParentChildNode(fixPos.iY, fixPos.iX) 

            if targSp then
                self:changeSymbolType(targSp,TAG_SYMBOL_TYPE.SYMBOL_WILD)

                local symbolName = self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                local lockNode = util_spineCreate(symbolName,true,true)
                lockNode.m_iconsPos = pos

                self.m_clipParent:addChild(lockNode,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_NODE_TAG)
                util_spinePlay(lockNode,"idleframe")
                lockNode:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
                lockNode:setPosition(cc.p(util_getOneGameReelsTarSpPos(self,pos )))
                table.insert( self.m_oldlockWildList,lockNode)
                
            end

            
        end
    end

end

function MonsterPartyBatManMiniMachine:restSelfGameEffects( restType  )

    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects , 1 do

            local effectData = self.m_gameEffects[i]
    
            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_selfEffectType

                if effectType == restType then

                    effectData.p_isPlay = true
                    self:playGameEffect()
                    return 
                end
                
            end

        end
    end
    
end

function MonsterPartyBatManMiniMachine:checkWildIsLocked( index )

    for i=1,#self.m_oldlockWildList do
        local wild = self.m_oldlockWildList[i]

        if wild then
            local iconsPos = wild.m_iconsPos

            if index == iconsPos then
                return true
            end
            
        end

    end

    return false
    
end


function MonsterPartyBatManMiniMachine:setWildList( wildPosList )

    self.m_lockWildList = {}
    for k, v in pairs(wildPosList) do
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local targSpIcons = self:getPosReelIdx(fixPos.iX, fixPos.iY)
        if not self:checkWildIsLocked( targSpIcons ) then
          
            local targSp = self:getReelParentChildNode(fixPos.iY,fixPos.iX) 
            if targSp then

                table.insert( self.m_lockWildList, targSp )

            end
            
        end
        

        
    end


end

function MonsterPartyBatManMiniMachine:removeAllReelsNode()

    self:stopAllActions()

    util_printLog("**********MonsterPartyBatManMiniMachine removeAllReelsNode 1",true)
    self:clearWinLineEffect()

    for i = #self.m_oldlockWildList, 1, -1 do
        local wild = self.m_oldlockWildList[i]
        wild:removeFromParent()
    end

    util_printLog("**********MonsterPartyBatManMiniMachine removeAllReelsNode 2",true)
    self.m_oldlockWildList = {}
    local childs = self.m_clipParent:getChildren()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            if targSp and targSp:getParent() then
                local randType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
                self:changeSymbolType(targSp,randType)
                
            end
        end
    end
    util_printLog("**********MonsterPartyBatManMiniMachine removeAllReelsNode 3",true)
end

function MonsterPartyBatManMiniMachine:clearLineAndFrame()
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME and not tolua.isnull(self.m_slotFrameLayer) then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        elseif not tolua.isnull(self.m_slotEffectLayer) then
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end
end

--补丁找不到在新滚动里面查找
function MonsterPartyBatManMiniMachine:getFixSymbol(iCol, iRow, iTag)
    if not iTag then
        iTag = SYMBOL_NODE_TAG
    end
    local fixSp = nil
    local clipParent = self.m_clipParent
    if not tolua.isnull(clipParent) then
        fixSp = clipParent:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
    end
    
    if fixSp == nil and (iCol >= 1 and iCol <= self.m_iReelColumnNum) then
        local slotParent = self.m_slotParents[iCol].slotParent
        if not tolua.isnull(slotParent) then
            fixSp = slotParent:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
        end
        
        if fixSp == nil then
            local slotParentBig = self.m_slotParents[iCol].slotParentBig
            if not tolua.isnull(slotParentBig) then
                fixSp = slotParentBig:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
            end
        end
    end
    if not fixSp then
        fixSp = self:getReelGridNode(iCol,iRow)
    end
    return fixSp
end


function MonsterPartyBatManMiniMachine:checkIsShowLockWild( wildPosList )
    if wildPosList and #wildPosList > 0 then

        for k, v in pairs(wildPosList) do
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSpIcons = self:getPosReelIdx(fixPos.iX, fixPos.iY)
            if not self:checkWildIsLocked( targSpIcons ) then
               return true
            end
            

            
        end
    end

    return false

end

-- 初始化 锁定wild
function MonsterPartyBatManMiniMachine:initShowlockWild(wildPosList)

    if wildPosList and #wildPosList > 0 then

        for k, v in pairs(wildPosList) do
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSpIcons = self:getPosReelIdx(fixPos.iX, fixPos.iY)
            if not self:checkWildIsLocked( targSpIcons ) then
                local targSp =  self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY, false)   
                if targSp then

                    local symbolName = self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    local lockNode = util_spineCreate(symbolName,true,true)
                    lockNode.m_iconsPos = pos

                    self.m_clipParent:addChild(lockNode,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_NODE_TAG)
                    lockNode:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
                    lockNode:setPosition(cc.p(util_getOneGameReelsTarSpPos(self,targSpIcons )))
                    table.insert( self.m_oldlockWildList,lockNode)

                    util_spinePlay(lockNode,"idleframe",true)
                end
            end
            

            
        end
    end

end




function MonsterPartyBatManMiniMachine:updateNetWorkData()

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


    -- 网络消息已经赋值成功开始进行飞蝙蝠变信号 , 等动画的判断逻辑

    self.m_parent:batManNetBackCheckAddAction( )
end


function MonsterPartyBatManMiniMachine:netBackReelsStop( )

    

    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end


function MonsterPartyBatManMiniMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                if child.p_slotNodeH == nil then -- 打个补丁
                    child.p_slotNodeH = self.m_SlotNodeH
                end
                topY = childY + child.p_slotNodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end

function MonsterPartyBatManMiniMachine:hidePaoAct( func )
    
    if self.m_paoAct == nil then
        
        return 
    end

    if #self.m_paoAct > 0 then
        gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_batman_Symbol_BATToWild.mp3")
    end

    for i=1,#self.m_paoAct do
        local paoAct = self.m_paoAct[i]
        if paoAct then
            paoAct:runCsbAction("animation0",false,function(  )
                paoAct:removeFromParent()
            end)
        end
        
    end


    

    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,4/30)
    

    self.m_paoAct = {}
end

function MonsterPartyBatManMiniMachine:CreatePaoAct( iRow, iCol , func)
    local reelIdx = self:getPosReelIdx(iRow, iCol)
    local createPos = util_getOneGameReelsTarSpPos(self,reelIdx )
    local paoAct = util_createAnimation("Socre_MonsterParty_xixuegui_smoke.csb") 
    self:findChild("Node_1"):addChild(paoAct,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER  + iRow)
    paoAct:setPosition(createPos)
    paoAct:runCsbAction("animation1",false,function(  )
        paoAct:runCsbAction("animation1",true)

        performWithDelay(self,function(  )
            if func then
                func()
            end
        end,1)
        

        -- paoAct:removeFromParent()
        
    end)

    return paoAct
end

function MonsterPartyBatManMiniMachine:createWildBat( wildLock, callFunc )
    

    self.m_paoAct = {}

    local addFunc = nil
    for k,v in pairs(wildLock) do
        local index = v 

        if not self:checkWildIsLocked( index ) then
            local func = nil
            if not addFunc  then
                addFunc = true
                func = function(  )
                    self:hidePaoAct( function(  )
                        
                        if callFunc then
                            callFunc()
                        end
                    end )
                end
            end
        
            local fixPos = self:getRowAndColByPos(index)

            local paoAct = self:CreatePaoAct( fixPos.iX, fixPos.iY,func )
            table.insert(self.m_paoAct,paoAct)
        end 

        


    end

end

---
-- 每个reel条滚动到底
function MonsterPartyBatManMiniMachine:slotOneReelDown(reelCol)
    for k,wild in pairs(self.m_oldlockWildList) do
        local iconPos = wild.m_iconsPos
        local fixPos = self:getRowAndColByPos(iconPos)
        local iCol,iRow = fixPos.iY, fixPos.iX
        if iCol == reelCol then
            local symbolNode = self:getFixSymbol(iCol,iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType then
                self:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD)
            end
        end
    end
    return MonsterPartyBatManMiniMachine.super.slotOneReelDown(self,reelCol)
end

function MonsterPartyBatManMiniMachine:slotReelDown()
    MonsterPartyBatManMiniMachine.super.slotReelDown(self)
    for k,wild in pairs(self.m_oldlockWildList) do
        wild:setVisible(false)
    end
end

return MonsterPartyBatManMiniMachine
