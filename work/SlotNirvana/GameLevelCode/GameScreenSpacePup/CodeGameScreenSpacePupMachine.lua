---
-- island li
-- 2019年1月26日
-- CodeGameScreenSpacePupMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "SpacePupPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenSpacePupMachine = class("CodeGameScreenSpacePupMachine", BaseNewReelMachine)

CodeGameScreenSpacePupMachine.m_baseRootScale = 1
CodeGameScreenSpacePupMachine.m_respinRootScale = 1
CodeGameScreenSpacePupMachine.m_pickRootScale = 1
CodeGameScreenSpacePupMachine.m_baseRootPosY = 0
CodeGameScreenSpacePupMachine.m_respinRootPoxY = 0
CodeGameScreenSpacePupMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenSpacePupMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenSpacePupMachine.SYMBOL_SCORE_BONUS = 94

CodeGameScreenSpacePupMachine.EFFECT_BUBBLE_CLEAR = GameEffect.EFFECT_LINE_FRAME + 1     --气泡消除
CodeGameScreenSpacePupMachine.EFFECT_WILD_MOVE = GameEffect.EFFECT_LINE_FRAME + 3     --金鱼游动

-- 构造函数
function CodeGameScreenSpacePupMachine:ctor()
    CodeGameScreenSpacePupMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

    self.triggerScatterDelayTime = 0

    self.m_lightScore = 0

    self.m_triggerBigWinEffect = false

    self.m_rocketSkinName = {"mini", "minor", "major", "mega", "grand"}

    self.m_symbolNodeRandom = {
        1, 6, 11, 16, 2,
        7, 12, 17, 3, 8,
        13, 18, 4, 9, 14,
        19, 5, 10, 15, 20
    }

    self.m_lastResSpinIsWin = false

    self.m_bottomScatterTbl = {}

    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
 
    --init
    self:initGame()
end

function CodeGameScreenSpacePupMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("SpacePupConfig.csv", "LevelSpacePupConfig.lua")
    self.m_configData.m_machine = self

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenSpacePupMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "SpacePup"  
end

function CodeGameScreenSpacePupMachine:getRespinNode()
    return "CodeSpacePupSrc.SpacePupRespinNode"
end

function CodeGameScreenSpacePupMachine:getRespinView()
    return "CodeSpacePupSrc.SpacePupRespinView"
end

function CodeGameScreenSpacePupMachine:getBottomUINode()
    return "CodeSpacePupSrc.SpacePupBottomNode"
end

---
-- 等待滚动全部结束后 执行reel down 的具体后续逻辑
local curWinType = 0

function CodeGameScreenSpacePupMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_baseBgSpine = util_spineCreate("GameScreen_SpacePup_Bg",true,true)
    self.m_gameBg:findChild("base_bg"):addChild(self.m_baseBgSpine)

    self.m_freeBgSpine = util_spineCreate("SpacePup_guochang",true,true)
    self.m_gameBg:findChild("base_bg"):addChild(self.m_freeBgSpine, 2)
    self.m_freeBgSpine:setVisible(false)

    self.m_freeBgAni = util_createAnimation("SpacePup_bg.csb")
    self.m_gameBg:findChild("base_bg"):addChild(self.m_freeBgAni, 1)
    self.m_freeBgAni:setVisible(false)

    
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_baseFreeSpinBar = util_createView("CodeSpacePupSrc.SpacePupFreespinBarView", self)
    self:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)

    --创建jackpot
    self.m_jackpotPool = {}
    local jackpotName = {"SpacePup_jackpot_mini.csb", "SpacePup_jackpot_minor.csb", "SpacePup_jackpot_major.csb", "SpacePup_jackpot_mega.csb", "SpacePup_jackpot_grand.csb"}
    local jackpotNode = {"Node_mini", "Node_minor", "Node_major", "Node_mega", "Node_grand"}
    for index=1,5 do
        local jackpotIndex = 5 - index + 1
        local jackpot = util_createView("CodeSpacePupSrc.SpacePupJackPotBarView",{csbName = jackpotName[index], pot_index = jackpotIndex})
        jackpot:initMachine(self)
        self:findChild(jackpotNode[index]):addChild(jackpot)
        self.m_jackpotPool[index] = jackpot
    end
   
    self.m_chooseView = util_createView("CodeSpacePupSrc.SpacePupChoosePlayView")
    self:addChild(self.m_chooseView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_chooseView:initMachine(self)
    self.m_chooseView:setVisible(false)

    --收集条
    self.m_collectionBar = util_createView("CodeSpacePupSrc.SpacePupCollectBar", self)
    self:findChild("Node_shoujitiao"):addChild(self.m_collectionBar)

    --选择界面
    self.m_bonusChooseView = util_createView("CodeSpacePupSrc.SpacePupPickSrc.SpacePupBonusChooseView",self) 
    self:addChild(self.m_bonusChooseView, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 2)
    self.m_bonusChooseView:setVisible(false)

    --pick玩法
    self.m_bonusPickView = util_createView("CodeSpacePupSrc.SpacePupPickSrc.SpacePupBonusPickView", self)
    self:addChild(self.m_bonusPickView, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    self.m_bonusPickView:setVisible(false)

    local nodePosX, nodePosY = self:findChild("Node_cutScene"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))

    self.m_pickCutSceneSpine = util_spineCreate("SpacePup_guochang3",true,true)
    self.m_pickCutSceneSpine:setPosition(worldPos)
    self:addChild(self.m_pickCutSceneSpine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_pickCutSceneSpine:setVisible(false)

    self.m_tblGameReelBg = {}
    self.m_tblGameReelBg[1] = self:findChild("Node_base_reel")
    self.m_tblGameReelBg[2] = self:findChild("Node_free_reel")
    self.m_tblGameReelBg[3] = self:findChild("Node_respin_reel")

    self.m_tblTopRocket = {}
    self.m_tblTopRocket[1] = self:findChild("Node_basekuang")
    self.m_tblTopRocket[2] = self:findChild("Node_freekuang")

    --发射台火箭
    self.m_tblRocketSpine = {}
    --发射台下边的环
    self.m_tblRocketCircleAni = {}
    for i=1, 5 do
        self.m_tblRocketSpine[i] = util_spineCreate("SpacePup_huojian",true,true)
        self:findChild("huojian"..i):addChild(self.m_tblRocketSpine[i])
        self.m_tblRocketSpine[i]:setVisible(false)

        self.m_tblRocketCircleAni[i] = util_createAnimation("SpacePup_respin_fashetai.csb")
        self:findChild("Node_fashitai"..i):addChild(self.m_tblRocketCircleAni[i])
    end

    --结算时最后飞的火箭
    self.m_topRocketSpine = util_spineCreate("SpacePup_huojian",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_topRocketSpine)
    self.m_topRocketSpine:setVisible(false)
    
    --创建respinBar
    self.m_respinBarPool = {}
    for index=1, 5 do
        self.m_respinBarPool[index] = util_createView("CodeSpacePupSrc.SpacePupRespinBarView", self, index)
        local respinBarNode = self:findChild("Node_topRespinBar_"..index)
        respinBarNode:addChild(self.m_respinBarPool[index])
        self.m_respinBarPool[index]:setVisible(false)
    end

    self.m_cutSceneTopSpine = util_spineCreate("SpacePup_guochang",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_cutSceneTopSpine, 15)
    self.m_cutSceneTopSpine:setVisible(false)

    self.m_cutSceneBottomSpine = util_spineCreate("SpacePup_guochang",true,true)
    self.m_gameBg:findChild("base_bg"):addChild(self.m_cutSceneBottomSpine, 15)
    self.m_cutSceneBottomSpine:setVisible(false)

    self.m_cutSceneTopAni = util_createAnimation("SpacePup_bg.csb")
    self:findChild("Node_cutScene"):addChild(self.m_cutSceneTopAni, 10)
    self.m_cutSceneTopAni:setVisible(false)

    self.m_cutSceneBottomAni = util_createAnimation("SpacePup_bg.csb")
    self.m_gameBg:findChild("base_bg"):addChild(self.m_cutSceneBottomAni, 10)
    self.m_cutSceneBottomAni:setVisible(false)

    self.m_yuGao = util_createAnimation("SpacePup_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_yuGao)
    self.m_yuGao:setVisible(false)
 
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    --freespin光效
    self.m_freeEffectAni = util_createAnimation("SpacePup_zhezhao.csb")
    self.m_onceClipNode:addChild(self.m_freeEffectAni,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE+1)
    self.m_freeEffectAni:setPosition(util_convertToNodeSpace(self:findChild("Node_cutScene"),self.m_onceClipNode))
    self.m_freeEffectAni:runCsbAction("idle",true) 
    self.m_freeEffectAni:setVisible(false)

    --respin光效层
    self.m_effectNode_respin = {}
    for index=1,5 do
        self.m_effectNode_respin[index] = cc.Node:create()
        self:findChild("Node_reel"):addChild(self.m_effectNode_respin[index],SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + index)
    end

    --特效层
    self.m_effectNode = self:findChild("Node_topEffect")
    --respin最后收集层
    self.m_respinEffectNode = cc.Node:create()
    self.m_respinEffectNode:setPosition(worldPos)
    self:addChild(self.m_respinEffectNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "SpacePup_yqqfk.csb")

    --收集气泡粒子层
    self.m_particleNode = cc.Node:create()
    self:findChild("qp"):addChild(self.m_particleNode,10)

    --scatter触发最上层（假的）
    self.m_scatterNode = cc.Node:create()
    self:findChild("qp"):addChild(self.m_scatterNode,20)

    --收集玩法气泡层
    self.m_bubbleNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_bubbleNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
    --全部气泡
    self.m_bubble_pool = {}
    --初始化气泡层
    self:initBubbleSymbol()
    self:changeBgAndReelBg(1)

    self:addClick(self:findChild("Panel_click"))

    self.m_bonusPickView:scaleMainLayer(self.m_pickRootScale)
end


function CodeGameScreenSpacePupMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 4, 0, 1)
    end,0.2,self:getModuleName())
end

function CodeGameScreenSpacePupMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenSpacePupMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenSpacePupMachine:addObservers()
    CodeGameScreenSpacePupMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin and not self.m_triggerBigWinEffect then
            return
        end

        local isTriggerFG = self:isTriggerSelectFeature()
        if isTriggerFG then
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
        else
            bgmType = "base"
        end

        local soundName = "SpacePupSounds/music_SpacePup_last_win_".. bgmType.."_"..soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end


function CodeGameScreenSpacePupMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local tempPosY = 0 - mainPosY

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
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        if display.width / display.height >= 1660/768 then
            self.m_baseRootScale = mainScale * 1.10
            self.m_baseRootPosY = tempPosY + 4
            self.m_respinRootScale = mainScale * 1.08
        elseif display.width / display.height >= 1530/768 then
            self.m_baseRootScale = mainScale * 1.10
            self.m_baseRootPosY = tempPosY + 4
            self.m_respinRootScale = mainScale * 1.08
        elseif display.width / display.height >= 1370/768 then
            self.m_baseRootScale = mainScale * 1.10
            self.m_baseRootPosY = tempPosY + 4
            self.m_respinRootScale = mainScale * 1.08
        elseif display.width / display.height >= 1228/768 then
            self.m_baseRootScale = mainScale * 1.065
            self.m_baseRootPosY = tempPosY - 10
            self.m_respinRootScale = mainScale * 1.08
            self.m_respinRootPoxY = tempPosY - 10
            self.m_pickRootScale = 0.90
        elseif display.width / display.height >= 960/640 then
            self.m_baseRootScale = mainScale * 0.96
            self.m_baseRootPosY = tempPosY + 10
            self.m_respinRootScale = mainScale * 0.96
            self.m_pickRootScale = 0.84
        elseif display.width / display.height >= 1024/768 then
            self.m_baseRootScale = mainScale * 0.87
            self.m_baseRootPosY = tempPosY
            self.m_respinRootScale = mainScale * 0.87
            self.m_respinRootPoxY = tempPosY - 10
            self.m_pickRootScale = 0.75
        else--2176/1812 then
            self.m_baseRootScale = mainScale * 0.87
            self.m_baseRootPosY = tempPosY
            self.m_respinRootScale = mainScale * 0.87
            self.m_respinRootPoxY = tempPosY - 10
            self.m_pickRootScale = 0.7
        end
        -- util_csbScale(self.m_machineNode, mainScale)
        -- self.m_machineRootScale = mainScale
        -- self.m_machineNode:setPositionY(mainPosY+tempPosY)
    end
end

--根据不同玩法去适配
function CodeGameScreenSpacePupMachine:setScaleMainLayerByType(_type)
    --1:base; 2:respin; 3:pick
    local mainScale, mainPosY
    if _type == 1 then
        mainScale = self.m_baseRootScale
        mainPosY = self.m_baseRootPosY
    elseif _type == 2 then
        mainScale = self.m_respinRootScale
        mainPosY = self.m_respinRootPoxY
    elseif _type == 3 then

    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

--[[
    初始轮盘
]]
function CodeGameScreenSpacePupMachine:initRandomSlotNodes()
    if type(self.m_configData.isHaveInitReel) == "function" and self.m_configData:isHaveInitReel() then
        self:initSlotNodes()
        self:addInitSlotIdle()
    else
        if self.m_currentReelStripData == nil then
            self:randomSlotNodes()
        else
            self:randomSlotNodesByReel()
        end
    end
end
function CodeGameScreenSpacePupMachine:addInitSlotIdle()
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and self:getCurSymbolIsBonus(slotNode.p_symbolType) then
                slotNode:runAnim("idleframe2", true)
            end
        end
    end
end

--默认按钮监听回调
function CodeGameScreenSpacePupMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" then
        self.m_collectionBar:spinCloseTips()
    end
end

function CodeGameScreenSpacePupMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenSpacePupMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenSpacePupMachine:initGameUI()
    self:setScaleMainLayerByType(1)
    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        self:showCollectionRes(false)
        self:changeBgAndReelBg(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
    end
    --respin模式
    if self:getCurStateIsRespin() then
        self:setScaleMainLayerByType(2)
        self:changeBgAndReelBg(3)
        --隐藏收集玩法相关控件
        self:showCollectionRes(false)
    end

    self.m_collectionBar:showTips()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenSpacePupMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_SpacePup_10"
    elseif symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_SpacePup_Bonus"
    end
end

---
--设置bonus scatter 层级
function CodeGameScreenSpacePupMachine:getBounsScatterDataZorder(symbolType, iCol, iRow)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
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

    --右压左、下压上
    if (iCol and iRow) then
        order = order + iCol * 100 - iRow
    end
    return order
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenSpacePupMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenSpacePupMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

--[[
    初始化气泡层
]]
function CodeGameScreenSpacePupMachine:initBubbleSymbol()
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local bubble = util_createAnimation("SpacePup_baseshouji.csb")
            --获取小块索引
            local index = self:getPosReelIdx(iRow ,iCol,self.m_iReelRowNum)
            self.m_bubbleNode:addChild(bubble,index,index)
            --转化坐标位置    
            local pos = cc.p(util_getOneGameReelsTarSpPos(self,index))  
            bubble:setPosition(pos)

            bubble:runCsbAction("idle", true)
            --存储气泡
            self.m_bubble_pool[tostring(index)] = bubble
        end
    end
end

--[[
    刷新气泡
]]
function CodeGameScreenSpacePupMachine:refreshBubbleSymbol()
    --数据安全判定
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local bubblePos = self.m_runSpinResultData.p_selfMakeData.bubblePos or {}
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local index = self:getPosReelIdx(iRow ,iCol,self.m_iReelRowNum)
            --获取气泡
            local bubble = self.m_bubble_pool[tostring(index)]

            --判断小块是否已消除
            if table.indexof(bubblePos,index) then
                bubble:setVisible(false)
            else
                bubble:setVisible(true)
                bubble:runCsbAction("idle", true)
            end
        end
    end
end

--[[
    刷新进度条
]]
function CodeGameScreenSpacePupMachine:refreshCollectionBar(isReconnect)
    --数据安全判定
    local selfData = self.m_runSpinResultData.p_selfMakeData 
    --选择界面断线重连会先播气泡收集,导致气泡数量错误
    if not selfData then
        return
    end
    local bubblePos = self.m_runSpinResultData.p_selfMakeData.bubblePos or {}
    local curBubble = self.m_runSpinResultData.p_selfMakeData.currentBubble or {}
    if isReconnect and selfData.bonusType and self.bonusType == "select" then
        self.m_collectionBar:refreshCollectCount(#bubblePos - #curBubble, isReconnect)
    else
        self.m_collectionBar:refreshCollectCount(#bubblePos, isReconnect)
    end
end

--[[
    是否显示收集玩法相关控件
]]
function CodeGameScreenSpacePupMachine:showCollectionRes(isShow)
    if not isShow then
        self.m_collectionBar:hideAni()
    else
        self.m_collectionBar:showAni()
    end
    
    self.m_bubbleNode:setVisible(isShow)
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenSpacePupMachine:MachineRule_initGame(  )
    --初始化气泡层
    self:refreshBubbleSymbol()
    
    --刷新收集进度条
    self:refreshCollectionBar(true)

    local bonusExtra = self.m_runSpinResultData.p_bonusExtra
    if bonusExtra and bonusExtra.pickPhase and bonusExtra.pickPhase == "PICK_REWARD" and bonusExtra.pickLeftTimes and bonusExtra.pickLeftTimes > 0 then
        local endCallFunc = function()
            self:playGameEffect() 
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self:showBonusPickGame(endCallFunc, bonusExtra)
    end
end

function CodeGameScreenSpacePupMachine:initGameStatusData(gameData)
    local featureData = gameData.feature
    local spinData = gameData.spin
    if featureData and spinData then
        if featureData.selfData and featureData.selfData.avgBet and spinData.selfData then
            -- spinData.selfData.avgBet = featureData.selfData.avgBet
            spinData.selfData = featureData.selfData
        end
    end
    
    CodeGameScreenSpacePupMachine.super.initGameStatusData(self,gameData)

    if gameData.gameConfig ~= nil  then
        if gameData.gameConfig.init and gameData.gameConfig.init.bubblePos then
            self.m_runSpinResultData.p_selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
            self.m_runSpinResultData.p_selfMakeData.bubblePos = gameData.gameConfig.init.bubblePos
        end
    end
end

--[[
    单列滚动停止
]]
function CodeGameScreenSpacePupMachine:slotOneReelDownFinishCallFunc( reelCol )

    CodeGameScreenSpacePupMachine.super.slotOneReelDownFinishCallFunc(self,reelCol)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE or not selfData or not selfData.wildPos then
        return
    end
    local moveRoute = selfData.moveRoute
    local wildPos = selfData.wildPos
    for index,times in pairs(wildPos) do
        local startPos = self:getRowAndColByPos(tonumber(index))
        if startPos.iY == reelCol then
            local fixNode = self:getFixSymbol(startPos.iY , startPos.iX)
            fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
            fixNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - fixNode.p_rowIndex)

            if fixNode.p_symbolImage then
                fixNode.p_symbolImage:removeFromParent()
                fixNode.p_symbolImage = nil
            end

            local skinName = "wild_" .. times
            self:setSpecialSymbolSkin(fixNode, skinName)
            fixNode:runIdleAnim()
        end
    end

    if reelCol == self.m_iReelColumnNum then
        if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_freeEffectAni:isVisible() then
            self.m_freeEffectAni:runCsbAction("over",false,function()
                self.m_freeEffectAni:setVisible(false)
            end) 
        end
        
        self.m_effectNode:setVisible(false)
        self.m_effectNode:removeAllChildren(true)
        for index,times in pairs(wildPos) do
            local startPos = self:getRowAndColByPos(index)
            --开始小块节点
            local startNode = self.m_bubble_pool[tostring(index)]

            local startSpine = self:createSpacePupSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD)
            startSpine:setPosition(util_convertToNodeSpace(startNode,self.m_effectNode))
            self.m_effectNode:addChild(startSpine)
            -- util_spinePlay(startSpine,times == 1 and "start_zou" or "idle_x"..times,false)
            self.m_effectNode:setVisible(false)

            local skinName = "wild_" .. times
            local spineNode = startSpine:getNodeSpine()
            startSpine:runAnim("idleframe", true)
            self:setFreeSpecialSymbolSkin(spineNode, skinName)
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenSpacePupMachine:slotLocalOneReelDown(_iCol)
    self:playReelDownSound(_iCol, self.m_reelDownSound)
end

--
--单列滚动停止回调
--
function CodeGameScreenSpacePupMachine:slotOneReelDown(reelCol)    
    CodeGameScreenSpacePupMachine.super.slotOneReelDown(self,reelCol)
    ---本列是否开始长滚
    local isTriggerLongRun = false
    if reelCol == 1 then
        self.isHaveLongRun = false
    end
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true
    end
    local delayTime = 15/30
    if isTriggerLongRun then
        self.isHaveLongRun = true
        self:playScatterSpine("idleframe3", reelCol)
    else
        if reelCol == self.m_iReelColumnNum and self.isHaveLongRun == true then
            --落地
            self.triggerScatterDelayTime = 15/30
            self:playScatterSpine("idleframe2", reelCol, true)
        end
    end
end

function CodeGameScreenSpacePupMachine:playScatterSpine(_spineName, _reelCol, isOver)
    performWithDelay(self.m_scWaitNode, function()
        for iCol = 1, _reelCol  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if _spineName == "idleframe3" and targSp.m_currAnimName ~= "idleframe3" then
                            targSp:runAnim(_spineName, true)
                        elseif _spineName == "idleframe2" then
                            targSp:runAnim(_spineName, true)
                        end
                    end
                end
            end
        end
    end, 0.1)
end

function CodeGameScreenSpacePupMachine:createSlotNextNode(parentData)
    if self.m_isWaitingNetworkData == true then
        -- 等待网络数据返回时， 还没开始滚动真信号，所以肯定为false 2018-12-15 18:15:51
        parentData.m_isLastSymbol = false
        self:getReelDataWithWaitingNetWork(parentData)
        return
    end
    parentData.lastReelIndex = parentData.lastReelIndex + 1
    local cloumnIndex = parentData.cloumnIndex
    local columnData = self.m_reelColDatas[cloumnIndex]
    local nodeCount = self.m_reelRunInfo[cloumnIndex]:getReelRunLen()
    if parentData.lastReelIndex<=nodeCount or parentData.lastReelIndex>nodeCount+columnData.p_showGridCount then
        if parentData.fillCount and parentData.fillCount>0 and parentData.lastReelIndex>=nodeCount-parentData.fillCount then
            --大信号补块
            parentData.m_isLastSymbol = false
            parentData.symbolType = self:getSymbolTypeForNetData(cloumnIndex,1)
        else
            parentData.m_isLastSymbol = false
            self:getReelDataWithWaitingNetWork(parentData)
        end
        local symbolCount = self.m_bigSymbolInfos[parentData.symbolType]
        if symbolCount then
            if parentData.fillCount then
                symbolCount = symbolCount + parentData.fillCount
            end
            if parentData.lastReelIndex + symbolCount >nodeCount then
                --假滚轴大信号覆盖到了真数据重新获取数据
                local symbolType = self:getReelSymbolType(parentData)
                local breakIndex = 0
                while self.m_bigSymbolInfos[symbolType] do
                    symbolType = self:getReelSymbolType(parentData)
                    breakIndex = breakIndex +1
                    if breakIndex>=10 then
                        --理论不会报错 预防一下
                        break
                    end
                end
                parentData.symbolType = symbolType
            end
        end
        return
    end
    parentData.fillCount = 0
    local columnRowNum = columnData.p_showGridCount
    parentData.rowIndex = parentData.lastReelIndex-nodeCount
    local symbolType = self:getSymbolTypeForNetData(cloumnIndex,parentData.rowIndex)
    local showOrder = self:getBounsScatterDataZorder(symbolType, parentData.cloumnIndex, parentData.rowIndex)
    parentData.symbolType = symbolType
    parentData.order = showOrder - parentData.rowIndex
    parentData.tag = cloumnIndex * SYMBOL_NODE_TAG + parentData.rowIndex

    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    if parentData.rowIndex == columnRowNum then --self.m_iReelRowNum then
        parentData.isLastNode = true
    end
    parentData.m_isLastSymbol = true
    self:changeReelDownAnima(parentData)
end

function CodeGameScreenSpacePupMachine:updateReelGridNode(_symbolNode)

    if _symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
        self:setSpecialNodeScoreBonus(_symbolNode)
    end

    self:setSpecialSymbolSkin(_symbolNode, "wild_1")
end

function CodeGameScreenSpacePupMachine:setSpecialSymbolSkin(_symbolNode, _skinName)
    if _symbolNode.m_isLastSymbol == true and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        local ccbNode = _symbolNode:getCCBNode()
        if not ccbNode then
            _symbolNode:checkLoadCCbNode()
        end
        ccbNode = _symbolNode:getCCBNode()
        if ccbNode then
            ccbNode.m_spineNode:setSkin(_skinName)
        end
    end
end

function CodeGameScreenSpacePupMachine:setFreeSpecialSymbolSkin(_spineNode, _skinName)
    local spineNode = _spineNode
    local skinName = _skinName
    spineNode:setSkin(skinName)
end

function CodeGameScreenSpacePupMachine:setSpecialNodeScoreBonus(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType  then
        return
    end

    local curBet = globalData.slotRunData:getCurTotalBet()
    local sScore = ""
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local nodeScore, mul
    if not tolua.isnull(spineNode.m_nodeScore) then
        nodeScore = spineNode.m_nodeScore
    else
        nodeScore = util_createAnimation("Socre_SpacePup_BonusCoins.csb")
        util_spinePushBindNode(spineNode,"aaa",nodeScore)
        spineNode.m_nodeScore = nodeScore
    end

    if symbolNode.m_isLastSymbol == true then
        mul = self:getReSpinBonusScore(self:getPosReelIdx(iRow, iCol))
        if mul ~= nil and mul ~= 0 then
            local coins = mul * curBet
            sScore = util_formatCoins(coins, 3)
        end
    else
        -- 获取随机分数（本地配置）
        mul = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        local coins = mul * curBet
        sScore = util_formatCoins(coins, 3)
    end
    local textNode, textHighNode
    if nodeScore then
        textNode = nodeScore:findChild("m_lb_coins")
        textHighNode = nodeScore:findChild("m_lb_coins_high")
    end
    if textNode and textHighNode then
        textNode:setString(sScore)
        textHighNode:setString(sScore)
        if mul then
            if mul >= 5 then
                textNode:setVisible(false)
                textHighNode:setVisible(true)
            else
                textNode:setVisible(true)
                textHighNode:setVisible(false)
            end
        else
            print("--error--")
        end
    end
end

--[[
    获取小块真实分数
]]
function CodeGameScreenSpacePupMachine:getReSpinBonusScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil
    if not storedIcons then
        return
    end

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    return score
end

--[[
    随机bonus分数
]]
function CodeGameScreenSpacePupMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_SCORE_BONUS then
        score = self.m_configData:getBnBasePro(1)
    end

    return score
end

-- 播放预告中奖统一接口
-- 子类重写接口
function CodeGameScreenSpacePupMachine:showFeatureGameTip(_func)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER and selfData and selfData.bonusType and selfData.bonusType == "select" then
        local randomNum = math.random(1, 10)
        if randomNum <= 4 then
            self.b_gameTipFlag = true
            self.triggerScatterDelayTime = 15/30
        end
        -- self.b_gameTipFlag = true
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE and selfData and selfData.moveRoute then
        -- 刷新wild
        self:refreshFreeSpinWilds(_func)
    else
        if self.b_gameTipFlag then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_YuGao_Sound)
            self.m_yuGao:setVisible(true)
            self.m_yuGao:runCsbAction("actionframe_yugao", false, function()
                _func()
            end)
        else
            _func() 
        end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenSpacePupMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenSpacePupMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

---
-- 显示bonus 触发的小游戏
function CodeGameScreenSpacePupMachine:showEffect_Bonus(effectData)
    self.m_beInSpecialGameTrigger = true

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停止播放背景音乐
    -- self:clearCurMusicBg()
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then
        self:showBonusAndScatterLineTip(
            bonusLineValue,
            function()
                self:showBonusGameView(effectData)
            end
        )
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playBonusTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenSpacePupMachine:showBonusGameView(_effectData)
    if self.m_runSpinResultData.p_selfMakeData then
        if self.m_runSpinResultData.p_selfMakeData.bonusType == "select" then
            -- self:showCollectionRes(false)
            self:runSelectGame(_effectData)
        elseif self.m_runSpinResultData.p_selfMakeData.bonusType == "pick" then
            self:triggerBonusSelectGame(_effectData)
        end
    else
        _effectData.p_isPlay = true
        self:playGameEffect()   
    end
end

function CodeGameScreenSpacePupMachine:runSelectGame(_effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.triggerScatterDelayTime = 0
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- 停掉背景音乐
        -- self:clearCurMusicBg()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end

        local waitTime = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        local topSatterNode = self:createSpacePupSymbol(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                        local scatterPos = self:getPosReelIdx(iRow, iCol)
                        local clipTarPos = util_getOneGameReelsTarSpPos(self, scatterPos)
                        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
                        local nodePos = self.m_scatterNode:convertToNodeSpace(worldPos)

                        slotNode:setVisible(false)
                        self.m_bottomScatterTbl[#self.m_bottomScatterTbl+1] = slotNode
                        topSatterNode:setPosition(nodePos)
                        local scatterZorder = 10 - iRow + iCol
                        self.m_scatterNode:addChild(topSatterNode, scatterZorder)
                        topSatterNode:runAnim("actionframe", false, function()
                            slotNode:runAnim("idleframe2", true)
                        end)

                        local duration = topSatterNode:getAnimDurationTime("actionframe")
                        waitTime = util_max(waitTime,duration)

                        -- local parent = slotNode:getParent()
                        -- if parent ~= self.m_clipParent then
                        --     slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                        -- end
                        -- slotNode:runAnim("actionframe")
                        -- local duration = slotNode:getAniamDurationByName("actionframe")
                        -- waitTime = util_max(waitTime,duration)
                    end
                end
            end
        end
        self:playScatterTipMusicEffect()
        performWithDelay(self,function(  )
            self:showChooseView(_effectData)
        end,waitTime)
    end, self.triggerScatterDelayTime)
end

function CodeGameScreenSpacePupMachine:triggerBonusSelectGame(effectData)
    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Trigger_Pick, 4, 0, 1)

    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    self.m_collectionBar:triggerCollect(function()
        self:runBonusSelectGame(effectData)
    end)
end

--pick玩法--选择pick次数玩法
function CodeGameScreenSpacePupMachine:runBonusSelectGame(effectData)
    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    self:clearCurMusicBg()
    self.m_bonusChooseView:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Pick_StartStart)
    self.m_bonusChooseView:refreshView()
    self.m_bonusChooseView:runCsbAction("start",false, function()
        self.m_bonusChooseView:refreshData(endCallFunc)
        self.m_bonusChooseView:runCsbAction("idle", true)
    end)
end

--pick玩法
function CodeGameScreenSpacePupMachine:showBonusPickGame(_endCallFunc, _bonusExtra)
    local endCallFunc = _endCallFunc
    local bonusExtra = _bonusExtra

    self:resetMusicBg(nil, self.m_publicConfig.Music_Pick_Bg)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_Pick_CutScene)
    self.m_pickCutSceneSpine:setVisible(true)
    util_spinePlay(self.m_pickCutSceneSpine,"actionframe_guochang", false)
    self.m_bonusPickView:refreshView(endCallFunc)
    performWithDelay(self.m_scWaitNode, function()
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        --清空赢钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
        self.m_bonusPickView:setVisible(true)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_FreeGame_ChooseStart)
        self.m_bonusPickView:refreshPickData(bonusExtra, true)
    end, 15/30)

    util_spineEndCallFunc(self.m_pickCutSceneSpine, "actionframe_guochang", function()
        self.m_pickCutSceneSpine:setVisible(false)
    end)
