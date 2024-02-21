---
-- island li
-- 2019年1月26日
-- CodeGameScreenCactusMariachiMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenCactusMariachiMachine = class("CodeGameScreenCactusMariachiMachine", BaseNewReelMachine)

CodeGameScreenCactusMariachiMachine.MAIN_ADD_POSY = 0
CodeGameScreenCactusMariachiMachine.MAIN_SHOP_ADD_POSY = 0
CodeGameScreenCactusMariachiMachine.m_shopRootScale = 1

CodeGameScreenCactusMariachiMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenCactusMariachiMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenCactusMariachiMachine.SYMBOL_SCORE_11 = 10

CodeGameScreenCactusMariachiMachine.EFFECT_OPEN_SHOP = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenCactusMariachiMachine.EFFECT_PLAY_TOP_ANI = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenCactusMariachiMachine.EFFECT_WIN_LINE = GameEffect.EFFECT_SELF_EFFECT - 3
CodeGameScreenCactusMariachiMachine.EFFECT_ADD_WILD = GameEffect.EFFECT_SELF_EFFECT - 4
CodeGameScreenCactusMariachiMachine.EFFECT_CHANGE_SYMBOL = GameEffect.EFFECT_SELF_EFFECT - 5
CodeGameScreenCactusMariachiMachine.EFFECT_LOCK_NEW_SYMBOL = GameEffect.EFFECT_SELF_EFFECT - 6
CodeGameScreenCactusMariachiMachine.EFFECT_LOCK_SYMBOL = GameEffect.EFFECT_SELF_EFFECT - 7
CodeGameScreenCactusMariachiMachine.EFFECT_COLLECT_ICON = GameEffect.EFFECT_SELF_EFFECT - 8

CodeGameScreenCactusMariachiMachine.m_shopMusicName = "CactusMariachiSounds/music_CactusMarichi_Shop_%s.mp3"

-- CodeGameScreenCactusMariachiMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
-- CodeGameScreenCactusMariachiMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识


-- 构造函数
function CodeGameScreenCactusMariachiMachine:ctor()
    CodeGameScreenCactusMariachiMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true

    self.m_lightScore = 0

    self.m_selfMakeData = {}
    self.m_selfPlayData = {}
    self.m_allFigureSpine = {}
    self.m_allGuoChangSpine = {}
    self.m_allFigureLockAni = {}
    self.m_topNameNode = {}
    self.m_topNameAni = {}
    self.m_topNameSuperNode = {}
    self.m_topNameSuperAni = {}
    self.tblPlayData = {}
    self.topSymbolNodeList = {}
    self.topLockEffectNodeList = {{}, {}}
    self.tblStopAllEffect = {}
    --init
    self:initGame()
end

function CodeGameScreenCactusMariachiMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

function CodeGameScreenCactusMariachiMachine:isFixSymbol()
    return false
end

function CodeGameScreenCactusMariachiMachine:resetData()
    --self.m_selfMakeData = {}
    self.m_selfPlayData = {}
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCactusMariachiMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CactusMariachi"  
end

function CodeGameScreenCactusMariachiMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_baseBgSpine = util_spineCreate("CactusMariachi_BG",true,true)
    self.m_gameBg:findChild("base_bg"):addChild(self.m_baseBgSpine)
    self:changeBgSpine(1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_CactusMariachiView = util_createView("CodeCactusMariachiSrc.CactusMariachiView")
    -- self:findChild("xxxx"):addChild(self.m_CactusMariachiView)
    
    self.m_shopView = util_createView("CodeCactusMariachiSrc.CactusMariachiShopView", self)
    self:addChild(self.m_shopView, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    self.m_shopView:setVisible(false)

    local node_bar = self.m_bottomUI:findChild("node_bar")
    self.m_baseFreeSpinBar = util_createView("CodeCactusMariachiSrc.CactusMariachiFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
    self.m_baseFreeSpinBar:setPositionY(35)

    self.m_baseSuperFreeSpinBar = util_createView("CodeCactusMariachiSrc.CactusMariachiSuperFreespinBarView")
    node_bar:addChild(self.m_baseSuperFreeSpinBar)
    self.m_baseSuperFreeSpinBar:setVisible(false)
    self.m_baseSuperFreeSpinBar:setPositionY(35)

    self.m_playBg = util_createAnimation("CactusMariachi_wanfaban.csb")
    self:findChild("Node_wanfaban"):addChild(self.m_playBg)
    self.m_playBg:setVisible(false)

    self.m_shopBtn = util_createAnimation("CactusMariachi_shopEntrance.csb")
    self:findChild("Node_store"):addChild(self.m_shopBtn)

    self.m_baseShopSpine = util_spineCreate("CactusMariachi_ShopEntrance",true,true)
    self.m_shopBtn:findChild("shop"):addChild(self.m_baseShopSpine)
    util_spinePlay(self.m_baseShopSpine,"idleframe2",true)

    self.m_shopCoins = util_createAnimation("CactusMariachi_shopcoins.csb")
    self.m_shopBtn:findChild("Node_coin"):addChild(self.m_shopCoins)

    self.m_totalShopCoins = self.m_shopCoins:findChild("m_lb_coins")

    self.m_tips = util_createAnimation("CactusMariachi_tip.csb")
    self:findChild("Node_tips"):addChild(self.m_tips)
    self.m_tips:setVisible(false)

    self.m_nodeBottomLight = self:findChild("Node_bottomLight")
    self.m_bottomLightSpine = util_spineCreate("Socre_CactusMariachi_languang",true,true)
    self.m_nodeBottomLight:addChild(self.m_bottomLightSpine)
    util_spinePlay(self.m_bottomLightSpine,"zhujiemian_idle",true)

    self.m_nodeCollect = self:findChild("Node_collect")

    self.m_nodeMask = self:findChild("Node_mask")
    self.m_figureSpine_mask = util_createAnimation("CactusMariachi_Mask.csb")
    self.m_nodeMask:addChild(self.m_figureSpine_mask)
    self.m_nodeMask:setVisible(false)

    self.m_nodeFigureRoot = self:findChild("Node_figure")
    self.m_audienceSpine = util_spineCreate("CactusMariachi_guanzhong",true,true)
    self.m_nodeFigureRoot:addChild(self.m_audienceSpine)
    self.m_audienceSpine:setVisible(false)

    self.m_allFigureSpine[1] = util_spineCreate("Socre_CactusMariachi_h1",true,true)
    self:findChild("Node_figure1"):addChild(self.m_allFigureSpine[1])
    util_spinePlay(self.m_allFigureSpine[1],"zhujiemian_idle",true)

    self.m_allFigureSpine[2] = util_spineCreate("Socre_CactusMariachi_h2",true,true)
    self:findChild("Node_figure2"):addChild(self.m_allFigureSpine[2])
    util_spinePlay(self.m_allFigureSpine[2],"zhujiemian_idle",true)

    self.m_allFigureSpine[3] = util_spineCreate("Socre_CactusMariachi_h3",true,true)
    self:findChild("Node_figure3"):addChild(self.m_allFigureSpine[3])
    util_spinePlay(self.m_allFigureSpine[3],"zhujiemian_idle",true)

    self.m_allFigureSpine[4] = util_spineCreate("Socre_CactusMariachi_h4",true,true)
    self:findChild("Node_figure4"):addChild(self.m_allFigureSpine[4])
    util_spinePlay(self.m_allFigureSpine[4],"zhujiemian_idle",true)

    self.m_nodeGuoChang = self:findChild("Node_guochang")
    self.m_nodeGuoChang:setVisible(false)

    self.m_allGuoChangSpine[1] = util_spineCreate("Socre_CactusMariachi_h1",true,true)
    self.m_nodeGuoChang:addChild(self.m_allGuoChangSpine[1])

    self.m_allGuoChangSpine[2] = util_spineCreate("Socre_CactusMariachi_h2",true,true)
    self.m_nodeGuoChang:addChild(self.m_allGuoChangSpine[2])

    self.m_allGuoChangSpine[3] = util_spineCreate("Socre_CactusMariachi_h3",true,true)
    self.m_nodeGuoChang:addChild(self.m_allGuoChangSpine[3])

    self.m_allGuoChangSpine[4] = util_spineCreate("Socre_CactusMariachi_h4",true,true)
    self.m_nodeGuoChang:addChild(self.m_allGuoChangSpine[4])

    self.m_nodePlaySelect = util_createAnimation("CactusMariachi_wanfaxuanze.csb")
    self:findChild("Node_wanfaxuanze"):addChild(self.m_nodePlaySelect)

    local tblLockAniPos = {cc.p(-340, -80), cc.p(-135, -80), cc.p(150, -80), cc.p(375, -80)}
    self.topPlayPos = {
        {cc.p(0, 27), cc.p(0, -27), cc.p(0, 0), cc.p(0, 0)},
        {cc.p(0, 27), cc.p(0, -27), cc.p(0, 0), cc.p(0, 0)},
        {cc.p(0, 38), cc.p(0, -1), cc.p(0, -42), cc.p(0, 0)},
        {cc.p(0, 38), cc.p(0, 10.9), cc.p(0, -14), cc.p(0, -42)},
    }
    for i=1, 4 do
        self.m_allFigureLockAni[i] = util_createAnimation("CactusMariachi_renwusuoding.csb")
        self:findChild("Node_figure"..i):addChild(self.m_allFigureLockAni[i])
        self.m_allFigureLockAni[i]:setPosition(tblLockAniPos[i])
        self.m_allFigureLockAni[i]:setVisible(false)

        self.m_topNameNode[i] = self.m_nodePlaySelect:findChild("Node_wanfaxuanze"..i)
        self.m_topNameAni[i] = util_createAnimation("CactusMariachi_wanfaxuanze1.csb")
        self.m_topNameNode[i]:addChild(self.m_topNameAni[i])

        self.m_topNameSuperNode[i] = self.m_playBg:findChild("Node_wanfa"..i)
        self.m_topNameSuperAni[i] = util_createAnimation("CactusMariachi_wanfaxuanze2.csb")
        self.m_topNameSuperNode[i]:addChild(self.m_topNameSuperAni[i])
    end
    
    --灯光
    self.m_nodeLight = self:findChild("Node_Light")
    self.m_nodeLight:setLocalZOrder(20)

    self.m_lightSpine = util_spineCreate("CactusMariachi_deng",true,true)
    self.m_nodeLight:addChild(self.m_lightSpine)
    self.m_lightSpine:setVisible(false)

    self.m_topSymbolNode = self:findChild("Node_topSymbol")

    self.m_bottomEffectNode = self:findChild("Node_bottomEffect")

    self.m_topEffectNode = self:findChild("Node_topEffect")

    self.m_topMulNode = self:findChild("Node_mul")

    for i=1, 15 do
        self.topSymbolNodeList[i] = self:initTopSymbol(i-1)
        self.topSymbolNodeList[i]:setVisible(false)
    end
   
    self:addClick(self.m_shopBtn:findChild("Panel_click"))
    self:addClick(self.m_shopCoins:findChild("Button_1"))

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitNodeFigure = cc.Node:create()
    self:addChild(self.m_scWaitNodeFigure)

    self.m_scWaitNodeFigureOut = cc.Node:create()
    self:addChild(self.m_scWaitNodeFigureOut)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "CactusMariachi_shoujifankui.csb")
    self.m_shopView:scaleShopMainLayer(self.m_shopRootScale, self.MAIN_SHOP_ADD_POSY)
end

-- function CodeGameScreenCactusMariachiMachine:enterGamePlayMusic(  )
--     scheduler.performWithDelayGlobal(function(  )
        
--       -- self:playEnterGameSound( "CactusMariachiSounds/music_CactusMariachi_enter.mp3" )

--     end,0.4,self:getModuleName())
-- end

function CodeGameScreenCactusMariachiMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCactusMariachiMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenCactusMariachiMachine:addObservers()
    CodeGameScreenCactusMariachiMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
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
        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE and not self.m_bInSuperFreeSpin then
            bgmType = "FG"
        else
            bgmType = self:getCurBgmType()
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "CactusMariachiSounds/music_CactusMariachi_last_win_"..bgmType.."_"..soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenCactusMariachiMachine:getCurBgmType()
    local shopMusicIndex = self.m_shopView:getCurPlayMusicIndex()
    if self.m_bInSuperFreeSpin then
        shopMusicIndex = self:getCurMusicNameShow()
    end
    return shopMusicIndex+1
end

function CodeGameScreenCactusMariachiMachine:enterGamePlayMusic(  )
    globalMachineController:playBgmAndResume("CactusMariachiSounds/music_CactusMariachi_EnterGame.mp3", 5, 0, 1)
    -- self:playEnterGameSound("CactusMariachiSounds/music_CactusMariachi_EnterGame.mp3")
end

function CodeGameScreenCactusMariachiMachine:playClickEffect()
    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_Click.mp3")
end

function CodeGameScreenCactusMariachiMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1
    local shopPosY = 0

    local ratio = display.height/display.width

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    -- if hScale < wScale then
    --     mainScale = hScale
    -- else
    --     mainScale = wScale
    --     self.m_isPadScale = true
    -- end
    if globalData.slotRunData.isPortrait == true then
        print("CodeGameScreenCactusMariachiMachine-不是竖版")
    else
        if display.width / display.height >= 1668/768 then
            mainScale = mainScale * 1.015
            self.m_shopRootScale = mainScale
            self.MAIN_ADD_POSY = 0
        elseif display.width / display.height >= 1370/768 then
            mainScale = mainScale * 1.005
            self.m_shopRootScale = mainScale
            self.MAIN_ADD_POSY = 3
            shopPosY = 5
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 1.0
            self.m_shopRootScale = mainScale * 0.9
            shopPosY = -30
        elseif display.width / display.height >= 960/640 then
            mainScale = mainScale * 0.9
            self.m_shopRootScale = mainScale * 0.95
            shopPosY = -10
            self.MAIN_ADD_POSY = -30
        elseif display.width / display.height >= 1024/768 then
            mainScale = 0.93 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
            self.m_shopRootScale = mainScale * 0.88
            shopPosY = -25
            self.MAIN_ADD_POSY = -35
        end
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.MAIN_SHOP_ADD_POSY = self.MAIN_SHOP_ADD_POSY + mainPosY + shopPosY
        self.m_machineNode:setPositionY(mainPosY + self.MAIN_ADD_POSY)
    end
end

function CodeGameScreenCactusMariachiMachine:onExit()
    if self.m_updateVolumeHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateVolumeHandlerID)
        self.m_updateVolumeHandlerID = nil
    end

    if gLobalViewManager:isViewPause() then
        return
    end

    CodeGameScreenCactusMariachiMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenCactusMariachiMachine:getCurMusicSatate()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.musicUnlock then
        return selfData.musicUnlock
    end
    return false
end

function CodeGameScreenCactusMariachiMachine:refreshShopCoins(_curCoins)
    self.m_totalShopCoins:setString(_curCoins)
    self.m_shopView:refreshShopCoins(_curCoins)
end

function CodeGameScreenCactusMariachiMachine:refreshShopLikeNum()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData then
        local likeNum = selfData.likes
        if likeNum then
            self.m_shopView:refreshShopLikeNum(likeNum)
        end
    end
end

function CodeGameScreenCactusMariachiMachine:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        self:showTips()
    elseif name == "Panel_click" then
        self:showShopView()
    end
end

function CodeGameScreenCactusMariachiMachine:setBtnCloseState(_state)
    self.m_shopBtn:findChild("Panel_click"):setTouchEnabled(_state)
end

function CodeGameScreenCactusMariachiMachine:showShopView(isPlayLock)
    if not self:shopBtnIsCanClick() then
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self.m_shopView:setVisible(true)
    self.m_shopView:setBtnCloseState(false)
    self:setBtnCloseState(false)
    self:refreshShopLikeNum()
    self.m_shopView:refreshAlbumData(true, true)
    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_openStore.mp3")
    self.m_shopView:runCsbAction("start",false, function()
        self.m_shopView:setBtnCloseState(true)
        self:setBtnCloseState(true)
        self.m_shopView:superOverCutShop(isPlayLock)
        self.m_shopView:runCsbAction("idle")
    end)
    self:setFigureSpineVisible(false)
end

function CodeGameScreenCactusMariachiMachine:beginReel()
    if self.tipsState then
        self:showTips()
    end
    CodeGameScreenCactusMariachiMachine.super.beginReel(self)
end

function CodeGameScreenCactusMariachiMachine:showTips()
    if not self:shopBtnIsCanClick() then
        return
    end
    self:playClickEffect()
    self.m_tips:stopAllActions()
    local function closeTips()
        if self.tipsState then
            self.tipsState = false
            self.m_tips:runCsbAction("over",false, function()
                self.m_tips:setVisible(false)
            end)
        end
    end

    if not self.tipsState then
        self.tipsState = true
        self.m_tips:setVisible(true)
        self.m_tips:runCsbAction("start",false, function()
            self.m_tips:runCsbAction("idle",true)
        end)
    else
        closeTips()
    end
    performWithDelay(self.m_tips, function ()
	    closeTips()
    end, 5.0)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCactusMariachiMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_CactusMariachi_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_CactusMariachi_11"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCactusMariachiMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCactusMariachiMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end
----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCactusMariachiMachine:MachineRule_initGame(spinData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --Free模式
    if self.m_bProduceSlots_InFreeSpin then

        --不是进入fs时 切背景
        if self.m_runSpinResultData.p_freeSpinsLeftCount ~= self.m_runSpinResultData.p_freeSpinsTotalCount then
            self:changeBgSpine(2)
            self.m_baseFreeSpinBar:changeFreeSpinByCount()
            self:setFigureSpineVisible(false)
        end
    end
    if self.m_bInSuperFreeSpin then
        self:changeBgSpine(3)
        self.m_baseSuperFreeSpinBar:changeFreeSpinByCount()
        self:initSuperFreePlayState()
        self:setShopBtnAndPlayBgState(true)
    end

    self.m_shopView:initGameRefreshMusic()
end

function CodeGameScreenCactusMariachiMachine:changeBgSpine(_bgType)
    -- 1.normal；2.freespin；3.superspin
    if _bgType == 1 then
        util_spinePlay(self.m_baseBgSpine,"idleframe",true)
    elseif _bgType == 2 then
        util_spinePlay(self.m_baseBgSpine,"idleframe2",true)
    elseif _bgType == 3 then
        util_spinePlay(self.m_baseBgSpine,"idleframe3",true)
    end
    self:setReelBgState(_bgType)
end

function CodeGameScreenCactusMariachiMachine:setReelBgState(_bgType)
    if _bgType == 1 then
        self:findChild("reel_base"):setVisible(true)
        self:findChild("reel_free"):setVisible(false)
    else
        self:findChild("reel_free"):setVisible(true)
        self:findChild("reel_base"):setVisible(false)
    end
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenCactusMariachiMachine:initGameStatusData(gameData)
    CodeGameScreenCactusMariachiMachine.super.initGameStatusData(self,gameData)
    
    self.tblSuperFreeList = {}
    local specialData = gameData.special
    if specialData then
        local freespinData = specialData.freespin
        local feature = specialData.features
        if feature then
            self.m_runSpinResultData.p_features = feature
            self.m_runSpinResultData.p_freeSpinsLeftCount = freespinData.freeSpinsLeftCount
            self.m_runSpinResultData.p_freeSpinsTotalCount = freespinData.freeSpinsTotalCount
        end
    end
    if gameData.gameConfig ~= nil  then
        if gameData.gameConfig.extra ~= nil  then
            local extraData = gameData.gameConfig.extra
            local shopCoins = extraData.coins

            self:refreshShopCoins(shopCoins)
            self.m_shopView:refreshView(extraData)
            self.m_shopView:refreshShopLikeNum()
            self.m_bInSuperFreeSpin = extraData.superFree
            self.tblSuperFreeList = extraData.superFreeType
            --最后一次掉线，特殊处理
            if self.m_bInSuperFreeSpin then
                if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 and not self.m_runSpinResultData.p_features[2] then
                    self.m_bInSuperFreeSpin = false
                end
            end
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData then
        if selfData.type and selfData.type[1] == 1 then
            self.tblPlayData = {}
            for k, v in pairs(selfData.type) do
                if v == 1 then
                    self.tblPlayData[k] = true
                end
                self:initGameAddTopPlayName(k)
            end
            self:addSelfEffect()
        end
    end

    local features = self.m_runSpinResultData.p_features or {}
    if features[2] == RESPIN_MODE and not self.m_bInSuperFreeSpin then
        self.m_nodeMask:setVisible(true)
        self.m_figureSpine_mask:runCsbAction("idle", true)
    end
end

--添加顶部玩法文本
function CodeGameScreenCactusMariachiMachine:initGameAddTopPlayName(_nameIndex)
    local tblIdleName = {"idlehong", "idlezi", "idlelan", "idlelv"}

    local isRun, namePos = self:getCurTopNamePos(_nameIndex)
    if isRun then
        self.m_topNameAni[namePos]:runCsbAction(tblIdleName[_nameIndex], true)
    end
end

function CodeGameScreenCactusMariachiMachine:checkTriggerFsOver()
    if self.m_initSpinData.p_freeSpinsLeftCount == 0 and not self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
        return true
    end
    return false
end

function CodeGameScreenCactusMariachiMachine:getCurLineIsScatter(_vecValidMatrixSymPos)
    local isScatterLine = false
    local totalScatterNum = #_vecValidMatrixSymPos
    local curScatterNum = 0
    for k, v in pairs(_vecValidMatrixSymPos) do
        local symbolNode = self:getFixSymbol(v.iY , v.iX , SYMBOL_NODE_TAG)
        if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            curScatterNum = curScatterNum + 1
        end
    end
    if curScatterNum == totalScatterNum then
        isScatterLine = true
    end
    return isScatterLine
end

function CodeGameScreenCactusMariachiMachine:lineLogicEffectType(winLineData, lineInfo, iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData, lineInfo)

    local vecValidMatrixSymPos = lineInfo.vecValidMatrixSymPos
    local isScatterLine = self:getCurLineIsScatter(vecValidMatrixSymPos)

    if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum and isScatterLine then
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

--
--单列滚动停止回调
--
function CodeGameScreenCactusMariachiMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCactusMariachiMachine.super.slotOneReelDown(self,reelCol)

    ---本列是否开始长滚
    local isTriggerLongRun = false
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true
    end
    if isTriggerLongRun then
        -- 开始快滚的时候 其他scatter 播放ialeframe2
        self:playScatterSpine("idleframe2", reelCol)
    else
        if reelCol == self.m_iReelColumnNum then
            self:playScatterSpine("idleframe", reelCol)
        end
    end
end

function CodeGameScreenCactusMariachiMachine:playScatterSpine(_spineName, _reelCol)
    performWithDelay(self.m_scWaitNode,function()
        for iCol = 1, _reelCol  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if _spineName == "idleframe" and targSp.m_currAnimName ~= "buling" then
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

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenCactusMariachiMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenCactusMariachiMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

function CodeGameScreenCactusMariachiMachine:notifyClearBottomWinCoin()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    else
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    end
    -- 不在区分是不是在 freespin下了 2019-05-08 20:56:44
end

------------  respin 代码 这个respin就是不是单个小格滚动的那种 

---
-- 触发respin 玩法
--
function CodeGameScreenCactusMariachiMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:lockIcon(effectData)

    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenCactusMariachiMachine:addLastWinSomeEffect() -- add big win or mega win
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        CodeGameScreenCactusMariachiMachine.super.addLastWinSomeEffect(self)
    else
        local notAddEffect = self:checkIsAddLastWinSomeEffect()

        if notAddEffect then
            return
        end

        self.m_bIsBigWin = false

        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        if self.getNewBingWinTotalBet then
            lTatolBetNum = self:getNewBingWinTotalBet()
        end
        self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

        local iBigWinLimit = self.m_BigWinLimitRate
        local iMegaWinLimit = self.m_MegaWinLimitRate
        local iEpicWinLimit = self.m_HugeWinLimitRate
        local iLegendaryLimit = self.m_LegendaryWinLimitRate
        if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
            self.m_bIsBigWin = true
        elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
            self.m_bIsBigWin = true
        elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
            self.m_bIsBigWin = true
        elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
            self.m_bIsBigWin = true
        end
    end
end

function CodeGameScreenCactusMariachiMachine:addSpecialBigWinEffect()
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    for i=#self.m_gameEffects ,1,-1 do
        local effect = self.m_gameEffects[i]
        if effect.p_selfEffectType == GameEffect.EFFECT_RESPIN_OVER or
            effect.p_selfEffectType == self.EFFECT_LOCK_NEW_SYMBOL or
                effect.p_selfEffectType == self.EFFECT_CHANGE_SYMBOL or
                    effect.p_selfEffectType == self.EFFECT_ADD_WILD or
                        effect.p_selfEffectType == self.EFFECT_WIN_LINE or 
                            effect.p_selfEffectType == GameEffect.EFFECT_LINE_FRAME then
                                local _effectType = self:getWinEffect(winCoins)
                                if not _effectType then
                                    return
                                end
                                local effectData = GameEffectData.new()
                                effectData.p_effectType = _effectType
                                table.insert(self.m_gameEffects,i+1,effectData)
                                self.m_llBigOrMegaNum = winCoins
                    break
        end
        
    end 
end

function CodeGameScreenCactusMariachiMachine:triggerReSpinOverCallFun()
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = 0
    self.m_preReSpinStoredIcons = nil

    local coins = nil
    -- if self.m_bProduceSlots_InFreeSpin then
    --     coins = self:getLastWinCoin() or 0
    --     local addCoin = self.m_serverWinCoins
    --     -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    -- else
    --     coins = self.m_serverWinCoins or 0

    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    -- end

    self:addRespinOverSelfEffect()
    --添加玩法一（winLine玩法）结束后连线动画
    self:addWinLineEffect()
    
    self:addSpecialBigWinEffect()
    
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    -- self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

function CodeGameScreenCactusMariachiMachine:showEffect_RespinOver(effectData)

    self:checkAddBasePlayEffect()

    self:checkAddFreeOverEffect()  

    effectData.p_isPlay = true
    self:triggerReSpinOverCallFun()

    return true
end

function CodeGameScreenCactusMariachiMachine:getTypeIsAddFrame(_symbolType)
    if _symbolType >= 4 and _symbolType <= 10 then
        return true
    end
    return false
end

function CodeGameScreenCactusMariachiMachine:initTopSymbol(_pos)
    local symbolNode = self:createCactusSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD)
    local nodePos = self:getTopSymbolPos(_pos)
    symbolNode:setPosition(nodePos)
    self.m_topSymbolNode:addChild(symbolNode)
    return symbolNode
end

function CodeGameScreenCactusMariachiMachine:getTopSymbolPos(_pos)
    local clipTarPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
    local nodePos = self.m_topSymbolNode:convertToNodeSpace(worldPos)
    return nodePos
end

function CodeGameScreenCactusMariachiMachine:createCactusSymbol(_symbolType)
    local symbol = util_createView("CodeCactusMariachiSrc.CactusMariachiSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenCactusMariachiMachine:lockIcon(_effectData, isNewLock)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local tblIconList
    if isNewLock then
        tblIconList = selfData.newIcon or {}
    else
        tblIconList = selfData.locIcon or {}
        self.topLockEffectNodeList = {{}, {}}
    end
    local delayTime = 30/60
    local totalNum = #tblIconList
    for k,v in pairs(tblIconList) do
        local changePos = tonumber(v)
        local fixPos = self:getRowAndColByPos(changePos)
        local _symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)

        local topSymbolNode = self.topSymbolNodeList[changePos+1]
        if topSymbolNode and not topSymbolNode:isVisible() then
            local nodePos = self:getTopSymbolPos(changePos)
            topSymbolNode:changeSymbolCcb(_symbolNode.p_symbolType)

            local frameNode, bottomNode
            if not isNewLock then
                frameNode = util_createAnimation("CactusMariachi_WinningRespin_Border.csb")
                frameNode:setPosition(nodePos)
                self.m_topEffectNode:addChild(frameNode)
                self.topLockEffectNodeList[1][changePos+1] = frameNode

                bottomNode = util_createAnimation("CactusMariachi_di.csb")
                bottomNode:setPosition(nodePos)
                self.m_bottomEffectNode:addChild(bottomNode)
                self.topLockEffectNodeList[2][changePos+1] = bottomNode
            end

            local lockEffectNode = util_createAnimation("CactusMariachi_suoding.csb")
            lockEffectNode:setPosition(nodePos)
            self.m_topEffectNode:addChild(lockEffectNode, 10)
            lockEffectNode:runCsbAction("suo2", false, function()
                lockEffectNode:removeFromParent()
            end)

            topSymbolNode:setVisible(true)
            local actionList = {}
            actionList[#actionList + 1] = cc.ScaleTo:create(4/30, 1.2)
            actionList[#actionList + 1] = cc.ScaleTo:create(6/30, 1.0)
            local seq = cc.Sequence:create(actionList)
            topSymbolNode:runAction(seq)

            performWithDelay(self.m_scWaitNode, function()
                if k == totalNum then
                    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_winningLock.mp3")
                end
                if not isNewLock then
                    frameNode:runCsbAction("suoding",false, function ()
                        _symbolNode:setVisible(false)
                        frameNode:runCsbAction("idle",true)
                    end)
                    bottomNode:runCsbAction("chuxian", false, function()
                        bottomNode:runCsbAction("idle",true)
                    end)
                else
                    _symbolNode:setVisible(false)
                end
            end, 10/60)
        end
    end

    local callFunc = function()
        performWithDelay(self.m_scWaitNode, function()
            if _effectData then
                _effectData.p_isPlay = true
                self:playGameEffect()
            end
        end, 0.5)
    end
    
    if isNewLock then
        performWithDelay(self.m_scWaitNode, function()
            self:unLockIcon(callFunc)
        end, delayTime)
    elseif self.m_bInSuperFreeSpin then
        self:playSuperFreeTopNameAni(1, callFunc)
    else
        self:playEndLight(1)
        self:playEndTopNameAni(1)
        performWithDelay(self.m_scWaitNode, function()
            if callFunc then
                callFunc()
            end
        end, delayTime)
    end
end

function CodeGameScreenCactusMariachiMachine:unLockIcon(_endCallFunc)
    if self.m_bInSuperFreeSpin then
        self:closeLockPlayTopNameAni(1, _endCallFunc)
    else
        if _endCallFunc then
            _endCallFunc()
        end
    end
end

function CodeGameScreenCactusMariachiMachine:MachineRule_respinTouchSpinBntCallBack()
    if globalData.slotRunData.gameSpinStage == IDLE and globalData.slotRunData.currSpinMode == RESPIN_MODE then 
        -- 处于等待中， 并且free spin 那么提前结束倒计时开始执行spin

        release_print("STR_TOUCH_SPIN_BTN 触发了 free mode")
        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
        release_print("btnTouchEnd 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
    else
        if self.m_bIsAuto == false then
            release_print("STR_TOUCH_SPIN_BTN 触发了 normal")
            gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
            release_print("btnTouchEnd m_bIsAuto == false 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
        end
    end 

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN  then  -- 表明滚动了起来。。
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP)
    end
end

function CodeGameScreenCactusMariachiMachine:showSuperFreeGame(_m_runSpinResultData, _tblSuperFreeList)
    self.m_bInSuperFreeSpin = true
    self.tblSuperFreeList = {}
    self.tblSuperFreeList = _tblSuperFreeList
    self:addSuperGameData(_m_runSpinResultData)
    self:setFigureSpineVisible(false)
    self:initSuperFreePlayState()
    self:notifyClearBottomWinCoin()
end

function CodeGameScreenCactusMariachiMachine:initSuperFreePlayState()
    local tblIdleName = {"idlehong", "idlezi", "idlelan", "idlelv"}
    for i=1, 4 do
        util_spinePlay(self.m_allFigureSpine[i],"zhujiemian_idle2",true)
        self.m_topNameSuperAni[i]:setVisible(false)
        if self.tblSuperFreeList[i] == 1 then
            self.m_allFigureSpine[i]:setVisible(true)
            local isRun, namePos = self:getCurSuperTopNamePos(i)
            local index = self:getCurSuperTopNodeIndex()
            if isRun then
                self.m_topNameSuperNode[namePos]:setPosition(self.topPlayPos[index][namePos])
                self.m_topNameSuperAni[namePos]:setVisible(true)
                self.m_topNameSuperAni[namePos]:runCsbAction(tblIdleName[i], true)
            end
        end
    end
end

function CodeGameScreenCactusMariachiMachine:playSuperFreeTopNameAni(_index, _callFunc)
    local tblAppearName = {"fangdahong", "fangdazi", "fangdalan", "fangdalv"}
    local tblIdleName = {"idlehong", "idlezi", "idlelan", "idlelv"}
    local isRun, namePos = self:getCurSuperTopNamePos(_index)
    --小块锁定动画比较特殊
    if isRun then
        if _index == 1 then
            self.m_topNameSuperAni[namePos]:runCsbAction(tblAppearName[_index], false, function()
                self.m_topNameSuperAni[namePos]:runCsbAction("idlehong1", true)
                if _callFunc then
                    _callFunc()
                end
            end)
        else
            self.m_topNameSuperAni[namePos]:runCsbAction(tblAppearName[_index], false, function()
                self.m_topNameSuperAni[namePos]:runCsbAction(tblIdleName[_index], true)
                if _callFunc then
                    local topNamaWorldPos = util_convertToNodeSpace(self.m_topNameSuperNode[_index], self)
                    _callFunc(topNamaWorldPos)
                end
            end)
        end
    else
        if _callFunc then
            _callFunc()
        end
    end
end

function CodeGameScreenCactusMariachiMachine:closeLockPlayTopNameAni(_index, _endCallFunc)
    local isRun, namePos = self:getCurSuperTopNamePos(_index)
    if isRun then
        self.m_topNameSuperAni[namePos]:runCsbAction("suoxiaohong", false, function()
            self.m_topNameSuperAni[namePos]:runCsbAction("idlehong", true)
            if _endCallFunc then
                _endCallFunc()
            end
        end)
    else
        if _endCallFunc then
            _endCallFunc()
        end
    end
end

function CodeGameScreenCactusMariachiMachine:getCurSuperTopNamePos(_nameIndex)
    local pos = 0
    local isRun = false
    for i=1, _nameIndex do
        if self.tblSuperFreeList[i] == 1 then
            pos = pos + 1
            isRun = true
        end
    end
    return isRun, pos
end

function CodeGameScreenCactusMariachiMachine:getCurSuperTopNodeIndex()
    local index = 0
    for i=1, 4 do
        if self.tblSuperFreeList[i] == 1 then
            index = index + 1
        end
    end
    return index
end

function CodeGameScreenCactusMariachiMachine:addSuperGameData(_m_runSpinResultData)

    self.m_runSpinResultData.p_freeSpinsTotalCount = _m_runSpinResultData.freespin.freeSpinsTotalCount
    self.m_runSpinResultData.p_freeSpinsLeftCount = _m_runSpinResultData.freespin.freeSpinsLeftCount
    self.m_runSpinResultData.p_freeSpinNewCount = _m_runSpinResultData.freespin.freeSpinNewCount
    self.m_runSpinResultData.p_fsWinCoins = _m_runSpinResultData.freespin.fsWinCoins
    self.m_runSpinResultData.p_freeSpinAddList = _m_runSpinResultData.freespin.freeSpinAddList
    self.m_runSpinResultData.p_newTrigger = _m_runSpinResultData.freespin.newTrigger
    self.m_runSpinResultData.p_fsExtraData = _m_runSpinResultData.freespin.extra

    -- 添加superfreespin effect
    local freeSpinEffect = GameEffectData.new()
    freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
    freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

    self:playGameEffect()
end

function CodeGameScreenCactusMariachiMachine:setTopEffectNodeOpacity()
    for k, effectNode in pairs(self.topLockEffectNodeList) do
        if #effectNode > 0 then
            for i=1, 15 do
                local effectNode = self.topLockEffectNodeList[k][i]
                if not tolua.isnull(effectNode) then
                    effectNode:runCsbAction("xiaoshi", false, function()
                        self.topLockEffectNodeList[k][i] = nil
                    end)
                end
            end
        end
    end
end

function CodeGameScreenCactusMariachiMachine:showEffect_LineFrame(effectData)
    self:removeBaseEffect()
    return CodeGameScreenCactusMariachiMachine.super.showEffect_LineFrame(self, effectData)
end

function CodeGameScreenCactusMariachiMachine:removeBaseEffect(_endCallFunc)
    if self.m_nodeMask:isVisible() or self.m_bInSuperFreeSpin then
        self.m_topEffectNode:removeAllChildren()
        self.m_bottomEffectNode:removeAllChildren()
        for i=1, 15 do
            self.topSymbolNodeList[i]:setVisible(false)
            local fixPos = self:getRowAndColByPos(i-1)
            local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG) 
            if not symbolNode:isVisible() then
                symbolNode:setVisible(true)
            end
        end
        self:playLightOver()
    end
    if self.m_nodeMask:isVisible() then
        self.m_figureSpine_mask:runCsbAction("over", false, function()
            self.m_nodeMask:setVisible(false)
            if _endCallFunc then
                _endCallFunc()
            end
        end)

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self:addTopAniEffect()
        end
    end
end

function CodeGameScreenCactusMariachiMachine:playLightOver()
    local isRun = false
    local lightIndex = 1
    for i=4, 1, -1 do
        if self.tblPlayData[i] then
            isRun = true
            lightIndex = i
            break
        end
    end
    
    local tblLightOutName = {"zhaomingdeng_out_hong", "zhaomingdeng_out_zi", "zhaomingdeng_out_lan", "zhaomingdeng_out_lv"}
    if isRun then
        self:findChild("QiPan"):setLocalZOrder(-2)
        self.m_nodeFigureRoot:setLocalZOrder(-1)
        util_spinePlay(self.m_lightSpine, tblLightOutName[lightIndex], false)
        performWithDelay(self.m_scWaitNode, function()
            self.m_lightSpine:setVisible(false)
        end, 15/30)
    end
end

function CodeGameScreenCactusMariachiMachine:getCurMusicNameShow()
    local tblAllSuperFreeList = self.m_shopView:getAllSuperFreeList()
    for index, superFreeData in pairs(tblAllSuperFreeList) do
        local totalSure = 0
        for k, v in pairs(superFreeData) do
            if v == self.tblSuperFreeList[k] then
                totalSure = totalSure + 1
            end 
        end
        if totalSure == 4 then
            return index
        end
    end
end

function CodeGameScreenCactusMariachiMachine:showSuperFreeSpinStart(_spinNum, _func)
    local ownerlist={}
    ownerlist["m_lb_num"] = _spinNum
    local view = self:showDialog("SuperFreeSpinStart",ownerlist, _func)
    local index = self:getCurMusicNameShow()
    for i=1, 4 do
        if i == index then
            view:findChild("SFG_"..i):setVisible(true)
        else
            view:findChild("SFG_"..i):setVisible(false)
        end
    end

    return view
end

function CodeGameScreenCactusMariachiMachine:showSuperFreeSpinOver(_spinNum,_coins,func)
    local ownerlist={}
    ownerlist["m_lb_coins"] = _coins
    ownerlist["m_lb_num"] = _spinNum
    local view = self:showDialog("SuperFreeSpinOver",ownerlist,func)

    return view
end

-- 显示free spin
function CodeGameScreenCactusMariachiMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    self:clearCurMusicBg()

    local waitTime = 0
    if not self.m_bInSuperFreeSpin then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                        local parent = slotNode:getParent()
                        if parent ~= self.m_clipParent then
                            slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                        end
                        slotNode:runAnim("actionframe")
                        local duration = slotNode:getAniamDurationByName("actionframe")
                        waitTime = util_max(waitTime,duration)
                    end
                end
            end
        end
    end
    self:playScatterTipMusicEffect()

    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    
    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenCactusMariachiMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar or not self.m_baseSuperFreeSpinBar then
        return
    end
    if self.m_bInSuperFreeSpin then
        self.m_baseSuperFreeSpinBar:setVisible(true)
    else
        self.m_baseFreeSpinBar:setVisible(true)
    end
end

function CodeGameScreenCactusMariachiMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar or not self.m_baseSuperFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    util_setCsbVisible(self.m_baseSuperFreeSpinBar, false)
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenCactusMariachiMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_custom_enter_fs.mp3")

    local triggerSuperFree = self.m_bInSuperFreeSpin == true
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            local freeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            --superFreeGame
            if triggerSuperFree then
                self.m_baseSuperFreeSpinBar:setVisible(true)
                self.m_baseSuperFreeSpinBar:changeFreeSpinByCount()
                self:changeBgSpine(3)
                gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_sFgBgStart.mp3")
                local view = self:showSuperFreeSpinStart(freeSpinCount, function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
                self:addLeftAndRightSpine(view)
                self:setShopBtnAndPlayBgState(true)
            else
                local endCallFunc = function()
                    self.m_baseFreeSpinBar:setVisible(true)
                    self.m_baseFreeSpinBar:changeFreeSpinByCount()
                    self:changeBgSpine(2)
                    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_fgBgStart.mp3")
                    local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                        self:triggerFreeSpinCallFun()
                        self:resetMusicBg()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                    self:addLeftAndRightSpine(view)
                end
                self:addFreeSpinSpine(endCallFunc)
            end
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenCactusMariachiMachine:setShopBtnAndPlayBgState(_state)
    self.m_playBg:setVisible(_state)
    self.m_shopBtn:setVisible(not _state)
end

function CodeGameScreenCactusMariachiMachine:addLeftAndRightSpine(_view)
    local leftShopSpine = util_spineCreate("CactusMariachi_ShopEntrance",true,true)
    util_spinePlay(leftShopSpine,"idleframe",true)

    local rightShopSpine= util_spineCreate("CactusMariachi_ShopEntrance",true,true)
    util_spinePlay(rightShopSpine,"idleframe",true)

    _view:findChild("zuoyinxiang"):addChild(leftShopSpine)
    _view:findChild("youyinxiang"):addChild(rightShopSpine)
end

function CodeGameScreenCactusMariachiMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_over_fs.mp3")
   local triggerSuperFree = self.m_bInSuperFreeSpin == true
   self.m_bInSuperFreeSpin = false
   local strCoins     = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
   local fsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount

    if triggerSuperFree then
        self:changeBgSpine(1)
        globalMachineController:playBgmAndResume("CactusMariachiSounds/music_CactusMariachi_sFgBgOver.mp3", 2, 0, 1)
        local view = self:showSuperFreeSpinOver(fsTotalCount, strCoins,function()
            self:triggerFreeSpinOverCallFun()
            self:addTopAniEffect()
            self:openShopAddEffect()
        end)
        self:addLeftAndRightSpine(view)
        self:setShopBtnAndPlayBgState(false)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.9,sy=0.9},683)
    else
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        self:changeBgSpine(1)
        local randomIndex = math.random(1, 2)
        local delayTime = randomIndex + 1
        globalMachineController:playBgmAndResume("CactusMariachiSounds/music_CactusMariachi_fgBgOver_"..randomIndex..".mp3", delayTime, 0, 1)
        local view = self:showFreeSpinOver( strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:triggerFreeSpinOverCallFun()
            self:addTopAniEffect()
        end)
        self:addLeftAndRightSpine(view)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.9,sy=0.9},683)
    end
end

--freeGame-out
function CodeGameScreenCactusMariachiMachine:addFreeSpinSpine(_callFunc)
    local tblActionList = {}

    local function outFunc()
        for i=1, 4 do
            util_spinePlay(self.m_allFigureSpine[i] ,"out",false)
        end
        gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_baseAllFigureTopOut.mp3")
    end
    local function endCallFunc()
        if _callFunc then
            _callFunc()
        end
    end

    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        outFunc()
    end)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(30/30)

    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        endCallFunc()
    end)

    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

