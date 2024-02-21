local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local RoyaleBattleDownReelMiniMachine = class("RoyaleBattleDownReelMiniMachine", BaseMiniMachine)


RoyaleBattleDownReelMiniMachine.m_panelOpacity = 160

-- 构造函数
function RoyaleBattleDownReelMiniMachine:ctor()
    BaseMiniMachine.ctor(self)
end

function RoyaleBattleDownReelMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_parent = data.parent

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()

end

function RoyaleBattleDownReelMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function RoyaleBattleDownReelMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RoyaleBattle"
end


--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function RoyaleBattleDownReelMiniMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = "RoyaleBattleSounds/sound_RoyaleBattle_scatter_ground.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

---
-- 读取配置文件数据
--
function RoyaleBattleDownReelMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData("RoyaleBattleDownConfig.csv", "LevelRoyaleBattleConfig.lua")
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function RoyaleBattleDownReelMiniMachine:initMachineCSB()
    -- self.m_winFrameCCB = "WinFrame" .. self.m_moduleName
    self.m_winFrameCCB = "WinFrameRoyaleBattle_blue"
    self:createCsbNode("reel_base_xia.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")


end

function RoyaleBattleDownReelMiniMachine:initMachine()
    self.m_moduleName =  self:getModuleName()

    BaseMiniMachine.initMachine(self)

    self.m_lockNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_lockNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)
    
    --遮罩
    self.m_panelDown = self.m_parent:createRoyaleBattleMask(self)
end

function RoyaleBattleDownReelMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function RoyaleBattleDownReelMiniMachine:addObservers()
    BaseMiniMachine.addObservers(self)
end

function RoyaleBattleDownReelMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

function RoyaleBattleDownReelMiniMachine:removeObservers()
    BaseMiniMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function RoyaleBattleDownReelMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)
    return ccbName
end


-- 处理特殊关卡 遮罩层级
function RoyaleBattleDownReelMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    local maxzorder = 0
    local zorder = 0

    for i = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder > maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

function RoyaleBattleDownReelMiniMachine:checkGameResumeCallFun()
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

function RoyaleBattleDownReelMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function RoyaleBattleDownReelMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function RoyaleBattleDownReelMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function RoyaleBattleDownReelMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function RoyaleBattleDownReelMiniMachine:clearCurMusicBg()
end

function RoyaleBattleDownReelMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function RoyaleBattleDownReelMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_parent:reelShowSpinNotify( )
end

function RoyaleBattleDownReelMiniMachine:slotReelDown()
    --将滚动时提层的scatter还原层级
    -- if self.m_parent.m_bProduceSlots_InFreeSpin then
        self.m_parent:reSetSymbolOrder(2)
    -- end


    RoyaleBattleDownReelMiniMachine.super.slotReelDown(self)
end

function RoyaleBattleDownReelMiniMachine:reelDownNotifyPlayGameEffect()

    RoyaleBattleDownReelMiniMachine.super.reelDownNotifyPlayGameEffect(self)

    self.m_parent:setReelRunDownNotify( )
end

----------------------------- 玩法处理 -----------------------------------

function RoyaleBattleDownReelMiniMachine:beginMiniReel()

    BaseMiniMachine.beginReel(self)
    
end
--解决玩法触发时 棋盘停止不同步问题
function RoyaleBattleDownReelMiniMachine:updateNetWorkData(_isAnim)
    --中奖预告
    if self.m_parent.m_isPlayWinningNotice then
        return
    end
    

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
   

    -- 第十次不调用
    local data =  self.m_parent:BaseMania_getCollectData(1)
    if (data.p_collectLeftCount == data.p_collectTotalCount) and not _isAnim then

    else
        self:produceSlots()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()  
    end
    
end



--[[
    @desc: 检测是否需要延迟处理网络消息
    time:2020-07-20 18:19:37
    @return:
]]
function RoyaleBattleDownReelMiniMachine:checkWaitOperaNetWorkData( )
    --存在等待时间延后调用下面代码
    if not self.m_netWorkID and self.m_waitChangeReelTime and self.m_waitChangeReelTime>0 then
        self.m_netWorkID = scheduler.performWithDelayGlobal(function()
            self.m_waitChangeReelTime=nil
            self:updateNetWorkData()

            self.m_netWorkID = nil
        end, self.m_waitChangeReelTime,self:getModuleName())
        return true
    end
    return false
end

--[[    --解决网络数据返回时的 数据初始化 和 使用网络数据的逻辑 做拆分
    @desc: 网络消息返回后， 做的处理
    time:2018-11-29 17:24:15
    @return:
]]
function RoyaleBattleDownReelMiniMachine:produceSlots()

    -- self:MachineRule_RestartProbabilityCtrl()

    self:setLastReelSymbolList() 
    
    self:setReelRunInfo()

    self:MachineRule_ResetReelRunData()
    
    self:produceReelSymbolList()

    self:MachineRule_InterveneReelList()

