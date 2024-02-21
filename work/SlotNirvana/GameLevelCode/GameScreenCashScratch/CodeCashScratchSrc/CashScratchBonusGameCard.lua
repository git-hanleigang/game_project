---
--xcyy
--2018年5月23日
--CashScratchBonusGameCard.lua

local SendDataManager = require "network.SendDataManager"
local CashScratchBonusGameCard = class("CashScratchBonusGameCard",util_require("Levels.BaseLevelDialog"))

CashScratchBonusGameCard.COUNTDOWN_TIME = 4

function CashScratchBonusGameCard:onExit()
    CashScratchBonusGameCard.super.onExit(self)

    self:stopCountDown()
    self:stopAutoScrape()
    self:stopGuideAnim()
    self:stopScrapingCardSound()
end

function CashScratchBonusGameCard:initDatas(_machine)
    self.m_machine  = _machine

    self:resetCountDownTime()
end
-- 通用的ui放在这里，逻辑相关的控件放在下面
function CashScratchBonusGameCard:initUI()
    self:createCsbNode("CashScratch_card.csb")
end

function CashScratchBonusGameCard:initMainCardUi()
    self.m_dark = util_createAnimation("CashScratch_card_patterns_dark.csb") 
    self:findChild("dark"):addChild(self.m_dark)
    self.m_dark:setVisible(false)

    self:findChild("sp_coin"):setLocalZOrder(10)

    for _panelIndex=1,4 do
        local panel = self:findChild(string.format("Panel_%d",_panelIndex))
        panel:setLocalZOrder(10)
    end

    self:initIconList()

    self:createJackpotAnim()

    self.m_guideSpine = util_spineCreate("CashScratch_Xinshou",true,true)
    self:findChild("xinshou"):addChild(self.m_guideSpine)
    self.m_guideSpine:setVisible(false)


    self.m_soundNode = cc.Node:create()
    self:addChild(self.m_soundNode)
end
function CashScratchBonusGameCard:initCardData(_cardData)
    self:setCardData(_cardData)
    self:changeCardByType(_cardData.symbolType)
    self:resetCoatingLayer()
    self:resetIconList()
end
--[[
    cardData = {
        cardIndex       = 1,
        iPos            = 0,
        symbolType      = 0,
        winCoin         = 0,
        winSymbolType   = {0}, 
        icon            = {0,0,0 ,0,0,0 ,0,0,0},
    }
]]
function CashScratchBonusGameCard:setCardData(_cardData)
    self.m_cardData = _cardData
end

-- 玩法开始
function CashScratchBonusGameCard:startCardGame(_fun)
    self.m_endFun   = _fun
    self.m_canTouch = true

    self:changeAutoBtnEnable(true)
    -- 播放引导
    self:playGuideAnim()
    -- 倒计时
    if 1 == self.m_cardData.cardIndex then
        self:resetCountDownTime()
    end
    self:startCountDown()
    self:updateMaxWinCoins()
end
-- 玩法结束
function CashScratchBonusGameCard:endCardGame()
    self.m_endFun()
end






-- 刷新卡片类型展示
function CashScratchBonusGameCard:changeCardByType(_symbolType)
    local bonus1Bg = self:findChild("card_0x")
    local bonus2Bg = self:findChild("card_2x")
    local bonus3Bg = self:findChild("card_3x")
    local bonus4Bg = self:findChild("card_5x")
    local bonus5Bg = self:findChild("card_nx_5")
    
    bonus1Bg:setVisible(_symbolType == self.m_machine.SYMBOL_Bonus_1)
    bonus2Bg:setVisible(_symbolType == self.m_machine.SYMBOL_Bonus_2)
    bonus3Bg:setVisible(_symbolType == self.m_machine.SYMBOL_Bonus_3)
    bonus4Bg:setVisible(_symbolType == self.m_machine.SYMBOL_Bonus_4)
    bonus5Bg:setVisible(_symbolType == self.m_machine.SYMBOL_Bonus_5)
end
--[[
    jackpot中奖展示
]]
function CashScratchBonusGameCard:createJackpotAnim()
    if nil ~= self.m_zhongjiang then
        return
    end
    self.m_zhongjiang = util_createAnimation("CashScratch_card_zhongjiang.csb") 
    self:findChild("zhongjiang"):addChild(self.m_zhongjiang)
    util_setCsbVisible(self.m_zhongjiang, false)
end
function CashScratchBonusGameCard:playJackpotAnim()
    util_setCsbVisible(self.m_zhongjiang, true)
    self.m_zhongjiang:runCsbAction("actionframe", true)
