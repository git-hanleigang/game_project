

local ThreeLittlePigsFreespinBarView = class("ThreeLittlePigsFreespinBarView",util_require("base.BaseView"))

function ThreeLittlePigsFreespinBarView:initUI(uiId)
    if uiId == 1 then
        self:createCsbNode("ThreeLittlePigs_FreeSpinNum.csb")--普通free
    elseif uiId == 2 then
        self:createCsbNode("ThreeLittlePigs_superFreeSpinNum.csb")--superfree
    end
end


function ThreeLittlePigsFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ThreeLittlePigsFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

-- 更新freespin 剩余次数
--
function ThreeLittlePigsFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ThreeLittlePigsFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
end

return ThreeLittlePigsFreespinBarView