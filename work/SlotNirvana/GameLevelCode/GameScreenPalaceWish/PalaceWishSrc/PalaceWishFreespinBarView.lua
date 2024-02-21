---
--xcyy
--2018年5月23日
--PalaceWishFreespinBarView.lua

local PalaceWishFreespinBarView = class("PalaceWishFreespinBarView",util_require("Levels.BaseLevelDialog"))

PalaceWishFreespinBarView.m_freespinCurrtTimes = 0


function PalaceWishFreespinBarView:initUI(machine)
    self.m_machine = machine
    -- self:createCsbNode("Puss_tishibar2.csb")

    --普通freespin
    self.m_normal_bar = util_createAnimation("PalaceWish_tishibar2.csb")
    self:addChild(self.m_normal_bar)

    --super free
    self.m_super_bar = util_createAnimation("PalaceWish_superfreebar.csb")
    self.m_machine:findChild("superfreespinBar"):addChild(self.m_super_bar)
    self.m_super_bar:setVisible(false)

    -- local notPos = util_convertToNodeSpace(self.m_machine:findChild("superfreespinBar"), self.m_machine:findChild("freeBar"))
    -- self.m_super_bar:setPosition(cc.p(notPos))
end


function PalaceWishFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function PalaceWishFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function PalaceWishFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function PalaceWishFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self.m_normal_bar:findChild("BitmapFontLabel_1"):setString(curtimes)

    self.m_super_bar:findChild("m_lb_num_1"):setString(totaltimes - curtimes)
    self.m_super_bar:findChild("m_lb_num_2"):setString(totaltimes)
end

--[[
    设置free类型
]]
function PalaceWishFreespinBarView:setFreeType(isSuper)
    self.m_normal_bar:setVisible(not isSuper)
    self.m_super_bar:setVisible(isSuper)
end


return PalaceWishFreespinBarView