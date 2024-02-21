--[[--
    FB加好友活动 数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local AlbumRaceNewChipsData = class("AlbumRaceNewChipsData", BaseActivityData)

function AlbumRaceNewChipsData:ctor()
    AlbumRaceNewChipsData.super.ctor(self)
    self.p_open = true
end

return AlbumRaceNewChipsData