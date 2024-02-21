--[[--
    集卡小游戏
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local CardSpecialAlbumGame = class("CardSpecialAlbumGame", BaseActivityData)
function CardSpecialAlbumGame:ctor()
    CardSpecialAlbumGame.super.ctor(self)
    self.p_open = true
end
return CardSpecialAlbumGame