end

--pick玩法结束过场
function CodeGameScreenSpacePupMachine:bonusPickGameOver(_totalWinCoins, _endCallFunc, _hideCallFunc)
    local endCallFunc = _endCallFunc
    local totalWinCoins = _totalWinCoins
    self.m_pickCutSceneSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Pick_Base_CutScene)
    util_spinePlay(self.m_pickCutSceneSpine,"actionframe_guochang2", false)
    performWithDelay(self.m_scWaitNode, function()
        self:resetMusicBg()
        self.m_collectionBar:setRemainPickCount(0)
        --刷新所有气泡
        self:refreshBubbleSymbol()
        self:refreshCollectionBar()
        self:playhBottomLight(totalWinCoins)
        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
        globalData.coinsSoundType = 1
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        if type(_hideCallFunc) == "function" then
            _hideCallFunc()
            _hideCallFunc = nil
        end
    end, 15/30)

    util_spineEndCallFunc(self.m_pickCutSceneSpine, "actionframe_guochang2", function()
        if type(_endCallFunc) == "function" then
            _endCallFunc()
            _endCallFunc = nil
        end
        self.m_pickCutSceneSpine:setVisible(false)
    end)
end

---
-- 根据Bonus Game 每关做的处理
--选择free和respin
function CodeGameScreenSpacePupMachine:showChooseView(effectData)
    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    self:clearCurMusicBg()
    self.m_chooseView:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Choose_startStart)
    self.m_chooseView:refreshView()
    self.m_chooseView:runCsbAction("start",false, function()
        self.m_chooseView:refreshData(endCallFunc)
        self.m_chooseView:runCsbAction("idle", true)
    end)
