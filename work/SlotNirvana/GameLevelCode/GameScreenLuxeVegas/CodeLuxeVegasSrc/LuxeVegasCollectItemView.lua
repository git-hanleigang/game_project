---
--xcyy
--2018年5月23日
--LuxeVegasCollectItemView.lua
local PublicConfig = require "LuxeVegasPublicConfig"
local LuxeVegasCollectItemView = class("LuxeVegasCollectItemView",util_require("Levels.BaseLevelDialog"))

function LuxeVegasCollectItemView:initUI(_machine, _itemLight)

    self:createCsbNode("LuxeVegas_shoujilan_item.csb")
    self.m_machine = _machine
    self.m_itemLight = _itemLight
    self:setCurColCoins(0)

    self.m_rectangleLight = util_createAnimation("LuxeVegas_shoujilan_item_light2.csb")
    self.m_itemLight:findChild("Node_idle3"):addChild(self.m_rectangleLight)
    util_setCascadeOpacityEnabledRescursion(self.m_itemLight, true)

    self.m_spColorTbl = {}
    self.m_spColorTbl[1] = self:findChild("sp_blue")
    self.m_spColorTbl[2] = self:findChild("sp_purple")
    self.m_spColorTbl[3] = self:findChild("sp_red")

    self.m_spMulTbl = {}
    self.m_spMulTbl[1] = _itemLight:findChild("X10")
    self.m_spMulTbl[2] = _itemLight:findChild("X25")
    self.m_spMulTbl[3] = _itemLight:findChild("X50")
    
    self:playIdle()

    self.m_scWaitJumpNode = cc.Node:create()
    self:addChild(self.m_scWaitJumpNode)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function LuxeVegasCollectItemView:refreshCoins(_coins, _isRefresh, _isPlaySound)
    local oldCoins = self:getCurColCoins()
    self:setCurColCoins(_coins)
    local curColor = self:getCurColColor()
    local coins = self:get_formatCoins(_coins, 3)
    local isRefresh = _isRefresh
    local isPlaySound = _isPlaySound
    if isRefresh then
        self:playTrigger(curColor, oldCoins, isPlaySound)
    else
        self:setCurCoins(coins)
        self:changeBgColor(curColor)
    end
end

function LuxeVegasCollectItemView:reloadRefreshCoins(_coins)
    self:setCurColCoins(_coins)
    local curColor = self:getCurColColor()
    self:changeBgColor(curColor)
    local coins = self:get_formatCoins(_coins, 3)
    self:setCurCoins(coins)
end

-- 设置钱数显示
function LuxeVegasCollectItemView:setCurCoins(_coins)
    local coins = _coins
    for i=1, 3 do
        local textNode = self:findChild("m_lb_coins_"..i)
        textNode:setString(coins)
        self:updateLabelSize({label=textNode,sx=1.0,sy=1.0},130)
    end
end

-- 小轮盘触发后刷新钱
function LuxeVegasCollectItemView:refreshCoinsByWheel(_curMul, _callFunc)
    local curMul = _curMul
    local callFunc = _callFunc
    local oldCoins = self:getCurColCoins()
    self:setCurColCoins(self.m_curCoins*curMul)
    local endCoins = self:getCurColCoins()
    for i=1, 3 do
        self.m_spMulTbl[i]:setVisible(false)
    end
    local isMaxMul = false
    if curMul == 10 and (self.m_machine.m_gamePlayMul == self.m_machine.M_ENUM_TYPE.BASE or self.m_machine.m_gamePlayMul == self.m_machine.M_ENUM_TYPE.FREE_1) then
        self.m_spMulTbl[1]:setVisible(true)
    elseif curMul == 25 and self.m_machine.m_gamePlayMul == self.m_machine.M_ENUM_TYPE.FREE_2 then
        self.m_spMulTbl[2]:setVisible(true)
    elseif curMul == 50 and self.m_machine.m_gamePlayMul == self.m_machine.M_ENUM_TYPE.FREE_3 then
        self.m_spMulTbl[3]:setVisible(true)
    end

    util_resetCsbAction(self.m_csbAct)
    util_resetCsbAction(self.m_itemLight.m_csbAct)
    local curColor = self:getCurColColor()
    self.m_itemLight:runCsbAction("actionframe3", false)
    self:runCsbAction("actionframe3", false)
    -- 15帧开始变数字
    local duration = 0.5
    performWithDelay(self, function()
        self:playJumpCoins(oldCoins, endCoins, duration, callFunc, true)
        self:changeBgColor(curColor)
        self:playRectangleLightIdle()
    end, 15/60)
end

-- 数字上涨
function LuxeVegasCollectItemView:playJumpCoins(_oldCoins, _endCoins, _duration, _endCallFunc, _playJumpCoins)
    local oldCoins = _oldCoins
    local endCoins = _endCoins
    local endCallFunc = _endCallFunc
    local duration = _duration   --持续时间
    local playJumpCoins = _playJumpCoins
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - oldCoins) / (60  * duration)   --1秒跳动60次
    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)
    if playJumpCoins then
        gLobalSoundManager:playSound(PublicConfig.Music_Mul_Jump, false)
    end

    local curCoins = oldCoins
    self:setCurCoins(self:get_formatCoins(curCoins,3))

    util_schedule(self.m_scWaitJumpNode, function()
        curCoins = curCoins + coinRiseNum
        if curCoins >= endCoins then
            self:setCurCoins(self:get_formatCoins(endCoins,3))
            self.m_scWaitJumpNode:stopAllActions()
            --结束回调
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
        else
            self:setCurCoins(self:get_formatCoins(curCoins,3))
        end
    end,1/60)
