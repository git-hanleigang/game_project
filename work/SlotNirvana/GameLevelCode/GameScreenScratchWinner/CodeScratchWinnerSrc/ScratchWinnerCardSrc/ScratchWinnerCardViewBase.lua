-- 刮刮卡界面的基类
-- 差异化用工程内相同的节点名称不同的展示解决 或 继承后重写解决
-- 刮卡界面的Ui使用时判空创建 (卡片界面也会用于出卡口展示)
--[[
    可能重写的接口

    initUI                       --调用父类接口后，添加独有Ui添加展示 (出卡界面也会用到)
    initMainCardUi               --调用父类接口后，添加独有Ui添加展示 (只有刮卡界面会用到 用判空创建的格式)
    getAutoScrapePath            --返回一条自动刮卡路径
    onTouchCoatingLayer          --调用父类接口后，添加刮卡时的一些特殊表现
    coatingOverCallBack          --刮卡结束回调，向服务器发送领取奖励请求
    showLineFrame                --领取卡片奖励数据返回，开始播放本张卡片的连线效果
    showJackpotLineEffect        --连线触发jackpot时的特殊表现
    endCardGame                  --!!!一定先调用自己的释放逻辑后, 再调用父类接口 (父类接口可能直接就把卡片移除了，延时释放时要注意)
]]
--[[
    工程文件存在的节点名称和作用

    -- !!!必有
    jackpot               --顶部奖池挂点
    Node_btnBack          --返回按钮
    Node_jackpotCoinSpine --jackpot效果-金币喷射
    Node_cardSpine        --spine挂点
    reel                  --刮卡区域的图标挂点 (普通层级)
    Panel_reel            --连线时遮挡不连线图标的遮罩
    reelSpecial           --刮卡区域的图标挂点 (连线层级)
    Layer_coating         --涂层挂点
    Sprite_mask           --涂层的精灵
    Node_xinshou          --新手引导挂点
    sp_coin               --刮卡时跟随移动的精灵
    Node_button           --底部按钮
    Panel_wait            --赢钱结束等待切换的遮罩

    -- 可选
    lines                 --bingo卡片的独有节点 (兑奖区域图标的挂点)
]]
--[[
    --数据

    m_cardData = {
        index      = 1,
        name       = "",
        lines      = {},
        reels      = {},
        bingoReels = {},
    }
]]
local ScratchWinnerBaseCardView = class("ScratchWinnerBaseCardView", util_require("Levels.BaseLevelDialog"))
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"
local ScratchWinnerMusicConfig = require "CodeScratchWinnerSrc.ScratchWinnerMusicConfig"

function ScratchWinnerBaseCardView:initUI(_cardConfig)
    self.m_cardConfig = _cardConfig
    self:createCsbNode(_cardConfig.cardViewRes)
    self:initCardViewSpine()
    -- 触摸位置的图标
    self.m_spCoin = self:findChild("sp_coin")
    -- 连线遮罩
    self.m_panelReel = self:findChild("Panel_reel")
    self.m_panelReel:setVisible(false)
    -- 等待遮罩
    self.m_panelWait = self:findChild("Panel_wait")
    self:addClick(self.m_panelWait)
    -- 涂层的挂点
    self.m_layerCoating = self:findChild("Layer_coating")
    -- 涂层精灵
    self.m_spMask = self:findChild("Sprite_mask")
    -- 音效计时器节点
    self.m_soundNode = cc.Node:create()
    self:addChild(self.m_soundNode)

    self.m_reelsSymbolList = {}
    self:resetAutoScrapeData()
end
-- 事件监听
function ScratchWinnerBaseCardView:addBaseCardViewObserver()
    -- spin按钮的事件
    gLobalNoticManager:addObserver(self,function(self,params)
        self:ScratchWinnerSpinBtnTouchBegin()
    end,"ScratchWinnerMachine_spinBtn_TouchBegan")
    gLobalNoticManager:addObserver(self,function(self,params)
        self:ScratchWinnerSpinBtnTouchEnd()
    end,"ScratchWinnerMachine_spinBtn_TouchEnd")
    -- stop按钮的事件
    gLobalNoticManager:addObserver(self,function(self,params)
        self:ScratchWinnerStopBtnTouchEnd()
    end,"ScratchWinnerMachine_stopBtn_TouchEnd")
end
function ScratchWinnerBaseCardView:removeBaseCardViewObserver()
    gLobalNoticManager:removeAllObservers(self)
end

function ScratchWinnerBaseCardView:initCardData(_data)
    self.m_cardData = _data
end
function ScratchWinnerBaseCardView:initMachine(_machine)
    self.m_machine = _machine
end

function ScratchWinnerBaseCardView:initMainCardUi()
    -- 这个地方创建的控件都能拿到卡片数据
    self:initJackpotCoinSpine()
    self:initCardViewJackpot()
    self:initBackBtn()
    self:initAutoBtnUi()
    self:initCardViewSymbol()
end
function ScratchWinnerBaseCardView:startCardGame(_bDifferent, _bReconnect, _fun)
    self.m_endFun   = _fun
    
    -- 自动刮卡需要等待 一些控件入场后再开始
    if self.m_bAutoAllState then
        self:delayAutoScrape()
    else
        self:changeAutoBtnEnable(true)
    end

    self:playCardViewShow(_bDifferent, _bReconnect)
    if _bDifferent then
        self:playDifferentCardViewShow(_bReconnect)
    end
end
function ScratchWinnerBaseCardView:endCardGame()
    self:removeBaseCardViewObserver()
    self:stopLineFrameUpDate()
    self:playInLineNodesIdle()

    self.m_endFun(self.m_bAutoAllState)
end


--========================================================初始化一些主卡片的控件
--[[
    卡片spine
]]
function ScratchWinnerBaseCardView:initCardViewSpine()
    local spineParent = self:findChild("Node_cardSpine")
    self.m_cardSpine = util_spineCreate(self.m_cardConfig.cardSpine,true,true)
    spineParent:addChild(self.m_cardSpine)
    util_spinePlay(self.m_cardSpine, "idle_static", false)
