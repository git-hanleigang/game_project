--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-06-29 17:21:54
]]
local MagicGameGuaranteeMgr = class("MagicGameGuaranteeMgr", BaseActivityControl)

function MagicGameGuaranteeMgr:ctor()
    MagicGameGuaranteeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.MagicGameGuarantee)
end

return MagicGameGuaranteeMgr
