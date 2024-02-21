---
--island
--2018年4月12日
--ChilliFiestaWildBar.lua
local ChilliFiestaWildBar = class("ChilliFiestaWildBar", util_require("base.BaseView"))
function ChilliFiestaWildBar:initUI(data)

    local resourceFilename = "Socre_ChilliFiesta_Wild_Bar.csb"
    self:createCsbNode(resourceFilename)
    -- self.m_Particle_1 = self:findChild("Particle_1")
    -- self.m_Particle_1:setVisible(false)
    self:findChild("lbs_num"):setString("")
    self:runCsbAction("idleframe",true)
end
function ChilliFiestaWildBar:updateView(num,callback)
    if num == 0 then
        self:findChild("lbs_num"):setString("")
        if callback then
            callback()
        end
    else
        gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_wildFire.mp3")
        self:runCsbAction("shouji",false,function()
            self:runCsbAction("idleframe",true)
            if callback then
                callback()
            end
        end)
        self:findChild("lbs_num"):setString("X"..num)
    end

end

function ChilliFiestaWildBar:showView()
    self:setVisible(true)
end

function ChilliFiestaWildBar:hideView()
    self:setVisible(false)
end

function ChilliFiestaWildBar:onEnter()
end

function ChilliFiestaWildBar:onExit()

end
return ChilliFiestaWildBar
