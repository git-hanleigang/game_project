--气泡
local GuidePopNode = class("GuidePopNode", util_require("base.BaseView"))
function GuidePopNode:initUI()
    self:createCsbNode("GuideNewUser/NewUserPopNode.csb")
end

function GuidePopNode:showIdle(type)
    local Sprite_1 = self:findChild("Sprite_1")
    local Sprite_2 = self:findChild("Sprite_2")
    if Sprite_1 then
        Sprite_1:setVisible(false)
    end
    if Sprite_2 then
        Sprite_2:setVisible(false)
    end
    if type == 1 then
        Sprite_1:setVisible(true)
    elseif type == 2 then
        Sprite_2:setVisible(true)
    end
end
return GuidePopNode