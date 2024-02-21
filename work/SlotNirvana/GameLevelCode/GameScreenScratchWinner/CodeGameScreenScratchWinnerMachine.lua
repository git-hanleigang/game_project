---
-- island li
-- 2019年1月26日
-- CodeGameScreenScratchWinnerMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"
local ScratchWinnerMusicConfig = require "CodeScratchWinnerSrc.ScratchWinnerMusicConfig"
local CodeGameScreenScratchWinnerMachine = class("CodeGameScreenScratchWinnerMachine", BaseNewReelMachine)

CodeGameScreenScratchWinnerMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenScratchWinnerMachine.SYMBOL_Card1_Start   = 100      --卡1 起始
CodeGameScreenScratchWinnerMachine.SYMBOL_Card1_Jackpot = 199      --卡1 jackpot图标
CodeGameScreenScratchWinnerMachine.SYMBOL_Card2_Start   = 200      --卡2 起始
CodeGameScreenScratchWinnerMachine.SYMBOL_Card3_Start   = 300      --卡3 起始 并且也是卡3 jackpot图标
CodeGameScreenScratchWinnerMachine.SYMBOL_Card4_Start   = 400      --卡4


-- 构造函数
function CodeGameScreenScratchWinnerMachine:ctor()
    CodeGameScreenScratchWinnerMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true

    self.m_shopMag = ScratchWinnerShopManager:getInstance()
    self.m_shopMag:initMachine(self)
    self.m_shopMag:initData()
    --[[
        
        m_exportCardList = {
            "triple" = {spine1, spine2}
        }
    ]]    
    self.m_exportCardList = {}

    -- 新手引导进入关卡玩家的所有卡片默认卡片数量
    self.m_initCardNum = 1
    -- playgameEffect 被打断时注册的恢复函数
    self.m_ScreenScratchLevelResumeFunc = nil
    -- bigWin 被打断时注册的恢复函数
    self.m_ScreenScratchLevelResumeFunc_bigWin = nil
    --init
    self:initGame()
end

function CodeGameScreenScratchWinnerMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenScratchWinnerMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ScratchWinner"  
end


function CodeGameScreenScratchWinnerMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    -- 商店
    self.m_shopList = util_createView("CodeScratchWinnerSrc.ScratchWinnerShopListView", self)
    self:findChild("Node_shop"):addChild(self.m_shopList)  

    self.m_titlePos   = cc.p(self:findChild("Sprite_title"):getPosition())
    self.m_btnPlayPos = cc.p(self.m_shopList:findChild("Node_btn"):getPosition()) 
    -- 打印口
    -- self.m_exportAnim = util_createView("CodeScratchWinnerSrc.ScratchWinnerBonusExport", self)
    -- self:findChild("Node_export"):addChild(self.m_exportAnim)  
    -- self.m_exportAnim:setVisible(false)
end

--[[
    Ui控件
]]
function CodeGameScreenScratchWinnerMachine:changeBgShowState(_bBase,_playAnim)
    local animTime = 0

    local shopNode = self:findChild("Node_shop")
    local cardNode = self:findChild("Node_guaguaka")
    shopNode:stopAllActions()
    cardNode:stopAllActions()

    if _playAnim then
        if _bBase then
            shopNode:setVisible(_bBase) 
            self.m_shopList:playShowAnim()
            performWithDelay(cardNode,function()
                cardNode:setVisible(not _bBase)
            end, 0.5)

            animTime = 0.5
        else
            animTime = self.m_shopList:playHideAnim()
            performWithDelay(shopNode,function()
                shopNode:setVisible(_bBase)
            end, animTime)
            
            cardNode:setVisible(not _bBase)
        end
    else
        shopNode:setVisible(_bBase)
        cardNode:setVisible(not _bBase)
    end
    return animTime
end

function CodeGameScreenScratchWinnerMachine:playShopNodeMoveAction(_bBase)
    local title   = self:findChild("Sprite_title")
    local btnPlay = self.m_shopList:findChild("Node_btn")
    
    local actListTitle = {}
    local actListBtn = {}

    local moveTime = 0.5
    local distance = display.height/2
    if _bBase then
        table.insert(actListTitle, cc.MoveTo:create(moveTime, cc.p(self.m_titlePos.x, self.m_titlePos.y) ))
        table.insert(actListBtn, cc.MoveTo:create(moveTime, cc.p(self.m_btnPlayPos.x, self.m_btnPlayPos.y) ))
    else
        table.insert(actListTitle, cc.MoveTo:create(moveTime, cc.p(self.m_titlePos.x, self.m_titlePos.y+distance) ))
        table.insert(actListBtn, cc.MoveTo:create(moveTime, cc.p(self.m_btnPlayPos.x, self.m_btnPlayPos.y-distance) ))
    end
    
    title:runAction(cc.Sequence:create(actListTitle))
    btnPlay:runAction(cc.Sequence:create(actListBtn))
