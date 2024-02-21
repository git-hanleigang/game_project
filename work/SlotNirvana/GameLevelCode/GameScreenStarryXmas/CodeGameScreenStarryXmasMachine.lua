---
-- island li
-- 2019年1月26日
-- CodeGameScreenStarryXmasMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "StarryXmasPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenStarryXmasMachine = class("CodeGameScreenStarryXmasMachine", BaseSlotoManiaMachine)

CodeGameScreenStarryXmasMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenStarryXmasMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1 --base下收集bonus
CodeGameScreenStarryXmasMachine.EFFECT_TYPE_TEN_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 2 --第10次spin
CodeGameScreenStarryXmasMachine.BONUS_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 进度条集满bonus

CodeGameScreenStarryXmasMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1 
CodeGameScreenStarryXmasMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenStarryXmasMachine.SYMBOL_SCORE_12 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3   
CodeGameScreenStarryXmasMachine.SYMBOL_FIX_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 
CodeGameScreenStarryXmasMachine.SYMBOL_FIX_BONUS_KUANG = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 100

-- 构造函数
function CodeGameScreenStarryXmasMachine:ctor()
    CodeGameScreenStarryXmasMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_iBetLevel = 0 -- bet等级 betlevel 0 1 
    self.m_bonusData = {} --地图数据
    self.m_betNetKuangData = {} -- 不同bet对应的框数据
    self.m_collectData = {} --进度条收集相关数据
    self.m_isQuicklyStop = false --是否点击快停
    self.m_collectList = nil --每次spin滚动出来bonus图标 存储bonus
    self.m_FixBonusKuang  = {} --base 下存储锁定框
    self.m_FreeSpinFixBonusKuang  = {} -- free 下存储锁定框
    self.m_superFreeSpinFixBonusKuang = {} -- superfree 下存储锁定框
    self.m_FreeSpinFixBonusWild = {}
    self.m_reelNodeWildByBigSymbol = {} --存储框变wild的时候 下面是 长条的情况
    self.m_betTotalCoins = 0
    self.m_bigItemInfo = {}
    self.isBigPro = false   --小地图是否是大关
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
 
    --init
    self:initGame()
end

function CodeGameScreenStarryXmasMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenStarryXmasMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "StarryXmas"  
end


function CodeGameScreenStarryXmasMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self:runCsbAction("idle",true)
    -- base spin计数栏 
    -- 收集次数
    self.m_baseCollectBar = util_createView("CodeStarryXmasSrc.collect.StarryXmasCollectTimesBarView",{machine = self})        
    self:findChild("jishu_base"):addChild(self.m_baseCollectBar)
   
    -- 收集进度条部分
    self.m_topCollectBar = util_createView("CodeStarryXmasSrc.collect.StarryXmasCollectBarView")         
    self:findChild("shoujilan"):addChild(self.m_topCollectBar)
    self.m_topCollectBar:runCsbAction("idle",true)
    self.collectTipView = self.m_topCollectBar.collectTipView
    self.collectTipView.m_states = nil

    self.m_FixBonusLayer = self:findChild("Node_fixBonusLayer")
    self.m_KuangLayer = self:findChild("Node_kuang")

    -- 第10次spin使用
    self.m_tenBonusLayer = cc.Node:create()
    self:findChild("root"):addChild(self.m_tenBonusLayer,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 2)

    self.m_jiesuanAct = self.m_bottomUI.coinWinNode

    -- 大赢动画
    self.m_bigwinEffect = util_spineCreate("StarryXmas_bigwin", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigwinEffect)
    self.m_bigwinEffect:setVisible(false)

    -- 大赢动画 粒子
    self.m_bigwinEffectLiZi = util_createAnimation("StarryXmas_daying_lizi.csb")
    self:findChild("Node_bigwin"):addChild(self.m_bigwinEffectLiZi)
    self.m_bigwinEffectLiZi:setVisible(false)

    --大赢
    self.m_bigwinTopEffect = util_spineCreate("StarryXmas_bigwin_fk", true, true)
    self:findChild("Node_guochang"):addChild(self.m_bigwinTopEffect)
    self.m_bigwinTopEffect:setVisible(false)

    --大赢飘数字
    self.m_bigwinEffectNum = util_createAnimation("StarryXmas_yingqianzi.csb")
    self.m_bottomUI.coinWinNode:addChild(self.m_bigwinEffectNum)
    self.m_bigwinEffectNum:setVisible(false)

    -- free过场动画
    self.m_guochangFreeEffect = util_spineCreate("StarryXmas_guochang",true,true)
    self:findChild("Node_guochang"):addChild(self.m_guochangFreeEffect, 10)
    self.m_guochangFreeEffect:setVisible(false)

    -- free over过场动画
    self.m_guochangFreeOverEffect = util_spineCreate("StarryXmas_guochang2",true,true)
    self:findChild("Node_guochang"):addChild(self.m_guochangFreeOverEffect, 10)
    self.m_guochangFreeOverEffect:setVisible(false)

    --遮罩
    self.m_maskAni = util_createAnimation("StarryXmas_yaan.csb")
    self.m_clipParent:addChild(self.m_maskAni,  SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 1)
    self.m_maskAni:setVisible(false)

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)

    self:setReelBg(1)
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2free
]]
function CodeGameScreenStarryXmasMachine:setReelBg(_BgIndex)
    
    if _BgIndex == 1 then
        self:findChild("Reel_base"):setVisible(true)
        self:findChild("Reel_FG"):setVisible(false)

        self.m_gameBg:findChild("Base"):setVisible(true)
        self.m_gameBg:findChild("Free"):setVisible(false)
        self.m_gameBg:runCsbAction("baceidle",true)

        self.m_baseCollectBar:setVisible(true)
        self.m_topCollectBar:setVisible(true)
    elseif _BgIndex == 2 then
        self:findChild("Reel_base"):setVisible(false)
        self:findChild("Reel_FG"):setVisible(true)

        self.m_gameBg:findChild("Base"):setVisible(false)
        self.m_gameBg:findChild("Free"):setVisible(true)
        self.m_gameBg:runCsbAction("idle",true)

        self.m_baseCollectBar:setVisible(false)
        self.m_topCollectBar:setVisible(false)
    end
end

--[[
    显示free 计数条
]]
function CodeGameScreenStarryXmasMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""
    if FreeType == "PickFree" then
        self.m_baseFreeSpinBar:refreshInfo(true)
    else
        self.m_baseFreeSpinBar:refreshInfo(false)
    end

    util_setCsbVisible(self.m_baseFreeSpinBar, true)

end

--[[
    隐藏free 计数条
]]
function CodeGameScreenStarryXmasMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

--[[
    创建free 计数条
]]
function CodeGameScreenStarryXmasMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("jishu_free")
        self.m_baseFreeSpinBar = util_createView("CodeStarryXmasSrc.StarryXmasFreespinBarView", {machine = self})
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
    end
end

function CodeGameScreenStarryXmasMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 5, 0, 1)
    end,0.2,self:getModuleName())
end

function CodeGameScreenStarryXmasMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenStarryXmasMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    -- 弹出tips
    if self:isNormalStates() then
        self.collectTipView:setVisible(true)
        self.collectTipView.m_states = "show"
        
        self.collectTipView:runCsbAction("show",false,function(  )

            self.collectTipView.m_states = "idle"
            self.collectTipView:runCsbAction("idle")
            performWithDelay(self.collectTipView,function( )
                self.collectTipView:runCsbAction("over",false,function (  )
                    self.collectTipView.m_states = "idle"
                    self.collectTipView:setVisible(false)
                end)
            end,5)
        end)
    end

    -- 还原锁定框
    self:initKuangUI()

    self:createMapScroll( )     --创建地图
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    self.m_betTotalCoins = totalBet  

    self:upateBetLevel(true)
end

function CodeGameScreenStarryXmasMachine:addObservers()
    CodeGameScreenStarryXmasMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin and not self.m_triggerBigWinEffect then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgmType = "fg"
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
            local FreeType = fsExtraData.FreeType or ""
            if FreeType == "PickFree" then
                bgmType = "superFg"
            end
        else
            bgmType = "base"
        end

        local soundName = "StarryXmasSounds/music_StarryXmas_last_win_".. bgmType.."_"..soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    -- 高低bet
    gLobalNoticManager:addObserver(self,function(self,params)
        if not params.p_isLevelUp then
            -- 切换bet解锁进度条
            self:changeBetCallBack()
        end
   end,ViewEventType.NOTIFY_BET_CHANGE)

    -- 地图
    gLobalNoticManager:addObserver(self,function(self,params)
        if self:isNormalStates( )  then
            if self:getBetLevel() == 0 then
                self:unlockHigherBet()
            else
                self:showMapScroll(nil,true)
            end
            
        end
    end,"SHOW_BONUS_MAP")

    -- 进度条说明
    gLobalNoticManager:addObserver(self,function(self,params)
        if self.getCurrSpinMode() == NORMAL_SPIN_MODE and self.getGameSpinStage() == IDLE then
            self:clickMapTipView()
        end
    end,"SHOW_BONUS_Tip")
end

function CodeGameScreenStarryXmasMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenStarryXmasMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenStarryXmasMachine:initGameStatusData(gameData)

    CodeGameScreenStarryXmasMachine.super.initGameStatusData(self, gameData)
    
    --存储不同bet 锁定框信息
    if gameData.gameConfig ~= nil and  gameData.gameConfig.bets ~= nil then
        self:initBetNetKuangData(gameData.gameConfig.bets)
    end

    --存储地图信息
    if gameData then
        if gameData.gameConfig then
            if gameData.gameConfig.extra then
                if gameData.gameConfig.extra.map then
                    self.m_bonusData = clone(gameData.gameConfig.extra.map)
                end
                
            end
        end
    end
end

