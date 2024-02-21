---
--xcyy
--2018年5月23日
--EasterFreespinBarView.lua

local EasterFreespinBarView = class("EasterFreespinBarView", util_require("base.BaseView"))

EasterFreespinBarView.m_freespinCurrtTimes = 0

function EasterFreespinBarView:initUI()
    self:createCsbNode("FreeGameTip.csb")

    local rabbit1 = util_spineCreate("Easter_Logoshang", true, true)
    self:findChild("spine_Easter_Logoshang"):addChild(rabbit1)
    util_spinePlay(rabbit1, "idle", true)

    self.m_rabbit2 = util_spineCreate("Easter_Logoxia", true, true)
    self:findChild("spine_Easter_Logoxia"):addChild(self.m_rabbit2)
    util_spinePlay(self.m_rabbit2, "idle", true)
    self.m_bPlay = false
end

function EasterFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function EasterFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function EasterFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function EasterFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local spinTimes = totaltimes - curtimes
    self:findChild("m_lb_cur"):setString(spinTimes)
    self:findChild("m_lb_num"):setString(totaltimes)
end

--刷新次数特效
function EasterFreespinBarView:changeTimeAni()
    if self.m_bPlay then
        return
    end
    self.m_bPlay = true
    self:runCsbAction("actionframe")

    self:findChild("Particle_3"):resetSystem()
    self:findChild("Particle_3_0"):resetSystem()
    util_spinePlay(self.m_rabbit2, "actionframe", false)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            self.m_bPlay = false
            waitNode:removeFromParent()
            util_spinePlay(self.m_rabbit2, "idle", true)
        end,
        29 / 30
    )
end

return EasterFreespinBarView
