
local ColorfulCircusDuckView = class("ColorfulCircusDuckView",util_require("Levels.BaseLevelDialog"))

local DUCK_STATUS ={
    NORMAL = 1,
    BEATTACK = 2,
}

local AIM_TIME = 24/60
function ColorfulCircusDuckView:initUI(_pickMain, _isToLeft)
    self.m_isToLeft = _isToLeft
    self.m_speed = 100
    self.m_status = DUCK_STATUS.NORMAL
    self.m_pickMain = _pickMain
    self:createCsbNode("ColorfulCircus_pick_yazi.csb")

    if _isToLeft then
        self:findChild("Node_zuo"):setScaleX(1)
    else
        self:findChild("Node_zuo"):setScaleX(-1)
    end


    -- self.m_damageEffect = util_createAnimation("ColorfulCircus_pick_yazizg.csb")
    -- self:findChild("zg"):addChild(self.m_damageEffect)
    -- self.m_damageEffect:setVisible(false)


    self:addClick(self:findChild("Panel_1"))

    self:runCsbAction("idle", true)
end

function ColorfulCircusDuckView:resetDuck(_x, _y, _isToLeft)
    self:setPositionY(_y)
    self:setPositionX(_x)
    self.m_isToLeft = _isToLeft

    if _isToLeft then
        self:findChild("Node_zuo"):setScaleX(1)
    else
        self:findChild("Node_zuo"):setScaleX(-1)
    end
    self:runCsbAction("idle", true)
    self.m_status = DUCK_STATUS.NORMAL
end

function ColorfulCircusDuckView:updateMove(dt)
    local posX = self:getPositionX()
    local moveDis = self.m_speed * dt
    if self.m_isToLeft then
        self:setPositionX(posX - moveDis)
    else
        self:setPositionX(posX + moveDis)
    end
end

function ColorfulCircusDuckView:getIsToLeft()
    return self.m_isToLeft
end

function ColorfulCircusDuckView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_1" then
        if self.m_pickMain.m_status == DUCK_STATUS.NORMAL and self.m_pickMain:checkDuckCanTouch(self) then
            if self.m_status == DUCK_STATUS.NORMAL then
                self.m_status = DUCK_STATUS.BEATTACK
                gLobalNoticManager:postNotification("COLORFULCIRCUS_DUCK_CLICK", self)
                self:addAim(function()
                    -- local worldPos = self:getParent():convertToWorldSpace(cc.p(self:getPositionX(), self:getPositionY()))
                    -- gLobalNoticManager:postNotification("COLORFULCIRCUS_DUCK_OVER", {cc.p(worldPos)})
                end)
            end
        end
        
    end
end

--瞄准
function ColorfulCircusDuckView:addAim(_func)
    local aimView = util_createAnimation("ColorfulCircus_pick_miaozhun.csb")
    self:findChild("Node_Aim"):addChild(aimView)
    aimView:runCsbAction("dianji", false)

    gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_duck_aim_shoot.mp3")

    performWithDelay(self, function()
        aimView:removeFromParent()
        if _func then
            _func()
        end
    end, AIM_TIME)
end

--受击
function ColorfulCircusDuckView:beDamage(_func)
    self:runCsbAction("actionframe2", false, function (  )
        if _func then
            _func()
        end
    end)
    -- self.m_damageEffect:setVisible(true)
    -- self.m_damageEffect:runCsbAction("actionframe2", false, function (  )
    --     self.m_damageEffect:setVisible(false)
    -- end)

end

function ColorfulCircusDuckView:onEnter()
    ColorfulCircusDuckView.super.onEnter(self)
end

function ColorfulCircusDuckView:onExit()
    ColorfulCircusDuckView.super.onExit(self)
end


return ColorfulCircusDuckView