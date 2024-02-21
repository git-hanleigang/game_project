---
--xcyy
--2018年5月23日
--MagicianFreespinBarView.lua

local MagicianFreespinBarView = class("MagicianFreespinBarView",util_require("Levels.BaseLevelDialog"))

MagicianFreespinBarView.m_freespinCurrtTimes = 0


function MagicianFreespinBarView:initUI()

    self:createCsbNode("Magician_SpinNum.csb")

    self:findChild("Node_respin"):setVisible(false)
    self:findChild("Node_free"):setVisible(true)
end


function MagicianFreespinBarView:onEnter()

    MagicianFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MagicianFreespinBarView:onExit()

    MagicianFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MagicianFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MagicianFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("m_lb_num"):setString(totaltimes - curtimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
    
end

--[[
    设置界面类型
]]
function MagicianFreespinBarView:setViewType(viewType)
    if viewType == "free" then
        self:findChild("Node_respin"):setVisible(false)
        self:findChild("Node_free"):setVisible(true)
    else
        self:findChild("Node_respin"):setVisible(true)
        self:findChild("Node_free"):setVisible(false)
    end
end

--[[
    刷新剩余respin次数
]]
function MagicianFreespinBarView:refreshRespinCount(leftCount,isInit)
    
    for index = 1,3 do
        local sign = self:findChild("num"..index.."_1")
        if index == leftCount then
            sign:setVisible(true)
        else
            sign:setVisible(false)
        end
    end

    if isInit then
        return
    end

    if leftCount == 3 then
        gLobalSoundManager:playSound("MagicianSounds/sound_Magician_respin_add_times.mp3")
        self:runCsbAction("actionframe",false,function()
            self:runCsbAction("idleframe")
        end)
    else
        self:runCsbAction("idleframe")
    end
    
end


return MagicianFreespinBarView