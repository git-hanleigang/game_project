---
--xcyy
--2018年5月23日
--TheHonorOfZorroRespinBar.lua
local PublicConfig = require "TheHonorOfZorroPublicConfig"
local TheHonorOfZorroRespinBar = class("TheHonorOfZorroRespinBar",util_require("Levels.BaseLevelDialog"))


function TheHonorOfZorroRespinBar:initUI()

    self:createCsbNode("TheHonorOfZorro_respin_bar.csb")

    self.m_items = {}
    for index = 1,3 do
        local item = util_createAnimation("TheHonorOfZorro_respinbar_cishu.csb")
        self:findChild("Node_"..index):addChild(item)
        for iCount = 1,3 do
            item:findChild("Node_"..iCount):setVisible(iCount == index)
        end
        self.m_items[index] = item
    end
end

--[[
    刷新当前次数
]]
function TheHonorOfZorroRespinBar:updateCount(count,isInit)
    for index = 1,3 do
        local item = self.m_items[index]
        if index == count then
            item:findChild("wu"..index):setVisible(false)
            item:findChild("you"..index):setVisible(true)
        else
            item:findChild("wu"..index):setVisible(true)
            item:findChild("you"..index):setVisible(false)
        end
    end

    if not isInit and count == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_reset_respin_count)
        self.m_items[3]:runCsbAction("actionframe")
    end
end



return TheHonorOfZorroRespinBar