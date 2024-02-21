---
-- island li
-- 2019年1月26日
-- CodeGameScreenClawStallMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "ClawStallPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"

local ClawStallGameManager = util_require("CodeClawStallPhysicsMachine.ClawStallGameManager"):getInstance()
local CodeGameScreenClawStallMachine = class("CodeGameScreenClawStallMachine", BaseNewReelMachine)

CodeGameScreenClawStallMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenClawStallMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenClawStallMachine.SYMBOL_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenClawStallMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenClawStallMachine.SYMBOL_SCORE_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7

CodeGameScreenClawStallMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集bonus图标

local SCALE_ROWS_4      =       0.96 --4行轮盘下的缩放比列

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}


-- 构造函数
function CodeGameScreenClawStallMachine:ctor()
    CodeGameScreenClawStallMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

    self.m_bonus_down = {}

    self.m_lockWildNodes = {}
    --当前行数
    self.m_curReelRowCount = -1

    self.m_isTriggerLongRun = false
    self.m_isAlreadyUpdateCoins = false
    self.m_longRunSymbols = {}
 
    --init
    self:initGame()
end

function CodeGameScreenClawStallMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("ClawStallConfig.csv", "LevelClawStallConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenClawStallMachine:initGameStatusData(gameData)
    CodeGameScreenClawStallMachine.super.initGameStatusData(self, gameData)
    --读取额外参数
    local extra = gameData.gameConfig.extra
    if nil ~= extra then
        self.m_collectProcess = extra.collectProcess
        self.m_mapList = extra.map
    end
    
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenClawStallMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ClawStall"  
end

-- 继承底层respinView
function CodeGameScreenClawStallMachine:getRespinView()
    return "CodeClawStallSrc.ClawStallRespinView"
end
-- 继承底层respinNode
function CodeGameScreenClawStallMachine:getRespinNode()
    return "CodeClawStallSrc.ClawStallRespinNode"
end

function CodeGameScreenClawStallMachine:getBottomUINode()
    return "CodeClawStallSrc.ClawStallBottomNode"
end

function CodeGameScreenClawStallMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
end

function CodeGameScreenClawStallMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_RespinBar")
    self.m_baseFreeSpinBar = util_createView("CodeClawStallSrc.ClawStallFreespinBarView",{machine = self})
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)

    self.m_superFreeSpinBar = util_createView("CodeClawStallSrc.ClawStallSuperFreespinBarView")
    self:findChild("Node_SuperFreeBar"):addChild(self.m_superFreeSpinBar)
    util_setCsbVisible(self.m_superFreeSpinBar, false)
end

function CodeGameScreenClawStallMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_superFreeSpinBar:setVisible(false)
    self.m_collectTarget:setVisible(false)
    self:findChild("Node_Progress"):setVisible(false)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_baseFreeSpinBar:showFreeUI()
        if self.m_iReelRowNum == 4 then
            self.m_superFreeSpinBar:setVisible(true)
            self.m_baseFreeSpinBar:setVisible(false)
        end
    else
        self.m_baseFreeSpinBar:showRespinUI()
    end
end

function CodeGameScreenClawStallMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_superFreeSpinBar:setVisible(false)
    self.m_collectTarget:setVisible(true)
    self:findChild("Node_Progress"):setVisible(true)
end

--变更背景显示
function CodeGameScreenClawStallMachine:changeBg(bgType)
    self.m_gameBg:findChild("base"):setVisible(bgType == "base")
    self.m_gameBg:findChild("super"):setVisible(bgType == "free")
    self.m_gameBg:findChild("respin"):setVisible(bgType == "respin")
    self:findChild("Node_reel_super"):setVisible(bgType == "free")
    self:findChild("Node_reel_base"):setVisible(bgType ~= "free")
    self:findChild("LightsBase"):setVisible(bgType ~= "free")
    self:findChild("LightsSuper"):setVisible(bgType == "free")
    self.m_jackpotBar:findChild("LightsJBase"):setVisible(bgType ~= "free")
    self.m_jackpotBar:findChild("LightsJSuper"):setVisible(bgType == "free")
end

function CodeGameScreenClawStallMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --地图界面
    self.m_mapView = util_createView("CodeClawStallSrc.ClawStallMapView",{machine = self})
    self:findChild("Node_Map"):addChild(self.m_mapView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_mapView:setVisible(false)

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self.m_effectNode:setScale(self.m_machineRootScale)

    --锁定小块层
    self.m_lockNode = cc.Node:create()
    self:findChild("Node_1"):addChild(self.m_lockNode)

    self:runCsbAction("idle",true)
    
    self:initFreeSpinBar() -- FreeSpinbar

    --初始化收集条
    self:initCollectBar()

    self.m_reelLayOut = self:findChild("Panel_SpReels")
    self.m_reelLayOut:setClippingEnabled(false)

    self.m_jackpotBar = util_createView("CodeClawStallSrc.ClawStallJackPotBarView",{machine = self})
    self:findChild("Node_JackpotView"):addChild(self.m_jackpotBar)

    --初始化遮黑层
    self:initLayerBlack()
end

--[[
    初始化黑色遮罩层
]]
function CodeGameScreenClawStallMachine:initLayerBlack()
    self.m_blackLayer = util_createAnimation("ClawStall_qpzz.csb")
    self.m_blackLayer:setPosition(util_convertToNodeSpace(self.m_csbOwner["sp_reel_0"],self.m_onceClipNode))
    self.m_onceClipNode:addChild(self.m_blackLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 5000)
    self.m_blackLayer:setVisible(false)
end

--[[
    显示黑色遮罩层
]]
function CodeGameScreenClawStallMachine:showBlackLayer()
    self.m_blackLayer:setVisible(true)
    self.m_blackLayer:runCsbAction("start")
end

--[[
    隐藏黑色遮罩层
]]
function CodeGameScreenClawStallMachine:hideBlackLayer()
    self.m_blackLayer:runCsbAction("over",false,function(  )
        self.m_blackLayer:setVisible(false)
    end)
end


function CodeGameScreenClawStallMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( PublicConfig.SoundConfig.sound_ClawStall_enter_game)

    end,0.4,self:getModuleName())
