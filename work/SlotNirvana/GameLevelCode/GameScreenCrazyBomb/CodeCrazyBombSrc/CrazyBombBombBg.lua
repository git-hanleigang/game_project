---
--xhkj
--2018年6月11日
--CrazyBombBombBg.lua

local CrazyBombBombBg = class("CrazyBombBombBg", util_require("base.BaseView"))

function CrazyBombBombBg:initUI(name)

    local resourceFilename = "CrazyBomb_Wall.csb"
    self:createCsbNode(resourceFilename)

end

function CrazyBombBombBg:changeImage(data )
    local nodeInfo = data
    local bgImage = self:findChild("wall2")
    local name = nodeInfo.shape
    local path = "Common/"..name.."a.png"

    -- if not cc.FileUtils:getInstance():isFileExist(path) then
    --     path = "Other/1x1a.png"
    -- end

    util_changeTexture(bgImage,path)

    -- local bgX  = self:findChild("wall1"):getContentSize().width
    -- local bgY  = self:findChild("wall1"):getContentSize().height
    -- self:setScaleX(data.width / self:findChild("wall1"):getContentSize().width)
    -- self:setScaleY(data.height / self:findChild("wall1"):getContentSize().height)
end

function CrazyBombBombBg:onEnter()
   
end


function CrazyBombBombBg:onExit()
    
end


return CrazyBombBombBg