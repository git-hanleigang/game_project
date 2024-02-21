---
-- xcyy
-- 2018-12-18 
-- MonsterPartyGhostGirlMiniMachine.lua
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


local MonsterPartyGhostGirlMiniMachine = class("MonsterPartyGhostGirlMiniMachine", BaseMiniMachine)


MonsterPartyGhostGirlMiniMachine.m_runCsvData = nil
MonsterPartyGhostGirlMiniMachine.m_machineIndex = nil -- csv 文件模块名字

MonsterPartyGhostGirlMiniMachine.gameResumeFunc = nil
MonsterPartyGhostGirlMiniMachine.gameRunPause = nil

MonsterPartyGhostGirlMiniMachine.FS_LockWild_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
function MonsterPartyGhostGirlMiniMachine:getBaseReelGridNode()
    return "CodeMonsterPartySrc.MonsterPartySlotFastNode"
end
-- 构造函数
function MonsterPartyGhostGirlMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    
end

function MonsterPartyGhostGirlMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_maxReelIndex = data.maxReelIndex 

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function MonsterPartyGhostGirlMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MonsterPartyGhostGirlMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MonsterParty"
end

function MonsterPartyGhostGirlMiniMachine:getMachineConfigName()

    local str = "GhostMini"

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MonsterPartyGhostGirlMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType) 

    

    return ccbName
end

---
-- 读取配置文件数据
--
function MonsterPartyGhostGirlMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelMonsterPartyConfig.lua")
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function MonsterPartyGhostGirlMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("MonsterParty_FS_reel3x5.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function MonsterPartyGhostGirlMiniMachine:initMachine()
    self.m_moduleName =  self:getModuleName()


    BaseMiniMachine.initMachine(self)
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function MonsterPartyGhostGirlMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()
   
    
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function MonsterPartyGhostGirlMiniMachine:addSelfEffect()




end


function MonsterPartyGhostGirlMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end



function MonsterPartyGhostGirlMiniMachine:reelDownNotifyPlayGameEffect( )
    self:playGameEffect()

    if self.m_parent then
        self.m_parent:FSReelDownNotify( self.m_maxReelIndex  )
    end
end

function MonsterPartyGhostGirlMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MonsterPartyGhostGirlMiniMachine:slotReelDown()
    
    local isHide =  self:hidePaoAct( )

    
    local waitTimes = 0
    if isHide then
        waitTimes = 20 /30
    end
    
    
    performWithDelay(self,function(  )

        BaseMiniMachine.slotReelDown(self) 

    end,waitTimes)
    
    
    
end


---
-- 每个reel条滚动到底
function MonsterPartyGhostGirlMiniMachine:slotOneReelDown(reelCol)
    BaseMiniMachine.slotOneReelDown(self,reelCol)

    if self.m_machineIndex == 1 then
        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_JP_ReelStop.mp3")
    end

end

function MonsterPartyGhostGirlMiniMachine:getVecGetLineInfo( )
    return self.m_runSpinResultData.p_winLines
end


function MonsterPartyGhostGirlMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_parent then
        self.m_parent:FSReelShowSpinNotify( self.m_maxReelIndex )
    end

end

function MonsterPartyGhostGirlMiniMachine:quicklyStopReel(colIndex)

    
    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then

        local selfData = self.m_parent.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        if freeSpinType == self.m_parent.FS_GAME_TYPE_m_batMan then

            

        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_wolfMan then
            
        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_ghostGirl then
            BaseMiniMachine.quicklyStopReel(self, colIndex) 
        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_greenMan then
            
        end

        
    end

    
end

function MonsterPartyGhostGirlMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function MonsterPartyGhostGirlMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function MonsterPartyGhostGirlMiniMachine:beginMiniReel()

    BaseMiniMachine.beginReel(self)

end


-- 消息返回更新数据
function MonsterPartyGhostGirlMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function MonsterPartyGhostGirlMiniMachine:enterLevel( )
    BaseMiniMachine.enterLevel(self)
end

function MonsterPartyGhostGirlMiniMachine:enterLevelMiniSelf( )

    BaseMiniMachine.enterLevel(self)
    
end



function MonsterPartyGhostGirlMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end



-- 处理特殊关卡 遮罩层级
function MonsterPartyGhostGirlMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function MonsterPartyGhostGirlMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parent:getBounsScatterDataZorder(symbolType ) 

end


function MonsterPartyGhostGirlMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function MonsterPartyGhostGirlMiniMachine:checkGameResumeCallFun( )
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


function MonsterPartyGhostGirlMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MonsterPartyGhostGirlMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function MonsterPartyGhostGirlMiniMachine:resumeMachine()
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
function MonsterPartyGhostGirlMiniMachine:getSlotNodeBySymbolType(symbolType)
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
function MonsterPartyGhostGirlMiniMachine:clearSlotoData()
    
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

function MonsterPartyGhostGirlMiniMachine:restSelfGameEffects( restType  )

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

function MonsterPartyGhostGirlMiniMachine:showLineFrame()
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
function MonsterPartyGhostGirlMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function MonsterPartyGhostGirlMiniMachine:clearCurMusicBg( )
    
end

function MonsterPartyGhostGirlMiniMachine:removeAllReelsNode()

    self:stopAllActions()
    self:clearWinLineEffect()

    local childs = self.m_clipParent:getChildren()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            if targSp and targSp:getParent() then
                targSp:removeFromParent(false)
                targSp:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType,targSp)
            end
        end
    end

    self:randomSlotNodes( )
    
