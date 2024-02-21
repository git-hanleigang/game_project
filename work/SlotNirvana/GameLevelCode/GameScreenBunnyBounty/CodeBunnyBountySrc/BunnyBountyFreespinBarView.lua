---
--xcyy
--2018年5月23日
--BunnyBountyFreespinBarView.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyFreespinBarView = class("BunnyBountyFreespinBarView",util_require("Levels.BaseLevelDialog"))

BunnyBountyFreespinBarView.m_freespinCurrtTimes = 0


function BunnyBountyFreespinBarView:initUI()

    self:createCsbNode("BunnyBounty_free_bar.csb")


end


function BunnyBountyFreespinBarView:onEnter()

    BunnyBountyFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function BunnyBountyFreespinBarView:onExit()

    BunnyBountyFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function BunnyBountyFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BunnyBountyFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

--[[
    增加次数动画
]]
function BunnyBountyFreespinBarView:runAddCountAni()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_add_free_count)
    self:runCsbAction("actionframe")
end


return BunnyBountyFreespinBarView