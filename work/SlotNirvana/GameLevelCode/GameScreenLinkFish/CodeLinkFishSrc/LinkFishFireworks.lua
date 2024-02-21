---
--island
--2018年6月5日
--LinkFishFireworks.lua
local LinkFishFireworks = class("LinkFishFireworks", util_require("base.BaseView"))

function LinkFishFireworks:initUI(data)

    local resourceFilename="LinkFish/GameScreenLinkFishLihua.csb"
    self:createCsbNode(resourceFilename)
    
    self:ignoreAnchorPointForPosition(false)
    self:setAnchorPoint(0.5,0.5)
end


function LinkFishFireworks:onEnter()
    
end


--
function LinkFishFireworks:showFireEffect()
    self:runCsbAction("idleframe")
end


function LinkFishFireworks:onExit()

end

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return LinkFishFireworks