end

function CodeGameScreenScratchWinnerMachine:enterGamePlayMusic()
    self:playEnterGameSound(ScratchWinnerMusicConfig.Sound_EnterLevel)
    if nil == self.m_bonusGameData then
        self:levelPerformWithDelay(4,function()
            self:resetMusicBg(true, ScratchWinnerMusicConfig.Music_Base_Bg)
        end)
        
    end
end

function CodeGameScreenScratchWinnerMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end


    local shopData = self.m_shopMag:getShopListData()
    self.m_shopList:setDataList(shopData)
    local spinBtnUi = self.m_bottomUI.m_spinBtn
    local guideState = spinBtnUi.m_isShowFirstGuide
    if guideState then
        self.m_shopList:firstEnterLevelUpDateCardCount(self.m_initCardNum)
    end

    CodeGameScreenScratchWinnerMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_shopList:upDateButBtnState()
    self:runCsbAction("idle", true)
end

function CodeGameScreenScratchWinnerMachine:addObservers()
    CodeGameScreenScratchWinnerMachine.super.addObservers(self)

    --消息返回
    gLobalNoticManager:addObserver(self,function(self,params)
        if params.isBuy then
            self:playEffect_buyAnim()
        end
    end,"ScratchWinnerMachine_resultCallFun")
    -- spin按钮的事件
    gLobalNoticManager:addObserver(self,function(self,params)
        local enable  = params[1]
        local visible = params[2]
        self:setScratchWinnerSpinBtnEnable(enable, visible)
    end,"ScratchWinnerMachine_spinBtn_ChangeEnable")
    gLobalNoticManager:addObserver(self,function(self,params)
        self:ScratchWinnerSpinBtnTouchEnd()
    end,"ScratchWinnerMachine_spinBtn_TouchEnd")
    -- stop按钮的事件
    gLobalNoticManager:addObserver(self,function(self,params)
        local enable  = params[1]
        local visible = params[2]
        self:setScratchWinnerStopBtnEnable(enable, visible)
    end,"ScratchWinnerMachine_stopBtn_ChangeEnable")
end

function CodeGameScreenScratchWinnerMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end


    gLobalNoticManager:removeAllObservers(self.m_shopMag)
    self.m_shopMag:removeInstance()

    CodeGameScreenScratchWinnerMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

--[[
    bet按钮 和 spin按钮的状态
]]
function CodeGameScreenScratchWinnerMachine:setScratchWinnerBetBtnEnable(_enable)
    self.m_bottomUI:updateBetEnable(_enable)
end
function CodeGameScreenScratchWinnerMachine:setScratchWinnerStopBtnEnable(_enable, _visible)
    local spinBtnUi = self.m_bottomUI.m_spinBtn

    if nil ~= _enable then
        spinBtnUi.m_stopBtn:setBright(_enable)
        spinBtnUi.m_stopBtn:setTouchEnabled(_enable)
    end
    if nil ~= _visible then
        spinBtnUi.m_stopBtn:setVisible(_visible)
    end
end

function CodeGameScreenScratchWinnerMachine:setScratchWinnerSpinBtnEnable(_enable, _visible)
    local spinBtnUi = self.m_bottomUI.m_spinBtn

    if nil ~= _enable then
        spinBtnUi.m_spinBtn:setBright(_enable)
        spinBtnUi.m_spinBtn:setTouchEnabled(_enable)
    end
    if nil ~= _visible then
        spinBtnUi.m_spinBtn:setVisible(_visible)
    end
