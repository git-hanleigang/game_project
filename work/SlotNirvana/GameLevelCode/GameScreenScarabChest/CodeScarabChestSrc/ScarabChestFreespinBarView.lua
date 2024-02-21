---
--xcyy
--2018年5月23日
--ScarabChestFreespinBarView.lua
local PublicConfig = require "ScarabChestPublicConfig"
local ScarabChestFreespinBarView = class("ScarabChestFreespinBarView", util_require("base.BaseView"))

ScarabChestFreespinBarView.m_freespinCurrtTimes = 0

function ScarabChestFreespinBarView:initUI()
    self:createCsbNode("ScarabChest_FGbar.csb")

    self:runCsbAction("idle", true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function ScarabChestFreespinBarView:onEnter()
    ScarabChestFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self, function(params) -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end, ViewEventType.SHOW_FREE_SPIN_NUM)
end

function ScarabChestFreespinBarView:onExit()
    ScarabChestFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function ScarabChestFreespinBarView:setFreeAni(_isFreeMore)
    self.m_isFreeMore = _isFreeMore
end

---
-- 更新freespin 剩余次数
--
function ScarabChestFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ScarabChestFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)

    if self.m_isFreeMore then
        self.m_isFreeMore = false
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_FgCount_Add)
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("idle", true)
        end)
    end
end

return ScarabChestFreespinBarView