end

function CodeGameScreenClawStallMachine:checkInitSpinWithEnterLevel()
    local isTriggerEffect = false
    local isPlayGameEffect = false

    if self.m_initSpinData ~= nil then
        -- 检测上次的feature 信息

        if self.m_initFeatureData == nil then
            -- 检测是否要触发 feature
            self:checkNetDataFeatures()
        end

        isPlayGameEffect = self:checkNetDataCloumnStatus()
        local isPlayFreeSpin = self:checkTriggerINFreeSpin()

        isPlayGameEffect = isPlayGameEffect or isPlayFreeSpin --self:checkTriggerINFreeSpin()
        if isPlayGameEffect and self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
            -- 这里只是用来检测是否 触发了 bonus ，如果触发了那么不调用数据生成
            isTriggerEffect = true
        end

        ----- 以下是检测初始化当前轮盘 ----
        self:checkInitSlotsWithEnterLevel()
    end

    return isTriggerEffect, isPlayGameEffect
end

function CodeGameScreenClawStallMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    --娃娃机界面
    self.m_clawMainView = ClawStallGameManager:createMainLayer({machine = self})
    self:addChild(self.m_clawMainView,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    self.m_clawMainView:setVisible(false)
    self.m_isEnter = true

    CodeGameScreenClawStallMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_jackpotBar:updateJackpotInfo()

    local maxRowCount = 3
    --初始化锁定小块
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local mapConfigData = self:getCurLockNodeInfo()
        if mapConfigData.mapRows == "maprow4" then
            maxRowCount = 4
        end
        self:changeBg("free")
    else
        self:changeBg("base")
    end

    self:changeMainUI(maxRowCount)
    if maxRowCount == 4 then
        self:changeReelData(maxRowCount)
    end
    self.m_curReelRowCount = maxRowCount
    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:initLockWildSymbol()
        self:showFreeSpinBar()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self.m_bottomUI:showAverageBet()
    end

    --地图界面装载数据
    self.m_mapView:loadMapContent()

    --刷新当前betlevel
    self:updateBetLevel()

    --刷新收集进度
    self:updateCollectProcess(true)

    if self:collectBarClickEnabled() then
        self.m_collectBar:showTip()
    end


    --测试代码
    -- self:showClawView()
end

--[[
    修改主界面
]]
function CodeGameScreenClawStallMachine:changeMainUI(rowCount)
    if self.m_curReelRowCount == rowCount then
        return
    end
    
    self.m_iReelRowNum = rowCount

    self:findChild("Node_4Rows"):setVisible(rowCount == 4)
    self:findChild("Node_3Rows"):setVisible(rowCount == 3)

    self:findChild("Node_4Rows"):setScale(SCALE_ROWS_4)
    if rowCount == 3 then
        self:findChild("Node_sp_reels"):setScale(1)
    else
        self:findChild("Node_sp_reels"):setScale(SCALE_ROWS_4)
        self.m_lockNode:setScale(SCALE_ROWS_4)
    end

    self:findChild("Node_Progress"):setVisible(rowCount == 3)
    self:findChild("Node_CollectionTarget"):setVisible(rowCount == 3)
    self:findChild("Node_RespinBar"):setVisible(rowCount == 3)
end


function CodeGameScreenClawStallMachine:changeReelData(rowCount)
    if self.m_curReelRowCount == rowCount then
        return
    end
    for i = self.m_iReelRowNum , 1, - 1 do
        if self.m_stcValidSymbolMatrix[i] == nil then
            self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
        end
    end
    

    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i,self.m_iReelRowNum,true)
    end

    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum

        local rect = self.m_onceClipNode:getClippingRegion()
        self.m_onceClipNode:setClippingRegion(
            {
                x = rect.x, 
                y = rect.y, 
                width = rect.width, 
                height = columnData.p_slotColumnHeight
            }
        )
    end

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
end

-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
function CodeGameScreenClawStallMachine:initCloumnSlotNodesByNetData()
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
                symbolType = 0
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
            -- node:runIdleAnim()      
            rowIndex = rowIndex - 1
        end  -- end while
    end
    self:initGridList()
end

