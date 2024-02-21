
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenWickedBlazeMachine = class("CodeGameScreenWickedBlazeMachine", BaseNewReelMachine)

CodeGameScreenWickedBlazeMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenWickedBlazeMachine.SYMBOL_SCORE_11 = 10

CodeGameScreenWickedBlazeMachine.SYMBOL_SCORE_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1--93 + 几
CodeGameScreenWickedBlazeMachine.SYMBOL_SCORE_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenWickedBlazeMachine.SYMBOL_SCORE_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3

CodeGameScreenWickedBlazeMachine.SYMBOL_SCORE_SCATTER2 = 91

CodeGameScreenWickedBlazeMachine.COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- bonus图标收集
CodeGameScreenWickedBlazeMachine.ADDBIGWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 大wild出现
CodeGameScreenWickedBlazeMachine.COLLECT_FREESPIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --收集freespin次数
--bugly:小转盘over时间线还没播完还存在时，玩家freeSpin导致解析了不存在的回传数据
CodeGameScreenWickedBlazeMachine.m_WheelViewOver2Time = 1.1
-- 构造函数
function CodeGameScreenWickedBlazeMachine:ctor()
    CodeGameScreenWickedBlazeMachine.super.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_enterGameMusicIsComplete = false--进关音乐是否播完
    self.m_betCollectData = {}--bet收集数据
    self.m_collectNodeTab = {}--收集标记对象存储表
    self.m_bigWildNodeTab = {}--大wild对象存储表
    self.m_smallWildNodeTab = {}--假装是大wild的整列小wild对象存储表
    self.m_bigWildFrameNodeTab = {}--一列wild边框特效存储表

    self.m_scatterNodeTab = {}--小恶魔发射的火球变的scatter对象存储表

    self.m_curCollectColTab = {}--本轮有收集图标的列
    self.m_curNoCollectColTab = {}--本轮没有收集图标的列

    self.m_paozhangCollectLiziTab = {}--存储炮仗收集粒子对象
    self.m_freespinNumCollectLiziTab = {}--存储freespin次数收集粒子对象
    self.m_addNumScatterNodeTab = {}--存储被提层的加freespin次数图标
    self.m_flyTime = 0--收集动画的最大时间
    self:initGame()
end

function CodeGameScreenWickedBlazeMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("WickedBlazeConfig.csv", "LevelWickedBlazeConfig.lua")
	--初始化基本数据
	self:initMachine()
end
function CodeGameScreenWickedBlazeMachine:getBottomUINode()
    return "CodeWickedBlazeSrc.WickedBlazeBoottomUiView"
end
-- 获取关卡名字
function CodeGameScreenWickedBlazeMachine:getModuleName()
    return self.m_configData.m_levelName
end
--UI初始化
function CodeGameScreenWickedBlazeMachine:initUI()
    self.m_reelRunSound = "WickedBlazeSounds/music_WickedBlaze_quick_run.mp3"--快滚音效
    self.m_gameBg:setPositionY(self.m_machineNode:getPositionY())
    self.m_gameBg:findChild("root"):setScale(self.m_machineRootScale)

    self.m_effectNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_effectNode,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)

    --初始化底部条上的freespin信息显示条
    self:initFreeSpinBar()
    --添加jackpot条
    self.m_jackpotBar = util_createView("CodeWickedBlazeSrc.WickedBlazeJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)
    --添加火魔
    self.m_wickedBlazeNode = util_spineCreate("WickedBlaze_dajuese",true,true)
    self:findChild("devil"):addChild(self.m_wickedBlazeNode)
    self:playWickedBlazeAni("idleframe",true)
    self.m_wickedBlazeNode:setPosition(cc.p(self:findChild("devil_1"):getPosition()))
    --添加收集标记
    for i = 1,self.m_iReelColumnNum do
        local collectNode = util_createAnimation("WickedBlaze_shouji.csb")
        self:findChild("shouji_"..i):addChild(collectNode)
        table.insert(self.m_collectNodeTab,collectNode)
        collectNode:playAction("idle1",false)
        collectNode.paozhangTab = {}
        for j = 1,self.m_configData.m_collectNodeFirecrackerNum do
            local paozhang = util_createAnimation("WickedBlaze_shouji_paozhang"..j..".csb")
            collectNode:findChild("paozhang"):addChild(paozhang)
            table.insert(collectNode.paozhangTab,paozhang)
            paozhang:setVisible(false)
        end
        collectNode:findChild("Particle_1"):setVisible(false)
    end
    --添加freespin计数条
    self.m_freespinBar = util_createView("CodeWickedBlazeSrc.WickedBlazeFreespinBarView")
    self:findChild("freespinNode"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)

    self:findChild("triggerEffect"):setVisible(false)
    self:findChild("triggerEffect"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)

    self.m_waitNode = cc.Node:create()
    self:addChild(self.m_waitNode)
end
--播放小恶魔动画
function CodeGameScreenWickedBlazeMachine:playWickedBlazeAni(aniName,isLoop,func)
    if self.m_wickedBlazeNode.currPlayAni ~= aniName then
        self.m_wickedBlazeNode.currPlayAni = aniName
        util_spinePlay(self.m_wickedBlazeNode,aniName,isLoop)
        util_spineEndCallFunc(self.m_wickedBlazeNode,aniName,function ()
            if func then
                func()
            end
        end)
    end
end
--适配
function CodeGameScreenWickedBlazeMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize() --h 120
    local uiBW, uiBH = self.m_bottomUI:getUISize()  --h 180
    --看资源实际的高度
    uiH = 120
    uiBH = 180

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1

    if display.height/display.width == DESIGN_SIZE.height/DESIGN_SIZE.width then
        --设计尺寸屏

    elseif display.height/display.width > DESIGN_SIZE.height/DESIGN_SIZE.width then
        --高屏
        local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale < wScale then
            mainScale = hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end
    else
        --宽屏
        local topAoH = 40--顶部条凹下去距离 在宽屏中会被用的尺寸
        local bottomMoveH = 30--底部空间尺寸，最后要下移距离
        local hScale1 = (mainHeight + topAoH )/(mainHeight + topAoH - bottomMoveH)--有效区域尺寸改变适配
        local hScale = (mainHeight + topAoH ) / (DESIGN_SIZE.height - uiH - uiBH + topAoH )--有效区域屏幕适配
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale1 * hScale < wScale then
            mainScale = hScale1 * hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end

        local designDis = (DESIGN_SIZE.height/2 - uiBH) * mainScale--设计离下条距离
        local dis = (display.height/2 - uiBH)--实际离下条距离
        local move = designDis - dis
        --宽屏下轮盘跟底部条更接近，实际整体下移了
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + move - bottomMoveH)
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end
function CodeGameScreenWickedBlazeMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(self.m_configData.m_freespinRowNum,self.m_iReelColumnNum,TAG_SYMBOL_TYPE.SYMBOL_WILD)
end
--进关播放音乐
function CodeGameScreenWickedBlazeMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_enter.mp3")
        scheduler.performWithDelayGlobal(function ()
            self.m_enterGameMusicIsComplete = true
            self:resetMusicBg()
            if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
                self:setMinMusicBGVolume()
            end
        end,2.5,self:getModuleName())
    end,0.4,self:getModuleName())
end
-- 重置当前背景音乐名称
function CodeGameScreenWickedBlazeMachine:resetCurBgMusicName()
    if self.m_enterGameMusicIsComplete == false then
        return nil
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == REWAED_SPIN_MODE then
        self.m_currentMusicBgName = "WickedBlazeSounds/music_WickedBlaze_WheelBG.mp3"
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end
--进关数据初始化
function CodeGameScreenWickedBlazeMachine:initGameStatusData(gameData)
    CodeGameScreenWickedBlazeMachine.super.initGameStatusData(self,gameData)
    if gameData.gameConfig and gameData.gameConfig.extra then
        --进关初始化bet收集数据
        local collectDatas = gameData.gameConfig.extra.collectData
        for betIdString,collectData in pairs(collectDatas) do
            local data = {}
            data.collects = {}
            data.wildLeftCounts = {}
            for i,num in ipairs(collectData.collects) do
                table.insert(data.collects,num)
            end
            for i,leftCount in ipairs(collectData.wildLeftCounts) do
                table.insert(data.wildLeftCounts,leftCount)
            end
            self.m_betCollectData[betIdString] = data
        end
    end
end
--更新bet收集数据
function CodeGameScreenWickedBlazeMachine:updateBetCollectData()
    if self.m_runSpinResultData.p_selfMakeData then
        local totalBetID = globalData.slotRunData:getCurTotalBet()
        local collectData = self.m_runSpinResultData.p_selfMakeData.collectData

        local data = {}
        data.collects = clone(collectData.collects)
        data.wildLeftCounts = clone(collectData.wildLeftCounts)
        self.m_betCollectData[""..totalBetID] = data
    end
end