end

-- 矩形光效（只有触发小轮盘才有）
function LuxeVegasCollectItemView:playRectangleLightIdle()
    self.m_rectangleLight:setVisible(true)
    util_resetCsbAction(self.m_rectangleLight.m_csbAct)
    self.m_rectangleLight:runCsbAction("idle3", true)
end

function LuxeVegasCollectItemView:playIdle()
    util_resetCsbAction(self.m_csbAct)
    util_resetCsbAction(self.m_itemLight.m_csbAct)
    self.m_itemLight:runCsbAction("idle", true)
    self:runCsbAction("idle", true)
end

-- 当前列的钱
function LuxeVegasCollectItemView:setCurColCoins(_curCoins)
    self.m_curCoins = _curCoins
end

-- 当前列的钱
function LuxeVegasCollectItemView:getCurColCoins()
    return self.m_curCoins
end

-- 收集动画over-idle
function LuxeVegasCollectItemView:collectBottomCoins()
    util_resetCsbAction(self.m_csbAct)
    util_resetCsbAction(self.m_itemLight.m_csbAct)
    self.m_itemLight:runCsbAction("over", false)
    self:runCsbAction("over", false, function()
        self.m_rectangleLight:setVisible(false)
        self:playIdle()
    end)
end

-- 换底板颜色
function LuxeVegasCollectItemView:changeBgColor(_index)
    for i=1, 3 do
        if i == _index then
            self.m_spColorTbl[i]:setVisible(true)
        else
            self.m_spColorTbl[i]:setVisible(false)
        end
    end
end

function LuxeVegasCollectItemView:playTrigger(_curColor, _oldCoins, _isPlaySound)
    util_resetCsbAction(self.m_csbAct)
    util_resetCsbAction(self.m_itemLight.m_csbAct)
    local curColor = _curColor
    local oldCoins = _oldCoins
    local isPlaySound = _isPlaySound
    local isPlayRectIdle = false
    if not curColor then
        isPlayRectIdle = true
        curColor = self:getCurColColor()
    end
    local endCoins = self:getCurColCoins()
    local duration = 0.5
    performWithDelay(self, function()
        if oldCoins then
            self:playJumpCoins(oldCoins, endCoins, duration, nil, isPlaySound)
            -- self:setCurCoins(coins)
        end
        self:changeBgColor(curColor)
        if isPlayRectIdle then
            self:playRectangleLightIdle()
        else
            self.m_rectangleLight:setVisible(false)
        end
    end, 10/60)
    self.m_itemLight:runCsbAction("actionframe", false)
    self:runCsbAction("actionframe", false, function()
        if not isPlayRectIdle then
            self:playIdle()
        end
    end)
end

-- 判断收集栏颜色
function LuxeVegasCollectItemView:getCurColColor()
    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local curColor = 1
    local curCoinMul = self:getCurColCoins()/betCoin
    if curCoinMul < self.m_machine.m_collectBgMul[1] then
        curColor = 1
    elseif curCoinMul >= self.m_machine.m_collectBgMul[1] and curCoinMul <= self.m_machine.m_collectBgMul[2] then
        curColor = 2
    elseif curCoinMul > self.m_machine.m_collectBgMul[2] then
        curColor = 3
    end
    return curColor
end

function LuxeVegasCollectItemView:get_formatCoins(coins, obligate, notCut, normal, noRounding, useRealObligate)
    local obK = math.pow(10, 3)
    if type(coins) ~= "number" then
        return coins
    end
    --不需要限制的直接返回
    if obligate < 1 then
        return coins
    end

    --是否添加分割符
    local isCut = true
    if notCut then
        isCut = false
    end

    local str_coins = nil
    coins = tonumber(coins + 0.00001)
    local nCoins = math.floor(coins)
    local count = math.floor(math.log10(nCoins)) + 1
    if count <= obligate then
        str_coins = util_cutCoins(nCoins, isCut, nil, noRounding)
    else
        if count < 3 then
            str_coins = util_cutCoins(nCoins / obK, isCut, nil, noRounding) .. "K"
        else
            local tCoins = nCoins
            local tNum = 0
            local units = {"K", "M", "B", "T"}
            local cell = 1000
            local index = 0
            while (1) do
                index = index + 1
                if index > 4 then
                    return util_cutCoins(tCoins, isCut, nil, noRounding) .. units[4]
                end
                tNum = tCoins % cell
                tCoins = tCoins / cell
                local num = math.floor(math.log10(tCoins)) + 1
                if num <= obligate then
                    --应该保留的小数位
                    local floatNum = obligate - num
                    if normal then
                        return util_cutCoins(tCoins, isCut, floatNum, noRounding) .. units[index]
                    end
                    if not useRealObligate then
                        --保留1位小数
                        if num == 1 and floatNum > 0 then
                            floatNum = 2
                        else
                            --正常模式不保留小数
                            floatNum = 1
                            if tCoins > 100 then
                                floatNum = 0
                            end
                        end
                    end
                    return util_cutCoins(tCoins, isCut, floatNum, noRounding) .. units[index]
                end
            end
        end
    end
    return str_coins
end

return LuxeVegasCollectItemView
