---
--xhkj
--2018年6月11日
--QuickHitTimsBar.lua

local QuickHitTimsBar = class("QuickHitTimsBar", util_require("base.BaseView"))

function QuickHitTimsBar:initUI(data)

    local resourceFilename="Socre_QuickHit_FreeGame.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe")

    self:changeFreeSpinByCount()
    --不知道这个干啥的，还扔屏幕外面
    self:setPositionY(-10000)
    --搞不清楚就隐藏了吧,谁搞清楚就删了吧
    self:setVisible(false)
end


function QuickHitTimsBar:onEnter()

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
function QuickHitTimsBar:changeFreeSpinByCountOutLine(params,changeNum)
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
function QuickHitTimsBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function QuickHitTimsBar:updateFreespinCount( curtimes ,totalFsCount)
    if curtimes == totalFsCount then
        --self:runCsbAction("start",false)
    else
        self:runCsbAction("idleframe",false)
    end

    self:updateTimes( curtimes,totalFsCount )
    
end

function QuickHitTimsBar:updateTimes( curtimes,totalFsCount )
    
    --self:updateLabelSize({label=self:findChild("lab_cur_time"),sx=0.8,sy=0.8},590)
    
    
    self:findChild("lab_cur_time"):setString(totalFsCount - curtimes)
    self:findChild("lab_totle_time"):setString(totalFsCount)

end

function QuickHitTimsBar:onExit()

    gLobalNoticManager:removeAllObservers(self)
end

function QuickHitTimsBar:initMachine(machine)
    self.m_machine = machine
end

return QuickHitTimsBar