function CodeGameScreenClawStallMachine:getAnimNodeFromPool(symbolType, ccbName)
    if not symbolType then
        release_print(debug.traceback())
        release_print("sever传回的数据：  " .. (globalData.slotRunData.severGameJsonData or "isnil"))
        release_print(
            "error_userInfo_ udid=" ..
                (globalData.userRunData.userUdid or "isnil") .. " machineName=" .. (globalData.slotRunData.gameModuleName or "isLobby") .. " gameSeqID = " .. (globalData.seqId or "")
        )
        release_print("AnimNodeFromPool error not symbolType!!!    ccbName:" .. ccbName)
        return nil
    end
    if ccbName == nil then
        ccbName = self:getSymbolCCBNameByType(self, symbolType)
    end

    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}
        self.m_reelAnimNodePool[symbolType] = reelPool
    end

    if #reelPool == 0 then
        -- 扩展支持 spine 的元素
        local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
        local node = nil
        if spineSymbolData ~= nil then
            node = SlotsSpineAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType, spineSymbolData[3])
            node:initSpineInfo(spineSymbolData[1], spineSymbolData[2])
            -- node:runDefaultAnim()
        else
            node = SlotsAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:runDefaultAnim()
        end

        return node
    else
        local node = reelPool[1] -- 存内存池取出来
        table.remove(reelPool, 1)
        -- node:runDefaultAnim()

        -- print("从尺子里面拿 SlotsAnimNode")

        return node
    end
end

--[[
    显示娃娃机界面
]]
function CodeGameScreenClawStallMachine:showClawView(func)
    --刷新界面
    local bonusData = self.m_runSpinResultData.p_bonusExtra
    if self.m_initFeatureData and self.m_initFeatureData.p_status == "OPEN" then
        bonusData = self.m_initFeatureData.p_bonus.extra
    end
    ClawStallGameManager:setAutoStatus(true)
    self.m_clawMainView:updateBonusData(bonusData)
    self.m_clawMainView:updateView()
    self.m_clawMainView:setVisible(true)
    self.m_clawMainView:setEndFunc(func)
    self.m_gameBg:setVisible(false)


    self:findChild("Node_1"):setVisible(false)
    self.m_bottomUI:setVisible(false)

    util_changeNodeParent(self.m_clawMainView.m_clawInfoView:findChild("Node_MachineJackpotView"),self.m_jackpotBar)
    self.m_jackpotBar:findChild("Node_stick"):setVisible(false)
end

--[[
    隐藏娃娃机界面
]]
function CodeGameScreenClawStallMachine:hideClawView( )
    self.m_clawMainView:setVisible(false)
    self.m_clawMainView:setEndFunc()
    self.m_clawMainView:stopSchedule()
    self.m_gameBg:setVisible(true)

    self:findChild("Node_1"):setVisible(true)
    self.m_bottomUI:setVisible(true)

    util_changeNodeParent(self:findChild("Node_JackpotView"),self.m_jackpotBar)
    self.m_jackpotBar:findChild("Node_stick"):setVisible(true)
end

function CodeGameScreenClawStallMachine:addObservers()
    CodeGameScreenClawStallMachine.super.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
        end
        
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --freespin最后一次spin不会播大赢,需单独处理
            local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            if fsLeftCount <= 0 then
                self.m_bIsBigWin = false
            end
        end
        
        if self.m_bIsBigWin then
            return
        end

        if self.m_triggerRespin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winRatio = winCoin / lTatolBetNum
        local soundIndex = 1
        local soundTime = 2
        if winRatio > 0 then
            if winRatio <= 1 then
                soundIndex = 1
            elseif winRatio > 1 and winRatio <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = PublicConfig.SoundConfig["sound_ClawStall_winline_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_ClawStall_fs_winline_"..soundIndex] 
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenClawStallMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenClawStallMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function CodeGameScreenClawStallMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0 
    if betCoin >= self.m_specialBets[1].p_totalBetValue then
        level = 1
    end
    if level ~= self.m_iBetLevel then
        self.m_collectBar:setLockStatus(level == 0)
    end
    self.m_iBetLevel = level
end

--[[
    初始化收集条
]]
function CodeGameScreenClawStallMachine:initCollectBar( )
    self.m_collectBar = util_createView("CodeClawStallSrc.ClawStallCollectBar",{machine = self})
    self:findChild("Node_Progress"):addChild(self.m_collectBar)

    self.m_collectTarget = util_createAnimation("ClawStall_Base_CollectionTarget.csb")
    self:findChild("Node_CollectionTarget"):addChild(self.m_collectTarget)
end

--[[
    刷新收集进度
]]
function CodeGameScreenClawStallMachine:updateCollectProcess(isInit)
    self.m_collectBar:updateProcess(isInit)
end