end
--[[
    jackpot相关
]]
--jackpot触发效果
function ScratchWinnerBaseCardView:initJackpotCoinSpine()
    local spineParent = self:findChild("Node_jackpotCoinSpine")
    --创建
    if nil == self.m_jackpotCoinSpine_1 and nil == self.m_jackpotCoinSpine_2 then
        self.m_jackpotCoinSpine_1 = util_spineCreate("ScratchWinner_bigwin_1",true,true)
        self.m_jackpotCoinSpine_2 = util_spineCreate("ScratchWinner_bigwin_2",true,true)
        spineParent:addChild(self.m_jackpotCoinSpine_1)
        spineParent:addChild(self.m_jackpotCoinSpine_2)
    end
    --隐藏
    spineParent:setVisible(false)
end
function ScratchWinnerBaseCardView:playJackpotCoinEffect()
    gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_CardView_JackpotCoinEffect)

    local spineParent = self:findChild("Node_jackpotCoinSpine")
    spineParent:setVisible(true)

    util_spinePlay(self.m_jackpotCoinSpine_1, "actionframe", false)
    util_spinePlay(self.m_jackpotCoinSpine_2, "actionframe", false)

    return 120/30 --75/30
end
function ScratchWinnerBaseCardView:hideJackpotCoinEffect()
    local spineParent = self:findChild("Node_jackpotCoinSpine")
    spineParent:setVisible(false)
end
--奖池栏
function ScratchWinnerBaseCardView:initCardViewJackpot()
    -- 创建
    local jackpotPartent = self:findChild("jackpot")
    if not jackpotPartent then
        return 
    end
    if not self.m_jackpotUi then
        self.m_jackpotUi = util_createAnimation("ScratchWinner_jackpot_all.csb")  
        jackpotPartent:addChild(self.m_jackpotUi)
    end
    
    self:stopUpDateJackpot()
    local lbCoins = self.m_jackpotUi:findChild("m_lb_coins")

    local cardShopData =  ScratchWinnerShopManager:getInstance():getCardShopData(self.m_cardData.name)
    local jpIndex = self.m_machine:getScratchWinnerJackpotIndex(cardShopData.jpIndex)
    if jpIndex <= 0 then
        lbCoins:setString("")
        return 
    end
    --先立刻刷一遍
    local value   = self.m_machine:BaseMania_updateJackpotScore(jpIndex)
    lbCoins:setString(util_formatCoins(value,20,nil,nil,true))
    self:updateLabelSize({label=lbCoins,sx=1,sy=1}, 470)

    self.m_upDateJackpot = schedule(self, function()
        local value   = self.m_machine:BaseMania_updateJackpotScore(jpIndex)
        lbCoins:setString(util_formatCoins(value,20,nil,nil,true))
        self:updateLabelSize({label=lbCoins,sx=1,sy=1}, 470)
    end, 0.08)
end
function ScratchWinnerBaseCardView:stopUpDateJackpot()
    if nil ~= self.m_upDateJackpot then
        self:stopAction(self.m_upDateJackpot)
        self.m_upDateJackpot = nil
    end
end
function ScratchWinnerBaseCardView:playJackpotBarStartAnim()
    self.m_jackpotUi:runCsbAction("start", false)

    local time = util_csbGetAnimTimes(self.m_jackpotUi.m_csbAct, "start")
    performWithDelay(self.m_jackpotUi,function()
        self.m_jackpotUi:runCsbAction("idle", true)
    end, time)

end
function ScratchWinnerBaseCardView:playJackpotBarOverAnim()
    self.m_jackpotUi:stopAllActions()
    self.m_jackpotUi:runCsbAction("over", false)
end
--[[
    返回按钮
    禁用时期:
        只要玩家触摸到刮卡区域
        在自动刮卡状态打开卡片
        断线重连状态下打开卡片
]]
function ScratchWinnerBaseCardView:initBackBtn()
    if nil ~= self.m_backBtnCsb then
        return
    end
    local btnParent = self:findChild("Node_btnBack")
    self.m_backBtnCsb = util_createAnimation("ScratchWinner_btnBack.csb")
    btnParent:addChild(self.m_backBtnCsb)
    util_setCascadeOpacityEnabledRescursion(self.m_backBtnCsb, true)
    self:addClick(self.m_backBtnCsb:findChild("btn_back"))
end
function ScratchWinnerBaseCardView:changeBackBtnEnable(_enabled)
    self.m_backBtnCsb:findChild("btn_back"):setEnabled(_enabled)
end
function ScratchWinnerBaseCardView:playBackBtnStartAnim(_bReconnect)
    self:changeBackBtnEnable(false)

    local actList = {}
    table.insert(actList, cc.FadeIn:create(21/60))
    table.insert(actList, cc.CallFunc:create(function()
        self:changeBackBtnEnable(not _bReconnect)
    end))

    self.m_backBtnCsb:setOpacity(0)
    self.m_backBtnCsb:runAction(cc.Sequence:create(actList))
end
function ScratchWinnerBaseCardView:playBackBtnOverAnim()
    self.m_backBtnCsb:runAction(cc.FadeOut:create(15/60))
end
function ScratchWinnerBaseCardView:onBackBtnClick()
    self:changeBackBtnEnable(false)
    self.m_overClearState = true

    -- 自动刮卡状态 点击了按钮
    if self:getAutoScrapeState() then
        self:onAutoBtnClick("btn_auto")
    -- 没有触摸过刮卡区域时 点击了按钮
    else
        self:coatingOverCallBack()
    end
end
--[[
    卡片上的图标(刮卡区域 兑奖区域)
]]
function ScratchWinnerBaseCardView:initCardViewSymbol()
    self:initCardViewReels()
end
function ScratchWinnerBaseCardView:initCardViewReels()
    local parent = self:findChild("reel")

    for _reelIndex,_symbolType in ipairs(self.m_cardData.reels) do
        local reelSymbol = self.m_reelsSymbolList[_reelIndex]
        if not reelSymbol then
            local posNode = self:findChild(string.format("%d", _reelIndex))
            if posNode then
                reelSymbol = self.m_machine:createnScratchWinnerTempSymbol(_symbolType)
                parent:addChild(reelSymbol)
                self.m_reelsSymbolList[_reelIndex] = reelSymbol
            end
        else
            reelSymbol:changeSymbolCcb(_symbolType)
        end
        
        self:changeReelSymbolOrder(reelSymbol, false)
        self.m_machine:upDateCardViewReelSymbol(self.m_cardData.index, self.m_cardData,_reelIndex, reelSymbol)
    end

    self:initCardViewReelsPos()
