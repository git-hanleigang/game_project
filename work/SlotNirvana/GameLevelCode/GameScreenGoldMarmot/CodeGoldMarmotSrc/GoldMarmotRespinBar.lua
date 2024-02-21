---
--xcyy
--2018年5月23日
--GoldMarmotRespinBar.lua
local PublicConfig = require "levelsGoldMarmotPublicConfig"
local GoldMarmotRespinBar = class("GoldMarmotRespinBar",util_require("Levels.BaseLevelDialog"))


function GoldMarmotRespinBar:initUI()
    self:createCsbNode("GoldMarmot_respinbar.csb")
    self.m_curLeftCount = 0
    
    self.m_light = util_createAnimation("GoldMarmot_respinbar_fankui.csb")
    self:findChild("node_light"):addChild(self.m_light)
    self.m_light:setVisible(false)
end

function GoldMarmotRespinBar:updateRepinCount(leftCount,isInit)
    for index = 1,3 do
        self:findChild("liang"..index):setVisible(index == leftCount)
    end

    if not isInit then
        
        if leftCount == 3 then
            -- local posX = self:findChild("liang2"):getPositionX()
            -- self:findChild("node_light"):setPositionX(posX)
            self.m_light:setVisible(true)
            self.m_light:runCsbAction("cishuchongzhi",false,function()
                self.m_light:setVisible(false)
            end)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldMarmot_refresh_respin_left)
        end
    end

    self.m_curLeftCount = leftCount
end




return GoldMarmotRespinBar