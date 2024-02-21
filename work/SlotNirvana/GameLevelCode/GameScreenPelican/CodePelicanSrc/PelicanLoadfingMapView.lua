---
--xcyy
--2018年5月23日
--PelicanLoadfingMapView.lua

local PelicanLoadfingMapView = class("PelicanLoadfingMapView",util_require("Levels.BaseLevelDialog"))


function PelicanLoadfingMapView:initUI()

    self:createCsbNode("Pelican_loadingbar_map.csb")
    self:runCsbAction("idle")
    self:addClick(self:findChild("touch_panel"))
end

function PelicanLoadfingMapView:showActionFrame( )
    performWithDelay(self,function (  )
        gLobalSoundManager:playSound("PelicanSounds/Pelican_wildCollect_jiman.mp3")
    end,110/60)
    self:runCsbAction("actionframe",false,function (  )
        self:runCsbAction("idle")
    end)
    
end

--默认按钮监听回调
function PelicanLoadfingMapView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch_panel" then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

return PelicanLoadfingMapView