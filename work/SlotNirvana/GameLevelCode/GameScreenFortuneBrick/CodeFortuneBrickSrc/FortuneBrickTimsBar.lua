---
--xhkj
--2018年6月11日
--FortuneBrickTimsBar.lua

local FortuneBrickTimsBar = class("FortuneBrickTimsBar", util_require("base.BaseView"))

function FortuneBrickTimsBar:initUI(data)
    local resourceFilename="Socre_FortuneBrick_FreeSpin.csb"
    self:createCsbNode(resourceFilename)

    self:changeFreeSpinByCount()

end


function FortuneBrickTimsBar:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

---
-- 更新freespin 剩余次数
--
function FortuneBrickTimsBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateTimes(leftFsCount,totalFsCount)
end

function FortuneBrickTimsBar:updateTimes( curtimes,totalFsCount )
    
    --self:updateLabelSize({label=self:findChild("lab_cur_time"),sx=0.8,sy=0.8},590)
    
    self:findChild("BitmapFontLabel_1"):setString(totalFsCount - curtimes)
    self:findChild("BitmapFontLabel_1_0"):setString(totalFsCount)

    self:findChild("BitmapFontLabelsuper_1"):setString(totalFsCount - curtimes)
    self:findChild("BitmapFontLabelsuper_1_0"):setString(totalFsCount)
end

function FortuneBrickTimsBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return FortuneBrickTimsBar