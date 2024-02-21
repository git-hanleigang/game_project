---
--xcyy
--2018年5月23日
--MermaidFreespinBarView.lua

local MermaidFreespinBarView = class("MermaidFreespinBarView",util_require("base.BaseView"))

MermaidFreespinBarView.m_freespinCurrtTimes = 0


function MermaidFreespinBarView:initUI()

    self:createCsbNode("Mermaid_TOTAL_BONUSWIN.csb")

    self:restFsNumlab( )

end


function MermaidFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MermaidFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MermaidFreespinBarView:changeFreeSpinByCount()
    
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes =  leftFsCount
    self.m_totalFreeSpinCount =  totalFsCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MermaidFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    

    self:findChild("BitmapFontLabel_2"):setString(curtimes)
    self:findChild("BitmapFontLabel_2_0"):setString(totaltimes)
    
end

function MermaidFreespinBarView:restFsNumlab( )
    self:findChild("BitmapFontLabel_2"):setString("")
    self:findChild("BitmapFontLabel_2_0"):setString("")
end


return MermaidFreespinBarView