end

function CodeGameScreenSpacePupMachine:initRespinView(endTypes, randomTypes)
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
            self:showReSpinStart(
                function()
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    self:runNextReSpinReel()
                end
            )
        end
    )

    --隐藏 盘面信息
    --self:setReelSlotsNodeVisible(false)
end

function CodeGameScreenSpacePupMachine:showReSpinStart(_callFunc)
    local callFunc = _callFunc
    local endCallFunc = function()
        callFunc()
    end

    --判断是否播放过场
    local isPlayCutScene = self:getRespinStartIsPlayCutScene()

    local startRespinFunc = function()
        self:showTriggerRespinAction(isPlayCutScene, endCallFunc)
    end
    self:clearCurMusicBg()
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_StartOver)
    end
    if isPlayCutScene then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.respinFromMode and selfData.respinFromMode == "NORMAL" then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_StartStart)
            local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, startRespinFunc)
            view:setBtnClickFunc(cutSceneFunc)
        else
            startRespinFunc()
        end
    else
        --隐藏收集玩法相关控件
        self:showCollectionRes(false)
        self:changeBgAndReelBg(3)
        startRespinFunc()
    end
end

function CodeGameScreenSpacePupMachine:showTriggerRespinAction(_isPlayCutScene, _callFunc)
    local isPlayCutScene = _isPlayCutScene
    local callFunc = _callFunc
    local endCallFunc = function()
        callFunc()
    end
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    local tblActionList = {}
    if isPlayCutScene then
        --待触发的respin小块
        self.m_triggerRespinNode = {}
        --闪电光效
        self.m_lightAni = {}
        --先切过场
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:showCutPlaySceneAni(false)
        end)
        --86帧的时候切换棋盘
        tblActionList[#tblActionList+1] = cc.DelayTime:create(86/30)
        --切棋盘
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            --隐藏 盘面信息
            self:setReelSlotsNodeVisible(false)
            --隐藏base轮盘小块
            self:hideBaseReelSymbol()
            self.m_respinView:setSpecialClipNode()
        end)
        --过场75/30
        tblActionList[#tblActionList+1] = cc.DelayTime:create(29/30)
        --棋盘播放缩小动画
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:runCsbAction("start", false, function()
                self:runCsbAction("idleframe_xiao", true)
            end)
        end)
        --棋盘缩小音效10/60
        tblActionList[#tblActionList+1] = cc.DelayTime:create(12/60)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Reel_ScaleSmall)
        end)
        --棋盘缩小动画30/60
        tblActionList[#tblActionList+1] = cc.DelayTime:create(18/60)
        --respin小块播放触发闪电
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local symbolNode = self.m_respinView:getRespinEndNode(iRow,iCol)
                if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        gLobalSoundManager:playSound(self.m_publicConfig.Music_Col_TriggerLight)
                        symbolNode:runAnim("actionframe2_1", false, function()
                            symbolNode:runAnim("idleframe4", true)
                        end)
                    end)
                    --15帧后播放闪电
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(15/30)
                    --播放闪电动画
                    if symbolNode and symbolNode.p_rowIndex < 4 then
                        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                            local lightName = "SpacePup_respin_cd" .. symbolNode.p_rowIndex .. ".csb"
                            local lightAni = util_createAnimation(lightName)
                            self.m_lightAni[#self.m_lightAni+1] = lightAni
                            local pos = util_convertToNodeSpace(symbolNode,self.m_respinView)
                            pos.y = pos.y + self.m_SlotNodeH/2
                            lightAni:setPosition(pos)
                            self.m_respinView:addChild(lightAni)
                            lightAni:runCsbAction("actionframe", false, function()
                                lightAni:setVisible(false)
                            end)
                        end)
                    end
                    --再过6帧后播放respinBar
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(6/30)
                    --播放respinBar动画
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        local curCol = symbolNode.p_cloumnIndex
                        local respinBar = self.m_respinBarPool[curCol]
                        respinBar:setVisible(true)
                        self:refreshRespinTimes(2, curCol, true)
                        respinBar:runCsbAction("start", false, function()
                            respinBar:runCsbAction("idleframe3", true)
                        end)
                        self.m_tblRocketSpine[curCol]:setVisible(true)
                        self.m_tblRocketSpine[curCol]:setSkin(self.m_rocketSkinName[curCol])
                        util_spinePlay(self.m_tblRocketSpine[curCol],"up",false)
                        util_spineEndCallFunc(self.m_tblRocketSpine[curCol], "up", function()
                            util_spinePlay(self.m_tblRocketSpine[curCol],"idleframe",true)
                        end)
                    end)

                    --每列之间的停顿间隔
                    -- tblActionList[#tblActionList+1] = cc.DelayTime:create(5/30)
                end
            end
        end
        --up是18帧
        tblActionList[#tblActionList+1] = cc.DelayTime:create(18/30)
        --up是18帧，播放up之后棋盘回原位
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Reel_ScaleBig)
            self:runCsbAction("over", false, function()
                self:runCsbAction("idleframe_da", true)
            end)
        end)
        --over是10帧
        tblActionList[#tblActionList+1] = cc.DelayTime:create(10/60)
        --jackpot栏动画改变
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            for key,times in pairs(rsExtraData.reSpinTimes) do
                if times == 0 then   --统计显示的jackpot
                    local jackpot = self.m_jackpotPool[key]
                    jackpot:runCsbAction("yaan", false, function()
                        jackpot:runCsbAction("yaan_idleframe", true)
                    end)
                    -- self.m_tblRocketCircleAni[key]:runCsbAction("bt", false, function()
                    --     self.m_tblRocketCircleAni[key]:runCsbAction("bt_idleframe", true)
                    -- end)
                end
            end
        end)
        --yaan是20帧
        tblActionList[#tblActionList+1] = cc.DelayTime:create(20/60)
        --开始respin
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            endCallFunc()
        end)
    else
        --隐藏 盘面信息
        self:setReelSlotsNodeVisible(false)
        --隐藏base轮盘小块
        self:hideBaseReelSymbol()
        self.m_respinView:setSpecialClipNode()
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local symbolNode = self.m_respinView:getRespinEndNode(iRow,iCol)
                if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    symbolNode:runAnim("idleframe4", true)
                end
            end
        end
        --播放respinBar静帧
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            for key,times in pairs(rsExtraData.reSpinTimes) do
                if self:isRespinCol(key) then   --统计显示的jackpot
                    local respinBar = self.m_respinBarPool[key]
                    respinBar:setVisible(true)
                    self:refreshRespinTimes(2, key, true)
                    self.m_tblRocketSpine[key]:setVisible(true)
                    self.m_tblRocketSpine[key]:setSkin(self.m_rocketSkinName[key])
                    util_spinePlay(self.m_tblRocketSpine[key],"idleframe",true)
                end
            end
            
        end)
        --棋盘静帧
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:runCsbAction("idleframe_da", true)
        end)
        --jackpot栏动画静帧
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            for key,times in pairs(rsExtraData.reSpinTimes) do
                local isUnLock = self:isUnLockRewardByCol(key)
                if not isUnLock then
                    self.m_jackpotPool[key]:runCsbAction("idleframe", true)
                    if times == 0 and not self:isRespinCol(key) then
                        self.m_jackpotPool[key]:runCsbAction("yaan_idleframe", true)
                    end
                end
            end
        end)
        --开始respin
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            endCallFunc()
        end)
    end
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

function CodeGameScreenSpacePupMachine:showRespinView()
    self.collectBonus = false
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --用respin次数判断当前是否播放过场和触发
    local isPlayCutScene = self:getRespinStartIsPlayCutScene()

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()
    
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    --序列动作
    local tblActionList = {}
    -- tblActionList[#tblActionList+1] = cc.DelayTime:create(0.5)
    if isPlayCutScene then
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Bonus_trigger, 4, 0, 1)
        for key,times in pairs(rsExtraData.reSpinTimes) do
            if self:isRespinCol(key) then
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    --播放Link图标特效
                    for iRow =1,self.m_iReelRowNum do
                        local symbol = self:getFixSymbol(key, iRow)
                        if symbol and symbol.p_symbolType ~= nil and symbol.p_symbolType == self.SYMBOL_SCORE_BONUS  then
                            symbol:runAnim("actionframe2",false,function(  )
                                symbol:runAnim("idleframe2",true)
                            end)
                        end
                    end
                end)
            end
        end

        tblActionList[#tblActionList+1] = cc.DelayTime:create(60/30)
        --开始respin
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end)
    else
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end)
    end
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

