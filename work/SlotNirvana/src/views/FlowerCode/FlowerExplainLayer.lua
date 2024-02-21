--规则
local FlowerExplainLayer = class("FlowerExplainLayer", BaseLayer)

function FlowerExplainLayer:ctor()
    FlowerExplainLayer.super.ctor(self)
    -- 设置横屏csb
    self:setLandscapeCsbName("Activity/csd/EasterSeason_Explain.csb")
    self:setPortraitCsbName("Activity/csd/EasterSeason_Explain_vertical.csb")
end

function FlowerExplainLayer:clickFunc(_sender)
    local name = _sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" then
        self:closeUI()
    end
end
return FlowerExplainLayer
