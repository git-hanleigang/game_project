--[[
    飞界面金币  
]]
local GameCoinFlyView = class("GameCoinFlyView", util_require("base.BaseView"))

GameCoinFlyView.m_layerColor = nil
GameCoinFlyView.m_topCoinUI = nil
GameCoinFlyView.m_bAddCoinUI = nil
GameCoinFlyView.m_startEffect = nil
GameCoinFlyView.m_startEffectNode = nil

GameCoinFlyView.m_endPos = nil
GameCoinFlyView.m_viewActions = nil

GameCoinFlyView.m_bHorizontalScreen = nil
GameCoinFlyView.m_bSelfEndPos = nil
GameCoinFlyView.m_bRotation = nil
GameCoinFlyView.m_bCoinUIRotation = nil
GameCoinFlyView.m_bShowSelfCoins = nil

-- local DEFAULT_FLY_TIME = 63 / 30            --金币飞行时间
local DEFAULT_INTERVAL_FLY_TIME = 0.04 --金币之间间隔
local DEFAULT_COIN_COUNT = 30 --金币默认数量
local DEFAULT_DELAYFLYTIME = 0 --开始飞金币前默认延迟时间
local DEFAULT_DELAYREMOVETIME = 1 --全部金币飞到金币条之后 默认延迟移除GameCoinFlyView时间
local DEFAULT_COIN_CALE = 1.2 --金币放大倍数
local DEFAULT_START_COIN_CALE = 0.8 --金币放大倍数
local DEFAULT_RANDOM_TIMELINE_COUNT = 8 --随机金币时间线个数

local DEFAULT_MIN_DIS_X = 100
local MAX_COIN_SCALE = 1.7 --金币放大倍数

local DEBUG_MODE_FLY_COINS = false --测试模式 从点击点飞金币

function GameCoinFlyView:initUI()
    self.m_viewActions = nil
    self.m_bHorizontalScreen = nil
    self.m_bSelfEndPos = nil
    self.m_bRotation = nil
    self.m_bCoinUIRotation = nil
    self.m_bShowSelfCoins = nil
end

--------------------------------------------------------------------------------------------------------------------------------
--灰色遮罩
function GameCoinFlyView:addLayerColor(c4fColor)
    if self.m_layerColor then
        return
    end
    local c4f = cc.c4f(0, 0, 0, 200)
    if c4fColor then
        c4f = c4fColor
    end
    local size = {width = display.width, height = display.height}
    self.m_layerColor = cc.LayerColor:create(cc.c4f(0, 0, 0, 200), size.width, size.height)
    self:addChild(self.m_layerColor, -1)

    if DEBUG_MODE_FLY_COINS then
        local function onTouchBegan(touch, event)
            return true
        end
        local function onTouchEnded(touch, event)
            -- local pos = self:convertToNodeSpaceAR(touch:getLocation())

            self.test[1] = touch:getLocation()
            self:pubPlayFlyCoin(self.test[1], self.test[2], self.test[3], self.test[4], self.test[5], self.test[6], self.test[7])
        end
        local function onTouchCancelled(touch, event)
        end
        local function onTouchMoved(touch, event)
        end

        local listener1 = cc.EventListenerTouchOneByOne:create()
        listener1:setSwallowTouches(true)
        listener1:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
        listener1:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
        listener1:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
        listener1:registerScriptHandler(onTouchCancelled, cc.Handler.EVENT_TOUCH_CANCELLED)
        local eventDispatcher = self.m_layerColor:getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, self.m_layerColor)
    end
end

--创建金钱lable
function GameCoinFlyView:createGameTopCoinUI(posCoinUI, baseCoinValue)
    if not self.m_bAddCoinUI then
        -- csc 2022-02-16 新版商城需要做判断， 如果有商城界面的情况下，用新的协议
        if gLobalViewManager:getViewByExtendData("ZQCoinStoreLayer") then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWSHOP_UP_COIN_LABEL, self)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UP_COIN_LABEL, self)
        end
    else
        if self.m_topCoinUI then
            return
        end

        self.m_topCoinUI = util_createView("views.lobby.GameTopCoinUI", self.m_bHorizontalScreen, self.m_bCoinUIRotation)

        self.m_topCoinUI:setPosition(posCoinUI)
        self:addChild(self.m_topCoinUI)
        -- self.m_topCoinUI:setVisible(false)
        --这里使用总钱-奖励的钱
        self.m_topCoinUI:updateUI(baseCoinValue)
    end
