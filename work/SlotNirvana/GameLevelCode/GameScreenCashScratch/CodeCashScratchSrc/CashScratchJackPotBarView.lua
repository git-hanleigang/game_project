---
--xcyy
--2018年5月23日
--CashScratchJackPotBarView.lua

local CashScratchJackPotBarView = class("CashScratchJackPotBarView",util_require("Levels.BaseLevelDialog"))

function CashScratchJackPotBarView:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("CashScratch_jackpot.csb")

    -- self:runCsbAction("idleframe",true)

    self.m_labelNodes = {}
    self.m_jackpotLocks = {}

    for i=9,5,-1 do
        local labCoins = self:findChild( string.format("m_lb_coins_%d", i) )

        local scale = labCoins:getScale()
        local width = labCoins:getContentSize().width
        local info  = {label = labCoins, sx = scale, sy = scale, width = width}
        table.insert(self.m_labelNodes, info)

        -- local lock = util_createAnimation("CashScratch_jackpot_lock.csb") 
        local lock = util_createView("CodeCashScratchSrc.CashScratchJackPotBarLock", {i, _machine})
        
        local lockParent = self:findChild( string.format("lock_%d", i) )
        lockParent:addChild(lock)
        local effectIndex = i - 4
        local effect = lock:findChild( string.format("%d", effectIndex) )
        effect:setVisible(true)
        table.insert(self.m_jackpotLocks, lock)
    end
end

function CashScratchJackPotBarView:onEnter()
    CashScratchJackPotBarView.super.onEnter(self)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function CashScratchJackPotBarView:onExit()
    CashScratchJackPotBarView.super.onExit(self)
end



-- 更新jackpot 数值信息
function CashScratchJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    for _index,_info in ipairs(self.m_labelNodes) do
        local value = self.m_machine:BaseMania_updateJackpotScore(_index + 5)
        _info.label:setString(util_formatCoins(value,20,nil,nil,true))

        self:updateLabelSize(_info, _info.width)
    end
end

--[[
    中奖动画
]]
function CashScratchJackPotBarView:playJackpotWinAnim(_rapidCount)
    self:upDateJackpotWinAnimVisible(_rapidCount)
    
    self:runCsbAction("actionframe", true)
end
function CashScratchJackPotBarView:hideJackpotWinAnim()
    self:runCsbAction("idleframe", false)
end
function CashScratchJackPotBarView:upDateJackpotWinAnimVisible(_rapidCount)
    local animIndex = 1 + 9 - _rapidCount

    for i=1,5 do
        local animNode = self:findChild( string.format("%d", i) )
        animNode:setVisible(animIndex == i)
    end
end
--[[
    bet锁
]]
-- 接口只在进入关卡时调用一次
function CashScratchJackPotBarView:setLockBetCoins(_value, _index)
    local lockIndex = 5 - _index + 1
    local lock = self.m_jackpotLocks[lockIndex]
    local sCoins = util_formatCoins(_value,4 )

    local labCoins = lock:findChild("m_lb_coins")
    local scale = labCoins:getScale()
    local width = labCoins:getContentSize().width
    local info  = {label = labCoins, sx = scale, sy = scale, width = width} 

    labCoins:setString(sCoins)
    self:updateLabelSize(info, info.width)

    lock:setUnLockCoin(_value)
end

function CashScratchJackPotBarView:setLockBetVisible(_visible, _index)
    local lockIndex = 5 - _index + 1
    local lock = self.m_jackpotLocks[lockIndex]
    local curVisible = lock:isVisible()
    
    -- 解锁
    if not _visible then

        -- 还没有完全解锁 不处理等待上一次解锁动画完成
        if nil ~= lock.m_nextVisible and _visible == lock.m_nextVisible then
          
        elseif curVisible then
            lock.m_nextVisible = _visible
            lock:runCsbAction("jiesuo", false, function()
                if nil ~= lock.m_nextVisible then
                    lock.m_nextVisible = nil
                    lock:setVisible(_visible)
                    lock:runCsbAction("idleframe", false)
                end
            end)
        end

    -- 锁定
    else

        -- 上一次的解锁动画还没有完成 突然锁定, 停止时间线
        if nil ~= lock.m_nextVisible and _visible ~= lock.m_nextVisible then
            lock.m_nextVisible = nil
        end

        lock:runCsbAction("idleframe", false)
        lock:setVisible(_visible)
    end
    

    local panelIndex = _index + 4
    local lockPanel = lock:findChild( string.format("Panel_%d", panelIndex) )
    lockPanel:setVisible(_visible)
end


--[[
    切换玩法时切换展示
]]
function CashScratchJackPotBarView:showJackpotBar(_fun)
    self:runCsbAction("start", false, _fun)
end
function CashScratchJackPotBarView:hideJackpotBar(_fun)
    self:runCsbAction("over", false, _fun)
end

return CashScratchJackPotBarView