---
--设置bonus scatter 层级
function CodeGameScreenClawStallMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif self:isBonusType(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
        if symbolType == self.SYMBOL_BONUS_2 then
            order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 50
        end
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

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenClawStallMachine:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_ClawStall_Bonus"
    end

    if symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_ClawStall_Bonus2"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_ClawStall_10"
    end

    if symbolType == self.SYMBOL_SCORE_EMPTY then
        return "Socre_ClawStall_Empty"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenClawStallMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenClawStallMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenClawStallMachine:MachineRule_initGame(  )

    
end

--
--单列滚动停止回调
--
function CodeGameScreenClawStallMachine:slotOneReelDown(reelCol)    
    local isTriggerLongRun = CodeGameScreenClawStallMachine.super.slotOneReelDown(self,reelCol) 
    if isTriggerLongRun then
        if not self.m_isTriggerLongRun then
            self.m_isTriggerLongRun = isTriggerLongRun
        end
    end

    --播放期待动画
    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(reelCol,iRow)
        if symbolNode and symbolNode.p_symbolType and self:isBonusType(symbolNode.p_symbolType) then
            self.m_longRunSymbols[#self.m_longRunSymbols + 1] = symbolNode
            --图标提层
            local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
            util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
            symbolNode:setPositionY(curPos.y)

            symbolNode:runAnim("buling",false,function(  )
                if not self.m_isTriggerLongRun then
                    symbolNode:runAnim("idleframe",true)
                else
                    symbolNode:runAnim("idleframe2",true)
                end 
            end)

            if not self.m_bonus_down[reelCol] then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_bonus_down)
            end
            
            if self.m_isNewReelQuickStop then
                for index = 1,self.m_iReelColumnNum do
                    self.m_bonus_down[index] = true
                end
            else
                self.m_bonus_down[reelCol] = true
            end
        end
    end

    

    if self.m_isTriggerLongRun then
        for i,symbolNode in ipairs(self.m_longRunSymbols) do
            if symbolNode.p_cloumnIndex < reelCol and symbolNode.m_currAnimName ~= "idleframe2" then
                symbolNode:runAnim("idleframe2",true)
            end
        end
    end
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenClawStallMachine:symbolBulingEndCallBack(_slotNode)
    
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenClawStallMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenClawStallMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

function CodeGameScreenClawStallMachine:triggerFreeSpinCallFun()
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
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self:showFreeSpinBar()
    self.m_bProduceSlots_InFreeSpin = true
    self:resetMusicBg()
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenClawStallMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("ClawStallSounds/music_ClawStall_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        self.m_bottomUI:showAverageBet()
        self.m_bottomUI:updateWinCount("")
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                --修改行数
                local maxRowCount = 3
                local mapConfigData = self:getCurLockNodeInfo()
                if mapConfigData.mapRows == "maprow4" then
                    maxRowCount = 4
                end
                self:changeBg("free")
                self:changeMainUI(maxRowCount)
                self:changeReelData(maxRowCount)
                self.m_curReelRowCount = maxRowCount

                self:initLockWildSymbol()
                
                if maxRowCount == 4 then
                    self:runCsbAction("start",false,function(  )
                        self:runCsbAction("idle",true)
                    end)
                end

                if self.m_mapView:isVisible() then
                    self.m_mapView:hideView()
                end
                

                --触发freespin
                self:triggerFreeSpinCallFun()

                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        end
    end

    self:delayCallBack(0.5,function(  )
        showFSView()
    end)
    

end

function CodeGameScreenClawStallMachine:showFreeSpinStart(num, func, isAuto)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_free_start)
    local view = util_createView("CodeClawStallSrc.ClawStallFreeStartView",{num = num,func = function(  )
        if type(func) == "function" then
            func()
        end
    end})
    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    view:findChild("root"):setScale(self.m_machineRootScale)

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenClawStallMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_free_over)
    local view = self:showFreeSpinOver( globalData.slotRunData.lastWinCoin, self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        local spine = util_spineCreate("ClawStall_JSGC",true,true)
        gLobalViewManager:showUI(spine)
        util_setCascadeOpacityEnabledRescursion(spine,true)
        spine:setPosition(display.center)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_change_scene_to_base)
        util_spinePlay(spine,"guochang")
        util_spineEndCallFunc(spine,"guochang",function(  )
            
            spine:setVisible(false)
            self:delayCallBack(0.1,function(  )
                spine:removeFromParent()
            end)

            self:triggerFreeSpinOverCallFun()
        end)

        self:delayCallBack(13 / 30,function(  )
            if self.m_iReelRowNum == 4 then
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()
                self:runCsbAction("over",false,function(  )
                    self:runCsbAction("idle",true)
                end)
            end
    
            --修改行数
            self:changeMainUI(3)
            self:changeReelData(3)
            self.m_curReelRowCount = 3
    
            self:changeBg("base")
    
            --清理锁定小块
            self:clearLockNodes()

            

            self.m_bottomUI:hideAverageBet()
        end)
        
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},800)

end

--[[
    断线重连检测bonus
]]
function CodeGameScreenClawStallMachine:initFeatureInfo(spinData,featureData)
    if featureData.p_bonus and featureData.p_bonus.status == "CLOSED" then
        return
    end
    local features = spinData.p_features
    --判断是否触发feature
    local isTriggerBonus = false
    for i,featureID in ipairs(features) do
        if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            isTriggerBonus = true
        end
    end
    
    if featureData.p_bonus and featureData.p_bonus.status == "OPEN" or isTriggerBonus then
        self:addBonusEffect()
    end
end

--[[
    添加bonus事件
]]
function CodeGameScreenClawStallMachine:addBonusEffect( )
    if self:checkHasEffectType(GameEffect.EFFECT_BONUS) then
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    self.m_isRunningEffect = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})

end

