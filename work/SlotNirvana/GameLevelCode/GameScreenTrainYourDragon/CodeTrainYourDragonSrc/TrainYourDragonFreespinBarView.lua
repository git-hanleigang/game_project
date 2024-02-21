

local TrainYourDragonFreespinBarView = class("TrainYourDragonFreespinBarView",util_require("base.BaseView"))
-- FIX IOS 139 1
function TrainYourDragonFreespinBarView:initUI()
    self:createCsbNode("TrainYourDragon_fs.csb")
end


function TrainYourDragonFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function TrainYourDragonFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function TrainYourDragonFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function TrainYourDragonFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("BitmapFontLabel_1"):setString(totaltimes - curtimes)
    self:findChild("BitmapFontLabel_1_0"):setString(totaltimes)
end

return TrainYourDragonFreespinBarView