function CodeGameScreenSpacePupMachine:hideBaseReelSymbol()
    --下边加一层，因为有间隙
    self.node_mask_ary = {}
    for index=1,20 do
        local mask = util_createAnimation("SpacePup_respindange.csb")
        self.m_onceClipNode:addChild(mask,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE+1)
        mask:setPosition(util_getOneGameReelsTarSpPos(self,index - 1))
        mask:setScale(1.03)
        mask:runCsbAction("idleframe")
        self.node_mask_ary[#self.node_mask_ary + 1] = mask
    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(false)
            end
        end
    end
end

function CodeGameScreenSpacePupMachine:getRespinStartIsPlayCutScene()
    --用respin次数判断当前是否播放过场和触发
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local reels = self.m_runSpinResultData.p_reels
    local respinTimeCount = 0
    local respinNodeCount = 0
    local isPlayCutScene = false
    for key,times in pairs(rsExtraData.reSpinTimes) do
        if times == 3 then
            respinTimeCount = respinTimeCount + 1
        end
    end
    --判断当前轮盘bonus小块有多少
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = reels[iRow][iCol]
            if symbolType and symbolType == self.SYMBOL_SCORE_BONUS then
                respinNodeCount = respinNodeCount + 1
            end
        end
    end
    if respinTimeCount == respinNodeCount then
        isPlayCutScene = true
    end
    return isPlayCutScene
end

function CodeGameScreenSpacePupMachine:getCurStateIsRespin()
    --用respin次数判断当前是否是respin状态
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local respinState = false
    if rsExtraData then
        for key,times in pairs(rsExtraData.reSpinTimes) do
            if times > 0 then
                respinState = true
                break
            end
        end
    end
    return respinState
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenSpacePupMachine:getRespinRandomTypes( )
    local symbolList = {
        self.SYMBOL_SCORE_BONUS,
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenSpacePupMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_SCORE_BONUS, runEndAnimaName = "", bRandom = true},
    }

    return symbolList
end

--[[
    刷新respin次数
    refreshType: 1 开始是刷新,次数需减1 2结束时刷新,次数不需要减1 
]]
function CodeGameScreenSpacePupMachine:refreshRespinTimes(refreshType,colIndex,isInit)
    if not self:isRespinCol(colIndex) then
        return
    end
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local times = rsExtraData.reSpinTimes[colIndex]
    local isUnLock = self:isUnLockRewardByCol(colIndex)
    if isUnLock then    --成功解锁奖励
        --显示解锁动画
        self.m_respinBarPool[colIndex]:unlockReward(isInit)
    else
        if times > 0 then
            local jackpot = self.m_respinBarPool[colIndex]
            jackpot:refreshTimes(refreshType == 1 and times - 1 or times, isInit)
        else
            if refreshType == 2 then
                --显示变黑动画
                self.m_respinBarPool[colIndex]:turnToBlack(isInit)
            end
        end
    end
end

--[[
    判断该列是否已成功解锁最大奖励
]]
function CodeGameScreenSpacePupMachine:isUnLockRewardByCol(colIndex)
    local reels = self.m_runSpinResultData.p_reels

    local link_count = 0
    for rowIndex=1,self.m_iReelRowNum do
        if reels[rowIndex][colIndex] == self.SYMBOL_SCORE_BONUS then --判断是否为link图标
            link_count = link_count + 1
        end
    end
    return link_count >= 4
end

--[[
    判断该列是否为respin玩法
]]
function CodeGameScreenSpacePupMachine:isRespinCol(colIndex)
    local reels = self.m_runSpinResultData.p_reels

    local link_count = 0
    for rowIndex=1,self.m_iReelRowNum do
        if reels[rowIndex][colIndex] == self.SYMBOL_SCORE_BONUS then --判断是否为link图标
            return true
        end
    end
    return false
end

--ReSpin开始改变UI状态
function CodeGameScreenSpacePupMachine:changeReSpinStartUI(respinCount)
    -- util_setCsbVisible(self.m_respinBarPool, true)
    -- self.m_respinBarPool:showRespinBar(respinCount, self.m_runSpinResultData.p_reSpinsTotalCount)
end

--ReSpin刷新数量
function CodeGameScreenSpacePupMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenSpacePupMachine:changeReSpinOverUI()

end

function CodeGameScreenSpacePupMachine:setLastRespinIsWinState(_state)
    self.m_lastResSpinIsWin = _state
end

function CodeGameScreenSpacePupMachine:getLastRespinIsWinState()
    return self.m_lastResSpinIsWin
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenSpacePupMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getChangeRespinOrder(node)
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)

    if self:getCurSymbolIsBonus(node.p_symbolType) then
        if node ~= nil then
            node:runAnim("idleframe2", true)
        end
    end
end

--一列满了之后播放idleframe3
function CodeGameScreenSpacePupMachine:playTriggerCurColBonus(_curCol)
    local curCol = _curCol
    performWithDelay(self.m_scWaitNode, function()
        for iRow = 1, self.m_iReelRowNum do
            local symbolNode = self.m_respinView:getRespinEndNode(iRow,curCol)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                symbolNode:runAnim("idleframe3", true)
            end
        end
    end, 21/30)
end

--
function CodeGameScreenSpacePupMachine:respinOver()
    self:setReelSlotsNodeVisible(true)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    local delayTime = 0.5
    if self:getLastRespinIsWinState() then
        delayTime = delayTime + 1.5
    end
    --添加奖励
    performWithDelay(self.m_scWaitNode, function()
        self:playAllBonusTriggerAni()
    end, delayTime)
end

--respin结束后全部的bonus先播放一遍触发动画
function CodeGameScreenSpacePupMachine:playAllBonusTriggerAni()
    local jackpotsWin = self.m_runSpinResultData.p_rsExtraData.jackpotsWin
    if jackpotsWin then
        for curColIndex=1, 5 do
            for key,jackpotInfo in pairs(jackpotsWin) do
                if jackpotInfo.column + 1 == curColIndex then
                    local delayTime = 0
                    local jackpot = self.m_jackpotPool[curColIndex]
                    if not tolua.isnull(jackpot) then
                        local curPlayTime= util_csbGetDuration(jackpot.m_csbAct)
                        delayTime = 60/60 - curPlayTime
                    end
                    performWithDelay(self.m_scWaitNode, function()
                        self.m_jackpotPool[curColIndex]:runCsbAction("idleframe", true)
                    end, delayTime)
                    --结算特效
                    self.m_respinView:cleanEffect(curColIndex)
                end
            end
        end
    end

    gLobalSoundManager:playSound(self.m_publicConfig.Music_Repin_AllBonusScaleBig)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolNode = self.m_respinView:getRespinEndNode(iRow,iCol)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                symbolNode:runAnim("actionframe3", false, function()
                    symbolNode:runAnim("idleframe2", true)
                end)
            end
        end
    end
    performWithDelay(self.m_scWaitNode, function()
        self:playRewardColBonusOverAni(1, true)
    end, 60/30)
end

--respin结束后获奖列的bonus播放关舱门动画
function CodeGameScreenSpacePupMachine:playRewardColBonusOverAni(_curCol, _rootIsPlay)
    
    local jackpotsWin = self.m_runSpinResultData.p_rsExtraData.jackpotsWin
    self.m_topRocketSpine:setVisible(false)
    local curColIndex = _curCol
    --主棋盘是否播放
    local rootIsPlay = _rootIsPlay
    local tblActionList = {}
    if jackpotsWin then
        --关舱门
        local closeBonusFunc = function(_curCol)
            for iRow = 1, self.m_iReelRowNum do
                local symbolNode = self.m_respinView:getRespinEndNode(iRow,_curCol)
                if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    symbolNode:runAnim("over", false, function()
                        symbolNode:runAnim("idleframe2_1", true)
                    end)
                end
            end
        end

        local jackpotCount = #jackpotsWin
        local isLastJackpot = false
        local isJackpot = false
        local totalJackpotCount = #jackpotsWin
        for key,jackpotInfo in pairs(jackpotsWin) do
            if jackpotInfo.column + 1 == curColIndex then
                isLastJackpot = key == totalJackpotCount and true or false
                local curCol = jackpotInfo.column + 1
                --主棋盘缩放
                if rootIsPlay then
                    rootIsPlay = false
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        self:runCsbAction("start", false, function()
                            self:runCsbAction("idleframe_xiao", true)
                        end)
                    end)
                end
                tblActionList[#tblActionList+1] = cc.DelayTime:create(30/60)
                tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Repin_ColWinBonus)
                    closeBonusFunc(curCol)
                end)
                
                --关舱门结束后，延迟播放整列电流充能特效时间
                tblActionList[#tblActionList+1] = cc.DelayTime:create(30/30)
                --整列电流充能特效
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    local reelNode = self:findChild("sp_reel_" .. (curCol - 1))
                    local light_effect = util_createAnimation("SpacePup_respin_cm.csb")
                    light_effect:runCsbAction("actionframe", false, function()
                        light_effect:setVisible(false)
                    end)
                    self.m_effectNode_respin[curCol]:addChild(light_effect)
                    light_effect:setPosition(util_convertToNodeSpace(reelNode,self.m_effectNode_respin[curCol]))
                end)
                --8帧后播放火箭
                local rocketDelayTime = 8/60
                tblActionList[#tblActionList+1] = cc.DelayTime:create(rocketDelayTime)
                --播放火箭
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    self.m_tblRocketSpine[curCol]:setSkin(self.m_rocketSkinName[curCol])
                    util_spinePlay(self.m_tblRocketSpine[curCol], "actionframe", false)
                end)

                --actionframe 49帧
                tblActionList[#tblActionList+1] = cc.DelayTime:create(49/30)
                --最后飞的火箭
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    self.m_topRocketSpine:setVisible(true)
                    self.m_topRocketSpine:setSkin(self.m_rocketSkinName[curColIndex])
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_Bonus_Fly)
                    util_spinePlay(self.m_topRocketSpine, "fly", false)
                end)
                --fly 49帧
                tblActionList[#tblActionList+1] = cc.DelayTime:create(15/30)
                --jackpot弹板
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    self:addJackpotRewardAni(curColIndex, rootIsPlay, isLastJackpot)
                end)
                isJackpot = true
                break
            end
        end
        if isJackpot then
            self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
        else
            self:addJackpotRewardAni(curColIndex, rootIsPlay)
        end
    else
        self:addJackpotRewardAni(6)
    end