--[[
    棋盘上有锁定框的时候 进入free玩法 会移除锁定框
    这个函数 是移除锁定框之后 随机补一个小块
]]
function CodeGameScreenStarryXmasMachine:changeLockFixNodeNode( isFreeStart)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spintimes = selfdata.spinTimes or 0
    -- 如果这一轮的次数为第十次那么就不变了
    -- 因为fix symbol 已经变成wild了
    if spintimes == 10  then
        return
    end

    for colIndex = 1, self.m_iReelColumnNum do
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        for rowIndex = 1, self.m_iReelRowNum do
            local netSymbolType = self.m_stcValidSymbolMatrix[rowIndex][colIndex]
            if netSymbolType == self.SYMBOL_FIX_BONUS then
                local symbolNode = self:getFixSymbol(colIndex, rowIndex, SYMBOL_NODE_TAG)
                local symbolType = self:getRandomReelType(colIndex, reelDatas)
                while true do
                    if self.m_bigSymbolInfos[symbolType] == nil then
                        break
                    end
                    symbolType = self:getRandomReelType(colIndex, reelDatas)
                end

                while true do
                    if symbolType ~= self.SYMBOL_FIX_BONUS and symbolType ~= 0 then
                    
                        break
                    end
                    symbolType = self:getRandomReelType(colIndex, reelDatas)
                end

                if symbolNode   then
                    if not symbolNode:isVisible() then
                        symbolNode:setVisible(true)
                        -- symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType),symbolType)
                        self:changeSymbolType(symbolNode, symbolType, true)
                        symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(symbolType))
                        symbolNode:runIdleAnim()
                    end
                else
                    self:createNewNodeByReel(symbolType, rowIndex, colIndex)
                end
            end
        end
    end
end

--[[
    在棋盘上补一个小块
]]
function CodeGameScreenStarryXmasMachine:createNewNodeByReel(symbolType, rowIndex, colIndex)
    local targSp = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)   
    if targSp and targSp.p_symbolType then 
        targSp.m_symbolTag = SYMBOL_NODE_TAG
        targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

        self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_FIX_NODE_TAG + 1) -- 为了参与连线
        local position =  self:getNodePosByColAndRow(rowIndex, colIndex)
        targSp:setPosition(cc.p(position))
        targSp:setTag(self:getNodeTag(colIndex, rowIndex, SYMBOL_NODE_TAG))
    end
    return targSp
end

--[[
    切换bet解锁进度条
]]
function CodeGameScreenStarryXmasMachine:changeBetCallBack( )
    self:upateBetLevel()

    local totalBet = globalData.slotRunData:getCurTotalBet( )

    -- 不同的bet切换才刷新框
    if self.m_betTotalCoins ~=  totalBet  then
        self.m_betTotalCoins = totalBet
        -- 根据bet刷新框显示
        self:removeAllBaseKuang()
        self:initCollectKuang(true )
        self:updateCollectTimes(true)
        self:changeLockFixNodeNode( )
    end
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenStarryXmasMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_10  then
        return "Socre_StarryXmas_10"
    elseif symbolType == self.SYMBOL_SCORE_11  then
        return "Socre_StarryXmas_11"
    elseif symbolType == self.SYMBOL_SCORE_12 then
        return "Socre_StarryXmas_12"
    elseif symbolType == self.SYMBOL_FIX_BONUS then  
        return "Socre_StarryXmas_WildBonus"
    elseif symbolType == self.SYMBOL_FIX_BONUS_KUANG then
        return "Socre_StarryXmas_FIx_Bonus"
    end

    return nil
end

--[[
    根据配置初始轮盘
]]
function CodeGameScreenStarryXmasMachine:initSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local initDatas = self.m_configData:getInitReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        local startIndex = 1
        --大信号数量
        local bigSymbolCount = 0
        for rowIndex = 1, rowCount do
            local symbolType = initDatas[startIndex]
            startIndex = startIndex + 1
            if startIndex > #initDatas then
                startIndex = 1
            end

            --判断是否是否属于需要隐藏
            local isNeedHide = false
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                bigSymbolCount = bigSymbolCount + 1
                if bigSymbolCount > 1 then
                    isNeedHide = true
                    symbolType = 1
                end

                if bigSymbolCount == self.m_bigSymbolInfos[symbolType] then
                    bigSymbolCount = 0
                end
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if isNeedHide then
                node:setVisible(false)
            end

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenStarryXmasMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenStarryXmasMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_12,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS,count =  12}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS_KUANG,count =  12}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenStarryXmasMachine:MachineRule_initGame(  )
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setReelBg(2)
        --更新fs次数ui 显示
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local FreeType = fsExtraData.FreeType or ""
        if FreeType == "PickFree" then
            self:setFsBackGroundMusic(self.m_publicConfig.Music_SuperFree_Bg)--fs背景音乐
            self.m_fsReelDataIndex = self.COllECT_FS_RUN_STATES
            self.m_bottomUI:showAverageBet()
            self:createSuperFsKuang(nil,true)
        else
            self:setFsBackGroundMusic(self.m_publicConfig.Music_FG_Bg)--fs背景音乐
            self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
        end
    end
    
end

function CodeGameScreenStarryXmasMachine:playCustomSpecialSymbolDownAct( slotNode )

    if slotNode and slotNode.p_symbolType == self.SYMBOL_FIX_BONUS then 
        local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100000)
        slotNode:runAnim("buling",false)
    end
end

--[[
    处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
]]
function CodeGameScreenStarryXmasMachine:specialSymbolActionTreatment(_node)
    if _node and _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        local symbolNode = util_setSymbolToClipReel(self,_node.p_cloumnIndex, _node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)

        symbolNode:runAnim("buling",false,function()
            symbolNode:runAnim("idleframe", true)
        end)
    end

end

-- 每个reel条滚动到底
function CodeGameScreenStarryXmasMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)
    
    if isTriggerLongRun then
        -- 开始快滚的时候 其他scatter 播放ialeframe3
        self:waitWithDelay(0.1,function()
            for iCol = 1, reelCol  do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp then
                        local symbolType = targSp.p_symbolType
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            -- 触发快停
                            if self.m_isQuicklyStop then
                                targSp:runAnim("idleframe",true)
                            else
                                targSp:runAnim("idleframe3",true)
                            end
                        end
                    end
                end
            end
        end)
        
    end

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            local features = self.m_runSpinResultData.p_features
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local spinTimes = selfdata.spinTimes
            local randomPlay = math.random(1, 10)
            if not features or #features <= 1 and randomPlay <= 7 and spinTimes and spinTimes < 10 then
                local randomNum = math.random(1, 2)
                local soundEffect = self.m_publicConfig.Music_Near_MIss_Tbl[randomNum]
                gLobalSoundManager:playSound(soundEffect)
            end
            reelEffectNode[1]:runAction(cc.Hide:create())
            for iCol = 1, reelCol  do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp then
                        local symbolType = targSp.p_symbolType
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            targSp:runAnim("idleframe",true)
                        end
                    end
                end
            end
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        self:triggerLongRunChangeBtnStates()
    end
    
    return isTriggerLongRun
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenStarryXmasMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenStarryXmasMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenStarryXmasMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("StarryXmasSounds/music_StarryXmas_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        self:hideMapTipView(true)
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local FreeType = fsExtraData.FreeType or ""
        local selectReel = fsExtraData.selectReel or ""
        if FreeType == "PickFree" then
            self:setFsBackGroundMusic(self.m_publicConfig.Music_SuperFree_Bg)--fs背景音乐
            local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
            if fsWinCoin ~= 0 then
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoin))
            else
                self.m_bottomUI:updateWinCount("")
            end
            self.m_bottomUI:showAverageBet()
            self:showSuperFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:resetMusicBg(nil, self.m_publicConfig.Music_SuperFree_Bg)
                self:playGuoChangFree(function()
                    self.m_topCollectBar:initLoadingbar(0)

                    self:clearBaseKuangByFree()

                    self:setReelBg(2)
                    self:triggerFreeSpinCallFun()
                    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息
                end,function()
                    self.m_maskAni:setVisible(true)
                    self.m_maskAni:runCsbAction("start", false, function()
                        self.m_maskAni:runCsbAction("idle", true)
                        self:createSuperFsKuang(function(  )
                            self.m_maskAni:runCsbAction("over", false, function()
                                self.m_maskAni:setVisible(false)
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end)
                        end)   
                    end)
                end)      
            end)
        else
            self:setFsBackGroundMusic(self.m_publicConfig.Music_FG_Bg)--fs背景音乐
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:resetMusicBg(nil, self.m_publicConfig.Music_FG_Bg)
                self:playGuoChangFree(function()
                    self:clearBaseKuangByFree()

                    self:setReelBg(2)
                    self:triggerFreeSpinCallFun()
                end,function()
                    
                    self:createFsMoveKuang( function(  )
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end ) 
                end)
                      
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

function CodeGameScreenStarryXmasMachine:triggerFreeSpinCallFun()
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
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
end

--[[
    free玩法 过场的时候 清掉base下锁定框
]]
function CodeGameScreenStarryXmasMachine:clearBaseKuangByFree( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spintimes = selfdata.spinTimes or 0

    -- 如果这一轮的次数为第十次那么就不变了
    -- 因为fix symbol 已经变成wild了
    if spintimes ~= 10  then
        self:removeAllBaseKuang( )
    end
    -- 避免freespin开始时有空的格子，显得像有BUg一样
    self:changeLockFixNodeNode()
end

function CodeGameScreenStarryXmasMachine:showFreeSpinStart(num,func)
    
    if func then
        func()
    end
end

--开始superfs界面
function CodeGameScreenStarryXmasMachine:showSuperFreeSpinStart( num,func )
    self:levelFreeSpinEffectChange()

    self:clearCurMusicBg()

    local btnCallFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        self:waitWithDelay(5/60, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_SuperFg_StartOver)
        end)
    end
    
    gLobalSoundManager:playSound(self.m_publicConfig.Music_SuperFg_StartStart)
    local ownerlist={}
    local path = "SuperFreeSpinStart"
    local imgName = nil
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""
    local selectReel = fsExtraData.selectReel or ""
    local fixPos = fsExtraData.fixPos or {}
    ownerlist["m_lb_num"]=num
    local view =  self:showDialog(path,ownerlist,func)
    view:setBtnClickFunc(btnCallFunc)
    -- --初始化开始界面的显示位置（留）
    local maxImgNum = 20
    for i=1,maxImgNum do
        local img = view:findChild("wild_img__" .. i - 1) 
        if img then
            img:setVisible(false)
        end
    end
    for i=1,#fixPos do
        local img = view:findChild("wild_img__" .. fixPos[i]) 
        if img then
            img:setVisible(true)
        end
    end

    self:createSuperFreeStartViewByNode(view)
end

