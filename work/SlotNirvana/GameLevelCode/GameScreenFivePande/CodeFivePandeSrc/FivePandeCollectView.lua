---
--smy
--2018年4月26日
--CollectView.lua

local CollectView = class("CollectView", util_require("base.BaseView"))

CollectView.m_nCurRateValue = 0 -- 当前进度值
CollectView.m_nNewRateValue = 0 -- 需要增长到的值
CollectView.m_nMaxRateValue = 0 -- 最大进度值
CollectView.m_nGrowTime = 1 -- 增长时间 默认1秒钟
CollectView.m_nUpdateRateSchID = nil -- 增长定时器

function CollectView:initUI(machine)
    self.m_machine = machine

    self:createCsbNode("FivePande/CollectView.csb")

    self._progressLength = 10 -- 进度条 默认值
    -- scheduler.performWithDelayGlobal(function()
    --     self:updateCollect(10086,34,100)
    -- end, 0.5)

    self.m_eff = util_createView("CodeFivePandeSrc.FivePandeCollectEff")
    self.m_csbOwner["sp_progress"]:addChild(self.m_eff)
    self.m_eff:setVisible(true)
    self.m_eff:setPosition(0, 23)
    self:updateCollect(0, 0, 100)

    self:runCsbAction("idleframe", true)
end

function CollectView:showGray()
    -- self:runCsbAction("showgary")
    -- for k,node in pairs(self.m_csbOwner) do
    --     if k=="FivePande_topbar3_4" then
    --         util_setSpriteGray(node)
    --     else
    --         if tolua.type(node)=="ccui.LoadingBar" then
    --             local sp=node:getVirtualRenderer()
    --             util_setSpriteGray(sp)
    --         else
    --             util_setSpriteGray(node)
    --         end
    --     end
    -- end
end

function CollectView:hideGray()
    -- self:runCsbAction("actionframe")
    -- for k,node in pairs(self.m_csbOwner) do
    --     if tolua.type(node)=="ccui.LoadingBar" then
    --         local sp=node:getVirtualRenderer()
    --         util_clearSpriteGray(sp)
    --     else
    --         util_clearSpriteGray(node)
    --     end
    -- end
end

function CollectView:showAddAnim()
    self:runCsbAction(
        "add",
        false,
        function()
            self:runCsbAction("idleframe", true)
        end
    )
end

function CollectView:initViewData(coins, nCur, nMax)
    self.m_nCurRateValue = nCur or 0
    self.m_nMaxRateValue = nMax or 0
    self:refreshRate()
end

-- coins 金币数量
-- nNewRate 新进度
-- nMaxRate 最大值
function CollectView:updateCollect(coins, nNewRate, nMaxRate, time)
    if time then
        performWithDelay(
            self,
            function()
                self.m_csbOwner["m_lb_coins"]:setString("$" .. util_formatCoins(coins, 5))
            end,
            time
        )
    else
        self.m_csbOwner["m_lb_coins"]:setString("$" .. util_formatCoins(coins, 5))
    end

    -- if nNewRate == 0 then
    --     self.m_nNewRateValue = nNewRate  -- 新的需要增长到的值
    -- elseif nMaxRate == nNewRate then
    --     self.m_nNewRateValue = 0
    -- else
    self.m_nNewRateValue = nMaxRate - nNewRate -- 新的需要增长到的值
    -- end

    self.m_nMaxRateValue = nMaxRate -- 最大值

    if self.m_nNewRateValue < self.m_nCurRateValue then -- 新目标值 < 当前已经收集道德值 说明已经是触发bonus game 了 到 下一轮收集
        self.m_nCurRateValue = self.m_nNewRateValue
        self:refreshRate(time)
        return
    end
    self:updateCollectProgress(time)
end

function CollectView:updateCollectProgress(time)
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
                -- self.m_eff:setVisible(false)
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
            -- self.m_eff:setVisible(false)
            end
            self:refreshRate(time)
        end
    )
end

-- 刷新进度
function CollectView:refreshRate(time)
    local fRate = self.m_nCurRateValue / self.m_nMaxRateValue
    local nMaxWidth = 632
    local _width = nMaxWidth * fRate - 8
    if time then
        performWithDelay(
            self,
            function()
                -- self.m_csbOwner["sp_progress"]:setPercent(fRate * 100);
                self.m_eff:setPosition(_width, 23)
            end,
            time
        )
    else
        -- self.m_csbOwner["sp_progress"]:setPercent(fRate * 100);
        self.m_eff:setPosition(_width, 23)
    end
end

function CollectView:getCollectPos()
    local sp = self.m_csbOwner["sp_pos"]
    local pos = sp:getParent():convertToWorldSpace(cc.p(sp:getPosition()))
    return pos
end

function CollectView:onEnter()
    -- self:runCsbAction("actionframe")
    -- self.m_csbOwner["sp_progress"]:setPercent(0);
    self.m_eff:setPosition(0, 23)
end

function CollectView:onExit()
    if self.m_nUpdateRateSchID ~= nil then
        scheduler.unscheduleGlobal(self.m_nUpdateRateSchID)
        self.m_nUpdateRateSchID = nil
    end
end

--默认按钮监听回调
function CollectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then
        self.m_machine:checkShowTipView()
    end
end

return CollectView