end
function CashScratchBonusGameCard:hideJackpotAnim()
    util_setCsbVisible(self.m_zhongjiang, false)
end
--[[
    icon列表 相关
]]
-- 初始化
function CashScratchBonusGameCard:initIconList()
    local parent = self:findChild("patterns")

    self.m_iconList = {}
    for i=0,8 do
        local icon = util_createView("CodeCashScratchSrc.CashScratchBonusGameIcon")
        local iconPosNode = self:findChild( string.format("s_%d", i) ) 
        parent:addChild(icon)
        icon:setPosition( util_convertToNodeSpace(iconPosNode, parent) )
        table.insert(self.m_iconList, icon)
    end
end
-- 重置
function CashScratchBonusGameCard:resetIconList()
    local iconData = self.m_cardData.icon

    for _index,_icon in ipairs(self.m_iconList) do
        local initData = {
            machine = self.m_machine,
            symbolType = iconData[_index],
        }
        initData.iconType = self:getBonusIconType(self.m_cardData.symbolType,iconData[_index])

        _icon:setInitData(initData)
        _icon:upDateAnimNode()
        _icon:upDateIconShow()
    end
end
-- 根据不同的卡片转换一下信号
function CashScratchBonusGameCard:getBonusIconType(_cardType, _iconType)
    local iconType = _iconType

    -- 是否需要转换图标的信号类型
    if self.m_machine:checkCashScratchABTest() then
        local bonusIndex = self.m_machine:getCashScratchBonusSymbolIndex(_cardType)
        if (self.m_machine.SYMBOL_BONUSCARD_Watermelon <= _iconType and  _iconType <= self.m_machine.SYMBOL_BONUSCARD_Cherry ) 
            and bonusIndex > 1 then
            iconType = _iconType + (bonusIndex-1)*100
        end
    end

    return iconType
end

-- 连线
function CashScratchBonusGameCard:showIconListLineAnim(_winSymbolList, _winIndex)
    -- 乘倍信号
    local multSymbolList = {
        [self.m_machine.SYMBOL_BONUSCARD_2x] = true,
        [self.m_machine.SYMBOL_BONUSCARD_3x] = true,
        [self.m_machine.SYMBOL_BONUSCARD_5x] = true,
    }
    local newWinSymbolList = {}
    -- 插入赢钱信号 
    for i,_winSymbolType in ipairs(_winSymbolList) do
        newWinSymbolList[_winSymbolType] = true
    end

    for i,_icon in ipairs(self.m_iconList) do

        local bLine    = false
        local lineName = 6 == _winIndex and  "actionframe2" or "actionframe"
        if newWinSymbolList[_icon.m_initData.symbolType] or multSymbolList[_icon.m_initData.symbolType] then
            bLine = true
        end

        self:changeIconOrder(_icon, bLine)

        if bLine then
            _icon:setLineAnimName(lineName)
            _icon:runLineAnim()
        end
        
    end
end
-- 切换高亮层级
function CashScratchBonusGameCard:changeIconOrder(_icon, _isLight)
    local parent = self:findChild("patterns")
    local parentLight = self:findChild("patternsLight")

    local nextParent = _isLight and parentLight or parent
    local pos = util_convertToNodeSpace(_icon, nextParent)
    util_changeNodeParent(nextParent, _icon)
    _icon:setPosition(pos)
end

--[[
    刮刮卡遮罩
]]
function CashScratchBonusGameCard:showDark()
    self.m_dark:setVisible(true)
    self.m_dark:runCsbAction("start")
end
function CashScratchBonusGameCard:hideDark()
    self.m_dark:setVisible(false)
end

--刷新 最大赢钱
function CashScratchBonusGameCard:updateMaxWinCoins(_cardData)
    if not self.m_machine then
        return
    end
    local cardData = _cardData or self.m_cardData

    local value = self.m_machine:getBonusCardWinUpCoins(cardData)

    local labMaxCoin = self:findChild("m_lb_coins")
    local info  = {label = labMaxCoin, sx = 1, sy = 1, width = 230}
    info.label:setString(util_formatCoins(value,20,nil,nil,true))
    self:updateLabelSize(info, info.width)
end

--[[
    默认按钮监听回调
]] 
function CashScratchBonusGameCard:clickFunc(sender)
    if not self.m_canTouch then
        return
    end

    local name = sender:getName()

    if name == "Button_auto" then
        self:stopGuideAnim(true)
        self:startAutoScrape()
        self.m_countDown = 0
    end
end

