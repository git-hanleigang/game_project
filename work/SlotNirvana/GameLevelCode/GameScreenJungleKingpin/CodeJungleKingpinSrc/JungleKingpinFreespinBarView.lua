---
--xcyy
--2018年5月23日
--JungleKingpinFreespinBarView.lua

local JungleKingpinFreespinBarView = class("JungleKingpinFreespinBarView",util_require("base.BaseView"))

-- 构造函数
function JungleKingpinFreespinBarView:initUI(data)
    local resourceFilename="JungleKingpin_SpinRemaining.csb"
    self:createCsbNode(resourceFilename)
    self.m_csbOwner["BitmapFontLabel_1"]:setString("")
end

function JungleKingpinFreespinBarView:onEnter()

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
function JungleKingpinFreespinBarView:changeFreeSpinByCountOutLine(params,changeNum)
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
function JungleKingpinFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function JungleKingpinFreespinBarView:updateFreespinCount(leftCount,totalCount)

    local rightCount =  totalCount - leftCount
    -- self.m_csbOwner["BitmapFontLabel_1"]:setString(rightCount  .. "/" ..totalCount )
    self.m_csbOwner["BitmapFontLabel_1"]:setString(leftCount)
    local node = self:findChild("BitmapFontLabel_1")
    self:updateLabelSize( {label=node,sx=1,sy=1}, 38)
end

function JungleKingpinFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)
end


return JungleKingpinFreespinBarView