---
--xcyy
--2018年5月23日
--FortuneGodFreespinBarView.lua

local FortuneGodFreespinBarView = class("FortuneGodFreespinBarView",util_require("Levels.BaseLevelDialog"))

FortuneGodFreespinBarView.m_freespinCurrtTimes = 0


function FortuneGodFreespinBarView:initUI(data)
    self:createCsbNode("FortuneGod_freeandrespinwenzi.csb")
    self.type = data
    self.Node = cc.Node:create()
    self:addChild(self.Node)
    if data == "free" then
        self:findChild("Node_link"):setVisible(false)
        self:findChild("Node_free"):setVisible(true)
        self:findChild("Node_superfree"):setVisible(false)
    else
        self:findChild("Node_link"):setVisible(true)
        self:findChild("Node_free"):setVisible(false)
        self:findChild("Node_superfree"):setVisible(false)
        self.bianPao = util_spineCreate("FortuneGod_Freeandrespinwenzi",true,true)
        self:findChild("bianpao"):addChild(self.bianPao)
        self:Idle()
    end
    
    self.m_freespinCurrtTimes = 0
end

function FortuneGodFreespinBarView:Idle( )
    self.Node:stopAllActions()
    util_spinePlay(self.bianPao,"idleframe",false)
    util_spineEndCallFunc(self.bianPao,"idleframe",function (  )
        util_spinePlay(self.bianPao,"idleframe2",true)
    end)
    performWithDelay(self.Node,function (  )
        self:Idle()
    end,3)

end

function FortuneGodFreespinBarView:changeShowFree(isSuper)
    self.isSuper = isSuper
    if isSuper then
        self:findChild("Node_free"):setVisible(false)
        self:findChild("Node_superfree"):setVisible(true)
    else
        self:findChild("Node_free"):setVisible(true)
        self:findChild("Node_superfree"):setVisible(false)
    end
end

function FortuneGodFreespinBarView:onEnter()

    FortuneGodFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function FortuneGodFreespinBarView:onExit()
    FortuneGodFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function FortuneGodFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FortuneGodFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    if self.isSuper then
        self:findChild("m_lb_num_2"):setString(curtimes)
        self:findChild("m_lb_num_3"):setString(totaltimes)
    else
        self:findChild("m_lb_num_0"):setString(curtimes)
        self:findChild("m_lb_num_1"):setString(totaltimes)
    end
    
    
end


return FortuneGodFreespinBarView