--引导箭头
local GuideArrowNode = class("GuideArrowNode", util_require("base.BaseView"))
function GuideArrowNode:initUI()
    self:createCsbNode("GuideNewUser/NewUserArrowNode.csb")
    
end
--横竖俩方向
function GuideArrowNode:showIdle(type)
    if type == 1 then
        self:runCsbAction("idleframe",true)
    elseif type == 2 then
        self:runCsbAction("idleframe2",true)
    elseif type == 3 then
        self:runCsbAction("idleframe3",true)
    end
end

return GuideArrowNode