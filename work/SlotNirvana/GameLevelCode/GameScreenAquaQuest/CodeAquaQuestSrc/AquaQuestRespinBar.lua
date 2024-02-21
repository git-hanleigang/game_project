---
--xcyy
--2018年5月23日
--AquaQuestRespinBar.lua
local PublicConfig = require "AquaQuestPublicConfig"
local AquaQuestRespinBar = class("AquaQuestRespinBar",util_require("Levels.BaseLevelDialog"))


function AquaQuestRespinBar:initUI()

    self:createCsbNode("AquaQuest_respinbar.csb")
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function AquaQuestRespinBar:initSpineUI()
    
end


function AquaQuestRespinBar:updateCurRespinCount(count)
    local label = self:findChild("m_lb_num")
    if not tolua.isnull(label) then
        label:setString(count)
    end

    self:findChild("Zi1_dan"):setVisible(count <= 1)
    self:findChild("Zi1_0"):setVisible(count > 1)
end



return AquaQuestRespinBar