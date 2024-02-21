local CloverHatBonusMapBigLevel = class("CloverHatBonusMapBigLevel", util_require("base.BaseView"))

local maxImgNum_3Reel = 15
local maxImgNum_4Reel = 20
CloverHatBonusMapBigLevel.m_maxImgNum = 20

-- 构造函数
local DESCRIBE_LAYER_WIDTH = 212
function CloverHatBonusMapBigLevel:initUI(data)
    local resourceFilename = "CloverHat_Map_baozang2"

    if data.info.mapRows == "maprow3" then
        resourceFilename = "CloverHat_Map_baozang2.csb"
        self.m_maxImgNum = maxImgNum_3Reel

    elseif data.info.mapRows == "maprow4" then
        resourceFilename = "CloverHat_Map_baozang2_0.csb"
        self.m_maxImgNum = maxImgNum_4Reel
    end

    self:createCsbNode(resourceFilename)

    self:initLockWild( data.info.fixPos )

    self:idle()
    
end

function CloverHatBonusMapBigLevel:initLockWild( fixPos )
    
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

function CloverHatBonusMapBigLevel:idle()
    self:runCsbAction("idle", true)
end

function CloverHatBonusMapBigLevel:click(func)

    self:runCsbAction("actionframe", false, function()
        if func ~= nil then

            func()

        end
    end)
end



function CloverHatBonusMapBigLevel:completed()
    self:runCsbAction("idle2")
end

function CloverHatBonusMapBigLevel:onEnter()

end

function CloverHatBonusMapBigLevel:onExit()

end

return CloverHatBonusMapBigLevel