end
function ScratchWinnerBaseCardView:initCardViewReelsPos()
    for _reelIndex,_reelSymbol in ipairs(self.m_reelsSymbolList) do
        local posNode = self:findChild(string.format("%d", _reelIndex))
        if posNode then
            local pos = util_convertToNodeSpace(posNode, _reelSymbol:getParent()) 
            _reelSymbol:setPosition(pos)
        end
    end
end

--[[
    刮卡引导

    只有首张卡片播放引导
]]
function ScratchWinnerBaseCardView:playGuideAnim()
    if 1 ~= self.m_cardData.index then
        return
    end
    if not self.m_guideSpine then
        self.m_guideSpine = util_spineCreate("ScratchWinner_Xinshou",true,true)
        self:findChild("Node_xinshou"):addChild(self.m_guideSpine)
    end
    
    self.m_guideSpine:setVisible(true)
    self.m_guideSpine:setOpacity(255)

    local intervalTime = 60/30
    self:stopGuideAnim()

    util_spinePlay(self.m_guideSpine, "idleframe", false)
    self.m_updateGuideAction = schedule(self.m_guideSpine,function()
        util_spinePlay(self.m_guideSpine, "idleframe", false)
    end, intervalTime)
end
function ScratchWinnerBaseCardView:stopGuideAnim(_hide)
    if self.m_updateGuideAction then
        self.m_guideSpine:stopAction(self.m_updateGuideAction)
        self.m_updateGuideAction = nil

        if _hide then
            self.m_guideSpine:runAction(cc.Sequence:create(
                cc.FadeOut:create(0.5),
                cc.CallFunc:create(function()
                    self.m_guideSpine:setVisible(false)
                end)
            ))
        end
    end
end

--[[
    auto按钮 / stop按钮
]]
function ScratchWinnerBaseCardView:initAutoBtnUi()
    if not self.m_autoBtnCsb then
        self.m_autoBtnCsb = util_createView("CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerCardViewUiAutoBtn")
        self:findChild("Node_button"):addChild(self.m_autoBtnCsb)
        self:addClick(self.m_autoBtnCsb:findChild("btn_scratch"))
        self:addClick(self.m_autoBtnCsb:findChild("btn_scratch_one"))
        self:addClick(self.m_autoBtnCsb:findChild("btn_auto"))
        self:addClick(self.m_autoBtnCsb:findChild("btn_auto_one"))
    end
end
function ScratchWinnerBaseCardView:upDateAutoBtnCountLab()
    local bagList = ScratchWinnerShopManager:getInstance():getBagListData()
    local curIndex = self.m_cardData.index
    local maxIndex = #bagList
    self.m_autoBtnCsb:upDateTimes(curIndex, maxIndex)

    self.m_autoBtnCsb:setOneCardState(1 == maxIndex)
    self.m_autoBtnCsb:upDateBtnState()
end
function ScratchWinnerBaseCardView:changeAutoBtnEnable(_enable)
    self.m_autoBtnCsb:changeAutoBtnEnable(_enable)

    gLobalNoticManager:postNotification("ScratchWinnerMachine_spinBtn_ChangeEnable", {_enable, nil})
    gLobalNoticManager:postNotification("ScratchWinnerMachine_stopBtn_ChangeEnable", {_enable, nil})
end
function ScratchWinnerBaseCardView:onAutoBtnClick(_name)
    self:changeAutoBtnEnable(false)
    if _name == "btn_auto" then
        self:setAutoState(false)
    end
end

function ScratchWinnerBaseCardView:ScratchWinnerSpinBtnTouchBegin()
    -- local state = self.m_autoBtnCsb.m_bOneCard
    -- if state then
    --     return
    -- end
    self:startHoldFroAuto()
end
function ScratchWinnerBaseCardView:ScratchWinnerSpinBtnTouchEnd()
    -- 长按触发后不处理点击
    if not self:getAutoScrapeState() then
        self:stopGuideAnim(true)
        self:startAutoScrape(false)
        self:setAutoState(false)
        self:changeBackBtnEnable(true)
    end

    self:stopHoldFroAuto()
end
function ScratchWinnerBaseCardView:ScratchWinnerStopBtnTouchEnd()
    self:onAutoBtnClick("btn_auto")
end
--[[
    触摸事件
]]
function ScratchWinnerBaseCardView:clickStartFunc(sender)
    local name = sender:getName()
    if name == "btn_scratch" or name == "btn_scratch_one" then
        self:startHoldFroAuto()
    end
end
function ScratchWinnerBaseCardView:clickEndFunc(sender)
    local name = sender:getName()
    if name == "btn_scratch" or name == "btn_scratch_one" then
        self:stopHoldFroAuto()
    end
end
function ScratchWinnerBaseCardView:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_scratch" or name == "btn_scratch_one" then
        -- 长按触发后不处理点击
        if not self:getAutoScrapeState() then
            gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_Click)
            self:stopGuideAnim(true)
            self:startAutoScrape(false)
            self:setAutoState(false)
            self:changeBackBtnEnable(true)
        end
    elseif name == "btn_auto" or name == "btn_auto_one" then
        gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_Click)
        self:onAutoBtnClick(name)
    elseif name == "Panel_wait" then
        gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_Click)
        self:onPanelWaitClick()
    elseif name == "btn_back" then
        gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_Click)
        self:onBackBtnClick()
    end
end
-- 长按
function ScratchWinnerBaseCardView:startHoldFroAuto()
    self:stopHoldFroAuto()

    local actList = {}
    table.insert(actList, cc.DelayTime:create(15/60))
    table.insert(actList, cc.CallFunc:create(function()
        self.m_autoBtnCsb:runCsbAction("actionframe", false)
    end))
    table.insert(actList, cc.DelayTime:create(45/60))
    table.insert(actList, cc.CallFunc:create(function()
        self.m_autoBtnCsb:plauAutoBtnIdleAnim()
        self:stopGuideAnim(true)
        self:startAutoScrape(true)
        self:setAutoState(true)
        self:changeBackBtnEnable(true)
        self.m_upDateHoldFroAuto = nil
    end))
    
    self.m_upDateHoldFroAuto = self.m_autoBtnCsb:runAction(cc.Sequence:create(actList))
