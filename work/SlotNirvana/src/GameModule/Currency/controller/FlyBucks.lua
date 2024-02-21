--[[
    author:{author}
    time:2022-05-16 15:25:59
]]
local DEFAULT_INTERVAL_FLY_TIME = 0.2 --金币之间间隔
local DEFAULT_COIN_COUNT = 10 --金币默认数量
local DEFAULT_DELAYFLYTIME = 0 --开始飞金币前默认延迟时间
local DEFAULT_DELAYREMOVETIME = 1 --全部金币飞到金币条之后 默认延迟移除GameCoinFlyView时间
local DEFAULT_COIN_CALE = 1.2 --金币放大倍数
local DEFAULT_START_COIN_CALE = 1 --金币放大倍数
local DEFAULT_RANDOM_TIMELINE_COUNT = 8 --随机金币时间线个数

local FlyBase = require("GameModule.Currency.controller.FlyBase")
local FlyBucks = class("FlyBucks", FlyBase)

function FlyBucks:ctor(...)
    FlyBucks.super.ctor(self, ...)

    -- 横版坐标
    self.m_defEndPos.Landscape = self:createEndPos(cc.p(170, display.height - 30))
    -- 竖版坐标
    local bangHeight = util_getBangScreenHeight()
    self.m_defEndPos.Portrait = self:createEndPos(cc.p(254, display.width - (bangHeight + 30)))
end

-- 开始位置
function FlyBucks:getStartPos()
    local _startPos = self.m_flyCuyInfo:getStartPos()
    return _startPos
end

-- 是否创建收集节点
-- function FlyBucks:isNeedCreateCollectUI()
--     -- 是否发生旋转
--     if globalData.slotRunData:isFramePortrait() ~= globalData.slotRunData.isPortrait then
--         return true
--     end
--     if gLobalViewManager:isCoinPusherScene() then
--         return true
--     end
--     return false
-- end

-- 创建货币节点
function FlyBucks:createCuyNode(index)
    if not self.m_flyCuyInfo then
        return nil
    end
    return util_createView("GameModule.Currency.views.FlyBuckNode", self.m_flyCuyInfo, index)
end

-- 收集UI
function FlyBucks:showCollectUI()
    local _layer = self.m_mgr:getFlyLayer()
    if not self:isNeedCreateCollectUI() then
        -- 刷新
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUCKSHOP_UP_LABEL, _layer)
    else
        -- 创建目的UI
        local uiPos = _layer:convertToNodeSpace(self:getEndPos())
        local collectUI = _layer:getChildByName("CollectBucksUI")
        if not collectUI then
            collectUI = util_createView("GameModule.Currency.views.CollectBucksUI", self.m_bCoinUIRotation)
            collectUI:setName("CollectBucksUI")
            _layer:addChild(collectUI)
        end

        collectUI:setPosition(uiPos)
        local _bucks = G_GetMgr(G_REF.Currency):getBucks()
        collectUI:updateUI(_bucks)

        --渐显topCoinUI
        collectUI:showAction()
    end
end

-- 飞行准备
function FlyBucks:flyReady()
    FlyBucks.super.flyReady(self)

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
function FlyBucks:flyStart(flyNode)
    FlyBucks.super.flyStart(self, flyNode)

    if flyNode and flyNode:getIdx() == 1 then
        self:playFlySound()
    end
end

--创建金币出现时漩涡动画
function FlyBucks:createStartEffect(posEffect)
    -- if self.m_startEffectNode then
    --     self.m_startEffectNode:setPosition(posEffect)
    --     return
    -- end

    local node, csbAct = util_csbCreate("Lobby/FlyBucks_longjuanfeng.csb")
    self.m_startEffect = csbAct
    self.m_startEffectNode = node
    self.m_mgr:getFlyLayer():addChild(node)
    node:setPosition(posEffect)
    self.m_startEffectNode:setVisible(false)
end

-- 飞行音效
function FlyBucks:playFlySound()
    gLobalSoundManager:playSound("Sounds/sound_fly_buck.mp3")
end

function FlyBucks:getFlyCount()
    return DEFAULT_COIN_COUNT
end

function FlyBucks:flyCurrencys(flyFunc)
    FlyBucks.super.flyCurrencys(self)

    local flyCuyInfo = self.m_flyCuyInfo

    local startPos = self:getStartPos()
    local endPos = self:getEndPos()
    local addValue = flyCuyInfo:getAddValue()

    local flyTime = cc.pGetDistance(startPos, endPos) / 1000
    local spanTime = DEFAULT_INTERVAL_FLY_TIME
    local coinCount = DEFAULT_COIN_COUNT
    local delayFlyTime = self.m_delayFlyTime

    --计算金钱增长时间
    -- local addCoinTime = flyTime + spanTime * coinCount + DEFAULT_DELAYREMOVETIME
    local cionRunningTime = (spanTime * (coinCount)) * 60
    local perAddCion = addValue / cionRunningTime
    local allFlyEndTime = spanTime * coinCount + delayFlyTime

    for i = 1, coinCount do
        local _delay = spanTime * i + delayFlyTime
        local flyNode = self:createCuyNode(i)
        if flyNode then
            flyNode:setVisible(false)
            flyNode:playAction()
            if flyFunc then
                flyFunc(self, flyNode, flyTime, startPos, endPos, _delay, DEFAULT_COIN_CALE, DEFAULT_START_COIN_CALE)
            end
        end
    end
end

-- 飞货币抵达效果
function FlyBucks:flyArrive(flyNode)
    if flyNode and flyNode:getIdx() == 1 then
        local flyCuyInfo = self.m_flyCuyInfo

        local spanTime = DEFAULT_INTERVAL_FLY_TIME
        local coinCount = DEFAULT_COIN_COUNT
        local addValue = flyCuyInfo:getAddValue()

        local coinRunningTime = (spanTime * (coinCount)) * 60
        local perAddCion = addValue / coinRunningTime

        local allFlyEndTime = spanTime * coinCount + self.m_delayFlyTime

        if not self:isNeedCreateCollectUI() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUCKSHOP_FRESH_LABEL, {perAddCion, nil, coinRunningTime, bShowSelfCoins})
        else
            local collectUI = self.m_mgr:getFlyLayer():getChildByName("CollectBucksUI")
            if collectUI then
                collectUI:refreshValue(addValue, allFlyEndTime)
            end
        end
    end
end

-- 收集音效
function FlyBucks:playCollectSound()
    -- gLobalSoundManager:playSound("Sounds/sound_flycoin_collect1.mp3")
end

function FlyBucks:playCollectAction(flyLayer, callback)
    local endPos = self:getEndPos()
    local node, csbAct = util_csbCreate("Lobby/FlyBucks_guanghuan.csb")
    flyLayer:addChild(node)
    node:setPosition(endPos)
    util_csbPlayForKey(
        csbAct,
        "actionframe",
        false,
        function()
            node:removeFromParent()
            FlyBucks.super.playCollectAction(self, flyLayer, callback)
        end
    )
end

function FlyBucks:flyOver()
    performWithDelay(
        self.m_mgr:getFlyLayer(),
        function()
            FlyBucks.super.flyOver(self)
        end,
        DEFAULT_DELAYREMOVETIME
    )
end

function FlyBucks:flyExit()
    FlyBucks.super.flyExit(self)
    if (not self:isNeedCreateCollectUI()) then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUCKSHOP_RESET_LABEL)
    else
        local _bucks = G_GetMgr(G_REF.Currency):getBucks()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUCKSHOP_RESET_LABEL, _bucks)
    end
end

return FlyBucks
