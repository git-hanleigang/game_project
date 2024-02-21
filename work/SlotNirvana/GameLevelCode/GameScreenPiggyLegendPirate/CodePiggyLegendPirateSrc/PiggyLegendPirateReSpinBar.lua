---
--xcyy
--2018年5月23日
--PiggyLegendPirateReSpinBar.lua

local PiggyLegendPirateReSpinBar = class("PiggyLegendPirateReSpinBar",util_require("base.BaseView"))

function PiggyLegendPirateReSpinBar:initUI()
    self:createCsbNode("PiggyLegendPirate_respinbar.csb")
    
    self.m_CurrtTimes = 0
end

---
-- 更新freespin 剩余次数
--
function PiggyLegendPirateReSpinBar:showTimes(times)
    self:updateTimes(times)

    --respin次数重置为3音效
    if(3 == times)then
        -- gLobalSoundManager:playSound("PiggyLegendPirateSounds/PiggyLegendPirateSounds_RS_ReSet.mp3")
    end
end

-- 更新并显示FreeSpin剩余次数
function PiggyLegendPirateReSpinBar:updateTimes(curtimes)
    print("[PiggyLegendPirateReSpinBar:updateTimes] = ", curtimes)
    self.m_CurrtTimes = curtimes
end

function PiggyLegendPirateReSpinBar:playChangeAction(times_node, img_node)
    -- times_node:runCsbAction("actionframe")
end

--[[
    show -> idle -> over
]]
function PiggyLegendPirateReSpinBar:playStartAnim()
    self:setVisible(true)
    self:playIdleAnim()
end

function PiggyLegendPirateReSpinBar:playIdleAnim()
    self:runCsbAction("auto",true)
end

function PiggyLegendPirateReSpinBar:playOverAnim()
    self:setVisible(false)
end


return PiggyLegendPirateReSpinBar