--
-- 大厅展示图
--
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelAlbumMoreAwardSaleHallNode = class("LevelAlbumMoreAwardSaleHallNode", LevelFeature)

function LevelAlbumMoreAwardSaleHallNode:createCsb()
    self:createCsbNode("Activity_AlbumMoreAward/Icons/AlbumMoreAwardSale_Hall.csb")

    self:initView()
end

function LevelAlbumMoreAwardSaleHallNode:initView()
    self:setButtonLabelContent("hallButton", "SEE IT")
end

function LevelAlbumMoreAwardSaleHallNode:clickFunc(_sender)
    G_GetMgr(ACTIVITY_REF.AlbumMoreAward):showSaleLayer()
end

return LevelAlbumMoreAwardSaleHallNode
