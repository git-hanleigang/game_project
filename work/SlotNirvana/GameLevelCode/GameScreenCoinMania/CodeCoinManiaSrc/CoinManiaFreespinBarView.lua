---
--xcyy
--2018年5月23日
--CoinManiaFreespinBarView.lua

local CoinManiaFreespinBarView = class("CoinManiaFreespinBarView",util_require("base.BaseView"))

CoinManiaFreespinBarView.m_freespinCurrtTimes = 0


function CoinManiaFreespinBarView:initUI()

    self:createCsbNode("CoinMania_FS_cishu.csb")


end


function CoinManiaFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function CoinManiaFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function CoinManiaFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CoinManiaFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    
end


return CoinManiaFreespinBarView