----
--- 处理spin 成功消息
--
function CodeGameScreenWickedBlazeMachine:checkOperaSpinSuccess( param )

    if param[2].result then
        if  param[2].result.features[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            local rand = math.random(0,9)
            if rand < 3 then
                --本轮触发bonus玩法  播小恶魔施法动画
                self:wickedBlazeCasting(param)
                self.m_waitChangeReelTime = self.m_configData.m_fireBallReelWartTime
                self:findChild("triggerEffect"):setVisible(true)
            end
        end
    end
    
    CodeGameScreenWickedBlazeMachine.super.checkOperaSpinSuccess(self,param)
    if self.m_waitChangeReelTime and self.m_waitChangeReelTime > 0 then
        --不能快停
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end
--添加快滚特效
function CodeGameScreenWickedBlazeMachine:creatReelRunAnimation(col)
    --   self.m_runSpinResultData.p_selfMakeData.wildColumns
    if self.m_bigWildNodeTab[col] ~= nil then
        --本列有大wild
        return
    end
    CodeGameScreenWickedBlazeMachine.super.creatReelRunAnimation(self,col)
end
--滚动长度的设置
function CodeGameScreenWickedBlazeMachine:getLongRunLen(col, index)
    local len = 0
    local scatterShowCol = self.m_ScatterShowCol
    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if scatterShowCol ~= nil then
        if self:getInScatterShowCol(col) then 
            if self.m_bigWildNodeTab[col] ~= nil then
                local reelRunData = self.m_reelRunInfo[col - 1]
                local diffLen = self.m_reelRunInfo[2]:getReelRunLen() - self.m_reelRunInfo[1]:getReelRunLen()
                local lastRunLen = reelRunData:getReelRunLen()
                len = lastRunLen + diffLen
                self.m_reelRunInfo[col]:setReelLongRun(false)
            else
                local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
            end
        elseif col > scatterShowCol[#scatterShowCol] then
            local reelRunData = self.m_reelRunInfo[col - 1]
            local diffLen = self.m_reelRunInfo[2]:getReelRunLen() - self.m_reelRunInfo[1]:getReelRunLen()
            local lastRunLen = reelRunData:getReelRunLen()
            len = lastRunLen + diffLen
            self.m_reelRunInfo[col]:setReelLongRun(false)
        end
    end
    if len == 0 then
        local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    end
    return len
end
function CodeGameScreenWickedBlazeMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()
    
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenWickedBlazeMachine:MachineRule_afterNetWorkLineLogicCalculate()   
    self:updateBetCollectData()
end

-- 小恶魔施法动画
function CodeGameScreenWickedBlazeMachine:wickedBlazeCasting(param)
    --将scatter图标换为普通图标并记录scatter图标的位置
    local scatterPos = {}

    local reelsData = param[2].result.reels
    for i,rowDatas in ipairs(reelsData) do
        for col,symbolType in ipairs(rowDatas) do
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                reelsData[i][col] = self:getOneSmallNorSymbol()
                table.insert(scatterPos,{row = self.m_iReelRowNum - i + 1,col = col})
            end
        end
    end
    --根据列数排序
    table.sort(scatterPos,function (pos1,pos2)
        return pos1.col < pos2.col
    end)
    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_wickedBlazeCasting.mp3")
    gLobalSoundManager:playSound("WickedBlazeSounds/Wannatohavesomemysteriousflamingballgifts.mp3")
    --小恶魔开始施法放火球
    self:playWickedBlazeAni("actionframe",false,function ()
        self:playWickedBlazeAni("idleframe",true)
    end)
    performWithDelay(self,function ()
        --开始飞火球
        self:startFlyFireBall(scatterPos)
    end,self.m_configData.m_startFireBallFrame / 30)
end
--开始飞火球
function CodeGameScreenWickedBlazeMachine:startFlyFireBall(scatterPos)
    for i,posTab in ipairs(scatterPos) do
        local startPos = cc.p(self:findChild("huoqiuStartPos"):getPosition())
        local endPos = self:getNodePosByColAndRow(posTab.row,posTab.col)
        -- local worldPos = self.m_clipParent:convertToWorldSpace(pos)
        local fireBall = util_spineCreate("WickedBlaze_dajuese_feixing",true,true)
        self.m_clipParent:addChild(fireBall,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
        util_spinePlay(fireBall,"feixing",true)
        fireBall:setPosition(startPos)
        fireBall:setVisible(false)

        local delay = cc.DelayTime:create((i - 1) * self.m_configData.m_fireBallIntervalTime)
        local callFunc1 = cc.CallFunc:create(function()
            fireBall:setVisible(true)
        end)
        local movtTo = cc.MoveTo:create(self.m_configData.m_fireBallFlyTime ,endPos)
        local callFunc2 = cc.CallFunc:create(function()
            --删除火球
            fireBall:removeFromParent()
            --添加爆炸特效
            local baozhaNode = util_spineCreate("WickedBlaze_dajuese_baozha",true,true)
            baozhaNode:setPosition(endPos)
            self.m_clipParent:addChild(baozhaNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
            util_spinePlay(baozhaNode,"baozha",false)
            util_spineEndCallFunc(baozhaNode,"baozha",function ()
                baozhaNode:setVisible(false)
                local callFun = cc.CallFunc:create(function ()
                    baozhaNode:removeFromParent()
                end)
                baozhaNode:runAction(callFun)
            end)
            --添加scatter图标
            performWithDelay(self,function ()
                local scatter = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, posTab.row,posTab.col)
                self.m_clipParent:addChild(scatter,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 200 - self.m_iReelRowNum - 1 + posTab.col, SYMBOL_NODE_TAG)
                scatter:setPosition(endPos)
                scatter:runAnim("idleframe")
                scatter.p_slotNodeH = self.m_SlotNodeH

                scatter.m_symbolTag = SYMBOL_FIX_NODE_TAG
                scatter.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                scatter.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

                local linePos = {}
                linePos[#linePos + 1] = {iX = posTab.row,iY = posTab.col}
                scatter:setLinePos(linePos)

                table.insert(self.m_scatterNodeTab,scatter)
            end,self.m_configData.m_baozhaFrameScatter/30)
        end)
        local seq = cc.Sequence:create(delay,callFunc1,movtTo,callFunc2)
        fireBall:runAction(seq)
    end
end
--删除飞火球创建的scatter
function CodeGameScreenWickedBlazeMachine:beginReelRemoveAllScatter()
    for i,scatterNode in ipairs(self.m_scatterNodeTab) do
        local col = scatterNode.p_cloumnIndex
        local row = scatterNode.p_rowIndex
        local slotNode = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
        if slotNode then
            slotNode:setVisible(true)
        end
        scatterNode:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(scatterNode.p_symbolType, scatterNode)
    end
    self.m_scatterNodeTab = {}
end
function CodeGameScreenWickedBlazeMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    
    CodeGameScreenWickedBlazeMachine.super.onEnter(self)
    self:addObservers()

    self:updateBigWildNode(false)
    self:updateCollectNode()
end
--进关初始化
function CodeGameScreenWickedBlazeMachine:checkInitSpinWithEnterLevel()
    local isTriggerEffect = false
    local isPlayGameEffect = false

    if self.m_initSpinData ~= nil then 
        -- 检测上次的feature 信息
       
        if self.m_initFeatureData == nil or (self.m_initFeatureData ~= nil and self.m_initFeatureData.p_status == "CLOSED") then
            -- 检测是否要触发 feature
            self:checkNetDataFeatures()
        end
        
        isPlayGameEffect = self:checkNetDataCloumnStatus()
        local isPlayFreeSpin =  self:checkTriggerINFreeSpin()

        isPlayGameEffect = isPlayGameEffect or isPlayFreeSpin --self:checkTriggerINFreeSpin()
        if isPlayGameEffect and self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
            -- 这里只是用来检测是否 触发了 bonus ，如果触发了那么不调用数据生成
            isTriggerEffect = true
        end

        ----- 以下是检测初始化当前轮盘 ---- 
        self:checkInitSlotsWithEnterLevel()
        
    end

    return isTriggerEffect,isPlayGameEffect
end
-- 断线重连
function CodeGameScreenWickedBlazeMachine:MachineRule_initGame()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --轮盘动画
        self:runCsbAction("idle_1")
        --背景动画
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle2")

        -- self.m_jackpotBar:setVisible(false)
        self.m_jackpotBar:runCsbAction("over")
        self.m_freespinBar:setVisible(true)
        self.m_freespinBar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount - self.m_runSpinResultData.p_freeSpinNewCount,self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinNewCount )
        self.m_wickedBlazeNode:setPosition(cc.p(self:findChild("devil_2"):getPosition()))
        self:playWickedBlazeAni("actionframe_free_1",false,function ()
            self:playWickedBlazeAni("actionframe_free_2",true)
        end)
        --修改总行数为freespin行数
        self:changeToFreespinRowNum()
        --修改盘面滚轴及图标
        self:changeReel()
        --更改裁切区域
        self:changeClipRegion()
        --修改滚轴属性为freespin盘面的
        self:changeReelAttributeToFreespin()

        self.m_fsLastWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    end
end
--添加事件
function CodeGameScreenWickedBlazeMachine:addObservers()
    CodeGameScreenWickedBlazeMachine.super.addObservers(self)
    -- 播放赢钱音效
    gLobalNoticManager:addObserver(self,function(self,params)  
        if self.m_bIsBigWin then
            return
        end

        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 3
        else
            soundIndex = 3
            soundTime = 3
        end

        local soundName = "WickedBlazeSounds/music_WickedBlaze_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self,params)
        if params then
            local isLevelUp = params.p_isLevelUp
            self:betChangeNotify(isLevelUp) 
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    --添加jackpot弹框
    gLobalNoticManager:addObserver(self,function(self,params)
        self:showJackpotLayer()
    end,"CodeGameScreenWickedBlazeMachine_showJackpotLayer")

    --轮盘结束触发freespin
    gLobalNoticManager:addObserver(self,function(self,params)
        self:wheelOverTriggerFreeSpin()
    end,"CodeGameScreenWickedBlazeMachine_wheelOverTriggerFreeSpin")
    
end

function CodeGameScreenWickedBlazeMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWickedBlazeMachine.super.onExit(self)
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

-- 返回自定义信号类型对应资源名
-- @param symbolType int 信号块类型
function CodeGameScreenWickedBlazeMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_WickedBlaze_10"
    end
    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_WickedBlaze_11"
    end

    if symbolType == self.SYMBOL_SCORE_BONUS1 then
        return "Socre_WickedBlaze_Bonus1"
    end

    if symbolType == self.SYMBOL_SCORE_BONUS2 then
        return "Socre_WickedBlaze_Bonus2"
    end

    if symbolType == self.SYMBOL_SCORE_BONUS3 then
        return "Socre_WickedBlaze_Bonus3"
    end

    if symbolType == self.SYMBOL_SCORE_SCATTER2 then
        return "Socre_WickedBlaze_Scatter2"
    end
    
    return nil
end

-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
-- function CodeGameScreenWickedBlazeMachine:getPreLoadSlotNodes()
--     local loadNode = CodeGameScreenWickedBlazeMachine.super.getPreLoadSlotNodes(self)

--     loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count = 1}
--     loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count = 1}

--     loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS1,count = 1}
--     loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS2,count = 1}
--     loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS3,count = 1}