end
function CodeGameScreenScratchWinnerMachine:ScratchWinnerSpinBtnTouchEnd()
    local bBonus = self:isInScratchWinnerBonusGame()
    if not bBonus then
        self.m_shopList:onBuyBtnClick()
    end
    -- 引导相关参考 BaseMachine:normalSpinBtnCall()

    -- 引导打点：进入关卡-4.点击spin
    if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskStart1) then
        gLobalSendDataManager:getLogGuide():sendGuideLog(1, 4)
    end
    --新手引导相关
    local isComplete = globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskStart1, true)
    if isComplete then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_TIPS, {1, false})
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenScratchWinnerMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 卡3
    if symbolType >= self.SYMBOL_Card3_Start then
        return "Socre_ScratchWinner_luckyball_common"
    end
    -- 卡2
    if symbolType >= self.SYMBOL_Card2_Start then
        return "Socre_ScratchWinner_lottoluck_common"
    end
    -- 卡1
    if symbolType == self.SYMBOL_Card1_Jackpot then
        return "Socre_ScratchWinner_triplejackpot_jackpot"
    end
    if symbolType >= self.SYMBOL_Card1_Start then
        return "Socre_ScratchWinner_triplejackpot_common"
    end
    
    return nil
end

---
-- 不载入
--
function CodeGameScreenScratchWinnerMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenScratchWinnerMachine.super.getPreLoadSlotNodes(self)
    loadNode = {
        {symbolType = self.SYMBOL_Card1_Jackpot,count =  1}
    }
    -- !!!空列表会导致 loading 界面被卡住步骤
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------
--[[
    断线重连 | 进入关卡
]]
function CodeGameScreenScratchWinnerMachine:initGameStatusData(gameData)
    if nil ~= gameData.special then
        gameData.spin = gameData.special
    end
    if gameData.gameConfig.extra ~= nil then
        local extra = gameData.gameConfig.extra
        local shopData = extra.shopData
        self.m_shopMag:upDataShopData(shopData)
        
    end
    --初始化一下betId
    if gameData.spin and gameData.spin.selfData then
        local betIndex = gameData.spin.selfData.betIndex
        if nil ~= betIndex then
            local betData = globalData.slotRunData.machineData.p_betsData.p_curBetList[betIndex]
            if nil ~= betData then
                gameData.betId = betData.p_betId
            end
        end
    end

    -- 
    CodeGameScreenScratchWinnerMachine.super.initGameStatusData(self,gameData)
end
function CodeGameScreenScratchWinnerMachine:MachineRule_initGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local index     = selfData.index  or 0
    local cardCount = selfData.bagData and #selfData.bagData or 0
    local isTriggerBonus = cardCount > 0 and index <= cardCount

    if isTriggerBonus then
        self.m_beInSpecialGameTrigger = true
        self:setScratchWinnerBetBtnEnable(false)
        self.m_shopMag:upDataBagData(selfData)
        self.m_shopList:reconnectionUpDateCardCount()
        self:saveBonusGameData(true)
        self:showBonusGameView()
    end
end

--[[
    购买返回动画 -> 出卡流程
]]
function CodeGameScreenScratchWinnerMachine:playEffect_buyAnim()
    self:saveBonusGameData(false)
    self:showBonusGameView()

    -- local animTime = self:changeBgShowState(false, true)
    -- self:levelPerformWithDelay(animTime, function()
        -- local bagList = self.m_shopMag:getBagListData()
        -- -- 反序
        -- table.sort(bagList, function(_cardA, _cardB)
        --     local configA = self.m_shopMag:getCardConfig(_cardA.name)
        --     local configB = self.m_shopMag:getCardConfig(_cardB.name)
        --     -- 按照 order 排列
        --     if configA.order ~= configB.order then
        --         return configA.order > configB.order
        --     end
        --     return false
        -- end)
        -- self.m_exportAnim:setVisible(true)
        -- self.m_exportAnim:setDataList(bagList)
        -- self.m_exportAnim:playStartAnim(function()
        --     self.m_exportAnim:playExportAnim(1, function()
        --         self:showBonusGameView()
        --         self.m_exportAnim:setVisible(false)
        --     end)
        -- end)
    -- end)
end