--[[
    superfree 开始弹板上挂载的文件
]]
function CodeGameScreenStarryXmasMachine:createSuperFreeStartViewByNode(_view)
    -- 弹板上的光
    local tanbanShine = util_createAnimation("StarryXmas_tanban_guang.csb")
    _view:findChild("guang"):addChild(tanbanShine)
    tanbanShine:runCsbAction("idleframe",true)
    util_setCascadeOpacityEnabledRescursion(_view:findChild("guang"), true)
    util_setCascadeColorEnabledRescursion(_view:findChild("guang"), true)

    for i=1,2 do
        -- 弹板上的光点
        local tanbanShineDian = util_createAnimation("StarryXmas_tanban_guangdian.csb")
        _view:findChild("guangdian"..i):addChild(tanbanShineDian)
        tanbanShineDian:runCsbAction("idleframe",true)
        util_setCascadeOpacityEnabledRescursion(_view:findChild("guangdian"..i), true)
        util_setCascadeColorEnabledRescursion(_view:findChild("guangdian"..i), true)
    end

    -- 弹板上的烟
    local tanbanYan = util_createAnimation("StarryXmas_tanban_yan.csb")
    _view:findChild("yan"):addChild(tanbanYan)
    tanbanYan:runCsbAction("idleframe",true)
    util_setCascadeOpacityEnabledRescursion(_view:findChild("yan"), true)
    util_setCascadeColorEnabledRescursion(_view:findChild("yan"), true)
end

--创建superFreeSpin固定wild
function CodeGameScreenStarryXmasMachine:createSuperFsKuang( func,isinit)
    self.m_superFreeSpinFixBonusKuang = {}
    local selfData = self.m_runSpinResultData.p_fsExtraData or {}
    local startWildPositions =  selfData.fixPos or {1,5,6,7}
    local time = 0.08
    if isinit then
        time = 0
    else
        local symbolNodeRandom = {
            1, 6, 11, 16, 2,
            7, 12, 17, 3, 8,
            13, 18, 4, 9, 14,
            19, 5, 10, 15, 20
        }
        local tempTbl = {}
        for i=1, #symbolNodeRandom do
            local curPos = symbolNodeRandom[i]-1
            for j=1, #startWildPositions do
                if curPos == startWildPositions[j] then
                    table.insert(tempTbl, curPos)
                    break
                end
            end
        end
        startWildPositions = tempTbl
    end
    --固定wild的位置
    if startWildPositions then
        for wildPositionsIndex=1,#startWildPositions do
            self:waitWithDelay(((wildPositionsIndex-1) * time) + 0.2,function(  )
                gLobalSoundManager:playSound(self.m_publicConfig.Music_SuperFg_Wild_Appear)
                local v = startWildPositions[wildPositionsIndex]
                local pos = tonumber(v)   
                local wildSpine = util_spineCreate("Socre_StarryXmas_Wild", true, true)
                self.m_KuangLayer:addChild(wildSpine, 10)
                util_spinePlay(wildSpine,"sd",false)
                wildSpine:setName("fsSuperKuang_" .. tostring(wildPositionsIndex))
                local position =  self:getBaseReelsTarSpPos(pos)
                wildSpine:setPosition(cc.p(position))
                wildSpine.m_pos = pos
                table.insert(self.m_superFreeSpinFixBonusKuang,wildSpine)
            end)
        end
    end
    local waitTime = ( (#startWildPositions - 1) * time) + 44/60
    self:waitWithDelay(waitTime,function()
        if func then
            func()
        end
    end)
end

-- free过场动画
function CodeGameScreenStarryXmasMachine:playGuoChangFree(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_Fg_CutScene)
    self.m_guochangFreeEffect:setVisible(true)
    util_spinePlay(self.m_guochangFreeEffect, "actionframe_guochang", false)

    -- switch  62帧
    util_spineFrameCallFunc(self.m_guochangFreeEffect, "actionframe_guochang", "qiehuan", function()
        if _func1 then
            _func1()
        end
    end, function()
        self.m_guochangFreeEffect:setVisible(false)
        if _func2 then
            _func2()
        end
    end)
end

-- free over过场动画
function CodeGameScreenStarryXmasMachine:playGuoChangFreeOver(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Base_CutScene)
    self.m_guochangFreeOverEffect:setVisible(true)
    util_spinePlay(self.m_guochangFreeOverEffect, "actionframe_guochang", false)

    -- switch  74帧
    util_spineFrameCallFunc(self.m_guochangFreeOverEffect, "actionframe_guochang", "qh", function()
        if _func1 then
            _func1()
        end
    end, function()
        self.m_guochangFreeOverEffect:setVisible(false)
        if _func2 then
            _func2()
        end
    end)
end

function CodeGameScreenStarryXmasMachine:showFreeSpinOverView()

    
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""

    if FreeType == "PickFree" then
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_SuperFg_OverStart, 3, 0, 1)
    else
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_overStart, 3, 0, 1)
    end

    local btnCallFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        self:waitWithDelay(5/60, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_overOver)
        end)
    end
    local view = self:showFreeSpinOver( strCoins, 
    self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:playGuoChangFreeOver(function()
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local currentPos = selfData.currentPos or 0
            local needCount = self.m_collectData.maxScatters 
            local pickScatters =  self.m_collectData.pickScatters 
            
            if pickScatters == needCount then
                if fsExtraData.collect then
                    pickScatters = 0
                end
            end

            self:updateCollectLoading(pickScatters ,needCount)

            self.m_bottomUI:hideAverageBet()

            local totalBet = globalData.slotRunData:getCurTotalBet( )
            local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 
            local selfdata =  wilddata or {}
            local oldSpinTimes = selfdata.spinTimes or 0

            if oldSpinTimes and oldSpinTimes == 10  then
                -- 第10次就不还原固定框了
            else
                self:initCollectKuang( )
            end
            
            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
            self:clearFrames_Fun()
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
            --移除free中的框（wild）
            if FreeType == "PickFree" then
                self:removeAllSuperWildKuang()
                self.m_mapNodePos = currentPos -- 更新最新位置
                self.m_map.m_currPos = self.m_mapNodePos
                self:changeProgress()
            else
                self:removeAllFsKuang()
            end
            
            self:setReelBg(1)
        end, function()
            self:triggerFreeSpinOverCallFun()
        end)
    end)
    view:setBtnClickFunc(btnCallFunc)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},730)
end

function CodeGameScreenStarryXmasMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    local view = nil
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""
    if FreeType == "PickFree" then
        view = self:showDialog("SuperFreeSpinOver", ownerlist, func)
        self:createSuperFreeStartViewByNode(view)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
        --角色
        local tanbanJuese1 = util_spineCreate("Socre_StarryXmas_5",true,true)
        view:findChild("xueren"):addChild(tanbanJuese1)
        util_spinePlay(tanbanJuese1, "idleframe2", true)

        local tanbanJuese2 = util_spineCreate("Socre_StarryXmas_9",true,true)
        view:findChild("juese"):addChild(tanbanJuese2)
        util_spinePlay(tanbanJuese2, "idleframe2", true)

        local tanbanJuese3 = util_spineCreate("Socre_StarryXmas_9",true,true)
        view:findChild("shou"):addChild(tanbanJuese3)
        util_spinePlay(tanbanJuese3, "idleframe3", true)

        -- 弹板上的光
        local tanbanShine = util_createAnimation("StarryXmas_tanban_guang.csb")
        view:findChild("guang"):addChild(tanbanShine)
        tanbanShine:runCsbAction("idleframe",true)
        util_setCascadeOpacityEnabledRescursion(view:findChild("guang"), true)
        util_setCascadeColorEnabledRescursion(view:findChild("guang"), true)
    end

    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenStarryXmasMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )

    self:hideMapScroll()

    self:hideMapTipView()

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
function CodeGameScreenStarryXmasMachine:addSelfEffect()
    self.m_collectList = nil
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node then
                    if node.p_symbolType == self.SYMBOL_FIX_BONUS then
                        if not self.m_collectList then
                            self.m_collectList = {}
                        end
                        self.m_collectList[#self.m_collectList + 1] = node
                    end
                end
            end
        end

        if self.m_collectList and #self.m_collectList > 0 then
            --收集星星
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT
        end
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local spinTimes = selfdata.spinTimes
        local kaungList = selfdata.wildPositions or {}
        local PickGame = selfdata.PickGame
        if spinTimes then
            if spinTimes == 10 and kaungList and #kaungList > 0 then
                --第十次所有框都变成wild
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_TEN_COLLECT
            end
        end
        --是否触发收集小游戏
        if PickGame then 
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_FIVE_OF_KIND + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
        end
    end
end

--[[
    获取星星飞行之前的延迟时间
    星星飞之前 bonus 有落地动画 区分一下 4 5列的延迟时间
]]
function CodeGameScreenStarryXmasMachine:getBonusXingXingFlyTime( )
    local delayTime = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_FIX_BONUS then
                    if iCol == 5 then
                        delayTime = 5/30
                    end
                end
            end
        end
    end
    if self.m_isQuicklyStop then
        delayTime = 5/30
    end

    return delayTime
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenStarryXmasMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        local delayTime = self:getBonusXingXingFlyTime()
        self:waitWithDelay(delayTime,function()
            self:collectFixBonus(effectData )
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_TEN_COLLECT then  
        self:fixBonusTurnWild( effectData )
    elseif effectData.p_selfEffectType == self.BONUS_GAME_EFFECT then
        self:showEffect_CollectBonus(effectData)
    end

    return true
    
end

--[[
    第10次spin 变成wild
]]
function CodeGameScreenStarryXmasMachine:fixBonusTurnWild( effectData )

    local time = 0.1

    local actList = {}
    for i=1,#self.m_FixBonusKuang do
        local node = self.m_FixBonusKuang[i]
        table.insert( actList, node)
    end

    table.sort( actList, function( a,b )

        local icolA = a.p_cloumnIndex
        local icolB = b.p_cloumnIndex

        return icolA < icolB
    end )

    local sortList = {}
    for i=1,#actList do
        local node = actList[i]
        local index = node.p_cloumnIndex
        local list = sortList[index]
        if list == nil then
            sortList[index] = {}
        end
        table.insert( sortList[index], actList[i] )
    end

    for k,v in pairs(sortList) do
        local list = v
        if list then
            table.sort( list, function( a,b )
                local irowA = a.p_rowIndex 
                local irowB = b.p_rowIndex 
        
                return irowA > irowB
            end )
        end
    end

    
    local sortNodeList = {}
    for i=1,5 do
        local list = sortList[i]
        if list then
            for k = 1,#list do

                table.insert( sortNodeList, list[ k ] )
            end
        end
    end
    
    for nodeIndex=1,#sortNodeList do
        self:waitWithDelay(((nodeIndex-1) * time) + 0.2,function(  )
            local node = sortNodeList[nodeIndex]
            node:stopAllActions()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_TenSpins_Wild_Appear)
            node:runCsbAction("sd2", false, function()
                local fixPos = self:getRowAndColByPos(node.m_pos) 
                local nodeQiPan = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                if not nodeQiPan then
                    nodeQiPan = self:getBigFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                end
                if nodeQiPan and nodeQiPan.p_symbolType ~= 0 then
                    nodeQiPan:setVisible(true)
                    self:changeSymbolType(nodeQiPan, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    nodeQiPan:setName("")
                else
                    local newNode = self:createNewNodeByReel(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY)
                    nodeQiPan = newNode
                    table.insert(self.m_reelNodeWildByBigSymbol, newNode)
                end
                local linePos = {}
                linePos[#linePos + 1] = {iX = nodeQiPan.p_rowIndex, iY = nodeQiPan.p_cloumnIndex}
                nodeQiPan.m_bInLine = true
                nodeQiPan:setLinePos(linePos)
                nodeQiPan:runAnim("idleframe", false)

                node:removeFromParent()
                node = nil
            end)

            self:tenSpinCreateWild(node)

            -- 锁定框上的4个粒子
            if node then
                for i=1,4 do
                    node:findChild("Particle_sd_"..i):resetSystem()
                end
            end
        end )
    end

    self.m_FixBonusKuang = {}

    local waitTime = ( (#actList -1) * time) + 33/60 + 0.2
    
    self:waitWithDelay(waitTime, function()
        effectData.p_isPlay = true
        self:playGameEffect() 
    end)
end

--[[
    第10次spin 边wild的时候 在锁定框上面在创建一个wild
]]
function CodeGameScreenStarryXmasMachine:tenSpinCreateWild(_node)
    local startPos = _node:getParent():convertToWorldSpace(cc.p(_node:getPosition()))
    local newStartPos = self.m_tenBonusLayer:convertToNodeSpace(startPos)

    local wildSpine = util_spineCreate("Socre_StarryXmas_Wild", true, true)
    self.m_tenBonusLayer:addChild(wildSpine, 100)
    wildSpine:setPosition(newStartPos)
    util_spinePlay(wildSpine,"sd",false)
    self:waitWithDelay(29/30, function()
        wildSpine:removeFromParent()
        wildSpine = nil
    end)
end
--[[
    延时函数
]]
function CodeGameScreenStarryXmasMachine:waitWithDelay(time, endFunc)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(endFunc) == "function" then
                endFunc()
            end
        end,
        time
    )

    return waitNode
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenStarryXmasMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenStarryXmasMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenStarryXmasMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenStarryXmasMachine:slotReelDown( )
    self:changeReelNodeByFree()

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenStarryXmasMachine.super.slotReelDown(self)
end

function CodeGameScreenStarryXmasMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end


function CodeGameScreenStarryXmasMachine:changeReelNodeByFree()
    -- free玩法停轮的时候 改变棋盘上的小块为 wild
    for k=1,#self.m_FreeSpinFixBonusKuang do
        local node = self.m_FreeSpinFixBonusKuang[k]
        local fixPos = self:getRowAndColByPos(node.m_pos) 
        local nodeQiPan = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if nodeQiPan and nodeQiPan.p_symbolType ~= 0 then
            self:changeSymbolType(nodeQiPan, TAG_SYMBOL_TYPE.SYMBOL_WILD)
            nodeQiPan:setName("")
        else --棋盘上滚动出来的这个位置 是长条 补一个小块
            local newNode = self:createNewNodeByReel(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY)
            nodeQiPan = newNode
            table.insert(self.m_reelNodeWildByBigSymbol, newNode)
        end

        local linePos = {}
        linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
        nodeQiPan.m_bInLine = true
        nodeQiPan:setLinePos(linePos)
        nodeQiPan:runAnim("idleframe", false)

        node:setVisible(false)
    end
    for k=1,#self.m_FreeSpinFixBonusWild do
        local node = self.m_FreeSpinFixBonusWild[k]
        node:setVisible(false)
    end

    -- superfree玩法停轮的时候 改变棋盘上的小块为 wild
    for k=1,#self.m_superFreeSpinFixBonusKuang do
        local node = self.m_superFreeSpinFixBonusKuang[k]
        local fixPos = self:getRowAndColByPos(node.m_pos) 
        local nodeQiPan = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if nodeQiPan and nodeQiPan.p_symbolType ~= 0 then
            self:changeSymbolType(nodeQiPan, TAG_SYMBOL_TYPE.SYMBOL_WILD)
            nodeQiPan:setName("")
        else --棋盘上滚动出来的这个位置 是长条 补一个小块
            local newNode = self:createNewNodeByReel(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY)
            nodeQiPan = newNode
            table.insert(self.m_reelNodeWildByBigSymbol, newNode)
        end

        local linePos = {}
        linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
        nodeQiPan.m_bInLine = true
        nodeQiPan:setLinePos(linePos)
        nodeQiPan:runAnim("idleframe", false)

        node:setVisible(false)
    end
    for k=1,#self.m_superFreeSpinFixBonusKuang do
        local node = self.m_superFreeSpinFixBonusKuang[k]
        node:setVisible(false)
    end
end

----------------------------------------地图相关----start---------------------------------------
--[[
    创建地图
]]
function CodeGameScreenStarryXmasMachine:createMapScroll( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.currentPos or 0

    self.m_mapNodePos = currentPos

    self.m_map = util_createView("CodeStarryXmasSrc.StarryXmasMap.StarryXmasBonusMapScrollView", self.m_bonusData, self.m_mapNodePos,self)
    self:findChild("map"):addChild(self.m_map)
    self.m_map:setVisible(false)
    
end

--[[
    存储地图 大关信息
]]
function CodeGameScreenStarryXmasMachine:setBigItemInfo( )
    for k,v in pairs(self.m_bonusData) do
        table.insert( self.m_bigItemInfo,v)
    end
end

--[[
    获取地图大关信息
]]
function CodeGameScreenStarryXmasMachine:getIsBigType( curPos )
    local pos = 0
    if curPos < 60 then
        pos = curPos + 1
    else
        pos = 1
    end
    for i,v in pairs(self.m_bigItemInfo) do
        if v.pos == pos and v.type == "BIG" then
            return v
        end
    end
    return nil
end

--是否可以点击
function CodeGameScreenStarryXmasMachine:isNormalStates( )
    
    local featureLen = self.m_runSpinResultData.p_features or {}

    if #featureLen >= 2 then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        return false
    end

    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return false
    end

    if self.m_bonusReconnect and self.m_bonusReconnect == true then
        return false
    end

    return true
end

--展示地图
function CodeGameScreenStarryXmasMachine:showMapScroll(callback,canTouch)
    if (self.m_bCanClickMap == false or not self:mapBtnIsCanClick()) and callback == nil then
        return
    end
    -- gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
    self.m_bCanClickMap = false

    if self.m_map:getMapIsShow() == true then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Map_Close)
        self.m_baseCollectBar:SetFadeOut()
        self.m_map:mapDisappear(function()

            self:resetMusicBg(true)

            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)

            self.m_bCanClickMap = true
        end)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Map_Open)
        if canTouch then
            self:resetMusicBg(nil, self.m_publicConfig.Music_Collect_Bg)
        end
        -- self:clearCurMusicBg()
        self:hideMapTipView(true)
        -- self:removeSoundHandler( )
        self.m_baseCollectBar:setFadeIn()
        
        self.m_map:mapAppear(function()
            self.m_bCanClickMap = true

            if callback then
                callback()
            end
        end)
        if canTouch then
            self.m_map:setMapCanTouch(true)
        else
            self.m_map:hidMoveBtn( )
        end
    end
    
end

--[[
    关闭地图
]]
function CodeGameScreenStarryXmasMachine:hideMapScroll()
    if self.m_map:getMapIsShow() == true then
        self.m_bCanClickMap = false
        self:resetMusicBg(true)
        self.m_baseCollectBar:SetFadeOut()
        self.m_map:mapDisappear(function()
            self.m_bCanClickMap = true
        end)

    end
end

--提示 进度条说明
function CodeGameScreenStarryXmasMachine:clickMapTipView( )
    if self.m_map:getMapIsShow() ~= true then
        -- gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        if not self.collectTipView:isVisible() then
            self:showMapTipView( )
        else
            self:hideMapTipView( )
        end
    end
end

--[[
    打开说明tips
]]
function CodeGameScreenStarryXmasMachine:showMapTipView( )
    if self:isNormalStates( ) then  --是否可以点击
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Tips_Open)
        if self.collectTipView.m_states == nil or self.collectTipView.m_states == "idle" then
            self.collectTipView:setVisible(true)
            self.collectTipView.m_states = "show"

            self.collectTipView:stopAllActions()
            self.collectTipView:runCsbAction("show",false,function(  )
                self.collectTipView.m_states = "idle"
                self.collectTipView:stopAllActions()
                self.collectTipView:runCsbAction("idle")
                performWithDelay(self.collectTipView,function( )
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Tips_Close)
                    self.collectTipView:stopAllActions()
                    self.collectTipView:runCsbAction("over",false,function (  )
                        self.collectTipView.m_states = "idle"
                        self.collectTipView:setVisible(false)
                    end)
                end,5)
            end)  
        end
    end
end

--[[
    关闭说明tips
]]
function CodeGameScreenStarryXmasMachine:hideMapTipView( _close )
    if self.collectTipView.m_states == "idle" then
        if self.collectTipView:isVisible() then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Tips_Close)
        end
        self.collectTipView.m_states = "over"
        self.collectTipView:stopAllActions()
        self.collectTipView:runCsbAction("over",false,function(  )
            self.collectTipView.m_states = "idle"
            self.collectTipView:setVisible(false)
        end)   
    end
    if _close then
        self.collectTipView:setVisible(false)
        self.collectTipView.m_states = "over"
        self.collectTipView:runCsbAction("over",false,function(  )
            self.collectTipView.m_states = "idle"
            self.collectTipView:setVisible(false)
        end)
    end
end

----------------------------------------地图相关----end---------------------------------------



----------------------------------------高低bet start----------------------------------------

function CodeGameScreenStarryXmasMachine:getBetLevel( )

    return self.m_iBetLevel
end

