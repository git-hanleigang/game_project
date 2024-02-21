---
--xcyy
--2018年5月23日
--CandyBingoFreespinBar.lua

local CandyBingoFreespinBar = class("CandyBingoFreespinBar",util_require("base.BaseView"))


function CandyBingoFreespinBar:initUI()

    self:createCsbNode("CandyBingo_FreeGamebar.csb")

end


function CandyBingoFreespinBar:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count

        self:changeCharmsFreeSpinByCount(params)

        
    end,ViewEventType.SHOW_FREE_SPIN_NUM)



end


---
-- 更新freespin 剩余次数
--
function CandyBingoFreespinBar:changeCharmsFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end


-- 更新并显示FreeSpin剩余次数
function CandyBingoFreespinBar:updateFreespinCount( curtimes ,totalFsCount)
    -- if curtimes == totalFsCount then
    --     self:runCsbAction("start",false)
    -- else
    --     self:runCsbAction("idle",false)
    -- end

    self:updateTimes( curtimes,totalFsCount )
    
end

function CandyBingoFreespinBar:updateTimes( curtimes,totalFsCount )
     
    self:findChild("m_lb_num1"):setString(totalFsCount - curtimes) -- 
    self:findChild("m_lb_num2"):setString(totalFsCount)

end

function CandyBingoFreespinBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
end


return CandyBingoFreespinBar