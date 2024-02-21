---
--xcyy
--2018年5月23日
--AfricaRiseBonusWinFrame.lua

local AfricaRiseBonusWinFrame = class("AfricaRiseBonusWinFrame", util_require("base.BaseView"))

function AfricaRiseBonusWinFrame:initUI(_type)
    local strName 
    if _type == 1 then
        strName = "AfricaRise_ji_kuang_zj.csb"
    elseif _type == 2 then
        strName = "AfricaRise_ji_kuang_zj2.csb"
    elseif _type == 3 then
        strName = "AfricaRise_ji_kuang_zj3.csb"
    end
    self:createCsbNode(strName)
end

function AfricaRiseBonusWinFrame:onEnter()
end

function AfricaRiseBonusWinFrame:onExit()
end

return AfricaRiseBonusWinFrame
