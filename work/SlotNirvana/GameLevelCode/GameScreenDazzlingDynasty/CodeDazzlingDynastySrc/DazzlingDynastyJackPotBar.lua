--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:JohnnyFred
    time:2019-07-30 10:00:10
]]
local DazzlingDynastyJackPotBar = class("DazzlingDynastyJackPotBar",util_require("base.BaseView"))

function DazzlingDynastyJackPotBar:initUI()
    self:createCsbNode("DazzlingDynasty_Jackpot.csb")
    self:runCsbAction("idle",true)
    self.m_lbTopUIMap = 
    {
        self:findChild("m_lb_grand"),
        self:findChild("m_lb_major"),
        self:findChild("m_lb_minor"),
        self:findChild("m_lb_mini")
    }
end

function DazzlingDynastyJackPotBar:initMachine(machine)
    self.m_machine = machine
end

function DazzlingDynastyJackPotBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

--[[function DazzlingDynastyJackPotBar:updateJackpotInfo()
    local m_machine = self.m_machine
    if m_machine ~= nil then
        local data=self.m_csbOwner
        self:changeNode(self:findChild("m_lb_grand"),1,true)
        self:changeNode(self:findChild("m_lb_major"),2,true)
        self:changeNode(self:findChild("m_lb_minor"),3)
        self:changeNode(self:findChild("m_lb_mini"),4)
        self:updateSize()
    end
end]]

function DazzlingDynastyJackPotBar:updateSize()
    local m_lbTopUIMap = self.m_lbTopUIMap
    local info1 = {label = m_lbTopUIMap[1],sx = 1,sy = 1}
    local info2 = {label = m_lbTopUIMap[2],sx = 1,sy = 1}
    local info3 = {label = m_lbTopUIMap[3],sx = 0.72,sy = 0.72}
    local info4 = {label = m_lbTopUIMap[4],sx = 0.72,sy = 0.72}
    self:updateLabelSize(info1,270)
    self:updateLabelSize(info2,270)
    self:updateLabelSize(info3,270)
    self:updateLabelSize(info4,270)
end

function DazzlingDynastyJackPotBar:updateJackpotInfo()
    local m_lbTopUIMap = self.m_lbTopUIMap
    local m_machine = self.m_machine
    for i = 1,4 do
        local coin = m_machine:BaseMania_updateJackpotScore(i)
        m_lbTopUIMap[i]:setString(util_formatCoins(coin,20))
    end
    self:updateSize()
end
return DazzlingDynastyJackPotBar