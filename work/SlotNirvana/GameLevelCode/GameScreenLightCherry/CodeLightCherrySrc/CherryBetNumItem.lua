---
--xcyy
--2018年5月30日
--CherryBetNumItem.lua

local CherryBetNumItem = class("CherryBetNumItem",util_require("base.baseView"))
function CherryBetNumItem:initUI(data)
    -- TODO 输入自己初始化逻辑
    self:createCsbNode("LightCherry/Socre_Special_Rase.csb")
end
function CherryBetNumItem:setNum(num)
    self.m_csbOwner["m_lb_num"]:setString(num.."")
end
return CherryBetNumItem