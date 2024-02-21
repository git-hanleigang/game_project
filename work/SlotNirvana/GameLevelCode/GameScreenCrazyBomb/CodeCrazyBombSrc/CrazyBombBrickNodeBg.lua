---
--xhkj
--2018年6月11日
--CrazyBombBrickNodeBg.lua

local CrazyBombBrickNodeBg = class("CrazyBombBrickNodeBg", util_require("base.BaseView"))

function CrazyBombBrickNodeBg:initUI(name)

    local resourceFilename = "CrazyBomb_BrokenWall.csb"
    self:createCsbNode(resourceFilename)

end

function CrazyBombBrickNodeBg:changeImage(data )
    local nodeInfo = data
    local bgImage = self:findChild("wall1")
    local name = nodeInfo.shape
    local path = "Common/"..name.."b.png"

    -- if not cc.FileUtils:getInstance():isFileExist(path) then
    --     path = "Other/1x1b.png"
    -- end

    util_changeTexture(bgImage,path)

    -- local bgX  = self:findChild("wall1"):getContentSize().width
    -- local bgY  = self:findChild("wall1"):getContentSize().height
    -- self:setScaleX(data.width / self:findChild("wall1"):getContentSize().width)
    -- self:setScaleY(data.height / self:findChild("wall1"):getContentSize().height)
end

function CrazyBombBrickNodeBg:onEnter()
   
end


function CrazyBombBrickNodeBg:onExit()
    
end


return CrazyBombBrickNodeBg