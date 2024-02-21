---
--AfricaRiseCollectView.lua

local AfricaRiseCollectView = class("AfricaRiseCollectView", util_require("base.BaseView"))
AfricaRiseCollectView.m_nCurRateValue = 0 -- 当前进度值
AfricaRiseCollectView.m_nNewRateValue = 0 -- 需要增长到的值
AfricaRiseCollectView.m_nMaxRateValue = 0 -- 最大进度值
AfricaRiseCollectView.m_nGrowTime = 1 -- 增长时间 默认1秒钟
AfricaRiseCollectView.m_nUpdateRateSchID = nil -- 增长定时器

function AfricaRiseCollectView:initUI()
    self:createCsbNode("AfricaRise_jindutiao.csb")
    self._progressLength = 10 -- 进度条 默认值
    self.m_eff = util_createView("CodeAfricaRiseSrc.AfricaRiseCollectEff")
    self.m_eff:setPosition(cc.p(0,0))
    self.m_csbOwner["m_eff"]:addChild(self.m_eff)
    -- self:updateCollect(0, 0, 0)
    self:runCsbAction("idleframe1",true)
end

function AfricaRiseCollectView:showGray()
    self:runCsbAction("showgary")
end

function AfricaRiseCollectView:hideGray()
    self:runCsbAction("actionframe")
end

function AfricaRiseCollectView:showAddAnim()
    self:runCsbAction("actionframe",false,function (  )
        self:runCsbAction("idleframe1",true)
    end)
end

function AfricaRiseCollectView:initViewData(coins, nCur, nMax)
    self.m_nCurRateValue = nCur or 0
    self.m_nMaxRateValue = nMax or 0
    self:refreshRate()
end

-- coins 金币数量
-- nNewRate 新进度
-- nMaxRate 最大值
function AfricaRiseCollectView:updateCollect(coins, nNewRate, nMaxRate, time)
    self.m_eff:runCsbAction("actionframe",true)
    self.m_nNewRateValue = nMaxRate - nNewRate -- 新的需要增长到的值
    self.m_nMaxRateValue = nMaxRate -- 最大值
    if self.m_nNewRateValue < self.m_nCurRateValue then -- 新目标值 < 当前已经收集道德值 说明已经是触发bonus game 了 到 下一轮收集
        self.m_nCurRateValue = self.m_nNewRateValue
        self:refreshRate(time,true)
        return
    end
    self:updateCollectProgress(time)
end

function AfricaRiseCollectView:updateCollectProgress(time)
    local _nGrowRateValue = (self.m_nNewRateValue - self.m_nCurRateValue) / self.m_nGrowTime
    local stop = false
    if self.m_nUpdateRateSchID ~= nil then
        scheduler.unscheduleGlobal(self.m_nUpdateRateSchID)
        self.m_nUpdateRateSchID = nil
    end
    self.m_nUpdateRateSchID =
        scheduler.scheduleUpdateGlobal(
        function(delayTime)
            if not self.m_nCurRateValue then
                if self.m_nUpdateRateSchID ~= nil then
                    scheduler.unscheduleGlobal(self.m_nUpdateRateSchID)
                    self.m_nUpdateRateSchID = nil
                  
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
                    stop = true
                end
            end
            self:refreshRate(time,stop)
        end
    )
end

-- 刷新进度
function AfricaRiseCollectView:refreshRate(time,stop)
    local fRate = self.m_nCurRateValue / self.m_nMaxRateValue
    local nMaxWidth = 655
    local _offset = 5
    local _width = nMaxWidth * fRate + _offset
    if time then
        -- performWithDelay(
        --     self,
        --     function()
                local percent = fRate * 100
                self.m_csbOwner["AfricaRise_jidu"]:setPercent(percent)
                self.m_eff:setPosition(_width, 0)
                if stop then
                    self.m_eff:runCsbAction("idleframe",false)
                end
        --     end,
        --     time
        -- )
    else
        local percent = fRate * 100
        self.m_csbOwner["AfricaRise_jidu"]:setPercent(percent)
        self.m_eff:setPosition(_width, 0)
        if stop then
            self.m_eff:runCsbAction("idleframe",false)
        end
    end
end

function AfricaRiseCollectView:getCollectPos()
    local sp = self.m_csbOwner["shouji_icon"]
    local pos = sp:getParent():convertToWorldSpace(cc.p(sp:getPosition()))
    return pos
end

function AfricaRiseCollectView:onEnter()
    self.m_csbOwner["AfricaRise_jidu"]:setPercent(0)
    self.m_eff:setPosition(0, 0)
end

function AfricaRiseCollectView:onExit()
    if self.m_nUpdateRateSchID ~= nil then
        scheduler.unscheduleGlobal(self.m_nUpdateRateSchID)
        self.m_nUpdateRateSchID = nil
    end
end

--默认按钮监听回调
function AfricaRiseCollectView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

function AfricaRiseCollectView:setBtnTouch(_bTouch)
end

function AfricaRiseCollectView:progressEffect(percent)
    self.m_csbOwner["AfricaRise_jidu"]:setPercent(percent)
    local oldPercent = self.m_csbOwner["AfricaRise_jidu"]:getPercent()
    local _width = 655 * oldPercent + 5
    self.m_eff:setPositionX(_width)
end

function AfricaRiseCollectView:resetProgress(func)
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
                self:runCsbAction("idleframe1",true)
                if func ~= nil then
                    func()
                end
            end
        end,
        0.016
    )
end

function AfricaRiseCollectView:setPercent(percent)
    self:progressEffect(percent)
end

--播放收集满效果
function AfricaRiseCollectView:playCollectfull(func)

    self:runCsbAction(
        "jiman",
        false,
        function()
            if func then
                func()
            end
        end
    )
end

function AfricaRiseCollectView:setButtonTouchEnabled(_enabled)
    self.m_csbOwner["Button_1"]:setTouchEnabled(_enabled)
end
return AfricaRiseCollectView
