--[[--
    金币 火
]]
local LSGameCoin = util_require("views.LuckyStamp.MiniGame.mainUI.LSGameCoin")
local LSGameCoinFire = class("LSGameCoinFire", LSGameCoin)

function LSGameCoinFire:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_coin_fire.csb"
end

function LSGameCoinFire:initCsbNodes()
    self.m_lbCoin = self:findChild("lb_num1")
end

return LSGameCoinFire
