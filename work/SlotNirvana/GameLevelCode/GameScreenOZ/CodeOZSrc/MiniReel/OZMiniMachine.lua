---
-- xcyy
-- 2018-12-18 
-- OZMiniMachine.lua
--
--

local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local OZSlotsNode = require "CodeOZSrc.OZSlotFastNode"

local OZMiniMachine = class("OZMiniMachine", BaseMiniMachine)

OZMiniMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  
OZMiniMachine.SYMBOL_FixBonus = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE 
OZMiniMachine.SYMBOL_Mini_Scatter = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2

OZMiniMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1 


OZMiniMachine.m_machineIndex = nil -- csv 文件模块名字

OZMiniMachine.gameResumeFunc = nil
OZMiniMachine.gameRunPause = nil

local MainReelId = 1

OZMiniMachine.m_lastWinCoin = nil
--重写了小块
function OZMiniMachine:getBaseReelGridNode()
    return "CodeOZSrc.OZSlotFastNode"
end
-- 构造函数
function OZMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    
end

function OZMiniMachine:initData_( data )


    self.gameResumeFunc = nil
    self.gameRunPause = nil
    
    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_reelId = data.index
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function OZMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function OZMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "OZ"
end

function OZMiniMachine:getMachineConfigName()

    local str = "Mini"
    

    return self.m_moduleName.. str .. "Config"..".csv"
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function OZMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil


    if symbolType == self.SYMBOL_SCORE_10  then
        return "Socre_OZ_10"
    elseif symbolType == self.SYMBOL_FixBonus then
        return "Socre_OZ_Bonus"
    elseif symbolType == self.SYMBOL_Mini_Scatter then
        return "Socre_OZ_Scatter_Mini"
    end
 
    return ccbName
end

function OZMiniMachine:getlevelConfigName( )
    local levelConfigName = "LevelOZMiniConfig.lua"
   

    return levelConfigName

end
---
-- 读取配置文件数据
--
function OZMiniMachine:readCSVConfigData( )
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
function OZMiniMachine:readSoundConfigData( )
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

function OZMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    local csbName = "GameScreenOZ_4rl_mini.csb"
    self:createCsbNode(csbName)
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function OZMiniMachine:initMachine()
    self.m_moduleName = "OZ" -- self:getModuleName()

    BaseMiniMachine.initMachine(self)
    self:initMiniReelsUi( )

end


function OZMiniMachine:initMiniReelsUi( )
    

    self.m_ReelsWinBar = util_createView("CodeOZSrc.MiniReel.OZMiniReelsWinBar")
    self:findChild("OZ_4rl_xiakuang"):addChild(self.m_ReelsWinBar)
    self:updateWinBarScore( 0)
    self:updateWinBarDiamondsNum( 0)


    local csbname = "GameScreenOZ_4rl_rentou" .. self.m_reelId
    self.m_ReelsMan = util_createView("CodeOZSrc.MiniReel.OZMiniReelsMan",csbname)
    self:findChild("rentou"):addChild(self.m_ReelsMan)
   
    

end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function OZMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()
    

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Mini_Scatter,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FixBonus,count =  2}



    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function OZMiniMachine:addSelfEffect()


    if self.m_parent:checkAllMiniReelsIsAddDiamonds( ) then
        --收集钻石
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT
    end
    
end


function OZMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end

function OZMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end


---
-- 每个reel条滚动到底
function OZMiniMachine:slotOneReelDown(reelCol)

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


    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            if  self:getGameSpinStage() ~= QUICK_RUN and self.m_reelId == MainReelId  then
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        if  self:getGameSpinStage() ~= QUICK_RUN and self.m_reelId == MainReelId  then
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
        if self.m_reelId == MainReelId  then
            gLobalSoundManager:playSound(self.m_reelDownSound)
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

end

function OZMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end

function OZMiniMachine:reelDownNotifyChangeSpinStatus()
  
    -- 发送freespin停止回调
    if self.m_reelId == MainReelId then
        if self.m_parent then
            self.m_parent:slotReelDownInFS()
        end
        
    end
    
end



function OZMiniMachine:playEffectNotifyChangeSpinStatus( )

    self.m_parent:setFsAllRunDown( 1)
end



function OZMiniMachine:quicklyStopReel(colIndex)

    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then

        BaseMiniMachine.quicklyStopReel(self, colIndex)
    end
end

function OZMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function OZMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function OZMiniMachine:beginMiniReel()

    BaseMiniMachine.beginReel(self)

end


-- 消息返回更新数据
function OZMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function OZMiniMachine:enterLevel( )
    BaseMiniMachine.enterLevel(self)
end


function OZMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end


-- 轮盘停止回调(自己实现)
function OZMiniMachine:setDownCallFunc(func )
    self.m_reelDownCallback = func
end

function OZMiniMachine:playEffectNotifyNextSpinCall( )
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end



-- 处理特殊关卡 遮罩层级
function OZMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
-- function OZMiniMachine:getBounsScatterDataZorder(symbolType )
--     -- 避免传递进来的是nil ，但是这种情况基本不会发生
--     symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
--     local order = 0
--     if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
--         order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
--     elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
--         order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
--     elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
--         order = REEL_SYMBOL_ORDER.REEL_ORDER_2
--     else

--         if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
--             -- 这样调整后 分支越高的信号层级越高
--             order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
--         else
--             order = REEL_SYMBOL_ORDER.REEL_ORDER_1
--         end
--     end
--     return order

