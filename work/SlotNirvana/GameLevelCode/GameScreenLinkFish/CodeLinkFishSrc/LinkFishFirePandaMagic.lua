---
--island
--2018年6月5日
--LinkFishFirePandaMagic.lua
local LinkFishFirePandaMagic = class("LinkFishFirePandaMagic", util_require("base.BaseView"))

function LinkFishFirePandaMagic:initUI(data)
    
    local resourceFilename="LinkFish/LinkFish_top_panda_HuXi.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("animation0", true)
end


function LinkFishFirePandaMagic:onEnter()
    
end

function LinkFishFirePandaMagic:onExit()

end


return LinkFishFirePandaMagic