end
function ScratchWinnerBaseCardView:stopHoldFroAuto()
    if self.m_upDateHoldFroAuto then
        self.m_autoBtnCsb:plauAutoBtnIdleAnim()
        self.m_autoBtnCsb:stopAction(self.m_upDateHoldFroAuto)
        self.m_upDateHoldFroAuto = nil
    end
end
--[[
    自动刮卡
]]
function ScratchWinnerBaseCardView:setAutoState(_bAuto)
    -- 更新卡片的autoAll状态
    self.m_bAutoAllState = _bAuto
    -- 更新按钮的当前auto状态
    local isAutoScrape = self:getAutoScrapeState()
    self.m_autoBtnCsb:setAutoState(isAutoScrape)
    self.m_autoBtnCsb:upDateBtnState()

    gLobalNoticManager:postNotification("ScratchWinnerMachine_spinBtn_ChangeEnable", {nil, not isAutoScrape})
    gLobalNoticManager:postNotification("ScratchWinnerMachine_stopBtn_ChangeEnable", {nil, isAutoScrape})
end
function ScratchWinnerBaseCardView:delayAutoScrape()
    local jackpotEnterTime = self:getDelayAutoScrapeTime()

    performWithDelay(self.m_layerCoating,function()
        self:changeAutoBtnEnable(true)
        self:startAutoScrape(true)
        self:setAutoState(true)
        self:changeBackBtnEnable(true)

    end, jackpotEnterTime)
end
function ScratchWinnerBaseCardView:stopDelayAutoScrape()
    self.m_layerCoating:stopAllActions()
end
function ScratchWinnerBaseCardView:getDelayAutoScrapeTime()
    return 0.5
end

function ScratchWinnerBaseCardView:startAutoScrape()
    if self.m_autoScrapeAction or not self.m_coatingLayer then
        return
    end

    local pathIndex = 1
    local path = {}
    -- 之前存在自动刮卡
    if self.m_curAutoScrapeIndex > 1 and self.m_curAutoScrapeIndex < #self.m_curAutoScrapePath then
        pathIndex = self.m_curAutoScrapeIndex
    else
        -- 拿一条路径
        self.m_curAutoScrapePath  = self:getAutoScrapePath()
    end

    path = self.m_curAutoScrapePath
    if #path < 1 then
        self:setAutoState(false)
        return
    end
    
    local cardConfig   = ScratchWinnerShopManager:getInstance():getCardConfig(self.m_cardData.name)
    local moveInter    = cardConfig.cardViewAutoScrapeInter or 0.015
    local coatingLayer = self.m_coatingLayer
    local parent    = coatingLayer:getParent()
    local touchFunc = coatingLayer.touchFunc
    local distance  = cardConfig.cardViewBrushRadius
    local startPos  = parent:convertToWorldSpace(cc.p(0, 0))

    self:setCoatingLayerUserTouchState(false)
    local eventData = {
        isAutoScrape = true,
        name = "began",
        x = startPos.x + path[pathIndex].x, 
        y = startPos.y + path[pathIndex].y,
    }
    touchFunc(nil, eventData)

    self.m_autoScrapeAction = schedule(coatingLayer, function()
        if self.m_machine:checkGameRunPause() then
            return
        end
        if not self.m_coatingLayer.m_canTouch then
            return
        end
        

        local targetData = path[pathIndex+1]
        local targetPos  = cc.p(startPos.x + targetData.x, startPos.y + targetData.y)
        local rotation = util_getAngleByPos(cc.p(eventData.x, eventData.y), targetPos)
        local surplusDistance = math.sqrt(math.pow(targetPos.x-eventData.x, 2) + math.pow(targetPos.y-eventData.y, 2))
        
        if surplusDistance <= distance then
            pathIndex = pathIndex + 1
            self.m_curAutoScrapeIndex = pathIndex

            eventData.x = startPos.x + targetData.x
            eventData.y = startPos.y + targetData.y
        else
            local nextPos = cc.p( util_getCirclePointPos(eventData.x, eventData.y, distance, rotation) ) 
            eventData.x = nextPos.x
            eventData.y = nextPos.y
        end

        eventData.name = pathIndex < #path and "moved" or "ended"

        touchFunc(nil, eventData)

        if pathIndex == #path then
            self:stopAutoScrape()
        end
    end, moveInter)
end
-- @_bAuto : 停止自动刮卡时是否修改自动刮卡状态
function ScratchWinnerBaseCardView:stopAutoScrape()
    if self.m_autoScrapeAction and self.m_coatingLayer then
        self.m_coatingLayer:stopAction(self.m_autoScrapeAction)
        self.m_autoScrapeAction = nil
    end
end
-- 返回一条路线 --!!!子类自己重写
function ScratchWinnerBaseCardView:getAutoScrapePath()
    local pathList = {
        {
            -- cc.p(45, 175),cc.p(125, 220),
            -- cc.p(190, 220),cc.p(45, 130),

            -- cc.p(45, 85),cc.p(255, 220),
            -- cc.p(320, 220),cc.p(45, 40),

            -- cc.p(125, 40),cc.p(320, 175),
            -- cc.p(320, 130),cc.p(190, 40),

            -- cc.p(320, 40),cc.p(320, 40),
        }
    }
    local finalPath = pathList[1]
    local newPath = {}
    local mainScale = self.m_machine.m_machineRootScale

    for i,_pos in ipairs(finalPath) do
        table.insert( newPath, cc.p(_pos.x*mainScale, _pos.y*mainScale))
    end

    return newPath
end

function ScratchWinnerBaseCardView:resetAutoScrapeData()
    self.m_curAutoScrapeIndex = 1
    self.m_curAutoScrapePath  = {}
end
function ScratchWinnerBaseCardView:getAutoScrapeState()
    local isAutoScrape = nil ~= self.m_autoScrapeAction
    return isAutoScrape
