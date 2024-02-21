--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-12 21:00:59
]]
local DazzlingDynastyChangeEffect = class("DazzlingDynastyChangeEffect", util_require("base.BaseView"))

function DazzlingDynastyChangeEffect:initUI()
    self:createCsbNode("DazzlingDynasty_guochang.csb")
end

function DazzlingDynastyChangeEffect:setExtraInfo(machine)
    self.m_machine = machine
end

function DazzlingDynastyChangeEffect:play(midCallBack,endCallBack)
    self:runCsbAction("actionframe",false,
    function()
        if endCallBack ~= nil then
            endCallBack()
        end
        self:removeFromParent()
    end,20)
    if midCallBack ~= nil then
        performWithDelay(self,midCallBack,20 / 20)
    end
end

function DazzlingDynastyChangeEffect:onExit()
    self.m_machine.changeEffect = nil
end

return DazzlingDynastyChangeEffect