end

--播放收集金币时动画
function GameCoinFlyView:playCollectAction()
    local node, csbAct = util_csbCreate("Lobby/FlyCoins_guanghuan.csb")
    self:addChild(node)
    node:setPosition(self.m_endPos)
    util_csbPlayForKey(
        csbAct,
        "actionframe",
        false,
        function()
            node:removeFromParent()
        end
    )
end

--创建金币出现时漩涡动画
function GameCoinFlyView:createStartEffect(posEffect)
    if self.m_startEffectNode then
        self.m_startEffectNode:setPosition(posEffect)
        return
    end

    local node, csbAct = util_csbCreate("Lobby/FlyCoins_longjuanfeng_2.csb")
    self.m_startEffect = csbAct
    self.m_startEffectNode = node
    self:addChild(node)
    node:setPosition(posEffect)
    self.m_startEffectNode:setVisible(false)
end

--播放金币出现时动画（龙卷风）
function GameCoinFlyView:playStartEffectShow()
    if not self.m_startEffectNode then
        return
    end
    self:showSound()

    self.m_startEffectNode:setVisible(true)
    util_csbPlayForKey(self.m_startEffect, "actionframe", false)
    -- self:playStartEffectScaleAction(false)
end

function GameCoinFlyView:playStartEffectScaleAction(bScale)
    if not self.m_startEffectNode then
        return
    end
    local spScale = {0.8, 1.2, 2, 2.85, 3.6}

    for i = 1, 5 do
        local sp = util_getChildByName(self.m_startEffectNode, "sp_" .. i)
        if not tolua.isnull(sp) then
            sp:setVisible(true)

            local action = nil

            if not bScale then
                sp:setScale(0.01)
                action = cc.Sequence:create(cc.DelayTime:create(3 / 30), cc.ScaleTo:create(0.5, spScale[i]), nil)
            else
                action =
                    cc.Sequence:create(
                    cc.DelayTime:create(3 / 30),
                    cc.ScaleTo:create(0.5, 0.01),
                    cc.CallFunc:create(
                        function()
                            self.m_startEffectNode:removeFromParent()
                            self.m_startEffectNode = nil
                        end
                    ),
                    nil
                )
            end
            sp:runAction(action)
        end
    end
end

function GameCoinFlyView:playFlySound()
    if self.flySound then
        return
    end
    self.flySound = gLobalSoundManager:playSound("Sounds/sound_flycoin.mp3")
end
function GameCoinFlyView:showSound()
    --self.showSound = gLobalSoundManager:playSound("Sounds/sound_flycoin_tonato_show3.mp3")
end
function GameCoinFlyView:collectSound()
    gLobalSoundManager:playSound("Sounds/sound_flycoin_collect1.mp3")
end

function GameCoinFlyView:changeRotationFlyData()
    if self.m_bSelfEndPos then
        self.m_endPos = self.m_bSelfEndPos
    else
        --设置横竖屏坐标
        local posX, posY = nil, nil
        if self.m_bHorizontalScreen then
            --竖屏切横屏
            if globalData.slotRunData.isPortrait then
                posY = display.height - globalData.recordHorizontalEndPos.x
                posX = globalData.recordHorizontalEndPos.y

                self.m_bCoinUIRotation = true
            else
                posY = globalData.recordHorizontalEndPos.y
                posX = globalData.recordHorizontalEndPos.x
            end
        else
            -- --横屏切竖屏    --暂时先不处理暂时没有相关需求
            -- if globalData.slotRunData.isPortrait then
            --     posY = globalData.flyCoinsEndPos.y
            --     posX = globalData.flyCoinsEndPos.x
            -- else
            --     posY = globalData.flyCoinsEndPos.y
            --     posX = globalData.flyCoinsEndPos.x
            -- end
        end
        if posX and posY then
            self.m_endPos.x = posX
            self.m_endPos.y = posY
        end
    end

    self.m_bAddCoinUI = true --添加假滚动label
