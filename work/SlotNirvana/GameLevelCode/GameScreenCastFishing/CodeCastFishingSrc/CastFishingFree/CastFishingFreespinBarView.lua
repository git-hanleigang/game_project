---
--xcyy
--2018年5月23日
--CastFishingFreespinBarView.lua

local CastFishingFreespinBarView = class("CastFishingFreespinBarView",util_require("Levels.BaseLevelDialog"))

function CastFishingFreespinBarView:initUI()
    self:createCsbNode("CastFishing_FGspin.csb")
    
end


function CastFishingFreespinBarView:onEnter()
    CastFishingFreespinBarView.super.onEnter(self)

    -- 由父类释放
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

---
-- 更新freespin 剩余次数
--
function CastFishingFreespinBarView:changeFreeSpinByCount()
    local leftFsCount  = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 

    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CastFishingFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local leftLab = self:findChild("m_lb_num_1")
    local rightLab = self:findChild("m_lb_num_2")

    leftLab:setString(curtimes)
    rightLab:setString(totaltimes)

    self:updateLabelSize({label=leftLab, sx=0.58, sy=0.58}, 76)
    self:updateLabelSize({label=rightLab, sx=0.58, sy=0.58},76)
end

--[[
    出现消失
]]
function CastFishingFreespinBarView:playStartAnim()
    self:runCsbAction("chuxian", false)
end
function CastFishingFreespinBarView:playOverAnim(_fun)
    self:runCsbAction("xiaoshi", false, _fun)
end


return CastFishingFreespinBarView