function CodeGameScreenStarryXmasMachine:unlockHigherBet()
    if self.m_bProduceSlots_InFreeSpin == true or
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and
    self:getGameSpinStage() ~= IDLE ) or
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end

    self:hideMapTipView()
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local bets = betList[i]
        if bets.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = bets.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenStarryXmasMachine:updatProgressLock( minBet , _isComeIn)

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if _isComeIn then
        if betCoin >= minBet  then
            self.m_iBetLevel = 1 
            -- 解锁进度条
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Top_Process_UnLock)
            self.m_topCollectBar:unLock(self.m_iBetLevel)
        else
            self.m_iBetLevel = 0  
            -- 锁定进度条
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Top_Process_Lock)
            self.m_topCollectBar:lock(self.m_iBetLevel)
        end 
    else
        if betCoin >= minBet  then
            if self.m_iBetLevel == nil or self.m_iBetLevel == 0 then
                self.m_iBetLevel = 1 
                -- 解锁进度条
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Top_Process_UnLock)
                self.m_topCollectBar:unLock(self.m_iBetLevel)
            end
        else
            if self.m_iBetLevel == nil or self.m_iBetLevel == 1 then
                self.m_iBetLevel = 0  
                -- 锁定进度条
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Top_Process_Lock)
                self.m_topCollectBar:lock(self.m_iBetLevel)
            end
        end 
    end
end

function CodeGameScreenStarryXmasMachine:getMinBet( )
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenStarryXmasMachine:upateBetLevel(_isComeIn)
    local minBet = self:getMinBet( )
    self:updatProgressLock( minBet , _isComeIn) 
end

----------------------------------------高低bet end----------------------------------------

----------------------------------------框 start-------------------------------------------

--[[
    进入游戏 初始化锁定框
]]
function CodeGameScreenStarryXmasMachine:initKuangUI( )
    self:updateCollectData( )
    local selfData = self.m_runSpinResultData.p_selfMakeData 
    local needCount = 0
    local pickScatters =  0
    if selfData then
        needCount = selfData.maxScatters 
        pickScatters =  selfData.pickScatters 
    end
    
    if pickScatters and needCount and pickScatters >= needCount then
        pickScatters = 0
    end
    self.m_topCollectBar:updateLoadingbar(pickScatters ,needCount,true)
    self:updateCollectTimes( )
    self:setBigItemInfo()
    --设置进度条尾部显示
    self:changeProgress()

    local totalBet = globalData.slotRunData:getCurTotalBet( )
    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 
    local selfdata =  wilddata or {}
    local oldSpinTimes = selfdata.spinTimes or 0
  
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if oldSpinTimes and oldSpinTimes == 10  then
            -- 第10次就不还原固定框了
        else
            self:initCollectKuang( )
        end
    else    
        local selfdata = self.m_runSpinResultData.p_fsExtraData or {}
        if selfdata.collect then
            self.m_bottomUI:showAverageBet()
        end
        
        self:createFsMoveKuang( nil, true )
        self.m_baseCollectBar:setVisible(false)
        self.m_topCollectBar:setVisible(false)
    end
end

--[[
    初始化base下锁定框
]]
function CodeGameScreenStarryXmasMachine:initCollectKuang(isBetChange )

    local totalBet = globalData.slotRunData:getCurTotalBet( )
    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 

    local selfdata = wilddata or {} 
    local kaungList = selfdata.wildPositions or {}
    local spintimes = selfdata.spinTimes or 0

    --第10次spin 没有锁定框
    if isBetChange and (spintimes == 10) then
        return
    end

    for i=1,#kaungList do
        local v = kaungList[i]
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos) 
        local targSp =  util_createAnimation("Socre_StarryXmas_FIx_Bonus.csb")
        targSp:runCsbAction("kuang",true)
        targSp.m_pos = pos
        targSp:setName(tostring(pos))
        self.m_KuangLayer:addChild(targSp,1)
        targSp.p_cloumnIndex = fixPos.iY
        targSp.p_rowIndex = fixPos.iX

        local position =  self:getBaseReelsTarSpPos(pos )
        targSp:setPosition(cc.p(position))
        table.insert( self.m_FixBonusKuang,targSp)
    end
end

--[[
    普通free玩法 结束 移除锁定框
]]
function CodeGameScreenStarryXmasMachine:removeAllFsKuang( )
    for i=1,#self.m_FreeSpinFixBonusKuang do
        local node = self.m_FreeSpinFixBonusKuang[i]
        node:removeFromParent()
        node = nil
    end

    self.m_FreeSpinFixBonusKuang = {}

    for k=1,#self.m_FreeSpinFixBonusWild do
        local node = self.m_FreeSpinFixBonusWild[k]
        node:removeFromParent()
        node = nil
    end
    self.m_FreeSpinFixBonusWild = {}
end

--[[
    superfree 玩法结束 移除锁定框
]]
function CodeGameScreenStarryXmasMachine:removeAllSuperWildKuang()
    for i=1,#self.m_superFreeSpinFixBonusKuang do
        local node = self.m_superFreeSpinFixBonusKuang[i]
        node:removeFromParent()
        node = nil
    end
    self.m_superFreeSpinFixBonusKuang = {}
end

--[[
    base 下锁定框 移除
]]
function CodeGameScreenStarryXmasMachine:removeAllBaseKuang( )
    for i=1,#self.m_FixBonusKuang do
        local node = self.m_FixBonusKuang[i]
        node:removeFromParent()
        node = nil
    end

    self.m_FixBonusKuang = {}
end

function CodeGameScreenStarryXmasMachine:initBetNetKuangData(bets )
    if bets then
        self.m_betNetKuangData = bets
    end
end

function CodeGameScreenStarryXmasMachine:updateBetNetKuangData( )
    local selfdata =  self.m_runSpinResultData.p_selfMakeData
    if selfdata then
        local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
        local wilddata =  self.m_betNetKuangData[tostring(totalBet)] 
        if wilddata == nil then
            self.m_betNetKuangData[tostring(totalBet)] = {}
            wilddata =  self.m_betNetKuangData[tostring(totalBet)]
        end
        if selfdata.wildPositions then
            wilddata.wildPositions = selfdata.wildPositions
        end
        
        if selfdata.spinTimes then
            wilddata.spinTimes = selfdata.spinTimes
        end

    end

end
----------------------------------------框 end-----------------------------------


---------------------------------------------------collect 相关-------start-------------------------------------------
--更新最大收集和当前收集
function CodeGameScreenStarryXmasMachine:updateCollectData( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData 
    if selfdata then
        self.m_collectData.maxScatters = selfdata.maxScatters
        self.m_collectData.pickScatters = selfdata.pickScatters
    end
end
--刷新进度条
function CodeGameScreenStarryXmasMachine:updateCollectLoading(pickScatters, needCount, func)
    if pickScatters and needCount  then
        self.m_topCollectBar:updateLoadingbar(pickScatters,needCount,false,func)
    end
end

--[[
    处理 收集星星
]]
function CodeGameScreenStarryXmasMachine:collectFixBonus(effectData )
    local needCount = self.m_collectData.maxScatters 
    local pickScatters =  self.m_collectData.pickScatters 
    local isHaveBouns = false   --是否有收集

    local cash = self.m_runSpinResultData.p_selfMakeData.cash or {}
    local lines = cash.lines

    local spinTimes = self.m_runSpinResultData.p_selfMakeData.spinTimes
    local features = self.m_runSpinResultData.p_features
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""

    if self.m_collectList and #self.m_collectList > 0 then
        isHaveBouns = true
        self:flyXingXingSymbol(self.m_collectList,function()
            if self:getBetLevel() == 0 then return end
            --这里刷新进度条 
            self:updateCollectLoading(pickScatters ,needCount, function()
                -- 进度条满 才会触发地图玩法
                -- 写到这里为了 防止加速的时候 进度条显示有问题
                if lines and #lines > 0 then
                elseif spinTimes == 10 and self.m_FixBonusKuang and #self.m_FixBonusKuang > 0 then
                elseif features and #features == 2 and features[2] == 5 then
                elseif pickScatters >= needCount then
                    --进入地图
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end)
        end)

        self.m_collectList = nil
    end

    if lines and #lines > 0 then
        --第十次所有框都变成wild
        self:waitWithDelay(2.7,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    elseif spinTimes == 10 and self.m_FixBonusKuang and #self.m_FixBonusKuang > 0 then
        --第十次所有框都变成wild
        if isHaveBouns then
            self:waitWithDelay(2.2,function(  )
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
        
    elseif features and #features == 2 and features[2] == 5 then
        --freeSpin
        self:waitWithDelay(2.7,function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif pickScatters >= needCount then
        --进入地图
        -- self:waitWithDelay(2.7,function(  )
        --     effectData.p_isPlay = true
        --     self:playGameEffect()
        -- end)
    else
        -- 延迟 就可以往下执行了
        -- self:waitWithDelay(5/60,function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        -- end)
    end
end

--收集玩法
function CodeGameScreenStarryXmasMachine:flyXingXingSymbol(list, func)

    for i=1,#self.m_FixBonusKuang do
        local fixBonusKuang = self.m_FixBonusKuang[i]
        if fixBonusKuang then
            fixBonusKuang:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100 )   --将现有的框层级降低
        end
    end
    local endPosWorld = self.m_topCollectBar:findChild("xingxing"):getParent():convertToWorldSpace(cc.p(self.m_topCollectBar:findChild("xingxing"):getPosition()))
    local endPos = self.m_FixBonusLayer:convertToNodeSpace(endPosWorld)
    local bezTime = 0.5
    local waitTime = 4/30
    
    if self:getBetLevel() == 1 then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Start_Collect)
        self:waitWithDelay(40/60,function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Start_CollectFeedBack)
        end)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Wild_Lock)
    end

    for _, node in pairs(list) do
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self.m_KuangLayer:convertToNodeSpace(startPos)

        local newNode = nil
        local reelIndex = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex )
        local oldNode = self.m_KuangLayer:getChildByName(tostring(reelIndex))
        
        if not tolua.isnull(node) then
            node:setVisible(false)
        end

        if oldNode then
            oldNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 2 )   --将oldNode层级提起来
            oldNode:stopAllActions()
            newNode = oldNode
        else
            local targSp =  util_createAnimation("Socre_StarryXmas_FIx_Bonus.csb")
            targSp:setName(tostring(reelIndex))
            targSp.m_pos = reelIndex
            self.m_KuangLayer:addChild(targSp,1)
            targSp:setPosition(newStartPos)
            targSp.p_cloumnIndex = node.p_cloumnIndex
            targSp.p_rowIndex = node.p_rowIndex
            newNode = targSp
            table.insert( self.m_FixBonusKuang,targSp)
        end
        if self:getBetLevel() == 1 then
            self:runFlyLineAct(newNode, reelIndex, newStartPos, endPos)
        else
            self:playSuoDingEffect(newNode, newStartPos)
        end      
    end
    if list and #list > 0 then
        self:waitWithDelay( bezTime + waitTime + 20/60,function(  )
            if func ~= nil then
                func()
            end
        end)
    else
        if func ~= nil then
            func()
        end
    end
