---
--xcyy
--2018年5月23日
--HowlingMoonRespinBarView.lua

local HowlingMoonRespinBarView = class("HowlingMoonRespinBarView", util_require("base.BaseView"))

HowlingMoonRespinBarView.m_freespinCurrtTimes = 0

function HowlingMoonRespinBarView:initUI()
    self:createCsbNode("Socre_HowlingMoon_spinremaining.csb")
end

function HowlingMoonRespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function()
            -- 显示 freespin count
            self:updateLeftCount(globalData.slotRunData.iReSpinCount, false)
        end,
        ViewEventType.SHOW_RESPIN_SPIN_NUM
    )
end

function HowlingMoonRespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function HowlingMoonRespinBarView:showRespinBar(totalRespin)
    self:updateLeftCount(totalRespin,true)
end

-- 更新 respin 次数
function HowlingMoonRespinBarView:updateLeftCount(respinCount,isfirst)
    for i = 1, 3 do
        if i == respinCount then
            self:findChild(i.. "light"):setVisible(true)
        else
            self:findChild(i.. "light"):setVisible(false)
        end
    end
   
    if respinCount == 3 then
        self:runCsbAction("animation0")
        if not isfirst then
            gLobalSoundManager:playSound("HowlingMoonSounds/sound_HowlingMoon_unlock_highbet.mp3")
        end
    end

    
end

return HowlingMoonRespinBarView
