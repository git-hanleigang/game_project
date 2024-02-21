
local KittysCatchFishTankView = class("KittysCatchFishTankView",util_require("Levels.BaseLevelDialog"))

function KittysCatchFishTankView:initUI()

    self:createCsbNode("KittysCatch_yugang.csb")

    -- self:runCsbAction("start", false)

    self.m_spine = util_spineCreate("Socre_KittysCatch_Feature", true, true)
    self.m_spine:setPosition(cc.p(0, 0))
    self.m_csbOwner["Node_yugang"]:addChild(self.m_spine, 10)
    util_spinePlay(self.m_spine, "idleframe", true)

    self.m_spineFish = util_spineCreate("Socre_KittysCatch_Feature", true, true)
    self.m_spineFish:setPosition(cc.p(0, 0))
    self.m_csbOwner["yugang2"]:addChild(self.m_spineFish, 20)
    self.m_spineFish:setVisible(false)

    self.m_yugang2 = util_createAnimation("KittysCatch_yugang2.csb")
    self.m_csbOwner["yugang2"]:addChild(self.m_yugang2)

    self.m_yugang3 = util_createAnimation("KittysCatch_yugang3.csb")
    util_setCascadeOpacityEnabledRescursion(self.m_yugang3, true)
    self.m_csbOwner["Node_yugang3"]:addChild(self.m_yugang3)
    self.m_yugang3:setVisible(false)
    
    self.m_bigNumEffect1 = self.m_csbOwner["KittysCatch_yugangglow_1"]
    self.m_bigNumEffect1:setVisible(false)
    self.m_bigNumEffect2 = self.m_csbOwner["Particle_1"]
    self.m_bigNumEffect2:setVisible(false)

    self.m_isMultiBigNum = false
end

function KittysCatchFishTankView:onEnter()
    KittysCatchFishTankView.super.onEnter(self)
end

function KittysCatchFishTankView:onExit()
    KittysCatchFishTankView.super.onExit(self)
end

function KittysCatchFishTankView:initMachine(_machine, _index)
    self.m_machine = _machine
    self.m_index = _index
end

function KittysCatchFishTankView:updateSize()
    local label1=self.m_csbOwner["m_lb_coins"]
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,86)
end

function KittysCatchFishTankView:setString(str)
    local label1=self.m_csbOwner["m_lb_coins"]
    label1:setString(str)
    self:updateSize()
end

function KittysCatchFishTankView:fishJump(_row, _func, _func2)
    --缸
    util_spinePlay(self.m_spine, "actionframe_feature", false)
    local spineEndCallFunc = function()
        local spineEnd3 = function()
            util_spinePlay(self.m_spine, "idleframe", true)
        end
        util_spinePlay(self.m_spine, "actionframe_feature3", false)
        util_spineEndCallFunc(self.m_spine, "actionframe_feature3", spineEnd3)
        if _func2 then
            _func2()
        end
    end
    util_spineEndCallFunc(self.m_spine, "actionframe_feature", spineEndCallFunc)

    --鱼
    local anim = "actionframe_feature2_1"
    if _row == 1 then
        anim = "actionframe_feature2_4"
    elseif _row == 2 then
        anim = "actionframe_feature2_3"
    elseif _row == 3 then
        anim = "actionframe_feature2_2"
    elseif _row == 4 then
        anim = "actionframe_feature2_1"
    end
    self.m_spineFish:setVisible(true)
    util_spinePlay(self.m_spineFish, anim, false)
    local spineEndCallFunc = function()
        self.m_spineFish:setVisible(false)
        if _func then
            _func()
        end
    end
    util_spineEndCallFunc(self.m_spineFish, anim, spineEndCallFunc)
end

-- function KittysCatchFishTankView:playNumUp(_numStart, _numEnd)
--     self.m_yugang3:setVisible(true)
--     util_nodeFadeIn(self.m_yugang3, 0, 255, 255)
--     self.m_yugang3:runCsbAction("idle2", true)

--     self:runCsbAction("up", false, function()
--     end)
--     performWithDelay(self, function()
--         self:jumpNums(_numStart, _numEnd)

--         -- local node=self:findChild("m_lb_coins")
--         -- node:setString(util_formatCoins(_numEnd, 3))
--         -- self:updateLabelSize({label = node, sx = 1, sy = 1}, 86)
--     end, 10/60)
-- end

-- function KittysCatchFishTankView:jumpNums(numStart, numEnd)

--     local node=self:findChild("m_lb_coins")
--     node:setString(numStart)
--     local addValue = numEnd - numStart
--     util_jumpNum(node,numStart,numEnd,addValue,1/2,{3}, nil, nil,function(  )
--         self.m_isJumpOver = true
--         -- if self.m_soundId then
--         --     gLobalSoundManager:stopAudio(self.m_soundId)
--         --     self.m_soundId = nil
--         -- end
--         -- gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JPCoinsJump_Over.mp3")
--     end,function()
--         self:updateLabelSize({label = node, sx = 1, sy = 1}, 86)
--     end)
-- end

function KittysCatchFishTankView:playFishTankAnim(_anim, _loop, _func)
    local loop = not not _loop
    util_spinePlay(self.m_spine, _anim, loop)
    local spineEndCallFunc = function()
        if _func then
            _func()
        end
    end
    if not loop then
        util_spineEndCallFunc(self.m_spine, _anim, spineEndCallFunc)
    end
    
end

function KittysCatchFishTankView:resetUpEffect()
    util_nodeFadeIn(self.m_yugang3, 0.2, 255, 0, nil, function()
        self.m_yugang3:setVisible(false)
        util_nodeFadeIn(self.m_yugang3, 0, 255, 255)
    end)
end

function KittysCatchFishTankView:setUpEffect()
    self.m_yugang3:setVisible(true)
    util_nodeFadeIn(self.m_yugang3, 0.2, 0, 255)
    self.m_yugang3:runCsbAction("idle2", true)
end

-- function KittysCatchFishTankView:setSkin(_isMulti)
--     if _isMulti then
--         self.m_spine:setSkin("highlight")
--     else
--         self.m_spine:setSkin("normal")
--     end
-- end

function KittysCatchFishTankView:showBigNumEffect(_isShow)
    local isShow = not not _isShow
    self.m_bigNumEffect1:setVisible(isShow)
    self.m_bigNumEffect2:setVisible(isShow)

    self.m_isMultiBigNum = isShow

    self.m_yugang3:findChild("KittysCatch_zhujiemian_shuzi_di_3"):setVisible(isShow)
    self.m_yugang3:findChild("KittysCatch_zhujiemian_shuzi_di_2_11_0"):setVisible(not isShow)

    self:findChild("KittysCatch_zhujiemian_shuzi_di_3"):setVisible(isShow)
    self:findChild("KittysCatch_zhujiemian_shuzi_di_2_11"):setVisible(not isShow)
end

return KittysCatchFishTankView