--[[
    显示收集玩法界面
]]
function CodeGameScreenClawStallMachine:showEffect_Bonus(effectData)
    
    self:showBonusStart(function(  )
        self:resetMusicBg(true,"ClawStallSounds/music_ClawStall_bonus.mp3")
        --显示娃娃机界面
        self:showClawView(function(featureData)
            self.m_runSpinResultData:parseResultData(featureData, self.m_lineDataPool)
            local winCoins = self.m_runSpinResultData.p_bonusWinCoins or 0
            --检测是否获得大赢
            self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)

            --bonus图标播idle
            for iCol = 1,self.m_iReelColumnNum do
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol,iRow)
                    if symbolNode and symbolNode.p_symbolType and self:isBonusType(symbolNode.p_symbolType) then
                        if self:isBonusType(symbolNode.p_symbolType) then
                            symbolNode:runAnim("idleframe",true)
                        end
                    end
                end
            end

            --显示娃娃机结算弹板
            self:showBonusOverView(winCoins,function(  )
                --隐藏娃娃机界面
                self:hideClawView()
                self.m_initFeatureData = nil
                effectData.p_isPlay = true
                self:playGameEffect()
                self:removeGameEffectType(GameEffect.EFFECT_BONUS)
            end)
            
        end)
    end)
    
end

--[[
    bonus开始界面
]]
function CodeGameScreenClawStallMachine:showBonusStart(func)
    if not self.m_runSpinResultData.p_bonusExtra then
        if type(func) == "function" then
            func()
        end
        return
    end
    local count = self.m_runSpinResultData.p_bonusExtra.totalbonustime or 0
    local view = util_createView("CodeClawStallSrc.ClawStallBonusStartView",{num = count,machine = self,func = function(  )
        
        if self.m_isRespinOver then
            self:changeReSpinOverUI()
            self:removeRespinNode()
            self:setReelSlotsNodeVisible(true)
            self.m_isRespinOver = false
        end
        

        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(iCol,iRow)
                if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_SCORE_EMPTY then
                    local randSymbolType = math.random(0,9)
                    self:changeSymbolType(symbolNode,randSymbolType)
                end
            end
        end

        if type(func) == "function" then
            func()
        end
    end})
    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    bonus结算弹板
]]
function CodeGameScreenClawStallMachine:showBonusOverView(winCoins,func)
    self.m_iOnceSpinLastWin = winCoins
    if winCoins > 0 then
        self:clearCurMusicBg()
    end
    local view = util_createView("CodeClawStallSrc.ClawStallBonusOverView",{winCoins = winCoins,func = function()
        if winCoins == 0 then
            self:clearCurMusicBg()
        end
        local params = {self.m_iOnceSpinLastWin, true}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)

        local spine = util_spineCreate("ClawStall_JSGC",true,true)
        gLobalViewManager:showUI(spine)
        util_setCascadeOpacityEnabledRescursion(spine,true)
        spine:setPosition(display.center)

        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_change_scene_to_base_from_bonus)
        util_spinePlay(spine,"guochang")
        util_spineEndCallFunc(spine,"guochang",function(  )
            
            spine:setVisible(false)
            self:delayCallBack(0.1,function(  )
                spine:removeFromParent()
            end)
        end)

        self:delayCallBack(13 / 30,function(  )
            if type(func) == "function" then
                func()
            end
        end)
        
    end})
    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenClawStallMachine:showFreeSpinOver(coins, num, func,keyFunc)
    self:clearCurMusicBg()

    local view = util_createView("CodeClawStallSrc.ClawStallFreeOverView",{
        winCoins = coins,
        num = num,
        func = func
    })
    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

