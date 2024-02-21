---
--xcyy
--2018年5月23日
--FourInOne_FS_TimeisBarView.lua

local FourInOne_FS_TimeisBarView = class("FourInOne_FS_TimeisBarView",util_require("base.BaseView"))


function FourInOne_FS_TimeisBarView:initUI()

    self:createCsbNode("FSReels/freespin_text.csb")


end


function FourInOne_FS_TimeisBarView:onEnter()
 
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end


function FourInOne_FS_TimeisBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function FourInOne_FS_TimeisBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount -  globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FourInOne_FS_TimeisBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString( curtimes)
    self:findChild("BitmapFontLabel_2"):setString(totaltimes)
    
end



return FourInOne_FS_TimeisBarView