end

function RoyaleBattleDownReelMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
end

-- 消息返回更新数据 
-- 废弃 拆分为 MainReel_parseResultData   MainReel_updateNetWorkData
function RoyaleBattleDownReelMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    self:updateNetWorkData()
end

function RoyaleBattleDownReelMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function RoyaleBattleDownReelMiniMachine:quicklyStopReel(colIndex)

    BaseMiniMachine.quicklyStopReel(self, colIndex)
    
end

---
-- 清空掉产生的数据
--
function RoyaleBattleDownReelMiniMachine:clearSlotoData()
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then
        for i = #self.m_lineDataPool, 1, -1 do
            self.m_lineDataPool[i] = nil
        end
    end
end


function RoyaleBattleDownReelMiniMachine:addSelfEffect()
 
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.m_parent:addCollectSCEffect( self )
        self.m_parent:addCollectSCFullTimesEffect(self )
    end

end

function RoyaleBattleDownReelMiniMachine:restSelfGameEffects(restType)
    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects, 1 do
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



function RoyaleBattleDownReelMiniMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.BONUS_FS_ADD_EFFECT then
        
    end

    return true
end




function RoyaleBattleDownReelMiniMachine:specialSymbolActionTreatment(node)

end


function RoyaleBattleDownReelMiniMachine:getNextReelSymbolType( )
    
    return self.m_runSpinResultData.p_prevReel
end

function RoyaleBattleDownReelMiniMachine:slotOneReelDown(reelCol)
    RoyaleBattleDownReelMiniMachine.super.slotOneReelDown(self, reelCol)
    
end




--新滚动使用
function RoyaleBattleDownReelMiniMachine:updateReelGridNode(symblNode)
    
end



--设置bonus scatter 层级
function RoyaleBattleDownReelMiniMachine:getBounsScatterDataZorder(symbolType)
    
    return self.m_parent:getBounsScatterDataZorder(symbolType)
end

function RoyaleBattleDownReelMiniMachine:initMiniGameStatusData(gameData )
    local spin = gameData.spin
    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin,self.m_lineDataPool,self.m_symbolCompares,feature)
        self.m_initSpinData = self.m_runSpinResultData
    end

end

function RoyaleBattleDownReelMiniMachine:enterLevel( )
    
end

function RoyaleBattleDownReelMiniMachine:enterLevelMiniSelf( )

    RoyaleBattleDownReelMiniMachine.super.enterLevel(self)
    
end

function RoyaleBattleDownReelMiniMachine:dealSmallReelsSpinStates( )
  
end

function RoyaleBattleDownReelMiniMachine:checkNotifyUpdateWinCoin( )
    self.m_parent:miniMachine_checkNotifyUpdateWinCoin(self.m_reelResultLines)
end



----主棋盘调用接口: 

--发消息返回的接口拆分为2个 
function RoyaleBattleDownReelMiniMachine:MainReel_parseResultData(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    --从 produceSlots 提出
    self:MachineRule_RestartProbabilityCtrl()
end
function RoyaleBattleDownReelMiniMachine:MainReel_updateNetWorkData()
    self:updateNetWorkData()
end

--添加的事件会卡住其他事件进行 主棋盘的事件完毕后 会注销 迷你棋盘的对应事件
function RoyaleBattleDownReelMiniMachine:MainReel_addSelfEffect(effect)
    local selfEffect = clone(effect)
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
end
--注销进入下一步
function RoyaleBattleDownReelMiniMachine:MainReel_removeSelfEffect(effect)
    for _index,_effectData in ipairs(self.m_gameEffects) do
        if _effectData.p_effectType == effect.p_effectType then
            _effectData.p_isPlay = true
            self:playGameEffect()
            return
        end
    end

    self:playGameEffect()
end

function RoyaleBattleDownReelMiniMachine:MainReel_changeMaskVisible(_isVis)
    self.m_panelDown:setVisible(_isVis)
    self.m_panelDown:setOpacity(self.m_panelOpacity)
end
function RoyaleBattleDownReelMiniMachine:MainReel_playMaskFadeAction(_isFadeIn, _fadeTime)
    local fadeTime = _fadeTime or 0.1
    local opacity = _isFadeIn and 0 or self.m_panelOpacity

    local act_fade = _isFadeIn and cc.FadeIn:create(fadeTime) or cc.FadeOut:create(fadeTime)
    self.m_panelDown:setOpacity(opacity)
    self.m_panelDown:setVisible(true)
    self.m_panelDown:runAction(act_fade)
end

------------------------------------------------------------一些特殊操作重写父类接口

-- 解决Scatter小块上面附加的spine节点问题
-- 根据类型获取对应节点
--
function RoyaleBattleDownReelMiniMachine:getSlotNodeBySymbolType(symbolType)
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
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    --!!!插入修改
    self.m_parent:addScatterSpineNode(reelNode)

    return reelNode
end
function RoyaleBattleDownReelMiniMachine:pushAnimNodeToPool(animNode, symbolType)
    self.m_parent:removeScatterSpineNode(animNode )
    RoyaleBattleDownReelMiniMachine.super.pushAnimNodeToPool(self,animNode, symbolType)
   
end
function RoyaleBattleDownReelMiniMachine:getAnimNodeFromPool(symbolType, ccbName)
    local node = RoyaleBattleDownReelMiniMachine.super.getAnimNodeFromPool(self,symbolType, ccbName)
    self.m_parent:removeScatterSpineNode(node )

    return node
end
-- 解决落地动画
function RoyaleBattleDownReelMiniMachine:playCustomSpecialSymbolDownAct( slotNode )

    RoyaleBattleDownReelMiniMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    if slotNode.p_symbolType and self.m_parent:isRoyaleBattleScatter(slotNode.p_symbolType)  then

        local soundPath = "RoyaleBattleSounds/sound_RoyaleBattle_Scatter_down.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

        self.m_parent:addScatterSpineNode(slotNode)

        local scatterOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex
        local slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,-scatterOrder)
        self:playRoyaleBattleScatterAnim(slotNode, "buling", false, 40/60,function()
            self:playRoyaleBattleScatterAnim(slotNode, "idleframe")
        end)

    end
