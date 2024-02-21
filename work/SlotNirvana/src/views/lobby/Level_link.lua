-- Level_Link
--link卡 abtest

local Level_Link = class("Level_Link", util_require("base.BaseView"))

function Level_Link:initUI(csbName)
    self:createCsbNode(csbName)

    self.m_sp_ace = self:findChild("sp_ace")
    self:runCsbAction("idle", true)
end

return Level_Link
