---
--xcyy
--2018年5月23日
--ScarabChestBoxCoinsView.lua
local PublicConfig = require "ScarabChestPublicConfig"
local ScarabChestBoxCoinsView = class("ScarabChestBoxCoinsView",util_require("Levels.BaseLevelDialog"))

function ScarabChestBoxCoinsView:initUI(_machine)

    self:createCsbNode("ScarabChest_baoxiang_coins.csb")

    self.m_machine = _machine

    self.m_cionsTextTbl = {}
    for i=1, 2 do
        self.m_cionsTextTbl[i] = self:findChild("m_lb_coins_" .. i)
    end

    self:runCsbAction("idle", true)
    self.m_maxWidth = 650

    self.m_scScheduleNode = cc.Node:create()
    self:addChild(self.m_scScheduleNode)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_boxLevel = 1
    self:setLastBoxCoins(0)
end

-- 开始涨钱
function ScarabChestBoxCoinsView:startJumpCouns(params)
    self:clearScheduleNode()
    self:setVisible(true)
    self:playJumpCoinsIdle()
    self.m_endCoins = params.endCoins or 0   --结束金币数
    self.m_duration = params.duration or 2   --持续时间
    self.m_maxWidth = params.maxWidth or 650 --lable最大宽度
    self.m_charLevel = params.charLevel or 0 --字体变色的阈值
    self.m_coinLevel = params.coinLevel or {0, 0} --金币堆等级的阈值
    self.m_endCallFunc = params.endCallFunc -- 结束回调
    self.m_isFreeStart = params.isFreeStart -- free开始
    self.m_isFreeBonus = params.isFreeBonus -- free里bonus玩法
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_BoxCoins_Jump, true)
    --每帧跳动上涨金币数
    self.m_curCoins = self:getLastBoxCoins()
    self.m_coinRiseNum =  (self.m_endCoins - self.m_curCoins) / self.m_duration
    if self.m_scScheduleNode ~= nil then
        self.m_scScheduleNode:onUpdate(function(delayTime)
            self:jumpBonusTotalWin(delayTime)
        end)
    end
end

-- 最终赢钱涨钱
function ScarabChestBoxCoinsView:jumpBonusTotalWin(delayTime)
    self.m_curCoins = self.m_curCoins + self.m_coinRiseNum * delayTime
    if self.m_curCoins >= self.m_endCoins then
        self:clearScheduleNode(true)
        self:setWinCoins(self.m_endCoins)
        self:setLastBoxCoins(self.m_endCoins)
        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    else
        self:setWinCoins(self.m_curCoins)
    end
end

function ScarabChestBoxCoinsView:setWinCoins(curCoins, _onEnter, _isFreeEnd)
    local onEnter = _onEnter
    local isFreeEnd = _isFreeEnd
    if onEnter then
        self:setLastBoxCoins(curCoins)
    end
    for i=1, 2 do
        self.m_cionsTextTbl[i]:setString(self:get_formatCoins(curCoins, 3))
        local info={label =  self.m_cionsTextTbl[i],sx = 1,sy = 1}
        self:updateLabelSize(info, self.m_maxWidth)
    end

    -- 字体显示
    self.m_cionsTextTbl[1]:setVisible(curCoins < self.m_charLevel)
    self.m_cionsTextTbl[2]:setVisible(curCoins >= self.m_charLevel)
    
    -- 宝箱等级
    if not isFreeEnd then
        if curCoins >= self.m_coinLevel[1] and curCoins < self.m_coinLevel[2] then
            if self.m_boxLevel ~= 2 then
                self.m_boxLevel = 2
                self.m_machine:boxSpineSwitchLevel(2)
            end
        elseif curCoins >= self.m_coinLevel[2] then
            if self.m_boxLevel ~= 3 then
                self.m_boxLevel = 3
                self.m_machine:boxSpineSwitchLevel(3)
            end
        end
    end
end

-- 初始化赋值
function ScarabChestBoxCoinsView:setLevelCoins(_charLevel, _coinLevel)
    self:setVisible(true)
    self.m_charLevel = _charLevel
    self.m_coinLevel = _coinLevel
end

function ScarabChestBoxCoinsView:clearScheduleNode(_isOver)
    local isOver = _isOver
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle", true)
    if self.m_scScheduleNode ~= nil then
        self.m_scScheduleNode:unscheduleUpdate()
    end

    if isOver then
        if self.m_isFreeStart then
            -- self:playJumpCoinsIdle()
            if type(self.m_endCallFunc) == "function" then
                self.m_endCallFunc()
            end
        else
            performWithDelay(self.m_scWaitNode, function()
                if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
                    self.m_machine:showFreeBonusOverView(self.m_endCallFunc, self.m_isFreeBonus)
                else
                    self:playTextTrigger()
                    self.m_machine:showBonusOverView(self.m_endCallFunc)
                end
            end, 0.3)
        end
    end
end

-- 字体触发
function ScarabChestBoxCoinsView:playTextTrigger()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idle", true)
    end)
end

-- free结束飞金币
function ScarabChestBoxCoinsView:playFlyCoinsAct()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe2", false, function()
        self:setVisible(false)
    end)
end

function ScarabChestBoxCoinsView:setLastBoxCoins(_lastBaseCoins)
    self.m_lastBoxCoins = _lastBaseCoins
end

function ScarabChestBoxCoinsView:getLastBoxCoins()
    return self.m_lastBoxCoins
end

-- 播放涨钱动画
function ScarabChestBoxCoinsView:playJumpCoinsIdle()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idleframe2", true)
end

-- 关闭
function ScarabChestBoxCoinsView:closeBoxCoins()
    self.m_boxLevel = 1
    self:setLastBoxCoins(0)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

function ScarabChestBoxCoinsView:get_formatCoins(coins, obligate, notCut, normal, noRounding, useRealObligate)
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

return ScarabChestBoxCoinsView
