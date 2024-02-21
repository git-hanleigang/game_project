---
--xcyy
--2018年5月23日
--ThorFreespinBarView.lua

local ThorFreespinBarView = class("ThorFreespinBarView",util_require("base.BaseView"))


function ThorFreespinBarView:initUI()
    self:createCsbNode("Thor_freespin_tip.csb")
end


function ThorFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ThorFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end
function ThorFreespinBarView:playAddSpinFreeSpinCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    local rightFsCount = totalFsCount - leftFsCount
    self:runCsbAction("actionframe")
    self:updateFreespinCount(rightFsCount,totalFsCount)
    -- print("leftFsCount ===============================" .. leftFsCount)
    -- print("totalFsCount ==============================" .. totalFsCount)
end
---
-- 更新freespin 剩余次数
--
function ThorFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    local rightFsCount = totalFsCount - leftFsCount
    self:updateFreespinCount(rightFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ThorFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    self:findChild("totalLabel"):setString(totaltimes)
end

function ThorFreespinBarView:getCollectPos()
    local sp=self:findChild("totalLabel")
    local pos=sp:getParent():convertToWorldSpace(cc.p(sp:getPosition()))
    return pos
end


return ThorFreespinBarView