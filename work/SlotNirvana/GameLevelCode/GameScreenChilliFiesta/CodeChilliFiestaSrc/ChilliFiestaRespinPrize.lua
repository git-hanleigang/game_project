---
--island
--2018年4月12日
--ChilliFiestaRespinPrize.lua
local ChilliFiestaRespinPrize = class("ChilliFiestaRespinPrize", util_require("base.BaseView"))
function ChilliFiestaRespinPrize:initUI(data)

    local resourceFilename = "ChilliFiesta_Respin_Prize.csb"
    self:createCsbNode(resourceFilename)

    self.m_Particle_1 = self:findChild("Particle_1")
    self.m_Particle_1:setVisible(false)
    -- self:runCsbAction("start",false,function()
    --     self:runCsbAction("idle",true)
    -- end)
end
function ChilliFiestaRespinPrize:updateView(curNum)

    if tonumber(curNum) > 0 then
        self:playCollect()
    end
    self:findChild("lbs_curNum"):setString(util_formatCoins(curNum, 20))
end

function ChilliFiestaRespinPrize:playCollect()
    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_bonusCollectBuling.mp3")

    self.m_Particle_1:setVisible(true)
    self.m_Particle_1:resetSystem()
end

function ChilliFiestaRespinPrize:changeTitle(type)
    if type == 0 then
        self:findChild("prizeTitle1"):setVisible(true)
        self:findChild("prizeTitle2"):setVisible(false)
    else
        self:findChild("prizeTitle1"):setVisible(false)
        self:findChild("prizeTitle2"):setVisible(true)
    end

end

function ChilliFiestaRespinPrize:hideView()
    self:setVisible(false)
end

function ChilliFiestaRespinPrize:onEnter()
end

function ChilliFiestaRespinPrize:onExit()

end



return ChilliFiestaRespinPrize