--     loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_SCATTER2,count = 1}
    
--     return loadNode
-- end

--所有effect播放完之后调用
-- function CodeGameScreenWickedBlazeMachine:playEffectNotifyNextSpinCall()
--     self:checkTriggerOrInSpecialGame(function()
--         self:reelsDownDelaySetMusicBGVolume()
--     end)
--     CodeGameScreenWickedBlazeMachine.super.playEffectNotifyNextSpinCall(self)
-- end
--所有滚轴停止调用
function CodeGameScreenWickedBlazeMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)

    CodeGameScreenWickedBlazeMachine.super.slotReelDown(self)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local wildColumns = {}
    if selfData and selfData.wildColumns then
        wildColumns = selfData.wildColumns
    end

    local isError = false
    local wildCols = {}
    for colIndex,smallWildNode in pairs(self.m_smallWildNodeTab) do
        for k,wildNode in pairs(smallWildNode) do
            wildNode:setVisible(false)
        end
        isError = true
        --检测是否有没删除掉的列
        for k, iCol in pairs(wildColumns) do
            if iCol + 1 == colIndex then
                isError = false
                break
            end
        end
        wildCols[#wildCols + 1] = colIndex
    end

    --显示错误打印日志
    if isError and util_sendToSplunkMsg then
        local totalBetID = globalData.slotRunData:getCurTotalBet()
        local data = self.m_betCollectData[""..totalBetID]

        local str1 = "wildColumns:"..json.encode(wildColumns)
        local str2 = "collectData:"..json.encode(selfData.collectData)
        local str3 = "wildCols:"..json.encode(wildCols)
        local msg = "WickedBlaze serverData:"..str1..","..str2..","..str3.."\n"
        if data then
            msg = msg.."localData:"..json.encode(data).."\nudid:"..globalData.userRunData.userUdid
        end
       
        util_sendToSplunkMsg("WickedBlaze_654_luaError",msg)
    end

    for i,scatterNode in ipairs(self.m_scatterNodeTab) do
        local col = scatterNode.p_cloumnIndex
        local row = scatterNode.p_rowIndex
        local slotNode = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
        if slotNode then
            slotNode:setVisible(false)
            slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_SCATTER), TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            slotNode:initSlotNodeByCCBName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_SCATTER), TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        end
    end
    self:findChild("triggerEffect"):setVisible(false)
end
--
--单列滚动停止回调
--
function CodeGameScreenWickedBlazeMachine:slotOneReelDown(reelCol)    
    CodeGameScreenWickedBlazeMachine.super.slotOneReelDown(self,reelCol)
    local playSound = {bonusSound = 0,scatterSound = 0}
    if self.m_isNewReelQuickStop == nil or self.m_isNewReelQuickStop == false then 
        for k = 1, self.m_iReelRowNum do
            if  self:isCollectSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
                if symbolNode then
                    playSound.bonusSound = 1
                    symbolNode:runAnim("buling",false,function()
                        if symbolNode.p_symbolType ~= nil then
                            symbolNode:runAnim("idleframe",true)
                        end
                    end)
                end
            end
            if self.m_stcValidSymbolMatrix[k][reelCol] == self.SYMBOL_SCORE_SCATTER2 then
                local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
                if symbolNode then
                    playSound.scatterSound = 1
                    symbolNode:runAnim("buling")
                end
            end
        end
    end

    self:changeToWildSymbol(reelCol)

    local soundPath = nil
    if playSound.scatterSound == 1 then
        soundPath = "WickedBlazeSounds/music_WickedBlaze_Scatterbuling.mp3"
    elseif playSound.bonusSound == 1 then
        soundPath = "WickedBlazeSounds/music_WickedBlaze_bonusBuling.mp3"
    end

    if soundPath then
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
end

--[[
    变更固定wild列的信号值
]]
function CodeGameScreenWickedBlazeMachine:changeToWildSymbol(colIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end

    local wildColumns = selfData.wildColumns
    for k, iCol in pairs(wildColumns) do
        if iCol + 1 == colIndex then
            for iRow = 1, self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol + 1, iRow)
                if symbol then
                    symbol:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                end
            end
            break
        end
    end
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
]]
function CodeGameScreenWickedBlazeMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "WickedBlazeSounds/music_WickedBlaze_Scatterbuling.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWickedBlazeMachine:levelFreeSpinEffectChange()
    --是重连时在freespin里调这里，不用调，直接return
    if self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        return
    end

    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle2")

    self:clearWinLineEffect()
    self.m_freespinBar:setVisible(true)
    -- self.m_jackpotBar:setVisible(false)

    self:resetMaskLayerNodes()

    self:runCsbAction("idle_1")


    self.m_wickedBlazeNode:setPosition(cc.p(self:findChild("devil_2"):getPosition()))
    self:playWickedBlazeAni("actionframe_free_1",false,function ()
        self:playWickedBlazeAni("actionframe_free_2",true)
    end)
    --隐藏盘面不要的图标
    -- self:changeToFreespinHideRedundantSymbol()
    --修改总行数为freespin行数
    self:changeToFreespinRowNum()
    --修改盘面滚轴及图标
    self:changeReel()
    --更改裁切区域
    self:changeClipRegion()
    --修改滚轴属性为freespin盘面的
    self:changeReelAttributeToFreespin()
    --给freespin盘上面添加必要的图标
    -- self:addSymbolToFreespinLayer()

    --清除大wild
    self:removeAllBigWild(false)
    
    --重新添加大wild
    self:updateBigWildNode(false)
    self:updateCollectNode()
end
--切换freespin盘面之前，先隐藏普通盘面上的多余不用的图标
function CodeGameScreenWickedBlazeMachine:changeToFreespinHideRedundantSymbol()
    --隐藏第四行
    for col = 1,self.m_iReelColumnNum do
        self:hideSymbolByRowCol(col,4)
    end
end
--修改总行数为freespin行数
function CodeGameScreenWickedBlazeMachine:changeToFreespinRowNum()
    self.m_iReelRowNum = self.m_configData.m_freespinRowNum
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
end
--修改裁切区域
function CodeGameScreenWickedBlazeMachine:changeClipRegion()
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum
    end

    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x,
            y = rect.y,
            width = rect.width,
            height = self.m_fReelHeigth
        }
    )
end
--修改盘面滚轴及图标
function CodeGameScreenWickedBlazeMachine:changeReel()
    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i, self.m_iReelRowNum, true)
    end