function CodeGameScreenCactusMariachiMachine:setFigureSpineVisible(_isShow)
    for i=1, 4 do
        self.m_allFigureSpine[i]:setVisible(_isShow)
    end
end

---
-- 点击快速停止reel
--
function CodeGameScreenCactusMariachiMachine:quicklyStopReel(colIndex)
    if self.netWorkFunc then
        self:isClickQuickReel()
    end
    CodeGameScreenCactusMariachiMachine.super.quicklyStopReel(self, colIndex)
end

function CodeGameScreenCactusMariachiMachine:isClickQuickReel(_isStart)
    -- 首次进入
    if _isStart then
        -- 打开stop按钮的点击状态 
        -- 修改的状态取自 SpinBtn:btnStopTouchEnd() 内判断的状态数据
        self.m_bottomUI.m_spinBtn.m_btnStopTouch = false
        globalData.slotRunData.gameSpinStage = GAME_MODE_ONE_RUN
        globalData.slotRunData.isClickQucikStop = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true}) 
    -- 后续触发了快停 直接跳出
    else
        self:playFigureAniOver()
    end
end

function CodeGameScreenCactusMariachiMachine:playFigureAniOver()
    self.m_scWaitNodeFigure:stopAllActions()
    self.m_audienceSpine:setVisible(false)
    self.m_nodeMask:setVisible(true)
    self.m_figureSpine_mask:runCsbAction("idle", true)
    self.m_lightSpine:setVisible(true)
    self:setFigureSpineVisible(false)

    for index=1, 4 do
        local isPlayLight = false
        local curTypeIsHave = self.tblPlayData[index]
        if curTypeIsHave then
            local tblIdleName = {"idlehong", "idlezi", "idlelan", "idlelv"}
            local isRun, namePos = self:getCurTopNamePos(index)
            self.m_topNameAni[namePos]:runCsbAction(tblIdleName[index], true)
            if not isPlayLight then
                self:playEndLight(index)
            end
        end
    end

    --音效停止
    if self.tblStopAllEffect and #self.tblStopAllEffect > 0 then
        for k, effectId in pairs(self.tblStopAllEffect)do
            gLobalSoundManager:stopAudio(effectId)
        end
        self.tblStopAllEffect = {}
    end

    if self.netWorkFunc then
        self.netWorkFunc()
        self.netWorkFunc = nil
    end
