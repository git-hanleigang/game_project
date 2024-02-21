
local ColorfulCircusSignView = class("ColorfulCircusSignView",util_require("Levels.BaseLevelDialog"))

local PRIZE_TYPE = {
    TIMES = 1,
    MULTI = 2,
}

function ColorfulCircusSignView:initUI(_pickMain, _type, _param, isHaveLight)
    self.m_pickMain = _pickMain
    self.m_type = _type
    self.m_param = _param
    self:createCsbNode("ColorfulCircus_pick_jieguo.csb")

    self:findChild("Node_cheng"):setVisible(false)
    self:findChild("Node_jiashu"):setVisible(false)
    if self.m_type == PRIZE_TYPE.MULTI then
        self:findChild("Node_cheng"):setVisible(true)
        if self.m_param then
            self:findChild("m_lb_num_1"):setString("x" .. self.m_param)
            self:updateLabelSize({label=self:findChild("m_lb_num_1"),sx=0.95,sy=0.95},177)
        end
    elseif self.m_type == PRIZE_TYPE.TIMES then
        self:findChild("Node_jiashu"):setVisible(true)

        if self.m_param then
            self:findChild("m_lb_num_2"):setString("+" .. self.m_param)
            self:updateLabelSize({label=self:findChild("m_lb_num_2"),sx=1,sy=1},115)
        end
    end

    self.m_isHaveLight = isHaveLight
    -- if self.m_isHaveLight then
    --     self.m_lightBg = util_createAnimation("ColorfulCircus_shuzhi_beiguang.csb")
    --     self:findChild("shuzhi_beiguang"):addChild(self.m_lightBg)
    --     self.m_lightBg:runCsbAction("idle", true)

    --     -- self.m_lightBg:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
    --     -- self.m_lightBg:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
    --     self.m_lightBg:findChild("Particle_1"):resetSystem()
    -- end
    -- util_setCascadeOpacityEnabledRescursion(self:findChild("shuzhi_beiguang"), true)
end

function ColorfulCircusSignView:playFly()
    if self.m_isHaveLight then
        self:runCsbAction("fly2", false)
    else
        self:runCsbAction("fly", false)
    end
    
end

function ColorfulCircusSignView:onEnter()
    ColorfulCircusSignView.super.onEnter(self)
end

function ColorfulCircusSignView:onExit()
    ColorfulCircusSignView.super.onExit(self)
end


return ColorfulCircusSignView