--[[
    数据发送返回
]] 
function CashScratchBonusGameCard:sendData()
    self.m_canTouch = false

    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {
        msg = MessageDataType.MSG_BONUS_SELECT,
        data = {
        }
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--数据接收 bonusGame接收到消息回传过来
function CashScratchBonusGameCard:recvBaseData(result)
    local bonus = result.bonus or {}
    local extra = bonus.extra
    if extra then
        self:endCardGame()
    end
end

function CashScratchBonusGameCard:showLineAnim()
    -- 移除涂层
    self:removeCoatingLayer()
    -- 展示 连线 | 遮罩
    local cardIndex      = self.m_cardData.cardIndex
    local cardSymbolType = self.m_cardData.symbolType
    local winSymbolType  = self.m_cardData.winSymbolType
    local winIndex = self.m_machine:getRightPaytableWinIndex(winSymbolType)
    if 6 == winIndex then
        gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_bonusGame_winCoin_jackpot.mp3")
    else
        gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_bonusGame_winCoin.mp3")
    end
    self.m_machine:showRightPaytableLineAnim(cardIndex+1,cardSymbolType, winIndex, function()
        self:hideJackpotAnim()
        self:sendData()
    end)
    self:showDark()
    self:showIconListLineAnim(winSymbolType, winIndex)
    -- jackpot动效
    local triggerJackpot = 6 == winIndex
    if triggerJackpot then
        self:playJackpotAnim()
    end
end
-- 隐藏连线动画展示
function CashScratchBonusGameCard:hideLineAnim()
    -- over 0 ~ 20
    -- over的第18帧切掉 高亮、遮罩、paytable
    self.m_machine:levelPerformWithDelay(18/60, function()
        self.m_machine:setRightPaytableWinLineVisible(0)

        self:hideDark()
        for i,_icon in ipairs(self.m_iconList) do
            _icon:hideLightAnim()
            self:changeIconOrder(_icon, false)
        end
    end)
end
--[[
    刮卡音效
]]
function CashScratchBonusGameCard:playScrapingCardSound(_event)
    local soundName = ""
    if _event.isAutoScrape then
        soundName = "CashScratchSounds/sound_CashScratch_autoScrapingCard.mp3"
    else
        soundName = "CashScratchSounds/sound_CashScratch_scrapingCard.mp3"
    end

    -- 没有在播放刮卡音效 or 切换了刮卡模式
    if nil == self.m_scrapingCardSoundId or soundName ~= self.m_scrapingCardSoundName then
        if soundName ~= self.m_scrapingCardSoundName then
            self:stopScrapingCardSound()
        end   

        self.m_scrapingCardSoundId = gLobalSoundManager:playSound(soundName)
        self.m_scrapingCardSoundName = soundName     

        -- 下一次可以播放的时间
        self.m_soundNode:stopAllActions()
        local soundTime = _event.isAutoScrape and 3 or 0.5
        performWithDelay(self.m_soundNode,function()
            self.m_scrapingCardSoundId   = nil
            self.m_scrapingCardSoundName = nil
        end, soundTime)
    end
end
function CashScratchBonusGameCard:stopScrapingCardSound()
    if nil ~= self.m_scrapingCardSoundId then
        gLobalSoundManager:stopAudio(self.m_scrapingCardSoundId)
        self.m_scrapingCardSoundId = nil
        self.m_scrapingCardSoundName = nil
    end
end
--[[
    刮卡引导

    只有首张卡片播放引导
]]
function CashScratchBonusGameCard:playGuideAnim()
    if 1 ~= self.m_cardData.cardIndex then
        return
    end

    self.m_guideSpine:setVisible(true)

    local intervalTime = 60/30
    self:stopGuideAnim()

    util_spinePlay(self.m_guideSpine, "idleframe", false)
    self.m_updateGuideAction = schedule(self.m_guideSpine,function()
        util_spinePlay(self.m_guideSpine, "idleframe", false)
    end, intervalTime)
end
function CashScratchBonusGameCard:stopGuideAnim(_hide)
    if self.m_updateGuideAction then
        self.m_guideSpine:stopAction(self.m_updateGuideAction)
        self.m_updateGuideAction = nil

        if _hide then
            self.m_guideSpine:setVisible(false)
        end
    end
end

--[[
    自动刮卡
]]
-- 倒计时
function CashScratchBonusGameCard:resetCountDownTime()
    self.m_countDown = self.COUNTDOWN_TIME
end
function CashScratchBonusGameCard:startCountDown()
    self:stopCountDown()

    local countDownNode = self:findChild("Node_downCoatingLayer") 
    
    local interval = 1
    self.m_upDateCountDown = schedule(countDownNode, function()
        self.m_countDown = self.m_countDown - 1
        if self.m_countDown <= 0 then
            self:startAutoScrape()
        end
    end, interval)
end
function CashScratchBonusGameCard:stopCountDown()
    if nil ~= self.m_upDateCountDown then
        self:findChild("Node_downCoatingLayer"):stopAction(self.m_upDateCountDown)
        self.m_upDateCountDown = nil
    end
end
-- 刮卡
function CashScratchBonusGameCard:startAutoScrape()
    local coatingLayer = self.m_downCoatingLayer
    if not coatingLayer or self.m_autoScrapeAction then
        return
    end

    local parent    = coatingLayer:getParent()
    local touchFunc = coatingLayer.touchFunc
    local distance  = 30
    local startPos  = parent:convertToWorldSpace(cc.p(0, 0))

    -- 拿一条路径
    local pathIndex = 1
    local path = self:getAutoScrapePath()


    local eventData = {
        isAutoScrape = true,
        name = "began",
        x = startPos.x + path[pathIndex].x, 
        y = startPos.y + path[pathIndex].y,
    }
    touchFunc(nil, eventData)

    self.m_autoScrapeAction = schedule(coatingLayer, function()
        local targetData = path[pathIndex+1]
        local targetPos  = cc.p(startPos.x + targetData.x, startPos.y + targetData.y)
        local rotation = util_getAngleByPos(cc.p(eventData.x, eventData.y), targetPos)
        local surplusDistance = math.sqrt(math.pow(targetPos.x-eventData.x, 2) + math.pow(targetPos.y-eventData.y, 2))
        
        if surplusDistance <= distance then
            pathIndex = pathIndex + 1

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
    end,0.015)
end
function CashScratchBonusGameCard:stopAutoScrape()
    if self.m_autoScrapeAction and self.m_downCoatingLayer then
        self.m_downCoatingLayer:stopAction(self.m_autoScrapeAction)
        self.m_autoScrapeAction = nil
    end
end
-- 返回一条路线
function CashScratchBonusGameCard:getAutoScrapePath()
    local pathList = {
        -- 左上 -> 右下 （稍微内敛一些）
        {
            cc.p(45, 175),cc.p(125, 220),
            cc.p(190, 220),cc.p(45, 130),

            cc.p(45, 85),cc.p(255, 220),
            cc.p(320, 220),cc.p(45, 40),

            cc.p(125, 40),cc.p(320, 175),
            cc.p(320, 130),cc.p(190, 40),

            cc.p(320, 40),cc.p(320, 40),
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
-- 自动刮卡按钮
function CashScratchBonusGameCard:changeAutoBtnEnable(_enable)
    local btnAuto = self:findChild("Button_auto")
    btnAuto:setEnabled(_enable)
end
-- 刮卡硬币
function CashScratchBonusGameCard:changeAutoCoinVisible(_visible)
    local spCoin = self:findChild("sp_coin")
    spCoin:setVisible(_visible)
end
function CashScratchBonusGameCard:changeAutoCoinPos(_event)
    local spCoin = self:findChild("sp_coin")
    local spCoinSize = spCoin:getContentSize()
    local pos = spCoin:getParent():convertToNodeSpace( cc.p(_event.x, _event.y) ) 
    spCoin:setPosition(pos)
end
--------------------- 涂层相关
-- 重置 涂层
function CashScratchBonusGameCard:resetCoatingLayer()
    self:removeCoatingLayer()

    -- 创建刮刮卡涂层 消息返回时直接移除
    self.m_downCoatingLayer = self:createGuaGuaLeLayer({
        sp_reward   = nil,
        sp_bg       = util_createSprite("common/CashScratch_card_hui.png"),   
        size        = nil,  
        pos         = nil,       
        onTouch     = function(obj,event,bInArea)
            if not event.isAutoScrape then
                self:resetCountDownTime()
                self:stopAutoScrape()
            end
            if bInArea then
                if event.name == "moved" then
                    self:playScrapingCardSound(event)
                end
            end

            if event.name == "began" then
                self:changeAutoBtnEnable(false)
                self:changeAutoCoinVisible(true)
            end
            self:changeAutoCoinPos(event)
        end,
        onTouch_end = function(obj,event)
            self:changeAutoBtnEnable(true)
            self:changeAutoCoinVisible(false)
            self:stopScrapingCardSound()
        end,
        startFunc = function (bInArea)
            self:stopGuideAnim(true)
        end,
        callBack = function()
            if not tolua.isnull(self) then
                self:changeAutoCoinVisible(false)
                self:showLineAnim()
            end
        end 
    })
    self:findChild("Node_downCoatingLayer"):addChild(self.m_downCoatingLayer)
    self.m_downCoatingLayer.m_canTouch = true
end
--[[
    参考 GD.util_createGuaGuaLeLayer(params)
    修改一下结束条件 {
        分为 3 x 3 的大矩阵 全部移除才算结束
        移除划过的矩阵方块
    }
    
    参数说明
    {
        sp_reward,      --需要刮出来的奖励精灵
        sp_bg,          --需要刮开的图层
        size,           --需要刮开的区域大小
        pos,            --涂层位置
        onTouch,        --触摸回调
        onTouch_end,    --触摸结束
        startFunc,      --开始刮开
        callBack        --刮开结束回调
    }
]]
function CashScratchBonusGameCard:createGuaGuaLeLayer(params)
    -- getReferenceCount
    --需要刮出来的奖励精灵
    local sp_reward     = params.sp_reward      
    --需要刮开的图层
    local sp_bg         = params.sp_bg  
    --需要刮开的区域大小            
    local rewardSize    = params.size          
    local callBack      = params.callBack
    local pos           = params.pos 

    if not rewardSize then
        rewardSize = sp_bg:getContentSize()
    end
    if not pos then
        pos = cc.p(rewardSize.width/2, rewardSize.height/2)
    end
    

    -- 添加所有矩阵，矩阵列表数量少于一定比例，直接结束
    local rectList = {}
    local maxX = rewardSize.width
    local maxY = rewardSize.height

    local rectSize   = cc.size(maxX/3, maxY/3)
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
    -- 移除矩阵列表的逻辑
    local fnRemoveRect = function(_rectList, _pos)
        for i=#_rectList,1,-1 do
            local littleRectList = _rectList[i]
            local isRemove = false

            for ii,v in ipairs(littleRectList) do
                if cc.rectContainsPoint(v, _pos) then
                    isRemove = true
                    table.remove(littleRectList, ii)
                    break
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

    if nil ~= sp_reward then
        sp_reward:setAnchorPoint(cc.p(0.5, 0.5));  
        sp_reward:setPosition(pos);  
        layer:addChild(sp_reward)
    end
    
    local render = cc.RenderTexture:create(display.width, display.height)
    render:setPosition(cc.p(display.width / 2, display.height / 2))
    layer:addChild(render)
    --创建笔刷
    local brush = cc.DrawNode:create()
    -- render:addChild(brush) 
    brush:retain()  
    brush:drawSolidCircle(cc.p(0, 0), 30, 0, 47,cc.c4f(1, 0, 0, 1))

    sp_bg:setAnchorPoint(cc.p(0.5, 0.5))
    sp_bg:setPosition(pos)

    local spBgRect = sp_bg:getBoundingBox()
    -- 存一些变量到layer上
    layer.m_bgSize    = sp_bg:getContentSize()
    layer.m_bgPos     = pos

    render:begin()
    sp_bg:visit()
    render:endToLua()
      
    local lastPos = nil
    layer.touchFunc = function(obj,event)
        if not self.m_canTouch or not layer.m_canTouch then
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
                release_print("[CashScratchBonusGameCard:createGuaGuaLeLayer] GuaGuaLe brush is nil")
                if type(callBack) == "function" then
                    render:setVisible(false)
                    callBack()
                end
                return
            end
    
            if type(params.startFunc) == "function" then
                params.startFunc(bInArea)
                params.startFunc = nil
            end
            if type(params.onTouch) == "function" then
                params.onTouch(obj,event,bInArea)
            end

            

            -- 从上一个点 到 最新的触摸点  间隔过长时需要创建多个刷子
            if nil ~= lastPos then
                local distance = math.floor( math.sqrt(math.pow(nodePos.x-lastPos.x, 2) + math.pow(nodePos.y-lastPos.y, 2)) ) 
                local limiti = 25
                if distance <= limiti or event.isAutoScrape then
                    brush:setPosition(nodePos)
                else
                    local rotation = util_getAngleByPos(cc.p(lastPos.x, lastPos.y), nodePos)
                    local otherBushRect = {}
                    local otherWidth = 30
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
            if curRectCount  <= 0 or event.isAutoScrape then
                layer.m_canTouch = false
                render:setVisible(false)
                if type(callBack) == "function" then
                    -- callBack()
                    util_afterDrawCallBack(callBack)
                end
            end
        end
        return true
    end

    layer:onTouch(handler(nil, layer.touchFunc))

    return layer
end
function CashScratchBonusGameCard:removeCoatingLayer()
    if self.m_downCoatingLayer then
        self:stopCountDown()
        self:stopAutoScrape()

        self.m_downCoatingLayer:removeFromParent()
        self.m_downCoatingLayer = nil
    end
end


return CashScratchBonusGameCard