end

function CodeGameScreenCactusMariachiMachine:updateNetWorkData()
    local callFunc = function()
        CodeGameScreenCactusMariachiMachine.super.updateNetWorkData(self)
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    local isPlay = false
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        self.tblPlayData = {}
        if selfData and selfData.type then
            for k, v in pairs(selfData.type) do
                if v == 1 then
                    self.tblPlayData[k] = true
                    isPlay = true
                end
            end
        end
    end

    if isPlay and not self.m_bInSuperFreeSpin then
        self.m_scWaitNodeFigureOut:stopAllActions()
        self.netWorkFunc = callFunc
        self:playFigureAniStart()
        self:isClickQuickReel(true)
    else
        callFunc()
    end
end

--添加中奖动画
function CodeGameScreenCactusMariachiMachine:playFigureAniStart()
    local tblActionList = {}
    local tblOutActionList = {}
    self.tblStopAllEffect = {}

    local function startPlayOutFunc()
        self.m_nodeGuoChang:setVisible(true)
        self:setFigureSpineVisible(false)
        for i=1, 4 do
            util_spinePlay(self.m_allGuoChangSpine[i] ,"out",false)
        end
        gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_baseAllFigureTopOut.mp3")
    end

    local function figureSpineOver()
        self.m_nodeGuoChang:setVisible(false)
    end
    
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        tblOutActionList[#tblOutActionList + 1] = cc.CallFunc:create(function()
            startPlayOutFunc()
        end)
        tblOutActionList[#tblOutActionList + 1] = cc.DelayTime:create(30/30)
        tblOutActionList[#tblOutActionList + 1] = cc.CallFunc:create(function()
            figureSpineOver()
        end)
    end

    local function startPlayMaskFunc()
        self:setFigureSpineVisible(false)
        self.m_nodeFigureRoot:setLocalZOrder(10)
        self.m_lightSpine:setVisible(true)
        self.m_nodeMask:setVisible(true)
        self.m_figureSpine_mask:runCsbAction("start", false, function()
            self.m_figureSpine_mask:runCsbAction("idle", true)
        end)
    end

    local function enterAndLightFunc()
        self:setFigureSpineVisible(true)
        self.m_audienceSpine:setVisible(true)
        util_spinePlay(self.m_lightSpine,"wutai_deng_in",false)
        util_spinePlay(self.m_audienceSpine,"wutai_guanzhong_in",false)
        for i=1, 4 do
            self:setFigureSpineVisible(true)
            util_spinePlay(self.m_allFigureSpine[i] ,"wutai_guanzhong_in",false)
        end
        local randomIndex = math.random(1, 2)
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self.tblStopAllEffect[#self.tblStopAllEffect + 1] = gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_fgShowTime_"..randomIndex..".mp3")
        else
            self.tblStopAllEffect[#self.tblStopAllEffect + 1] = gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_showTime_"..randomIndex..".mp3")
        end
    end

    local function figureWaitFunc()
        for i=1, 4 do
            util_spinePlay(self.m_allFigureSpine[i] ,"wutaishow", true)
        end
        util_spinePlay(self.m_audienceSpine,"wutai_guanzonghuanhu",true)
    end

    local function playLightAniFunc()
        util_spinePlay(self.m_lightSpine,"wutaishow_deng_hong-zi-lan-lv",true)
    end

    --锁定人物光
    local tblLockAniName = {"suodinghong", "suodingfen", "suodinglan", "suodinglv"}
    local function lockLightFunc(_playType)
        self.m_allFigureLockAni[_playType]:setVisible(true)
        self.m_allFigureLockAni[_playType]:runCsbAction(tblLockAniName[_playType],false, function()
            self.m_allFigureLockAni[_playType]:setVisible(false)
        end)
    end
 
     --未触发玩法
    local function playOutAniFunc(_playType)
        gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_figureOut.mp3")
        util_spinePlay(self.m_allFigureSpine[_playType] ,"wutai_out", false)
    end

    --触发玩法(第一个和后边三个角色不同)
    local tblLightName = {"wutaishow_deng_hong", "wutaishow_deng_zi", "wutaishow_deng_lan", "wutaishow_deng_lv"}
    local tblCatLightName = {"wutaishow_deng_hong2", "wutaishow_deng_zi2", "wutaishow_deng_lan2", "wutaishow_deng_lv2"}
    local function triggerPlayFunc_1(_playType)
        util_spinePlay(self.m_allFigureSpine[_playType] ,"wutaishow_end", false)
        util_spinePlay(self.m_lightSpine,tblLightName[_playType],true)
        self.tblStopAllEffect[#self.tblStopAllEffect + 1] = gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_baseFigureOut_".._playType..".mp3")
    end

    local function triggerPlayFunc_other(_playType)
        if _playType <= 4 then
            util_spinePlay(self.m_allFigureSpine[_playType] ,"wutaishow_end", false)
            util_spinePlay(self.m_lightSpine,tblCatLightName[_playType-1],false)
            self.tblStopAllEffect[#self.tblStopAllEffect + 1] = gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_baseFigureOut_".._playType..".mp3")
        end
    end
    local function triggerPlayFunc_other_1(_playType)
        if _playType <= 4 then
            util_spinePlay(self.m_lightSpine,tblLightName[_playType],true)
        else
            util_spinePlay(self.m_lightSpine,tblLightName[4],true)
        end
        
        local index = _playType-1
        local curTypeIsHave = self.tblPlayData[index]
        if curTypeIsHave then
            lockLightFunc(index)
            self:addTopPlayName(index)
        else
            playOutAniFunc(index)
        end
    end

    --角色和观众全部移除
    local function allPlayOutFunc()
        for i=1, 4 do
            if self.tblPlayData[i] then
                util_spinePlay(self.m_allFigureSpine[i] ,"wutai_out", false)
            end
        end
        util_spinePlay(self.m_audienceSpine,"wutai_guanzhong_out",false)
        gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_baseAllFigureOut.mp3")
    end

    local function endCallFunc()
        self:setFigureSpineVisible(false)
        self.m_audienceSpine:setVisible(false)
        if self.netWorkFunc then
            self.netWorkFunc()
            self.netWorkFunc = nil
        end
    end
    
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(30/30)
    end
    
    --黑幕和聚光灯出现
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        startPlayMaskFunc()
    end)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        enterAndLightFunc()
    end)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(30/30)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        figureWaitFunc()
    end)

    --添加灯光
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        playLightAniFunc()
    end)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(60/30)

    --添加玩法
    for i=1, 5 do
        local curTypeIsHave = self.tblPlayData[i]
        if i == 1 then
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                triggerPlayFunc_1(i)
            end)
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(60/30)
        else
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                triggerPlayFunc_other(i)
            end)
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(10/30)
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                triggerPlayFunc_other_1(i)
            end)
            if i < 5 then
                tblActionList[#tblActionList + 1] = cc.DelayTime:create(50/30)
            end
        end
    end

    --全部定住
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(1.0)

    --全部离场
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        allPlayOutFunc()
    end)

    --添加灯光
    -- tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
    --     playLightAniFunc()
    -- end)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(30/30)

    --最后
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        endCallFunc()
    end)

    self.m_scWaitNodeFigure:runAction(cc.Sequence:create(tblActionList))
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.m_scWaitNodeFigureOut:runAction(cc.Sequence:create(tblOutActionList))
    end
