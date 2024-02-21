---
--xcyy
--2018年5月23日
--ManicMonsterFreespinBarView.lua

local ManicMonsterFreespinBarView = class("ManicMonsterFreespinBarView",util_require("base.BaseView"))

ManicMonsterFreespinBarView.m_freespinCurrtTimes = 0


function ManicMonsterFreespinBarView:initUI()

    self:createCsbNode("ManicMonster_FreeSpins_biaoti.csb")


end


function ManicMonsterFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ManicMonsterFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function ManicMonsterFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ManicMonsterFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    self:findChild("BitmapFontLabel_1_0"):setString(totaltimes)
end


return ManicMonsterFreespinBarView