
local ApolloFreespinBarView = class("ApolloFreespinBarView",util_require("base.BaseView"))

function ApolloFreespinBarView:initUI()
    self:createCsbNode("Apollo_fg_tishikuang.csb")
end

function ApolloFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function ApolloFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

-- 更新freespin 剩余次数
--
function ApolloFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ApolloFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("fs_left_num"):setString(curtimes)
    self:findChild("fs_total_num"):setString(totaltimes)
end

return ApolloFreespinBarView