end

--添加顶部玩法文本
function CodeGameScreenCactusMariachiMachine:addTopPlayName(_nameIndex)
    local tblAppearName = {"chuxianhong", "chuxianzi", "chuxianlan", "chuxianlv"}
    local tblIdleName = {"idlehong", "idlezi", "idlelan", "idlelv"}

    local isRun, namePos = self:getCurTopNamePos(_nameIndex)
    if isRun then
        self:playBaseAniEffect(_nameIndex)
        self.m_topNameAni[namePos]:runCsbAction(tblAppearName[_nameIndex], false, function()
            self.m_topNameAni[namePos]:runCsbAction(tblIdleName[_nameIndex], true)
        end)
    end
end

function CodeGameScreenCactusMariachiMachine:playBaseAniEffect(_index)
    local tblAniEffectName = {
        "music_CactusMariachi_winningRespin_",
        "music_CactusMariachi_symbolUpgrade_",
        "music_CactusMariachi_randomWild_",
        "music_CactusMariachi_multiplier_",
    }
    local randomIndex = math.random(1, 3)
    gLobalSoundManager:playSound("CactusMariachiSounds/"..tblAniEffectName[_index]..randomIndex..".mp3")
end

function CodeGameScreenCactusMariachiMachine:playEndLight(_index)
    local tblEndLight = {"wutaishow_deng_hong", "wutaishow_deng_zi", "wutaishow_deng_lan", "wutaishow_deng_lv"}
    util_spinePlay(self.m_lightSpine,tblEndLight[_index],true)
