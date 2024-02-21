---
--xcyy
--2018年5月23日
--DiscoFeverFreespinBarView.lua

local DiscoFeverFreespinBarView = class("DiscoFeverFreespinBarView",util_require("base.BaseView"))

DiscoFeverFreespinBarView.m_freespinCurrtTimes = 0
DiscoFeverFreespinBarView.imageName = {"DiscoFever_left2_2","DiscoFever_left1_1","DiscoFever_left4_4","DiscoFever_left3_3"}

function DiscoFeverFreespinBarView:initUI()

    self:createCsbNode("DiscoFever_right.csb")


end


function DiscoFeverFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function DiscoFeverFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function DiscoFeverFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function DiscoFeverFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end

function DiscoFeverFreespinBarView:changeImg( index)
    for k,v in pairs(self.imageName) do
        local node = self:findChild(v)
        if index == k then
            if node then
                node:setVisible(true)
            end
        else
            if node then
                node:setVisible(false)
            end
        end
    end
end

return DiscoFeverFreespinBarView