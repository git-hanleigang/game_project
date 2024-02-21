---
-- xcyy
-- 2018-12-18 
-- MonsterPartyWolfManMiniMachine.lua
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


local MonsterPartyWolfManMiniMachine = class("MonsterPartyWolfManMiniMachine", BaseMiniMachine)


MonsterPartyWolfManMiniMachine.m_machineIndex = nil -- csv 文件模块名字

MonsterPartyWolfManMiniMachine.gameResumeFunc = nil
MonsterPartyWolfManMiniMachine.gameRunPause = nil

MonsterPartyWolfManMiniMachine.m_FixBonusLayer = nil
MonsterPartyWolfManMiniMachine.m_FixBonusKuang  = {}

MonsterPartyWolfManMiniMachine.FS_Collect_Wild_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
function MonsterPartyWolfManMiniMachine:getBaseReelGridNode()
    return "CodeMonsterPartySrc.MonsterPartySlotFastNode"
end
-- 构造函数
function MonsterPartyWolfManMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    
end

function MonsterPartyWolfManMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_maxReelIndex = data.maxReelIndex 

    self.m_FixBonusLayer = nil
    self.m_FixBonusKuang  = {}

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function MonsterPartyWolfManMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MonsterPartyWolfManMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MonsterParty"
end

function MonsterPartyWolfManMiniMachine:getMachineConfigName()

    local str = "WolfMini"

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MonsterPartyWolfManMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType) 

    

    return ccbName
end


---
-- 读取配置文件数据
--
function MonsterPartyWolfManMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelMonsterPartyConfig.lua")
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function MonsterPartyWolfManMiniMachine:initMachineCSB( )
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
function MonsterPartyWolfManMiniMachine:initMachine()
    self.m_moduleName =  self:getModuleName()

    
    BaseMiniMachine.initMachine(self)

    self:initSelfUI()
end

function MonsterPartyWolfManMiniMachine:initSelfUI( )
    
    self.m_FixBonusLayer = cc.Node:create()
    self:findChild("root"):addChild(self.m_FixBonusLayer,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)
    

end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function MonsterPartyWolfManMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()
   
    
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function MonsterPartyWolfManMiniMachine:addSelfEffect()


    local selfdata = self.m_parent.m_runSpinResultData.p_selfMakeData or {}
    local wildCollect = selfdata.wildCollect
    local freeSpinLeftTimes = self.m_parent.m_runSpinResultData.p_freeSpinsLeftCount or 0

    if self.m_parent.m_Reels_wolfMan:checkIsShowCollectKuang( wildCollect ) and freeSpinLeftTimes > 0 then
        
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FS_Collect_Wild_EFFECT -- 动画类型

    end

end


function MonsterPartyWolfManMiniMachine:MachineRule_playSelfEffect(effectData)
    

    if effectData.p_selfEffectType == self.FS_Collect_Wild_EFFECT then 


     

    end

    return true
end



function MonsterPartyWolfManMiniMachine:reelDownNotifyPlayGameEffect( )
    self:playGameEffect()

    if self.m_parent then
  
        self.m_parent:FSReelDownNotify( self.m_maxReelIndex  )
        
    end
end

function MonsterPartyWolfManMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MonsterPartyWolfManMiniMachine:checkNotifyUpdateWinCoin( )

    -- 这里作为freespin下狼人玩法 连线时通知钱数更新的接口

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


function MonsterPartyWolfManMiniMachine:getVecGetLineInfo( )
    return self.m_runSpinResultData.p_winLines
end


function MonsterPartyWolfManMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_parent then
        self.m_parent:FSReelShowSpinNotify( self.m_maxReelIndex )
        
        
    end

end

function MonsterPartyWolfManMiniMachine:quicklyStopReel(colIndex)

    
    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        local selfData = self.m_parent.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        if freeSpinType == self.m_parent.FS_GAME_TYPE_m_batMan then

        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_wolfMan then
            BaseMiniMachine.quicklyStopReel(self, colIndex) 
        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_ghostGirl then
            
        elseif freeSpinType == self.m_parent.FS_GAME_TYPE_greenMan then
            
        end
    end

    
end

function MonsterPartyWolfManMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end



function MonsterPartyWolfManMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function MonsterPartyWolfManMiniMachine:beginMiniReel()

    BaseMiniMachine.beginReel(self)

end


-- 消息返回更新数据
function MonsterPartyWolfManMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function MonsterPartyWolfManMiniMachine:enterLevel( )
    BaseMiniMachine.enterLevel(self)
end

function MonsterPartyWolfManMiniMachine:enterLevelMiniSelf( )

    BaseMiniMachine.enterLevel(self)
    
end



function MonsterPartyWolfManMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end



-- 处理特殊关卡 遮罩层级
function MonsterPartyWolfManMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function MonsterPartyWolfManMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parent:getBounsScatterDataZorder(symbolType ) 

end


function MonsterPartyWolfManMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function MonsterPartyWolfManMiniMachine:checkGameResumeCallFun( )
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

function MonsterPartyWolfManMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function MonsterPartyWolfManMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function MonsterPartyWolfManMiniMachine:resumeMachine()
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
function MonsterPartyWolfManMiniMachine:getSlotNodeBySymbolType(symbolType)
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
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:setMachine(self )
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

---
-- 清空掉产生的数据
--
function MonsterPartyWolfManMiniMachine:clearSlotoData()
    
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

function MonsterPartyWolfManMiniMachine:restSelfGameEffects( restType  )

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

function MonsterPartyWolfManMiniMachine:showLineFrame()
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
function MonsterPartyWolfManMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function MonsterPartyWolfManMiniMachine:clearCurMusicBg( )
    
end


function MonsterPartyWolfManMiniMachine:updateCollectKuang( kaungList )

    for i=1,#kaungList do
        local v = kaungList[i]
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local targSpIcons = self:getPosReelIdx(fixPos.iX, fixPos.iY)

        if not self:checkKuangIsLocked( targSpIcons ) then
            local targSp = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY, false)   

            if targSp  then 

               

                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

                local linePos = {}
                -- linePos[#linePos + 1] = {iX = targSp.p_rowIndex, iY = targSp.p_cloumnIndex}
                targSp.m_bInLine = false
                targSp:setLinePos(linePos)
                
                self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , fixPos.iY * SYMBOL_NODE_TAG + fixPos.iX)
    
                local position =  util_getOneGameReelsTarSpPos(self,pos )
                targSp:setPosition(cc.p(position))
                table.insert( self.m_FixBonusKuang,targSp)

                
                if targSp.p_symbolImage then
                    targSp.p_symbolImage:removeFromParent()
                    targSp.p_symbolImage = nil
                end
                targSp:runAnim("langren_wild_over",false,function(  )
                    targSp:runAnim("idleframe2") 
                end)
                
            end
        end
       


    end
        
end

function MonsterPartyWolfManMiniMachine:removeAllBaseKuang( )
    for i=1,#self.m_FixBonusKuang do
        local node = self.m_FixBonusKuang[i]
        node:removeFromParent(false)
        local linePos = {}
        node.m_bInLine = false
        node:setLinePos(linePos)
        node:setName("")
        local symbolType = node.p_symbolType
        node:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
    end

    self.m_FixBonusKuang = {}

end

function MonsterPartyWolfManMiniMachine:removeAllReelsNode()

    self:stopAllActions()
    self:clearWinLineEffect()

    self:removeAllBaseKuang( )

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

function MonsterPartyWolfManMiniMachine:checkIsShowCollectKuang( wildPosList )
    if wildPosList and #wildPosList > 0 then

        for k, v in pairs(wildPosList) do
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSpIcons = self:getPosReelIdx(fixPos.iX, fixPos.iY)
            if not self:checkKuangIsLocked( targSpIcons ) then
               return true
            end
            

            
        end
    end

    return false

end

function MonsterPartyWolfManMiniMachine:checkKuangIsLocked( index )

    for i=1,#self.m_FixBonusKuang do
        local wild = self.m_FixBonusKuang[i]

        if wild then
            local iconsPos = self:getPosReelIdx(wild.p_rowIndex, wild.p_cloumnIndex)

            if index == iconsPos then
                return true
            end
            
        end

    end

    return false
    
end


function MonsterPartyWolfManMiniMachine:updateNetWorkData()

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

    self.m_parent:wolfManNetBackCheckAddAction( )
end


function MonsterPartyWolfManMiniMachine:netBackReelsStop( )

    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end

function MonsterPartyWolfManMiniMachine:changeKuangToWild( func )
    
    local freeSpinLeftTimes = self.m_parent.m_runSpinResultData.p_freeSpinsLeftCount or 0

    if freeSpinLeftTimes == 0 then
        
        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_WolfMan_LastSpin_wolfHoujiao.mp3")

        util_spinePlay(self.m_parent.m_wolfManZhua,"chufa_1")
        util_spinePlay(self.m_parent.m_wolfMan,"chufa_1")
        self.m_parent.m_FsGameLightBg:runCsbAction("langren",false,function(  )
            self.m_parent.m_FsGameLightBg:runCsbAction("idle",true)
        end)

        performWithDelay(self,function(  )

            util_spinePlay(self.m_parent.m_wolfManZhua,"idleframe",true)
            util_spinePlay(self.m_parent.m_wolfMan,"idleframe",true)

            gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_WolfMan_KuangToWild.mp3")

            for i=1,#self.m_FixBonusKuang do
                local node = self.m_FixBonusKuang[i]
                local linePos = {}
                linePos[#linePos + 1] = {iX = node.p_rowIndex, iY = node.p_cloumnIndex}
                node.m_bInLine = true
                node:setLinePos(linePos)
                node:runAnim("langren_wild_chuxian")
            end
    
            performWithDelay(self,function(  )
                
                if func then
                    func()
                end
            end,50 / 30)
            
        end,80/30)
        
        
    else
        if func then
            func()
        end
    end
end

function MonsterPartyWolfManMiniMachine:getSlotNodeChildsTopY(colIndex)
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

return MonsterPartyWolfManMiniMachine
