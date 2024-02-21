local CashScratchTopScreen = class("CashScratchTopScreen",util_require("Levels.BaseLevelDialog"))

--[[
    _initData = {
        index = 1,
        machine = CodeGameScreenCashScratchMachine,
    }
]]
function CashScratchTopScreen:initUI(_initData)
    self.m_initData = _initData
    self.m_machine = _initData.machine
    --
    self.m_unLockCoin = 0
    -- >=0 参与玩法  -1 没有参与玩法
    self.m_cardCount = -1
    self.m_lockState = true
    -- 是否为展示卡片数量的状态
    self.m_bShowCardCount = false


    self:createCsbNode("CashScratch_top_screen.csb")
    
    self:addClick(self:findChild("lay_unLock"))

    local labCoins = self:findChild("m_lb_coins")
    local scale = labCoins:getScale()
    local width = labCoins:getContentSize().width
    self.m_labelInfo  = {label = labCoins, sx = scale, sy = scale, width = width}

    self:updateIconVisibleByIndex(self.m_initData.index)
end

function CashScratchTopScreen:setUnLockCoin(_coin)
    self.m_unLockCoin = _coin
end

function CashScratchTopScreen:onEnter()
    CashScratchTopScreen.super.onEnter(self)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
    -- 卡片数量 -1
    gLobalNoticManager:addObserver(self,function(self,params)
        self:noticCallBack_bonusCardOver(params)
    end,"CashScratch_bonusCardOver")
end

-- 更新jackpot 数值信息
function CashScratchTopScreen:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    local value = self.m_machine:BaseMania_updateJackpotScore(5 - self.m_initData.index + 1)
    self.m_labelInfo.label:setString(util_formatCoins(value,20,nil,nil,true))
    self:updateLabelSize(self.m_labelInfo, self.m_labelInfo.width)
end

function CashScratchTopScreen:updateIconVisibleByIndex(_index)
    local nameList = {
        [1] = "card",
        [2] = "card_2x",
        [3] = "card_3x",
        [4] = "card_5x",
        [5] = "card_2x3x5x",
    }
    for i,_name in ipairs(nameList) do
        local icon = self:findChild(_name)
        icon:setVisible(_index == i)
    end
end

--[[
    刮刮卡玩法
    >=0 参与玩法 
    -1 没有参与玩法
]]
function CashScratchTopScreen:resetCardCount(_cardCount)
    self.m_cardCount = _cardCount or -1
end
function CashScratchTopScreen:playFlyCardEndAnim(_cardCount)
    self.m_cardCount = _cardCount or self.m_cardCount + 1

    self.m_bShowCardCount = true

    local animName = "switch3"
    if self.m_cardCount > 1 then
        animName = "switch4"
    end

    local particle1 = self:findChild("Particle_1")
    particle1:setDuration(-1)
    particle1:stopSystem()
    particle1:resetSystem()
    self:runCsbAction(animName, false, function()
        particle1:stopSystem()
        self:upDateCardCountLab()
    end)
end
function CashScratchTopScreen:upDateCardCountLab(_count)
    local count = _count or self.m_cardCount
    local labCardCount = self:findChild("m_lb_num")
    labCardCount:setString(count)

    -- card or cards
    local isCards = count > 1

    local idleName = isCards and "idle3" or "idle2"
    self:runCsbAction(idleName, false)
end
function CashScratchTopScreen:changLightAnim(_isLight)
    -- 防止锁定状态下的双重阴影 （锁定不包含阴影了移除规避逻辑）
    -- if nil == self.m_nextVisible and self.m_lockState and self.m_cardCount < 0 then
    --     return
    -- end
    local shadowNode = self:findChild("shadowBonus")
    shadowNode:setVisible(not _isLight)
end
-- 如果当前为展示卡片数量状态，转为展示金币
function CashScratchTopScreen:resetShowCoinsState()
    if self.m_bShowCardCount then
        self.m_bShowCardCount = false
        self:runCsbAction("idle", false)
    end
end
--[[
    bet锁
]]
function CashScratchTopScreen:setLockBetCoins(_value)
    local sCoins = util_formatCoins(_value,4 )

    local labCoins = self:findChild("m_lb_coins_lock")
    local scale = labCoins:getScale()
    local width = labCoins:getContentSize().width
    local info  = {label = labCoins, sx = scale, sy = scale, width = width} 

    labCoins:setString(sCoins)
    self:updateLabelSize(info, info.width)

    self:setUnLockCoin(_value)
end

function CashScratchTopScreen:setLockBetVisible(_visible)
    -- 解锁
    if not _visible then
        -- 还没有完全解锁 不处理等待上一次解锁动画完成
        if nil ~= self.m_nextVisible and _visible == self.m_nextVisible then
        elseif self.m_lockState then
            self.m_nextVisible = _visible
            self:runCsbAction("jiesuo", false, function()
                if nil ~= self.m_nextVisible then
                    self.m_lockState = _visible
                    self.m_nextVisible = nil
                end
            end)
        end
    
    -- 锁定
    else
        self:runCsbAction("suoding", false)
        self.m_lockState = _visible
        self.m_nextVisible = nil
    end
end
-- 获取最新的锁定状态
function CashScratchTopScreen:getLockState()
    if nil ~= self.m_nextVisible then
        return self.m_nextVisible
    else
        return self.m_lockState
    end
end
--[[
    监听事件
]]
function CashScratchTopScreen:noticCallBack_bonusCardOver(_params)
    local symbolType = _params[1]
    local bonusIndex = self.m_machine:getCashScratchBonusSymbolIndex(symbolType)
    if bonusIndex == self.m_initData.index then
        local nextCount = math.max(0, self.m_cardCount-1)
        self:resetCardCount(nextCount)
        self:upDateCardCountLab()
    end
end

--[[
    点击事件
]]
--结束监听
function CashScratchTopScreen:clickEndFunc(sender)
    if not self:isCanClick() then
        return
    end

    local name = sender:getName()

    if name == "lay_unLock" then
        self:clickUnLockBet()
    end
end

function CashScratchTopScreen:clickUnLockBet()
    self.m_machine:clickUnLockBet(self.m_unLockCoin)
end

function CashScratchTopScreen:isCanClick()
    return self.m_machine:isCanUnLockJackpot(self.m_unLockCoin)
end

return CashScratchTopScreen