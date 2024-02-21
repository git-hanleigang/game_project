--[[--
    集卡小游戏
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local CardSpecialAlbum = class("CardSpecialAlbum", BaseActivityData)
function CardSpecialAlbum:ctor()
    CardSpecialAlbum.super.ctor(self)
    self.p_open = true
end
return CardSpecialAlbum
