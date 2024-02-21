--[[
    author:{author}
    time:2022-05-16 15:25:59
]]
local DEFAULT_INTERVAL_FLY_TIME = 0.04 --金币之间间隔
local DEFAULT_COIN_COUNT = 30 --金币默认数量
local DEFAULT_DELAYFLYTIME = 0 --开始飞金币前默认延迟时间
local DEFAULT_DELAYREMOVETIME = 1 --全部金币飞到金币条之后 默认延迟移除GameCoinFlyView时间
local DEFAULT_COIN_CALE = 1.2 --金币放大倍数
local DEFAULT_START_COIN_CALE = 0.8 --金币放大倍数
local DEFAULT_RANDOM_TIMELINE_COUNT = 8 --随机金币时间线个数

local FlyBase = require("GameModule.Currency.controller.FlyBase")
local FlyCoins = class("FlyCoins", FlyBase)

function FlyCoins:ctor(...)
    FlyCoins.super.ctor(self, ...)

    -- 横版坐标
    self.m_defEndPos.Landscape = self:createEndPos(cc.p(340, display.height - 30))
    -- 竖版坐标
    local bangHeight = util_getBangScreenHeight()
    self.m_defEndPos.Portrait = self:createEndPos(cc.p(74, display.width - (bangHeight + 30)))
end

-- 是否创建收集节点
-- function FlyCoins:isNeedCreateCollectUI()
--     -- 是否发生旋转
--     if globalData.slotRunData:isFramePortrait() ~= globalData.slotRunData.isPortrait then
--         return true
--     end
--     if gLobalViewManager:isCoinPusherScene() then
--         return true
--     end
--     return false
-- end

function FlyCoins:createCuyNode(index)
    if not self.m_flyCuyInfo then
        return nil
    end
    return util_createView("GameModule.Currency.views.FlyCoinNode", self.m_flyCuyInfo, index)
end

-- 显示收集UI
function FlyCoins:showCollectUI()
    local _layer = self.m_mgr:getFlyLayer()
    if not self:isNeedCreateCollectUI() then
        -- csc 2022-02-16 新版商城需要做判断， 如果有商城界面的情况下，用新的协议
        if gLobalViewManager:getViewByExtendData("ZQCoinStoreLayer") then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWSHOP_UP_COIN_LABEL, _layer)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UP_COIN_LABEL, _layer)
        end
    else
        -- 创建目的UI
        local uiPos = _layer:convertToNodeSpace(self:getEndPos())
        local collectUI = _layer:getChildByName("CollectCoinsUI")
        if not collectUI then
            collectUI = util_createView("GameModule.Currency.views.CollectCoinsUI", self.m_bCoinUIRotation)
            collectUI:setName("CollectCoinsUI")
            _layer:addChild(collectUI)
        end

        collectUI:setPosition(uiPos)
        local _coins = G_GetMgr(G_REF.Currency):getCoins()
        collectUI:updateUI(_coins)

        --渐显topCoinUI
        collectUI:showAction()
    end
end

-- 飞行准备
function FlyCoins:flyReady()
    FlyCoins.super.flyReady(self)

    if not bHideOriginEffect then
        -- 创建开始动画
        self:createStartEffect(self:getStartPos())
        self.m_delayFlyTime = self.m_delayFlyTime + DEFAULT_DELAYFLYTIME

        if self.m_startEffectNode then
            --播放金币出现时动画
            self.m_startEffectNode:setVisible(true)
            util_csbPlayForKey(self.m_startEffect, "actionframe", false)
        end
    end
end

-- 开始飞行
function FlyCoins:flyStart(flyNode)
    FlyCoins.super.flyStart(self, flyNode)

    if flyNode and flyNode:getIdx() == 1 then
        self:playFlySound()
    end
end

