---
--xcyy
--2018年5月23日
--GirlsCookFreespinBarView.lua

local GirlsCookFreespinBarView = class("GirlsCookFreespinBarView",util_require("base.BaseView"))

GirlsCookFreespinBarView.m_freespinCurrtTimes = 0


function GirlsCookFreespinBarView:initUI()
    self:createCsbNode("GirlsCook_free_cishu.csb")
end


function GirlsCookFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function GirlsCookFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function GirlsCookFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function GirlsCookFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    
end

--[[
    开始动作
]]
function GirlsCookFreespinBarView:startAni(func)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    增加次数动作
]]
function GirlsCookFreespinBarView:addTimesAni(func)
    self:runCsbAction("add",false,function()
        self:runCsbAction("idle",true)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    结束动作
]]
function GirlsCookFreespinBarView:overAni(func)
    self:runCsbAction("over",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    idle动作
]]
function GirlsCookFreespinBarView:idleAni()
    self:runCsbAction("idle",true)
end

return GirlsCookFreespinBarView