end
--[[
    刮卡时触摸位置的图标
]]
function ScratchWinnerBaseCardView:changeAutoCoinVisible(_visible)
    self.m_spCoin:setVisible(_visible)
end
function ScratchWinnerBaseCardView:changeAutoCoinPos(_event)
    local pos = self.m_spCoin:getParent():convertToNodeSpace( cc.p(_event.x, _event.y) ) 
    self.m_spCoin:setPosition(pos)
end


--[[
    刷新卡片: 奖池 刮卡区域 卡片进度
]]
function ScratchWinnerBaseCardView:playCardViewShow(_bDifferent, _bReconnect)
    -- 引导动画
    self:playGuideAnim()
    -- 重置涂层
    self:upDateCardViewCoatingLayer()
    -- 返回按钮打开点击状态
    if not _bDifferent then
        self:changeBackBtnEnable(not _bReconnect)
    end
    -- 自动按钮
    self:upDateAutoBtnCountLab()

    self:resetPanelWait()
    self:resetAutoScrapeData()
    -- 重置一下结束本张卡片时的清理状态,
    -- 卡片结束时, 判断状态,决定是否清理背包
    self.m_overClearState = false

    -- 卡片spine的闪光idle
    util_spinePlay(self.m_cardSpine, "idle", true)
end
function ScratchWinnerBaseCardView:playDifferentCardViewShow(_bReconnect)
    -- jackpot淡入
    self:playJackpotBarStartAnim()
    -- 自动按钮出现
    self.m_autoBtnCsb:plauAutoBtnStartAnim()
    -- 返回按钮淡入
    self:playBackBtnStartAnim(_bReconnect)
end
function ScratchWinnerBaseCardView:hideDifferentCardViewShow()
    self.m_autoBtnCsb:plauAutoBtnOverAnim()
    self:playJackpotBarOverAnim()
    self:playBackBtnOverAnim()
end
-- 刷新重置涂层相关
function ScratchWinnerBaseCardView:upDateCardViewCoatingLayer()
    self:resetCoatingLayer()
    self.m_machine:clearBottomUICoins()
end
function ScratchWinnerBaseCardView:resetCoatingLayer()
    self:removeCoatingLayer()

    local cardConfig = ScratchWinnerShopManager:getInstance():getCardConfig(self.m_cardData.name)

    -- 创建刮刮卡涂层 消息返回时直接移除
    self.m_coatingLayer = self:createGuaGuaLeLayer({
        brushRadius = cardConfig.cardViewBrushRadius,
        rectSize    = cardConfig.cardViewMaskRectSize,
        sp_bg       = util_createSprite(cardConfig.cardViewMaskRes),   
        pos         = nil,   
        onTouch_start = function(obj,event,bInArea)
            self:stopGuideAnim(true)
        end,
        onTouch     = function(obj,event,bInArea)
            if bInArea and not event.isAutoScrape then
                self:changeBackBtnEnable(false)
            end
            self:onTouchCoatingLayer(obj,event,bInArea)
        end,
        onTouch_end = function(obj,event)
            self:changeAutoCoinVisible(false)
            self:stopScrapingCardSound()
        end,
        overFun = function()
            self:coatingOverCallBack()
        end 
    })
    self.m_layerCoating:addChild(self.m_coatingLayer)
    self:setCoatingLayerTouchState(true)
    self:setCoatingLayerUserTouchState(true)
end
function ScratchWinnerBaseCardView:setCoatingLayerTouchState(_bool)
    if not self.m_coatingLayer then
        return
    end
    self.m_coatingLayer.m_canTouch = _bool
end
function ScratchWinnerBaseCardView:setCoatingLayerUserTouchState(_bool)
    if not self.m_coatingLayer then
        return
    end
    self.m_coatingLayer.m_canUserTouch = _bool
end

function ScratchWinnerBaseCardView:coatingOverCallBack()
    -- 移除延时开始自动刮卡逻辑
    self:stopDelayAutoScrape()
    -- 修改一些状态
    self:setCoatingLayerUserTouchState(false)
    self:changeAutoCoinVisible(false)
    self:changeAutoBtnEnable(false)
    self:changeBackBtnEnable(false)
    self:stopGuideAnim(true)
        
    util_afterDrawCallBack(function()
        if tolua.isnull(self) then
            return
        end
        -- 移除涂层
        self:removeCoatingLayer()
        -- 刷新奖励
        globalData.coinsSoundType = -1
        self:recvServerData()
    end)
