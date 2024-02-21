---
-- island li
-- 2019年1月26日
-- CodeGameScreenFruitFarmMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local FruitFarmBaseData = require "CodeFruitFarmSrc.FruitFarmBaseData"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenFruitFarmMachine = class("CodeGameScreenFruitFarmMachine", BaseFastMachine)

CodeGameScreenFruitFarmMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenFruitFarmMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenFruitFarmMachine.SYMBOL_SMALL_FIX_BONUS = 94  
CodeGameScreenFruitFarmMachine.SYMBOL_SMALL_FIX_BONUS_SCORE = 100  
CodeGameScreenFruitFarmMachine.SYMBOL_SMALL_FIX_MINI = 101
CodeGameScreenFruitFarmMachine.SYMBOL_SMALL_FIX_MINOR = 102
CodeGameScreenFruitFarmMachine.SYMBOL_SMALL_FIX_MAJOR = 103
CodeGameScreenFruitFarmMachine.SYMBOL_SMALL_FIX_GRAND = 104


-- CodeGameScreenFruitFarmMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
-- CodeGameScreenFruitFarmMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenFruitFarmMachine.BASEGAME_BOUNSCOLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenFruitFarmMachine.BASEGAME_BOUNSSCORE_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1 -- 自定义动画的标识
CodeGameScreenFruitFarmMachine.BASEGAME_BOUNSJACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 2 -- 自定义动画的标识

local FIT_HEIGHT_MAX = 1370
local FIT_HEIGHT_MIN = 1136

CodeGameScreenFruitFarmMachine.m_arrNormalSymbol =
{
    "Socre_FruitFarm_1",
    "Socre_FruitFarm_2",
    "Socre_FruitFarm_3",
    "Socre_FruitFarm_4",
    "Socre_FruitFarm_5",
    "Socre_FruitFarm_6",
    "Socre_FruitFarm_7",
    "Socre_FruitFarm_8",
    "Socre_FruitFarm_9",
    "Socre_FruitFarm_10",
}

local node_statue = {
    idle = 1,       --idle状态
    open = 2,       --打开
    openIdle = 3,   --打开的idle
    over = 4        --关闭
}

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}


-- 构造函数
function CodeGameScreenFruitFarmMachine:ctor()
    self.m_isOnceClipNode = false
    BaseFastMachine.ctor(self)


	--init
	self:initGame()
end

function CodeGameScreenFruitFarmMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FruitFarmConfig.csv", "LevelFruitFarmConfig.lua")
	--初始化基本数据
    self.m_spine_num = 0
    self.m_isInFree = false
    self.m_iReelRowMaxNum = 8
    self.m_iReelRowMinNum = 3
    self.m_curBounsWinCoins = 0  --本次滚动bouns的赢钱的总数
    self.m_effct_time = 0  --记录bouns动效的时间
    self.m_bIsBouns = false
    self.m_iReelRowMaxTab = {false, false, false, false, false}
    self.m_bounsCollect = nil  --baseGame bouns图标收集数据
    self.m_isChangeBgMusic = false
    self.m_isFeatureOverBigWinInFree = true
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
    -- 中奖音效
    self.m_winPrizeSounds = {}
    for i = 1, 3 do
        self.m_winPrizeSounds[#self.m_winPrizeSounds + 1] = "FruitFarmSounds/fruitFarm_winLine_" .. i .. ".mp3"
    end
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFruitFarmMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FruitFarm"  
end




function CodeGameScreenFruitFarmMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_FruitFarmView = util_createView("CodeFruitFarmSrc.FruitFarmView")
    -- self:findChild("xxxx"):addChild(self.m_FruitFarmView)

    --jackPot
    self.m_jackPotBar = util_createView("CodeFruitFarmSrc.FruitFarmJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:updateJackpotInfo()
    self.m_jackPotBar:initMachine(self)

    --灯光
    self.m_bgLight = util_createAnimation("FruitFarm_Bg_Light.csb")
    self:findChild("Light"):addChild(self.m_bgLight)
    self.m_bgLight:playAction("idle", true)
    self.m_bgLight.status = node_statue.idle
    self:runCsbAction("idle_cloes")
    util_setCascadeOpacityEnabledRescursion(self:findChild("Light"), true)


    self.m_colDoor_num = 5  --每列door的个数
    --顶部的花
    self.m_topFlower_num = 3  --数量
    self.m_topFlower_tab = {}
    self.m_jiMan_tab = {}
    for fIndex =1 ,self.m_topFlower_num do
        self.m_topFlower_tab[fIndex] = util_createView("CodeFruitFarmSrc.FruitFarmTopFlower")
        self:findChild("Node_TopFlower_"..fIndex):addChild(self.m_topFlower_tab[fIndex])

        --升到最高行背景
        self.m_jiMan_tab[fIndex] = util_createAnimation("WinFrameFruitFarm_run_JiMan.csb")
        self:findChild("bg_reel_"..fIndex):addChild(self.m_jiMan_tab[fIndex])
        self.m_jiMan_tab[fIndex]:playAction("idle_over")
        self.m_jiMan_tab[fIndex].status = node_statue.idle
        util_setCascadeOpacityEnabledRescursion(self.m_jiMan_tab[fIndex], true)
        --self.m_jiMan_tab[fIndex]:
    end

    --分割线
    self.m_fenGe_tab = {}
    for index =1,self.m_topFlower_num do
        self.m_fenGe_tab[index] = util_createAnimation("FruitFarm_FenGe.csb")
        self.m_fenGe_tab[index]:playAction("idle")
        self.m_fenGe_tab[index].status = node_statue.idle
        self:findChild("FenGe_"..index):addChild(self.m_fenGe_tab[index])
        self:findChild("FenGe_"..index):setZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 1)
    end

    self.m_collact_node = cc.Node:create()
    self:addChild(self.m_collact_node, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    self:createDoor()

    --添加过场
    self.m_guochangDi = util_spineCreate("SpineUi/FruitFarm_Guochang_di", true, true)
    self:findChild("free_guoChang"):addChild(self.m_guochangDi)
    self:findChild("free_guoChang"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_guochangDi:setVisible(false)
    self.m_guochang = util_spineCreate("SpineUi/FruitFarm_Guochang", true, true)
    self:findChild("free_guoChang"):addChild(self.m_guochang)
    self:findChild("free_guoChang"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_guochang:setVisible(false)

    --bounsScore 
    self.m_bounsScore_node = cc.Node:create()
    self:addChild(self.m_bounsScore_node, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    -- local pos = util_getConvertNodePos(self.m_bottomUI:getCoinWinNode(), self.m_bounsScore_node)
    -- self.m_winTip = util_createAnimation("FruitFarm_jiesuan.csb")
    -- self.m_winTip:findChild("FruitFarm_jiesuanguang_1"):setVisible(false)
    -- self.m_winTip:findChild("Sprite_4"):setVisible(false)
    -- self.m_bounsScore_node:addChild(self.m_winTip, 2)
    -- self.m_winTip:setPosition(pos.x, pos.y - 15)
    -- self.m_winTip:setVisible(false)

    --freespinBar
    self.m_freeSpinBar = util_createView("CodeFruitFarmSrc.FruitFarmFreespinBarView")
    self:findChild("Node_FreeSpinNum"):addChild(self.m_freeSpinBar)
    self.m_freeSpinBar:setVisible(false)

    --basespinBar
    self.m_baseSpinBar = util_createAnimation("FruitFarm_baseSpinBar.csb")
    self:findChild("baseSpinBar"):addChild(self.m_baseSpinBar)
    self.m_baseSpinBar:playAction("idle")
    self.m_baseSpinBar.status = node_statue.idle

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        if not (freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE)then
            if self.m_bIsBigWin then
                return 
            end
        end 

        if self.m_bIsBouns then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 1
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 2
        elseif winRate > 3 then
            soundIndex = 3
            soundTime = 3
        end

        local soundName = "FruitFarmSounds/fruitFarm_winLine_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenFruitFarmMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_baseGame_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenFruitFarmMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:updataTopDoorData()
    if self.m_bProduceSlots_InFreeSpin then
        local upReels = self.m_upReels or {}
        FruitFarmBaseData:getInstance():initDoorArry(upReels, true) 
        self:checkReelIsMax()
    end
    
    self:updateTopDoorNode()
    self:initTopFlower()
    self:updataJackPotIdle(true)
end

function CodeGameScreenFruitFarmMachine:addObservers()
    BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        --local betCoin = globalData.slotRunData:getCurTotalBet() or 0
        local betCoin = globalData.slotRunData:getCurTotalBet()
        local cur_coin = FruitFarmBaseData:getInstance():getDataByKey("curBetValue")
        if tonumber(betCoin) ~= tonumber(cur_coin) then
            scheduler.unschedulesByTargetName("fruitFarm_base_colleact")
            if self.m_collact_node then
                self.m_collact_node:removeAllChildren()
            end
            self:resetBaseView()
            self:updataTopDoorData()
            self:updateTopDoorNode()
            self:initTopFlower()
            self:updataJackPotIdle()
            self:changeBaseGameMusic(false)
        end
   end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenFruitFarmMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    FruitFarmBaseData:clear()
    scheduler.unschedulesByTargetName(self:getModuleName())
    scheduler.unschedulesByTargetName("fruitFarm_base_colleact")

end

function CodeGameScreenFruitFarmMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()
    for colIndex=self.m_iReelColumnNum,  1, -1 do
        local columnData = self.m_reelColDatas[colIndex]

        local rowCount,rowNum,rowIndex = self:getinitSlotRowDatatByNetData(columnData )

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                symbolType = util_random(1, self.m_iRandomSmallSymbolTypeNum)
            end
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH
            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) - changeRowIndex
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
                node:setVisible(true)
            end
            node.p_symbolType = symbolType
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:runIdleAnim()      
            rowIndex = rowIndex - 1
        end  -- end while
    end
    self:initGridList()
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFruitFarmMachine:MachineRule_GetSelfCCBName(symbolType)

    local ccbName = nil
    if symbolType == self.SYMBOL_SMALL_FIX_BONUS then
        ccbName = "Socre_FruitFarm_Bonus_0"
    elseif symbolType == self.SYMBOL_SMALL_FIX_BONUS_SCORE then
        ccbName = "Socre_FruitFarm_Bonus_Coin"
    elseif symbolType == self.SYMBOL_SMALL_FIX_MINI then
        ccbName = "Socre_FruitFarm_Bonus_Mini"
    elseif symbolType == self.SYMBOL_SMALL_FIX_MINOR then
        ccbName = "Socre_FruitFarm_Bonus_Minor"
    elseif symbolType == self.SYMBOL_SMALL_FIX_MAJOR then
        ccbName = "Socre_FruitFarm_Bonus_Major"
    elseif symbolType == self.SYMBOL_SMALL_FIX_GRAND then
        ccbName = "Socre_FruitFarm_Bonus_Grand"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        ccbName = "Socre_FruitFarm_10"
    elseif symbolType == -1 then --  -1服务器返回表示本格子为空，客户端随机给一个基础小块的csb
        ccbName = self.m_arrNormalSymbol[util_random(1, self.m_iRandomSmallSymbolTypeNum)]
    end
--SYMBOL_SCORE_10
    return ccbName
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFruitFarmMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_BONUS, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_BONUS_SCORE, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_GRAND, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenFruitFarmMachine:MachineRule_initGame(  )

    
end

--
--单列滚动停止回调
--
function CodeGameScreenFruitFarmMachine:slotOneReelDown(reelCol)    
    BaseFastMachine.slotOneReelDown(self,reelCol) 
    local isBouns = false
    for iRow = 1, self.m_iReelRowNum do
        local slotNode = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if slotNode and slotNode:isLastSymbol() then
            local symbolType = slotNode.p_symbolType
            if symbolType == self.SYMBOL_SMALL_FIX_BONUS then
                isBouns = true
                break
            elseif self:isBounsType(symbolType) and self.m_iReelRowMaxTab[reelCol] then
                isBouns = true
                break
            end
        end
    end
    if isBouns then
        gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_bouns_down.mp3")
    end
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFruitFarmMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self.m_isInFree = true
    self.m_freeSpinBar:setVisible(true)
    self.m_freeSpinBar:changeFreeSpinByCount()
    self:findChild("baseSpinBar"):setVisible(false)
    self.m_gameBg:runCsbAction("idle_free")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFruitFarmMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self.m_isInFree = false
    self:findChild("baseSpinBar"):setVisible(true)
    self.m_freeSpinBar:setVisible(false)
    self.m_gameBg:runCsbAction("free_base")
    self:resetBaseView()
    self:updataTopDoorData()
    self:updateTopDoorNode()
    self:initTopFlower()
    self:changeBaseGameMusic(false)
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenFruitFarmMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("FruitFarmSounds/music_FruitFarm_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            util_changeNodeParent(self:findChild("Node_TanBan"), view)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenFruitFarmMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("FruitFarmSounds/music_FruitFarm_over_fs.mp3")
    self.m_fsOverSoundId = gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_freeGame_end.mp3")
    if self.m_isInFree then
        globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_fsWinCoins 
    end
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    view:setClickFunc(function(  )
        if self.m_fsOverSoundId then
            gLobalSoundManager:stopAudio(self.m_fsOverSoundId)
            self.m_fsOverSoundId = nil
        end
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.7,sy=0.7},799)
    util_changeNodeParent(self:findChild("Node_TanBan"), view)
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFruitFarmMachine:MachineRule_SpinBtnCall()
    -- gLobalSoundManager:setBackgroundMusicVolume(1)
    --freeSpin 逻辑
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFruitFarmMachine:addSelfEffect()
    self.m_curBounsWinCoins = 0  --重置当前bouns 赢钱
    self.m_effct_time = 0
    if self.m_bounsCollect then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BASEGAME_BOUNSCOLLECT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BASEGAME_BOUNSCOLLECT_EFFECT -- 动画类型
    end
    local winLins = self.m_runSpinResultData.p_winLines

    self.m_bouns_socre = nil  --分值bouns
    self.m_bouns_jackPot = nil --jackpot bouns
    for k,v in pairs(winLins) do
        local line_data = v
        if line_data.p_type == self.SYMBOL_SMALL_FIX_BONUS_SCORE then
            if self.m_bouns_socre == nil then
                self.m_bouns_socre = {}
            end
            local pos = self:getRowAndColByPos(line_data.p_iconPos[1])
            local targSpNode = self:getFixSymbol(pos.iY , pos.iX , SYMBOL_NODE_TAG)
            if targSpNode then
                local symbolTab = {}
                symbolTab.index = line_data.p_iconPos[1]
                symbolTab.node = targSpNode
                symbolTab.score = line_data.p_amount
                self.m_bouns_socre[#self.m_bouns_socre + 1] = symbolTab
            else
                release_print(string.format( "fruitFarm node is null iconPos = %d==***== reelRow = %d",line_data.p_iconPos[1],self.m_iReelRowNum))
                release_print(string.format( "fruitFarm node is null spin_num = %d==***== isFree = %s",self.m_spine_num,tostring(self.m_bProduceSlots_InFreeSpin)))
            end
        end
        if line_data.p_type == self.SYMBOL_SMALL_FIX_GRAND or 
           line_data.p_type == self.SYMBOL_SMALL_FIX_MAJOR or 
           line_data.p_type == self.SYMBOL_SMALL_FIX_MINOR or 
           line_data.p_type == self.SYMBOL_SMALL_FIX_MINI then
            if self.m_bouns_jackPot == nil then
                self.m_bouns_jackPot = {}
            end
            local pos = self:getRowAndColByPos(line_data.p_iconPos[1])
            local targSpNode = self:getFixSymbol(pos.iY , pos.iX , SYMBOL_NODE_TAG)
            if targSpNode then
                local symbolTab = {}
                symbolTab.node = targSpNode
                symbolTab.score = line_data.p_amount
                symbolTab.index = line_data.p_type % 100   --index 1~4 
                self.m_bouns_jackPot[#self.m_bouns_jackPot + 1] = symbolTab
            else
                release_print(string.format( "fruitFarm node is null iconPos = %d==***== reelRow = %d",line_data.p_iconPos[1],self.m_iReelRowNum))
                release_print(string.format( "fruitFarm node is null spin_num = %d==***== isFree = %s",self.m_spine_num,tostring(self.m_bProduceSlots_InFreeSpin)))
            end
        end
    end
    --BASEGAME_BOUNSSCORE_EFFECT
    if self.m_bouns_socre then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BASEGAME_BOUNSSCORE_EFFECT 
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BASEGAME_BOUNSSCORE_EFFECT -- 动画类型
        self.m_effct_time  = 1.17 + 0.67 * #self.m_bouns_socre
    end

    --BASEGAME_BOUNSJACKPOT_EFFECT
    if self.m_bouns_jackPot then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BASEGAME_BOUNSJACKPOT_EFFECT 
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BASEGAME_BOUNSJACKPOT_EFFECT -- 动画类型
        self.m_effct_time  = self.m_effct_time + 2
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFruitFarmMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.BASEGAME_BOUNSCOLLECT_EFFECT then
        self:bounsCollectEffect(effectData)
    end

    if effectData.p_selfEffectType == self.BASEGAME_BOUNSSCORE_EFFECT then
        self:bounsSocreEffect(effectData)
    end

    if effectData.p_selfEffectType == self.BASEGAME_BOUNSJACKPOT_EFFECT then
        self:bounsJackpotEffect(effectData)
    end
    
	return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFruitFarmMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

--刷新spin num 
function CodeGameScreenFruitFarmMachine:updataSpinLableNum()
    local lable = self.m_baseSpinBar:findChild("m_lb_spin_num")
    lable:setString(self.m_spine_num)
    if self.m_spine_num == 8 or self.m_spine_num == 9 then
        if self.m_baseSpinBar.status == node_statue.idle then
            self.m_baseSpinBar:playAction("idle1", true)
            self.m_baseSpinBar.status = node_statue.open
        end
    else
        if self.m_baseSpinBar.status == node_statue.open then
            self.m_baseSpinBar:playAction("idle")
            self.m_baseSpinBar.status = node_statue.idle
        end
    end

end

--创建door
function CodeGameScreenFruitFarmMachine:createDoor()
    self.m_door_tab = {}
    for parentIndx=1, self.m_topFlower_num do
        local doorParent = self:findChild("reel_door_"..parentIndx)
        doorParent:setZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE)
        self.m_door_tab[parentIndx] = {}
        for doorIndex=1,self.m_colDoor_num do
            local door = util_createView("CodeFruitFarmSrc.FruitFarmDoor", 1)
            local h = self.m_SlotNodeH
            door:setPosition(cc.p(self.m_SlotNodeW/2, self.m_SlotNodeH * (doorIndex - 0.5)))
            doorParent:addChild(door)
            table.insert(self.m_door_tab[parentIndx], door)
        end
    end
end


--返回本组下落音效和是否触发长滚效果
function CodeGameScreenFruitFarmMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == showColTemp[#showColTemp] then
        if nodeNum < 2  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum == 1  then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end


function CodeGameScreenFruitFarmMachine:initGameStatusData(gameData)
    BaseFastMachine.initGameStatusData(self, gameData)
    local gameConfig = gameData.gameConfig
    if gameConfig and gameConfig.extra then
        local spinProcess = gameConfig.extra.spinProcess
        if spinProcess then
            for k,v in pairs(spinProcess) do
                if v.spinTimes == 10 then
                    spinProcess[k].spinTimes = 0
                end
            end
            FruitFarmBaseData:getInstance():setDataByKey("betData", spinProcess)
        end
    end
    local spin = gameData.spin
    if spin and spin.selfData and spin.selfData.upReels then
        self.m_upReels = spin.selfData.upReels   --记录上面轮盘数据  freegame会用到
    end
end

--闪烁
function CodeGameScreenFruitFarmMachine:flashDoor(reel_col, len)
    local door_col = reel_col - 1
    if door_col <= 0 or door_col > 3 then
        return
    end
    local door_tab = self.m_door_tab[door_col]
    local col_len = len or self:getReelRowByCol(reel_col)
    local act_tab = {}
    local temp_first = true
    for doorIndex=1,self.m_colDoor_num do
        local doorNode = door_tab[doorIndex]
        if doorNode:isLock() then
            if temp_first then
                temp_first = false
            else
                act_tab[#act_tab + 1] = cc.DelayTime:create(0.1)
            end
            local callFunc = cc.CallFunc:create(
                function( )
                    if col_len == self.m_iReelRowMaxNum - 1 and doorIndex == self.m_colDoor_num then
                        if self.m_spine_num ~= 10 then
                            doorNode:playShine()
                        end
                    else
                        doorNode:playLight()
                    end
                end
            )
            act_tab[#act_tab + 1] = callFunc
        end
    end
    act_tab[#act_tab + 1] = cc.DelayTime:create(0.1)
    act_tab[#act_tab + 1] = cc.CallFunc:create(function(  )
        self.m_topFlower_tab[door_col]:flowerFlash()
    end)
    local action_node = self:findChild("reel_door_"..door_col)
    action_node:runAction(cc.Sequence:create(act_tab))
end

--服务器返回的数据
function CodeGameScreenFruitFarmMachine:spinResultCallFun(param)
    BaseFastMachine.spinResultCallFun(self, param)
    dump(param, "spin数据 = ", 6)
    if param[1] == true and param[2] and param[2].action == "SPIN" then
        self.m_bounsCollect = nil
        local result = param[2].result
        if result and result.selfData then
            local temp_data = result.selfData
            if self:getTableNum(temp_data.bonusCollect) > 0 then
                self.m_bounsCollect = temp_data.bonusCollect
            end
            if not self.m_bProduceSlots_InFreeSpin then
                self.m_spine_num = temp_data.spinTimes or 0
                FruitFarmBaseData:getInstance():setSpinNum(self.m_spine_num)
                self:updataSpinLableNum()
            end
            local doorArry = temp_data.upReels or {}
            FruitFarmBaseData:getInstance():initDoorArry(doorArry, self.m_bProduceSlots_InFreeSpin)
            if self.m_spine_num ~= 10 or self.m_bProduceSlots_InFreeSpin then
                self:checkReelIsMax()
            end
        end
    end
    if self.m_bProduceSlots_InFreeSpin and self.m_runSpinResultData.p_freeSpinNewCount > 0 then
        self:resetFreespinNum()
    end
end

--bouns 收集的动效
function CodeGameScreenFruitFarmMachine:bounsCollectEffect(effectData)
    local doorCol_tab = {}
    for key,value in pairs(self.m_bounsCollect) do
        local server_reelIndex = tonumber(key)
        local server_doorIndex = tonumber(value)
        local doorCol, doorRow = self:getDoorPos(server_doorIndex)
        local door = self.m_door_tab[doorCol][doorRow]
        local fixPos = self:getRowAndColByPos(server_reelIndex)
        local targSpNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if door and targSpNode then
            doorCol_tab[doorCol] = 1
            local start_pos = util_getConvertNodePos(targSpNode, self.m_collact_node)
            local end_pos = util_getConvertNodePos(door, self.m_collact_node)
            local collact_node = util_spineCreate("Socre_FruitFarm_Bonus_0", true, true)
            self.m_collact_node:addChild(collact_node)
            collact_node:setPosition(start_pos)
            collact_node:setScale(self.m_machineRootScale * 0.95)
            local act_tab = {}
            act_tab[#act_tab + 1] = cc.DelayTime:create(0.17)
            act_tab[#act_tab + 1] = cc.EaseIn:create(cc.MoveTo:create(0.34, end_pos),2)
            act_tab[#act_tab + 1] = cc.DelayTime:create(0.16)
            act_tab[#act_tab + 1] = cc.CallFunc:create(function(  )
                door:playUnLock()
            end)
            collact_node:runAction(cc.Sequence:create(act_tab))
            util_spinePlay(collact_node, "actionframe", false)
            util_nextFrameFunc(function(  )
                if not tolua.isnull(collact_node) then
                    collact_node:stopAllActions()
                    collact_node:removeFromParent()
                end
            end, 1.11)
        end
    end
    local isFree = self.m_isInFree
    local spin_num = self.m_spine_num
    if not isFree and spin_num ~= 9 then
        effectData.p_isPlay = true
        self:playGameEffect()
    end
    local reelRowMax = clone(self.m_iReelRowMaxTab) 
    local reelRowLenTab = {}
    for i = 1, self.m_topFlower_num do
        local row = self:getReelRowByCol(i+1)
        reelRowLenTab[i] = row
    end
    scheduler.performWithDelayGlobal(function()
        for k,v in pairs(doorCol_tab) do
            local temp_doorCol = tonumber(k)
            if reelRowMax[temp_doorCol + 1] then
                self.m_topFlower_tab[temp_doorCol]:flowerLightUp(isFree)
                if isFree and self.m_runSpinResultData.p_freeSpinNewCount > 0 then
                    self:addFreeSpinNumEffect(temp_doorCol)
                end
                for index = 1, self.m_colDoor_num do
                    local door = self.m_door_tab[temp_doorCol][index]
                    if door then
                        --door:playShan()
                    end
                end
            else
                self:flashDoor(temp_doorCol + 1, reelRowLenTab[temp_doorCol])
            end
        end
        doorCol_tab = nil
  
    end,0.51, "fruitFarm_base_colleact")

    scheduler.performWithDelayGlobal(function()
        if not isFree and spin_num == 9 then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end, 0.52, self:getModuleName())

    scheduler.performWithDelayGlobal(function()
        if isFree then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end, 1.11, self:getModuleName())
    gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_bouns_collect.mp3")
end

--获取上面door的行列数
function CodeGameScreenFruitFarmMachine:getDoorPos(server_index)
    local col_max, row_max = 3, 5
    local col, row = 0, 0
    col = server_index % col_max + 1
    row = (server_index + col_max + 1 - col) / col_max
    row = row_max - row + 1
    return col, row
end

--点击spine
function CodeGameScreenFruitFarmMachine:callSpinBtn()
    BaseFastMachine.callSpinBtn(self)
end

function CodeGameScreenFruitFarmMachine:addSpinNum(  )
    self.m_spine_num  = self.m_spine_num + 1
    self:updataSpinLableNum()
    if self.m_spine_num > 10 then
        self.m_spine_num = 1
    end
    FruitFarmBaseData:getInstance():setSpinNum(self.m_spine_num)
end

function CodeGameScreenFruitFarmMachine:changeReelLength(rowNum)
    --第一列很最后一列不用动
    for i = 2, self.m_iReelColumnNum - 1 do
        local row = rowNum or self:getReelRowByCol(i)
        self:changeReelRowNum(i, row,false)
        local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
        local rect = clipNode:getClippingRegion()
        clipNode:setClippingRegion(
            {
                x = rect.x,
                y = rect.y,
                width = rect.width,
                height = row * self.m_SlotNodeH
            }
        )
    end
end

function CodeGameScreenFruitFarmMachine:getReelRowByCol(col)
    local row = self.m_iReelRowMinNum
    if col == 1 or col == self.m_iReelColumnNum then
        return row
    end
    local doorArry = FruitFarmBaseData:getInstance():getDataByKey("doorArry")
    for k,v in pairs(doorArry[col-1]) do
        if -2 == tonumber(v) then  --  -2 服务器的数据表示是解封状态  -1是关闭状态 ps：服务器定的数据
            row  = row + 1
        end
    end
    return row
end

--开关上面的门
function CodeGameScreenFruitFarmMachine:openOrCloseDoor(isOpen)
    for parentIndx=1, self.m_topFlower_num do
        local isPlaySpund = false
        for doorIndex=1,self.m_colDoor_num do
            local door = self.m_door_tab[parentIndx][doorIndex]
            if door then
                if isOpen then
                   local isOpen = door:playOpen(self.m_bProduceSlots_InFreeSpin)
                    if isOpen then
                        isPlaySpund = true
                    end
                else
                    door:playLock()
                end
            end
        end
        if isPlaySpund then
            if self.m_isInFree then
                gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_door_open.mp3")
            else
                gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_door_open2.mp3")
            end
        end
    end
end

function CodeGameScreenFruitFarmMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(self.m_iReelRowMaxNum,self.m_iReelColumnNum,
    TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function CodeGameScreenFruitFarmMachine:changeDividerStatus(index,func)
    local ani_str_tab = {
        "idle",
        "over",
        "idle2",
        "start"
    }
    local divider_node = self.m_fenGe_tab[index]
    if divider_node then
        divider_node.status = divider_node.status + 1
        if divider_node.status > node_statue.over then
            divider_node.status = node_statue.idle
        end
        if func then
            divider_node:playAction(ani_str_tab[divider_node.status], false, function (  )
                func()
            end, 60)
        else
            divider_node:playAction(ani_str_tab[divider_node.status])
        end
    end
end

function CodeGameScreenFruitFarmMachine:initTopFlower()
    for index =1,self.m_topFlower_num do
        local top_flower = self.m_topFlower_tab[index]
        if top_flower then
            local row = self:getReelRowByCol(index + 1)
            if self.m_iReelRowMaxTab[index + 1] then
                top_flower:flowerIdle(self.m_bProduceSlots_InFreeSpin)
            end
        end
    end
end

function CodeGameScreenFruitFarmMachine:checkReelIsMax(  )
    --第一列很最后一列不用动
    for index = 2, self.m_iReelColumnNum - 1 do
        local row = self:getReelRowByCol(index)
        self.m_iReelRowMaxTab[index] = self.m_iReelRowMaxNum == row
    end
    FruitFarmBaseData:getInstance():setDataByKey("row_max", self.m_iReelRowMaxTab)
end

function CodeGameScreenFruitFarmMachine:slotReelDown(  )
    BaseFastMachine.slotReelDown(self)
    if self.m_bProduceSlots_InFreeSpin == false then
        -- if self.m_spine_num == 9 then
        --     for iRow = 1, self.m_iReelColumnNum do
        --         local columnData = self.m_reelColDatas[iRow]
        --         local runInfo = self.m_reelRunInfo[iRow]
        --         --得到初始长度
        --         local len = runInfo:getInitReelRunLen()
        --         runInfo:setReelRunLen(len + 10)
        --     end
        -- end
        if self.m_spine_num == 10 then
            self.m_spine_num = 0 
            FruitFarmBaseData:getInstance():setSpinNum(self.m_spine_num)
        end
    end
end

function CodeGameScreenFruitFarmMachine:changeReelData(rowNum)
    for iRow = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[iRow]
        local row = rowNum or self:getReelRowByCol(iRow)
        columnData.p_slotColumnHeight = self.m_SlotNodeH * row
        columnData:updateShowColCount(row)
        self.m_fReelHeigth = self.m_SlotNodeH * row
    end
end


function CodeGameScreenFruitFarmMachine:updataTopDoorData( )
    local betValue = globalData.slotRunData:getCurTotalBet()
    FruitFarmBaseData:getInstance():setCurBetValue(tostring(betValue))
    self:checkReelIsMax()
    self.m_spine_num = FruitFarmBaseData:getInstance():getDataByKey("spin_num")
    self:updataSpinLableNum()
end

function CodeGameScreenFruitFarmMachine:updateTopDoorNode()
    local doorArry = FruitFarmBaseData:getInstance():getDataByKey("doorArry")
    for parentIndx=1, self.m_topFlower_num do
        local col_len = self:getReelRowByCol(parentIndx + 1)
        for doorIndex=1,self.m_colDoor_num do
            local door = self.m_door_tab[parentIndx][doorIndex]
            if door then
                door:stopAllActions()
                local status = doorArry[parentIndx][doorIndex] == -1 and 1 or 2
                door:setIdleStatus(status)
                if self.m_iReelRowMaxTab[doorIndex] then
                    --door:playShan()
                end
                if col_len == self.m_iReelRowMaxNum - 1 and doorIndex == self.m_colDoor_num and self.m_spine_num ~= 10 then
                    door:playShine()
                end
            end
        end
    end
end

function CodeGameScreenFruitFarmMachine:getTableNum(array)
    local num = 0
    if array == nil then
        array = {}
    end
    for k,v in pairs(array) do
        num = num + 1
    end

    return num
end


function CodeGameScreenFruitFarmMachine:produceSlots()
    if self.m_spine_num == 10 or self.m_bProduceSlots_InFreeSpin then
        self.m_iReelRowNum = self.m_iReelRowMaxNum
        for iRow = 1, self.m_iReelColumnNum do
            local columnData = self.m_reelColDatas[iRow]
            local runInfo = self.m_reelRunInfo[iRow]
            --得到初始长度
            local len = runInfo:getInitReelRunLen()
            runInfo:setReelRunLen(len + 10)
        end
    end
    BaseFastMachine.produceSlots(self)
end

function CodeGameScreenFruitFarmMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0 
    if globalData.slotRunData.isDeluexeClub == true then
        level = 2
    else
        if betCoin > self.m_specialBets[2].p_totalBetValue then
            level = 2
        elseif betCoin > self.m_specialBets[1].p_totalBetValue then
            level = 1
        end
    end
    return level
end

function CodeGameScreenFruitFarmMachine:updataJackPotIdle(isInit)
    self.m_iBetLevel = self:updateBetLevel()
    FruitFarmBaseData:getInstance():setDataByKey("betLevel", self.m_iBetLevel)
    self.m_jackPotBar:toAction(self.m_iBetLevel + 1, isInit)
    self:findChild("txt_bet_1"):setVisible(self.m_iBetLevel < 2)
    self:findChild("txt_bet_2"):setVisible(self.m_iBetLevel == 2)
end

function CodeGameScreenFruitFarmMachine:updateReelGridNode(slotNode)
    local symnolType = slotNode.p_symbolType
    if symnolType == self.SYMBOL_SMALL_FIX_BONUS_SCORE or
        symnolType == self.SYMBOL_SMALL_FIX_GRAND or
        symnolType == self.SYMBOL_SMALL_FIX_MAJOR or
        symnolType == self.SYMBOL_SMALL_FIX_MINI  or
        symnolType == self.SYMBOL_SMALL_FIX_MINOR  then
        if self.m_iReelRowMaxTab[slotNode.p_cloumnIndex] == false then
            slotNode:setIdleAnimName("idle_dark")
            slotNode:runIdleAnim()
        else
            slotNode.p_reelDownRunAnima = "buling"
        end
        if symnolType == self.SYMBOL_SMALL_FIX_BONUS_SCORE then
         
            local label_str = "m_lb_score"
            if self.m_iReelRowMaxTab[slotNode.p_cloumnIndex] == false  then
                label_str = "m_lb_score_dark"
            end
            local labCoin = slotNode:getCcbProperty(label_str)
            local betCoin = globalData.slotRunData:getCurTotalBet() or 0
            if labCoin then
                local score = nil
                if slotNode:isLastSymbol() then
                    local reelsIndex = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
                    score = self:getReSpinSymbolScore(reelsIndex)
                else
                    score = self.m_configData:getFixSymbolPro()
                end
                if score then
                    labCoin:setString(util_formatCoins(score * betCoin, 3))
                end
            end
        end
    end
    if symnolType == self.SYMBOL_SMALL_FIX_BONUS then
        slotNode.p_reelDownRunAnima = "buling"
    end
end

function CodeGameScreenFruitFarmMachine:getReSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil

    if storedIcons == nil then
        return
    end
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end

    return score
end

function CodeGameScreenFruitFarmMachine:updateNetWorkData()
    local wait_time = 0
    if self.m_spine_num == 1 or self.m_spine_num == 10 then
        wait_time = 0.34
    end

    scheduler.performWithDelayGlobal(function()
        self.m_isWaitChangeReel=true
        self:produceSlots()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()
    end, wait_time, self:getModuleName())

end

--重置顶部花 分割线的状态等
function CodeGameScreenFruitFarmMachine:resetBaseView()
    for index =1,self.m_topFlower_num do
        local topFlower = self.m_topFlower_tab[index]
        if topFlower then
            topFlower:runCsbAction("idle_dark")
        end
        local fenge =  self.m_fenGe_tab[index]
        if fenge then
            fenge:playAction("idle")
            fenge.status = node_statue.idle
        end
        local reelBg = self.m_jiMan_tab[index]
        if reelBg then
            reelBg.status = node_statue.idle
            reelBg:playAction("idle_over")
        end
    end

    self:stopAllActions()
    -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
    self.m_nScatterNumInOneSpin = 0
    self.m_nBonusNumInOneSpin = 0
    if self.m_bgLight.status == node_statue.open then
        self:runCsbAction("close")
    end
    self.m_bgLight.status = node_statue.idle
    self:clearWinLineEffect()
    self:checkChangeBaseParent()
    self.m_iReelRowNum = self.m_iReelRowMinNum
    self:changeReelData()
    self:changeReelLength(self.m_iReelRowMinNum)
end

function CodeGameScreenFruitFarmMachine:showFreeSpinStart(num, func)

    self.m_guochang:setVisible(true)
    self.m_guochangDi:setVisible(true)
    util_spinePlay(self.m_guochangDi, "actionframe", false)
    util_spinePlay(self.m_guochang, "actionframe", false)
    gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_freeGame_guochang.mp3")
    util_spineEndCallFunc(self.m_guochang, "actionframe", function(  )
        self.m_fsStartSoundId = gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_freeGame_start.mp3")
        local view = BaseFastMachine.showFreeSpinStart(self, num, function(  )
            func()
        end)
        view:setClickFunc(function(  )
            if self.m_fsStartSoundId then
                gLobalSoundManager:stopAudio(self.m_fsStartSoundId)
                self.m_fsStartSoundId = nil
            end
        end)
        util_changeNodeParent(self:findChild("Node_TanBan"), view)
        self.m_guochang:setVisible(false)
        self.m_guochangDi:setVisible(false)
    end)

    scheduler.performWithDelayGlobal(function()
        self:resetBaseView()
        self.m_gameBg:runCsbAction("base_free")
        FruitFarmBaseData:getInstance():initDoorArry({}, true) 
        self:checkReelIsMax()
        self:updateTopDoorNode()
    end,2.06, self:getModuleName())

    -- scheduler.performWithDelayGlobal(function()
    -- end,3.13, self:getModuleName())
end

--bouns 收集的动效
function CodeGameScreenFruitFarmMachine:bounsSocreEffect(effectData)
    local winCoins = 0
    self.m_bIsBouns = true
    table.sort(self.m_bouns_socre, function(v1, v2)
        local fixPos1 = self:getRowAndColByPos(v1.index)
        local fixPos2 = self:getRowAndColByPos(v2.index)
        local result = fixPos1.iY == fixPos2.iY and (fixPos1.iX > fixPos2.iX) or (fixPos1.iY < fixPos2.iY)
        return result
        --return v1.index < v2.index
    end )
    local tab_num = self:getTableNum(self.m_bouns_socre)
    for key,value in pairs(self.m_bouns_socre) do
        local score_data = value
        local symbolNode = score_data.node
        local score = score_data.score
        if symbolNode and not tolua.isnull(symbolNode) then
            performWithDelay(
                symbolNode,
                function()
                    local win_coins_old = winCoins
                    winCoins  = winCoins + score
                    self.m_curBounsWinCoins = winCoins
                    symbolNode:runAnim("actionframe")
                    local socre_node = util_createAnimation("Socre_FruitFarm_Bonus_Coin_tuowei.csb")
                    socre_node:playAction("actionframe")
                    socre_node:findChild("m_lb_score"):setString(util_formatCoins(score, 3))
                    socre_node:setScale(self.m_machineRootScale * 0.95)
                    local startPos = util_getConvertNodePos(symbolNode, self.m_bounsScore_node)
                    local endPos = util_getConvertNodePos(self.m_bottomUI:getCoinWinNode(), self.m_bounsScore_node)
                    self.m_bounsScore_node:addChild(socre_node)
                    socre_node:setPosition(startPos)
                    local action_tab = {}
                    action_tab[#action_tab + 1] = cc.DelayTime:create(0.33)
                    action_tab[#action_tab + 1] = cc.CallFunc:create(function(  )
                        local lizi = socre_node:findChild("lizi")
                        lizi:setPositionType(0)
                        lizi:stopSystem()
                        lizi:resetSystem()
    
                        local yezi = socre_node:findChild("yezi")
                        yezi:setPositionType(0)
                        yezi:stopSystem()
                        yezi:resetSystem()
                    end)
                    action_tab[#action_tab + 1] = cc.MoveTo:create(0.33, endPos)
                    action_tab[#action_tab + 1] = cc.CallFunc:create(function(  )
                        local lizi = socre_node:findChild("lizi")
                        lizi:stopSystem()
                        local yezi = socre_node:findChild("yezi")
                        yezi:stopSystem()
                    end)
                    socre_node:runAction(cc.Sequence:create(action_tab))
                    local win_coins = winCoins
                    
                    util_nextFrameFunc(function(  )
                        if not tolua.isnull(socre_node) then
                            socre_node:stopAllActions()
                            socre_node:removeFromParent()
                            self:playCoinWinEffectUI()
                            if self.m_isInFree then
                                globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_fsWinCoins - self.m_iOnceSpinLastWin + win_coins
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {win_coins, false, true,})
                            else
                                globalData.slotRunData.lastWinCoin = 0
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {win_coins, false, true, win_coins_old})
                                if self.m_iOnceSpinLastWin == win_coins then
                                    self:checkNotifyUpdateWinCoin()
                                end
                            end
                            -- self.m_winTip:setVisible(true)
                            -- local win_act = {}
                            -- win_act[#win_act + 1] = cc.CallFunc:create(function(  )
                            --     --self.m_winTip:playAction("actionframe")
                            --     local Particle_1 = self.m_winTip:findChild("Particle_1")
                            --     Particle_1:stopSystem()
                            --     Particle_1:resetSystem()
            
                            --     local Particle_2 = self.m_winTip:findChild("Particle_1_0")
                            --     Particle_2:stopSystem()
                            --     Particle_2:resetSystem()
                            --     if self.m_isInFree then
                            --         globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_fsWinCoins - self.m_iOnceSpinLastWin + win_coins
                            --         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {win_coins, false, true,})
                            --     else
                            --         globalData.slotRunData.lastWinCoin = 0
                            --         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {win_coins, false, true, win_coins_old})
                            --         if self.m_iOnceSpinLastWin == win_coins then
                            --             self:checkNotifyUpdateWinCoin()
                            --         end
                            --     end
                            -- end)
                            -- win_act[#win_act + 1] = cc.DelayTime:create(0.74)
                            -- win_act[#win_act + 1] = cc.CallFunc:create(function(  )
                            --     self.m_winTip:setVisible(false)
                            -- end)
                            -- self.m_winTip:stopAllActions()
                            -- self.m_winTip:runAction(cc.Sequence:create(win_act))
                        end
                    end, 0.67)
                    gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_bouns_score.mp3")
                end,
                0.67 * key
            )
        else
            local str = ""
            if symbolNode == nil then
                str = "node is null"
            else
                str = "node is delete"
            end
            release_print(string.format( "fruitFarm bounsSocreEffect %s iconPos = %d==***== reelRow = %d",str,score_data.index ,self.m_iReelRowNum))
            release_print(string.format( "fruitFarm bounsSocreEffect %s is null spin_num = %d==***== isFree = %s",str,self.m_spine_num,tostring(self.m_bProduceSlots_InFreeSpin)))
            gLobalBuglyControl:luaException("fruitFarm symbolNode is abnormal",debug.traceback())
        end
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        release_print("fruitFarm bounsSocreEffect is over")
        self.m_bouns_socre = nil  --分值bouns
        self.m_bIsBouns = false
        effectData.p_isPlay = true
        self:playGameEffect()
        waitNode:removeFromParent()
    end,0.67 * tab_num + 1.17)
end

--bouns jackPot 收集
function CodeGameScreenFruitFarmMachine:bounsJackpotEffect(effectData)
    self.m_bIsBouns = true
    if self.m_bProduceSlots_InFreeSpin then
        self:setMinMusicBGVolume()
    end
    local tab_num = self:getTableNum(self.m_bouns_jackPot)
    if tab_num > 0 then
        local effect_data = self.m_bouns_jackPot[1]
        local symbolNode = effect_data.node
        self.m_curBounsWinCoins  = self.m_curBounsWinCoins + effect_data.score
        symbolNode:runAnim(
            "actionframe",
            false,
            function()
                local dataInfo = {}
                dataInfo.machine = self
                dataInfo.index   = effect_data.index
                dataInfo.coins   = effect_data.score
                if self.m_bProduceSlots_InFreeSpin then
                    dataInfo.start_coins = self.m_runSpinResultData.p_fsWinCoins - self.m_iOnceSpinLastWin + self.m_curBounsWinCoins - effect_data.score
                else
                    dataInfo.start_coins = self.m_curBounsWinCoins - effect_data.score
                end
                local view = util_createView("CodeFruitFarmSrc/FruitFarmJackpotOver", dataInfo)
                view:setCloseCallFunc(
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                        if self.m_bProduceSlots_InFreeSpin then
                            self:setMaxMusicBGVolume()
                        else
                            if self.m_iOnceSpinLastWin == self.m_curBounsWinCoins then
                                self:checkNotifyUpdateWinCoin()
                            end
                        end
                        self.m_bIsBouns = false
                    end
                )
                if globalData.slotRunData.machineData.p_portraitFlag then
                    view.getRotateBackScaleFlag = function()
                        return false
                    end
                end
                gLobalViewManager:showUI(view)
            end,
            60
        )
        gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_bouns_jackpot.mp3")
    else
        effectData.p_isPlay = true
        self:playGameEffect()
        if self.m_bProduceSlots_InFreeSpin then
            self:setMaxMusicBGVolume()
        end
        self.m_bIsBouns = false
    end
end

--重置freeSpinNum
function CodeGameScreenFruitFarmMachine:resetFreespinNum()
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
end

function CodeGameScreenFruitFarmMachine:checkNotifyUpdateWinCoin( )
    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    if self.m_bProduceSlots_InFreeSpin == false then
        globalData.slotRunData.lastWinCoin = self.m_iOnceSpinLastWin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop, true, self.m_curBounsWinCoins})
    else
        globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_fsWinCoins 
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin - self.m_curBounsWinCoins,isNotifyUpdateTop})
    end

end

--
function CodeGameScreenFruitFarmMachine:playMaxBgEffect(index, isOver)
    if isOver then
        if self.m_jiMan_tab[index].status == node_statue.open or self.m_jiMan_tab[index].status == node_statue.openIdle then
            self.m_jiMan_tab[index].status = node_statue.over
            self.m_jiMan_tab[index]:playAction("xiaoshi", false,function(  )
                self.m_jiMan_tab[index]:playAction("idle_over")
                self.m_jiMan_tab[index].status = node_statue.idle
            end, 60)
        end
    else
        if self.m_jiMan_tab[index].status == node_statue.over or self.m_jiMan_tab[index].status == node_statue.idle then
            self.m_jiMan_tab[index].status = node_statue.open
            self.m_jiMan_tab[index]:playAction("actionframe", false,function(  )
                self.m_jiMan_tab[index]:playAction("idle")
                self.m_jiMan_tab[index].status = node_statue.openIdle
            end, 60)
        end
    end
end

---
-- 显示所有的连线框
--
function CodeGameScreenFruitFarmMachine:showAllFrame(winLines)

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
        local isBounsLines = false
        if lineValue == nil then
            printInfo("xcyy : %s","")
        else
            isBounsLines = self:isBounsType(lineValue.enumSymbolType)
        end
        local frameNum = lineValue.iLineSymbolNum
        if isBounsLines then
            frameNum = 0  --bouns不显示连线框
        end
        for i=1,frameNum do

            local symPosData = lineValue.vecValidMatrixSymPos[i]


            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then

                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen( )

                local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
                local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY

                local node = self:getFrameWithPool(lineValue,symPosData)
                node:setPosition(cc.p(posX,posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

            end

        end
    end

end
---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenFruitFarmMachine:showLineFrameByIndex(winLines,frameIndex)

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s","")
    else
        if self:isBounsType(lineValue.enumSymbolType) then
            return
        end
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
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

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

function CodeGameScreenFruitFarmMachine:isBounsType(node_type)
    local isBouns = false
    if self.SYMBOL_SMALL_FIX_BONUS == node_type or self.SYMBOL_SMALL_FIX_BONUS_SCORE == node_type or
       self.SYMBOL_SMALL_FIX_GRAND == node_type or self.SYMBOL_SMALL_FIX_MAJOR == node_type or
       self.SYMBOL_SMALL_FIX_MINI == node_type or self.SYMBOL_SMALL_FIX_MINOR == node_type then
       isBouns = true
    end
    return isBouns
end

function CodeGameScreenFruitFarmMachine:lineLogicEffectType(winLineData, lineInfo,iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData,lineInfo)
    local symNum = enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and 2 or self.m_validLineSymNum
    if iconsPos ~= nil and #iconsPos >= symNum then
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果

        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenFruitFarmMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "FruitFarmSounds/fruitFarm_scatter_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenFruitFarmMachine:playEffectNotifyNextSpinCall( )

    BaseFastMachine.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( )
    end)


end

function CodeGameScreenFruitFarmMachine:changeBaseGameMusic(isChange)
    local music_bg = self.m_configData.p_musicBg
    if isChange then
        music_bg = "FruitFarmSounds/fruitFarm_baseGame_bg2.mp3"
    end
    self:setBackGroundMusic(music_bg)
    if isChange ~= self.m_isChangeBgMusic then
        local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0
        self:clearCurMusicBg()
        self:resetMusicBg()
        self.m_isChangeBgMusic = not self.m_isChangeBgMusic
        gLobalSoundManager:setBackgroundMusicVolume(volume)
        self:removeSoundHandler()
        self:checkTriggerOrInSpecialGame(function(  )
            self:reelsDownDelaySetMusicBGVolume( )
        end)
    end
end

-- 背景音乐点击spin后播放
function CodeGameScreenFruitFarmMachine:normalSpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    BaseFastMachine.normalSpinBtnCall(self)
end

function CodeGameScreenFruitFarmMachine:reelsDownDelaySetMusicBGVolume()
    self:removeSoundHandler()


    self.m_soundHandlerId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_soundHandlerId = nil
            local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0

            self.m_soundGlobalId =
                scheduler.scheduleGlobal(
                function()
                    --播放广告过程中暂停逻辑
                    if gLobalAdsControl ~= nil and gLobalAdsControl.getPlayAdFlag ~= nil and gLobalAdsControl:getPlayAdFlag() then
                        return
                    end

                    if volume <= 0 then
                        volume = 0
                    end

                    -- print("缩小音量 = " .. tostring(volume))
                    gLobalSoundManager:setBackgroundMusicVolume(volume)

                    if volume <= 0 then
                        if self.m_soundGlobalId ~= nil then
                            scheduler.unscheduleGlobal(self.m_soundGlobalId)
                            self.m_soundGlobalId = nil
                        end
                    end

                    volume = volume - 0.04
                end,
                0.1
            )
        end,
        5 + self.m_effct_time,
        "SoundHandlerId"
    )

    self:setReelDownSoundFlag(true)
end

function CodeGameScreenFruitFarmMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("CodeFruitFarmSrc/FruitFarmDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(view)

    return view
end

--添加freeSpin效果相关
function CodeGameScreenFruitFarmMachine:addFreeSpinNumEffect(topFlowerIndex)
    -- 0.47  0.3
    scheduler.performWithDelayGlobal(function()
        local addSpin_node = util_createAnimation("FruitFarm_TopFlower_1.csb")
        local lizi = addSpin_node:findChild("lizi")
        lizi:setPositionType(0)
        lizi:stopSystem()
        lizi:resetSystem()
        local start_node = self:findChild("Node_TopFlower_"..topFlowerIndex)
        local end_node = self.m_freeSpinBar:findChild("ef_baodian")
        local start_pos = util_getConvertNodePos(start_node, self.m_collact_node)
        local end_pos = util_getConvertNodePos(end_node, self.m_collact_node)
        local action_list = {}
        action_list[#action_list + 1] = cc.MoveTo:create(0.57, end_pos)
        action_list[#action_list + 1] = cc.CallFunc:create(function(  )
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            gLobalSoundManager:playSound("FruitFarmSounds/fruitFarm_freeGame_add.mp3")
            self.m_freeSpinBar:runCsbAction("add1")
        end)
        addSpin_node:setPosition(start_pos)
        self.m_collact_node:addChild(addSpin_node)
        addSpin_node:runAction(cc.Sequence:create(action_list))
        util_nextFrameFunc(function(  )
            if not tolua.isnull(addSpin_node) then
                addSpin_node:stopAllActions()
                addSpin_node:removeFromParent()
            end
        end, 0.58)
    end,0.47, self:getModuleName())
end

function CodeGameScreenFruitFarmMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    if globalData.slotRunData.isPortrait == true then
        if display.height >= FIT_HEIGHT_MAX then
            mainScale = (FIT_HEIGHT_MAX - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale

        elseif display.height <= FIT_HEIGHT_MIN then
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            mainScale = mainScale + 0.03
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        elseif display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            -- mainScale = mainScale
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

end

--添加连线动画
function CodeGameScreenFruitFarmMachine:addLineEffect()
    if #self.m_vecGetLineInfo ~= 0 then
        local bounsEffect = 0
        for i = 1, #self.m_reelResultLines do
            local lineValue = self.m_reelResultLines[i]
            if
                (lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS or
                    lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN) and
                    #self.m_reelResultLines == 1 and
                    lineValue.lineSymbolRate == 0
             then
                -- 如果只有bonus 和 freespin 连线 那么， 不做连线播放，
                return
            end
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS or
               lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or
               self:isBounsType(lineValue.enumSymbolType) then
                bounsEffect  = bounsEffect + 1
            end
        end
        if bounsEffect ==  #self.m_reelResultLines then
            return
        end
        
        local effectData = GameEffectData.new()
        effectData.p_effectType = self.m_LineEffectType
         --GameEffect.EFFECT_SHOW_ALL_LINE
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData

        table.sort(self.m_reelResultLines, function(a, b)
            return a.enumSymbolType < b.enumSymbolType
        end)

    end
end


function CodeGameScreenFruitFarmMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

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
                   lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS or 
                   self:isBounsType(lineData.enumSymbolType) then

                    if #winLines == 1 then
                        break
                    end

                    frameIndex = frameIndex + 1
                    if frameIndex > #winLines  then
                        frameIndex = 1
                        if self.m_showLineHandlerID ~= nil then
                            scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                            self.m_showLineHandlerID = nil
                            self:showAllFrame(winLines)
                            self:playInLineNodes()
                            showLienFrameByIndex()
                            return
                        end
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

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
        self:getCurrSpinMode() == FREE_SPIN_MODE then


        self:showAllFrame(winLines)  -- 播放全部线框

        -- if #winLines > 1 then
            showLienFrameByIndex()
        -- end

    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end


        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines,1)
        end

    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenFruitFarmMachine:playInLineNodes()

    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and self:isBounsType(slotsNode.p_symbolType) == false then
            slotsNode:runLineAnim()
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()) )
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

function CodeGameScreenFruitFarmMachine:spinBtnEnProc()
    --补丁
    if self.m_bProduceSlots_InFreeSpin then
        self.m_iReelRowNum = self.m_iReelRowMaxNum
        self:changeReelData()
        self:changeReelLength()
        self:openOrCloseDoor(true)
        for i = 1, self.m_topFlower_num do
            local row = self:getReelRowByCol(i+1)
            if row > self.m_iReelRowMinNum then
                local divider_node = self.m_fenGe_tab[i]
                if divider_node and divider_node.status == node_statue.idle then
                    self:changeDividerStatus(i, function(  )
                        self:changeDividerStatus(i, nil)
                    end)
                end
            end
            if self.m_iReelRowMaxTab[i+1] then     
                self:playMaxBgEffect(i, false)
            end
        end
    else
        --非 freeSpin 逻辑
        self:addSpinNum()
        if self.m_spine_num == 1 then
            self:changeBaseGameMusic(false)
            self.m_iReelRowNum = self.m_iReelRowMinNum
            for index =1,self.m_topFlower_num do
                local top_flower = self.m_topFlower_tab[index]
                local row = self:getReelRowByCol(index + 1)
                if top_flower and self.m_iReelRowMaxTab[index + 1] then
                    top_flower:flowerDark( )
                end
            end
            self:changeReelData(self.m_iReelRowMinNum)
            FruitFarmBaseData:getInstance():initDoorArry({}, false) 
            if self.m_bgLight.status == node_statue.open then
                self.m_bgLight.status = node_statue.idle
                self:runCsbAction("close")
            end
            self:openOrCloseDoor(false)
            for i = 1, self.m_topFlower_num do
                local divider_node = self.m_fenGe_tab[i]
                if divider_node.status == node_statue.open or divider_node.status == node_statue.openIdle then
                    divider_node.status = node_statue.openIdle
                    self:changeDividerStatus(i, function(  )
                        self:changeDividerStatus(i, nil)
                    end)
                end
                if self.m_iReelRowMaxTab[i+1] then
                    self:playMaxBgEffect(i, true)
                end
            end
            self:checkReelIsMax()
            --滚动效果 延后改变裁剪区域
            scheduler.performWithDelayGlobal(function()

                self:changeReelLength(self.m_iReelRowMinNum)
            end,0.34, self:getModuleName())
        end
        if self.m_spine_num == 10 then
            self:changeBaseGameMusic(true)
            if self.m_collact_node then
                self.m_collact_node:removeAllChildren()
            end
            scheduler.unschedulesByTargetName("fruitFarm_base_colleact")
            self:updateTopDoorNode()
            self:initTopFlower()
            if self.m_bgLight.status == node_statue.idle then
                self.m_bgLight.status = node_statue.open
                self:runCsbAction("open")
            end
            self.m_iReelRowNum = self.m_iReelRowMaxNum
            for iRow = 1, self.m_iReelColumnNum do
                local columnData = self.m_reelColDatas[iRow]
                local runInfo = self.m_reelRunInfo[iRow]
                --得到初始长度
                local len = runInfo:getInitReelRunLen()
                runInfo:setReelRunLen(len + 10)
            end
            self:changeReelData()
            self:changeReelLength()
            self:openOrCloseDoor(true)
            local row_col = {}  -- 记录 2 3 4 列的行数
            for i = 1, self.m_topFlower_num do
                local row = self:getReelRowByCol(i + 1)
                row_col[i] = row
            end
            scheduler.performWithDelayGlobal(
                function()
                    for i = 1, self.m_topFlower_num do
                        if row_col[i] > self.m_iReelRowMinNum then
                            self:changeDividerStatus(
                                i,
                                function()
                                    self:changeDividerStatus(i, nil)
                                end
                            )
                        end
                        if row_col[i] == self.m_iReelRowMaxNum then
                            self:playMaxBgEffect(i, false)
                        end
                    end
                end,
                0.5,
                self:getModuleName()
            )
        end
    end

    
    --TODO 处理repeat逻辑

    if self.m_isChangeBGMusic then
        -- gLobalSoundManager:playFreeSpinBackMusic(self:getFreeSpinMusicBG())

        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self:getFreeSpinMusicBG())

        self.m_isChangeBGMusic = false
    end
    self:beginReel()
end

return CodeGameScreenFruitFarmMachine