--[[
    固定wild小块
]]
function CodeGameScreenClawStallMachine:initLockWildSymbol( )
    local mapConfigData = self:getCurLockNodeInfo()
    local fixPos = mapConfigData.fixPos
    if fixPos then
        for i,posIndex in ipairs(fixPos) do
            local clipTarPos = util_getOneGameReelsTarSpPos(self,posIndex)
            local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
            local nodePos = self.m_lockNode:convertToNodeSpace(worldPos)

            local wildSymbol = util_spineCreate("Socre_ClawStall_Wild",true,true)
            util_spinePlay(wildSymbol,"idleframe")
            self.m_lockNode:addChild(wildSymbol)
            wildSymbol:setPosition(nodePos)
            self.m_lockWildNodes[#self.m_lockWildNodes + 1] = wildSymbol
        end
    end
end

--[[
    设置锁定小块是否可见
]]
function CodeGameScreenClawStallMachine:setLockNodeVisible(isShow)
    for k,lockNode in pairs(self.m_lockWildNodes) do
        lockNode:setVisible(isShow)
    end
end

--[[
    清空锁定小块
]]
function CodeGameScreenClawStallMachine:clearLockNodes()
    self.m_lockNode:removeAllChildren()
    self.m_lockWildNodes = {}
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenClawStallMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
   

    if self.m_mapView:isVisible() then
        self.m_mapView:hideView()
    end

    if self.m_collectBar.m_tip:isVisible() then
        self.m_collectBar:hideTip()
    end

    self.m_bonus_down = {}

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenClawStallMachine:beginReel()
    CodeGameScreenClawStallMachine.super.beginReel(self)
    self:setLockNodeVisible(true)
    self.m_isAlreadyUpdateCoins = false
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenClawStallMachine:addSelfEffect()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.type or selfData.collect and selfData.collect.collect and selfData.collect.collect > self.m_collectProcess.collect then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型
        self.m_collectProcess = selfData.collect
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenClawStallMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
        --等待落地播完
        -- self:delayCallBack(17 / 30,function(  )
            self:collectBonusAni(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        -- end)
    end

    
    return true
end

function CodeGameScreenClawStallMachine:collectFullShowMap(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local mapType = selfData.type
    --显示地图界面
    local posIndex = self.m_collectProcess.pos
    if posIndex > 0 then
        posIndex = posIndex - 1
    else
        posIndex = #self.m_mapList - 1
    end
    self.m_bottomUI:showAverageBet()
    self:clearWinLineEffect()
    self:checkChangeBaseParent()
    --先重置当前位置
    self.m_mapView:resetPlayerPos(posIndex)
    self.m_mapView:showView(false,function()
        self:delayCallBack(1,function(  )
            if mapType == "SMALL" and not self:checkHasBigWin() then
                --检测大赢
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
            end
            self.m_runSpinResultData.p_selfMakeData.type = nil
            
            --地图玩家位置刷新
            self.m_mapView:movePlayerAni(function()
                

                self:delayCallBack(1,function(  )
                    self.m_bottomUI:hideAverageBet()
                    self.m_mapView:hideView(function(  )
                        --重置收集进度
                        self:updateCollectProcess()
                        if type(func) == "function" then
                            func()
                        end
                    end)
                end)
                
            end)
        end)
        
    end)
end

--[[
    显示地图界面
]]
function CodeGameScreenClawStallMachine:showMapView(func)
    if self.m_mapView:isVisible() then
        self.m_mapView:hideView(func)
    else
        self.m_mapView:showView(true,func)
        self:clearWinLineEffect()
        self:checkChangeBaseParent()
    end
end

--[[
    地图玩法赢钱
]]
function CodeGameScreenClawStallMachine:flyMapWinCoinsAni(coins,startNode,func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_fly_coins_to_bottom)
    local flyNode = util_createAnimation("ClawStall_Map_xiaoguan_fenzhi.csb")
    flyNode:findChild("m_lb_coins"):setString(coins)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endNode = self.m_bottomUI.coinWinNode
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(0.5,endPos),
        cc.CallFunc:create(function()
            local lightAni = util_createAnimation("ClawStall_yingqianqu.csb")
            self.m_bottomUI.coinWinNode:addChild(lightAni)
            lightAni:runCsbAction("actionframe2",false,function(  )
                lightAni:removeFromParent()
            end)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, true})
            self.m_isAlreadyUpdateCoins = true
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
    flyNode:runCsbAction("animation")
end

function CodeGameScreenClawStallMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or (globalData.slotRunData.freeSpinCount > 0 and globalData.slotRunData.freeSpinCount ~= globalData.slotRunData.totalFreeSpinCount)then
        isNotifyUpdateTop = false
    end

    if not self.m_isAlreadyUpdateCoins then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

--[[
    收集bonus图标动画
]]
function CodeGameScreenClawStallMachine:collectBonusAni(func)
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType and self:isBonusType(symbolNode.p_symbolType) then
                self:flyParticleAni(symbolNode,self.m_collectTarget)
                -- symbolNode:runAnim("shouji",false,function(  )
                --     symbolNode:runAnim("idleframe",true)
                -- end)
            end
        end
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_collect_bonus_base)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isTriggerRespin = #self.m_runSpinResultData.p_features > 1
    

    self:delayCallBack(16 / 30,function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_collect_bonus_feed_back_base)
        local feedBackAni = util_createAnimation("ClawStall_shoujichu.csb")
        self.m_effectNode:addChild(feedBackAni)
        feedBackAni:setPosition(util_convertToNodeSpace(self.m_collectTarget,self.m_effectNode))
        feedBackAni:runCsbAction("actionframe2",false,function(  )
            feedBackAni:removeFromParent()
        end)
        --刷新收集进度
        self:updateCollectProcess()
        if selfData.type then
            self:delayCallBack(80 / 60,function(  )
                --集满显示地图
                self:collectFullShowMap(function(  )
                    if type(func) == "function" then
                        func()
                    end
                end)
            end)
            return
        end

        if isTriggerRespin then
            self:delayCallBack(80 / 60,function(  )
                if type(func) == "function" then
                    func()
                end
            end)
            return
        end
    end)

    if not selfData.type and not isTriggerRespin then
        if type(func) == "function" then
            func()
        end
    end
end

--[[
    飞粒子动画
]]
function CodeGameScreenClawStallMachine:flyParticleAni(startNode,endNode,func)
    
    local flyNode = util_createAnimation("ClawStall_lizitv.csb")
    local particle = flyNode:findChild("Particle_1")
    particle:setPositionType(0)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(16 / 30,endPos),
        cc.CallFunc:create(function()
            particle:stopSystem()
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenClawStallMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenClawStallMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenClawStallMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenClawStallMachine:operaEffectOver( )
    CodeGameScreenClawStallMachine.super.operaEffectOver(self)
    if self.m_isEnter then
        self.m_isEnter = false
        return
    end
    self:resetMusicBg()
end

function CodeGameScreenClawStallMachine:slotReelDown( )

    --bonus图标重置idle动画
    if self.m_isTriggerLongRun then
        for k,symbolNode in pairs(self.m_longRunSymbols) do
            if symbolNode.m_currAnimName == "idleframe2" then
                symbolNode:runAnim("idleframe",true)
            end
        end
    end
    self.m_isTriggerLongRun = false
    self.m_longRunSymbols = {}

    --变更固定小块
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local mapConfigData = self:getCurLockNodeInfo()
        local fixPos = mapConfigData.fixPos
        for i,posIndex in ipairs(fixPos) do
            local pos = self:getRowAndColByPos(posIndex)
            local symbolNode = self:getFixSymbol(pos.iY, pos.iX, SYMBOL_NODE_TAG)
            self:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD)
        end
        self:setLockNodeVisible(false)
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenClawStallMachine.super.slotReelDown(self)
end

function CodeGameScreenClawStallMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenClawStallMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    if not storedIcons then
        return self:randomDownRespinSymbolScore(self.SYMBOL_BONUS)
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

    return score
end

function CodeGameScreenClawStallMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if self:isBonusType(symbolType) then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getBnBasePro()
    end


    return score
end

-- 给respin小块进行赋值
function CodeGameScreenClawStallMachine:setSpecialNodeScore(sender,symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end
    local score = 0

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
    else
        score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score == nil then
                score = 1
            end
        end
    end

    if symbolNode and symbolNode.p_symbolType then
        local lbl_score = self:getLblOnBonusSymbol(symbolNode)
        symbolNode.m_score = score
        score = "X"..score
        local label = lbl_score:findChild("m_lb_multiplier")
        label:setString(score)

        self:updateLabelSize({label=label,sx=0.6,sy=0.6},156)
    end
end

--[[
    获取bonus小块上的label
]]
function CodeGameScreenClawStallMachine:getLblOnBonusSymbol(symbolNode)
    local aniNode = symbolNode:checkLoadCCbNode()
    local symbolType = symbolNode.p_symbolType
    local lblName = "Socre_ClawStall_Bonus_1.csb"
    if symbolType == self.SYMBOL_BONUS_2 then
        lblName = "Socre_ClawStall_Bonus_2.csb"
    end
    local spine = aniNode.m_spineNode
    if spine and not spine.m_lbl_score then
        local label = util_createAnimation(lblName)
        util_spinePushBindNode(spine,"kb",label)
        spine.m_lbl_score = label
    end

    return spine.m_lbl_score
end

function CodeGameScreenClawStallMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isBonusType(symbolType) then
        self:setSpecialNodeScore(self,node)
    end
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenClawStallMachine:getRespinRandomTypes( )
    local symbolList = { 
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenClawStallMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_BONUS_2, runEndAnimaName = "buling", bRandom = true}
    }

    return symbolList
end

function CodeGameScreenClawStallMachine:showRespinView()

    --先播放动画 再进入respin
    self:clearCurMusicBg()

    self:clearWinLineEffect()


    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_bonus_trigger)
    --触发动画
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType then
                if self:isBonusType(symbolNode.p_symbolType) then
                    symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                    symbolNode:changeParentToOtherNode(self.m_effectNode)
                    symbolNode:runAnim("actionframe",false,function()
                        symbolNode:runAnim("idleframe",true)
                        symbolNode:putBackToPreParent()
                    end)
                end
            end
        end
    end

    self:showBlackLayer()

    self:delayCallBack(60 / 30,function(  )
        
        
        self:showReSpinStart(function()
            self:resetMusicBg()
            self:runNextReSpinReel()
        end)
        self:delayCallBack(70 / 60,function(  )
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end)
    end)

    
end

function CodeGameScreenClawStallMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
            -- 更改respin 状态下的背景音乐
            -- self:changeReSpinBgMusic()
            
        end
    )

    self.m_respinView:addBorderLine()

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

function CodeGameScreenClawStallMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    local view = util_createView("CodeClawStallSrc.ClawStallRespinStartView",{func = function(  )
        if type(func) == "function" then
            func()
        end
    end})
    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--ReSpin开始改变UI状态
function CodeGameScreenClawStallMachine:changeReSpinStartUI(respinCount)
    self:changeBg("respin")
    self:hideBlackLayer()
    self:showFreeSpinBar()
    self.m_baseFreeSpinBar:updateRespinCount(respinCount,true)
end

--ReSpin刷新数量
function CodeGameScreenClawStallMachine:changeReSpinUpdateUI(curCount)
    self.m_baseFreeSpinBar:updateRespinCount(curCount,false)
end

--ReSpin结算改变UI状态
function CodeGameScreenClawStallMachine:changeReSpinOverUI()
    self:changeBg("base")
    self:hideFreeSpinBar()
end

--结束移除小块调用结算特效
function CodeGameScreenClawStallMachine:reSpinEndAction()    
    
    -- 播放收集动画效

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_respin_bonus_trigger)
    -- 获得所有固定的respinBonus小块
    local chipList = self.m_respinView:getAllCleaningNode()    
    for k,symbolNode in pairs(chipList) do
        symbolNode:runAnim("actionframe")
    end

    --显示收集条
    self.m_baseFreeSpinBar:showCollectBar()

    self:delayCallBack(60 / 30,function(  )
        
        --开始收集
        self:playChipCollectAnim(1,chipList,function()
            -- 通知respin结束
            self:respinOver()
        end)
    end)

    
end

