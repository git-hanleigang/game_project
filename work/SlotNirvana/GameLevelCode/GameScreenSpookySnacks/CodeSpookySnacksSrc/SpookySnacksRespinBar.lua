---
--xcyy
--2018年5月23日
--SpookySnacksRespinBar.lua
local PublicConfig = require "SpookySnacksPublicConfig"
local SpookySnacksRespinBar = class("SpookySnacksRespinBar",util_require("base.BaseView"))


function SpookySnacksRespinBar:initUI()

    self:createCsbNode("SpookySnacks_respin_bar.csb")

    self.actNode = cc.Node:create()
    self:addChild(self.actNode)

end

--[[
    刷新当前次数
]]
function SpookySnacksRespinBar:updateCount(count,isInit)
    -- for index = 1,4 do
    --     self:findChild("sp_count_"..index):setVisible((count + 1) == index)
    -- end
    self.actNode:stopAllActions()
    self:showRespinBarSprite(count)

    --次数重置动效
    if isInit and count == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respinBar_update)
    end
    if isInit and count == 3 then
        
        self:runCsbAction("actionframe")
        performWithDelay(self.actNode,function ()
            for index = 1,4 do
                self:findChild("sp_count_"..index):setVisible((count + 1) == index)
            end
        end,10/60)
    else
        for index = 1,4 do
            self:findChild("sp_count_"..index):setVisible((count + 1) == index)
        end
    end
end

function SpookySnacksRespinBar:showRespinBarSprite(num)
    self:findChild("SpookySnacks_reel_46_3"):setVisible(num == 1)
    self:findChild("SpookySnacks_reel_46_3_0"):setVisible(num == 2 or num == 3 or num == 0)
end

return SpookySnacksRespinBar