end

-- 收集星星时候的拖尾
function CodeGameScreenStarryXmasMachine:runFlyLineAct(_newNode, _reelIndex, _startPos, _endPos, _func)
    -- 创建粒子拖尾
    local flyNode =  util_createAnimation("Socre_StarryXmas_tvv.csb")
    self.m_FixBonusLayer:addChild(flyNode,99)
    flyNode:setPosition(cc.p(_startPos))
    flyNode:findChild("Sprite_1"):setVisible(false)

    --星星
    local flyXingNode = self:getXingXingFlyCollect()
    self.m_FixBonusLayer:addChild(flyXingNode, 98)
    local xingxingStartPos = flyNode:findChild("Node_1"):getParent():convertToWorldSpace(cc.p(flyNode:findChild("Node_1"):getPosition()))
    local newXingXingStartPos = self.m_FixBonusLayer:convertToNodeSpace(xingxingStartPos)
    flyXingNode:setPosition(newXingXingStartPos)

    -- 创建一个新的 锁定框 层级最高 只用来播放动画 播完 删除
    local suoDingNode =  util_createAnimation("Socre_StarryXmas_FIx_Bonus.csb")
    self.m_FixBonusLayer:addChild(suoDingNode,100)
    suoDingNode:setPosition(cc.p(_startPos))

    if not tolua.isnull(_newNode) then
        _newNode:setVisible(false)
    end
    suoDingNode:findChild("daiji"):setVisible(false)
    suoDingNode:findChild("sd"):setVisible(false)
    suoDingNode:runCsbAction("sd",false,function()
        if not tolua.isnull(_newNode) then
            _newNode:setVisible(true)
        end

        self:waitWithDelay( 0.5 ,function()
            suoDingNode:removeFromParent()
            suoDingNode = nil
        end)
    end)

    util_spinePlay(flyXingNode.xingSpine, "kxs")

    -- suoDingNode的 sd 时间线 33开始 播放粒子
    self:waitWithDelay( 26/60 ,function()
        if suoDingNode then
            suoDingNode:findChild("sd"):setVisible(true)
            for i=1,4 do
                if suoDingNode:findChild("Particle_sd_"..i) then
                    suoDingNode:findChild("Particle_sd_"..i):resetSystem()
                end
            end
        end
        
    end)

    -- suoDingNode的 sd 时间线 13开始 后续流程
    self:waitWithDelay( 13/60 ,function()
        if suoDingNode then
            suoDingNode:setLocalZOrder(97)   --将现有的框层级降低
        end
        
        local particle1 = flyXingNode:findChild("Particle_1")
        util_spinePlay(flyXingNode.xingSpine, "shouji")
        if particle1 then
            particle1:setDuration(-1)     --设置拖尾时间(生命周期)
            particle1:setPositionType(0)   --设置可以拖尾
            particle1:resetSystem()
        end

        self:waitWithDelay( 4/30 ,function()
            local angle = util_getAngleByPos(_startPos,_endPos) 
            flyNode:setRotation( - angle)

            local scaleSize = math.sqrt( math.pow( _startPos.x - _endPos.x ,2) + math.pow( _startPos.y - _endPos.y,2 )) 
            local nodeScaleX = scaleSize / 700
            flyNode:setScaleX(nodeScaleX)
            --刷帧 获得node1 的坐标 赋给 星星
            local delay = 0
            flyNode:onUpdate(
            function(dt)
                delay = delay + dt
                if delay >= 0.5 then
                    flyNode:unscheduleUpdate()
                    return
                end
                local xingxingStartPos = flyNode:findChild("Node_1"):getParent():convertToWorldSpace(cc.p(flyNode:findChild("Node_1"):getPosition()))
                local newXingXingStartPos = self.m_FixBonusLayer:convertToNodeSpace(xingxingStartPos)
                if flyXingNode then
                    flyXingNode:setPosition(newXingXingStartPos)
                end
            end)

            -- 4个特殊位置 不显示 拖尾
            if _reelIndex == 0 or _reelIndex == 1 or _reelIndex == 1 or _reelIndex == 1 then
                flyNode:findChild("Sprite_1"):setVisible(false)
            else
                flyNode:findChild("Sprite_1"):setVisible(true)
            end

            flyNode:runCsbAction("actionframe",false,function(  )
                if _func then
                    _func()
                end

                flyNode:findChild("Sprite_1"):setVisible(false)

                self:waitWithDelay( 0.5 ,function(  )
                    flyNode:stopAllActions()
                    flyNode:removeFromParent()
                    flyNode = nil
                end)
            end)
            -- flyNode的 actionframe时间线 第20帧 星星消失
            self:waitWithDelay( 20/60 ,function(  )
                if not tolua.isnull(particle1) then
                    particle1:stopSystem()--移动结束后将拖尾停掉
                end
                if not tolua.isnull(flyXingNode.xingSpine) then
                    flyXingNode.xingSpine:setVisible(false)
                end

                flyXingNode:removeFromParent()
                flyXingNode = nil

                util_spinePlay(self.m_topCollectBar.xingxingSpine, "actionframe", false)
                util_spineEndCallFunc(self.m_topCollectBar.xingxingSpine,"actionframe",function()
                    util_spinePlay(self.m_topCollectBar.xingxingSpine, "actionframe_idle", true)
                end)
            end)
        end)
    end)
end

--[[
    进度条锁定的时候 不播放星星收集 只播下锁定框效果
]]
function CodeGameScreenStarryXmasMachine:playSuoDingEffect(_newNode, _startPos)
    -- 创建一个新的 锁定框 层级最高 只用来播放动画 播完 删除
    local suoDingNode =  util_createAnimation("Socre_StarryXmas_FIx_Bonus.csb")
    self.m_FixBonusLayer:addChild(suoDingNode,100)
    suoDingNode:setPosition(cc.p(_startPos))

    local xingSpine = util_spineCreate("Socre_StarryXmas_WildBonus", true, true)
    self.m_FixBonusLayer:addChild(xingSpine,99)
    xingSpine:setPosition(cc.p(_startPos))

    util_spinePlay(xingSpine, "kxs", false)
    util_spineEndCallFunc(xingSpine,"kxs",function()
        util_spinePlay(xingSpine, "over", false)
    end)
    self:waitWithDelay( 11/30 ,function()
        xingSpine:removeFromParent()
        xingSpine = nil
    end)

    if not tolua.isnull(_newNode) then
        _newNode:setVisible(false)
    end
    suoDingNode:findChild("daiji"):setVisible(false)
    suoDingNode:findChild("sd"):setVisible(false)
    suoDingNode:runCsbAction("sd",false,function()
        if not tolua.isnull(_newNode) then 
            _newNode:setVisible(true)
        end
        self:waitWithDelay( 0.5 ,function()
            suoDingNode:removeFromParent()
            suoDingNode = nil
        end)
    end)

    -- suoDingNode的 sd 时间线 33开始 播放粒子
    self:waitWithDelay( 26/60 ,function()
        if suoDingNode then
            suoDingNode:findChild("sd"):setVisible(true)
            for i=1,4 do
                suoDingNode:findChild("Particle_sd_"..i):resetSystem()
            end
        end
    end)
end

--得到一个飞行的星星 收集用
function CodeGameScreenStarryXmasMachine:getXingXingFlyCollect( )
    local flyXingNode = util_createAnimation("Socre_StarryXmas_Bonus_shouji_tuowei.csb")
    flyXingNode.xingSpine = util_spineCreate("Socre_StarryXmas_WildBonus", true, true)
    flyXingNode:findChild("Node_1"):addChild(flyXingNode.xingSpine)
    util_spinePlay(flyXingNode.xingSpine, "idleframe", false)

    return flyXingNode
end

--改变进度条尾部
function CodeGameScreenStarryXmasMachine:changeProgress()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.currentPos or 0
    local data = self:getIsBigType( currentPos )
    if data then
        self.m_topCollectBar.smallGuanNode:setVisible(false)
        self.m_topCollectBar.daGuanNode:setVisible(true)
        self.m_topCollectBar.daGuanNode:runCsbAction("idleframe",true)
        --大关wild位置显示
        self.m_topCollectBar.daGuanNode:setWildPos(data)
        self.isBigPro = true
    else
        self.m_topCollectBar.smallGuanNode:setVisible(true)
        self.m_topCollectBar.smallGuanNode:runCsbAction("idleframe",true)
        self.m_topCollectBar.daGuanNode:setVisible(false)
        self.isBigPro = false
    end
end

---------------------------------------------------collect相关-------end-------------------------------------------
--[[
    base下 spin 次数
]]
function CodeGameScreenStarryXmasMachine:updateCollectTimes(_isChangeBet)

    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local wilddata =  self.m_betNetKuangData[tostring(totalBet)] 

    local selfdata =  wilddata or {}
    local spinTimes = selfdata.spinTimes or 0
    local oldSpinTimes = selfdata.spinTimes or 0
    if spinTimes then
        if spinTimes == 10 then
            spinTimes = 0
        end
        self.m_baseCollectBar:updateTimes(spinTimes, _isChangeBet)
    end
end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenStarryXmasMachine:getBaseReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenStarryXmasMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function CodeGameScreenStarryXmasMachine:beginReel()
    -- free玩法 滚动的时候 显示出来wild
    for k=1,#self.m_FreeSpinFixBonusWild do
        local node = self.m_FreeSpinFixBonusWild[k]
        if not tolua.isnull(node) then
            node:setVisible(true)
        end
    end

    -- superfree玩法 滚动的时候 显示出来wild
    for k=1,#self.m_superFreeSpinFixBonusKuang do
        local node = self.m_superFreeSpinFixBonusKuang[k]
        if not tolua.isnull(node) then
            node:setVisible(true)
        end
    end

    -- 滚动的时候 长条上的小块 直接移除
    for k=1,#self.m_reelNodeWildByBigSymbol do
        local node = self.m_reelNodeWildByBigSymbol[k]
        if not tolua.isnull(node) then
            self:moveDownCallFun(node)
        end
    end
    self.m_reelNodeWildByBigSymbol = {}

    self.m_isQuicklyStop = false
    CodeGameScreenStarryXmasMachine.super.beginReel(self)