end

function RoyaleBattleDownReelMiniMachine:playRoyaleBattleScatterAnim(_scatterSymbol, _animName, _isLoop, _delay, _fun)
    _scatterSymbol:runAnim(_animName, _isLoop)

    local spineParent = _scatterSymbol:getCcbProperty("Node_spine")
    if spineParent then

        local scatterSpine = spineParent:getChildByName("scatterSpine")
        if scatterSpine then
            util_spinePlay(scatterSpine, _animName)
        end

    end

    if _delay and _fun then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode, function()
            if _fun then
                _fun()
            end

            waitNode:removeFromParent()
        end, _delay)
    end
end

-- 解决开始滚动时 赢钱展示被移除问题
--beginReel时尝试修改层级
function RoyaleBattleDownReelMiniMachine:checkChangeBaseParent()
    -- 处理特殊信号
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if childs[i].resetReelStatus ~= nil then
            --!!!修改此处
            -- childs[i]:resetReelStatus()
            self.m_parent:resetReelStatus(childs[i])
        end
        if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            --将该节点放在 .m_clipParent
            local posWorld =
                self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(), childs[i]:getPositionY()))
            local pos =
                self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            if not childs[i].p_showOrder then
                childs[i].p_showOrder = self:getBounsScatterDataZorder(childs[i].p_symbolType)
            end
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            self:changeBaseParent(childs[i])
            childs[i]:setPosition(pos)
            --!!!修改此处
            -- childs[i]:resetReelStatus()
            self.m_parent:resetReelStatus(childs[i])
        end
    end
end


-- 解决快滚时上下棋盘交替滚动
function RoyaleBattleDownReelMiniMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    return self.m_parent:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong, self)
end
-- 解决快滚时上下棋盘交替滚动
function RoyaleBattleDownReelMiniMachine:getLongRunLen(col, index)
    return self.m_parent:getLongRunLen(col, index,  self)
end
-- 解决快滚时上下棋盘交替滚动
function RoyaleBattleDownReelMiniMachine:creatReelRunAnimation(col)
    return self.m_parent:creatReelRunAnimation(col, self)
end
-- 解决滚动时小块层级不对问题
function RoyaleBattleDownReelMiniMachine:reelSchedulerHanlder(dt)
    self.m_parent:upDateRoyaleBattleRunOrder(self)
    
    RoyaleBattleDownReelMiniMachine.super.reelSchedulerHanlder(self, dt)
end
-- 解决连线时小块层级最高
function RoyaleBattleDownReelMiniMachine:playInLineNodes()
    self.m_parent:playInLineNodes(self)
end
-- 解决连线时小块层级最高
function RoyaleBattleDownReelMiniMachine:showLineFrameByIndex(winLines,frameIndex)
    self.m_parent:showLineFrameByIndex(winLines,frameIndex,self)
end

--进入关卡时没有玩法，首次轮盘初始化走配置
function RoyaleBattleDownReelMiniMachine:initRandomSlotNodes()
    self.m_parent:initRandomSlotNodes(self)
end

--返回本组下落音效和是否触发长滚效果
function RoyaleBattleDownReelMiniMachine:getRunStatus(col, nodeNum, showCol)
    local runStatus, runType = self.m_parent:getRunStatus(col, nodeNum, showCol,self)
   return runStatus, runType
end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function RoyaleBattleDownReelMiniMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
    local reelRunData = self.m_reelRunInfo
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function RoyaleBattleDownReelMiniMachine:checkUpdateReelDatas(parentData )
    local reelDatas = self.m_parent:checkUpdateReelDatas(parentData,self )

    

    return reelDatas

end

return RoyaleBattleDownReelMiniMachine
