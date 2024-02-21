---
--xcyy
--2018年5月23日
--VegasLifeFreespinBarView.lua

local VegasLifeFreespinBarView = class("VegasLifeFreespinBarView",util_require("base.BaseView"))

VegasLifeFreespinBarView.m_freespinCurrtTimes = 0
VegasLifeFreespinBarView.m_IsBonusCollectFull = false

function VegasLifeFreespinBarView:initUI()

    self:createCsbNode("VegasLife_fs_tanban.csb")

end


function VegasLifeFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function VegasLifeFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

function VegasLifeFreespinBarView:changeBgFreeSpin(IsBonusCollectFull)
    self.m_IsBonusCollectFull = IsBonusCollectFull
    if self.m_IsBonusCollectFull then
        self:findChild("Node_free_0"):setVisible(true)
        self:findChild("Node_free"):setVisible(false)
    else
        self:findChild("Node_free_0"):setVisible(false)
        self:findChild("Node_free"):setVisible(true)
    end
end
---
-- 更新freespin 剩余次数
--
function VegasLifeFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function VegasLifeFreespinBarView:updateFreespinCount( curtimes,totaltimes )

    if self.m_IsBonusCollectFull then
        self:findChild("lbs_curNum1"):setString( totaltimes - curtimes)
        self:findChild("lbs_sumNum1"):setString( totaltimes)
    else
        self:findChild("lbs_curNum"):setString( totaltimes - curtimes)
        self:findChild("lbs_sumNum"):setString( totaltimes)
    end
end


return VegasLifeFreespinBarView