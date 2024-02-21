---
--xcyy
--2018年5月23日
--BunnyBountyReelNode.lua

local BunnyBountyReelNode = class("BunnyBountyReelNode",util_require("Levels.BaseReel.BaseReelNode"))

function BunnyBountyReelNode:onEnter()
    BunnyBountyReelNode.super.onEnter(self)
end

function BunnyBountyReelNode:onExit( )
    
    BunnyBountyReelNode.super.onExit(self)
end

return BunnyBountyReelNode