---
--island
--2018年6月5日
--GoldenPigFireworks.lua
local GoldenPigFireworks = class("GoldenPigFireworks", util_require("base.BaseView"))

function GoldenPigFireworks:initUI(data)

    local resourceFilename="GoldenPig/GameScreenGoldenPigLihua.csb"
    self:createCsbNode(resourceFilename)
    
    self:ignoreAnchorPointForPosition(false)
    self:setAnchorPoint(0.5,0.5)
end


function GoldenPigFireworks:onEnter()
    
end


--
function GoldenPigFireworks:showFireEffect()
    self:runCsbAction("idleframe")
end


function GoldenPigFireworks:onExit()

end

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return GoldenPigFireworks