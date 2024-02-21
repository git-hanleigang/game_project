local CastFishingClickEffect = class("CastFishingClickEffect",util_require("Levels.BaseLevelDialog"))
local CastFishingMusicConfig = require "CodeCastFishingSrc.CastFishingMusicConfig"

function CastFishingClickEffect:initUI()
    self:createCsbNode("CastFishing_dianjifankui.csb")
    self.m_effectNode = self:findChild("Node_effect")

    self:addClick(self:findChild("Panel_click"))
end

--默认按钮监听回调
function CastFishingClickEffect:clickFunc(sender)
    local touchEndPos = sender:getTouchEndPosition()
    local nodePos     = self.m_effectNode:getParent():convertToNodeSpace(touchEndPos)
    self.m_effectNode:setPosition(nodePos)
    self:runCsbAction("dianji", false)
    self:playEffectSound()
end
function CastFishingClickEffect:playEffectSound()
    self:stopAllActions()
    
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    self.m_soundId = gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_clickBaseBg)
    performWithDelay(self,function()
        self.m_soundId = nil
    end, 1)
end

return CastFishingClickEffect