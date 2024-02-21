--[[

]]
local SettingsLayerFix = class("SettingsLayerFix", BaseLayer)

function SettingsLayerFix:ctor()
    SettingsLayerFix.super.ctor(self)
    -- 横屏资源
    local csbName = "Dialog/LoadingFailed_settingfix.csb"
    self:setLandscapeCsbName(csbName)
end

function SettingsLayerFix:clickFunc(_sander)
    local name = _sander:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_fixnow" then
        self:closeUI(
            function()
                if util_fixHotUpdate then
                    util_fixHotUpdate()
                end
            end
        )
    end
end

return SettingsLayerFix
