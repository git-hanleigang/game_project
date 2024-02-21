---
--xcyy
--2018年5月23日
--AliceRubyFreespinBarView.lua

local AliceRubyFreespinBarView = class("AliceRubyFreespinBarView",util_require("base.BaseView"))

AliceRubyFreespinBarView.m_freespinCurrtTimes = 0


function AliceRubyFreespinBarView:initUI()
    local resourceFilename="AliceRuby_jishu_free.csb"

    -- self:runCsbAction("idle1") 

    self:createCsbNode(resourceFilename)
    -- self:runCsbAction("idleframe")
    self.m_csbOwner["Alice_cishu_left"]:setString("")
    self.m_csbOwner["Alcie_cishu_total"]:setString("")
end


function AliceRubyFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)


    gLobalNoticManager:addObserver(self,function(params,num)  -- 改变 freespin count显示
        self:changeFreeSpinByCountOutLine(params,num)
    end,ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM)

end

function AliceRubyFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

-- 重连更新freespin 剩余次数
--
function AliceRubyFreespinBarView:changeFreeSpinByCountOutLine(params,changeNum)
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
function AliceRubyFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function AliceRubyFreespinBarView:updateFreespinCount( curtimes,totaltimes )
     self.m_csbOwner["Alice_cishu_left"]:setString(curtimes)
     self.m_csbOwner["Alcie_cishu_total"]:setString(totaltimes)
     if curtimes ~= totaltimes  then
         -- self:runCsbAction("actionframe")
     end
end


return AliceRubyFreespinBarView