---
--xcyy
--2018年5月23日
--BlackFridayFreespinBarView.lua

local BlackFridayFreespinBarView = class("BlackFridayFreespinBarView",util_require("Levels.BaseLevelDialog"))

BlackFridayFreespinBarView.m_freespinCurrtTimes = 0


function BlackFridayFreespinBarView:initUI(params)

    self.m_machine = params.machine

    self.m_free_bar = util_createAnimation("BlackFriday_free_bar.csb")

    self:addChild(self.m_free_bar)
end


function BlackFridayFreespinBarView:onEnter()

    BlackFridayFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function BlackFridayFreespinBarView:onExit()

    BlackFridayFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

function BlackFridayFreespinBarView:refreshInfo(isSuper)
    if isSuper then
        self.m_free_bar:findChild("Node_free_bar"):setVisible(false)
        self.m_free_bar:findChild("Node_superfree_bar"):setVisible(true)
        self.m_isSuper = true
    else
        self.m_free_bar:findChild("Node_free_bar"):setVisible(true)
        self.m_free_bar:findChild("Node_superfree_bar"):setVisible(false)
        self.m_isSuper = false
    end
end

---
-- 更新freespin 剩余次数
--
function BlackFridayFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BlackFridayFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    local changeFreeNumCallBack = function()
        if not self.m_isSuper then
            self.m_free_bar:findChild("m_lb_num_2"):setString(totaltimes - curtimes)
            self.m_free_bar:findChild("m_lb_num_1"):setString(totaltimes)
        else
            self.m_free_bar:findChild("m_lb_num_4"):setString(totaltimes - curtimes)
            self.m_free_bar:findChild("m_lb_num_3"):setString(totaltimes)
        end
    end

    if self.m_machine.m_isTriggerFreeMore then
        self.m_machine.m_isTriggerFreeMore = false
        self.m_free_bar:runCsbAction("actionframe",false)
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_free_num_change)

        self.m_machine:waitWithDelay(7/60,function()
            changeFreeNumCallBack()
        end)
    else
        changeFreeNumCallBack()
    end
end


return BlackFridayFreespinBarView