end

function CodeGameScreenStarryXmasMachine:requestSpinResult()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local FreeType = fsExtraData.FreeType or ""

        if FreeType == "PickFree" then

            CodeGameScreenStarryXmasMachine.super.requestSpinResult(self)

        else
            if self.m_FreeSpinFixBonusKuang and #self.m_FreeSpinFixBonusKuang then

                local freeSpinLeftTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
                local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    
                --框开始移动
                self:MoveFsKuang( function(  )
                    CodeGameScreenStarryXmasMachine.super.requestSpinResult(self)
                end )
    
            else
                CodeGameScreenStarryXmasMachine.super.requestSpinResult(self)
            end
        end
    else
        local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
        local wilddata =  self.m_betNetKuangData[tostring(totalBet)] 

        local selfdata =  wilddata or {}
        local spinTimes = selfdata.spinTimes or 0
        if spinTimes then

            if spinTimes == 10 then
                spinTimes = 0
            end
            
            self.m_baseCollectBar:updateTimes(spinTimes + 1)
        end

        CodeGameScreenStarryXmasMachine.super.requestSpinResult(self)
    end
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenStarryXmasMachine:MachineRule_afterNetWorkLineLogicCalculate()
    CodeGameScreenStarryXmasMachine.super.MachineRule_afterNetWorkLineLogicCalculate(self)
    self:updateCollectData()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

    self:updateBetNetKuangData()

    
end

---------------------------------------------------bonus相关-------start-------------------------------------------
-- 显示bonus 触发的小游戏
function CodeGameScreenStarryXmasMachine:showEffect_Bonus(effectData)
    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self.isInBonus = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Scatter 的连线， 将其移除， 并且播放一次Scatter 触发内容
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

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
    end

    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    -- -- 播放bonus 元素不显示连线
    if scatterLineValue ~= nil then
        local waitTime = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        
                        local parent = slotNode:getParent()
                        if parent ~= self.m_clipParent then
                            slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                        end
                        slotNode:runAnim("actionframe", false)

                        local duration = slotNode:getAniamDurationByName("actionframe")
                        waitTime = util_max(waitTime,duration)

                        slotNode:setVisible(false)

                        -- 重新创建一个scatter 层级放在锁定框上面
                        local startPos = slotNode:getParent():convertToWorldSpace(cc.p(slotNode:getPosition()))
                        local newStartPos = self.m_FixBonusLayer:convertToNodeSpace(startPos)
                        local newScatterSpine = util_spineCreate("Socre_StarryXmas_Scatter",true,true)
                        self.m_FixBonusLayer:addChild(newScatterSpine)
                        newScatterSpine:setPosition(newStartPos)
                        util_spinePlay(newScatterSpine, "actionframe", false)
                        self:waitWithDelay(waitTime,function()
                            slotNode:setVisible(true)
                            newScatterSpine:removeFromParent()
                            newScatterSpine = nil
                        end)
                    end
                end
            end
        end

        self:waitWithDelay(waitTime,function()
            self:showBonusGameView(effectData)
        end)

        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
         -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    return true
end

-- 根据Bonus Game 每关做的处理
--

function CodeGameScreenStarryXmasMachine:showBonusGameView( effectData )
    local features = self.m_runSpinResultData.p_features

    if features and #features == 2 and features[2] == 5 then      
        local time = 0
        self:waitWithDelay(time,function(  )
            self.m_bottomUI:checkClearWinLabel()
            self:show_Choose_BonusGameView(effectData)
        end)
    end
end

function CodeGameScreenStarryXmasMachine:showEffect_CollectBonus(effectData)
    -- gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_Trigger_Bonus.mp3")
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.currentPos or 0
    self.m_mapNodePos = currentPos -- 更新最新位置
    local LitterGameWin = selfData.LitterGameWin or 0
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local PickGame = selfData.PickGame
    -- self:clearCurMusicBg()
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    local tempTeilNode = nil
    if self.isBigPro then
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Process_Complete_Big, 3, 0, 1)
        tempTeilNode = self.m_topCollectBar.daGuanNode
    else
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Process_Complete_Small)
        tempTeilNode = self.m_topCollectBar.smallGuanNode
    end

    tempTeilNode:runCsbAction("actionframe",false,function(  )
        tempTeilNode:runCsbAction("idleframe",true)
        self.m_map:setMapCanTouch(false)
        self.m_map:hidMoveBtn()
        self:showMapScroll(function(  )
            self.m_map:pandaMove(function(  )
                if PickGame == "FreeGame" then   --大关
                    -- self:resetMusicBg(true)
                    
                    self.m_baseCollectBar:SetFadeOut()
                    self.m_map:mapDisappear(function ()
                        -- self:changeProgress()
                        self.m_map:setVisible(false)
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                else    --小关
                    local currNode = self.m_map.m_mapLayer.m_vecNodeLevel[self.m_mapNodePos]
                    
                    self:createParticleFly(currNode,LitterGameWin,function()
                        local beginCoins =  self.m_serverWinCoins - LitterGameWin
                        self:updateBottomUICoins(beginCoins,LitterGameWin,true )
                    end, function(  )
                        self.m_map:setMapCanTouch(true)
                        self.m_map:showMoveBtn()
                        
                        self.m_topCollectBar:initLoadingbar(0)
                        self.m_baseCollectBar:SetFadeOut()
                        self.m_map:mapDisappear(function(  )
                            -- self:resetMusicBg(true)
                            self:changeProgress()

                            self:checkFeatureOverTriggerBigWin( self.m_serverWinCoins , GameEffect.EFFECT_BONUS)

                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end)
                    end)
                end
            end, self.m_bonusData, self.m_mapNodePos,LitterGameWin, PickGame == "FreeGame")  
        end,false)
    end)
    
end

--[[
    free 选择弹板
]]
function CodeGameScreenStarryXmasMachine:show_Choose_BonusGameView(effectData)
    local chooseView = util_createView("CodeStarryXmasSrc.StarryXmasChooseView",self)
    self:findChild("fanye"):addChild(chooseView)
    chooseView:setPosition(cc.p(-display.width/2,-display.height/2))

    --改变棋盘样式
    chooseView:setEndCall( function(  )
        self:bonusOverAddFreespinEffect( )
        
        effectData.p_isPlay = true
        self:playGameEffect() -- 播放下一轮

        if chooseView then
            chooseView:removeFromParent()
        end
    end)
end

function CodeGameScreenStarryXmasMachine:bonusOverAddFreespinEffect( )
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

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end

--[[
    free玩法 第一次
]]
function CodeGameScreenStarryXmasMachine:createFsMoveKuang( func,isinit)
    self.m_FreeSpinFixBonusKuang = {}

    local selfData = self.m_runSpinResultData.p_fsExtraData or {}
    local startWildPositions =  selfData.startWildPositions 


    local kaungStarActName = {"up","under","left","right","up_left","up_right","under_right","under_left"}

    if startWildPositions then
        for wildPositionsIndex=1,#startWildPositions do
            local v = startWildPositions[wildPositionsIndex]
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos) 
            local targSp =  util_createAnimation("Socre_StarryXmas_FIx_Bonus.csb")
            if targSp  then 
                targSp.symbolType = self.SYMBOL_FIX_BONUS_KUANG
                targSp.m_pos = pos
                targSp:runCsbAction("kuang",true)
                targSp:setName("fsKuang_" .. tostring(wildPositionsIndex))
                self.m_KuangLayer:addChild(targSp, 10)
                
                if not isinit then
                    if pos > 10 then
                        pos = pos + 21
                    else
                        pos =  pos -21
                    end
                    targSp:setVisible(false)
                end
                local position =  self:getBaseReelsTarSpPos(pos )
                targSp:setPosition(cc.p(position))
                table.insert( self.m_FreeSpinFixBonusKuang,targSp)

                local actName = kaungStarActName[math.random( 1, #kaungStarActName)]
                --if isinit then
                    actName = "kuang"
                --end
                
                if wildPositionsIndex == 1 then
                    targSp:runCsbAction(actName,false,function(  )
                        targSp:runCsbAction("kuang",true)
                        if func then
                            func()
                        end
                    end)
                else
                    targSp:runCsbAction(actName,false,function(  )
                        targSp:runCsbAction("kuang",true)
                    end)
                    
                end
            end
        end
    end
end

--移动fs框
function CodeGameScreenStarryXmasMachine:MoveFsKuang( fun )

    local fsKuangNum = #self.m_FreeSpinFixBonusKuang
    self.m_FreeSpinFixBonusKuang = {}
    local moveList= {}
    local selfData = self.m_runSpinResultData.p_fsExtraData or {}
    local wildPositions =  selfData.wildPositions 

    for k=1,#self.m_FreeSpinFixBonusWild do
        local node = self.m_FreeSpinFixBonusWild[k]
        node:removeFromParent()
        node = nil
    end
    self.m_FreeSpinFixBonusWild = {}
    
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_Wild_ChangeBonus)
    self:waitWithDelay(5/30, function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_Wild_Move)
    end)
    if wildPositions then
        for kuangIndex=1,fsKuangNum do
            local targSp = self.m_KuangLayer:getChildByName("fsKuang_" .. tostring(kuangIndex)) 
            if not tolua.isnull(targSp) then
                targSp:setVisible(true)
            end
            
            local v = wildPositions[kuangIndex]
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local node = targSp
            node.p_cloumnIndex = fixPos.iY
            node.p_rowIndex = fixPos.iX
            
            local oldPos = cc.p(node:getPosition())
            local position =  self:getBaseReelsTarSpPos(pos )
            local turnOldX = 1
            if (oldPos.x - position.x) < 0 then
                turnOldX = -1
            elseif (oldPos.x - position.x) == 0 then
                turnOldX = 0
            end 
            local turnOldY = 1
            if (oldPos.y - position.y) < 0 then
                turnOldY = -1
            elseif (oldPos.y - position.y) == 0 then
                turnOldY = 0
            end
            local turnNewX =  1
            if (position.x - oldPos.x ) < 0 then
                turnNewX =  -1
            elseif (position.x - oldPos.x ) == 0 then
                turnNewX =  0
            end
            local turnNewY =  1
            if (position.y - oldPos.y ) < 0 then
                turnNewY =  -1
            elseif (position.y - oldPos.y ) == 0 then
                turnNewY =  0
            end
            local actList = {}
            -- free玩法 框移动的时候 判断是否是wild 是的话 先播放wild的 over时间线
            if targSp and targSp.symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local wildSpine = util_spineCreate("Socre_StarryXmas_Wild", true, true)
                self.m_KuangLayer:addChild(wildSpine, 10)
                wildSpine:setPosition(cc.p(targSp:getPosition()))
                util_spinePlay(wildSpine, "over", false)

                actList[#actList + 1 ] = cc.DelayTime:create(12/30)
                actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                    if not tolua.isnull(node) then
                        node:setVisible(true)
                    end
                    wildSpine:removeFromParent()
                    wildSpine = nil
                    table.insert( self.m_FreeSpinFixBonusKuang, targSp )
                end)

            else
                table.insert( self.m_FreeSpinFixBonusKuang, targSp )
            end

            actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                -- 待机的4个粒子
                for i=1,4 do
                    targSp:findChild("Particle_daiji_"..i):resetSystem()
                end
                targSp:runCsbAction("move",false)
            end)
            
            actList[#actList + 1 ] = cc.MoveTo:create(1,cc.p(position))
            actList[#actList + 1 ] = cc.DelayTime:create(17/60)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                if not tolua.isnull(node) then
                    node:runCsbAction("sd2", false, function()
                        if not tolua.isnull(node) then
                            node.symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
                            node.m_pos = pos
                        end
                    end)
        
                    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                    local newStartPos = self.m_tenBonusLayer:convertToNodeSpace(startPos)

                    local wildSpine = util_spineCreate("Socre_StarryXmas_Wild", true, true)
                    self.m_tenBonusLayer:addChild(wildSpine, 100)
                    wildSpine:setPosition(newStartPos)
                    util_spinePlay(wildSpine,"sd",false)
                    table.insert( self.m_FreeSpinFixBonusWild, wildSpine )
        
                    -- 锁定框上的4个粒子
                    for i=1,4 do
                        node:findChild("Particle_sd_"..i):resetSystem()
                    end
                end
            end)
            if kuangIndex == fsKuangNum then
                actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_Bonus_ChangeWild)
                end)
                actList[#actList + 1 ] = cc.DelayTime:create(1)
                actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                    for k=1,#self.m_FreeSpinFixBonusKuang do
                        local node = self.m_FreeSpinFixBonusKuang[k]
                        node:setName("fsKuang_" .. tostring(k))
                    end
                    if fun then
                        fun()
                    end
                end)
            end
            local sq = cc.Sequence:create(actList)
            node:runAction(sq)
        end
    end
