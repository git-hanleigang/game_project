---
--xcyy
--2018年5月23日
--CookieCrunchFreespinBarView.lua

local CookieCrunchFreespinBarView = class("CookieCrunchFreespinBarView",util_require("Levels.BaseLevelDialog"))

CookieCrunchFreespinBarView.m_freespinTotalTimes = 0

function CookieCrunchFreespinBarView:initUI()
    self:createCsbNode("CookieCrunch_FreeSpinBar.csb")
end


function CookieCrunchFreespinBarView:onEnter()

    CookieCrunchFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function CookieCrunchFreespinBarView:onExit()

    CookieCrunchFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function CookieCrunchFreespinBarView:changeFreeSpinByCount()
    local leftFsCount  = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 

    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CookieCrunchFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self.m_freespinTotalTimes = totaltimes

    local label_num1 = self:findChild("m_lb_num1")
    local label_num2 = self:findChild("m_lb_num2")

    label_num1:setString(curtimes)
    label_num2:setString(totaltimes)

    if curtimes < 100 then
        self:updateLabelSize({label=label_num1,sx=0.75,sy=0.75}, 71)
    else
        self:updateLabelSize({label=label_num1,sx=0.5,sy=0.5}, 109)
    end
    
    if totaltimes < 100 then
        self:updateLabelSize({label=label_num2,sx=0.75,sy=0.75}, 71)
    else
        self:updateLabelSize({label=label_num2,sx=0.5,sy=0.5}, 109)
    end
end

--[[
    free玩法开始和结束的展示
]]
function CookieCrunchFreespinBarView:showBar()
    self:setVisible(true)

    self:runCsbAction("show", false,function()
        -- 就一个静帧
        self:runCsbAction("idle", false)
    end)
end
function CookieCrunchFreespinBarView:hideBar()
    self:runCsbAction("over", false,function()
        self:setVisible(false)
    end)
end

return CookieCrunchFreespinBarView