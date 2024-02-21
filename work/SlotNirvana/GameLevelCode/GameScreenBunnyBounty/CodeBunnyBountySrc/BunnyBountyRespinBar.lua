---
--xcyy
--2018年5月23日
--BunnyBountyRespinBar.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyRespinBar = class("BunnyBountyRespinBar",util_require("Levels.BaseLevelDialog"))


function BunnyBountyRespinBar:initUI()

    self:createCsbNode("BunnyBounty_respin_bar.csb")

end

--[[
    刷新当前次数
]]
function BunnyBountyRespinBar:updateCount(count,isInit)
    for index = 1,3 do
        self:findChild("sp_count_"..index):setVisible(count == index)
    end

    if not isInit and count == 3 then
        -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_reset_respin_count)
        self:runCsbAction("actionframe")
    end
end

--[[
    开始动画
]]
function BunnyBountyRespinBar:runStartAni(func)
    self:setVisible(true)
    self:runCsbAction("start",false,func)
end



return BunnyBountyRespinBar