end
--滚轴属性修改为freespin盘面的
function CodeGameScreenWickedBlazeMachine:changeReelAttributeToFreespin()
    for col = 1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[col]
        columnData:updateShowColCount(self.m_iReelRowNum)
    end
    local runData = self.m_configData.m_freespinReelRunDatas
    self:slotsReelRunData(runData,self.m_configData.p_bInclScatter
            ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
                ,self.m_configData.p_bPlayBonusAction)
end
--给freespin盘上面添加必要的图标
function CodeGameScreenWickedBlazeMachine:addSymbolToFreespinLayer()
    for col = 1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[col]
        for row = 1,reelColData.p_showGridCount do
            local slotNode = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
            if slotNode == nil then
                local symbolType = self:getOneNorSymbol()
                local parentData = self.m_slotParents[col]
                local halfNodeH = reelColData.p_showGridH * 0.5
                local showOrder = self:getBounsScatterDataZorder(symbolType)
                local node = self:getSlotNodeWithPosAndType(symbolType, row, col, false)
                parentData.slotParent:addChild(node, showOrder - row, col * SYMBOL_NODE_TAG + row)
                node.p_slotNodeH = reelColData.p_showGridH
                node.p_symbolType = symbolType
                node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
                node.p_reelDownRunAnima = parentData.reelDownAnima
                node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                node:setPositionY((row - 1) * reelColData.p_showGridH + halfNodeH)
            end
        end
    end
end
--随机一个普通图标
function CodeGameScreenWickedBlazeMachine:getOneNorSymbol()
    local symbolList = {0,1,2,3,4,5,6,7,8,9,10}
    return symbolList[math.random(1,#symbolList)]
end
--随机一个低分普通图标
function CodeGameScreenWickedBlazeMachine:getOneSmallNorSymbol()
    local symbolList = {5,6,7,8,9,10}
    return symbolList[math.random(1,#symbolList)]
end
---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWickedBlazeMachine:levelFreeSpinOverChangeEffect()
    
end

--盘面由freespin变为normal
function CodeGameScreenWickedBlazeMachine:freeSpinOverChangeToNormal()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle1")
    self:clearWinLineEffect()

    self.m_freespinBar:setVisible(false)
    -- self.m_jackpotBar:setVisible(true)
    self.m_jackpotBar:runCsbAction("actionframe",true)

    self:runCsbAction("idle_0")

    self.m_wickedBlazeNode:setPosition(cc.p(self:findChild("devil_1"):getPosition()))
    self:playWickedBlazeAni("idleframe",true)
    --修改总行数为normal行数
    self:changeToNormalRowNum()
    --修改盘面滚轴及图标
    self:changeReel()
    --更改裁切区域
    self:changeClipRegion()
    --滚轴属性修改为normal盘面的
    self:changeReelAttributeToNormal()

    --清除大wild
    self:removeAllBigWild(false)
    --重新添加大wild
    self:updateBigWildNode(false)
    self:updateCollectNode()
end

--修改总行数为normal行数
function CodeGameScreenWickedBlazeMachine:changeToNormalRowNum()
    self.m_iReelRowNum = self.m_configData.p_rowNum
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
end
--滚轴属性修改为normal盘面的
function CodeGameScreenWickedBlazeMachine:changeReelAttributeToNormal()
    for i = 1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData:updateShowColCount(self.m_iReelRowNum)
    end
    self:slotsReelRunData(self.m_configData.p_reelRunDatas,self.m_configData.p_bInclScatter
            ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
                ,self.m_configData.p_bPlayBonusAction)
end

--隐藏盘面图标
function CodeGameScreenWickedBlazeMachine:hideSymbolByRowCol(col, row)
    local slotParentData = self.m_slotParents[col]
    if slotParentData ~= nil then
        local slotParent = slotParentData.slotParent
        local slotParentBig = slotParentData.slotParentBig
        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j=1,#newChilds do
                childs[#childs+1] = newChilds[j]
            end
        end
        local clipChild = self.m_clipParent:getChildren()
        for i,v in ipairs(clipChild) do
            childs[#childs+1] = clipChild[i]
        end
        local index = 1
        while true do
            if index > #childs then
                break
            end
            local child = childs[index]
            if child.p_cloumnIndex == col and child.p_rowIndex == row then
                child:setVisible(false)
            end
            index = index + 1
        end
    end
end
function CodeGameScreenWickedBlazeMachine:showBonusGameView(effectData)
    self:clearCurMusicBg()
    self:playScatterTipMusicEffect()
    if self.m_scatterNodeTab and #self.m_scatterNodeTab > 0 then
        for i,scatterNode in ipairs(self.m_scatterNodeTab) do
            scatterNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
            scatterNode:runAnim("actionframe",false,function ()
                scatterNode:runAnim("idleframe")
            end)
        end
    else
        for row = 1,self.m_iReelRowNum do
            for col = 1,self.m_iReelColumnNum do
                local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    self:setSlotNodeEffectParent(slotNode)
                    slotNode:runAnim("actionframe",false,function ()
                        slotNode:runAnim("idleframe")
                    end)
                end
            end
        end
    end
    self:setCurrSpinMode(REWAED_SPIN_MODE)
    performWithDelay(self,function ()
        self:addWheelNode()
    end,self.m_configData.m_showWheelViewDelayTime)
end
function CodeGameScreenWickedBlazeMachine:showEffect_LineFrame(effectData)
    self.m_waitNode:stopAllActions()
    for i,smallWildNode in pairs(self.m_smallWildNodeTab) do
        for k,wildNode in pairs(smallWildNode) do
            wildNode:setVisible(false)
        end
    end

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end


    local featureDatas = self.m_runSpinResultData.p_features
    local delayTim = 0
    if featureDatas then
        local featureId = featureDatas[2]
        if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            delayTim = 2
        end
    end

    self:showLineFrame()

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.5)
    else
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,delayTim)
    end

    return true

end
----------- FreeSpin相关
-- 显示free spin
function CodeGameScreenWickedBlazeMachine:showEffect_FreeSpin(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
    end

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停掉背景音乐
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        self:clearCurMusicBg()
    end
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
            self:showFreeSpinView(effectData)
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            self:showFreeSpinView(effectData)
        end
        
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end
function CodeGameScreenWickedBlazeMachine:triggerFreeSpinCallFun()

    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)  -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode( FREE_SPIN_MODE )
    self.m_bProduceSlots_InFreeSpin = true
    -- self:resetMusicBg()
end
-- FreeSpinstart
function CodeGameScreenWickedBlazeMachine:showFreeSpinView(effectData)
    local showFSView = function ()
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            performWithDelay(self,function ()
                self:triggerFreeSpinCallFun()
                gLobalSoundManager:playSound("WickedBlazeSounds/Freegamesarecoming.mp3")
            end,self.m_configData.m_reelChangeWaitTime)
            gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_freespinStartViewShow.mp3")
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:resetMusicBg()
                self.m_jackpotBar:runCsbAction("over")
                self.m_freespinBar:setVisible(true)
                gLobalNoticManager:postNotification("WickedBlazeWheelView_closeView")
                performWithDelay(self,function ()
                    gLobalSoundManager:playSound("WickedBlazeSounds/NoonegonnahatethislovelynaughtyDevil.mp3")
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end, self.m_WheelViewOver2Time)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function()
        showFSView()
    end,self.m_configData.m_showFreespinViewDelayTime)
end
    
function CodeGameScreenWickedBlazeMachine:collectFreespinNum()
    local flyTime = 0
    for row = 1,self.m_iReelRowNum do
        for col = 1,self.m_iReelColumnNum do
            local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_SCATTER2 then
                local flyNode = util_createAnimation("Socre_WickedBlaze_Bonuslizi.csb")
                -- flyNode:playAction("collect",false)
                self.m_freespinBar:addChild(flyNode)
                local startWorldPos = self.m_clipParent:convertToWorldSpace(self:getNodePosByColAndRow(row,col))
                local startPos = self.m_freespinBar:convertToNodeSpace(startWorldPos)
                flyNode:setPosition(startPos)
                local endWorldPos = self.m_freespinBar:findChild("m_lb_num_2"):getParent():convertToWorldSpace(cc.p(self.m_freespinBar:findChild("m_lb_num_2"):getPosition()))
                local endPos = self.m_freespinBar:convertToNodeSpace(endWorldPos)
                -- flyTime = util_csbGetAnimTimes(flyNode.m_csbAct,"collect")
                -- local delay = cc.DelayTime:create(flyTime/2)
                if self:getCurrSpinMode() == FREE_SPIN_MODE and row <= 3 then
                    flyTime = self.m_configData.m_freespinBottomRowCollectParticleFlyTime
                else
                    if flyTime < self.m_configData.m_collectParticleFlyTime then
                        flyTime = self.m_configData.m_collectParticleFlyTime
                    end
                end
                local moveTo = cc.MoveTo:create(flyTime,endPos)
                local func = cc.CallFunc:create(function ()
                    flyNode:setVisible(false)
                end)
                local seq = cc.Sequence:create(moveTo,func)
                flyNode:runAction(seq)
                flyNode:findChild("Particle_1"):setPositionType(0)
                flyNode:findChild("Particle_1"):resetSystem()
                table.insert(self.m_freespinNumCollectLiziTab,flyNode)
            end
        end
    end
    if flyTime > 0 then
        gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_ParticleFly.mp3")
    end
    performWithDelay(self,function ()
        self.m_freespinBar:findChild("Particle_1"):setPositionType(0)
        self.m_freespinBar:findChild("Particle_1"):resetSystem()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:setClipScatterToReel()
        -- self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT ,self.COLLECT_FREESPIN_EFFECT})
    end,flyTime)
end
--轮盘转完触发freespin
function CodeGameScreenWickedBlazeMachine:wheelOverTriggerFreeSpin()
    self:featuresOverAddFreespinEffect()
    self:notifyGameEffectPlayComplete(GameEffect.EFFECT_BONUS)
end
--bonus玩法结束后添加freespin动画效果
function CodeGameScreenWickedBlazeMachine:featuresOverAddFreespinEffect()
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end

function CodeGameScreenWickedBlazeMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_freespinOverViewShow.mp3")
    
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.9,sy=0.9},704)
    performWithDelay(self,function ()
        self:freeSpinOverChangeToNormal()
        local totalBet = globalData.slotRunData:getCurTotalBet()
        if globalData.slotRunData.lastWinCoin > 5 * totalBet then
            gLobalSoundManager:playSound("WickedBlazeSounds/Excellent.mp3")
        end
    end,self.m_configData.m_reelChangeWaitTime)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWickedBlazeMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    return false -- 用作延时点击spin调用