end

--添加jackpot奖励
function CodeGameScreenSpacePupMachine:addJackpotRewardAni(_curColIndex, _rootIsPlay, _isLastJackpot)
    local jackpotsWin = self.m_runSpinResultData.p_rsExtraData.jackpotsWin
    local curColIndex = _curColIndex
    local rootIsPlay = _rootIsPlay
    local isLastJackpot = _isLastJackpot

    if curColIndex > 5 or not jackpotsWin then
        self:addBonusRewardAni(0)
    else
        if jackpotsWin then
            local isJackpot = false
            for key,jackpotInfo in pairs(jackpotsWin) do
                if jackpotInfo.column + 1 == curColIndex then
                    local winCount = jackpotInfo.winCoins
                    if isLastJackpot then
                        self:runCsbAction("over", false, function()
                            self:runCsbAction("idleframe_da", true)
                        end)
                    end
                    --结算特效
                    local jackPotWinView = util_createView("CodeSpacePupSrc.SpacePupJackpotWinView")
                    self:addChild(jackPotWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    jackPotWinView:refreshRewardType(jackpotInfo, self, function()
                        curColIndex = curColIndex + 1
                        self:playRewardColBonusOverAni(curColIndex, rootIsPlay)
                    end)
                    self:playhBottomLight(winCount, nil, true)
                    
                    jackPotWinView:runCsbAction("start",false, function()
                        jackPotWinView:setClickState(true)
                        jackPotWinView:runCsbAction("idle", true)
                    end)
                    isJackpot = true
                    break
                end
            end
            if not isJackpot then
                curColIndex = curColIndex + 1
                self:playRewardColBonusOverAni(curColIndex, rootIsPlay)
            end
        end
    end
end

--判断当前列是否中jackpot
function CodeGameScreenSpacePupMachine:getCurColIsWin(_curCol)
    local curCol = _curCol
    local jackpotsWin = self.m_runSpinResultData.p_rsExtraData.jackpotsWin
    local isJackpot = false
    if jackpotsWin then
        for key,jackpotInfo in pairs(jackpotsWin) do
            if jackpotInfo.column + 1 == curCol then
                isJackpot = true
                break
            end
        end
    end
    return isJackpot
end

--bonus收集特效
function CodeGameScreenSpacePupMachine:addBonusRewardAni(_curIndex)
    local curIndex = _curIndex
    curIndex = curIndex + 1
    local symbolNodePos = self.m_symbolNodeRandom[curIndex]
    local fixPos = self:getRowAndColByPos(symbolNodePos-1)
    local symbolNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
    local curBet = globalData.slotRunData:getCurTotalBet()
    local rewardMul = self:getReSpinBonusScore(symbolNodePos-1)

    if rewardMul and symbolNode then
        local curReward = curBet * rewardMul
        local collectName = "shouji2"
        local darkName = "dark2"
        local idleName = "idleframe2_3"
        if self:getCurColIsWin(symbolNode.p_cloumnIndex) then
            collectName = "shouji"
            darkName = "dark"
            idleName = "idlefreme2_2"
        end
        symbolNode:runAnim(collectName, false, function()
            symbolNode:runAnim(darkName, false, function()
                symbolNode:runAnim(idleName, true)
            end)
        end)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_Collect)
            local light = util_createAnimation("SpacePup_respin_tuowei.csb")
            --转化坐标位置    
            local startPos = cc.p(util_getOneGameReelsTarSpPos(self,symbolNodePos-1))
            local endPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self.m_respinEffectNode)
            light:setPosition(startPos)
            self.m_respinEffectNode:addChild(light)

            local angle = util_getAngleByPos(startPos,endPos)
            light:setRotation( - angle)
            
            local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
            light:setScaleX(scaleSize / 360)
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_CollectFeedBack)
                self:playhBottomLight(curReward, true, true)
            end, 10/60)
            light:runCsbAction("actionframe",false,function()
                local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
                if curIndex >= symbolTotalNum then
                    self:showRespinOverView()
                else
                    self:addBonusRewardAni(curIndex)
                end

                light:stopAllActions()
                light:removeFromParent()
            end)
        end, 7/30)
    else
        local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
        if curIndex >= symbolTotalNum then
            self:showRespinOverView()
        else
            self:addBonusRewardAni(curIndex)
        end
    end
end

function CodeGameScreenSpacePupMachine:showRespinOverView(effectData)
    performWithDelay(self.m_scWaitNode, function()
        self:clearRespinLight()
        self.m_topRocketSpine:setVisible(false)
        self:setLastRespinIsWinState(false)

        local cutSceneFunc = function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_OverOver)
            end, 5/60)
            performWithDelay(self.m_scWaitNode, function()
                self.collectBonus = false
                self.m_respinEffectNode:removeAllChildren()
                self:removeRespinNode()
                --显示收集玩法相关控件
                self:showCollectionRes(true)
                for index=1, 5 do
                    self.m_respinBarPool[index]:setVisible(false)
                end
                for key,mask in pairs(self.node_mask_ary) do
                    mask:removeFromParent(true)
                end
                self:resetRespinBarData()
            end, 140/60)
        end

        gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_OverStart)
        local strCoins=util_formatCoins(self.m_serverWinCoins,50)
        local view=self:showReSpinOver(strCoins,function()
            self:showCutBaseSceneAni(false, function()
                -- self:changeBgAndReelBg(1)
                self:triggerReSpinOverCallFun(self.m_lightScore)
                self.m_lightScore = 0
                self:resetMusicBg()
                --检测是否同时触发了其他玩法
                self:checkNetDataFeatures()
            end)
        end)
        view.m_allowClick = false
        performWithDelay(view,function ()
            view.m_allowClick = true
        end,55/60)
        local lightAni = util_createAnimation("SpacePup_FreeSpinOver_guang.csb")
        view:findChild("guang"):addChild(lightAni)
        lightAni:runCsbAction("idleframe", true)
        view:setBtnClickFunc(cutSceneFunc)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.0,sy=1.0},631)
        util_setCascadeOpacityEnabledRescursion(view, true)
    end, 1.0)
end

function CodeGameScreenSpacePupMachine:resetRespinBarData()
    for col=1, 5 do
        local respinBar = self.m_respinBarPool[col]
        respinBar:resetBarData()
    end
end

--[[
    清理respin光效
]]
function CodeGameScreenSpacePupMachine:clearRespinLight()
    for index=1,5 do
        self.m_effectNode_respin[index]:removeAllChildren(true)
    end
end

-- 显示free spin
function CodeGameScreenSpacePupMachine:showEffect_FreeSpin(effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.triggerScatterDelayTime = 0
        self.m_beInSpecialGameTrigger = true
        local waitTime = 0
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            -- 取消掉赢钱线的显示
            self:shakeOneNodeForeverRootNode(1.5)
            self:clearWinLineEffect()
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if slotNode then
                        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                            local parent = slotNode:getParent()
                            if parent ~= self.m_clipParent then
                                slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                            else
                                slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 5)
                            end
                            slotNode:runAnim("actionframe")
                            local duration = slotNode:getAniamDurationByName("actionframe")
                            waitTime = util_max(waitTime,duration)
                        end
                    end
                end
            end
            self:playScatterTipMusicEffect(true)
        end
        
        performWithDelay(self,function(  )
            self:showFreeSpinView(effectData)
        end,waitTime)
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    end, self.triggerScatterDelayTime)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenSpacePupMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startOver)
    local showFSView = function ( ... )
        local cutSceneFunc = function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startOver)
            end, 5/60)
        end
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startStart)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:showCutPlaySceneAni(true, function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end)
            view:setBtnClickFunc(cutSceneFunc)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

--base到free和respin用一个过场
function CodeGameScreenSpacePupMachine:showCutPlaySceneAni(_isFree, _callFunc)
    local isFree = _isFree
    local callFunc = _callFunc
    if isFree then
        self:resetMusicBg(nil, self.m_publicConfig.Music_FG_Bg)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_Fg_CutScene)
    else
        self:resetMusicBg(nil, self.m_publicConfig.Music_Respin_Bg)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_Respin_CutScene)
    end
    self:runCsbAction("guochang1_xiazhui", false)
    self.m_cutSceneTopSpine:setVisible(true)
    self.m_cutSceneBottomAni:setVisible(true)
    self.m_cutSceneTopAni:runCsbAction("guochang1", false)
    self.m_cutSceneBottomAni:runCsbAction("guochang1", false)
    util_spinePlay(self.m_cutSceneTopSpine,"actionframe_guochang1",false)
    util_spinePlay(self.m_cutSceneBottomSpine,"actionframe_guochang1",false)
    util_spineFrameEvent(self.m_cutSceneTopSpine , "actionframe_guochang1","qiehuan",function ()
        local playType = 2
        if isFree then
            self:setScaleMainLayerByType(1)
        else
            self:setScaleMainLayerByType(2)
            playType = 3
        end
        self:changeBgAndReelBg(playType)
        self.m_cutSceneTopSpine:setVisible(false)
        self.m_cutSceneBottomSpine:setVisible(true)
        self.m_cutSceneTopAni:setVisible(false)
        self.m_cutSceneBottomAni:setVisible(true)
        self:runCsbAction("guochang1", false, function()
            self:runCsbAction("idleframe_da", true)
        end)
        self:removeTopTriggerScatter()
        --隐藏收集玩法相关控件
        self:showCollectionRes(false)
    end)
    
    util_spineEndCallFunc(self.m_cutSceneBottomSpine, "actionframe_guochang1", function()
        self.m_cutSceneBottomSpine:setVisible(false)
        self.m_cutSceneBottomAni:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

--free和respin回base用一个过场
function CodeGameScreenSpacePupMachine:showCutBaseSceneAni(_isFree, _callFunc)
    local isFree = _isFree
    local callFunc = _callFunc
    if isFree then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Base_CutScene)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_Base_CutScene)
    end
    self.m_cutSceneBottomSpine:setVisible(true)
    self.m_cutSceneBottomAni:setVisible(true)
    self.m_cutSceneBottomAni:runCsbAction("guochang", false)
    self.m_cutSceneTopAni:runCsbAction("guochang", false)
    util_spinePlay(self.m_cutSceneTopSpine,"actionframe_guochang",false)
    util_spinePlay(self.m_cutSceneBottomSpine,"actionframe_guochang",false)

    self:runCsbAction("guochang", false, function()
        self:setScaleMainLayerByType(1)
        self:runCsbAction("idleframe_da", true)
        self:changeBgAndReelBg(1)
        self.m_cutSceneTopSpine:setVisible(true)
        self.m_cutSceneBottomSpine:setVisible(false)
        self.m_cutSceneTopAni:setVisible(true)
        self.m_cutSceneBottomAni:setVisible(false)
    end)
    
    util_spineEndCallFunc(self.m_cutSceneTopSpine, "actionframe_guochang", function()
        self.m_cutSceneTopSpine:setVisible(false)
        self.m_cutSceneTopAni:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

function CodeGameScreenSpacePupMachine:showFreeSpinOverView()

    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_overStart, 3, 0, 1)
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_overOver)
        end, 5/60)
        performWithDelay(self.m_scWaitNode, function()
            self:clearWinLineEffect()
            --显示收集玩法相关控件
            self:showCollectionRes(true)
            self.m_baseFreeSpinBar:setVisible(false)
        end, 140/60)
    end
    if globalData.slotRunData.lastWinCoin > 0 then
        local lightAni = util_createAnimation("SpacePup_FreeSpinOver_guang.csb")
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver(strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:showCutBaseSceneAni(true, function()
                    self:triggerFreeSpinOverCallFun()
                end)
            end)

        view.m_allowClick = false
        performWithDelay(view,function ()
            view.m_allowClick = true
        end,55/60)
        view:findChild("guang"):addChild(lightAni)
        lightAni:runCsbAction("idleframe", true)
        view:setBtnClickFunc(cutSceneFunc)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.0,sy=1.0},631)
        util_setCascadeOpacityEnabledRescursion(view, true)
    else
        local view = self:showFreeSpinOverNoWin(function()
            self:showCutBaseSceneAni(true, function()
                self:triggerFreeSpinOverCallFun()
            end)
        end)
        view:setBtnClickFunc(cutSceneFunc)
    end
