--[[
    free计数栏
]]
local PublicConfig = require "TripleBingoPublicConfig"
local TripleBingoFreespinBarView = class("TripleBingoFreespinBarView", util_require("base.BaseView"))

function TripleBingoFreespinBarView:initUI()
    self:createCsbNode("TripleBingo_FGbar.csb")
end

function TripleBingoFreespinBarView:onEnter()
    TripleBingoFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function TripleBingoFreespinBarView:onExit()
    TripleBingoFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function TripleBingoFreespinBarView:changeFreeSpinByCount()
    local leftFsCount  = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function TripleBingoFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local label1 = self:findChild("m_lb_num1")
    local label2 = self:findChild("m_lb_num2")
    label1:setString(curtimes)
    label2:setString(totaltimes)
    self:updateLabelSize({label=label1, sx=0.55, sy=0.6}, 58)
    self:updateLabelSize({label=label2, sx=0.55, sy=0.6}, 58)
end

function TripleBingoFreespinBarView:playFreeMoreAnim(_func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_58"])
    
    self:runCsbAction("add", false)
    performWithDelay(self, function()
        self:changeFreeSpinByCount()
        if _func then
            _func()
        end
    end, 9/60)
end
return TripleBingoFreespinBarView
