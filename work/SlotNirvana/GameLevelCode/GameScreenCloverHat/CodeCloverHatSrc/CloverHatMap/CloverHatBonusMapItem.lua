local CloverHatBonusMapItem = class("CloverHatBonusMapItem", util_require("base.BaseView"))
-- 构造函数
function CloverHatBonusMapItem:initUI(data)
    local resourceFilename = "CloverHat_Map_baozang1.csb"
    self:createCsbNode(resourceFilename)

end

function CloverHatBonusMapItem:idle()
    self:runCsbAction("idle", true)
end

function CloverHatBonusMapItem:showParticle()

end

function CloverHatBonusMapItem:click(func)
    
    gLobalSoundManager:playSound("CloverHatSounds/CloverHat_map_bianChujine.mp3")
    
    self:runCsbAction("actionframe", false, function()
        if func then
            performWithDelay(self, function()
                if func ~= nil then
                    func()
                end
            end, 0.5)
        end
    end)
end

function CloverHatBonusMapItem:completed()
    self:runCsbAction("idle2", true)
end

function CloverHatBonusMapItem:onEnter()

end

function CloverHatBonusMapItem:onExit()

end

return CloverHatBonusMapItem