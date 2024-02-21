---
--xcyy
--2018年5月19日
--ReSpinBar.lua
local ReSpinBar = class("ReSpinBar",util_require("base.BaseView"))

function ReSpinBar:initUI(data)
    local resourceFilename="Socre_Pharaoh_Middiebar.csb"
    self:createCsbNode(resourceFilename)
    -- TODO 输入自己初始化逻辑
end

function ReSpinBar:toAction(name)
    self:runCsbAction(name)
end

function ReSpinBar:updateLeftCount(num)
    if num then
        self.m_csbOwner["m_lb_num"]:setString(num.."")
    end
end

function ReSpinBar:updateWinCount(num)
    if num then
        self.m_csbOwner["m_lb_coins"]:setString(num)
    end
end

return ReSpinBar