end

--获取当前name的位置(位置从上向下)
function CodeGameScreenCactusMariachiMachine:getCurTopNamePos(_nameIndex)
    local pos = 0
    local isRun = false
    for i=1, _nameIndex do
        isRun = false
        if self.tblPlayData[i] then
            pos = pos + 1
            isRun = true
        end
    end
    return isRun, pos
end

function CodeGameScreenCactusMariachiMachine:playEndTopNameAni(_index, _callFunc)
    local callFunc = _callFunc
    local tblAppearName = {"fangdahong", "fangdazi", "fangdalan", "fangdalv"}
    local isRun, namePos = self:getCurTopNamePos(_index)
    if isRun then
        self.m_topNameAni[namePos]:runCsbAction(tblAppearName[_index], false, function()
            self:playEndNameAni(_index, callFunc)
        end)
    else
        if callFunc then
            callFunc()
            callFunc = nil
        end
    end
end

function CodeGameScreenCactusMariachiMachine:playEndNameAni(_index, _callFunc)
    local callFunc = _callFunc
    local tblAppearName = {"xiaoshihong", "xiaoshizi", "xiaoshilan", "xiaoshilv"}
    local isRun, namePos = self:getCurTopNamePos(_index)
    if isRun then
        self.m_topNameAni[namePos]:runCsbAction(tblAppearName[_index], false, function()
            if callFunc then
                local topNamaWorldPos = util_convertToNodeSpace(self.m_topNameNode[namePos], self)
                callFunc(topNamaWorldPos)
                callFunc = nil
            end
        end)
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCactusMariachiMachine:MachineRule_SpinBtnCall()

    self:setMaxMusicBGVolume( )
   



    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCactusMariachiMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if selfData and selfData.score then
            local scoreList = selfData.score
            local effectData = GameEffectData.new()
            effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
            effectData.p_effectOrder    = self.EFFECT_COLLECT_ICON
            effectData.p_selfEffectType = self.EFFECT_COLLECT_ICON
            self.m_gameEffects[#self.m_gameEffects + 1] = effectData
        end
    end

    local m_isReset = false
    if selfData and selfData.type then
        local baseType_2 = selfData.type[2]
        if baseType_2 == 1 then
            table.insert(self.m_selfPlayData, 2)
            self.m_selfMakeData = clone(selfData)
            if not self:checkIsFreeSpin() then
                m_isReset = true
                self:addChangeSymbolPlay()
            end
        end
    end

    if selfData and selfData.type then
        local baseType_3 = selfData.type[3]
        if baseType_3 == 1 then
            table.insert(self.m_selfPlayData, 3)
            self.m_selfMakeData = clone(selfData)
            if not self:checkIsFreeSpin() then
                m_isReset = true
                self:addWildPlsy()
            end
            
        end
    end

    if selfData and selfData.type then
        local baseType_4 = selfData.type[4]
        if baseType_4 == 1 then
            table.insert(self.m_selfPlayData, 4)
            self.m_selfMakeData = clone(selfData)
            if not self:checkIsFreeSpin() then
                m_isReset = true
                self:addWinLinePlay()
            end
        end
    end


    if m_isReset then
        self:resetData()
    end
end

-- superGame结束后打开商店事件
function CodeGameScreenCactusMariachiMachine:openShopAddEffect()
    local effectData = GameEffectData.new()
    effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
    effectData.p_effectOrder    = self.EFFECT_OPEN_SHOP
    effectData.p_selfEffectType = self.EFFECT_OPEN_SHOP
    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
end

-- 动画移动到上边
function CodeGameScreenCactusMariachiMachine:addTopAniEffect()
    local effectData = GameEffectData.new()
    effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
    effectData.p_effectOrder    = self.EFFECT_PLAY_TOP_ANI
    effectData.p_selfEffectType = self.EFFECT_PLAY_TOP_ANI
    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
end

-- 检查是否有basePlay1
function CodeGameScreenCactusMariachiMachine:checkIsFreeSpin()
    if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return true
    end
    return false
end

function CodeGameScreenCactusMariachiMachine:addNewLockSymbolPlay()
    local effectData = GameEffectData.new()
    effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
    effectData.p_effectOrder    = self.EFFECT_LOCK_NEW_SYMBOL
    effectData.p_selfEffectType = self.EFFECT_LOCK_NEW_SYMBOL
    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
end

function CodeGameScreenCactusMariachiMachine:addChangeSymbolPlay()
    local effectData = GameEffectData.new()
    effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
    effectData.p_effectOrder    = self.EFFECT_CHANGE_SYMBOL
    effectData.p_selfEffectType = self.EFFECT_CHANGE_SYMBOL
    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
end

function CodeGameScreenCactusMariachiMachine:addWildPlsy()
    local effectData = GameEffectData.new()
    effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
    effectData.p_effectOrder    = self.EFFECT_ADD_WILD
    effectData.p_selfEffectType = self.EFFECT_ADD_WILD
    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
end

function CodeGameScreenCactusMariachiMachine:addWinLinePlay()
    local effectData = GameEffectData.new()
    effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
    effectData.p_effectOrder    = self.EFFECT_WIN_LINE
    effectData.p_selfEffectType = self.EFFECT_WIN_LINE
    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCactusMariachiMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_COLLECT_ICON then
        self:playCollectIcon(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_LOCK_NEW_SYMBOL then
        self:lockIcon(effectData, true)
    elseif effectData.p_selfEffectType == self.EFFECT_CHANGE_SYMBOL then
        self:playChangeSymbol(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_ADD_WILD then
        self:playAddWild(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_WIN_LINE then
        self:playWinLine(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_PLAY_TOP_ANI then
        self:playTopInAni(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_OPEN_SHOP then
        effectData.p_isPlay = true
        self:playGameEffect()
        self:showShopView(true)
    end
    return true
end

function CodeGameScreenCactusMariachiMachine:addLockSpine(_symbolNode, _pos, _changeType, _isLast, _isChangeSymbol)
    local lockSpine = util_createAnimation("CactusMariachi_suoding.csb")
    local nodePos = self:getTopSymbolPos(_pos)
    lockSpine:setPosition(nodePos)
    self.m_topEffectNode:addChild(lockSpine)
    
    lockSpine:runCsbAction("suo", false, function()
        lockSpine:removeFromParent()
    end)

    local topSymbolNode = self.topSymbolNodeList[_pos+1]
    if _changeType == TAG_SYMBOL_TYPE.SYMBOL_WILD and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        topSymbolNode:changeSymbolCcb(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        topSymbolNode:runAnim("idleframe", false)
    else
        topSymbolNode:changeSymbolCcb(_symbolNode.p_symbolType)
    end
    topSymbolNode:setVisible(true)
    performWithDelay(lockSpine, function()
        _symbolNode:setVisible(false)
        local effectName
        if _isChangeSymbol then
            effectName = "CactusMariachiSounds/music_CactusMariachi_symbolUpgradeChange.mp3"
        else
            effectName = "CactusMariachiSounds/music_CactusMariachi_randomWildChange.mp3"
        end
        if _isLast then
            gLobalSoundManager:playSound(effectName)
        end
        if _changeType == TAG_SYMBOL_TYPE.SYMBOL_WILD and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local ccbName = self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            _symbolNode:changeCCBByName(ccbName, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            topSymbolNode:runAnim("bian", false, function()
                topSymbolNode:runAnim("idleframe3", false)
                _symbolNode:runAnim("idleframe3", false)
                _symbolNode:setLineAnimName("actionframe2")
                _symbolNode:setIdleAnimName("idleframe3")
            end)
        else
            topSymbolNode:changeSymbolCcb(_changeType)
            local ccbName = self:getSymbolCCBNameByType(self, _changeType)
            _symbolNode:changeCCBByName(ccbName, _changeType)
            topSymbolNode:runAnim("bian", false)
        end
    end, 36/60)
end

function CodeGameScreenCactusMariachiMachine:playChangeSymbol(_effectData)
    self:setTopEffectNodeOpacity()
    local selfData = self.m_selfMakeData or {}
    local changeSymbolData = selfData.changeSignal

    local changeSymbolList = changeSymbolData[1]
    local changeType = changeSymbolData[2]
    local totalNum = #changeSymbolList
    for k,v in pairs(changeSymbolList) do
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos) 
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        local isLast = k == totalNum and true or false
        if symbolNode then
            self:addLockSpine(symbolNode, pos, changeType, isLast, true)
        end
    end

    local callFunc = function()
        performWithDelay(self.m_scWaitNode, function()
            if _effectData then
                _effectData.p_isPlay = true
                self:playGameEffect()
            end
        end, 0.5)
    end
    if self.m_bInSuperFreeSpin then
        self:playSuperFreeTopNameAni(2, callFunc)
    else
        self:playEndLight(2)
        self:playEndTopNameAni(2)
        performWithDelay(self,function()
            if callFunc then
                callFunc()
            end
        end,83/60)
    end
end

function CodeGameScreenCactusMariachiMachine:playAddWild(_effectData)
    self:setTopEffectNodeOpacity()
    local selfData = self.m_selfMakeData or {}
    local wildPos = selfData.wildPos

    local totalNum = #wildPos
    for k,v in pairs(wildPos) do
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        local isLast = k == totalNum and true or false
        if symbolNode then
            self:addLockSpine(symbolNode, pos, TAG_SYMBOL_TYPE.SYMBOL_WILD, isLast)
        end
    end

    local callFunc = function()
        performWithDelay(self.m_scWaitNode, function()
            if _effectData then
                _effectData.p_isPlay = true
                self:playGameEffect()
            end
        end, 0.5)
    end

    if self.m_bInSuperFreeSpin then
        self:playSuperFreeTopNameAni(3, callFunc)
    else
        self:playEndLight(3)
        self:playEndTopNameAni(3)
        performWithDelay(self,function()
            if callFunc then
                callFunc()
            end
        end,83/60)
    end
end

function CodeGameScreenCactusMariachiMachine:playWinLine(_effectData)
    self:setTopEffectNodeOpacity()
    local selfData = self.m_selfMakeData or {}
    local mul = selfData.mul

    local endCallFunc = function(_topNamaWorldPos)
        local mulNodeFly = util_createAnimation("CactusMariachi_Multiplier.csb")
        local mulNodeEffect = util_createAnimation("CactusMariachi_Multiplier_1.csb")
        self.m_topMulNode:addChild(mulNodeEffect)
        mulNodeFly:findChild("m_lb_num"):setString(mul.."X")
        mulNodeFly:setPosition(_topNamaWorldPos)
        self:addChild(mulNodeFly, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
        local posX, posY = self.m_topMulNode:getPosition()
        local endPos = self:findChild("panel_topSymbol"):convertToWorldSpace(cc.p(posX, posY))

        local callFunc = function()
            performWithDelay(self.m_scWaitNode, function()
                if _effectData then
                    _effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end, 0.5)
        end

        gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMariachi_playMul.mp3")
        mulNodeFly:runCsbAction("chuxian",false, function ()
            performWithDelay(self.m_scWaitNode, function()
                util_playMoveToAction(mulNodeFly,20/60,endPos, nil, "easyInOut")
            end, 6/60)

            performWithDelay(self.m_scWaitNode, function()
                self:runCsbAction("zhen", false)
            end, 34/60)

            mulNodeEffect:runCsbAction("za", false, function()
                mulNodeEffect:removeFromParent()
            end)
            mulNodeFly:runCsbAction("za", false, function()
                if callFunc then
                    callFunc()
                end
                mulNodeFly:removeFromParent()
            end)
        end)
        
    end

    if self.m_bInSuperFreeSpin then
        self:playSuperFreeTopNameAni(4, endCallFunc)
    else
        self:playEndLight(4)
        self:playEndTopNameAni(4, endCallFunc)
    end
end

function CodeGameScreenCactusMariachiMachine:playCollectIcon(_effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local scoreList = selfData.score 
    local totalShopCoins = selfData.coins or 0

    local delayTime = 15/60
    local actionDelayTime = 20/60
    local m_scCount = 0

    if selfData and scoreList then
        local totalNum = self:getLastIndex(scoreList)
        for k, v in pairs(scoreList) do
            local score = tonumber(v)
            if score > 0 then
                local pos = k-1
                m_scCount = m_scCount + 1
                local fixPos = self:getRowAndColByPos(pos)
                local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if symbolNode then
                    self:removeSymbolCollectIcon(symbolNode)
                end

                local clipTarPos = util_getOneGameReelsTarSpPos(self, pos)
                -- local startPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
                local endPos = util_convertToNodeSpace(self.m_shopCoins:findChild("jinbi"), self.m_nodeCollect)
                local iconNode = util_createAnimation("CactusMariachi_jiaobiao.csb")
                self.m_nodeCollect:addChild(iconNode)
                iconNode:setPosition(clipTarPos.x + 70, clipTarPos.y - 42)

                local particle = iconNode:findChild("Particle_1")
                if particle then
                    particle:setPositionType(0)
                    particle:setDuration(-1)
                    particle:resetSystem()
                end

                local lab = iconNode:findChild("m_lb_num")
                if lab then
                    lab:setString(score)
                end

                iconNode:runCsbAction("fankui")
                if k == totalNum then
                    gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMarichi_Collect.mp3")
                end
                performWithDelay(iconNode, function()
                    util_playMoveToAction(iconNode,actionDelayTime,endPos,function()
                        if k == totalNum then
                            gLobalSoundManager:playSound("CactusMariachiSounds/music_CactusMarichi_Collect_FeedBack.mp3")
                        end
                        self:refreshShopCoins(totalShopCoins)
                        self.m_shopCoins:runCsbAction("fankui", false)
                        if particle then
                            particle:stopSystem()
                        end
                        iconNode:findChild("Node_bg"):setVisible(false)
                        performWithDelay(self.m_scWaitNode, function()
                            iconNode:removeFromParent()
                        end, 1.0)
                    end)
                end, delayTime)
            end
        end

        performWithDelay(self.m_scWaitNode,function(  )
            if _effectData then
                _effectData.p_isPlay = true
                self:playGameEffect()
            end
        end, 0)--delayTime+actionDelayTime)
    end
end

function CodeGameScreenCactusMariachiMachine:getLastIndex(_collectData)
    local collectData = _collectData
    local index = 0
    for index=15, 1, -1 do
        if collectData[index] > 0 then
            return index
        end
    end
end

function CodeGameScreenCactusMariachiMachine:playTopInAni(_effectData)
    local callFunc = function()
        if _effectData then
            _effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    for i=1, 4 do
        if not self.m_allFigureSpine[i]:isVisible() then 
            self.m_allFigureSpine[i]:setVisible(true)
            util_spinePlay(self.m_allFigureSpine[i],"in",false)
        end

        performWithDelay(self.m_scWaitNode, function()
            util_spinePlay(self.m_allFigureSpine[i],"zhujiemian_idle",true)
            if callFunc and i == 4 then
                callFunc()
            end
        end, 22/30)
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenCactusMariachiMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenCactusMariachiMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenCactusMariachiMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame()
end

function CodeGameScreenCactusMariachiMachine:removeSymbolCollectIcon(_symbolNode)
    local iconNode = _symbolNode:getChildByName("collectIcon")
    if iconNode then
        iconNode:removeFromParent()
    end
end

function CodeGameScreenCactusMariachiMachine:getHaveSymbol(_reelsIndex)
    local isHave = false
    local scoreNum = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.score then
        local scoreList = selfData.score
        scoreNum = scoreList[_reelsIndex+1]
        if scoreNum and scoreNum > 0 then
            isHave = true
        end
    end
    
    return isHave, scoreNum
end

function CodeGameScreenCactusMariachiMachine:createSymbolCollectIcon(_symbolNode)
    self:removeSymbolCollectIcon(_symbolNode)
    if self:getCurrSpinMode() == FREE_SPIN_MODE or (self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsTotalCount > 0) then
        return
    end

    local isLastSymbol = _symbolNode.m_isLastSymbol
    local symbolType = _symbolNode.p_symbolType
    if isLastSymbol then
        local row = _symbolNode.p_rowIndex
        local col = _symbolNode.p_cloumnIndex
        local reelsIndex = self:getPosReelIdx(row, col)
        local isHave, scoreNum = self:getHaveSymbol(reelsIndex)
        if _symbolNode and isHave then
            local nodeIcon = util_createAnimation("CactusMariachi_jiaobiao.csb")
            nodeIcon:setPosition(cc.p(70, -40))
            nodeIcon:setName("collectIcon")
            _symbolNode:addChild(nodeIcon, 100)

            local lab = nodeIcon:findChild("m_lb_num")
            if lab then
                lab:setString(scoreNum)
            end
        end
    end
end

function CodeGameScreenCactusMariachiMachine:updateReelGridNode(_symbolNode)

    if _symbolNode.p_symbolType then
        _symbolNode:setLineAnimName("actionframe")
        _symbolNode:setIdleAnimName( "idleframe" )
    end

    self:createSymbolCollectIcon(_symbolNode)

end

function CodeGameScreenCactusMariachiMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame()

    CodeGameScreenCactusMariachiMachine.super.slotReelDown(self)
end

function CodeGameScreenCactusMariachiMachine:addRespinOverSelfEffect()
    for i=#self.m_gameEffects ,1,-1 do
        local effect = self.m_gameEffects[i]
        if effect.p_effectType == GameEffect.EFFECT_RESPIN_OVER then
            effect.p_selfEffectType = GameEffect.EFFECT_RESPIN_OVER
            break
        end
    end
end

--添加Base1连线动画
function CodeGameScreenCactusMariachiMachine:addWinLineEffect()
    for i=#self.m_gameEffects ,1,-1 do
        local effect = self.m_gameEffects[i]
        if effect.p_selfEffectType == GameEffect.EFFECT_RESPIN_OVER or
            effect.p_selfEffectType == self.EFFECT_LOCK_NEW_SYMBOL or
                effect.p_selfEffectType == self.EFFECT_CHANGE_SYMBOL or
                    effect.p_selfEffectType == self.EFFECT_ADD_WILD or
                        effect.p_selfEffectType == self.EFFECT_WIN_LINE then

                            local effectData = GameEffectData.new()
                            effectData.p_effectType = GameEffect.EFFECT_LINE_FRAME
                            effectData.p_selfEffectType = GameEffect.EFFECT_LINE_FRAME
                            table.insert(self.m_gameEffects,i+1,effectData)
                    break
        end
    end 
end
-- 添加连线动画
function CodeGameScreenCactusMariachiMachine:addLineEffect()
    CodeGameScreenCactusMariachiMachine.super.addLineEffect(self)
    if self:getCurrSpinMode() == RESPIN_MODE then
        for i=#self.m_gameEffects ,1,-1 do
            local effect = self.m_gameEffects[i]
            if effect.p_effectType == GameEffect.EFFECT_LINE_FRAME then
                table.remove(self.m_gameEffects, i)
                break
            end
        end
    end
end

function CodeGameScreenCactusMariachiMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()

    local isFiveOfKind = self:lineLogicWinLines()

    if isFiveOfKind and self:getCurrSpinMode() ~= RESPIN_MODE then
        self:addAnimationOrEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

    -- 根据features 添加具体玩法
    self:MachineRule_checkTriggerFeatures()
    self:staticsQuestEffect()
end

function CodeGameScreenCactusMariachiMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenCactusMariachiMachine:getCurBottomWinCoins()
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

--BottomUI接口
function CodeGameScreenCactusMariachiMachine:updateBottomUICoins( _beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound )
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenCactusMariachiMachine:playhBottomLight(_startCoins, _endCoins, _endCallFunc)
    self.m_bottomUI:playCoinWinEffectUI(_endCallFunc)

    --local bottomWinCoin = self:getCurBottomWinCoins()
    self:setLastWinCoin(_endCoins)
    self:updateBottomUICoins(_startCoins, _endCoins)
end

function CodeGameScreenCactusMariachiMachine:getBottomUi()
    return self.m_bottomUI
end

function CodeGameScreenCactusMariachiMachine:shopBtnIsCanClick()
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

function CodeGameScreenCactusMariachiMachine:getRespinRandomTypes()
    local symbolList = { 
        self.SYMBOL_SCORE_11,
        self.SYMBOL_SCORE_10,
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

function CodeGameScreenCactusMariachiMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling2", bRandom = true},
        {type = -self.SYMBOL_FIX_SYMBOL_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_FIX_MINOR_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_FIX_MINI, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling2", bRandom = true}


    }

    return symbolList
end

function CodeGameScreenCactusMariachiMachine:setGameEffectOrder()
    CodeGameScreenCactusMariachiMachine.super.setGameEffectOrder(self)

    if self.m_gameEffects == nil then
        return
    end

    local lenEffect = #self.m_gameEffects
    for i = 1, lenEffect, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == GameEffect.EFFECT_RESPIN then
            effectData.p_effectOrder = self.EFFECT_LOCK_SYMBOL
        end
    end
end
---
--判断改变freespin的状态
function CodeGameScreenCactusMariachiMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                local features = self.m_runSpinResultData.p_features or {}
                if features[2] ~= RESPIN_MODE  then ---没有respin才添加
                    self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
                end
            end
        end
    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
        end
    end
end

--如果有respin(base1)玩法，在respin结束之后再播放其他basePlay
function CodeGameScreenCactusMariachiMachine:checkAddBasePlayEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local newLockIcon = selfData.newIcon or {}
    if newLockIcon then
        self:addNewLockSymbolPlay()
    end
    for id, playType in pairs(self.m_selfPlayData) do
        if playType == 2 then
            self:addChangeSymbolPlay()
        elseif playType == 3 then
            self:addWildPlsy()
        elseif playType == 4 then
            self:addWinLinePlay()
        end
    end
    self:resetData()
end

-- 这个手动添加freeOverEffect  在respinOver时 
function CodeGameScreenCactusMariachiMachine:checkAddFreeOverEffect()
    
    if self.m_runSpinResultData.p_freeSpinsLeftCount ~= self.m_runSpinResultData.p_freeSpinsTotalCount
     and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_FREE_SPIN_OVER
        effectData.p_effectOrder    = GameEffect.EFFECT_FREE_SPIN_OVER
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
     end
end

function CodeGameScreenCactusMariachiMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin(  ) then

                self.m_topUI:updataPiggy(betCoin)
                isFreeSpin = false
    end
    
    self:updateJackpotList()
    
    self:setSpecialSpinStates(false )

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel,
        clickPos = self.m_shopView:getCurPlayMusicIndex()
    }
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenCactusMariachiMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
    end
end

function CodeGameScreenCactusMariachiMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenCactusMariachiMachine:symbolBulingEndCallBack(node)
    if node.p_symbolType and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
        node:runAnim("idleframe", true)
    end
end

function CodeGameScreenCactusMariachiMachine:playCurMusic(_musicIndex)
    local volumeRiseNum = 1 / 60
    local startVolume = 1
    if self.m_updateVolumeHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateVolumeHandlerID)
        self.m_updateVolumeHandlerID = nil
    end
    self.m_updateVolumeHandlerID = scheduler.scheduleUpdateGlobal(function()
        print("当前的音量为："..startVolume)
        startVolume = startVolume - volumeRiseNum
        if startVolume <= 0 then
            gLobalSoundManager:setBackgroundMusicVolume(0)
            self:resetMusicBg(nil, string.format(self.m_shopMusicName, _musicIndex))

            if self.m_updateVolumeHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateVolumeHandlerID)
                self.m_updateVolumeHandlerID = nil
            end
        else
            gLobalSoundManager:setBackgroundMusicVolume(startVolume)
        end
    end)
end

--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenCactusMariachiMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if self:getCurrSpinMode() == FREE_SPIN_MODE and not self.m_bInSuperFreeSpin then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self.m_bInSuperFreeSpin then
        self.m_currentMusicBgName = self:getCurBgMusic(true)
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    else
        self.m_currentMusicBgName = self:getCurBgMusic()
    end

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
    gLobalSoundManager:setBackgroundMusicVolume(1)
end

function CodeGameScreenCactusMariachiMachine:getCurBgMusic(_isSuperFree)
    local shopMusicIndex = self.m_shopView:getCurPlayMusicIndex()
    if _isSuperFree then
        shopMusicIndex = self:getCurMusicNameShow()
    end
    local musicName = string.format(self.m_shopMusicName, shopMusicIndex+1)
    return musicName
end

return CodeGameScreenCactusMariachiMachine