function CodeGameScreenScratchWinnerMachine:playExportAnim(_startPos, _order, _cardName, _fun)
    -- 收起两端的节点
    self:playShopNodeMoveAction(false)

    local cardAnim = nil
    --拿池子
    if nil ~= self.m_exportCardList[_cardName] then
        if #self.m_exportCardList[_cardName] > 0 then
            local sMsg = string.format("[CodeGameScreenScratchWinnerMachine:playExportAnim] 复用 %s", _cardName)
            print(sMsg)
            release_print(sMsg)
            cardAnim = table.remove(self.m_exportCardList[_cardName], 1)
        end
    else
        self.m_exportCardList[_cardName] = {}
    end
    --创建
    local bCreate = nil == cardAnim
    local spineParent = self:findChild("Node_export")
    if bCreate then
        local sMsg = string.format("[CodeGameScreenScratchWinnerMachine:playExportAnim] 创建 %s", _cardName)
        print(sMsg)
        release_print(sMsg)
        local cardConfig = ScratchWinnerShopManager:getInstance():getCardConfig(_cardName)
        cardAnim = util_spineCreate(cardConfig.cardSpine,true,true)
        spineParent:addChild(cardAnim)
        cardAnim:setVisible(false)
    end

    local startPos = spineParent:convertToNodeSpace(_startPos)
    local endPos   = cc.p(0, 0)
    cardAnim:setPosition(startPos)
    cardAnim:setLocalZOrder(_order)
    -- 切换时延时一帧打开可见性
    util_spinePlay(cardAnim, "switch_daka", false)
    util_afterDrawCallBack(function()
        if tolua.isnull(cardAnim) then
            return
        end
        cardAnim:setVisible(true)
    end)
    
    --飞行
    local actList = {}
    local switchDakaTime = 15/30
    local flyTime = 12/30
    table.insert(actList, cc.MoveTo:create(flyTime, endPos))
    table.insert(actList, cc.DelayTime:create(switchDakaTime-flyTime))
    table.insert(actList, cc.CallFunc:create(function()
        local sMsg = string.format("[CodeGameScreenScratchWinnerMachine:playExportAnim] 放回 %s", _cardName)
        print(sMsg)
        release_print(sMsg)
        --放回池子
        table.insert(self.m_exportCardList[_cardName], cardAnim)
        -- 下一步
        _fun()
    end))
    cardAnim:runAction(cc.Sequence:create(actList))
end
function CodeGameScreenScratchWinnerMachine:hideExportCardList()
    for k,v in pairs(self.m_exportCardList) do
        for ii,vv in ipairs(v) do
            vv:stopAllActions()
            --有淡出了不能做堆叠效果了 (spine淡出时 子节点异常)
            -- local actList = {}
            -- table.insert(actList, cc.FadeTo:create(9/30, 0))
            -- table.insert(actList, cc.CallFunc:create(function()
                vv:setVisible(false)
            --     vv:setOpacity(255)
            -- end))
            -- vv:runAction(cc.Sequence:create(actList))
        end
    end
end

function CodeGameScreenScratchWinnerMachine:showBonusGameView()
    local initData = self:getBonusGameData()
    gLobalNoticManager:postNotification("ScratchWinnerMachine_bonus", {state="start"})
    self:resetMusicBg(true, ScratchWinnerMusicConfig.Music_Bonus_Bg)

    self.m_bottomUI:resetWinLabel()
    self.m_bottomUI:checkClearWinLabel()

    self.m_bonusGameView = util_createView("CodeScratchWinnerSrc.ScratchWinnerBonusGame", initData)
    self:findChild("Node_guaguaka"):addChild(self.m_bonusGameView)
    self.m_bonusGameView:startBonusGame()
end
function CodeGameScreenScratchWinnerMachine:saveBonusGameData(_bReconnect)
    self.m_bonusGameData = {}
    self.m_bonusGameData.bReconnect = _bReconnect
    self.m_bonusGameData.index = self.m_shopMag.m_bagData.index
    self.m_bonusGameData.machine  = self
    self.m_bonusGameData.cardList = self.m_shopMag:getBagListData()
    self.m_bonusGameData.overFun  = function()
        -- 释放
        if self.m_bonusGameView then
            gLobalNoticManager:removeAllObservers(self.m_bonusGameView)
            self.m_bonusGameView:removeFromParent()
            self.m_bonusGameView = nil
        end
        gLobalNoticManager:postNotification("ScratchWinnerMachine_bonus", {state="over"})
        gLobalNoticManager:postNotification("ScratchWinnerMachine_spinBtn_ChangeEnable", {nil, true})
        gLobalNoticManager:postNotification("ScratchWinnerMachine_stopBtn_ChangeEnable", {nil, false})
        self.m_shopList:upDateButBtnState()
        self:resetMusicBg(true, ScratchWinnerMusicConfig.Music_Base_Bg)

        self:setScratchWinnerBetBtnEnable(true)
        self.m_bonusGameData = nil
    end
end

function CodeGameScreenScratchWinnerMachine:getBonusGameData()
    return self.m_bonusGameData
end
-- 只判断数据不判断界面是否创建完毕 
function CodeGameScreenScratchWinnerMachine:isInScratchWinnerBonusGame()
    local curIndex = self.m_shopMag.m_bagData.index
    local list     = self.m_shopMag.m_bagData.list
    local bBonus = #list > 0 and curIndex < #list 
    return bBonus
