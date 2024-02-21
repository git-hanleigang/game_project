---
--xcyy
--2018年5月23日
--EgyptCollectBar.lua

local EgyptCollectBar = class("EgyptCollectBar",util_require("base.BaseView"))


function EgyptCollectBar:initUI()

    self:createCsbNode("Egypt_freespin_num.csb")
    self:runCsbAction("idleframe", true)
end


function EgyptCollectBar:onEnter()

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)


    gLobalNoticManager:addObserver(self,function(params,num)  -- 改变 freespin count显示
        self:changeFreeSpinByCountOutLine(params,num)
    end,ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM)
    
end

---
-- 重连更新freespin 剩余次数
--
function EgyptCollectBar:changeFreeSpinByCountOutLine(params,changeNum)
    if changeNum and type(changeNum) == "number" then
        if globalData.slotRunData.totalFreeSpinCount == changeNum then
            return
        end
        local leftFsCount = globalData.slotRunData.freeSpinCount - changeNum
        local totalFsCount = globalData.slotRunData.totalFreeSpinCount
        self:updateFreespinCount(leftFsCount,totalFsCount)
    end
end

---
-- 更新freespin 剩余次数
--
function EgyptCollectBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function EgyptCollectBar:updateFreespinCount(leftCount,totalCount)
    -- self.m_csbOwner["m_lb_num"]:setString("FREE SPINS: "..leftCount)
    self.m_csbOwner["labSpinNum"]:setString(leftCount)
    self.m_csbOwner["labTotalNum"]:setString(totalCount)
end

function EgyptCollectBar:onExit()

    gLobalNoticManager:removeAllObservers(self)
end


return EgyptCollectBar