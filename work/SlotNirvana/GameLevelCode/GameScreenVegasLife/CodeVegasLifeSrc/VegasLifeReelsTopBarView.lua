---
--xcyy
--2018年5月23日
--VegasLifeReelsTopBarView.lua

local VegasLifeReelsTopBarView = class("VegasLifeReelsTopBarView",util_require("base.BaseView"))
VegasLifeReelsTopBarView.betLevel = nil
VegasLifeReelsTopBarView.m_open = nil
VegasLifeReelsTopBarView.m_barId = 1
VegasLifeReelsTopBarView.m_curIndex = 0
function VegasLifeReelsTopBarView:initUI(index,machine)
    self.betLevel = nil
    self.m_machine = machine
    self:createCsbNode("VegasLife_jackpot_bar_"..index..".csb")
    self.m_barId = index
    self:runCsbAction("idleframe") -- 播放时间线
    self.m_open = false

    self.m_barWin = util_createAnimation("VegasLife_jackpot_bar_win.csb")
    self:findChild("Win"):addChild(self.m_barWin)
    self.m_barWin:runCsbAction("idle") -- 播放时间线

    local clickNode = self:findChild("click")
    if clickNode then
        self:addClick(clickNode)
    end
    self:showSpinTime(0)
end

function VegasLifeReelsTopBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)

end

-- 更新jackpot 数值信息
--
function VegasLifeReelsTopBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    local lbLockCoins = self:findChild("lbs_jackpotNum")
    self:updateSize(lbLockCoins,125)
end

function VegasLifeReelsTopBarView:updateSize(lockLbs,width)

    local value=self.m_machine:BaseMania_updateJackpotScore(self.m_barId)
    lockLbs:setString(util_formatCoins(value,20))

    local info2={label=lockLbs,sx = 1,sy = 1}
    self:updateLabelSize(info2,width)
end


function VegasLifeReelsTopBarView:showUnLockBet(coins)
    self:findChild("lbs_unLockBet"):setString(util_formatCoins(coins, 3))
    
end

function VegasLifeReelsTopBarView:showSpinTime(curCount,sumCount)
    self.m_curIndex = curCount
    self:findChild("lbs_awardSpin"):setString(curCount)
    --2 2 +1 1
    --1 2 +1 2
    --0 2 +1 3
    if sumCount then
        self:findChild("lbs_playSumNum"):setString(sumCount)
        self:findChild("lbs_sumNum"):setString(sumCount)
        local showCount = curCount
        if sumCount then
            showCount = sumCount - curCount
            if curCount ~= 0 then
                showCount = sumCount - curCount + 1
            end
            if showCount > sumCount then
                showCount = sumCount
            end
        end
        self:findChild("lbs_playCurNum"):setString(showCount)
        self:findChild("lbs_curNum"):setString(showCount)
    end


end

function VegasLifeReelsTopBarView:changeState(state,callback,callback2)

    self.m_state = state
    if state == 0 then --award 弹出
        self:runCsbAction("start1")
        if callback then
            callback()
        end
    elseif state == 1 then --award 待机
        self:runCsbAction("idleframe1",true)
    elseif state == 2 then --award 收回
        self:runCsbAction("over1",false,function()
            if callback then
                callback()
            end
        end)
    elseif state == 3 then -- play弹出

        self:runCsbAction("start2",false,function()
            if callback then
                callback()
            end
        end)
    elseif state == 4 then-- playidle
        self:runCsbAction("idleframe2",true)
    elseif state == 5 then-- playover
        self:runCsbAction("over2",false,function()
            if callback then
                callback()
            end
        end)
    elseif state == 6 then-- complete start

        self:runCsbAction("start3",false,function()
            if callback then
                callback()
            end
        end)
    elseif state == 7 then-- complete idle
        self:runCsbAction("idleframe3",true)
    elseif state == 8 then-- complete over
        self:runCsbAction("over3",false,function()
            if callback then
                callback()
            end
        end)
    elseif state == 9 then-- complete over
        self:runCsbAction("shouji1",false,function(  )
            
        end)
        if callback then
            callback()
        end
        if callback2 then
            callback2()
        end
    elseif state == -1 then-- complete over
        self:runCsbAction("idleframe",false,function()
            if callback then
                callback()
            end
        end)
    end
end


function VegasLifeReelsTopBarView:showLock(_leve)

    self.betLevel = _leve
    
    if self.m_barId ~= 5 then
        self:runCsbAction("lock")
        self.m_open = false
    end
    
end

function VegasLifeReelsTopBarView:showUnLock(_leve,_isInit)


    if self.betLevel and self.betLevel == _leve then
        return
    end

    if self.m_barId ~= 5 then
        if not self.m_open then
            self.m_open = true
            if _isInit then 
                self:runCsbAction("jiesuo2")
            else
                self:runCsbAction("jiesuo")
            end
            
        end
    end

    self.betLevel = _leve
    
end

-- 显示jiakpot中奖预告
function VegasLifeReelsTopBarView:showJacpPotYuGao( )
    self.m_barWin:runCsbAction("actionframe"..self.m_barId, true)
end

-- 隐藏jiakpot中奖预告
function VegasLifeReelsTopBarView:unShowJacpPotYuGao( )
    self.m_barWin:runCsbAction("idle")
end

function VegasLifeReelsTopBarView:onExit()

end

--默认按钮监听回调
function VegasLifeReelsTopBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        
        print("self.m_barId    ".. 6 - self.m_barId)

        if self.m_machine then
            self.m_machine:unlockHigherBet( 6 - self.m_barId )
        end

    end

end


return VegasLifeReelsTopBarView