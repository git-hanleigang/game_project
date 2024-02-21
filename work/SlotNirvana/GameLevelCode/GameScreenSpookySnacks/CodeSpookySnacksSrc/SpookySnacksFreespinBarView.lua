---
--xcyy
--2018年5月23日
--SpookySnacksFreespinBarView.lua
local PublicConfig = require "SpookySnacksPublicConfig"
local SpookySnacksFreespinBarView = class("SpookySnacksFreespinBarView", util_require("Levels.BaseLevelDialog"))

SpookySnacksFreespinBarView.m_freespinCurrtTimes = 0

function SpookySnacksFreespinBarView:initUI(params)
    
    self:createCsbNode("SpookySnacks_free_bar.csb")
    self.m_machine = params.machine
end

function SpookySnacksFreespinBarView:onEnter()
    SpookySnacksFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function SpookySnacksFreespinBarView:onExit()
    SpookySnacksFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function SpookySnacksFreespinBarView:refreshInfo(isSuper)
    if isSuper then
        self:findChild("Node_fg"):setVisible(false)
        self:findChild("Node_superfg"):setVisible(true)
        self.m_isSuper = true
    else
        self:findChild("Node_fg"):setVisible(true)
        self:findChild("Node_superfg"):setVisible(false)
        self.m_isSuper = false
    end
end

---
-- 更新freespin 剩余次数
--
function SpookySnacksFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function SpookySnacksFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local changeFreeNumCallBack = function()
        if not self.m_isSuper then
            self:findChild("m_lb_num_2"):setString(totaltimes - curtimes)
            self:findChild("m_lb_num_1"):setString(totaltimes)
        else
            self:findChild("m_lb_num_4"):setString(totaltimes - curtimes)
            self:findChild("m_lb_num_3"):setString(totaltimes)
        end
    end

    if self.m_machine.m_isTriggerFreeMore then
        self.m_machine.m_isTriggerFreeMore = false
        self:runCsbAction("actionframe",false)
        -- gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_free_num_change)

        self.m_machine:delayCallBack(6/60,function()
            changeFreeNumCallBack()
        end)
    else
        changeFreeNumCallBack()
    end
end

return SpookySnacksFreespinBarView