end
--[[
    参考 GD.util_createGuaGuaLeLayer(params)
    结束条件 {
        分为 row x col 的大矩阵 
        大矩阵内部分为 2 x 2 的小矩阵
        移除划过的小矩阵
        大矩阵内部小矩阵数量低于50% 移除大矩阵
        大矩阵移除超过一定比例 或 自动刮卡结束 开始结算 
    }
    
    参数说明
    {
        brushRadius     --笔刷的半径
        rectSize,       --大矩阵的尺寸
        sp_bg,          --需要刮开的图层
        size,           --需要刮开的区域大小
        pos,            --涂层位置
        onTouch_start,  --触摸开始只进行一次  
        onTouch,        --触摸回调
        onTouch_end,    --触摸结束
        overFun         --刮开结束回调
    }
]]
function ScratchWinnerBaseCardView:createGuaGuaLeLayer(params)  
    local brushRadius  = params.brushRadius   
    local sp_bg        = params.sp_bg  
    local bgSize       = sp_bg:getContentSize()
    local overFun      = params.overFun
    local pos          = params.pos 
    if not pos then
        pos = cc.p(bgSize.width/2, bgSize.height/2)
    end
    

    -- 添加所有矩阵，矩阵列表数量少于一定比例，直接结束
    local rectList = {}
    local maxX = bgSize.width
    local maxY = bgSize.height

    local rectSize   = params.rectSize
    local rectPos    = cc.p(rectSize.width/2, rectSize.height/2)
    local littleRect = cc.size(rectSize.width/2 + 1, rectSize.height/2 + 1)
    
    while rectPos.x < maxX and rectPos.y < maxY do
        -- 以该点为中心添加四个矩阵
        table.insert(rectList, {
            cc.rect(rectPos.x-littleRect.width, rectPos.y, littleRect.width, littleRect.height),
            cc.rect(rectPos.x-littleRect.width, rectPos.y-littleRect.height, littleRect.width, littleRect.height),
            cc.rect(rectPos.x, rectPos.y, littleRect.width, littleRect.height),
            cc.rect(rectPos.x, rectPos.y-littleRect.height, littleRect.width, littleRect.height),
        })
        
        -- 移动到下一个点位 ( 先右移，X越界后 上移一格重置X再右移 )
        rectPos.x = rectPos.x + rectSize.width
        if rectPos.x >= maxX and rectPos.y < maxY then

            rectPos.y = rectPos.y + rectSize.height
            if rectPos.y < maxY then
                rectPos.x = rectSize.width/2
            end

        end
    end
    --大矩阵列表最小数量 结束比例
    local minRectCount = math.floor(#rectList * (1-0.8))

    -- 移除矩阵列表的逻辑
    local fnRemoveRect = function(_rectList, _pos)
        for i=#_rectList,1,-1 do
            local littleRectList = _rectList[i]
            local isRemove = false

            for ii=#littleRectList,1,-1 do
                local littleRect = littleRectList[ii]
                local distance  = math.sqrt(math.pow(littleRect.x + littleRect.width/2 -_pos.x, 2) + math.pow(littleRect.y + littleRect.height/2 -_pos.y, 2))
                if distance <= brushRadius then
                -- if cc.rectContainsPoint(v, _pos) then
                    isRemove = true
                    table.remove(littleRectList, ii)
                end 
            end
            if isRemove then
                if #littleRectList <= 2 then
                    table.remove(_rectList, i)
                end
                break
            end
        end
    end

    local layer = cc.Layer:create()

    local render = cc.RenderTexture:create(display.width, display.height)
    render:setPosition(cc.p(display.width / 2, display.height / 2))
    layer:addChild(render)
    --创建笔刷
    local brush = cc.DrawNode:create()
    brush:retain()  
    brush:drawSolidCircle(cc.p(0, 0), brushRadius, 0, 47,cc.c4f(1, 0, 0, 1))

    sp_bg:setAnchorPoint(cc.p(0.5, 0.5))
    sp_bg:setPosition(pos)

    local spBgRect = sp_bg:getBoundingBox()

    render:begin()
    sp_bg:visit()
    render:endToLua()
      
    local lastPos = nil
    layer.touchFunc = function(obj,event)
        if not layer.m_canTouch then
            return
        end
        -- 玩家不可触摸状态
        if not event.isAutoScrape and not layer.m_canUserTouch then
            return
        end

        local eventPos = cc.p(event.x, event.y)
        local nodePos = layer:convertToNodeSpace(eventPos)

        -- 触摸区域判定
        local bInArea  = cc.rectContainsPoint(spBgRect, nodePos) 

        if event.name == "moved" or 
        event.name == "began" then
            --安全判定
            if not brush then
                release_print("[ScratchWinnerBaseCardView:createGuaGuaLeLayer] GuaGuaLe brush is nil")
                if type(overFun) == "function" then
                    render:setVisible(false)
                    overFun()
                end
                return
            end

            if type(params.onTouch_start) == "function" then
                params.onTouch_start(obj,event,bInArea)
                params.onTouch_start = nil
            end
            if type(params.onTouch) == "function" then
                params.onTouch(obj,event,bInArea)
            end
            


            -- 从上一个点 到 最新的触摸点  间隔过长时需要创建多个刷子
            if nil ~= lastPos then
                local distance = math.floor( math.sqrt(math.pow(nodePos.x-lastPos.x, 2) + math.pow(nodePos.y-lastPos.y, 2)) ) 
                local limiti = brushRadius -- 25
                if distance <= limiti or event.isAutoScrape then
                    brush:setPosition(nodePos)
                else
                    local rotation = util_getAngleByPos(cc.p(lastPos.x, lastPos.y), nodePos)
                    local otherBushRect = {}
                    local otherWidth = brushRadius
                    while distance > limiti do
                        -- 坐标
                        local nextPos  = cc.p( util_getCirclePointPos(lastPos.x, lastPos.y, limiti, rotation) )
                        if not cc.rectContainsPoint(spBgRect, nextPos) then
                            break
                        end
                        -- 和其他刷子重叠了
                        local isSame = false
                        for i,_otherRect in ipairs(otherBushRect)do
                            if cc.rectContainsPoint(_otherRect, nextPos) then
                                isSame = true
                                break
                            end
                        end
                        if not isSame then 
                            -- 创建临时刷子
                            local tempbrush = cc.DrawNode:create() 
                            tempbrush:drawSolidCircle(cc.p(0, 0), otherWidth, 0, 47,cc.c4f(1, 0, 0, 1))
                            tempbrush:setPosition(nextPos)
                            -- 设置混合模式  
                            local blendFunc = { GL_ONE, GL_ZERO }
                            tempbrush:setBlendFunc(blendFunc)
                            -- 将橡皮擦的像素渲染到画布上，与原来的像素进行混合  
                            render:begin()
                            tempbrush:visit()  
                            render:endToLua()
                            -- 加入刷子矩阵
                            local otherRect = cc.rect(nextPos.x-otherWidth/2,nextPos.y-otherWidth/2, otherWidth, otherWidth)
                            table.insert(otherBushRect, otherRect)
                        end
                        
                        --判断关键点是否被刮开
                        fnRemoveRect(rectList, nextPos)

                        lastPos = nextPos
                        distance = math.floor( math.sqrt(math.pow(nodePos.x-nextPos.x, 2) + math.pow(nodePos.y-nextPos.y, 2)))
                    end 
                    
                end
            else
                brush:setPosition(nodePos)
            end
            
            if bInArea then
                lastPos = nodePos
                -- 设置混合模式  
                local blendFunc = { GL_ONE, GL_ZERO }
                brush:setBlendFunc(blendFunc)
                -- 将橡皮擦的像素渲染到画布上，与原来的像素进行混合  
                render:begin()
                brush:visit()
                render:endToLua()
                --判断关键点是否被刮开
                fnRemoveRect(rectList, nodePos)
            end
            
        elseif event.name == "ended" then
            lastPos = nil
            if type(params.onTouch_end) == "function" then
                params.onTouch_end(obj,event)
            end
            
            --判断是否大部分被刮开
            local curRectCount = #rectList
            if curRectCount  <= minRectCount or event.isAutoScrape then
                self:setCoatingLayerTouchState(false)
                render:setVisible(false)
                if type(overFun) == "function" then
                    overFun()
                end
            end
        elseif event.name == "cancelled" then
            if type(params.onTouch_end) == "function" then
                params.onTouch_end(obj,event)
            end
        end

        return true
    end

    layer:onTouch(handler(nil, layer.touchFunc))

    return layer
end
-- 处理一些触摸刮卡区域时的独有表现 --!!!子类自己重写
function ScratchWinnerBaseCardView:onTouchCoatingLayer(_obj, _event, _bInArea)
    if not _event.isAutoScrape then
        self:setAutoState(false)
    end

    self:changeAutoCoinVisible(_bInArea)
    if _bInArea then
        self:changeAutoCoinPos(_event)
        self:playScrapingCardSound(_event)
    end


end
function ScratchWinnerBaseCardView:removeCoatingLayer()
    if self.m_coatingLayer then
        self:stopAutoScrape()

        self.m_coatingLayer:removeFromParent()
        self.m_coatingLayer = nil
    end
end
--[[
    刮卡音效
]]
function ScratchWinnerBaseCardView:playScrapingCardSound(_event)

    -- 没有在播放刮卡音效 or 切换了刮卡模式
    if nil == self.m_scrapingCardSoundId then
        self.m_scrapingCardSoundId = gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_ScrapingCard)

        -- 下一次可以播放的时间
        self.m_soundNode:stopAllActions()
        local soundTime = 2
        performWithDelay(self.m_soundNode,function()
            self.m_scrapingCardSoundId   = nil
        end, soundTime)
    end
