--[[

    author:{author}
    time:2022-05-15 14:40:50
]]
-- local DEFAULT_INTERVAL_FLY_TIME = 0.04 --金币之间间隔
-- local DEFAULT_COIN_COUNT = 30 --金币默认数量
-- local DEFAULT_DELAYFLYTIME = 0 --开始飞金币前默认延迟时间
-- local DEFAULT_DELAYREMOVETIME = 1 --全部金币飞到金币条之后 默认延迟移除GameCoinFlyView时间
-- local DEFAULT_COIN_CALE = 1.2 --金币放大倍数
local DEFAULT_START_COIN_CALE = 0.8 --金币放大倍数
-- local DEFAULT_RANDOM_TIMELINE_COUNT = 8 --随机金币时间线个数

local DEFAULT_MIN_DIS_X = 100
-- 金币放大倍数
local MAX_COIN_SCALE = 1.7
-- 测试模式 从点击点飞金币
local DEBUG_MODE_FLY_COINS = false

GD.FlyType = {
    Coin = "FlyCoin",
    Gem = "FlyGem",
    Buck = "FlyBuck"
}

local FlyCurrencyInfo = require("GameModule.Currency.model.FlyCurrencyInfo")
local FlyCoins = require("GameModule.Currency.controller.FlyCoins")
local FlyGems = require("GameModule.Currency.controller.FlyGems")
local FlyBucks = require("GameModule.Currency.controller.FlyBucks")
local CurrencyData = require("GameModule.Currency.model.CurrencyData")

local CurrencyMgr = class("CurrencyMgr", BaseGameControl)

function CurrencyMgr:ctor()
    CurrencyMgr.super.ctor(self)
    self.m_refName = G_REF.Currency

    self.m_cuyData = CurrencyData:create()

    -- 飞货币的信息列表
    self.m_flyInfoList = {}
    -- 飞货币时的遮罩引用计数
    self.m_flyLayerRef = 0

    -- 不同类型货币的飞行对象
    self.m_flyObjs = {}
    self.m_flyObjs[FlyType.Coin] = FlyCoins:create(self)
    self.m_flyObjs[FlyType.Gem] = FlyGems:create(self)
    self.m_flyObjs[FlyType.Buck] = FlyBucks:create(self)
end

function CurrencyMgr:setCoins(coins, _bFly)
    self.m_cuyData:setCoins(coins, _bFly)
end

function CurrencyMgr:getCoins()
    return self.m_cuyData:getCoins()
end

function CurrencyMgr:setGems(gems)
    self.m_cuyData:setGems(gems)
end

function CurrencyMgr:getGems()
    return self.m_cuyData:getGems()
end

function CurrencyMgr:setBucks(bucks)
    self.m_cuyData:setBucks(bucks)
end

function CurrencyMgr:getBucks()
    return self.m_cuyData:getBucks()
end

function CurrencyMgr:getFlyLayer()
    local _layer = gLobalViewManager:getViewByName("FlyCurrencyLayer")
    if not _layer then
        _layer = util_createView("GameModule.Currency.views.FlyCurrencyLayer")
        _layer:setName("FlyCurrencyLayer")

        gLobalViewManager:showUI(_layer, ViewZorder.ZORDER_SPECIAL)
    end

    return _layer
end

function CurrencyMgr:removeFlyLayer()
    local _layer = gLobalViewManager:getViewByName("FlyCurrencyLayer")
    if _layer then
        _layer:closeUI(
            function()
                if self.m_flyCallback then
                    self.m_flyCallback()
                    self.m_flyCallback = nil
                end
            end
        )
    end
end

function CurrencyMgr:onExitFlyLayer()
    -- 移除遮罩层时，清理飞货币对象
    for _, flyObj in pairs(self.m_flyObjs) do
        if flyObj:isRunning() then
            flyObj:flyExit()
            flyObj:flyCleanUp()
        end
    end
end

-- 维护遮罩层引用计数
function CurrencyMgr:addLayerRefCount()
    self.m_flyLayerRef = self.m_flyLayerRef + 1
end

function CurrencyMgr:desLayerRefCount()
    local _flyLayerRef = self.m_flyLayerRef

    self.m_flyLayerRef = math.max((_flyLayerRef - 1), 0)

    if _flyLayerRef > 0 and self.m_flyLayerRef == 0 then
        self:removeFlyLayer()
    end
end

