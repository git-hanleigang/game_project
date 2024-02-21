---
--xcyy
--2018年5月23日
--ToroLocoRespinBar.lua
local ToroLocoRespinBar = class("ToroLocoRespinBar",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "ToroLocoPublicConfig"

function ToroLocoRespinBar:initUI(params)
    self:createCsbNode("ToroLoco_ReSpinBar.csb")
end

--[[
    刷新当前次数
]]
function ToroLocoRespinBar:updateRespinCount(curCount, totalCount, _isComeIn)
    if curCount == 1 then
        self:findChild("Zi"):setVisible(false)
        self:findChild("zi1"):setVisible(true)
    else
        self:findChild("Zi"):setVisible(true)
        self:findChild("zi1"):setVisible(false)
    end
    self:findChild("m_lb_num"):setString(curCount)
    
    if curCount == totalCount then
        if not _isComeIn then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ToroLoco_respinNums_add)
        end
        self:runCsbAction("add", false)
    end
end

return ToroLocoRespinBar