end

function CodeGameScreenSpacePupMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FreeSpinOver_NoWin",nil,_func)
    return view
end

-----by he 将除自定义动画之外的动画层级赋值
--
function CodeGameScreenSpacePupMachine:setGameEffectOrder()
    if self.m_gameEffects == nil then
        return
    end

    local lenEffect = #self.m_gameEffects
    for i = 1, lenEffect, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType ~= GameEffect.EFFECT_SELF_EFFECT then
            if effectData.p_effectType == GameEffect.EFFECT_BONUS then
                effectData.p_effectOrder = GameEffect.EFFECT_QUEST_DONE + 1
            else
                effectData.p_effectOrder = effectData.p_effectType
            end
            
        end
    end
end

---
-- 重写父类接口
--
function CodeGameScreenSpacePupMachine:checkNetDataFeatures()

    local featureDatas =self.m_runSpinResultData and self.m_runSpinResultData.p_features
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

            if self.checkControlerReelType and self:checkControlerReelType( ) then
                globalMachineController.m_isEffectPlaying = true
            end

            self.m_isRunningEffect = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
    
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
    
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    
                            for addPosIndex = 1 , #lineData.p_iconPos do
    
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
    
                            end
    
                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                end
                if checkEnd == true then
                    break
                end

            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            local params = {self.m_runSpinResultData.p_fsWinCoins,false,false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)

            -- self:sortGameEffects( )
            -- self:playGameEffect()

        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then  -- respin 玩法一并通过respinCount 来进行判断处理
            
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            
            -- if self.m_initFeatureData.p_status=="CLOSED" then
            --     return
            -- end

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            if self.m_runSpinResultData.p_selfMakeData.bonusType and (self.m_runSpinResultData.p_selfMakeData.bonusType == "select" or self.m_runSpinResultData.p_selfMakeData.bonusType == "pick") then
                local bonusGameEffect = GameEffectData.new()
                bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
                bonusGameEffect.p_effectOrder = GameEffect.EFFECT_QUEST_DONE + 1
                self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

                if self.checkControlerReelType and self:checkControlerReelType( ) then
                    globalMachineController.m_isEffectPlaying = true
                end
                
                self.m_isRunningEffect = true
            end
            
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})


            for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                local checkEnd = false
                for posIndex = 1 , #lineData.p_iconPos do
                    local pos = lineData.p_iconPos[posIndex] 

                    local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                    local colIndex = pos % self.m_iReelColumnNum + 1

                    local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                        checkEnd = true
                        local lineInfo = self:getReelLineInfo()
                        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS

                        for addPosIndex = 1 , #lineData.p_iconPos do

                            local posData = lineData.p_iconPos[addPosIndex]
                            local rowColData = self:getRowAndColByPos(posData)
                            lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData

                        end

                        lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                        self.m_reelResultLines = {}
                        self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                        break
                    end
                end
                if checkEnd == true then
                    break
                end

            end

            -- self:sortGameEffects( )
            -- self:playGameEffect()


        end
    end

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenSpacePupMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
   
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenSpacePupMachine:beginReel()
    self.collectBonus = false
    self.m_triggerBigWinEffect = false
    self.m_collectionBar:spinCloseTips()
    self.m_effectNode:setVisible(true)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 刷新wild
        self.m_effectNode:removeAllChildren(true)
        CodeGameScreenSpacePupMachine.super.beginReel(self)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        performWithDelay(self.m_scWaitNode, function()
            CodeGameScreenSpacePupMachine.super.beginReel(self)
            self.m_freeEffectAni:setVisible(true)
            self.m_freeEffectAni:runCsbAction("start",false,function()
                self.m_freeEffectAni:runCsbAction("idle",true)
            end)
        end, 0.2)
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenSpacePupMachine:addSelfEffect()
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local currentBubble = self.m_runSpinResultData.p_selfMakeData.currentBubble 

    if currentBubble and #currentBubble > 0 then   --气泡收集
        --连线消除气泡
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BUBBLE_CLEAR
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BUBBLE_CLEAR -- 动画类型
    end
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_selfMakeData.wildPos and #self.m_runSpinResultData.p_selfMakeData.wildPos > 0 and not self.m_runSpinResultData.p_selfMakeData.moveRoute then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_WILD_MOVE
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_WILD_MOVE -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenSpacePupMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BUBBLE_CLEAR then --清除气泡动画
        self:clearBubbleAction(function()
            -- 记得完成所有动画后调用这两行
            -- 作用：标识这个动画播放完结，继续播放下一个动画
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_WILD_MOVE then    --金鱼游动
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData.wildPos and not selfData.moveRoute then
            self:refreshFreeSpinWilds()
        end
        effectData.p_isPlay = true
        self:playGameEffect()
    end
    return true
end

--[[
    清除气泡动画
]]
function CodeGameScreenSpacePupMachine:clearBubbleAction(_callBack)
    if not self.m_runSpinResultData.p_selfMakeData then
        if type(_callBack) == "function" then
            _callBack()
        end
        return
    end

    --当前需要消除的气泡
    local currentBubble = self.m_runSpinResultData.p_selfMakeData.currentBubble 
    if currentBubble and #currentBubble > 0 then
        local totalCount = #currentBubble
        for index=1, #currentBubble do
            --获取要消除的气泡
            local slotIndex = currentBubble[index]
            local bubble = self.m_bubble_pool[tostring(slotIndex)]
            --获取终点节点
            local node_end = self.m_collectionBar:getNextNode(index)
            bubble:runCsbAction("over", false, function()
                bubble:setVisible(false)
            end)
            local isTriggerFG = self:isTriggerFeature()
            if index == totalCount then
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Bubble_Collect)
                if not isTriggerFG then
                    if type(_callBack) == "function" then
                        _callBack()
                    end
                end
            end
            performWithDelay(self.m_scWaitNode, function()
                local pos = cc.p(bubble:getPosition())
                local flyNode = util_createAnimation("SpacePup_baseshouji_1.csb")
                flyNode:setPosition(pos)
                self.m_particleNode:addChild(flyNode)

                flyNode:runCsbAction("actionframe", false, function()
                    --flyNode:setVisible(false)
                end)

                local particle = flyNode:findChild("SpacePup_tuowei_lizi")
                particle:setPositionType(0)
                particle:setDuration(-1)
                particle:resetSystem()

                performWithDelay(self.m_scWaitNode, function()
                    local delayTime = 28/60
                    local endPos = util_convertToNodeSpace(node_end,self.m_effectNode)
                    util_playMoveToAction(flyNode, delayTime, endPos,function()
                        particle:stopSystem()
                        if index == totalCount then
                            gLobalSoundManager:playSound(self.m_publicConfig.Music_Bubble_FeedBack)
                            --刷新所有气泡
                            self:refreshBubbleSymbol()
                            --刷新收集进度条
                            self:refreshCollectionBar()

                            if isTriggerFG then
                                if type(_callBack) == "function" then
                                    _callBack()
                                end
                            end
                        end
                        performWithDelay(self.m_scWaitNode, function()
                            flyNode:removeFromParent()
                        end, 1.0)
                    end)
                end, 6/60)
            end, 18/60)
        end
    end
end

function CodeGameScreenSpacePupMachine:isTriggerFeature()
    local featureDatas = self.m_runSpinResultData.p_features or {}

    if featureDatas and (featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureDatas[2] == SLOTO_FEATURE.FEATURE_RESPIN) then
        return true
    end
    return false
end

function CodeGameScreenSpacePupMachine:isTriggerSelectFeature()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if featureDatas and (featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureDatas[2] == SLOTO_FEATURE.FEATURE_RESPIN) and selfData and selfData.bonusType and selfData.bonusType ~= "pick" then
        return true
    end
    return false
end

