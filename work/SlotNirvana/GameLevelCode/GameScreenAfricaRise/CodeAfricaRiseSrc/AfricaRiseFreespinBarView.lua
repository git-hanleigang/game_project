---
--xcyy
--2018年5月23日
--AfricaRiseFreespinBarView.lua

local AfricaRiseFreespinBarView = class("AfricaRiseFreespinBarView",util_require("base.BaseView"))
AfricaRiseFreespinBarView.m_freespinCurrtTimes = 0

function AfricaRiseFreespinBarView:initUI()
    self:createCsbNode("AfricaRise_fs_cishu.csb")
end

function AfricaRiseFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function AfricaRiseFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
---
-- 更新freespin 剩余次数
--
function AfricaRiseFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function AfricaRiseFreespinBarView:updateFreespinCount(curtimes,totaltimes)
    local nowTimes = totaltimes - curtimes
    self:findChild("m_lb_num"):setString(nowTimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
end

function AfricaRiseFreespinBarView:getCollectPos()
    local sp=self.m_csbOwner["m_lb_num_0"]
    local pos=sp:getParent():convertToWorldSpace(cc.p(sp:getPosition()))
    return pos
end

return AfricaRiseFreespinBarView