---
--xcyy
--2018年5月23日
--ColorfulCircusYuGaoView.lua

local ColorfulCircusYuGaoView = class("ColorfulCircusYuGaoView",util_require("Levels.BaseLevelDialog"))


function ColorfulCircusYuGaoView:initUI()

    self:createCsbNode("ColorfulCircus_yugao.csb")

    self.ball = util_spineCreate("ColorfulCircus_yugao",true,true)
    self:findChild("qiqiu"):addChild(self.ball)
    self.ball:setVisible(false)

    self:findChild("Particle_1"):stopSystem()
    self:findChild("Particle_1_0"):stopSystem()
    self:findChild("Particle_3"):stopSystem()
    self:findChild("Particle_3_0"):stopSystem()
    
end

function ColorfulCircusYuGaoView:onEnter()

    ColorfulCircusYuGaoView.super.onEnter(self)

end

function ColorfulCircusYuGaoView:onExit()
    ColorfulCircusYuGaoView.super.onExit(self)
end

function ColorfulCircusYuGaoView:showYuGao(type)
    local timeEnd = 130/60
    if type == 1 then
        self:runCsbAction("actionframe_yugao")
    elseif type == 2 then
        self:runCsbAction("actionframe_rq1")
        timeEnd = (200-10) / 60
    elseif type == 3 then
        self:runCsbAction("actionframe_rq2")
        timeEnd = (110-10) / 60
    end
    

    if type == 1 then
        self.ball:setVisible(true)
        util_spinePlay(self.ball,"actionframe_yugao",false)
    end
    

    performWithDelay(self, function (  )
        self:findChild("Particle_1"):resetSystem()
        self:findChild("Particle_1_0"):resetSystem()
        self:findChild("Particle_3"):resetSystem()
        self:findChild("Particle_3_0"):resetSystem()
    end, 10/60)
    performWithDelay(self, function (  )
        self:findChild("Particle_1"):stopSystem()
        self:findChild("Particle_1_0"):stopSystem()
        self:findChild("Particle_3"):stopSystem()
        self:findChild("Particle_3_0"):stopSystem()
    end, timeEnd)
    -- node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
    -- node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
    -- node:findChild("Particle_1"):resetSystem()
    -- node:findChild("Particle_1"):stopSystem()
end


return ColorfulCircusYuGaoView