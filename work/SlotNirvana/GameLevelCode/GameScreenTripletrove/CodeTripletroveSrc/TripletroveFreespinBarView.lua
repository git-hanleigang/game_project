---
--xcyy
--2018年5月23日
--TripletroveFreespinBarView.lua

local TripletroveFreespinBarView = class("TripletroveFreespinBarView",util_require("Levels.BaseLevelDialog"))

TripletroveFreespinBarView.m_freespinCurrtTimes = 0


function TripletroveFreespinBarView:initUI()

    self:createCsbNode("Tripletrove_freecishu.csb")

    self.curLab = nil
    self.totalLab = nil
    self.isBlue = false
end


function TripletroveFreespinBarView:onEnter()

    TripletroveFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function TripletroveFreespinBarView:onExit()

    TripletroveFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function TripletroveFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function TripletroveFreespinBarView:changeLabForFeature(kind)
    if kind[1] == 1 then
        self.isBlue = true
        self:findChild("Node_free_1"):setVisible(false)
        self:findChild("Node_free_2"):setVisible(true)
        self.curLab = self:findChild("m_lb_num_3")
        self.totalLab = self:findChild("m_lb_num_4")
    else
        self.isBlue = false
        self:findChild("Node_free_1"):setVisible(true)
        self:findChild("Node_free_2"):setVisible(false)
        self.curLab = self:findChild("m_lb_num_1")
        self.totalLab = self:findChild("m_lb_num_2")
    end
end

-- 更新并显示FreeSpin剩余次数
function TripletroveFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self.curLab:setString(curtimes)
    self:updateLabelSize({label = self.curLab,sx=0.23,sy=0.23},220)
    self.totalLab:setString(totaltimes)
    if self.isBlue then
        self:updateLabelSize({label = self.totalLab,sx=0.31,sy=0.31},163)
    else
        self:updateLabelSize({label = self.totalLab,sx=0.23,sy=0.23},220)
    end
    
end


return TripletroveFreespinBarView