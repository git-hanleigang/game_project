---
--xcyy
--2018年5月23日
--StarryAnniversaryRespinBar.lua
local StarryAnniversaryRespinBar = class("StarryAnniversaryRespinBar",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "StarryAnniversaryPublicConfig"

function StarryAnniversaryRespinBar:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("StarryAnniversary_RespinBar.csb")
end

--[[
    刷新当前次数
]]
function StarryAnniversaryRespinBar:updateRespinCount(curCount, isComeIn)
    if curCount == 3 then
        if not isComeIn then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_respin_nums_reset)
        end
        self:runCsbAction("actionframe", false)
        performWithDelay(self,function()
            for i = 1, 3 do
                self:findChild("an"..i):setVisible(not(i == curCount))
            end
        end, 10/60)
    else
        for i = 1, 3 do
            self:findChild("an"..i):setVisible(not(i == curCount))
        end
    end
end

return StarryAnniversaryRespinBar