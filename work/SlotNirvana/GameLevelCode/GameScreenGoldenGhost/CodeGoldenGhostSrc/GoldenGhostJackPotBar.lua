--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:JohnnyFred
    time:2019-07-30 10:00:10
]]
local GoldenGhostJackPotBar = class("GoldenGhostJackPotBar",util_require("base.BaseView"))

function GoldenGhostJackPotBar:initInfo( )
    self.m_lbTopUIMap = {self:findChild("m_lb_grand"),self:findChild("m_lb_major"),self:findChild("m_lb_minor"),self:findChild("m_lb_mini")}
end

function GoldenGhostJackPotBar:initUI()
    self:createCsbNode("GoldenGhost_Jackpot.csb")
    self:runCsbAction("idle",true)
    self:initInfo( )
end

function GoldenGhostJackPotBar:initMachine(machine)
    self.m_machine = machine
end

function GoldenGhostJackPotBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function GoldenGhostJackPotBar:updateSize()
    local m_lbTopUIMap = self.m_lbTopUIMap
    local info1 = {label = m_lbTopUIMap[1],sx = 1,sy = 1}
    local info2 = {label = m_lbTopUIMap[2],sx = 1,sy = 1}
    local info3 = {label = m_lbTopUIMap[3],sx = 1,sy = 1}
    local info4 = {label = m_lbTopUIMap[4],sx = 1,sy = 1}
    self:updateLabelSize(info1,270)
    self:updateLabelSize(info2,270)
    self:updateLabelSize(info3,270)
    self:updateLabelSize(info4,270)
end

function GoldenGhostJackPotBar:updateJackpotInfo()
    local m_lbTopUIMap = self.m_lbTopUIMap
    local m_machine = self.m_machine
    for i = 1,4 do
        local coin = m_machine:BaseMania_updateJackpotScore(i)
        m_lbTopUIMap[i]:setString(util_formatCoins(coin,20))
    end
    self:updateSize()
end
return GoldenGhostJackPotBar