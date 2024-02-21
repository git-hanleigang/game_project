---
--smy
--2018年4月26日
--FrogPrinceCollectView.lua

local FrogPrinceCollectView = class("FrogPrinceCollectView", util_require("base.BaseView"))

FrogPrinceCollectView.m_nCurRateValue = 0 -- 当前进度值
FrogPrinceCollectView.m_nNewRateValue = 0 -- 需要增长到的值
FrogPrinceCollectView.m_nMaxRateValue = 0 -- 最大进度值
FrogPrinceCollectView.m_nGrowTime = 1 -- 增长时间 默认1秒钟
FrogPrinceCollectView.m_nUpdateRateSchID = nil -- 增长定时器

function FrogPrinceCollectView:initUI()
    self:createCsbNode("FrogPrince_jindutiao.csb")
    self.m_clickFlag = true
    self._progressLength = 10 -- 进度条 默认值
   
    self.m_eff = util_createView("CodeFrogPrinceSrc.FrogPrinceCollectEff")
    self.m_csbOwner["m_eff"]:addChild(self.m_eff)
    self.m_eff:setVisible(false)
    self:updateCollect(0, 0, 100)
    self.m_eff2 = util_createView("CodeFrogPrinceSrc.FrogPrinceCollectEff2")
    self.m_csbOwner["m_eff"]:addChild(self.m_eff2)
    self.m_eff2:showIdle()
    -- self.m_eff2:setVisible(false)

    local touch =self:findChild("Panel_1")
    if touch then
        self:addClick(touch)
    end
    -- self.m_csbOwner["Button_1"]:setHighlighted(false)
    -- self.m_csbOwner["Button_1"]:setTouchEnabled(false)
end

function FrogPrinceCollectView:showGray()
    self:runCsbAction("showgary")
end

function FrogPrinceCollectView:hideGray()
    self:runCsbAction("actionframe")
end

function FrogPrinceCollectView:showAddAnim()
    self:runCsbAction("add")
end

function FrogPrinceCollectView:initCollectNum(num)
    
end

function FrogPrinceCollectView:setButtonTouchEnabled(_enabled)
    -- self.m_csbOwner["Button_1"]:setHighlighted(false)
    self.m_csbOwner["Button_1"]:setTouchEnabled(_enabled)
end

function FrogPrinceCollectView:initViewData(num, nCur, nMax)
    self.m_nCurRateValue = nCur or 0
    self.m_nMaxRateValue = nMax or 0
    self:refreshRate()
end

-- coins 金币数量
-- nNewRate 新进度
-- nMaxRate 最大值
function FrogPrinceCollectView:updateCollect(num, nNewRate, nMaxRate, time)
    self:runCsbAction(
        "actionframe1",
        false,
        function()
        end
    )
    self.m_nNewRateValue = nMaxRate - nNewRate -- 新的需要增长到的值

    self.m_nMaxRateValue = nMaxRate -- 最大值

    if self.m_nNewRateValue < self.m_nCurRateValue then -- 新目标值 < 当前已经收集道德值 说明已经是触发bonus game 了 到 下一轮收集
        self.m_nCurRateValue = self.m_nNewRateValue
        self:refreshRate(time)
        return
    end
    self:updateCollectProgress(time)
end

function FrogPrinceCollectView:updateCollectProgress(time)
    if time then
        performWithDelay(
            self,
            function()
                self.m_eff:showAdd()
                self.m_eff:setVisible(true)
            end,
            time
        )
    else
        self.m_eff:showAdd()
        self.m_eff:setVisible(true)
    end

    if  self.m_nUpdateRateSchID ~= nil then
        scheduler.unscheduleGlobal(self.m_nUpdateRateSchID)
        self.m_nUpdateRateSchID = nil
    end
    
    local _nGrowRateValue = (self.m_nNewRateValue - self.m_nCurRateValue) / self.m_nGrowTime
    self.m_nUpdateRateSchID =
        scheduler.scheduleUpdateGlobal(
        function(delayTime)
            if not self.m_nCurRateValue then
                if self.m_nUpdateRateSchID ~= nil then
                    scheduler.unscheduleGlobal(self.m_nUpdateRateSchID)
                    self.m_nUpdateRateSchID = nil
                end
                if self.m_eff then
                    self.m_eff:setVisible(false)
                end
                return
            end
            self.m_nCurRateValue = self.m_nCurRateValue + _nGrowRateValue * delayTime
            -- 判断是否到达目标
            if self.m_nCurRateValue >= self.m_nNewRateValue then
                self.m_nCurRateValue = self.m_nNewRateValue

                if self.m_nUpdateRateSchID ~= nil then
                    scheduler.unscheduleGlobal(self.m_nUpdateRateSchID)
                    self.m_nUpdateRateSchID = nil
                end
                self.m_eff:setVisible(false)
            end
            self:refreshRate(time)
        end
    )
