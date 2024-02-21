--
--大厅关卡节点
--
local GameBetGuang = class("GameBetGuang", util_require("base.BaseView"))

GameBetGuang.m_contentLen = nil
GameBetGuang.activityNodes = nil
function GameBetGuang:initUI()
    self:createCsbNode("Game/bet_guang.csb")
    self:runCsbAction("Defauilt_Timeline",false)
end

function GameBetGuang:runMaxBetAciton()
    self:runCsbAction("bet_guang",false)
end 

return GameBetGuang
