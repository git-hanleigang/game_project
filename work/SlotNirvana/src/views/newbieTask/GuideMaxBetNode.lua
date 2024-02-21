--maxbet特效
local GuideMaxBetNode = class("GuideMaxBetNode", util_require("base.BaseView"))
function GuideMaxBetNode:initUI()
    self:createCsbNode("GuideNewUser/NewUserMaxBet.csb")
    self:runCsbAction("actionframe",true)
end
return GuideMaxBetNode