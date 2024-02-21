--[[
    膨胀宣传 集卡
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MonsterAlbumData = class("MonsterAlbumData", BaseActivityData)

function MonsterAlbumData:ctor()
    MonsterAlbumData.super.ctor(self)
    self.p_open = true
end

return MonsterAlbumData