end
function ScratchWinnerBaseCardView:stopScrapingCardSound()
    if nil ~= self.m_scrapingCardSoundId then
        gLobalSoundManager:stopAudio(self.m_scrapingCardSoundId)
        self.m_scrapingCardSoundId = nil
    end
end
--[[
    连线效果 遮罩提层
]]
function ScratchWinnerBaseCardView:recvServerData()
    -- 赢钱
    local winCoins = ScratchWinnerShopManager:getInstance():getCardWinCoinsByIndex(self.m_cardData.index, nil)
    --顶栏金币
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    --连线逻辑
    self:showLineFrame(winCoins)
end
function ScratchWinnerBaseCardView:showLineFrame(_winCoins)
    -- 压暗
    self:showDark(_winCoins > 0)

    if _winCoins > 0 then
        -- 连线效果
        self:playInLineNodes()

        -- jackpot
        local isJackpot = self:isTriggerJackpot()
        if isJackpot then
            self:showJackpotLineEffect(_winCoins)
        else
            -- 底栏跳钱
            self.m_machine:updateBottomUICoins(0, _winCoins, nil, true)

            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(waitNode,function()
                -- 这一块逻辑在jackpot里面要一致
                if WinType.Normal ~= self.m_machine:isTriggerScratchWinnerBigWin(_winCoins) then
                    self:stopLineSound()
                end
                self.m_machine:showScratchWinnerBigWinView(_winCoins, function()
                    self:showPanelWait(2, function()
                        self:endCardGame()
                    end)
                end)
                -- 这一块逻辑在jackpot里面要一致 end
                waitNode:removeFromParent()
            end, 1)
        end
    else
        self:showPanelWait(1, function()
            self:endCardGame()
        end)
    end
end
function ScratchWinnerBaseCardView:showJackpotLineEffect(_winCoins)
    self:playJackpotLineSound()
    
    --播放金币喷射
    local time = self:playJackpotCoinEffect()
    local delayTime = util_max(2, time)
    --延时一个最大时间
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        --播放jackpot栏闪光
        self.m_jackpotUi:runCsbAction("actionframe", true)
        --展示jackpot弹板
        self.m_machine:showJackpotView(self.m_cardData, self.m_bAutoAllState,function()
            self:hideJackpotCoinEffect()
            self.m_jackpotUi:runCsbAction("idle", true)
            -- 底栏跳钱
            self.m_machine:updateBottomUICoins(0, _winCoins, nil, true)
            -- 这一块逻辑在base赢钱里面要一致
            if WinType.Normal ~= self.m_machine:isTriggerScratchWinnerBigWin(_winCoins) then
                self:stopLineSound()
            end
            self.m_machine:showScratchWinnerBigWinView(_winCoins, function()
                self:showPanelWait(2, function()
                    self:endCardGame()
                end)
            end)
            -- 这一块逻辑在base赢钱里面要一致 end
        end) 

        waitNode:removeFromParent()
    end, delayTime)
end
function ScratchWinnerBaseCardView:playJackpotLineSound()
    gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_CardView_TriggerJackpot)
end
function ScratchWinnerBaseCardView:playInLineNodes()
    -- 加入连线列表
    local allLinePos     = {}
    for i,v in ipairs(self.m_cardData.lines) do
        for ii,_reelPos in ipairs(v.icons) do
            local reelPos = _reelPos+1
            allLinePos[reelPos] = true
        end
    end
    -- 计算最大连线时间
    local lineMaxTime = 0
    local symbolList = self.m_reelsSymbolList
    for _reelPos,v in pairs(allLinePos) do
        local symbol = symbolList[_reelPos]
        lineMaxTime = util_max(lineMaxTime, symbol:getAniamDurationByName(symbol:getLineAnimName()))
    end

    self.m_lineBgSoundsId = gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_CardView_LineBg)
    local isJackpot = self:isTriggerJackpot()
    if not isJackpot then
        local keyName   = string.format("Sound_CardView_Line_%d", math.random(1, 3))
        local soundName =  ScratchWinnerMusicConfig[keyName]
        self.m_lineSoundsId   = gLobalSoundManager:playSound(soundName)
    end
    
    local lineFrameIndex = 0
    --超过一条线开始执行循环播放
    if #self.m_cardData.lines > 1 then
        local lineFrameNode  = self:findChild("reelSpecial")
        self:stopLineFrameUpDate()
        self:playInLineNodesByIndex(lineFrameIndex)
        self.m_upDateLineFrame = schedule(lineFrameNode, function()
            lineFrameIndex = lineFrameIndex >= #self.m_cardData.lines and 0 or lineFrameIndex+1
            self:playInLineNodesIdle()
            self:playInLineNodesByIndex(lineFrameIndex)
        end, lineMaxTime)
    else
        self:playInLineNodesByIndex(lineFrameIndex)
    end
    
