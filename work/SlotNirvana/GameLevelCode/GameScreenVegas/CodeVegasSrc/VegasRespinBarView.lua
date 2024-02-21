---
--xcyy
--2018年5月23日
--VegasRespinBarView.lua

local VegasRespinBarView = class("VegasRespinBarView", util_require("base.BaseView"))

VegasRespinBarView.m_freespinCurrtTimes = 0

function VegasRespinBarView:initUI()
    self:createCsbNode("Vegas_respin_counter.csb")
    local node = self:findChild("effectNode")
    self.m_effect = util_createView("CodeVegasSrc.VegasRespinResetEffect")
    node:addChild(self.m_effect)
end

function VegasRespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function()
            -- 显示 freespin count
            self:updateLeftCount(globalData.slotRunData.iReSpinCount, false)
        end,
        ViewEventType.SHOW_RESPIN_SPIN_NUM
    )
end

function VegasRespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function VegasRespinBarView:showRespinBar(totalRespin)
    self:updateLeftCount(totalRespin, true)
end

-- 更新 respin 次数
function VegasRespinBarView:updateLeftCount(respinCount, bstart)
    for i = 1, 3 do
        if i == respinCount then
            self:findChild("huang" .. i):setVisible(true)
            self:findChild("qian" .. i):setVisible(true)
            self:findChild("zi" .. i):setVisible(false)
            self:findChild("shen" .. i):setVisible(false)
        else
            self:findChild("huang" .. i):setVisible(false)
            self:findChild("qian" .. i):setVisible(false)
            self:findChild("zi" .. i):setVisible(true)
            self:findChild("shen" .. i):setVisible(true)
        end
    end
    if not bstart then
        if self.m_effect and respinCount == 3 then
            self.m_effect:playAddRespinNum()
            gLobalSoundManager:playSound("VegasSounds/sound_vegas_respin_reset_num3.mp3")
        end
    end
end

return VegasRespinBarView
