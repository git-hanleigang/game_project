---
--xcyy
--2018年5月23日
--LuxuryDiamondFreespinBarView.lua

local LuxuryDiamondFreespinBarView = class("LuxuryDiamondFreespinBarView",util_require("Levels.BaseLevelDialog"))

LuxuryDiamondFreespinBarView.m_freespinCurrtTimes = 0


function LuxuryDiamondFreespinBarView:initUI()

    self:createCsbNode("LuxuryDiamond_freegameBar.csb")

    -- self.m_fankui = util_createAnimation("LuxuryDiamond_shoujifankui.csb")
    -- self:findChild("Node_free"):addChild(self.m_fankui)
    -- self.m_fankui:setPosition(self:findChild("m_lb_num_2"):getPosition())
    -- self.m_fankui:setVisible(false)
end


function LuxuryDiamondFreespinBarView:onEnter()
    LuxuryDiamondFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function LuxuryDiamondFreespinBarView:onExit()
    
    gLobalNoticManager:removeAllObservers(self)
    LuxuryDiamondFreespinBarView.super.onExit(self)
end

---
-- 更新freespin 剩余次数
--
function LuxuryDiamondFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function LuxuryDiamondFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_1"):setString(totaltimes - curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)

    -- local isHundred = (totaltimes - curtimes) > 99 or totaltimes > 99
    -- self:setBarNodePos(isHundred)

    self:updateLabelSize({label = self:findChild("m_lb_num_1"), sx = 1, sy = 1}, 42)
    self:updateLabelSize({label = self:findChild("m_lb_num_2"), sx = 1, sy = 1}, 42)
end

function LuxuryDiamondFreespinBarView:showFankui()
    -- self.m_fankui:setVisible(true)
    -- self.m_fankui:playAction("fankui", false, function()
    --     self.m_fankui:setVisible(false)
    -- end)

    self:runCsbAction("actionframe", false, function()
        
    end)
end

function LuxuryDiamondFreespinBarView:setBarNodePos(isHundred)
    if isHundred then
        --百位数 显示位置设置
        self:findChild("m_lb_num_1"):setPositionX(29.4)
        self:findChild("free_cishukuang_wenzi2"):setPositionX(88.6)
        self:findChild("free_cishukuang_wenzi1"):setPositionX(-112)
    else
        self:findChild("m_lb_num_1"):setPositionX(57.4)
        self:findChild("free_cishukuang_wenzi2"):setPositionX(104.2)
        self:findChild("free_cishukuang_wenzi1"):setPositionX(-73.5)
    end
end


return LuxuryDiamondFreespinBarView