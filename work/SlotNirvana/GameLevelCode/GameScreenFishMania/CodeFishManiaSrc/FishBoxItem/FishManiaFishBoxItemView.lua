---
--xcyy
--2018年5月23日
--FishManiaFishBoxItemView.lua

local FishManiaFishBoxItemView = class("FishManiaFishBoxItemView",util_require("base.BaseView"))

FishManiaFishBoxItemView.m_itemId = 0

FishManiaFishBoxItemView.m_progressValue = 0

function FishManiaFishBoxItemView:initUI(_itemId)

    self.m_itemId       = _itemId
    self.m_fishItemId   = globalMachineController.p_fishManiaPlayConfig.FishItemId

    self:createCsbNode("FishMania_LittleLogo_" .. self.m_itemId ..".csb")

    self:addClick(self:findChild("wu1_click"))

    self.m_progress = util_createView("CodeFishManiaSrc.FishBoxItem.FishManiaFishBoxItemProgress") 
    self:findChild("progress"):addChild(self.m_progress)

    --初始化展示
    self:setBottomProgress(0)
    self:setBottomProgressVisible(false)
end


function FishManiaFishBoxItemView:onExit()
    gLobalNoticManager:removeAllObservers(self)

    if self.m_jumpHandlerID then
        scheduler.unscheduleGlobal(self.m_jumpHandlerID)
        self.m_jumpHandlerID = nil
    end

    FishManiaFishBoxItemView.super.onExit(self)
end

--默认按钮监听回调
function FishManiaFishBoxItemView:clickFunc(sender)
    local name = sender:getName()
    -- local tag = sender:getTag()

    if name ==  "wu1_click" then 
        self:responseItemClick( )
    end
end

function FishManiaFishBoxItemView:responseItemClick( )
    local p_fishManiaCfg = globalMachineController.p_fishManiaPlayConfig
    gLobalNoticManager:postNotification(p_fishManiaCfg.EventName.FISHBOX_CLICK,{self.m_itemId})
end

-- 刷新鱼缸
function FishManiaFishBoxItemView:upDateFishBoxShow()
    local p_shopData = globalMachineController.p_fishManiaShopData
    local progress = p_shopData:getShopProgress(self.m_itemId)

    self:setBottomProgress(progress)
    --自由鱼缸刷新icon
    if 4==self.m_itemId then
        local curShopIndex = p_shopData:getShowIndex()
        local selectIndex = p_shopData:getSelectIndex(self.m_itemId)
        selectIndex = selectIndex > 0 and selectIndex or curShopIndex
        selectIndex = (0 < selectIndex and selectIndex < 4)  and selectIndex or 1
        for i=1,3 do
            local logo = self:findChild(string.format("icon%d", i))
            if logo then
                logo:setVisible(i==selectIndex)
            end
        end
    end
end
--[[
    进度条
]]
--直接刷新
function FishManiaFishBoxItemView:setBottomProgress(_progressValue)
    self.m_progressValue = _progressValue
    self.m_progress:setProgress(_progressValue)
end
--上涨
function FishManiaFishBoxItemView:jumpBottomProgress(_progressValue)
    --粒子播放
    local particle = self.m_progress:findChild("Particle_1")
    particle:stopSystem()
    particle:setPositionType(0)
    particle:setDuration(-1)
    particle:resetSystem()
    local bar = self.m_progress:findChild("LoadingBar")
    local barWidth = bar:getContentSize().width * 0.8

    self.m_jumpValue = _progressValue
    if self.m_jumpHandlerID then
        scheduler.unscheduleGlobal(self.m_jumpHandlerID)
        self.m_jumpHandlerID = nil
    end

    local offset = self.m_jumpValue - self.m_progressValue
    local interval = offset / (0.5 * 60)
    self.m_jumpHandlerID = scheduler.scheduleUpdateGlobal(function()
        if self.m_progressValue ~= self.m_jumpValue then
            local curValue = self.m_progressValue + interval

            --
            
            particle:setPositionX( - barWidth/2 + barWidth*curValue)

            --是否结束跳动
            if (offset > 0 and  curValue >= self.m_jumpValue) or 
                (offset <= 0 and  curValue <= self.m_jumpValue)  then
                
                curValue = self.m_jumpValue
                self:setBottomProgress(curValue)
            --继续下一次跳动
            else
                self:setBottomProgress(curValue)
                return
            end

        end

        particle:stopSystem()

        if self.m_jumpHandlerID then
            scheduler.unscheduleGlobal(self.m_jumpHandlerID)
            self.m_jumpHandlerID = nil
        end
    end)
end

-- 刷新选中状态
function FishManiaFishBoxItemView:upDateSelectState(_isSelect)
    self:setBottomProgressVisible(_isSelect)
end
function FishManiaFishBoxItemView:setBottomProgressVisible(_isVisible)
    self.m_progress:setVisible(_isVisible)
end

-- 1:未解锁 2:已解锁 3:已完成收集
function FishManiaFishBoxItemView:upDateState()
    local p_shopData = globalMachineController.p_fishManiaShopData
    local showIndex = p_shopData:getShowIndex()
    
    local isUnLock = self.m_itemId <= showIndex
    
    local actName = ""
    if isUnLock then
        local progress = p_shopData:getShopProgress(self.m_itemId)
        local isFinish = progress >= 1
        actName = isFinish and "idleframe3" or "idleframe2"
    else
        actName = "idleframe1"
    end
    self:runCsbAction(actName, true)
end

--[[
    播放动画
]]
--收集
function FishManiaFishBoxItemView:playCollectAnim(_fun)
    -- self:runCsbAction("actionframe2")
end
--收集完成
function FishManiaFishBoxItemView:playCollectFinishAnim(_fun)
    self:runCsbAction("actionframe3", false, function()
        self:runCsbAction("idleframe3", true)
        if _fun then
            _fun()
        end
    end)
end
--解锁
function FishManiaFishBoxItemView:playUnLockAnim(_fun)
    self:runCsbAction("actionframe2", false, function()
        self:runCsbAction("idleframe2", true)
    end)

    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        if _fun then
            _fun()
        end

        waitNode:removeFromParent()
    end,30/60)
end

return FishManiaFishBoxItemView