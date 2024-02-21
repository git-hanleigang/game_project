---
--xcyy
--2018年5月23日
--FairyDragonJackpotCoinsTips.lua

local FairyDragonJackpotCoinsTips = class("FairyDragonJackpotCoinsTips",util_require("base.BaseView"))


function FairyDragonJackpotCoinsTips:initUI()

    self:createCsbNode("FairyDragon_Jackpot_wanfa_dikuang.csb")
end


function FairyDragonJackpotCoinsTips:onEnter()
 

end

function FairyDragonJackpotCoinsTips:setTipsCoins(curCoins)
    local node=self:findChild("BitmapFontLabel_1")
    node:setString(util_formatCoins(curCoins,4))
end

function FairyDragonJackpotCoinsTips:onExit()
 
end



return FairyDragonJackpotCoinsTips