end
--轮盘开始滚动
function CodeGameScreenWickedBlazeMachine:beginReel()
    self.m_curCollectColTab = {}
    self.m_curNoCollectColTab = {}
    self.m_flyTime = 0
    self.m_isHaveLeftCount = false
    self:removeAllCollectAction()
    self:updateCollectNode(false)
    self:beginReelUpdateAllWildFrame()
    self:beginReelRemoveAllScatter()

    CodeGameScreenWickedBlazeMachine.super.beginReel(self)
    
end
--开始滚动时判断更新wild边框
function CodeGameScreenWickedBlazeMachine:beginReelUpdateAllWildFrame()
    local totalBetID = globalData.slotRunData:getCurTotalBet()
    local data = self.m_betCollectData[""..totalBetID]
    local addBigWildColTab = {}
    if data then
        local leftCountsDatas = data.wildLeftCounts
        local isHaveLeftCount = false
        for i,counts in ipairs(leftCountsDatas) do
            if counts > 0 then
                isHaveLeftCount = true
                table.insert(addBigWildColTab,i)
                -- self:addBigWildFrame(i,true)
            end
        end
        if isHaveLeftCount == false then
            self:removeAllBigWild(true)
            self:updateCollectNodeNum(true)
        else
            self.m_isHaveLeftCount = true
            self:updateBigWildNode(true)
            for i,col in ipairs(addBigWildColTab) do
                if self.m_bigWildNodeTab[col] == nil then
                    --本轮有新出的大wild条，播音效
                    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_bigWildFire.mp3")
                    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                        self:playWickedBlazeAni("actionframe_base",false,function ()
                            self:playWickedBlazeAni("idleframe",true)
                        end)
                    else
                        self:playWickedBlazeAni("actionframe_free_3",false,function ()
                            self:playWickedBlazeAni("actionframe_free_2",true)
                        end)
                    end
                    gLobalSoundManager:playSound("WickedBlazeSounds/heiha.mp3")
                    break
                end
            end
        end
    else
        self:removeAllBigWild(true)
    end
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWickedBlazeMachine:addSelfEffect()
    -- bonus收集
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.COLLECT_EFFECT
    -- --添加长条wild
    -- if self.m_isNewReelQuickStop == nil or self.m_isNewReelQuickStop == false then
    --     local selfEffect = GameEffectData.new()
    --     selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    --     selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 1
    --     self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    --     selfEffect.p_selfEffectType = self.ADDBIGWILD_EFFECT
    -- end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local featureDatas = self.m_runSpinResultData.p_features
        if not featureDatas then
            return
        end
        for i=1,#featureDatas do
            local featureId = featureDatas[i]
            if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.COLLECT_FREESPIN_EFFECT
            end
        end
    end
    
 end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWickedBlazeMachine:MachineRule_playSelfEffect(effectData)
    -- bonus收集
    if effectData.p_selfEffectType == self.COLLECT_EFFECT then
        self:playCollectAni()
    end
    --显示大wild
    -- if effectData.p_selfEffectType == self.ADDBIGWILD_EFFECT then
    --     self:updateBigWildNode(true)
    -- end
    if effectData.p_selfEffectType == self.COLLECT_FREESPIN_EFFECT then
        gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_showFreespinMoreView.mp3")
        for row = 1,self.m_iReelRowNum do
            for col = 1,self.m_iReelColumnNum do
                local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_SCATTER2 then
                    self:setSlotNodetoClip(slotNode)
                    local zOrder = slotNode:getLocalZOrder() - SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
                    slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + zOrder) 
                    slotNode:runAnim("actionframe")
                end
            end
        end
        
        performWithDelay(self,function ()
            self:collectFreespinNum()
        end,self.m_configData.m_freespinMoreSymbolActionFlyTime)

        local time = 0.8
        if self.m_flyTime < time then
            self.m_flyTime = time
        end

        self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT ,self.COLLECT_FREESPIN_EFFECT})
    end
	return true
end
--将图标放到clip层（加次数的scatter用的）
function CodeGameScreenWickedBlazeMachine:setSlotNodetoClip(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = slotNode:getPositionY()
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX,slotNode.m_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode,self:getSlotNodeEffectZOrder(slotNode))
    table.insert(self.m_addNumScatterNodeTab,slotNode)

    return slotNode
end
--将放到clip层的图标放回滚轴（加次数的scatter用的）
function CodeGameScreenWickedBlazeMachine:setClipScatterToReel()
    for i,addNumScatterNode in ipairs(self.m_addNumScatterNodeTab) do
        local preParent = addNumScatterNode.m_preParent
        if preParent ~= nil then
            if preParent ~= self.m_clipParent then
                addNumScatterNode.p_layerTag = addNumScatterNode.m_preLayerTag
            end
            local nZOrder = addNumScatterNode.m_showOrder
            if preParent == self.m_clipParent then
                nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + addNumScatterNode.p_showOrder
            end
            util_changeNodeParent(preParent,addNumScatterNode,nZOrder)
            addNumScatterNode:setPosition(addNumScatterNode.m_preX, addNumScatterNode.m_preY)
            addNumScatterNode:runIdleAnim()
        end
    end
    self.m_addNumScatterNodeTab = {}
end
--新快停逻辑
function CodeGameScreenWickedBlazeMachine:newQuickStopReel(index)
    self.m_waitNode:stopAllActions()
    CodeGameScreenWickedBlazeMachine.super.newQuickStopReel(self,index)
    self:updateBigWildNode(false)
    -- self:playWickedBlazeAni("idleframe",true)
    
end
-- 通知某种类型动画播放完毕
function CodeGameScreenWickedBlazeMachine:notifyGameEffectPlayComplete(param)
    local effectType
    if type(param) == "table" then
        effectType = param[1]
    else
        effectType = param
    end
    local effectLen = #self.m_gameEffects
    if effectType == nil or effectType == EFFECT_NONE or effectLen == 0 then
        return
    end

    if effectType == GameEffect.EFFECT_QUEST_DONE then
        return
    end

    for i=1,effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == effectType and effectData.p_isPlay == false then
            if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT then
                if effectData.p_selfEffectType == param[2] then
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 继续播放动画
                    break
                end
            else
                effectData.p_isPlay = true
                self:playGameEffect() -- 继续播放动画
                break
            end
        end
    end

end
--获得信号块层级
function CodeGameScreenWickedBlazeMachine:getBounsScatterDataZorder(symbolType)
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER
        or symbolType == self.SYMBOL_SCORE_SCATTER2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==  self.SYMBOL_SCORE_BONUS1
        or symbolType ==  self.SYMBOL_SCORE_BONUS2
        or symbolType ==  self.SYMBOL_SCORE_BONUS3 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分值越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order