-- end


function OZMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function OZMiniMachine:checkGameResumeCallFun( )
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


function OZMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function OZMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function OZMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end



function OZMiniMachine:initRandomSlotNodes()
    --初始化节点
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()
end




function OZMiniMachine:addLastWinSomeEffect() -- add big win or mega win
    if self.m_reelId == MainReelId then
        -- BaseMiniMachine.addLastWinSomeEffect(self)
    end
        
end

function OZMiniMachine:lineLogicWinLines( )
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

function OZMiniMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()
    
    local isFiveOfKind = self:lineLogicWinLines()
    
end

function OZMiniMachine:stopMiniScatterAct( )
    local collectList = self:getCollectList( )

    if collectList then
        for i=1,#collectList do
            local node = collectList[i]
            node:runAnim("idleframe")
        end
    end
    
    
end

function OZMiniMachine:getCollectList( )
    local collectList = nil

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node then
                if node.p_symbolType == self.SYMBOL_Mini_Scatter then
                    if not collectList then
                        collectList = {}
                    end
                    collectList[#collectList + 1] = node
                end
            end
        end
    end
    if collectList and #collectList > 0 then

        return collectList

    end

end

function OZMiniMachine:checkIsAddDiamonds( )
    

    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node then
                if node.p_symbolType == self.SYMBOL_Mini_Scatter then
                    return true
                end
            end
        end
    end

end

-- 设置自定义游戏事件
function OZMiniMachine:restSelfEffect( selfEffect )
    for i = 1, #self.m_gameEffects , 1 do

        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType and effectData.p_selfEffectType == selfEffect then
            
            effectData.p_isPlay = true
            self:playGameEffect()

            break
        end
        
    end
    
end


function OZMiniMachine:runAddDiamondsEffect(  )

    local collectList = self:getCollectList( )
    if collectList and #collectList > 0 then

        gLobalSoundManager:playSound("OZSounds/music_OZ_FS_Collect_MiniScatter.mp3")

        local lab =  self.m_ReelsWinBar:findChild("Node_flyPos")
        local endWorldPos =  lab:getParent():convertToWorldSpace(cc.p(lab:getPositionX(), lab:getPositionY()))

        local moveTimes = 0.5
        for i=1,#collectList do
            local node = collectList[i]

            node:runAnim("actionframe",true)
            local flyNode = util_createAnimation("OZ_shoujilizi_tuowei.csb") 
            self:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)

            flyNode:findChild("Particle_1"):setPositionType(0)
            flyNode:findChild("Particle_1"):setDuration(moveTimes)

            local endPos = flyNode:getParent():convertToNodeSpace(cc.p(endWorldPos.x,endWorldPos.y))

            local nodeWorldPos =  node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
            local flyNodePos = flyNode:getParent():convertToNodeSpace(cc.p(nodeWorldPos))
            flyNode:setPosition(cc.p(flyNodePos))

             
            local actList = {}
            actList[#actList + 1] = cc.MoveTo:create(moveTimes,cc.p(endPos))
            actList[#actList + 1] = cc.DelayTime:create(moveTimes)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                flyNode:stopAllActions()
                flyNode:removeFromParent()
            end)
            local sq = cc.Sequence:create(actList)
            flyNode:runAction(sq)
            
        end

        scheduler.performWithDelayGlobal(function (  )
            self.m_parent:playEndAddDiamondsEffect( self.m_reelId )
        end,moveTimes,self:getModuleName())


        

    else
        self.m_parent:playEndAddDiamondsEffect(  )
    end
    
    

end

function OZMiniMachine:showEffect_LineFrame(effectData)

    if self.m_parent then
        self.m_parent:updateLittleReelsCoins( self.m_reelId )
    end
    

    self:showLineFrame()

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.5)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true

end

function OZMiniMachine:stopWinBarScoreAct( coins )
    local lab = self.m_ReelsWinBar:findChild("BitmapFontLabel_1")
    lab:unscheduleUpdate()
    lab:setString(util_formatCoins(coins,50))
    self.m_ReelsWinBar:updateLabelSize({label=lab,sx=1,sy=1},370)
end


function OZMiniMachine:updateWinBarScore( coins ,oldCoins)

    if oldCoins then

        local lb2 = self.m_ReelsWinBar:findChild("BitmapFontLabel_1")
        local startValue = oldCoins
        local addValue = (coins - startValue) /100
        util_jumpNum(lb2,startValue,coins,addValue,0.02,{50},nil,nil,function(  )
            self.m_ReelsWinBar:updateLabelSize({label=lb2,sx=1,sy=1},370)
        end)
        
    else
        local lab = self.m_ReelsWinBar:findChild("BitmapFontLabel_1")
        lab:setString(util_formatCoins(coins,50))
        self.m_ReelsWinBar:updateLabelSize({label=lab,sx=1,sy=1},370)
    end

end

function OZMiniMachine:updateWinBarDiamondsNum( num )
    local lab = self.m_ReelsWinBar:findChild("BitmapFontLabel_1_0")
    lab:setString(num)

end

---
--设置bonus scatter 层级
function OZMiniMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_Mini_Scatter then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 1
    elseif symbolType == self.SYMBOL_FixBonus then
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


function OZMiniMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    if self.m_bGetSymbolTime == nil then
        self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期
    end
    
    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

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

return OZMiniMachine
