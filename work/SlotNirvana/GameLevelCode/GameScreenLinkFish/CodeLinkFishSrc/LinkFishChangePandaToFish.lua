---
--island
--2018年6月5日
--LinkFishChangePandaToFish.lua
local LinkFishChangePandaToFish = class("LinkFishChangePandaToFish", util_require("base.BaseView"))

function LinkFishChangePandaToFish:initUI(data)
    
    local resourceFilename="Socre_LinkFish_shuatu.csb"
    self:createCsbNode(resourceFilename)
    
end


function LinkFishChangePandaToFish:actionChange( isloop,func )
    self:runCsbAction("actionframe",isloop,func)
end

function LinkFishChangePandaToFish:onEnter()
    
end

function LinkFishChangePandaToFish:onExit()

end


return LinkFishChangePandaToFish