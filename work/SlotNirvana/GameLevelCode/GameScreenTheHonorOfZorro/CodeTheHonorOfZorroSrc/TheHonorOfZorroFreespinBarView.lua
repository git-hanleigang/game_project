---
--xcyy
--2018年5月23日
--TheHonorOfZorroFreespinBarView.lua
local PublicConfig = require "TheHonorOfZorroPublicConfig"
local TheHonorOfZorroFreespinBarView = class("TheHonorOfZorroFreespinBarView",util_require("Levels.BaseLevelDialog"))

TheHonorOfZorroFreespinBarView.m_freespinCurrtTimes = 0


function TheHonorOfZorroFreespinBarView:initUI()
    self.m_isSuperFree = false
    self:createCsbNode("TheHonorOfZorro_free_bar.csb")
    self.m_curTotalCount = 0
end


function TheHonorOfZorroFreespinBarView:onEnter()

    TheHonorOfZorroFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function TheHonorOfZorroFreespinBarView:onExit()

    TheHonorOfZorroFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function TheHonorOfZorroFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount

    if self.m_curTotalCount > 0 and self.m_curTotalCount < totalFsCount then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_add_free_count)
        if self.m_isSuperFree then
            self:runCsbAction("actionframe")
        else
            self:runCsbAction("actionframe1")
        end
        
    end

    self.m_curTotalCount = totalFsCount

    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function TheHonorOfZorroFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num2"):setString(curtimes)
    self:findChild("m_lb_num1"):setString(totaltimes)
    
    self:findChild("m_lb_num4"):setString(curtimes)
    self:findChild("m_lb_num3"):setString(totaltimes)

    self:updateLabelSize({label=self:findChild("m_lb_num1"),sx=0.8,sy=0.8},60)
    self:updateLabelSize({label=self:findChild("m_lb_num2"),sx=0.8,sy=0.8},60)
    self:updateLabelSize({label=self:findChild("m_lb_num3"),sx=0.8,sy=0.8},60)
    self:updateLabelSize({label=self:findChild("m_lb_num4"),sx=0.8,sy=0.8},60)
end

--[[
    显示
]]
function TheHonorOfZorroFreespinBarView:show(isSuperFree)
    self:setVisible(true)
    self.m_isSuperFree = isSuperFree
    self:findChild("Node_free"):setVisible(not isSuperFree)
    self:findChild("Node_superfree"):setVisible(isSuperFree)
end

--[[
    隐藏
]]
function TheHonorOfZorroFreespinBarView:hide()
    self:setVisible(false)
end

return TheHonorOfZorroFreespinBarView