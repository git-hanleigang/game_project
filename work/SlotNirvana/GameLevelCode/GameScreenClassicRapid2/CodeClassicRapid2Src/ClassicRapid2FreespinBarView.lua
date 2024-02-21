---
--xcyy
--2018年5月23日
--ClassicRapid2FreespinBarView.lua

local ClassicRapid2FreespinBarView = class("ClassicRapid2FreespinBarView",util_require("base.BaseView"))

ClassicRapid2FreespinBarView.m_freespinCurrtTimes = 0

function ClassicRapid2FreespinBarView:initUI()

    self:createCsbNode("ClassicRapid2_fs_tanban.csb")

end


function ClassicRapid2FreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ClassicRapid2FreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function ClassicRapid2FreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ClassicRapid2FreespinBarView:updateFreespinCount( curtimes,totaltimes )

    self:findChild("lbs_curNum"):setString( totaltimes - curtimes)
    self:findChild("lbs_sumNum"):setString( totaltimes)

end


return ClassicRapid2FreespinBarView