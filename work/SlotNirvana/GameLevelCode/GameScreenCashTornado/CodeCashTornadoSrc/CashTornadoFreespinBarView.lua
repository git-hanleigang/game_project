---
--xcyy
--2018年5月23日
--CashTornadoFreespinBarView.lua
local PublicConfig = require "CashTornadoPublicConfig"
local CashTornadoFreespinBarView = class("CashTornadoFreespinBarView", util_require("base.BaseView"))

CashTornadoFreespinBarView.m_freespinCurrtTimes = 0

function CashTornadoFreespinBarView:initUI()
    self:createCsbNode("CashTornado_FGbar.csb")

    self.actNode = cc.Node:create()
    self:addChild(self.actNode)
    self.curTotalNum = 0
end

function CashTornadoFreespinBarView:onEnter()
    CashTornadoFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function CashTornadoFreespinBarView:onExit()
    CashTornadoFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function CashTornadoFreespinBarView:initFreeSpinCount(totaltimes)
    self.curTotalNum = 0
    self:findChild("m_lb_num_1"):setString(0)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

---
-- 更新freespin 剩余次数
--
function CashTornadoFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CashTornadoFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    -- if self.curTotalNum ~= curtimes then
    --     self.actNode:stopAllActions()
    --     self:runCsbAction("actionframe")
    --     self.curTotalNum = curtimes
    --     performWithDelay(self.actNode,function ()
    --         self:findChild("m_lb_num_1"):setString(curtimes)
    --     end,3/60)
    -- end
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

return CashTornadoFreespinBarView