-- 添加收集节点信息
function CurrencyMgr:addCollectNodeInfo(type, uiNode, uiName, isPortrait)
    local obj = self.m_flyObjs[type]
    if not obj or not uiNode then
        return
    end
    local uiParent = uiNode:getParent()
    if uiParent then
        local uiPos = cc.p(uiNode:getPosition())
        local wdPos = uiParent:convertToWorldSpace(uiPos)
        obj:addEndPos(wdPos, uiName, isPortrait)
    end
end

function CurrencyMgr:addCollectPosInfo(type, wdPos, uiName, isPortrait)
    local obj = self.m_flyObjs[type]
    if not obj or not wdPos then
        return
    end

    obj:addEndPos(wdPos, uiName, isPortrait)
end

-- 移除收集节点信息
function CurrencyMgr:removeCollectNodeInfo(uiName)
    for key, value in pairs(self.m_flyObjs) do
        if value then
            value:removeEndPos(uiName)
        end
    end
end

-- 添加飞货币信息
function CurrencyMgr:addFlyCuyInfo(info)
    if self:checkFlyCuyInfo(info) then
        local flyGemsInfo = FlyCurrencyInfo:create()
        flyGemsInfo:setFlyCurrencyInfo(info)
        table.insert(self.m_flyInfoList, 1, flyGemsInfo)
    end
end

function CurrencyMgr:checkFlyCuyInfo(info)
    if not info then
        assert(info, "cuyInfo is nil!!")
        return false
    end
    local cuyType = info.cuyType
    local addValue = info.addValue or 0
    local startPos = info.startPos
    if device.platform == "mac" then
        assert(cuyType, "cuyType is nil!!")
        -- assert((toLongNumber(addValue) > toLongNumber(0)), "addValue is <= 0!!")
        assert(startPos, "startPos is nil!!")
    end
    if (not cuyType) or (not startPos) then -- or (toLongNumber(addValue) <= toLongNumber(0))
        return false
    end

    return true
end

-- 飞货币
function CurrencyMgr:playFlyCurrency(infos, callback)
    if not infos or (not next(infos)) then
        if callback then
            callback()
        end
        return
    end
    if #infos > 0 then
        for i = 1, #infos do
            self:addFlyCuyInfo(infos[i])
        end
    else
        self:addFlyCuyInfo(infos)
    end

    if #self.m_flyInfoList <= 0 then
        if callback then
            callback()
        end
        return
    end

    self:showFlyReady()

    for index = #self.m_flyInfoList, 1, -1 do
        local info = self.m_flyInfoList[index]
        local _flyObj = self.m_flyObjs[info:getType()]
        if _flyObj then
            _flyObj:initFlyInfo(info)

            _flyObj:flyCurrencys(handler(self, self.flyCuyAction))
        end
        table.remove(self.m_flyInfoList, index)
    end

    self.m_flyCallback = callback
end

-- 准备飞货币前效果
function CurrencyMgr:showFlyReady()
    -- 创建目的UI
    local _layer = self:getFlyLayer()

    if bShowBgColor then
        self:addLayerColor(c4fColor)
    end
end

-- 飞货币动画
function CurrencyMgr:flyCuyAction(fly, flyNode, flyTime, startPos, endPos, delay, maxScale, startScale)
    local actionList = {}

    local baseNode = cc.Node:create()
    baseNode:addChild(flyNode)

    actionList[#actionList + 1] = cc.DelayTime:create(delay)

    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            fly:flyStart(flyNode)
        end
    )

    self:getFlyLayer():addChild(baseNode, 2)
    baseNode:setPosition(startPos)
    local defaultScale = math.random(90, 110) / 100 * DEFAULT_START_COIN_CALE
    startScale = startScale or defaultScale
    baseNode:setScale(startScale)
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
    maxScale = maxScale or MAX_COIN_SCALE
    local scaleAct = cc.Sequence:create(cc.ScaleTo:create(flyTime / 2, maxScale), cc.ScaleTo:create(flyTime / 2, 1))

    local spawAct = cc.Spawn:create(bez, scaleAct)
    actionList[#actionList + 1] = spawAct

    local endCallfunc =
        cc.CallFunc:create(
        function()
            fly:flyArrive(flyNode)
            fly:flyCollect(flyNode, self:getFlyLayer())

            baseNode:removeFromParent()
        end
    )

    actionList[#actionList + 1] = endCallfunc

    baseNode:runAction(cc.Sequence:create(actionList))
end

return CurrencyMgr
