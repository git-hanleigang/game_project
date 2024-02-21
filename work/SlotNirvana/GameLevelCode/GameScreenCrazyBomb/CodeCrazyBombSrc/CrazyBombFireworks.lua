---
--island
--2018年6月5日
--CrazyBombFireworks.lua
local CrazyBombFireworks = class("CrazyBombFireworks", util_require("base.BaseView"))

function CrazyBombFireworks:initUI(data)

    local resourceFilename="CrazyBomb/GameScreenCrazyBombLihua.csb"
    self:createCsbNode(resourceFilename)
    
    self:ignoreAnchorPointForPosition(false)
    self:setAnchorPoint(0.5,0.5)
end


function CrazyBombFireworks:onEnter()
    
end


--
function CrazyBombFireworks:showFireEffect()
    self:runCsbAction("idleframe")
end


function CrazyBombFireworks:onExit()

end

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return CrazyBombFireworks