---
--xcyy
--2018年5月23日
--ReelRocksFreespinBarView.lua

local ReelRocksFreespinBarView = class("ReelRocksFreespinBarView",util_require("base.BaseView"))

ReelRocksFreespinBarView.m_freespinCurrtTimes = 0


function ReelRocksFreespinBarView:initUI()

    self:createCsbNode("freegamedi.csb")
    self.m_csbOwner["m_lb_num_1"]:setString("")
    self.m_csbOwner["m_lb_num_2"]:setString("")

end


function ReelRocksFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ReelRocksFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function ReelRocksFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ReelRocksFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end


return ReelRocksFreespinBarView