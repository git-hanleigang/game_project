---
--xcyy
--2018年5月23日
--BeerGirlFreespinBarView.lua

local BeerGirlFreespinBarView = class("BeerGirlFreespinBarView",util_require("base.BaseView"))

-- 构造函数
function BeerGirlFreespinBarView:initUI(data)
    local resourceFilename="BeerGirl_fs_tishi.csb"

    self:runCsbAction("idle1") 

    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe")
    self.m_csbOwner["BitmapFontLabel_1"]:setString("")
    self.m_csbOwner["BitmapFontLabel_1_0"]:setString("")
end

function BeerGirlFreespinBarView:onEnter()

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
function BeerGirlFreespinBarView:changeFreeSpinByCountOutLine(params,changeNum)
    if changeNum and type(changeNum) == "number" then
        if globalData.slotRunData.totalFreeSpinCount == changeNum then
            return
        end
        local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
        local totalFsCount = globalData.slotRunData.totalFreeSpinCount
        self:updateFreespinCount(leftFsCount,totalFsCount)
    end
end

---
-- 更新freespin 剩余次数
--
function BeerGirlFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function BeerGirlFreespinBarView:updateFreespinCount(leftCount,totalCount)
    -- self.m_csbOwner["m_lb_num"]:setString("FREE SPINS: "..leftCount)
    self.m_csbOwner["BitmapFontLabel_1"]:setString(leftCount)
    self.m_csbOwner["BitmapFontLabel_1_0"]:setString(totalCount)

    if leftCount ~= totalCount  then
        -- self:runCsbAction("actionframe")
    end
    
end

function BeerGirlFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)
end


return BeerGirlFreespinBarView