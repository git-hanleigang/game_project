---
--xcyy
--2018年5月23日
--ChameleonRichesFreespinBarView.lua
local PublicConfig = require "ChameleonRichesPublicConfig"
local ChameleonRichesFreespinBarView = class("ChameleonRichesFreespinBarView", util_require("base.BaseView"))

ChameleonRichesFreespinBarView.m_freespinCurrtTimes = 0

function ChameleonRichesFreespinBarView:initUI()
    self:createCsbNode("ChameleonRiches_FreeGameBar.csb")
end

function ChameleonRichesFreespinBarView:onEnter()
    ChameleonRichesFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function ChameleonRichesFreespinBarView:onExit()
    ChameleonRichesFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function ChameleonRichesFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount

    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)

    self.m_fsTotalCount = totalFsCount
end

-- 更新并显示FreeSpin剩余次数
function ChameleonRichesFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num1_0"):setString(totaltimes)

    self:updateLabelSize({label=self:findChild("m_lb_num1"),sx=0.8,sy=0.8},52)    
    self:updateLabelSize({label=self:findChild("m_lb_num1_0"),sx=0.8,sy=0.8},52)    
    if self.m_fsTotalCount and totaltimes > self.m_fsTotalCount then
        self:runAddCountAni()
    end
end

function ChameleonRichesFreespinBarView:runAddCountAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_add_free_count)
    self:runCsbAction("add",false,func)
end

return ChameleonRichesFreespinBarView
