---
--xcyy
--2018年5月23日
--KangaPocketsFreespinBarView.lua

local KangaPocketsFreespinBarView = class("KangaPocketsFreespinBarView",util_require("Levels.BaseLevelDialog"))

function KangaPocketsFreespinBarView:initUI()
    self:createCsbNode("KangaPockets_FreeGameBar.csb")
end

function KangaPocketsFreespinBarView:onEnter()
    KangaPocketsFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end
function KangaPocketsFreespinBarView:onExit()
    KangaPocketsFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function KangaPocketsFreespinBarView:changeFreeSpinByCount()
    local leftFsCount  = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function KangaPocketsFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    local lab1 = self:findChild("m_lb_num1")
    local lab2 = self:findChild("m_lb_num2")
    lab1:setString(curtimes)
    lab2:setString(totaltimes)
    self:updateLabelSize({label=lab1,sx=0.7,sy=0.7}, 108)
    self:updateLabelSize({label=lab2,sx=0.7,sy=0.7}, 108)
end

function KangaPocketsFreespinBarView:playAddTimesAnim(_fun)
    self:changeFreeSpinByCount()
    local particle = self:findChild("Particle_1")
    particle:setDuration(0.5)
    particle:stopSystem()
    particle:resetSystem()
    self:runCsbAction("add", false, function()
        particle:stopSystem()
        _fun()
    end)
end

return KangaPocketsFreespinBarView