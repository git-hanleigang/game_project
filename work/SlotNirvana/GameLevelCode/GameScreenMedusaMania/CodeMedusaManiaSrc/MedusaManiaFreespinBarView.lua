---
--xcyy
--2018年5月23日
--MedusaManiaFreespinBarView.lua

local MedusaManiaFreespinBarView = class("MedusaManiaFreespinBarView",util_require("Levels.BaseLevelDialog"))

MedusaManiaFreespinBarView.m_freespinCurrtTimes = 0


function MedusaManiaFreespinBarView:initUI(machine)

    self:createCsbNode("MedusaMania_freebar.csb")

    self:runCsbAction("idle", true)
    self.m_machine = machine

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end


function MedusaManiaFreespinBarView:onEnter()

    MedusaManiaFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MedusaManiaFreespinBarView:onExit()

    MedusaManiaFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

function MedusaManiaFreespinBarView:setCutFreeType(_type)
    self.selectType = _type
    for i=1, 3 do
        if i == _type then
            self:findChild("Node_X"..i):setVisible(true)
        else
            self:findChild("Node_X"..i):setVisible(false)
        end
    end
end

function MedusaManiaFreespinBarView:setIsRefresh(_refresh)
    self.m_refresh = _refresh
end

---
-- 更新freespin 剩余次数
--
function MedusaManiaFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MedusaManiaFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    local delayTime = 0
    if self.m_refresh then
        delayTime = 9/60
    end

    local updateCount = function()
        self:findChild("m_lb_num_1_1"):setString(curtimes)
        self:findChild("m_lb_num_1_2"):setString(totaltimes)

        self:findChild("m_lb_num_2_1"):setString(curtimes)
        self:findChild("m_lb_num_2_2"):setString(totaltimes)

        self:findChild("m_lb_num_3_1"):setString(curtimes)
        self:findChild("m_lb_num_3_2"):setString(totaltimes)
    end

    if self.m_refresh then
        self.m_refresh = false
        local animationName = "start"..self.selectType
        
        self:runCsbAction(animationName, false, function()
            self:runCsbAction("idle", true)
        end)
    end

    performWithDelay(self.m_scWaitNode, function()
        updateCount()
    end, delayTime)
end

return MedusaManiaFreespinBarView
