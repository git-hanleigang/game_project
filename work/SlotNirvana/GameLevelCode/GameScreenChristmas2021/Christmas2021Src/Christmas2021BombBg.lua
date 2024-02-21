---
--xhkj
--2018年6月11日
--Christmas2021BombBg.lua

local Christmas2021BombBg = class("Christmas2021BombBg", util_require("base.BaseView"))

function Christmas2021BombBg:initUI(name)

    local resourceFilename = "Christmas2021_Wall.csb"
    self:createCsbNode(resourceFilename)

end

function Christmas2021BombBg:changeImage(data )
    local nodeInfo = data
    local bgImage = self:findChild("wall2")
    local name = nodeInfo.shape
    local path = "Common/kuang"..name..".png"

    util_changeTexture(bgImage,path)

end

function Christmas2021BombBg:onEnter()
   
end


function Christmas2021BombBg:onExit()
    
end


return Christmas2021BombBg