local Level_Tag = class("Level_Tag", util_require("base.BaseView"))

function Level_Tag:initUI(csbName)
    self:createCsbNode(csbName)
end

function Level_Tag:playIdleAction(name)
    self:runCsbAction(name, true, nil, 60)
end

return Level_Tag