end



function MonsterPartyGhostGirlMiniMachine:updateNetWorkData()

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

    self.m_parent:ghostGirlNetBackCheckAddAction( self.m_maxReelIndex )
end


function MonsterPartyGhostGirlMiniMachine:netBackReelsStop( )

    

    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end

function MonsterPartyGhostGirlMiniMachine:CreatePaoActFromNetData( mysteryColumns , callback )

    
    
    gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_GhostGirl_Showpao.mp3")

    self.m_paoAct = {}

    local index = 0 
    for k,v in pairs(mysteryColumns) do
        local iCol = v + 1

        for iRow = self.m_iReelRowNum, 1, -1 do
            index = index + 1
            local func = nil
            if index == 1 then
                func = function(  )
                    if callback then
                        callback()
                    end
                end
            end
            
            local paoAct = self:CreatePaoAct( iRow, iCol )
            table.insert(self.m_paoAct,paoAct)
        end

    end
end

function MonsterPartyGhostGirlMiniMachine:hidePaoAct( )
    
    local isHide = false

    if self.m_paoAct == nil then
        
        return 
    end

    for i=1,#self.m_paoAct do
        local paoAct = self.m_paoAct[i]
        if paoAct then
            isHide = true
            paoAct:runCsbAction("over",false,function(  )
                paoAct:removeFromParent()
            end)
        end
        
    end

    self.m_paoAct = {}


    return isHide
end

function MonsterPartyGhostGirlMiniMachine:CreatePaoAct( iRow, iCol , func)
    local reelIdx = self:getPosReelIdx(iRow, iCol)
    local createPos = util_getOneGameReelsTarSpPos(self,reelIdx )
    local paoAct = util_createAnimation("Socre_MonsterParty_jiangshixinniang.csb") 
    self:findChild("Node_1"):addChild(paoAct,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + iRow)
    paoAct:setPosition(createPos)
    paoAct:runCsbAction("start",false,function(  )

        paoAct:runCsbAction("idle",true)

        if func then
            func()
        end

        
    end)

    return paoAct
end

function MonsterPartyGhostGirlMiniMachine:getSlotNodeChildsTopY(colIndex)
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



return MonsterPartyGhostGirlMiniMachine
