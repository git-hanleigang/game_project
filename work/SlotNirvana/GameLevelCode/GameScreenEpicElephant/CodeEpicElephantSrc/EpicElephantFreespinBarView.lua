---
--xcyy
--2018年5月23日
--EpicElephantFreespinBarView.lua

local EpicElephantFreespinBarView = class("EpicElephantFreespinBarView",util_require("Levels.BaseLevelDialog"))

EpicElephantFreespinBarView.m_freespinCurrtTimes = 0


function EpicElephantFreespinBarView:initUI(params)

    self.m_machine = params.machine

    self.m_free_bar = util_createAnimation("EpicElephant_freebar.csb")
    self.m_super_free_bar = util_createAnimation("EpicElephant_superfreebar.csb")

    self:addChild(self.m_free_bar)
    self:addChild(self.m_super_free_bar)
end


function EpicElephantFreespinBarView:onEnter()

    EpicElephantFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function EpicElephantFreespinBarView:onExit()

    EpicElephantFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

function EpicElephantFreespinBarView:refreshInfo(triggerType,isSuper)
    if isSuper then
        self.m_super_free_bar:setVisible(true)
        self.m_free_bar:setVisible(false)
        self.m_curShowBar = self.m_super_free_bar
    else
        self.m_super_free_bar:setVisible(false)
        self.m_free_bar:setVisible(true)
        self.m_curShowBar = self.m_free_bar
    end

    self.m_curShowBar:findChild("mini"):setVisible(triggerType == self.m_machine.SYMBOL_BONUS_MINI)
    self.m_curShowBar:findChild("minor"):setVisible(triggerType == self.m_machine.SYMBOL_BONUS_MINOR)
    self.m_curShowBar:findChild("major"):setVisible(triggerType == self.m_machine.SYMBOL_BONUS_MAJOR)
    self.m_curShowBar:findChild("mega"):setVisible(triggerType == self.m_machine.SYMBOL_BONUS_MEGA)
end

---
-- 更新freespin 剩余次数
--
function EpicElephantFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function EpicElephantFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self.m_free_bar:findChild("m_lb_num1"):setString(totaltimes - curtimes)
    self.m_free_bar:findChild("m_lb_num2"):setString(totaltimes)

    self.m_super_free_bar:findChild("m_lb_num1"):setString(totaltimes - curtimes)
    self.m_super_free_bar:findChild("m_lb_num2"):setString(totaltimes)
    if totaltimes > 99 then
        self.m_free_bar:findChild("m_lb_num1"):setScale(0.45)
        self.m_free_bar:findChild("m_lb_num2"):setScale(0.45)
    else
        self.m_free_bar:findChild("m_lb_num1"):setScale(0.65)
        self.m_free_bar:findChild("m_lb_num2"):setScale(0.65)
    end
end


return EpicElephantFreespinBarView