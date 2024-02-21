---
--xcyy
--2018年5月23日
--MuchoChilliFreespinBarView.lua

local MuchoChilliFreespinBarView = class("MuchoChilliFreespinBarView",util_require("Levels.BaseLevelDialog"))

MuchoChilliFreespinBarView.m_freespinCurrtTimes = 0


function MuchoChilliFreespinBarView:initUI()

    self:createCsbNode("MuchoChilli_FreeSpinBar.csb")

    self.m_fanKuiEffect = util_createAnimation("MuchoChilli_fankui.csb")
    self:findChild("Node_1"):addChild(self.m_fanKuiEffect)
    self.m_fanKuiEffect:setVisible(false)
end


function MuchoChilliFreespinBarView:onEnter()

    MuchoChilliFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MuchoChilliFreespinBarView:onExit()
    MuchoChilliFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MuchoChilliFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MuchoChilliFreespinBarView:updateFreespinCount( curtimes, totaltimes )
    if totaltimes > 99 then
        self:findChild("m_lb_num1"):setScale(0.7)
        self:findChild("m_lb_num"):setScale(0.7)
    else
        self:findChild("m_lb_num1"):setScale(0.9)
        self:findChild("m_lb_num"):setScale(0.9)
    end

    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num1"):setString(totaltimes)
    
end

--[[
    free more 加次数的动画
]]
function MuchoChilliFreespinBarView:playFreeMoreEffect( )
    self.m_fanKuiEffect:setVisible(true)
    self:runCsbAction("fgcsfankui", false, function()
        self.m_fanKuiEffect:setVisible(false)
    end)
end

return MuchoChilliFreespinBarView