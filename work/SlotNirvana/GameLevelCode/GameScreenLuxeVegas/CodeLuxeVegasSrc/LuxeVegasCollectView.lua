---
--xcyy
--2018年5月23日
--LuxeVegasCollectView.lua
local PublicConfig = require "LuxeVegasPublicConfig"
local LuxeVegasCollectView = class("LuxeVegasCollectView",util_require("Levels.BaseLevelDialog"))

function LuxeVegasCollectView:initUI(_machine, _collectItemLightTbl)

    self:createCsbNode("LuxeVegas_shoujilan.csb")
    self.m_machine = _machine
    local collectItemLightTbl = _collectItemLightTbl

    self.m_collectItem = {}
    self.m_collectNode = {}
    for i=1, 5 do
        local itemLight = collectItemLightTbl[i]
        self.m_collectNode[i] = self:findChild("Node_collect_"..i)
        self.m_collectItem[i] = util_createView("CodeLuxeVegasSrc.LuxeVegasCollectItemView", _machine, itemLight)
        self.m_collectNode[i]:addChild(self.m_collectItem[i], -1)
    end

    self:playIdle()
end

function LuxeVegasCollectView:playIdle()
    self:runCsbAction("idle", true)
end

function LuxeVegasCollectView:playTrigger()
    for i=1, 5 do
        self.m_collectItem[i]:playTrigger()
    end
end

-- reload
function LuxeVegasCollectView:playReload()
    self:runCsbAction("reload", false, function()
        self:playIdle()
        for i=1, 5 do
            self:playItemIdle(i)
        end
    end)
end

function LuxeVegasCollectView:getCollectNode(_col)
    return self.m_collectNode[_col]
end

-- 播放收集条的idle
function LuxeVegasCollectView:playItemIdle(_col)
    self.m_collectItem[_col]:playIdle()
end

-- 获取当前列当前的钱数
function LuxeVegasCollectView:getCurColCoins(_col)
    return self.m_collectItem[_col]:getCurColCoins()
end

-- 收集到底部；播放顶部动画
function LuxeVegasCollectView:collectBottomCoins(_col)
    self.m_collectItem[_col]:collectBottomCoins()
end

-- 刷新钱
function LuxeVegasCollectView:refreshCollectCoins(_data, _refreshCol)
    local data = _data
    local refreshCol = _refreshCol
    local playSoundIndex = 0
    local isPlaySound = true
    for i=1, 5 do
        local coins = data[i] or 0
        local isRefresh = false
        if refreshCol and refreshCol[i] then
            isRefresh = true
            playSoundIndex = playSoundIndex + 1
        end
        if playSoundIndex > 1 then
            isPlaySound = false
        end
        self.m_collectItem[i]:refreshCoins(coins, isRefresh, isPlaySound)
    end
end

-- reload刷新钱
function LuxeVegasCollectView:reloadRefreshCollectCoins(_col, _coins)
    self.m_collectItem[_col]:reloadRefreshCoins(_coins)
end

-- 乘倍刷新钱
function LuxeVegasCollectView:refreshCoinsByWheel(_curCol, _curMul, _callFunc)
    self.m_collectItem[_curCol]:refreshCoinsByWheel(_curMul, _callFunc)
end

-- 设置多福多彩和base显隐
function LuxeVegasCollectView:setColfulState(_isColorful)
    if _isColorful then
        self:findChild("Node_dfdc"):setVisible(true)
        self:findChild("Node_base"):setVisible(false)
    else
        self:findChild("Node_dfdc"):setVisible(false)
        self:findChild("Node_base"):setVisible(true)
    end
end

return LuxeVegasCollectView