--[[
    刷新Wild图标
]]
function CodeGameScreenSpacePupMachine:refreshFreeSpinWilds(_callFunc)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_effectNode:removeAllChildren(true)
    local moveRoute = selfData.moveRoute
    local wildPos = selfData.wildPos
    local callFunc = _callFunc

    if not wildPos then
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    self.m_effectNode:setVisible(true)

    if moveRoute then
        local totalCount = #moveRoute
        for index=1,#moveRoute do
            local startIndex = moveRoute[index][1]
            local endIndex = moveRoute[index][2]

            local startPos = self:getRowAndColByPos(tonumber(startIndex))
            --开始小块节点
            local startNode = self.m_bubble_pool[startIndex]

            local nodeEndPos = self:getRowAndColByPos(endIndex)
            --终止小块节点
            local endNode = self.m_bubble_pool[tostring(endIndex)]

            --开始小块倍数
            local startTimes = moveRoute[index][3]
            --结束小块倍数
            local endTimes = wildPos[tostring(endIndex)]

            local delayTime = 25/30
            local bottomSpine = self:createSpacePupSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD)
            local startSpine = self:createSpacePupSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD)
            startSpine:setPosition(util_convertToNodeSpace(startNode,self.m_effectNode))
            bottomSpine:setPosition(util_convertToNodeSpace(startNode,self.m_effectNode))
            self.m_effectNode:addChild(startSpine,endIndex,endIndex)
            self.m_effectNode:addChild(bottomSpine,-10)
            --移除屏幕时不用位移，动效算好位置了
            if endIndex ~= -1 then
                startSpine:runAnim("move", false)
            end
            bottomSpine:runAnim("ditu_over", false, function()
                bottomSpine:setVisible(false)
            end)
            local spineNode = startSpine:getNodeSpine()

            local skinName = "wild_" .. startTimes
            self:setFreeSpecialSymbolSkin(spineNode, skinName)
            if index == totalCount then
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Wild_Move)
            end
            if endTimes == 1 then
                local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
                util_playMoveToAction(startSpine, delayTime, endPos,function()
                    startSpine:runAnim("move2", false, function()
                        startSpine:runAnim("idleframe", true)
                        local skinName = "wild_" .. endTimes
                        self:setFreeSpecialSymbolSkin(spineNode, skinName)
                        if index == totalCount then
                            if type(callFunc) == "function" then
                                callFunc()
                            end
                        end
                    end)
                end)
            elseif endIndex == -1 then
                startSpine:runAnim("over", false, function()
                    startSpine:setVisible(false)
                    if index == totalCount then
                        if type(callFunc) == "function" then
                            callFunc()
                        end
                    end
                end)
            else
                local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
                if endTimes > startTimes then
                    util_playMoveToAction(startSpine, delayTime, endPos,function()
                        local skinChangeName = "wild_" .. endTimes
                        if startTimes == 1 and endTimes == 3 then
                            skinChangeName = "wild_3x"
                        end
                        self:setFreeSpecialSymbolSkin(spineNode, skinChangeName)
                        startSpine:runAnim("switch_x", false, function()
                            startSpine:runAnim("idleframe", true)
                            local skinName = "wild_" .. endTimes
                            self:setFreeSpecialSymbolSkin(spineNode, skinName)
                            if index == totalCount then
                                if type(callFunc) == "function" then
                                    callFunc()
                                end
                            end
                        end)
                    end)
                else
                    util_playMoveToAction(startSpine, delayTime, endPos,function()
                        startSpine:runAnim("move2", false, function()
                            startSpine:runAnim("idleframe", true)
                            if index == totalCount then
                                if type(callFunc) == "function" then
                                    callFunc()
                                end
                            end
                        end)
                    end)
                end
            end
        end
    else
        for index,times in pairs(wildPos) do
            local startPos = self:getRowAndColByPos(index)
            --开始小块节点
            local startNode = self.m_bubble_pool[tostring(index)]

            -- local startSpine = util_spineCreate("Socre_WinningFish_Wild", true, true)
            local startSpine = self:createSpacePupSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD)
            startSpine:setPosition(util_convertToNodeSpace(startNode,self.m_effectNode))
            self.m_effectNode:addChild(startSpine,index,index)
            self.m_effectNode:setVisible(false)

            local skinName = "wild_" .. startTimes
            local spineNode = startSpine:getNodeSpine()
            startSpine:runAnim("idleframe", true)
            self:setFreeSpecialSymbolSkin(spineNode, skinName)
        end
    end
end

function CodeGameScreenSpacePupMachine:createSpacePupSymbol(_symbolType)
    local symbol = util_createView("CodeSpacePupSrc.SpacePupSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenSpacePupMachine:shakeRootNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i = 1,12 do
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

--设置顶部respin和jackpot动画，透明度
function CodeGameScreenSpacePupMachine:setTopJackpotAct(_index, _onEnter)
    local index = _index
    local onEnter = _onEnter
    if onEnter then
        self.m_jackpotPool[index]:runCsbAction("idle", true)
    else
        self.m_jackpotPool[index]:runCsbAction("start", false, function()
            self.m_jackpotPool[index]:runCsbAction("idle", true)
        end)
    end
end

function CodeGameScreenSpacePupMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenSpacePupMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenSpacePupMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenSpacePupMachine.super.slotReelDown(self)
end

function CodeGameScreenSpacePupMachine:addPlayEffect()
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if not featureDatas then
        return
    end

    for i = 1, #featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then
            --隐藏收集玩法相关控件
            self:showCollectionRes(false)
            self:removeTopTriggerScatter()
            self:setSpecialSpinStates(true)
            if self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
                self:normalSpinBtnCall()
            end
        end
    end
end

function CodeGameScreenSpacePupMachine:removeTopTriggerScatter()
    self.m_scatterNode:removeAllChildren()
    for i=1, #self.m_bottomScatterTbl do
        local scatterNode = self.m_bottomScatterTbl[i]
        scatterNode:setVisible(true)
    end
    self.m_bottomScatterTbl = {}
end

function CodeGameScreenSpacePupMachine:getCurSymbolIsBonus(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return true
    end
    return false
end

function CodeGameScreenSpacePupMachine:playhBottomLight(_endCoins, _isFlyCoins, _playEffect)
    self.collectBonus = true
    if _playEffect then
        self.m_bottomUI:playCoinWinEffectUI(_endCoins, _isFlyCoins)
    end

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenSpacePupMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenSpacePupMachine:getCurBottomWinCoins()
    local winCoin = 0
    local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == sCoins then
        return winCoin
    end
    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end

function CodeGameScreenSpacePupMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenSpacePupMachine:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    elseif self.m_isNotice then -- 只用作预告中奖修改假滚数据
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(2, parentData.cloumnIndex)
    elseif self.m_isRespin_normal then   --respin假滚
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(2, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas

end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function CodeGameScreenSpacePupMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self:getNextReelSymbolType( )
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then

        
        if self.m_isNotice then   --respin假滚
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(2, parentData.cloumnIndex)
        elseif self.m_isRespin_normal then   --respin假滚
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(2, parentData.cloumnIndex)
        elseif self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end

        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType

end

function CodeGameScreenSpacePupMachine:changeBgAndReelBg(_bgType)
    -- 1.base；2.freespin；3.respin
    if _bgType == 1 then
        self.m_tblTopRocket[1]:setVisible(true)
        self.m_tblTopRocket[2]:setVisible(false)
        for i=1, 5 do
            self.m_jackpotPool[i]:runCsbAction("idleframe", true)
            self.m_tblRocketSpine[i]:setVisible(false)
        end

        self.m_freeBgSpine:setVisible(false)
        self.m_freeBgAni:setVisible(false)
        self.m_baseBgSpine:setVisible(true)
        util_spinePlay(self.m_baseBgSpine,"idleframe",true)
        self:runCsbAction("idleframe_da", true)
    else
        self.m_tblTopRocket[1]:setVisible(false)
        self.m_tblTopRocket[2]:setVisible(true)
        for i=1, 5 do
            self.m_tblRocketCircleAni[i]:runCsbAction("idleframe", true)
        end

        self.m_freeBgSpine:setVisible(true)
        self.m_freeBgAni:setVisible(true)
        self.m_baseBgSpine:setVisible(false)
        util_spinePlay(self.m_freeBgSpine,"idleframe",true)
        self.m_freeBgAni:runCsbAction("idleframe", true)
        if _bgType == 2 then
            for i=1, 5 do
                self.m_tblRocketSpine[i]:setVisible(false)
            end
        end
    end
    for i=1, 3 do
        if i == _bgType then
            self.m_tblGameReelBg[i]:setVisible(true)
        else
            self.m_tblGameReelBg[i]:setVisible(false)
        end
    end
end

function CodeGameScreenSpacePupMachine:tipsBtnIsCanClick()
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

-- 有特殊需求判断的 重写一下
function CodeGameScreenSpacePupMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif self:getCurSymbolIsBonus(_slotNode.p_symbolType) then
                local isPlayBuLing = self:getCurSymbolIsPlayBuLing(_slotNode)
                if not isPlayBuLing then
                    _slotNode:runAnim("idleframe2", true)
                end
                return isPlayBuLing
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

function CodeGameScreenSpacePupMachine:getCurSymbolIsPlayBuLing(_slotNode)
    if _slotNode.p_cloumnIndex < 4 then
        return true
    else
        -- local curRow = _slotNode.p_rowIndex
        local lastCol = _slotNode.p_cloumnIndex - 1
        local bonusCount = 0
        local isPlay = false
        for colCol=1, lastCol do
            for curRow =1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(colCol, curRow, SYMBOL_NODE_TAG)
                if targSp and self:getCurSymbolIsBonus(targSp.p_symbolType) then
                    bonusCount = bonusCount + 1
                end
            end
        end
        if _slotNode.p_cloumnIndex == 4 and bonusCount > 0 then
            isPlay = true
        elseif _slotNode.p_cloumnIndex == 5 and bonusCount > 1 then
            isPlay = true
        end
        return isPlay
    end
end

function CodeGameScreenSpacePupMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenSpacePupMachine:symbolBulingEndCallBack(node)
    if node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        node:runAnim("idleframe2", true)
    elseif node.p_symbolType and node.p_symbolType == self.SYMBOL_SCORE_BONUS then
        node:runAnim("idleframe2", true)
    end
end

function CodeGameScreenSpacePupMachine:playScatterTipMusicEffect(_isFreeMore)
    if not _isFreeMore then
        if self.m_ScatterTipMusicPath ~= nil then
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
            -- gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        end
    end
end

function CodeGameScreenSpacePupMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenSpacePupMachine:showBigWinLight(_func)
    local lightSpine = util_spineCreate("SpacePup_dy",true,true)
    local lightAni = util_createAnimation("SpacePup_dy.csb")

    local particleTbl = {}
    for i=1, 3 do
        particleTbl[i] = lightAni:findChild("Particle_"..i)
        particleTbl[i]:resetSystem()
    end

    self:findChild("Node_bigWin"):addChild(lightSpine)
    self:findChild("Node_bigWin"):addChild(lightAni)
    util_spinePlay(lightSpine, "actionframe", false)
    util_spineEndCallFunc(lightSpine, "actionframe", function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        for i=1, 3 do
            particleTbl[i]:stopSystem()
        end
        lightAni:setVisible(false)
        lightSpine:setVisible(false)
        if type(_func) == "function" then
            _func()
        end
    end)
    performWithDelay(self.m_scWaitNode, function()
        lightAni:removeFromParent()
        lightSpine:removeFromParent()
    end, 90/30)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Celebrate_Win)
    self:shakeRootNode()
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenSpacePupMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_BIGWIN - 1
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

return CodeGameScreenSpacePupMachine






