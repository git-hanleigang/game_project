---
--xcyy
--2018年5月23日
--BingoldKoiFreespinBarView.lua

local BingoldKoiFreespinBarView = class("BingoldKoiFreespinBarView",util_require("Levels.BaseLevelDialog"))

BingoldKoiFreespinBarView.m_freespinCurrtTimes = 0

function BingoldKoiFreespinBarView:initUI()

    self:createCsbNode("BingoldKoi_FreeSpins.csb")

    self:runCsbAction("actionframe", false)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end


function BingoldKoiFreespinBarView:onEnter()

    BingoldKoiFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function BingoldKoiFreespinBarView:setCurSpinType(_isSuper)
    self:runCsbAction("actionframe", false)
    if _isSuper then
        self:findChild("Node_Sup"):setVisible(true)
        self:findChild("Node_Free"):setVisible(false)
    else
        self:findChild("Node_Sup"):setVisible(false)
        self:findChild("Node_Free"):setVisible(true)
    end
end

function BingoldKoiFreespinBarView:setIsRefresh(_refresh)
    self.m_refresh = _refresh
end

function BingoldKoiFreespinBarView:onExit()

    BingoldKoiFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function BingoldKoiFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BingoldKoiFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    local delayTime = 0
    if self.m_refresh then
        delayTime = 11/60
    end
    local updateCount = function()
        local timesNode = self:findChild("m_lb_num")
        if timesNode then
            timesNode:setString(curtimes)
        end
        local timesSuperNode = self:findChild("m_lb_num_0")
        if timesSuperNode then
            timesSuperNode:setString(curtimes)
        end
    end
    if self.m_refresh then
        self.m_refresh = false
        self:runCsbAction("animation_ref")
    end
    performWithDelay(self.m_scWaitNode, function()
        updateCount()
    end, delayTime)
end


return BingoldKoiFreespinBarView