end
--[[
    jackpot
]]
function CodeGameScreenScratchWinnerMachine:getScratchWinnerJackpotIndex(_cardJackpotIndex)
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id) or {}
    local jpIndex = #jackpotPools - (_cardJackpotIndex - 1)
    if nil ~= jackpotPools[jpIndex] then
        return jpIndex
    end

    return 0
end
function CodeGameScreenScratchWinnerMachine:showJackpotView(_cardData, _isAuto, _fun)
    --赢钱
    local winCoins = self.m_shopMag:getCardWinCoinsByIndex(_cardData.index, "jackpot")
    --奖池索引
    local cardShopData = self.m_shopMag:getCardShopData(_cardData.name)
    local jpIndex = self:getScratchWinnerJackpotIndex(cardShopData.jpIndex)

    local data = {
        name  = _cardData.name,
        coins = winCoins,
        jackpotIndex = jpIndex,
        isAuto  = _isAuto,
    }
    local newFun = function()
        _fun()
    end
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(winCoins, jpIndex)
    local jackPotWinView = util_createView("CodeScratchWinnerSrc.ScratchWinnerJackPotWinView", data)
    jackPotWinView:setOverAniRunFunc(newFun)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData()
end
--[[
    bigWin
]]
function CodeGameScreenScratchWinnerMachine:isTriggerScratchWinnerBigWin(_winCoins)
    local betCoins   = globalData.slotRunData:getCurTotalBet()
    local multi      = _winCoins / betCoins 

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate

    local winType = WinType.Normal

    if multi >= iEpicWinLimit then
        winType = WinType.EpicWin
    elseif multi >= iMegaWinLimit then
        winType = WinType.MegaWin
    elseif multi >= iBigWinLimit then
        winType = WinType.BigWin
    end

    return winType
end
function CodeGameScreenScratchWinnerMachine:showScratchWinnerBigWinView(_winCoins, _fun)
    local winType = self:isTriggerScratchWinnerBigWin(_winCoins)
    if winType == WinType.Normal then
        _fun()
        return 
    end

    local nextFun = function()
        self.m_bigWinOverFun = _fun
        self.m_llBigOrMegaNum = _winCoins

        if winType == WinType.EpicWin then
            self:showEffect_EpicWin({})
        elseif winType == WinType.MegaWin then
            self:showEffect_MegaWin({})
        elseif winType == WinType.BigWin then
            self:showEffect_BigWin({})
        end
    end

    if self:checkGameRunPause() then
        self.m_ScreenScratchLevelResumeFunc_bigWin = function()
            nextFun()
        end
    else
        nextFun()
    end    
end
-- 还是用底层的接口 但是把 playGameEffect 移除
function CodeGameScreenScratchWinnerMachine:showEffect_NewWin(effectData, winType)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    local bigMegaWin = util_createView("views.bigMegaWin.BigWinBg", winType)
    bigMegaWin:initViewData(
        self.m_llBigOrMegaNum,
        winType,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_OVER_BIGWIN_EFFECT, {winType = winType})

            -- cxc 2023年11月30日15:02:44  spinWin 需要监测弹（评分，绑定fb, 打开推送）
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("SpinWin", "SpinWin_" .. winType)
            if view then
                view:setOverFunc(function()
                    if not tolua.isnull(self) then
                        if nil ~= self.m_bigWinOverFun then
                            self.m_bigWinOverFun()
                            self.m_bigWinOverFun = nil
                        end
                        -- if self.playGameEffect then
                        --     effectData.p_isPlay = true
                        --     self:playGameEffect()
                        -- end
                    end
                end)
            else
                if nil ~= self.m_bigWinOverFun then
                    self.m_bigWinOverFun()
                    self.m_bigWinOverFun = nil
                end
                -- effectData.p_isPlay = true
                -- self:playGameEffect()
            end
            
        end
    )
    gLobalViewManager:showUI(bigMegaWin)
end

---------------------------------------------------------------------------

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenScratchWinnerMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume( )
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenScratchWinnerMachine:addSelfEffect()
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenScratchWinnerMachine:MachineRule_playSelfEffect(effectData)
    effectData.p_isPlay = true
    self:playGameEffect()
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenScratchWinnerMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end
function CodeGameScreenScratchWinnerMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenScratchWinnerMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end
function CodeGameScreenScratchWinnerMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    CodeGameScreenScratchWinnerMachine.super.slotReelDown(self)
end

function CodeGameScreenScratchWinnerMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end
--[[
    临时信号小块，不使用 池子的那一套，有可能泄漏
    create
    change
    runAnim
    getCcbProperty
]]
function CodeGameScreenScratchWinnerMachine:createnScratchWinnerTempSymbol(_symbolType)
    local symbol = util_createView("CodeScratchWinnerSrc.ScratchWinnerTempSymbol")
    symbol:initMachine(self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end
function CodeGameScreenScratchWinnerMachine:upDateCardViewReelSymbol(_cardIndex, _cardData,_reelIndex, _symbolNode)

    if self.SYMBOL_Card1_Start <= _symbolNode.m_symbolType and _symbolNode.m_symbolType <= self.SYMBOL_Card1_Jackpot then
        self:upDateReelSymbol_card1(_symbolNode, _reelIndex, _cardData)
    elseif self.SYMBOL_Card2_Start <= _symbolNode.m_symbolType and _symbolNode.m_symbolType < self.SYMBOL_Card3_Start then
        self:upDateReelSymbol_card2(_symbolNode, _reelIndex, _cardData)
    elseif self.SYMBOL_Card3_Start <= _symbolNode.m_symbolType and _symbolNode.m_symbolType < self.SYMBOL_Card4_Start then
        self:upDateReelSymbol_card3(_symbolNode, _reelIndex, _cardData)
    end

end
function CodeGameScreenScratchWinnerMachine:upDateReelSymbol_card1(_symbolNode, _reelIndex ,_cardData)
    _symbolNode:runAnim("idleframe", false)

    --创建连线框绑定在图标上
    if not _symbolNode.m_animNode.m_lineFrameCsb then
        local animNode = _symbolNode.m_animNode
        local lineFrameCsb = util_createAnimation("Socre_ScratchWinner_triplejackpot_zhongjiang.csb")
        animNode.m_lineFrameCsb = lineFrameCsb
        _symbolNode:getCcbProperty("Node_lineFrame"):addChild(lineFrameCsb)
        lineFrameCsb:setVisible(false)
    end
    
    local bJackpotSymbol = _symbolNode.m_symbolType == self.SYMBOL_Card1_Jackpot
    if not bJackpotSymbol then
        local labCoins = _symbolNode:getCcbProperty("m_lb_coins")
        local cardShopData = self.m_shopMag:getCardShopData(_cardData.name)
        local signalMulti = cardShopData.signalMulti
        local curMulti = signalMulti[_symbolNode.m_symbolType]
        local curBet = globalData.slotRunData:getCurTotalBet()
        local coins  = curBet * curMulti
        local sCoins = util_formatCoins(coins, 3)
        sCoins = string.format("$%s", sCoins)
        labCoins:setString(sCoins)

        self:updateLabelSize({label=labCoins,sx=1,sy=1}, 166)
    else
    end
end
function CodeGameScreenScratchWinnerMachine:upDateReelSymbol_card2(_symbolNode, _reelIndex ,_cardData)
    _symbolNode:runAnim("idleframe", false)

    --创建连线框绑定在图标上
    if not _symbolNode.m_animNode.m_lineFrameCsb then
        local animNode = _symbolNode.m_animNode
        local lineFrameCsb = util_createAnimation("Socre_ScratchWinner_lottoluck_zhongjiang.csb")
        animNode.m_lineFrameCsb = lineFrameCsb
        _symbolNode:getCcbProperty("Node_lineFrame"):addChild(lineFrameCsb)
        lineFrameCsb:setVisible(false)
    end


    local symbolIndex = _symbolNode.m_symbolType % 100
    local reelSymbolNode = _symbolNode:getCcbProperty("reelSymbol")
    local iconList = reelSymbolNode:getChildren()
    for i,v in ipairs(iconList) do
        v:setVisible(false)
    end
    local icon = _symbolNode:getCcbProperty( string.format("symbol_%d", symbolIndex) )
    if not icon then
        return
    end

    icon:setVisible(true)
end
function CodeGameScreenScratchWinnerMachine:upDateReelSymbol_card3(_symbolNode, _reelIndex ,_cardData)
    
    
    local comNode = _symbolNode:getCcbProperty("Node_common")
    local freeNode = _symbolNode:getCcbProperty("Node_free")

    local bFree = self.SYMBOL_Card3_Start == _symbolNode.m_symbolType
    comNode:setVisible(not bFree)
    freeNode:setVisible(bFree)

    if not bFree then
        _symbolNode:runAnim("idle2", false)

        local labB = _symbolNode:getCcbProperty("m_lb_coins_black")
        labB:setVisible(false)

        local labW = _symbolNode:getCcbProperty("m_lb_coins_white")
        labW:setVisible(true)
        local number = _cardData.reels[_reelIndex]
        number = number - self.SYMBOL_Card3_Start
        local sNumber = string.format("%d", number)
        labW:setString(sNumber)
        self:updateLabelSize({label=labW,sx=1,sy=1}, 50)
    else
        _symbolNode:runAnim("idle", false)
    end
end
function CodeGameScreenScratchWinnerMachine:upDateLineSymbol_card3(_symbolNode, _bingoIndex ,_cardData)
    _symbolNode:runAnim("idle", false)
    if not _symbolNode.m_diCsb then
        local diCsb = util_createAnimation("Socre_ScratchWinner_luckyball_common_di.csb")
        _symbolNode.m_diCsb = diCsb
        _symbolNode:getCcbProperty("di"):addChild(diCsb)
    end
    _symbolNode.m_diCsb:runCsbAction("idle", false)

    local comNode = _symbolNode:getCcbProperty("Node_common")
    local freeNode = _symbolNode:getCcbProperty("Node_free")

    local bFree = self.SYMBOL_Card3_Start == _symbolNode.m_symbolType
    comNode:setVisible(not bFree)
    freeNode:setVisible(bFree)

    if not bFree then
        local labW = _symbolNode:getCcbProperty("m_lb_coins_white")
        labW:setVisible(false)

        local labB = _symbolNode:getCcbProperty("m_lb_coins_black")
        labB:setVisible(true)
        local number = _cardData.bingoReels[_bingoIndex]
        number = number - self.SYMBOL_Card3_Start
        local sNumber = string.format("%d", number)
        labB:setString(sNumber)
        self:updateLabelSize({label=labB,sx=1,sy=1}, 60)

        local spW = _symbolNode:getCcbProperty("Sprite_white")
        spW:setVisible(false)
    end
end
--[[
    一些工具
]]
function CodeGameScreenScratchWinnerMachine:clearBottomUICoins()
    self.m_bottomUI:resetWinLabel()
    self.m_bottomUI:checkClearWinLabel()
end
function CodeGameScreenScratchWinnerMachine:updateBottomUICoins( _beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound )
    local winCoins = _endCoins - _beiginCoins
    self:setLastWinCoin(winCoins)
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)

    local jumpTime = self.m_bottomUI:getCoinsShowTimes(winCoins)
    return jumpTime
