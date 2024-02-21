---
--xcyy
--2018年5月23日
--SpartaFreespinBarView.lua

local SpartaFreespinBarView = class("SpartaFreespinBarView",util_require("base.BaseView"))

-- 构造函数
function SpartaFreespinBarView:initUI(data)
    local resourceFilename="Sparta_freespin.csb"
    self:createCsbNode(resourceFilename)
    -- self:runCsbAction("idleframe")
    self.m_csbOwner["BitmapFontLabel_1"]:setString("")
end

function SpartaFreespinBarView:onEnter()

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
function SpartaFreespinBarView:changeFreeSpinByCountOutLine(params,changeNum)
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
function SpartaFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function SpartaFreespinBarView:updateFreespinCount(leftCount,totalCount)

    local rightCount =  totalCount - leftCount
    self.m_csbOwner["BitmapFontLabel_1"]:setString(rightCount  .. "/" ..totalCount )
    -- self.m_csbOwner["BitmapFontLabel_1_0"]:setString(totalCount)

    if leftCount ~= totalCount  then
        -- self:runCsbAction("actionframe")
    end
    
end

function SpartaFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)
end


return SpartaFreespinBarView