---
--smy
--2018年4月26日
--PirateCollectView.lua

local PirateCollectView = class("PirateCollectView",util_require("base.BaseView"))

PirateCollectView.m_nCurRateValue = 0  -- 当前进度值
PirateCollectView.m_nNewRateValue = 0  -- 需要增长到的值 
PirateCollectView.m_nMaxRateValue = 0  -- 最大进度值
PirateCollectView.m_nGrowTime = 0.6     -- 增长时间 默认1秒钟
local PROGRESS_WIDTH = 705

function PirateCollectView:initUI()

    self:createCsbNode("Pirate_UI_shang.csb")
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    self._progressLength = 10;  -- 进度条 默认值

    -- self.m_effectNode = self.m_csbOwner["m_eff"]
    -- self.m_particle = util_createView("CodePirateSrc.PirateCollectEff")
    -- self.m_effectNode:addChild(self.m_particle)
    -- self.m_particle:setPosition(0, 0)  

    self.m_ship = util_spineCreate("Pirate_UI_shang_ship", true, true)
    self.m_csbOwner["ship"]:addChild(self.m_ship)
    util_spinePlay(self.m_ship, "idle", true)
    -- self.m_lightLayer = self.m_csbOwner["Panel_1"]

    self.m_binit = true
    self:updateCollect(0,0,100)
    self:addClick(self.m_csbOwner["anniu"])

    
   
end

function PirateCollectView:setFreespinState()
    self.m_csbOwner["sp_progress"]:setOpacity(0.7*255)
    -- self.m_effectNode:setVisible(false)
end
function PirateCollectView:setBaseState()
    self.m_csbOwner["sp_progress"]:setOpacity(255)
    -- self.m_effectNode:setVisible(true)
end

function PirateCollectView:showAddAnim()
    util_spinePlay(self.m_ship, "add", false)
    util_spineEndCallFunc(
        self.m_ship,
        "add",
        function()
            util_spinePlay(self.m_ship, "idle", true)
        end
    )
end

function PirateCollectView:initViewData(coins, nCur, nMax)
    self.m_nCurRateValue = nCur or 0
    self.m_nMaxRateValue = nMax or 0
    self:refreshRate()
end

-- coins 金币数量
-- nNewRate 新进度
-- nMaxRate 最大值
function PirateCollectView:updateCollect(coins, nNewRate, nMaxRate,time)

    self.m_nNewRateValue = nMaxRate - nNewRate  -- 新的需要增长到的值

    
    self.m_nMaxRateValue = nMaxRate  -- 最大值

    if self.m_nNewRateValue < self.m_nCurRateValue then   -- 新目标值 < 当前已经收集道德值 说明已经是触发bonus game 了 到 下一轮收集
        self.m_nCurRateValue = self.m_nNewRateValue 
        self:refreshRate(time)
        return 
    end 
    
    self:updateCollectProgress(time)
    if nNewRate <= 0 and self.m_binit ~= true then
        performWithDelay(self, function()
            self:collectOver()
        end, 0.6)
    end
end


function PirateCollectView:updateCollectProgress(time)
    -- self.m_particle:showAdd()
    -- self:SaoGuang()
    local _nGrowRateValue = (self.m_nNewRateValue - self.m_nCurRateValue) /  self.m_nGrowTime
    self.m_scheduleNode:onUpdate(function(delayTime)
        if not self.m_nCurRateValue  then
            --停止计时器
            self.m_scheduleNode:unscheduleUpdate()
            return
        end
        self.m_nCurRateValue = self.m_nCurRateValue + _nGrowRateValue * delayTime
        -- 判断是否到达目标
        if self.m_nCurRateValue >= self.m_nNewRateValue then             
            self.m_nCurRateValue = self.m_nNewRateValue     
            
            --停止计时器
            self.m_scheduleNode:unscheduleUpdate()
            
            if self.m_binit == false then
                local percent =  self.m_csbOwner["sp_progress"]:getPercent()
                if percent >= 100 then
                end
            end
            self.m_binit = false
        end
        self:refreshRate(time)
       
    end)
end

-- 刷新进度
function PirateCollectView:refreshRate(time)
    local fRate = self.m_nCurRateValue / self.m_nMaxRateValue
    local nMaxWidth = 705;
    local _offset = 10;
    local _width = nMaxWidth * fRate;
    if time then

        performWithDelay(self,function() 
                        
            self.m_csbOwner["sp_progress"]:setPercent(fRate * 100);
            -- self.m_particle:setPositionX(fRate * PROGRESS_WIDTH)
            -- self.m_lightLayer:setContentSize(fRate * PROGRESS_WIDTH, 80)
            -- self.m_particle:setPosition(_width, 0)  
                
        end, time)
    else
        self.m_csbOwner["sp_progress"]:setPercent(fRate * 100);    
        -- self.m_particle:setPositionX(fRate * PROGRESS_WIDTH)
        -- self.m_lightLayer:setContentSize(fRate * PROGRESS_WIDTH, 80)
        -- self.m_particle:setPosition(_width, 0)  
    end
                 
end

--默认按钮监听回调
function PirateCollectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "anniu" then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

function PirateCollectView:getCollectPos()
    local sp=self.m_csbOwner["sp_pos"]
    local pos=sp:getParent():convertToWorldSpace(cc.p(sp:getPosition()))
    return pos
end


function PirateCollectView:onEnter()
    self.m_csbOwner["sp_progress"]:setPercent(0);
    -- self.m_lightLayer:setContentSize(0, 80)
end

function PirateCollectView:onExit()
    --停止计时器
    self.m_scheduleNode:unscheduleUpdate()

end

function PirateCollectView:collectOver()
    self:runCsbAction("wancheng", false, function()
        self:runCsbAction("idle")
    end)
end

function PirateCollectView:SaoGuang()
    self:runCsbAction("saoguang_1", false, function()
        self:runCsbAction("idle")
    end)
end

function PirateCollectView:resetProgress(index, func)
    local percent = 100
    self.m_action = schedule(self,function()
        percent = percent - 4
        self:progressEffect(percent)
        if percent == 0 then
            self:stopAction(self.m_action)
            self:setPercent(0, index)
            if func ~= nil then
                func()
            end
        end
    end,0.016)
end

function PirateCollectView:setPercent(percent, index)
    self:progressEffect(percent)
end
function PirateCollectView:progressEffect(percent,isPlay)
    self.m_csbOwner["sp_progress"]:setPercent(percent)
    -- self.m_lightLayer:setContentSize(percent * 0.01 * PROGRESS_WIDTH, 80)
    -- self.m_particle:setPositionX(percent * 0.01 * PROGRESS_WIDTH)
    -- self.m_particle:showIdle()
    -- local oldPercent =  self.m_csbOwner["sp_progress"]:getPercent()
end

function PirateCollectView:setBtnTouchEnabled(_bTouch)
    self.m_csbOwner["anniu"]:setTouchEnabled(_bTouch)
end

return PirateCollectView