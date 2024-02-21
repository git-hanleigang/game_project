--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-06-11 11:17:49
]]
local ShopScratchTip = class("ShopScratchTip", util_require("base.BaseView"))

function ShopScratchTip:initUI(path)
    local name = "GameNode/ScratchCards.csb"
    if cc.FileUtils:getInstance():isFileExist(name) == true then
        self:createCsbNode(name)
        self:runCsbAction("animation0", true, nil, 60)
    end
end

return ShopScratchTip