end
function ScratchWinnerBaseCardView:stopLineSound()
    if self.m_lineBgSoundsId then
        gLobalSoundManager:stopAudio(self.m_lineBgSoundsId)
        self.m_lineBgSoundsId = nil
    end
    if self.m_lineSoundsId then
        gLobalSoundManager:stopAudio(self.m_lineSoundsId)
        self.m_lineSoundsId = nil
    end
end
function ScratchWinnerBaseCardView:playInLineNodesByIndex(_lineIndex)
    local allLinePos     = {}
    local lineData = self.m_cardData.lines[_lineIndex]
    -- 全体连线
    if not lineData then
        allLinePos = self:getFirstLinePosList()
    -- 单条连线
    else
        for i,_reelPos in ipairs(lineData.icons) do
            local reelPos = _reelPos+1
            allLinePos[reelPos] = true
        end
    end
    
    local symbolList = self.m_reelsSymbolList
    for _reelPos,v in pairs(allLinePos) do
        local symbol = symbolList[_reelPos]
        if nil ~= symbol then
            self:changeReelSymbolOrder(symbol, true)
            symbol:runLineAnim() 
        end
    end
end
function ScratchWinnerBaseCardView:stopLineFrameUpDate()
    if nil ~= self.m_upDateLineFrame then
        self.m_upDateLineFrame = nil
        self:findChild("reelSpecial"):stopAllActions()
    end
end
function ScratchWinnerBaseCardView:playInLineNodesIdle()
    local allLinePos     = {}
    for i,v in ipairs(self.m_cardData.lines) do
        for ii,_reelPos in ipairs(v.icons) do
            local reelPos = _reelPos+1
            allLinePos[reelPos] = true
        end
    end

    local symbolList = self.m_reelsSymbolList
    for _reelPos,v in pairs(allLinePos) do
        local symbol = symbolList[_reelPos]
        if nil ~= symbol then
            self:changeReelSymbolOrder(symbol, false)
            symbol:runIdleAnim() 
        end
    end
end
--获取全体连线时的位置列表 有jackpot时 只返回jackpot连线
function ScratchWinnerBaseCardView:getFirstLinePosList()
    local allLinePos     = {}

    local isJackpot = self:isTriggerJackpot()
    if isJackpot then
        for i,v in ipairs(self.m_cardData.lines) do
            if "jackpot" == v.kind then
                for ii,_reelPos in ipairs(v.icons) do
                    local reelPos = _reelPos+1
                    allLinePos[reelPos] = true
                end
            end
        end
    else
        for i,v in ipairs(self.m_cardData.lines) do
            for ii,_reelPos in ipairs(v.icons) do
                local reelPos = _reelPos+1
                allLinePos[reelPos] = true
            end
        end
    end

    return allLinePos
end

function ScratchWinnerBaseCardView:isTriggerJackpot()
    if not self.m_cardData then
        return false
    end

    for i,v in ipairs(self.m_cardData.lines) do
        if "jackpot" == v.kind then
            return true
        end
    end
    return false
end
function ScratchWinnerBaseCardView:changeReelSymbolOrder(_reelSymbol, _bSpecial)
    local parent = self:findChild("reel")
    local parentLight = self:findChild("reelSpecial")

    local nextParent = _bSpecial and parentLight or parent
    local pos = util_convertToNodeSpace(_reelSymbol, nextParent)
    util_changeNodeParent(nextParent, _reelSymbol)
    _reelSymbol:setPosition(pos)
end
function ScratchWinnerBaseCardView:showDark(_bWinCoin)
    self.m_panelReel:setVisible(true)
    if not _bWinCoin then
        local time    = 21/60
        local opacity = 255 * 0.5
        self.m_panelReel:setOpacity(0)
        self.m_panelReel:runAction(cc.FadeTo:create(time, opacity))
    end
end
function ScratchWinnerBaseCardView:hideDark()
    self.m_panelReel:setVisible(false)
    -- self.m_panelReel:runAction( 
    --     cc.Sequence:create(
    --         cc.FadeOut:create(0.5), 
    --         cc.CallFunc:create(function()
    --             self.m_panelReel:setVisible(false)
    --         end)
    --     ) 
    -- )
end

--[[
    卡片在开始游戏和结束游戏的时间线
]]
function ScratchWinnerBaseCardView:playCardStartAnim()
    self:runCsbAction("idle", false)
end
function ScratchWinnerBaseCardView:playCardOverAnim(_fun)
    gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_CardView_Over_Fly)

    util_setCascadeOpacityEnabledRescursion(self, true)
    self:runCsbAction("over", false, function()
        self:hideDark()
        
        if "function" == type(_fun) then
            _fun()
        end
    end)

    return 30/60
end
--[[
    等待遮罩
]]
function ScratchWinnerBaseCardView:resetPanelWait()
    self.m_panelWaitClickCallBack = nil
    self.m_panelWait:setVisible(false)
end
function ScratchWinnerBaseCardView:showPanelWait(_delayTime,_fun)
    self.m_panelWaitClickCallBack = _fun
    self.m_panelWait:setVisible(true)

    --2s后自动执行下一步
    performWithDelay(self.m_panelWait,function()
        self:onPanelWaitClick()
    end, _delayTime)
end
function ScratchWinnerBaseCardView:onPanelWaitClick()
    self.m_panelWait:stopAllActions()
    if "function" == type(self.m_panelWaitClickCallBack) then
        self.m_panelWaitClickCallBack()
        self.m_panelWaitClickCallBack = nil
    end
    self:resetPanelWait()
end


return ScratchWinnerBaseCardView