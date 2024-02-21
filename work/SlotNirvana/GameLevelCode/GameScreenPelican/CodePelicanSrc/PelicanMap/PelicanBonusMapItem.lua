local PelicanBonusMapItem = class("PelicanBonusMapItem", util_require("base.BaseView"))
-- 构造函数
function PelicanBonusMapItem:initUI(data)
    local resourceFilename = "Pelican_Map_level1.csb"
    self:createCsbNode(resourceFilename)

end

function PelicanBonusMapItem:idle()
    self:runCsbAction("idle", true)
end

function PelicanBonusMapItem:showParticle()

end

function PelicanBonusMapItem:click(func,LitterGameWin)
    
    -- 
    self:findChild("m_lb_coins"):setString(util_formatCoins(LitterGameWin,3))
    gLobalSoundManager:playSound("PelicanSounds/Pelican_collect_small.mp3")
    self:runCsbAction("actionframe",false)
    performWithDelay(self,function (  )
        gLobalSoundManager:playSound("PelicanSounds/Pelican_collect_shipDown.mp3")
    end,1/3)
    performWithDelay(self,function (  )
        if func then
            if func ~= nil then
                func()
            end
        end
    end,3/4)
        
    -- end)

end

function PelicanBonusMapItem:completed()
    self:findChild("m_lb_coins"):setString("")
    self:runCsbAction("idle2", true)
end


return PelicanBonusMapItem