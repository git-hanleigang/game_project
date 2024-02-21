---
--xcyy
--2018年5月23日
--FrozenJewelryFreespinBarView.lua

local FrozenJewelryFreespinBarView = class("FrozenJewelryFreespinBarView",util_require("Levels.BaseLevelDialog"))

FrozenJewelryFreespinBarView.m_freespinCurrtTimes = 0


function FrozenJewelryFreespinBarView:initUI(params)

    -- self:createCsbNode("FrozenJewelry_Free_Bar.csb")
    self.m_csb_freeSpin = util_createAnimation("FrozenJewelry_Free_Bar.csb")
    self.m_csb_superFreeSpin = util_createAnimation("FrozenJewelry_SuperFree_Bar.csb")

    self.m_csb_freeSpin:runCsbAction("idle")
    self.m_csb_superFreeSpin:runCsbAction("idle")

    self:addChild(self.m_csb_freeSpin)
    self:addChild(self.m_csb_superFreeSpin)

    self.m_machine = params.machine
end


function FrozenJewelryFreespinBarView:onEnter()

    FrozenJewelryFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function FrozenJewelryFreespinBarView:onExit()

    FrozenJewelryFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function FrozenJewelryFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FrozenJewelryFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self.m_csb_superFreeSpin:findChild("m_lb_num"):setString(curtimes)
    self:updateLabelSize({label=self.m_csb_superFreeSpin:findChild("m_lb_num"),sx=0.79,sy=0.79},78)
    self.m_csb_superFreeSpin:findChild("SuperFrees_of"):setVisible(curtimes > 1)
    self.m_csb_superFreeSpin:findChild("SuperFree_of"):setVisible(curtimes <= 1)

    self.m_csb_freeSpin:findChild("m_lb_num"):setString(curtimes)
    self:updateLabelSize({label=self.m_csb_freeSpin:findChild("m_lb_num"),sx=0.79,sy=0.79},78)
    self.m_csb_freeSpin:findChild("Frees_of"):setVisible(curtimes > 1)
    self.m_csb_freeSpin:findChild("Free_of"):setVisible(curtimes <= 1)
end


function FrozenJewelryFreespinBarView:pointLightAni()
    if self.m_machine.m_curChoose == 2 then
        self.m_csb_superFreeSpin:runCsbAction("start",false,function()
            self.m_csb_superFreeSpin:runCsbAction("idle")
        end)
    else
        self.m_csb_freeSpin:runCsbAction("start",false,function()
            self.m_csb_freeSpin:runCsbAction("idle")
        end)
    end
    
end

function FrozenJewelryFreespinBarView:showBar()
    self.m_csb_superFreeSpin:setVisible(self.m_machine.m_curChoose == 2)
    self.m_csb_freeSpin:setVisible(self.m_machine.m_curChoose ~= 2)
end

return FrozenJewelryFreespinBarView