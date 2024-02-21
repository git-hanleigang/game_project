local AliceRubyBonusMapPanda = class("AliceRubyBonusMapPanda", util_require("base.BaseView"))
-- 构造函数
function AliceRubyBonusMapPanda:initUI(data)
    local resourceFilename = "AliceRuby_Map_zhizhen.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idle", true)
end

function AliceRubyBonusMapPanda:onEnter()

end

function AliceRubyBonusMapPanda:onExit()

end


return AliceRubyBonusMapPanda