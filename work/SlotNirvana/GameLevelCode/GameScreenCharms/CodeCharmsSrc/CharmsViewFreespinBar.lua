---
--xcyy
--2018年5月23日
--CharmsViewFreespinBar.lua

local CharmsViewFreespinBar = class("CharmsViewFreespinBar",util_require("base.BaseView"))


function CharmsViewFreespinBar:initUI()

    self:createCsbNode("Socre_Charms_Chip_freespin.csb")

end


function CharmsViewFreespinBar:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count

        self:changeCharmsFreeSpinByCount(params)

        
    end,ViewEventType.SHOW_FREE_SPIN_NUM)



end


---
-- 更新freespin 剩余次数
--
function CharmsViewFreespinBar:changeCharmsFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end


-- 更新并显示FreeSpin剩余次数
function CharmsViewFreespinBar:updateFreespinCount( curtimes ,totalFsCount)
    if curtimes == totalFsCount then
        self:runCsbAction("start",false)
    else
        self:runCsbAction("idle",false)
    end

    self:updateTimes( curtimes,totalFsCount )
    
end

function CharmsViewFreespinBar:updateTimes( curtimes,totalFsCount )
     
    self:findChild("m_lb_num_1"):setString(totalFsCount - curtimes) -- 
    self:findChild("m_lb_num_2"):setString(totalFsCount)

end

function CharmsViewFreespinBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
end


return CharmsViewFreespinBar