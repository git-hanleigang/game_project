---
--xcyy
--2018年5月23日
--OZFreespinBar.lua

local OZFreespinBar = class("OZFreespinBar",util_require("base.BaseView"))


function OZFreespinBar:initUI()

    self:createCsbNode("OZ_FreeSpinBar.csb")

end


function OZFreespinBar:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count

        self:changeCharmsFreeSpinByCount(params)

        
    end,ViewEventType.SHOW_FREE_SPIN_NUM)



end


---
-- 更新freespin 剩余次数
--
function OZFreespinBar:changeCharmsFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end


-- 更新并显示FreeSpin剩余次数
function OZFreespinBar:updateFreespinCount( curtimes ,totalFsCount)
    -- if curtimes == totalFsCount then
    --     self:runCsbAction("start",false)
    -- else
    --     self:runCsbAction("idle",false)
    -- end

    self:updateTimes( curtimes,totalFsCount )
    
end

function OZFreespinBar:updateTimes( curtimes,totalFsCount )
     
    self:findChild("BitmapFontLabel_1"):setString(curtimes) -- 

end

function OZFreespinBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
end


return OZFreespinBar