end
function FrogPrinceCollectView:setMachine(machine)
    self.m_machine = machine
end
-- 刷新进度
function FrogPrinceCollectView:refreshRate(time)
    local fRate = self.m_nCurRateValue / self.m_nMaxRateValue
    local nMaxWidth = 760
    local _offset = -20
    local _width = nMaxWidth * fRate + _offset
    if time then
        performWithDelay(
            self,
            function()
                self.m_csbOwner["sp_progress"]:setPercent(fRate * 100)
                self.m_eff:setPosition(_width, 0)
                if fRate * 100 < 10 then
                    self.m_eff2:setVisible(false)
                else
                    self.m_eff2:setVisible(true)
                end
                self.m_eff2:setPosition(_width, 0)
            end,
            time
        )
    else
        self.m_csbOwner["sp_progress"]:setPercent(fRate * 100)
        self.m_eff:setPosition(_width, 0)
        if fRate * 100 < 10 then
            self.m_eff2:setVisible(false)
        else
            self.m_eff2:setVisible(true)
        end
        self.m_eff2:setPosition(_width, 0)
    end
end

function FrogPrinceCollectView:getCollectPos()
    local sp = self.m_csbOwner["sp_pos"]
    local pos = sp:getParent():convertToWorldSpace(cc.p(sp:getPosition()))
    return pos
end

function FrogPrinceCollectView:getCollectBtnPos()
    local sp = self.m_csbOwner["Button_1"]
    local pos = sp:getParent():convertToWorldSpace(cc.p(sp:getPosition()))
    return pos
end

function FrogPrinceCollectView:onEnter()
    self:runCsbAction("actionframe")
    self.m_csbOwner["sp_progress"]:setPercent(0)
end

function FrogPrinceCollectView:onExit()
    if self.m_nUpdateRateSchID ~= nil then
        scheduler.unscheduleGlobal(self.m_nUpdateRateSchID)
        self.m_nUpdateRateSchID = nil
    end
end

function FrogPrinceCollectView:setPercent(percent)
    self:progressEffect(percent)
end

function FrogPrinceCollectView:progressEffect(percent)
    self.m_csbOwner["sp_progress"]:setPercent(percent)
    local oldPercent = self.m_csbOwner["sp_progress"]:getPercent()
    self.m_eff:setPositionX(oldPercent * 0.01 * 760 - 20)
    if percent < 10 then
        self.m_eff2:setVisible(false)
    else
        self.m_eff2:setVisible(true)
    end
    self.m_eff2:setPositionX(oldPercent * 0.01 * 760 - 20)
end

function FrogPrinceCollectView:resetProgress(func)
    local percent = 100
    self.m_action =
        schedule(
        self,
        function()
            percent = percent - 4
            self:progressEffect(percent)
            if percent == 0 then
                self:stopAction(self.m_action)
                self:setPercent(0)
                if func ~= nil then
                    func()
                end
            end
        end,
        0.016
    )
end

function FrogPrinceCollectView:setClickFlag(_flag)
    self.m_clickFlag = _flag
end
function FrogPrinceCollectView:playLock()
    self.m_csbOwner["m_eff"]:setVisible(false)
    self.m_bLock = true
    self:runCsbAction(
        "lock",
        false,
        function()
        end
    )
end

function FrogPrinceCollectView:setHighLowBetNum(_num)
    local lab = self:findChild("BitmapFontLabel_1")
    local win = util_formatCoins(_num, 5)
    lab:setString(win)
end

function FrogPrinceCollectView:playOpenLock()
    self.m_csbOwner["m_eff"]:setVisible(true)
    self.m_bLock = false
    self:runCsbAction(
        "unlock",
        false,
        function()
        end
    )
end

--播放收集满效果
function FrogPrinceCollectView:playCollectfull(func)
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_collet_full.mp3")
    self:runCsbAction(
        "actionframe2",
        false,
        function()
            if func then
                func()
            end
        end
    )
end

--默认按钮监听回调
function FrogPrinceCollectView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_clickFlag == false then
            return
        end
        self.m_clickFlag = false
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction(
            "click",
            false,
            function()
                gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
            end
        )
    elseif name == "Panel_1" then
        if self.m_bLock == false then
            return
        end
        self.m_bLock = false
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local betList = globalData.slotRunData.machineData:getMachineCurBetList()
        for i=1,#betList do
            local betData = betList[i]
            if betData.p_totalBetValue >= self.m_machine:getMinBet( ) then

                globalData.slotRunData.iLastBetIdx =   betData.p_betId

                break
            end
        end
        
        -- 设置bet index
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    end
end
return FrogPrinceCollectView
