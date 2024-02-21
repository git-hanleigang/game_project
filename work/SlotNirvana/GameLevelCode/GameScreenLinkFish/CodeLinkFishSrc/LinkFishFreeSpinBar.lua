local LinkFishFreeSpinBar = class("LinkFishFreeSpinBar", util_require("base.BaseView"))
-- 构造函数
function LinkFishFreeSpinBar:initUI(data)
    local resourceFilename="Socre_LinkFish_Chip_freespin.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idle")
    self.m_csbOwner["m_lb_num"]:setString(0)
    self:findChild("click_respin_star"):setVisible(false)
end

function LinkFishFreeSpinBar:onEnter()
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
function LinkFishFreeSpinBar:changeFreeSpinByCountOutLine(params,changeNum)
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
function LinkFishFreeSpinBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function LinkFishFreeSpinBar:updateFreespinCount(leftCount,totalCount)
    self.m_csbOwner["m_lb_num"]:setString(leftCount)
end

function LinkFishFreeSpinBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
return LinkFishFreeSpinBar