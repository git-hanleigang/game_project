---
--xcyy
--2018年5月23日
--ClassicRapid2ReelsTopBarView.lua

local ClassicRapid2ReelsTopBarView = class("ClassicRapid2ReelsTopBarView",util_require("base.BaseView"))
ClassicRapid2ReelsTopBarView.betLevel = nil
ClassicRapid2ReelsTopBarView.m_open = nil
ClassicRapid2ReelsTopBarView.m_barId = 1
ClassicRapid2ReelsTopBarView.m_curIndex = 0
function ClassicRapid2ReelsTopBarView:initUI(index,machine)
    self.betLevel = nil
    self.m_machine = machine
    self:createCsbNode("ClassicRapid2_jackpot_bar_"..index..".csb")
    self.m_barId = index
    self:runCsbAction("idleframe") -- 播放时间线
    self.m_open = false

    local clickNode = self:findChild("click")
    if clickNode then
        self:addClick(clickNode)
    end
    self:showSpinTime(0)
end

function ClassicRapid2ReelsTopBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)

end

-- 更新jackpot 数值信息
--
function ClassicRapid2ReelsTopBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    local lbLockCoins = self:findChild("lbs_jackpotNum")
    self:updateSize(lbLockCoins,125)
end

function ClassicRapid2ReelsTopBarView:updateSize(lockLbs,width)

    local value=self.m_machine:BaseMania_updateJackpotScore(self.m_barId)
    lockLbs:setString(util_formatCoins(value,20))

    local info2={label=lockLbs,sx = 1,sy = 1}
    self:updateLabelSize(info2,width)
end


function ClassicRapid2ReelsTopBarView:showUnLockBet(coins)
    self:findChild("lbs_unLockBet"):setString(util_formatCoins(coins, 3))
    
end

function ClassicRapid2ReelsTopBarView:showSpinTime(curCount,sumCount)
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
            if showCount > sumCount then
                showCount = sumCount
            end
        end
        self:findChild("lbs_playCurNum"):setString(showCount)
        self:findChild("lbs_curNum"):setString(showCount)
    end


end

function ClassicRapid2ReelsTopBarView:changeState(state,callback,callback2)

    self.m_state = state
    if state == 0 then --award 弹出

        gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_topjackpotChange.mp3")
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
        gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_topjackpotChange.mp3")

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
        gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_topjackpotChange.mp3")

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


function ClassicRapid2ReelsTopBarView:showLock(_leve)

    self.betLevel = _leve
    
    if self.m_barId ~= 5 then
        self:runCsbAction("lock")
        self.m_open = false
    end
    
end

function ClassicRapid2ReelsTopBarView:showUnLock(_leve,_isInit)


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


function ClassicRapid2ReelsTopBarView:onExit()

end

--默认按钮监听回调
function ClassicRapid2ReelsTopBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        
        print("self.m_barId    ".. 6 - self.m_barId)

        if self.m_machine then
            self.m_machine:unlockHigherBet( 6 - self.m_barId )
        end

    end

end


return ClassicRapid2ReelsTopBarView