end

--播放漩涡金币
function GameCoinFlyView:createFlyCoinAnima(startPos, endPos, baseCoinValue, addCoinValue, func, bShowBgColor, coinCount, flyType, flyTime, spanTime, bHideOriginEffect, c4fColor)
    self.flySound = nil
    self.showSound = nil
    local bShowSelfCoins = self.m_bShowSelfCoins
    --取得全局变量 所以克隆下防止被改变
    self.m_endPos = clone(endPos)

    if self.m_bRotation then
        self:changeRotationFlyData()
    end

    --开始时延迟播放飞金币动画
    local delayFlyTime = 0
    local topUIPos = self:convertToNodeSpace(cc.p(self.m_endPos))
    self:createGameTopCoinUI(topUIPos, baseCoinValue)

    if not bHideOriginEffect then
        self:createStartEffect(startPos)
        delayFlyTime = delayFlyTime + DEFAULT_DELAYFLYTIME
    end
    local baseCoinValue = baseCoinValue
    local addCoinValue = addCoinValue

    if bShowBgColor then
        self:addLayerColor(c4fColor)
    end

    -- --渐显topCoinUI
    if self.m_topCoinUI then
        -- self.m_topCoinUI:setVisible(true)
        self.m_topCoinUI:showAction()
    end

    --播放漩涡动画
    self:playStartEffectShow()
    --延时移除self
    local removeTime = flyTime + spanTime * coinCount + DEFAULT_DELAYREMOVETIME + delayFlyTime
    --计算金钱增长时间
    local addCoinTime = flyTime + spanTime * coinCount + DEFAULT_DELAYREMOVETIME
    local cionRunningTime = (spanTime * (coinCount)) * 60
    local perAddCion = addCoinValue / cionRunningTime

    for i = 1, coinCount do
        self:runFlyCoinsAction1(
            i,
            spanTime * i + delayFlyTime,
            flyTime,
            startPos,
            self.m_endPos,
            flyType,
            removeTime - DEFAULT_DELAYREMOVETIME - flyTime,
            addCoinTime,
            cionRunningTime,
            perAddCion,
            baseCoinValue,
            addCoinValue,
            self.m_bAddCoinUI,
            bShowSelfCoins
        )
    end

    performWithDelay(
        self,
        function()
            if not DEBUG_MODE_FLY_COINS then
                if func then
                    func()
                end
            end
        end,
        removeTime
    )

    self.m_viewActions =
        performWithDelay(
        self,
        function()
            if not DEBUG_MODE_FLY_COINS then
                self.m_viewActions = nil
                self.m_bRotation = false
                -- if func then
                --     func()
                -- end
                if not self.m_bAddCoinUI then
                    gLobalNoticManager:postNotification(ViewEventType.RESET_COIN_LABEL)
                else
                    --如果不想用系统金钱 可以在这里抛一个消息 自己再更新下金钱
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {coins = globalData.userRunData.coinNum, isPlayEffect = false})
                end
                self:stopAllActions()
                self:removeFromParent()
            end
        end,
        removeTime
    )
end

