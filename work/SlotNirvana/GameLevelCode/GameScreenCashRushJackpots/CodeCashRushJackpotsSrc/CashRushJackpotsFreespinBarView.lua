---
--xcyy
--2018年5月23日
--CashRushJackpotsFreespinBarView.lua

local CashRushJackpotsFreespinBarView = class("CashRushJackpotsFreespinBarView",util_require("Levels.BaseLevelDialog"))

CashRushJackpotsFreespinBarView.m_freespinCurrtTimes = 0


function CashRushJackpotsFreespinBarView:initUI()

    self:createCsbNode("CashRushJackpots_freeBar.csb")
    self:runCsbAction("idle", true)

    self.m_bgSpine = util_spineCreate("CashRushJackpots_CS",true,true)
    self:findChild("xingguang"):addChild(self.m_bgSpine)
    util_spinePlay(self.m_bgSpine, "idle", true)

    self.m_text_1 = self:findChild("m_lb_num1")
    self.m_text_2 = self:findChild("m_lb_num2")

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CashRushJackpotsFreespinBarView:onEnter()

    CashRushJackpotsFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function CashRushJackpotsFreespinBarView:onExit()

    CashRushJackpotsFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

function CashRushJackpotsFreespinBarView:showAniTips()
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
    util_spinePlay(self.m_bgSpine, "start", false)
    util_spineEndCallFunc(self.m_bgSpine, "start", function()
        util_spinePlay(self.m_bgSpine, "idle", true)
    end)
end

function CashRushJackpotsFreespinBarView:hideAniTips()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
    util_spinePlay(self.m_bgSpine, "over", false)
    util_spineEndCallFunc(self.m_bgSpine, "over", function()
        self:setVisible(false)
    end)
end

function CashRushJackpotsFreespinBarView:changeFreeStarCount(_freeStarCount)
    local freeStarCount = _freeStarCount
    if freeStarCount == 2 then
        self:findChild("2xwild"):setVisible(true)
        self:findChild("3xwild"):setVisible(false)
    else
        self:findChild("3xwild"):setVisible(true)
        self:findChild("2xwild"):setVisible(false)
    end
end

function CashRushJackpotsFreespinBarView:changeFreeWildCount(_freeWildCount)
    local freeWildCount = _freeWildCount
    self:findChild("m_lb_num3"):setString(freeWildCount)
end

---
-- 更新freespin 剩余次数
--
function CashRushJackpotsFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CashRushJackpotsFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self.m_text_1:setString(curtimes)
    self.m_text_2:setString(totaltimes)
    self:updateLabelSize({label=self.m_text_1,sx=1.0,sy=1.0},110)
    self:updateLabelSize({label=self.m_text_2,sx=1.0,sy=1.0},110)
end


return CashRushJackpotsFreespinBarView