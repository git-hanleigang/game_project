--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-13 17:26:27
]]


---
--island
--2018年4月12日
--ChilliFiestaFreeSpinBar.lua
local ChilliFiestaFreeSpinBar = class("ChilliFiestaFreeSpinBar", util_require("base.BaseView"))
function ChilliFiestaFreeSpinBar:initUI(data)

    local resourceFilename = "ChilliFiesta_FreeSpin_bar.csb"
    self:createCsbNode(resourceFilename)
    self.m_Particle_1 = self:findChild("Particle_1")
    self.m_Particle_1:setVisible(false)

    -- self:runCsbAction("start",false,function()
    --     self:runCsbAction("idle",true)
    -- end)
end
function ChilliFiestaFreeSpinBar:updateView(curNum,sumNum)
    -- self:playCollect()
    local showNum = sumNum - curNum
    self:findChild("lbs_curNum"):setString(showNum)
    self:findChild("lbs_sumNum"):setString(sumNum)
end



function ChilliFiestaFreeSpinBar:playCollect()
    self:runCsbAction("shouji")
    self.m_Particle_1:setVisible(true)
    self.m_Particle_1:resetSystem()
end


function ChilliFiestaFreeSpinBar:onEnter()
end

function ChilliFiestaFreeSpinBar:onExit()

end



return ChilliFiestaFreeSpinBar
