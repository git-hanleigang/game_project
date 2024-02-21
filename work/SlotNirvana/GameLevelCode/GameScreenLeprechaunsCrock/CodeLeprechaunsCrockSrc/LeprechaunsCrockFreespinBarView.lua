---
--xcyy
--2018年5月23日
--LeprechaunsCrockFreespinBarView.lua

local LeprechaunsCrockFreespinBarView = class("LeprechaunsCrockFreespinBarView",util_require("Levels.BaseLevelDialog"))

LeprechaunsCrockFreespinBarView.m_freespinCurrtTimes = 0


function LeprechaunsCrockFreespinBarView:initUI(params)

    self.m_machine = params.machine or nil

    self:createCsbNode("LeprechaunsCrock_shangUI.csb")

    self:findChild("Node_base"):setVisible(false)
end


function LeprechaunsCrockFreespinBarView:onEnter()

    LeprechaunsCrockFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function LeprechaunsCrockFreespinBarView:onExit()

    LeprechaunsCrockFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function LeprechaunsCrockFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

--[[
    free more 加次数的动画
]]
function LeprechaunsCrockFreespinBarView:playFreeMoreEffect( )
    self:runCsbAction("actionframe", false)
    self:findChild("Particle_1"):resetSystem()
end

-- 更新并显示FreeSpin剩余次数
function LeprechaunsCrockFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
    
end


return LeprechaunsCrockFreespinBarView