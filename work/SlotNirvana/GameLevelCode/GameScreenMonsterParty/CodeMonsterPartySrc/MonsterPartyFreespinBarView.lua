---
--xcyy
--2018年5月23日
--MonsterPartyFreespinBarView.lua

local MonsterPartyFreespinBarView = class("MonsterPartyFreespinBarView",util_require("base.BaseView"))

MonsterPartyFreespinBarView.m_freespinCurrtTimes = 0


function MonsterPartyFreespinBarView:initUI()

    self:createCsbNode("MonsterParty_FS_shu.csb")


end


function MonsterPartyFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MonsterPartyFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MonsterPartyFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MonsterPartyFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(totaltimes - curtimes)

    self:findChild("BitmapFontLabel_1_0"):setString(totaltimes)
    
    
end


return MonsterPartyFreespinBarView