end

-- 创建飞行粒子
function CodeGameScreenStarryXmasMachine:createParticleFly(currNode,coins,func1,func2)

    local fly =  util_createAnimation("StarryXmas_xiaoguan_qian.csb")
    -- self:addChild(fly,GD.GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self:addChild(fly, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+2)

    fly:findChild("m_lb_coins"):setString(util_formatCoins(coins,3))
    
    fly:runCsbAction("fly_wenzi")
    
    -- fly:setPosition(cc.p(util_getConvertNodePos(currNode:findChild("qian"), fly)))
    local startPos = util_convertToNodeSpace(currNode:findChild("qian"), self)
    fly:setPosition(cc.p(startPos.x, startPos.y))

    -- local endPos = util_getConvertNodePos(self.m_jiesuanAct ,fly)
    local endPos = util_convertToNodeSpace(self.m_jiesuanAct, self)

    local particle = fly:findChild("tuoweilizi")

    local animation = {}
    animation[#animation + 1] = cc.DelayTime:create(90/60)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        particle:setPositionType(0)
        particle:setDuration(-1)
        particle:resetSystem()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Collect_Coins)
    end)
    animation[#animation + 1] = cc.MoveTo:create(25/60, cc.p(endPos.x,endPos.y))
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        particle:stopSystem()
        if func1 then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Collect_Coins_FeedBack)
            func1()
        end
    end)
    animation[#animation + 1] = cc.DelayTime:create(5/60)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        fly:findChild("m_lb_coins"):setVisible(false)
    end)
    animation[#animation + 1] = cc.DelayTime:create(0.5)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        if func2 then
            func2()
        end
        fly:removeFromParent()
    end)
    fly:runAction(cc.Sequence:create(animation))

    -- fly_wenzi 时间线 100帧的时候播放
    self:waitWithDelay(100/60,function()
        self.m_map.m_mapLayer:xiaoGuanGouByFly(self.m_mapNodePos)
    end)
end

function CodeGameScreenStarryXmasMachine:updateBottomUICoins( beiginCoins,currCoins,isNotifyUpdateTop )
    self.m_bottomUI:playCoinWinEffectUI()
    -- free下不需要考虑更新左上角赢钱
    local endCoins = beiginCoins + currCoins
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    self.m_bottomUI:setIsAddLineWin(false)
    local params = {endCoins,isNotifyUpdateTop,nil,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    globalData.slotRunData.lastWinCoin = lastWinCoin
end

---
-- 点击快速停止reel
--
function CodeGameScreenStarryXmasMachine:quicklyStopReel(colIndex)
    self.m_isQuicklyStop = true
    CodeGameScreenStarryXmasMachine.super.quicklyStopReel(self, colIndex)
end

function CodeGameScreenStarryXmasMachine:shakeRootNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i = 1,10 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)
end

--[[
    线数 显示和 隐藏
]]
function CodeGameScreenStarryXmasMachine:playLineShowOrOver(_isShow)
    if _isShow then
        self:runCsbAction("logo_idle1", true)
        self.m_baseCollectBar:runCsbAction("map_start", false)
    else
        self:runCsbAction("xianshu_over", false)
        self.m_baseCollectBar:runCsbAction("map_over", false)
        
        -- self:findChild("Node_sp_reel"):setVisible(false)
    end
end

function CodeGameScreenStarryXmasMachine:getBottomUINode( )
    return "CodeStarryXmasSrc.StarryXmasGameBottomNode"
end

--[[
    打开地图的时候隐藏棋盘上的图标
]]
function CodeGameScreenStarryXmasMachine:showQiPanSymbolClose( )
    -- self:findChild("Node_sp_reel"):setVisible(false)
end

--[[
    关闭地图的时候 显示棋盘上的图标
]]
function CodeGameScreenStarryXmasMachine:showQiPanSymbolOpen( )
    self:findChild("Node_sp_reel"):setVisible(true)
end

--[[
    触发收集地图的 这次spin不显示大赢
]]
function CodeGameScreenStarryXmasMachine:checkIsAddLastWinSomeEffect( )
    --
    local notAdd = CodeGameScreenStarryXmasMachine.super.checkIsAddLastWinSomeEffect(self)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local PickGame = selfdata.PickGame
    if PickGame then
        return true
    end
    
    return notAdd
end

--[[
    适配
]]
function CodeGameScreenStarryXmasMachine:scaleMainLayer()
    CodeGameScreenStarryXmasMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.83
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.90 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.97 - 0.06*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.98 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

function CodeGameScreenStarryXmasMachine:mapBtnIsCanClick()
    local isFreespin = self.m_bProduceSlots_InFreeSpin == true
    local isNormalNoIdle = self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE
    local isRunningEffect = self.m_isRunningEffect == true
    local isAutoSpin = self:getCurrSpinMode() == AUTO_SPIN_MODE
    local features = self.m_runSpinResultData.p_features or {}
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus
    if isFreespin or isNormalNoIdle or isFreespinOver or isRunningEffect or isAutoSpin then
        return false
    end

    return true
end

function CodeGameScreenStarryXmasMachine:playScatterTipMusicEffect()
    local randomNum = math.random(1, 2)
    local soundEffect = self.m_publicConfig.Music_Scatter_Trigger_Tbl[randomNum]
    globalMachineController:playBgmAndResume(soundEffect, 4, 0, 1)
end

function CodeGameScreenStarryXmasMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

function CodeGameScreenStarryXmasMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if _sFeature ~= "bonus" then
        return
    end
    if CodeGameScreenStarryXmasMachine.super.levelDeviceVibrate then
        CodeGameScreenStarryXmasMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenStarryXmasMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenStarryXmasMachine:showBigWinLight(_func)
    self.m_triggerBigWinEffect = false
    self.m_bigwinEffect:setVisible(true)
    self.m_bigwinTopEffect:setVisible(true)
    self.m_bigwinEffectLiZi:setVisible(true)
    self.m_bigwinEffectNum:setVisible(true)

    self.m_bigwinEffectLiZi:findChild("Particle_2"):resetSystem()
    self.m_bigwinEffectLiZi:findChild("Particle_2_0"):resetSystem()

    local actionName = "actionframe"

    util_spinePlay(self.m_bigwinTopEffect,actionName)
    util_spinePlay(self.m_bigwinEffect,actionName)
    util_spineEndCallFunc(self.m_bigwinEffect,actionName,function()
        self.m_bigwinEffect:setVisible(false)
        self.m_bigwinEffectLiZi:setVisible(false)
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Celebrate_Win)
    local winCoins = self.m_runSpinResultData.p_winAmount
    local coinsText = self.m_bigwinEffectNum:findChild("m_lb_coins")
    if winCoins then
        local strCoins = "+" .. util_formatCoins(winCoins, 15)
        coinsText:setVisible(true)

        local curCoins = 0
        local coinRiseNum =  winCoins / (1.5 * 60)  -- 每秒60帧
        local curRiseStrCoins = "+" .. util_formatCoins(coinRiseNum, 15)
        coinsText:setString(curRiseStrCoins)

        self.m_scWaitNodeAction:stopAllActions()
        util_schedule(self.m_scWaitNodeAction, function()
            curCoins = curCoins + coinRiseNum
            if curCoins >= winCoins then
                coinsText:setString(strCoins)
                self:waitWithDelay(0.5,function()
                    self.m_bigwinEffectNum:runCsbAction("over",false, function()
                        self.m_bigwinEffectNum:setVisible(false)
                    end)
                    if _func then
                        _func()
                    end
                end)
                self.m_scWaitNodeAction:stopAllActions()
            else
                local curStrCoins = "+" .. util_formatCoins(curCoins, 15)
                coinsText:setString(curStrCoins)
            end
        end, 1/60)
    end
    self.m_bigwinEffectNum:runCsbAction("start",false, function()
        self.m_bigwinEffectNum:runCsbAction("idle", true)
    end)
    self:shakeRootNode()
end

return CodeGameScreenStarryXmasMachine






