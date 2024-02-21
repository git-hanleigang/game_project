---
--xcyy
--2018年5月23日
--RoyaleBattleFreespinBarView.lua

local RoyaleBattleFreespinBarView = class("RoyaleBattleFreespinBarView",util_require("base.BaseView"))

RoyaleBattleFreespinBarView.m_freespinCurrtTimes = 0


function RoyaleBattleFreespinBarView:initUI()
    self:createCsbNode("RoyaleBattle_freegamedi.csb")

    self.m_lab_leftTimes = self:findChild("m_lb_num_1")
    self.m_lab_allTimes = self:findChild("m_lb_num_2")
end


function RoyaleBattleFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function RoyaleBattleFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function RoyaleBattleFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount --globalData.slotRunData.freeSpinCount -- 
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function RoyaleBattleFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self.m_lab_leftTimes:setString(curtimes)
    self.m_lab_allTimes:setString(totaltimes)
end

function RoyaleBattleFreespinBarView:playMoreTimesAnim(_fun)
    self:runCsbAction("actionframe", false, function()
        if _fun then
            _fun()
        end
    end)
end


function RoyaleBattleFreespinBarView:getFlyEndNode()
    return self:findChild("m_lb_num_2")
end
return RoyaleBattleFreespinBarView