end
--显示jackpot弹框
function CodeGameScreenWickedBlazeMachine:showJackpotLayer(func)
    self:clearCurMusicBg()
    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    local jackPotWinView = util_createView("CodeWickedBlazeSrc.WickedBlazeJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function() return false end
    end
    gLobalViewManager:showUI(jackPotWinView)

    local jackpotType = self.m_runSpinResultData.p_selfMakeData.turn
    local index = 1
    if jackpotType == "Grand" then
        index = 4
    elseif jackpotType == "Major" then
        index = 3
    elseif jackpotType == "Minor" then
        index = 2
    elseif jackpotType == "Mini" then
        index = 1
    end
    -- local bonuscoins = self.m_runSpinResultData.p_bonusWinCoins
    local winCoin = self.m_runSpinResultData.p_winAmount
    jackPotWinView:initViewData(self,index,winCoin,function ()
        gLobalNoticManager:postNotification("WickedBlazeWheelView_closeView")
        gLobalNoticManager:postNotification("WickedBlazeJackPotBarView_hideEffect")
        globalData.slotRunData.lastWinCoin = winCoin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{winCoin,true,true})
        performWithDelay(self,function ()
            self:notifyGameEffectPlayComplete({GameEffect.EFFECT_BONUS})
        end, self.m_WheelViewOver2Time)
        self:resetMusicBg()
    end)
    gLobalNoticManager:postNotification("WickedBlazeJackPotBarView_showEffect",{jackpotType})
end
--判断是不是收集图标
function CodeGameScreenWickedBlazeMachine:isCollectSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS1 or 
        symbolType == self.SYMBOL_SCORE_BONUS2 or 
        symbolType == self.SYMBOL_SCORE_BONUS3 then
        return true
    end
    return false
end
--播放收集动画
function CodeGameScreenWickedBlazeMachine:playCollectAni()
    --计算有收集图标的列，并开始收集
    for col = 1, self.m_iReelColumnNum do
        local isHaveCollectSymbol = false
        for row = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
            if slotNode and self:isCollectSymbol(slotNode.p_symbolType) then
                slotNode:runAnim("actionframe")
                performWithDelay(self,function ()
                    self:playCollectParticle(col,row)
                end,self.m_configData.m_bonusActionToCollectTime)
                isHaveCollectSymbol = true
            end
        end
        if isHaveCollectSymbol == true then
            gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_ParticleFly.mp3")
            table.insert(self.m_curCollectColTab,col)
        else
            table.insert(self.m_curNoCollectColTab,col)
        end
    end
    -- 2.5 1.5
    if #self.m_curCollectColTab > 0 then
        local time = 2

        local isHaveCollectFull = false
        local data = self.m_runSpinResultData.p_selfMakeData.collectData
        for i,wildLeft in ipairs(data.wildLeftCounts) do
            if wildLeft == self.m_configData.m_collectNodeFirecrackerNum then
                isHaveCollectFull = true
                break
            end
        end
        --如果有收集满的列，则开始非收集列炮仗的出现
        if isHaveCollectFull == true then
            --判读有没有要出炮仗的列
            local paozhangAppearColTab = {}--存储要出炮仗的列
            for i,v in ipairs(self.m_curNoCollectColTab) do
                if data.wildLeftCounts[v] == self.m_configData.m_collectNodeFirecrackerNum then
                    time = 3.5
                    break
                end
            end 
        end

        if self.m_flyTime < time then
            self.m_flyTime = time
        end
    end
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
        self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.COLLECT_EFFECT})
    else
        --如果没有要收集的，则进入下一个effect
        if #self.m_curCollectColTab == 0 then
            self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.COLLECT_EFFECT})
        end
    end
end
--播放收集粒子
function CodeGameScreenWickedBlazeMachine:playCollectParticle(col,row)
    local particleNode = util_createAnimation("Socre_WickedBlaze_Bonuslizi.csb")
    local startPos = self:getNodePosByColAndRow(row,col)
    local endWorldPos = self:findChild("shouji_"..col):getParent():convertToWorldSpace(cc.p(self:findChild("shouji_"..col):getPosition()))
    local endPos = self.m_clipParent:convertToNodeSpace(endWorldPos)
    self.m_clipParent:addChild(particleNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
    particleNode:setPosition(startPos)
    particleNode:findChild("Particle_1"):setPositionType(0)
    particleNode:findChild("Particle_1"):resetSystem()

    local moveTime = self.m_configData.m_collectParticleFlyTime
    if self:getCurrSpinMode() == FREE_SPIN_MODE and row <= 3 then
        moveTime = self.m_configData.m_freespinBottomRowCollectParticleFlyTime
    end
    local moveTo = cc.MoveTo:create(moveTime,endPos)
    local func = cc.CallFunc:create(function()
        particleNode:setVisible(false)
        local collectNode = self.m_collectNodeTab[col]
        collectNode:findChild("Particle_1"):setVisible(true)
        collectNode:findChild("Particle_1"):setPositionType(0)
        collectNode:findChild("Particle_1"):resetSystem()
        --收集粒子飞完，开始播收集标记上的炮仗动画
        self:CollectParticleEndOneCollectNodePaozhangAppear(col)
    end)
    local seq = cc.Sequence:create(moveTo,func)
    particleNode:runAction(seq)
    table.insert(self.m_paozhangCollectLiziTab,particleNode)
end
--收集粒子飞完后 一个收集标记上的炮仗出现
function CodeGameScreenWickedBlazeMachine:CollectParticleEndOneCollectNodePaozhangAppear(col)
    local collectNode = self.m_collectNodeTab[col]

    local data = self.m_runSpinResultData.p_selfMakeData.collectData
    local collectNum = 0
    local wildLeftCount = 0
    if data ~= nil then
        collectNum = data.collects[col]
        wildLeftCount = data.wildLeftCounts[col]
    end
    --检测从第几个炮仗出现
    local index = 0
    for i = 1,self.m_configData.m_collectNodeFirecrackerNum do
        if collectNode.paozhangTab[i]:isVisible() == false then
            index = i
            break
        end
    end

    if index > 0 then
        local function paozhangAppear()
            local paozhang = collectNode.paozhangTab[index]
            paozhang:setVisible(true)
            gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_paozhangAppear.mp3")
            paozhang:playAction("start")
            paozhang.m_curAniName = "start"

            index = index + 1
            if index > collectNum then
                --炮仗出现结束
                collectNode:stopAction(collectNode.m_scheduleAction)
                collectNode.m_scheduleAction = nil
                self:addDelayFuncAct(paozhang,"start",function ()
                    self:CollectParticleEndOneCollectNodePaozhangAppearEnd(col)
                end)
            end
        end
        collectNode.m_scheduleAction = util_schedule(collectNode,paozhangAppear,0.1)
    end
end
--收集粒子飞完后 一个收集标记上的炮仗出现结束
function CodeGameScreenWickedBlazeMachine:CollectParticleEndOneCollectNodePaozhangAppearEnd(col)
    local collectNode = self.m_collectNodeTab[col]
    local data = self.m_runSpinResultData.p_selfMakeData.collectData
    local collectNum = 0
    local wildLeftCount = 0
    if data ~= nil then
        collectNum = data.collects[col]
        wildLeftCount = data.wildLeftCounts[col]
    end
    --收集满了
    if wildLeftCount == self.m_configData.m_collectNodeFirecrackerNum then
        --出数字
        collectNode:findChild("shuziNode"):setVisible(true)
        collectNode:findChild("m_lb_num"):setString(wildLeftCount)
        gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_collectNodeNumChange.mp3")
        collectNode:playAction("start",false,function ()
            collectNode:playAction("idle2",true)
            self:CollectParticleEndOneCollectNodeCollectEnd(col)
        end)
        -- self:addBigWildFrame(col)
        --点火
        for i = 1,self.m_configData.m_collectNodeFirecrackerNum do
            if collectNode.paozhangTab[i].m_curAniName ~= "idle2" then
                collectNode.paozhangTab[i]:playAction("idle2",true)
                collectNode.paozhangTab[i].m_curAniName = "idle2"
            end
        end
    else
        self:CollectParticleEndOneCollectNodeCollectEnd(col)
    end
end
--一个收集图标彻底收集结束
function CodeGameScreenWickedBlazeMachine:CollectParticleEndOneCollectNodeCollectEnd(col)
    --收集结束的列清除记录
    for i,v in ipairs(self.m_curCollectColTab) do
        if v == col then
            table.remove(self.m_curCollectColTab,i)
            break
        end
    end
    --所有该收集的列都收集完
    if #self.m_curCollectColTab == 0 then
        local isHaveCollectFull = false
        local data = self.m_runSpinResultData.p_selfMakeData.collectData
        for i,wildLeft in ipairs(data.wildLeftCounts) do
            if wildLeft == self.m_configData.m_collectNodeFirecrackerNum then
                isHaveCollectFull = true
                break
            end
        end
        --如果有收集满的列，则开始非收集列炮仗的出现
        if isHaveCollectFull == true then
            --判读有没有要出炮仗的列
            local paozhangAppearColTab = {}--存储要出炮仗的列
            for i,v in ipairs(self.m_curNoCollectColTab) do
                if data.wildLeftCounts[v] == self.m_configData.m_collectNodeFirecrackerNum then
                    table.insert(paozhangAppearColTab,v)
                end
            end
            if #paozhangAppearColTab > 0 then
                self.m_curNoCollectColTab = paozhangAppearColTab
                for i,v in ipairs(self.m_curNoCollectColTab) do
                    self:OneNoCollectNodePaozhangAppear(v)
                end
            else
                --没有需要出炮仗的列，结束收集流程
                if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
                    self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.COLLECT_EFFECT})
                end
            end
        else--如果没有收集满的列，则结束收集流程
            if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
                self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.COLLECT_EFFECT})
            end
        end
    end
