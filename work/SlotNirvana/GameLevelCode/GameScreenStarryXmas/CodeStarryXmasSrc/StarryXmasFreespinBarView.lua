---
--xcyy
--2018年5月23日
--StarryXmasFreespinBarView.lua

local StarryXmasFreespinBarView = class("StarryXmasFreespinBarView",util_require("Levels.BaseLevelDialog"))

StarryXmasFreespinBarView.m_freespinCurrtTimes = 0


function StarryXmasFreespinBarView:initUI(params)

    self.m_machine = params.machine

    self.m_free_bar = util_createAnimation("StarryXmas_jishu_free.csb")

    self:addChild(self.m_free_bar)
end


function StarryXmasFreespinBarView:onEnter()

    StarryXmasFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function StarryXmasFreespinBarView:onExit()

    StarryXmasFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

-- 区分free superfree
function StarryXmasFreespinBarView:refreshInfo(_isSuper)
    if _isSuper then
        self.m_free_bar:findChild("FG"):setVisible(false)
        self.m_free_bar:findChild("Superfg"):setVisible(true)
        self.m_isSuper = true
    else
        self.m_free_bar:findChild("FG"):setVisible(true)
        self.m_free_bar:findChild("Superfg"):setVisible(false)
        self.m_isSuper = false
    end
end

---
-- 更新freespin 剩余次数
--
function StarryXmasFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function StarryXmasFreespinBarView:updateFreespinCount( _curtimes, _totaltimes )
    
    if self.m_isSuper then
        -- self.m_free_bar:runCsbAction("actionframe",false)
        self.m_machine:waitWithDelay(3/60,function(  )
            self.m_free_bar:findChild("m_lb_num_1"):setString(_curtimes)
            self.m_free_bar:findChild("m_lb_num_0_0"):setString(_totaltimes)
        end)
    else
        -- self.m_free_bar:runCsbAction("actionframe2",false)
        self.m_machine:waitWithDelay(3/60,function(  )
            self.m_free_bar:findChild("m_lb_num"):setString(_curtimes)
            self.m_free_bar:findChild("m_lb_num_0"):setString(_totaltimes)
        end)
        
    end
    
end


return StarryXmasFreespinBarView