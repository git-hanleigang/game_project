

local KoiBlissFreespinBarView = class("KoiBlissFreespinBarView",util_require("base.BaseView"))

function KoiBlissFreespinBarView:initUI()
    self:createCsbNode("KoiBliss_free_fgbar.csb")
end


function KoiBlissFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function KoiBlissFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

-- 更新freespin 剩余次数
function KoiBlissFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function KoiBlissFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("m_lb_num_0"):setString(totaltimes)
    self:findChild("m_lb_num_1"):setString(totaltimes - curtimes )
end


return KoiBlissFreespinBarView