function CodeGameScreenClawStallMachine:playChipCollectAnim(curIndex,symbolList,func)
    if curIndex > #symbolList then
        self:delayCallBack(1,function()
            if type(func) == "function" then
                func()
            end
        end)
        
        return
    end
    local symbolNode = symbolList[curIndex]
    if symbolNode then
        local endNode = self.m_baseFreeSpinBar:getCollectItemByIndex(curIndex)
        symbolNode:runAnim("shouji2")
        self:flyCollectBonusCount(symbolNode.m_score,symbolNode,endNode,function()
            self.m_baseFreeSpinBar:updateCollectBar(curIndex,symbolNode.m_score,symbolNode.p_symbolType)
            self:playChipCollectAnim(curIndex + 1,symbolList,func)
        end)
    else
        self:playChipCollectAnim(curIndex + 1,symbolList,func)
    end
end

--[[
    收集分数动画
]]
function CodeGameScreenClawStallMachine:flyCollectBonusCount(count,startNode,endNode,func)
    
    -- local flyNode = util_spineCreate("Socre_ClawStall_Bonus",true,true)
    -- local label = util_createAnimation("Socre_ClawStall_Bonus_1.csb")
    -- util_spinePushBindNode(flyNode,"kb",label)
    -- local label = label:findChild("m_lb_multiplier"):setString("X"..count)

    local flyNode = util_createAnimation("ClawStall_Machine_xin.csb")
    flyNode:findChild("m_lb_multiplier"):setString("X"..count)
    flyNode:findChild("m_lb_multiplier_0"):setString("X"..count)
    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
    flyNode:findChild("Gold"):setVisible(startNode.p_symbolType == self.SYMBOL_BONUS_2)
    flyNode:findChild("Normal"):setVisible(startNode.p_symbolType == self.SYMBOL_BONUS)
    flyNode:findChild("m_lb_multiplier"):setVisible(startNode.p_symbolType == self.SYMBOL_BONUS)
    flyNode:findChild("m_lb_multiplier_0"):setVisible(startNode.p_symbolType == self.SYMBOL_BONUS_2)
    

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_collect_bonus_respin)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(30 / 60,endPos),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_collect_bonus_feed_back_respin)
            local feedBackAni = util_createAnimation("ClawStall_shoujichu.csb")
            self.m_effectNode:addChild(feedBackAni)
            feedBackAni:setPosition(endPos)
            feedBackAni:runCsbAction("actionframe",false,function(  )
                feedBackAni:removeFromParent()
            end)
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
    flyNode:runCsbAction("shouji")
    -- util_spinePlay(flyNode,"shouji")
end

function CodeGameScreenClawStallMachine:respinOver()
    self:addBonusEffect()

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    self.m_isRespinOver = true

    
    self:triggerReSpinOverCallFun(0)
    
    self.m_lightScore = 0


end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenClawStallMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local zOrder = self:getBounsScatterDataZorder(node.p_symbolType)
    node.p_showOrder = zOrder - node.p_rowIndex + node.p_cloumnIndex * 10
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)
end

function CodeGameScreenClawStallMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil


    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    -- self:resetMusicBg(true)
    
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--[[
    延迟回调
]]
function CodeGameScreenClawStallMachine:delayCallBack(time, func)
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

function CodeGameScreenClawStallMachine:updateNetWorkData()
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

    self.m_isWaitingNetworkData = false
    self:operaNetWorkData() -- end
end

--[[
    获取当前固定小块的位置信息
]]
function CodeGameScreenClawStallMachine:getCurLockNodeInfo()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local posIndex = selfData.collect.pos 
    if posIndex == 0 then
        posIndex = #self.m_mapList
    end
    return self.m_mapList[posIndex]
end

--[[
    设置滚动数据
]]
function CodeGameScreenClawStallMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        end
        local runLen = reelRunData:getReelRunLen()
        bonusNum, bRunLong = self:setBonusScatterInfo(self.SYMBOL_BONUS, col , bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenClawStallMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  true,true

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if self:isBonusType(symbolType) then 
        showCol = self.m_ScatterShowCol
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        local tempSymbolType = self:getSymbolTypeForNetData(column,row,runLen)
        if  self:isBonusType(tempSymbolType)  then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
        
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenClawStallMachine:getRunStatus(col, nodeNum, showCol)
    if nodeNum >= 4 then
        return runStatus.DUANG, true
    else
        return runStatus.DUANG, false
    end
end

function CodeGameScreenClawStallMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

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
    

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

    local ratio = display.height / display.width
    local winSize = cc.Director:getInstance():getWinSize()
    if ratio >= 768 / 1024 then
        mainScale = 0.74
    elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
        mainScale = 0.83
        mainPosY = mainPosY
    elseif ratio < 640 / 960 and ratio > 768 / 1370 then
        mainScale = 0.88
    elseif ratio >= 768 / 1370 then
        mainScale = 1
    else
        mainScale = 1
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

function CodeGameScreenClawStallMachine:isBonusType(symbolType)
    if symbolType == self.SYMBOL_BONUS or symbolType == self.SYMBOL_BONUS_2 then
        return true
    end

    return false
end

---
-- 增加赢钱后的 效果
function CodeGameScreenClawStallMachine:addLastWinSomeEffect() -- add big win or mega win
    local notAddEffect = self:checkIsAddLastWinSomeEffect()

    if notAddEffect then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    local fsExtra = self.m_runSpinResultData.p_fsExtraData
    if self:getCurrSpinMode() == FREE_SPIN_MODE and fsExtra and fsExtra.avgBet then
        lTatolBetNum = fsExtra.avgBet
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    local curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

return CodeGameScreenClawStallMachine






