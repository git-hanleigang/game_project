local FortuneTreeFreeSpinBar = class("FortuneTreeFreeSpinBar", util_require("base.BaseView"))
-- 构造函数
function FortuneTreeFreeSpinBar:initUI(data)
    local resourceFilename="FortuneTree_FreeSpinBar.csb"
    self:createCsbNode(resourceFilename)
end

function FortuneTreeFreeSpinBar:onEnter()

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
function FortuneTreeFreeSpinBar:changeFreeSpinByCountOutLine(params,changeNum)
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
function FortuneTreeFreeSpinBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function FortuneTreeFreeSpinBar:updateFreespinCount(leftCount,totalCount)
    -- self.m_csbOwner["m_lb_num"]:setString("FREE SPINS: "..leftCount)
    self.m_csbOwner["labSpinNum"]:setString(leftCount)
    self.m_csbOwner["labTotalNum"]:setString(totalCount)
end

function FortuneTreeFreeSpinBar:onExit()

    gLobalNoticManager:removeAllObservers(self)
end
return FortuneTreeFreeSpinBar