--创建金币出现时漩涡动画
function FlyCoins:createStartEffect(posEffect)
    -- if self.m_startEffectNode then
    --     self.m_startEffectNode:setPosition(posEffect)
    --     return
    -- end

    local node, csbAct = util_csbCreate("Lobby/FlyCoins_longjuanfeng_2.csb")
    self.m_startEffect = csbAct
    self.m_startEffectNode = node
    self.m_mgr:getFlyLayer():addChild(node)
    node:setPosition(posEffect)
    self.m_startEffectNode:setVisible(false)
end

-- 飞行音效
function FlyCoins:playFlySound()
    gLobalSoundManager:playSound("Sounds/sound_flycoin.mp3")
end

function FlyCoins:flyCurrencys(flyFunc)
    FlyCoins.super.flyCurrencys(self)

    local flyCuyInfo = self.m_flyCuyInfo

    local startPos = self:getStartPos()
    local endPos = self:getEndPos()
    local addValue = flyCuyInfo:getAddValue()

    local flyTime = cc.pGetDistance(startPos, endPos) / 1000
    local spanTime = DEFAULT_INTERVAL_FLY_TIME
    local coinCount = DEFAULT_COIN_COUNT
    local delayFlyTime = self.m_delayFlyTime

    --计算金钱增长时间
    -- local coinRunningTime = (spanTime * (coinCount)) * 60
    -- local perAddCion = addValue / coinRunningTime

    local allFlyEndTime = spanTime * coinCount + delayFlyTime

    for i = 1, coinCount do
        local _delay = spanTime * i + delayFlyTime

        local flyNode = self:createCuyNode(i)
        if flyNode then
            flyNode:setVisible(false)
            flyNode:playAction()
            if flyFunc then
                flyFunc(self, flyNode, flyTime, startPos, endPos, _delay)
            end
        end
    end
end

-- 飞货币抵达效果
function FlyCoins:flyArrive(flyNode)
    if flyNode and flyNode:getIdx() == 1 then
        local flyCuyInfo = self.m_flyCuyInfo

        local spanTime = DEFAULT_INTERVAL_FLY_TIME
        local coinCount = DEFAULT_COIN_COUNT
        local addValue = flyCuyInfo:getAddValue()

        local coinRunningTime = (spanTime * (coinCount)) * 60
        local perAddCion = addValue / coinRunningTime

        local allFlyEndTime = spanTime * coinCount + self.m_delayFlyTime

        if not self:isNeedCreateCollectUI() then
            gLobalNoticManager:postNotification(ViewEventType.FRESH_COIN_LABEL, {perAddCion, nil, coinRunningTime, bShowSelfCoins})
        else
            local collectUI = self.m_mgr:getFlyLayer():getChildByName("CollectCoinsUI")
            if collectUI then
                collectUI:refreshValue(addValue, allFlyEndTime)
            end
        end
    end
end

-- 收集音效
function FlyCoins:playCollectSound()
    gLobalSoundManager:playSound("Sounds/sound_flycoin_collect_loop.mp3")
end

function FlyCoins:playCollectAction(flyLayer, callback)
    local endPos = self:getEndPos()
    local node, csbAct = util_csbCreate("Lobby/FlyCoins_guanghuan.csb")
    flyLayer:addChild(node)
    node:setPosition(endPos)
    util_csbPlayForKey(
        csbAct,
        "actionframe",
        false,
        function()
            node:removeFromParent()
            FlyCoins.super.playCollectAction(self, flyLayer, callback)
        end
    )
end

function FlyCoins:flyOver()
    performWithDelay(
        self.m_mgr:getFlyLayer(),
        function()
            FlyCoins.super.flyOver(self)
        end,
        DEFAULT_DELAYREMOVETIME
    )
end

function FlyCoins:flyExit()
    FlyCoins.super.flyExit(self)
    
    if (not self:isNeedCreateCollectUI()) then
        gLobalNoticManager:postNotification(ViewEventType.RESET_COIN_LABEL)
    else
        local _coins = G_GetMgr(G_REF.Currency):getCoins()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {coins = _coins, isPlayEffect = false})
    end
end

return FlyCoins