---
--xcyy
--2018年5月23日
--MayanMysteryRespinBar.lua
local MayanMysteryRespinBar = class("MayanMysteryRespinBar",util_require("base.BaseView"))
local PublicConfig = require "MayanMysteryPublicConfig"

function MayanMysteryRespinBar:initUI()

    self:createCsbNode("MayanMystery_respin_spins_bar.csb")

    self:runCsbAction("idle", true)
end

--[[
    刷新当前次数
]]
function MayanMysteryRespinBar:updateCount(count,isInit)
    for index = 1,3 do
        self:findChild(tostring(index)):setVisible(count == index)
    end

    --次数重置动效
    if not isInit and count == 3 then
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("idle", true)
        end)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_num_add)
    end
end

return MayanMysteryRespinBar