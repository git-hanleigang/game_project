---
--xcyy
--2018年5月23日
--ColorfulCircusLoadfingMapView.lua

local ColorfulCircusLoadfingMapView = class("ColorfulCircusLoadfingMapView",util_require("Levels.BaseLevelDialog"))


function ColorfulCircusLoadfingMapView:initUI()

    self:createCsbNode("ColorfulCircus_collect_zhangpen.csb")
    -- self:runCsbAction("idle")
    self:addClick(self:findChild("Panel_1"))

    --帐篷spine
    self.m_spine = util_spineCreate("ColorfulCircus_collect_zhangpen",true,true)
    self:findChild("spine_node"):addChild(self.m_spine)
    util_spinePlay(self.m_spine,"idle",true)
end

function ColorfulCircusLoadfingMapView:showActionFrame(_func)
    -- performWithDelay(self,function (  )
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_wildCollect_jiman.mp3")
    -- end,110/60)
    -- self:runCsbAction("actionframe2",false,function (  )
    --     if _func then
    --         _func()
    --     end
    --     self:runCsbAction("idle")
    -- end)

    gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_wildCollect_jiman.mp3")

    util_spinePlay(self.m_spine,"actionframe2",false)
    util_spineEndCallFunc(self.m_spine,"actionframe2", function (  )
        if _func then
            _func()
        end
        util_spinePlay(self.m_spine,"idle", true)
    end)
    
end

--默认按钮监听回调
function ColorfulCircusLoadfingMapView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_1" then
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")
        
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

return ColorfulCircusLoadfingMapView