end
--本轮没收集的一列 收集标志上的炮仗出现
function CodeGameScreenWickedBlazeMachine:OneNoCollectNodePaozhangAppear(col)
    local collectNode = self.m_collectNodeTab[col]

    --检测从第几个炮仗出现
    local index = 0
    for i = 1,self.m_configData.m_collectNodeFirecrackerNum do
        if collectNode.paozhangTab[i]:isVisible() == false then
            index = i
            break
        end
    end

    if index > 0 then--有没出现的炮仗
        local function paozhangAppear()
            local paozhang = collectNode.paozhangTab[index]
            paozhang:setVisible(true)
            gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_paozhangAppear.mp3")
            paozhang:playAction("start")
            paozhang.m_curAniName = "start"

            index = index + 1
            if index > self.m_configData.m_collectNodeFirecrackerNum then
                --炮仗出现结束
                collectNode:stopAction(collectNode.m_scheduleAction)
                collectNode.m_scheduleAction = nil
                self:addDelayFuncAct(paozhang,"start",function ()
                    self:OneNoCollectNodePaozhangAppearEnd(col)
                end)
            end
        end
        collectNode.m_scheduleAction = util_schedule(collectNode,paozhangAppear,0.1)
    else
        --没有没出现的炮仗，直接调用出现结束
        self:OneNoCollectNodePaozhangAppearEnd(col)
    end
end
--本轮没收集的列 收集标记上的炮仗出现结束
function CodeGameScreenWickedBlazeMachine:OneNoCollectNodePaozhangAppearEnd(col)
    local collectNode = self.m_collectNodeTab[col]
    local data = self.m_runSpinResultData.p_selfMakeData.collectData
    local collectNum = 0
    local wildLeftCount = 0
    if data ~= nil then
        collectNum = data.collects[col]
        wildLeftCount = data.wildLeftCounts[col]
    end
    collectNode:findChild("shuziNode"):setVisible(true)
    collectNode:findChild("m_lb_num"):setString(wildLeftCount)
    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_collectNodeNumChange.mp3")
    collectNode:playAction("start",false,function ()
        collectNode:playAction("idle2",true)
        self:OneNoCollectNodeCollectEnd(col)
    end)
    --点火
    for i = 1,self.m_configData.m_collectNodeFirecrackerNum do
        if collectNode.paozhangTab[i].m_curAniName ~= "idle2" then
            collectNode.paozhangTab[i]:playAction("idle2",true)
            collectNode.paozhangTab[i].m_curAniName = "idle2"
        end
    end
end
--本轮没收集图标的列 收集标记上的炮仗出现的流程彻底结束
function CodeGameScreenWickedBlazeMachine:OneNoCollectNodeCollectEnd(col)
    --动画结束的列清除记录
    for i,v in ipairs(self.m_curNoCollectColTab) do
        if v == col then
            table.remove(self.m_curNoCollectColTab,i)
            break
        end
    end

    if #self.m_curNoCollectColTab == 0 then
        --结束收集流程
        if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
            self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.COLLECT_EFFECT})
        end
    end
end
--清除停止所有的收集相关动画及数据
function CodeGameScreenWickedBlazeMachine:removeAllCollectAction()
    for i,lizi in ipairs(self.m_paozhangCollectLiziTab) do
        lizi:removeFromParent()
    end
    self.m_paozhangCollectLiziTab = {}
    for i,collectNode in ipairs(self.m_collectNodeTab) do
        if collectNode.m_scheduleAction then
            collectNode:stopAction(collectNode.m_scheduleAction)
            collectNode.m_scheduleAction = nil
        end
        collectNode:playAction("idle1")
        collectNode:findChild("Particle_1"):setVisible(false)
        for j,paozhang in ipairs(collectNode.paozhangTab) do
            self:stopDelayFuncAct(paozhang)
            paozhang:playAction("idle1")
            paozhang.m_curAniName = "idle1"
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    for i,freespinNumCollectLizi in ipairs(self.m_freespinNumCollectLiziTab) do
        freespinNumCollectLizi:removeFromParent()
    end
    self.m_freespinNumCollectLiziTab = {}
    self:setClipScatterToReel()
end

--更新收集标记 的显示
function CodeGameScreenWickedBlazeMachine:updateCollectNode(isVisibleZero)
    local totalBetID = globalData.slotRunData:getCurTotalBet()
    local data = self.m_betCollectData[""..totalBetID]

    for i,collectNode in ipairs(self.m_collectNodeTab) do
        local collectNum = 0
        local wildLeftCount = 0
        if data ~= nil then
            collectNum = data.collects[i]
            wildLeftCount = data.wildLeftCounts[i]
            if wildLeftCount > 0 then
                collectNum = wildLeftCount
            end
        end
        for j = 1,collectNum do
            self:stopDelayFuncAct(collectNode.paozhangTab[j])
            if collectNode.paozhangTab[j]:isVisible() == false then
                collectNode.paozhangTab[j]:setVisible(true)
                -- collectNode.paozhangTab[j]:playAction("start")
                -- collectNode.paozhangTab[j].m_curAniName = "start"
                if wildLeftCount > 0 then
                    -- self:addDelayFuncAct(collectNode.paozhangTab[j],"start",function ()
                        collectNode.paozhangTab[j]:playAction("idle2",true)
                        collectNode.paozhangTab[j].m_curAniName = "idle2"
                    -- end)
                else
                    -- self:addDelayFuncAct(collectNode.paozhangTab[j],"start",function ()
                        collectNode.paozhangTab[j]:playAction("idle1")
                        collectNode.paozhangTab[j].m_curAniName = "idle1"
                    -- end)
                end
            else
                if wildLeftCount > 0 then
                    -- if collectNode.paozhangTab[j].m_curAniName ~= "idle2" then
                        collectNode.paozhangTab[j]:playAction("idle2",true)
                        collectNode.paozhangTab[j].m_curAniName = "idle2"
                    -- end
                else
                    -- if collectNode.paozhangTab[j].m_curAniName ~= "idle1" then
                        collectNode.paozhangTab[j]:playAction("idle1")
                        collectNode.paozhangTab[j].m_curAniName = "idle1"
                    -- end
                end
            end
        end
        for i = collectNum + 1,self.m_configData.m_collectNodeFirecrackerNum do
            self:stopDelayFuncAct(collectNode.paozhangTab[i])
            collectNode.paozhangTab[i]:setVisible(false)
        end
    end
    self:updateCollectNodeNum(nil,isVisibleZero)
end
--更新收集标记上的数字显示
function CodeGameScreenWickedBlazeMachine:updateCollectNodeNum(isBeginReel,isVisibleZero)
    local totalBetID = globalData.slotRunData:getCurTotalBet()
    local data = self.m_betCollectData[""..totalBetID]
    for i,collectNode in ipairs(self.m_collectNodeTab) do
        local wildLeftCount = 0
        if data ~= nil then
            wildLeftCount = data.wildLeftCounts[i]
        end
        collectNode:findChild("m_lb_num"):setString(wildLeftCount)
        if wildLeftCount > 0 then
            collectNode:findChild("shuziNode"):setVisible(true)
            -- if wildLeftCount == self.m_configData.m_collectNodeFirecrackerNum then
                -- collectNode:playAction("start",false,function ()
                    collectNode:playAction("idle2",true)
                -- end)
            -- end
            -- self:addBigWildFrame(i)
        else
            -- collectNode:playAction("over",false,function ()
            local isHaveBigWild = false
            if isVisibleZero then
                if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.wildColumns then
                    local data = self.m_runSpinResultData.p_selfMakeData.wildColumns
                    for j,severCol in ipairs(data) do
                        if severCol + 1 == i then
                            isHaveBigWild = true
                            break
                        end
                    end
                end
            end
            if isHaveBigWild == false then
                collectNode:findChild("shuziNode"):setVisible(false)
                collectNode:playAction("idle1",true)
            else
                if isBeginReel == true then
                    collectNode:playAction("over",false,function ()
                        collectNode:findChild("shuziNode"):setVisible(false)
                    end)
                else
                    collectNode:findChild("shuziNode"):setVisible(true)
                    collectNode:playAction("idle2",true)
                end
            end
            -- end)
        end
    end
end