end
-- 通用延时接口
function CodeGameScreenScratchWinnerMachine:levelPerformWithDelay(_time, _fun)
    if _time <= 0 then
        _fun()
        return
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()

        _fun()

        waitNode:removeFromParent()
    end, _time)

    return waitNode
end
--[[
    ==============================================重写底层接口
]]
function CodeGameScreenScratchWinnerMachine:initTopUI()
    --!!!
    local topNode = util_createView(self:getScratchWinnerTopUiNode(), self)
    self:addChild(topNode, GAME_LAYER_ORDER.LAYER_ORDER_TOP)
    if globalData.slotRunData.isPortrait == false then
        topNode:setScaleForResolution(true)
    end
    topNode:setPositionX(display.cx)
    topNode:setPositionY(display.height)
    globalData.topUIScale = topNode:getCsbNodeScale()

    self.m_topUI = topNode

    local coin_dollar_10 = self.m_topUI:findChild("coin_dollar_10")
    local endPos = coin_dollar_10:getParent():convertToWorldSpace(cc.p(coin_dollar_10:getPosition()))
    globalData.flyCoinsEndPos = clone(endPos)

    if globalData.slotRunData.isPortrait == false then
        globalData.recordHorizontalEndPos = clone(endPos)
    end

    local lobbyHomeBtn = self.m_topUI:findChild("btn_layout_home")
    local endPos = lobbyHomeBtn:getParent():convertToWorldSpace(cc.p(lobbyHomeBtn:getPosition()))
    globalData.gameLobbyHomeNodePos = endPos

end
function CodeGameScreenScratchWinnerMachine:getScratchWinnerTopUiNode()
    return "CodeScratchWinnerSrc.ScratchWinnerGameTopNode" 
end
function CodeGameScreenScratchWinnerMachine:getBottomUINode()
    return "CodeScratchWinnerSrc.ScratchWinnerGameBottomNode"