--单个金币飞
function GameCoinFlyView:runFlyCoinsAction1(
    i,
    time,
    flyTime,
    startPos,
    endPos,
    flyType,
    allFlyEndTime,
    addCoinTime,
    cionRunningTime,
    perAddCion,
    baseCoinValue,
    addCoinValue,
    bAddCoinUI,
    bShowSelfCoins)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local baseNode = cc.Node:create()
    local randomCoinCsbNum = 3
    --math.random( 1,3 )
    local node, csbAct = util_csbCreate("Lobby/FlyCoins_" .. randomCoinCsbNum .. ".csb")
    local childsCoin = node:getChildren()
    node:setVisible(false)

    --这里直接播放动画 造成金币飞行播放不整齐的样子0
    util_csbPlayForKey(csbAct, "act_1", true, nil, 30)

    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:setVisible(true)
            local nodeLizi = cc.ParticleSystemQuad:create("Lobby/Jinbi/GameLobby_lizi_01.plist")
            baseNode:addChild(nodeLizi, -1)
            nodeLizi:setPosition(cc.p(0, 0))
            local timeLineName = "act_1"
            --  csbAct:gotoFrameAndPlay(0, 31, math.random( 10,20 ) ,true)

            local actionTime = util_csbGetAnimTimes(csbAct, timeLineName, 60)
            local speed = actionTime / flyTime
            csbAct:setTimeSpeed(1.2)
            node:setRotation(math.random(0, 360))

            self:playFlySound()
        end
    )
    baseNode:addChild(node)
    self:addChild(baseNode, 2)
    baseNode:setPosition(startPos)
    baseNode:setScale(math.random(90, 110) / 100 * DEFAULT_START_COIN_CALE)
    local bez = nil
    local a = cc.pGetAngle(startPos, endPos)
    if math.abs(endPos.x - startPos.x) < DEFAULT_MIN_DIS_X then
        bez =
            cc.BezierTo:create(
            flyTime,
            {
                cc.p(startPos.x + (DEFAULT_MIN_DIS_X) * 0.1, startPos.y + (endPos.y - startPos.y) * 3 / 5 + math.random(10, 50)),
                cc.p(startPos.x + (DEFAULT_MIN_DIS_X) * 0.9, startPos.y + (endPos.y - startPos.y) * 3 / 5 - math.random(10, 50)),
                endPos
            }
        )
    else
        bez =
            cc.BezierTo:create(
            flyTime,
            {
                cc.p(startPos.x + (endPos.x - startPos.x) * 0.1, startPos.y + (endPos.y - startPos.y) * 3 / 5 + math.random(10, 50)),
                cc.p(startPos.x + (endPos.x - startPos.x) * 0.9, startPos.y + (endPos.y - startPos.y) * 3 / 5 - math.random(10, 50)),
                endPos
            }
        )
    end
    -- if math.random(1,2)  == 1 then
    bez = cc.EaseSineIn:create(bez)
    -- end
    local scaleAct = cc.Sequence:create(cc.ScaleTo:create(flyTime / 2, MAX_COIN_SCALE), cc.ScaleTo:create(flyTime / 2, 1))

    local spawAct = cc.Spawn:create(bez, scaleAct)
    actionList[#actionList + 1] = spawAct

    local endCallfunc =
        cc.CallFunc:create(
        function()
            if i == 1 then
                if not bAddCoinUI then
                    gLobalNoticManager:postNotification(ViewEventType.FRESH_COIN_LABEL, {perAddCion, baseCoinValue + addCoinValue, cionRunningTime, bShowSelfCoins})
                else
                    self.m_topCoinUI:refreshCoin(addCoinValue, allFlyEndTime)
                end
            end

            self:collectSound()
            self:playCollectAction()
            baseNode:removeSelf()
        end
    )

    actionList[#actionList + 1] = endCallfunc

    baseNode:runAction(cc.Sequence:create(actionList))
end

--竖版关卡横屏旋转后横屏飞金币
function GameCoinFlyView:addHorizonTopCoin()
    if globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_portraitFlag and not globalData.slotRunData.isPortrait then
        self.m_bAddCoinUI = true
        self.m_bHorizontalScreen = true
        return true
    elseif gLobalViewManager:isCoinPusherScene() then
        self.m_bAddCoinUI = true
        self.m_bHorizontalScreen = false
        return true
    end

    return false
end

function GameCoinFlyView:onEnter()
end

function GameCoinFlyView:onExit()
    gLobalNoticManager:postNotification(ViewEventType.RESET_COIN_LABEL)
end
--------------------------------------------------------------------------------------------------------------------------------
--PUB外部接口函数-----------------------------------------------------------------------------------------------------------------
--[[
    @desc: 
    author:{author}
    time:2020-05-25 14:45:09
    --@startPos:            金币出现位置
    --@endPos:              金币结束位置 现在一般在topui金币条位置
    --@baseCoinValue:       金币滚动前的数值
    --@addCoinValue:        金币增加数量
    --@func:                全部动画播放完回调
    --@bShowBgColor:        是否显示bg的灰色遮罩    默认关闭
    --@flyType:             金币飞行轨迹 type 扩展用现在就一个moveto
	--@newCountNum:         新的收集飞行金币数量
	--@newFlyTime:          新的金币飞行时间
	--@newSpanTime:         金币出现间隔
	--@bHideOriginEffect:   是否隐藏金币出现时动画(漩涡动画)
	--@c4fColor:            遮罩color设置
    @return:
]]
function GameCoinFlyView:pubPlayFlyCoin(startPos, endPos, baseCoinValue, addCoinValue, func, bShowBgColor, newCoinCount, flyType, newFlyTime, newSpanTime, bHideOriginEffect, bgC4fColor)
    -- --横竖屏转动情况下不允许多个飞金币 加个保护直接回调  --暂时不竖版显示横版ui了 所以先注掉了
    -- if self.m_bRotation then
    --     self.m_bHorizontalScreen = nil
    --     self.m_bSelfEndPos       = nil
    --     self.m_bRotation         = nil
    --     self.m_bCoinUIRotation   = nil

    --     if func then
    --         func()
    --     end
    --     return
    -- end

    --竖版关卡中旋转横版活动 飞金币特殊处理
    if self:addHorizonTopCoin() then
        endPos = globalData.recordHorizontalEndPos
    end

    --加一个金币滚动补丁 当增加金币为0 或者 金币已经被先加上去调用
    local rewardCoins = toLongNumber(globalData.userRunData.coinNum - globalData.topUICoinCount)
    if addCoinValue == toLongNumber(0) or rewardCoins == toLongNumber(0) then
        --发消息还原金币数量
        gLobalNoticManager:postNotification(ViewEventType.BACK_LAST_WIN_COINS, addCoinValue)
        --更新金币添加数量
        if addCoinValue == 0 then
            addCoinValue = toLongNumber(globalData.userRunData.coinNum - globalData.topUICoinCount)
        end

        baseCoinValue = globalData.topUICoinCount
    end
    ----------------------------------------------------------

    ---debug--------------------------------------------------
    if DEBUG_MODE_FLY_COINS then
        self.test = {startPos, endPos, baseCoinValue, addCoinValue, func, bShowBgColor, newCoinCount, flyType, newFlyTime, newSpanTime, bHideOriginEffect, bgC4fColor}
    end
    ----------------------------------------------------------

    if self.m_viewActions then
        self:stopAction(self.m_viewActions)
        self.m_viewActions = nil
    end

    --初始化默认值
    local coinCount = DEFAULT_COIN_COUNT
    local flyTime = cc.pGetDistance(startPos, endPos) / 1000
    local spanTime = DEFAULT_INTERVAL_FLY_TIME

    --更新使用传入数值
    if newSpanTime then
        spanTime = newSpanTime
    end
    if newFlyTime then
        flyTime = newFlyTime
    end

    if newCoinCount then
        -- body
        coinCount = newCoinCount
    end

    self:createFlyCoinAnima(startPos, endPos, baseCoinValue, addCoinValue, func, bShowBgColor, coinCount, flyType, flyTime, spanTime, bHideOriginEffect, bgC4fColor)
end

--针对竖屏切横屏等特殊情况 会创建一个假的金币Lable用于飞金币滚动
function GameCoinFlyView:pubSetRotationFlag(isHorizontalScreen, selfEndPos)
    self.m_bHorizontalScreen = isHorizontalScreen
    self.m_bSelfEndPos = selfEndPos
    self.m_bRotation = true
end

--飞金币在refreshCoinLabel 不以globalData.userRunData.coinNum 做纠错处理 关卡中慎用 除非界面暂时 注意最后更新到与globalData.userRunData.coinNum数值一样
function GameCoinFlyView:pubShowSelfCoins(isShow)
    self.m_bShowSelfCoins = isShow
end

function GameCoinFlyView:pubSetAddCoinUI(state)
    self.m_bAddCoinUI = state
end

return GameCoinFlyView