--更新大wild显示  isPlayAni是否播放动画
function CodeGameScreenWickedBlazeMachine:updateBigWildNode(isPlayAni)
    local totalBetID = globalData.slotRunData:getCurTotalBet()
    local data = self.m_betCollectData[""..totalBetID]
    if isPlayAni == nil then
        isPlayAni = true
    end
    if isPlayAni == true then
        if data then
            local leftCountsDatas = data.wildLeftCounts
            local delay = 0
            for col,leftCounts in ipairs(leftCountsDatas) do
                if leftCounts > 0 then
                    self:firecrackerBlast(col,isPlayAni)
                end
            end
        end
    else
        if self.m_runSpinResultData.p_selfMakeData then
            local data = self.m_runSpinResultData.p_selfMakeData.wildColumns
            local delay = 0
            local isPlayAni = false
            if data then
                for i,severCol in ipairs(data) do
                    self:addWildByCol(severCol + 1,isPlayAni)
                end
            end
        end
    end

end
-- 某一列收集的炮仗爆炸一个 然后出现大wild
function CodeGameScreenWickedBlazeMachine:firecrackerBlast(col,isPlayAni)
    if isPlayAni == nil then
        isPlayAni = true
    end
    local paozhangTab = self.m_collectNodeTab[col].paozhangTab
    local aniTime = 0--爆炸动画时间

    --这里取显示的最后一个爆炸，不能取数值（数值是最终值，这里可能不是最终值）
    for i = #paozhangTab,1,-1 do
        if paozhangTab[i]:isVisible() == true then
            --就这个爆炸了
            if isPlayAni == true then
                aniTime = util_csbGetAnimTimes(paozhangTab[i].m_csbAct,"over")
                paozhangTab[i]:playAction("over",false,function ()
                    paozhangTab[i]:setVisible(false)
                end)
                paozhangTab[i].m_curAniName = "over"
            else
                paozhangTab[i]:setVisible(false)
            end
            --显示数字减1
            local currNum = tonumber(self.m_collectNodeTab[col]:findChild("m_lb_num"):getString())
            self.m_collectNodeTab[col]:findChild("m_lb_num"):setString(currNum - 1)
            -- gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_collectNodeNumChange.mp3")
            -- if currNum - 1 <= 0 then
            --     self.m_collectNodeTab[col]:playAction("over",false,function ()
            --         self.m_collectNodeTab[col]:findChild("shuziNode"):setVisible(false)
            --     end)
            -- end
            break
        end
    end
    
    --已经有了整列小wild,直接显示出来
    if self.m_smallWildNodeTab[col] then
        for i,wildNode in ipairs(self.m_smallWildNodeTab[col]) do
            wildNode:setVisible(true)
        end
    else
        performWithDelay(self.m_waitNode,function ()
            self:addWildByCol(col,isPlayAni)
        end,aniTime)
    end
    
end
-- 某一列添加大wild  isPlayAni是否播放动画
function CodeGameScreenWickedBlazeMachine:addWildByCol(col,isPlayAni)
    if self.m_bigWildNodeTab[col] == nil then
        if isPlayAni == nil then
            isPlayAni = true
        end
        local bigWild = util_createAnimation("Socre_WickedBlaze_Wild2_"..self.m_iReelRowNum..".csb")
        self.m_effectNode:addChild(bigWild,  SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 100 - self.m_iReelRowNum - 1 + col, SYMBOL_NODE_TAG)
        bigWild:setPosition(self:getNodePosByColAndRow(1,col))
        if isPlayAni then
            bigWild:playAction("actionframe",false)
            self:addDelayFuncAct(bigWild,"actionframe",function ()
                bigWild:setVisible(false)
                self:addSmallWildByCol(col)
            end)
        else
            bigWild:setVisible(false)
            self:addSmallWildByCol(col)
        end

        self.m_bigWildNodeTab[col] = bigWild
    else
        self:stopDelayFuncAct(self.m_bigWildNodeTab[col])
        self.m_bigWildNodeTab[col]:setVisible(false)
        self:addSmallWildByCol(col)
    end
end
--创建一列小wild
function CodeGameScreenWickedBlazeMachine:addSmallWildByCol(col)
    --添加一列wild
    if self.m_smallWildNodeTab[col] == nil then
        local smallWildNodeTab = {}
        for row = 1,self.m_iReelRowNum do
            local wild = util_createAnimation("Socre_WickedBlaze_Wild.csb") --self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, row, col)
            self.m_effectNode:addChild(wild,  SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 120 - self.m_iReelRowNum - 1 + col, SYMBOL_NODE_TAG)
            wild:setPosition(self:getNodePosByColAndRow(row,col))
            wild:runCsbAction("idleframe")
            table.insert(smallWildNodeTab,wild)
        end
        self.m_smallWildNodeTab[col] = smallWildNodeTab
    else
        local smallWildNodeTab = self.m_smallWildNodeTab[col]
        for i,wildNode in ipairs(smallWildNodeTab) do
            wildNode:setVisible(true)
        end
    end
end
--添加边框特效
function CodeGameScreenWickedBlazeMachine:addBigWildFrame(col)
    if self.m_bigWildFrameNodeTab[col] == nil then
        local bigWildFrame = util_createAnimation("Socre_WickedBlaze_Wild3_"..self.m_iReelRowNum..".csb")
        self.m_effectNode:addChild(bigWildFrame,  SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 110 - self.m_iReelRowNum - 1 + col , SYMBOL_NODE_TAG)
        bigWildFrame:setPosition(self:getNodePosByColAndRow(1,col))
        self.m_bigWildFrameNodeTab[col] = bigWildFrame
        self.m_bigWildFrameNodeTab[col]:playAction("idleframe",true)
    end
end
--[[
    @desc: 获得轮盘的位置
]]
function CodeGameScreenWickedBlazeMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end
--删除所有大wild
function CodeGameScreenWickedBlazeMachine:removeAllBigWild(isPlayAni)
    for col = 1,self.m_iReelColumnNum do
        self:removeBigWildByCol(col,isPlayAni)
    end

    self.m_smallWildNodeTab = {}
    self.m_bigWildFrameNodeTab = {}

    if isPlayAni then
        self:delayCallBack(10 / 60,function()
            self.m_effectNode:removeAllChildren(true)
            self.m_bigWildNodeTab = {}
        end)
    else
        self.m_effectNode:removeAllChildren(true)
        self.m_bigWildNodeTab = {}
    end
end

--[[
    延迟回调
]]
function CodeGameScreenWickedBlazeMachine:delayCallBack(time, func)
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
--删除某一列大wild  isPlayAni是否播动画
function CodeGameScreenWickedBlazeMachine:removeBigWildByCol(col,isPlayAni)
    if isPlayAni == nil then
        isPlayAni = true
    end
    if self.m_bigWildNodeTab[col] ~= nil then
        local bigWild = self.m_bigWildNodeTab[col]
        if isPlayAni then
            bigWild:setVisible(true)
            bigWild:playAction("over")
            self:addDelayFuncAct(bigWild,"over",function ()
                bigWild:setVisible(false)
            end)
        else
            bigWild:setVisible(false)
        end
    end
end

--更改bet时调用
function CodeGameScreenWickedBlazeMachine:betChangeNotify(isLevelUp)
    if isLevelUp then

    else
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        self:removeAllBigWild(false)
        self:removeAllCollectAction()
        self:updateCollectNode(false)
    end
end
--添加转盘
function CodeGameScreenWickedBlazeMachine:addWheelNode()
    gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_juchazi.mp3")
    self:playWickedBlazeAni("actionframe_guochang",false,function ()
        self:playWickedBlazeAni("idleframe",true)
    end)

    performWithDelay(self,function ()
        local wheelNode = util_createView("CodeWickedBlazeSrc.WickedBlazeWheelView",self)
        self:findChild("wheelNode"):addChild(wheelNode)
        self:resetMusicBg()
    end,self.m_configData.m_startShowWheelFrame / 30)
end
--点击轮盘后获得数据解析
function CodeGameScreenWickedBlazeMachine:SpinResultParseResultData(spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
end

--添加动画回调(用延迟)
function CodeGameScreenWickedBlazeMachine:addDelayFuncAct(animationNode,animationName,func)
    self:stopDelayFuncAct(animationNode)
    animationNode.m_runDelayFuncAct = performWithDelay(animationNode,function ()
        animationNode.m_runDelayFuncAct = nil
        if func then
            func()
        end
    end,util_csbGetAnimTimes(animationNode.m_csbAct,animationName))
end
--停止动画回调
function CodeGameScreenWickedBlazeMachine:stopDelayFuncAct(animationNode)
    if animationNode and animationNode.m_runDelayFuncAct then
        animationNode:stopAction(animationNode.m_runDelayFuncAct)
        animationNode.m_runDelayFuncAct = nil
    end
end

function CodeGameScreenWickedBlazeMachine:playEffectNotifyNextSpinCall( )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE then

        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime() + self.m_flyTime

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

end
return CodeGameScreenWickedBlazeMachine