end

-- 进入关卡时不想创建图标
function CodeGameScreenScratchWinnerMachine:initNoneFeature()
    if globalData.GameConfig:checkSelectBet() then
        local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if questConfig and questConfig.m_IsQuestLogin then
            --quest进入也使用服务器bet
        else
            if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest()then
                --quest进入也使用服务器bet
            else
                self.m_initBetId = -1
            end
        end
    end
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    --!!! 不创建图标
    -- self:initRandomSlotNodes()
end
function CodeGameScreenScratchWinnerMachine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    --!!! 不创建图标
    -- self:initCloumnSlotNodesByNetData()
end
--!!! 不滚动 只发消息
function CodeGameScreenScratchWinnerMachine:beginReel()
    self:resetReelDataAfterReel()
end
--!!! 不修改按钮状态
function CodeGameScreenScratchWinnerMachine:dealSmallReelsSpinStates( )
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
end
-- !!! 没有参数直接跳出 , ScratchWinnerShopManager:sendBuyData 调用这个接口
function CodeGameScreenScratchWinnerMachine:requestSpinResult(_messageData)
    if not _messageData then
        local sMsg = string.format("[CodeGameScreenScratchWinnerMachine] _messageData is nil")
        error(sMsg)
        return
    end

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

    --!!! 关闭bet按钮
    self:setScratchWinnerBetBtnEnable(false)
    --!!! spin时重置数据
    if MessageDataType.MSG_SPIN_PROGRESS == _messageData.msg then
        self:resetReelDataAfterReel()
    end
    
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg      = _messageData.msg,
        choose   = _messageData.data,
        jackpot  = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }

    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end
-- !!!不在此处请求数据
function CodeGameScreenScratchWinnerMachine:requestSpinReusltData()
end

-- 数据返回重置卡片列表
function CodeGameScreenScratchWinnerMachine:operaSpinResultData(param)
    CodeGameScreenScratchWinnerMachine.super.operaSpinResultData(self, param)

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_shopMag:upDataBagData(selfData)
end
function CodeGameScreenScratchWinnerMachine:updateNetWorkData()
    CodeGameScreenScratchWinnerMachine.super.updateNetWorkData(self)

    --!!! 直接处理事件池
    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()
end
-- 只修改状态和触发刮卡
function CodeGameScreenScratchWinnerMachine:operaEffectOver()
    printInfo("run effect end")

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = false
    end

    -- 结束动画播放
    self.m_isRunningEffect = false
    -- !!! playGameEffect最后结束时一定是处理卡片返回的数据
    local params = {
        isBuy    = false,
        isReward = true,
        isClear  = false,
    }
    gLobalNoticManager:postNotification("ScratchWinnerMachine_resultCallFun", params)
end
--[[
    暂停重写
]]
function CodeGameScreenScratchWinnerMachine:resumeMachine()
    CodeGameScreenScratchWinnerMachine.super.resumeMachine(self)

    if "function" == type(self.m_ScreenScratchLevelResumeFunc) then
        self.m_ScreenScratchLevelResumeFunc()
        self.m_ScreenScratchLevelResumeFunc = nil
    end

    if "function" == type(self.m_ScreenScratchLevelResumeFunc_bigWin) then
        self.m_ScreenScratchLevelResumeFunc_bigWin()
        self.m_ScreenScratchLevelResumeFunc_bigWin = nil
    end
end
function CodeGameScreenScratchWinnerMachine:checkGameResumeCallFun()
    if self:checkGameRunPause() then
        self.m_ScreenScratchLevelResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end

--[[
    恢复背景音并逐渐减小音量
]]
function CodeGameScreenScratchWinnerMachine:resumeLevelSoundHandler()
    self:setMaxMusicBGVolume()
    self:resetMusicBg()
    -- self:reelsDownDelaySetMusicBGVolume()
end

function CodeGameScreenScratchWinnerMachine:scaleMainLayer()
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
        if display.height < DESIGN_SIZE.height then
            if display.height / display.width > 1370/768 then
                mainScale = mainScale * 0.98
                mainPosY = mainPosY + 5
            elseif display.height / display.width >= 1228/768 then
                mainPosY = mainPosY + 30
            elseif display.height / display.width >= 960/640 then
                mainPosY = mainPosY + 40
            elseif display.height / display.width >= 1024/768 then
                mainScale = mainScale * 1.05
                mainPosY = mainPosY + 40
            end

            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(mainPosY)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end



return CodeGameScreenScratchWinnerMachine