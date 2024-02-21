local PelicanBonusMapBigLevel = class("PelicanBonusMapBigLevel", util_require("base.BaseView"))

local maxImgNum_3Reel = 15
local maxImgNum_4Reel = 20
PelicanBonusMapBigLevel.m_maxImgNum = 20

-- 构造函数
local DESCRIBE_LAYER_WIDTH = 212
function PelicanBonusMapBigLevel:initUI(data)
    local resourceFilename = "Pelican_Map_level2"

    if data.info.mapRows == "maprow3" then
        resourceFilename = "Pelican_Map_level2.csb"
        self.m_maxImgNum = maxImgNum_3Reel

    elseif data.info.mapRows == "maprow4" then
        resourceFilename = "Pelican_Map_level2_0.csb"
        self.m_maxImgNum = maxImgNum_4Reel
    end

    self:createCsbNode(resourceFilename)

    self:initLockWild( data.info.fixPos )

    self:idle()
    
end

function PelicanBonusMapBigLevel:initLockWild( fixPos )
    
    for i=1,self.m_maxImgNum do
        local img = self:findChild("CloverHat_wild_img_" .. i - 1) 
        if img then
            img:setVisible(false)
        end
    end

    for i=1,#fixPos do
        local img = self:findChild("CloverHat_wild_img_" .. fixPos[i]) 
        if img then
            img:setVisible(true)
        end
    end

end

function PelicanBonusMapBigLevel:idle()
    self:runCsbAction("idle")
end

function PelicanBonusMapBigLevel:click(func)
    gLobalSoundManager:playSound("PelicanSounds/Pelican_collect_big.mp3")
    gLobalSoundManager:playSound("PelicanSounds/Pelican_collect_shipDown.mp3")
    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            func()
        end
    end)
end



function PelicanBonusMapBigLevel:completed()
    self:runCsbAction("idle2")
end


return PelicanBonusMapBigLevel