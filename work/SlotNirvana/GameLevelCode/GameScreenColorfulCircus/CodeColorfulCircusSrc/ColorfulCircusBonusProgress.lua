local ColorfulCircusBonusProgress = class("ColorfulCircusBonusProgress", util_require("Levels.BaseLevelDialog"))
-- 构造函数
local PROGRESS_WIDTH = 611
-- local animBeginPosX = -320
-- local animEndPosX = 268
function ColorfulCircusBonusProgress:initUI(data, _nodeStar, _nodeBalloon, _nodeFAQ, _nodeTips)
    self.m_machine = data
    local resourceFilename = "ColorfulCircus_collect.csb"
    self:createCsbNode(resourceFilename)

    self.m_progress = self.m_csbOwner["loadingBar"]
    self.m_progress:setPositionX(0)

    --idle
    local collectEffect  = util_spineCreate("ColorfulCircus_collect",true,true)
    util_spinePlay(collectEffect,"idle",true)
    self:findChild("effect_head"):addChild(collectEffect, 1)
    collectEffect:setPositionX(-PROGRESS_WIDTH/2)

    --收集满
    self.m_effectCollectFull = util_createAnimation("ColorfulCircus_shoujitiao.csb")
    self:findChild("shoujitiao"):addChild(self.m_effectCollectFull)
    self.m_effectCollectFull:setVisible(false)

    --星
    self.m_effectStar = util_createAnimation("ColorfulCircus_collect_xing.csb")
    _nodeStar:addChild(self.m_effectStar)
    self.m_effectStar:setVisible(false) --< deprecated

    --气球
    self.m_effectBalloon = util_createAnimation("ColorfulCircus_collect_qiqiu.csb")
    _nodeBalloon:addChild(self.m_effectBalloon)

    --FAQ
    self.m_effectFAQ = util_createAnimation("ColorfulCircus_collect_i.csb")
    _nodeFAQ:addChild(self.m_effectFAQ)
    self:addClick(self.m_effectFAQ:findChild("Button_1_0"))

    self.m_FAQ = util_createView("CodeColorfulCircusSrc.ColorfulCircusTipsCommonView",self)
    _nodeTips:addChild(self.m_FAQ)
    --进度头特效
    self.m_effectHead1 = util_createAnimation("ColorfulCircus_collect_zhang_g.csb")
    self:findChild("effect_head"):addChild(self.m_effectHead1, 5)
    self.m_effectHead1:setVisible(false)
    -- self.m_effectHead2 = util_createAnimation("ColorfulCircus_collect_zhang_lizi.csb")
    -- self:findChild("effect_head"):addChild(self.m_effectHead2, 10)
    -- self.m_effectHead2:findChild("Particle_1"):stopSystem()

    -- util_spineEndCallFunc(self.m_spineTanban,"start",function(  )
    --     util_spinePlay(self.m_spineTanban,"idle",true)
    -- end)
    -- self:addClick(self.m_csbOwner["touchBtn"])
    -- self:addClick(self.m_csbOwner["Button_1"])
    
    -- self:runCsbAction("idle",true)

    -- self.m_anim = cc.Node:create()
    -- self:findChild("Node_jindu"):addChild(self.m_anim)
    -- self.m_anim:setPositionX(animBeginPosX)

    self:addClick(self:findChild("Panel_Click_Progress"))
    self:addClick(self.m_effectBalloon:findChild("Panel_Click"))

    self.changeAction = true


    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)
end

function ColorfulCircusBonusProgress:onEnter()
    ColorfulCircusBonusProgress.super.onEnter(self)
end

function ColorfulCircusBonusProgress:onExit()
    ColorfulCircusBonusProgress.super.onExit(self)
end

function ColorfulCircusBonusProgress:lock(betLevel,_isinit)
    self.m_iBetLevel = betLevel
    self:stopAllActions()
    if _isinit then
        self:idle()
    else
        self:runCsbAction("actionframe2",false,function (  )
            self:idle()
        end)
    end
    

    self:findChild("Node_lock"):setVisible(true)
    -- self.m_effectStar:setVisible(false)

    self.m_effectCollectFull:setVisible(false)
end

function ColorfulCircusBonusProgress:unlock(betLevel,_isinit)
    self.m_iBetLevel = betLevel
    self:stopAllActions()
    -- self:findChild("Particle_5"):resetSystem()
    -- self:findChild("Particle_6"):resetSystem()
    -- self:runCsbAction("", false, function()
        -- self:findChild("Particle_5"):stopSystem()
        -- self:findChild("Particle_6"):stopSystem()
        -- self:idle()

    -- end)

    -- self:findChild("Node_lock"):setVisible(false)
    -- self.m_effectStar:setVisible(true)

    if _isinit then
        self:idle()
        self:findChild("Node_lock"):setVisible(false)
    else
        gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_progressUnlock.mp3")

        self.m_effectCollectFull:setVisible(true)
        self.m_effectCollectFull:runCsbAction("animation0",false,function (  )
            
        end)
        performWithDelay(self, function()
            self.m_effectCollectFull:setVisible(false)
        end, 75/60)

        performWithDelay(self, function()
            self:idle()
            self:findChild("Node_lock"):setVisible(false)
        end, 30/60)
    end

end

function ColorfulCircusBonusProgress:idle()
    if self.m_iBetLevel == nil or self.m_iBetLevel == 0 then
        self:runCsbAction("idle2",true)
    else
        self:runCsbAction("idle",true)
        -- self:findChild("Particle_3"):resetSystem()
        -- self:findChild("Particle_3"):setDuration(-1) 
    end
end


--默认按钮监听回调
function ColorfulCircusBonusProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_Click" then
        -- gLobalNoticManager:postNotification("SHOW_BONUS_Ball")
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")

    elseif  name == "Panel_Click_Progress" then 
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")

    elseif name == "Button_1_0" then
        if self.m_machine:isNormalStates() and self.m_machine:isCanClickTip(  ) then
            self.m_effectFAQ:playAction("dianji")
            self.m_FAQ:TipClick()
            gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")
        end
        
    end
end

function ColorfulCircusBonusProgress:setPercent(percent)
    self:progressEffect(percent)

end


function ColorfulCircusBonusProgress:progressEffect(percent,isPlay)

    self.m_progress:setPositionX(percent * 0.01 * PROGRESS_WIDTH)
    -- self.m_anim:setPositionX((percent * 0.01 * PROGRESS_WIDTH) + animBeginPosX)

    local transPos = util_convertToNodeSpace(self.m_progress, self.m_effectStar:getParent())
    self.m_effectStar:setPosition(cc.p(transPos))

end

function ColorfulCircusBonusProgress:restProgressEffect(_percent)

    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    
    self.m_progress:setPositionX(_percent * 0.01 * PROGRESS_WIDTH)
    -- self.m_anim:setPositionX((_percent * 0.01 * PROGRESS_WIDTH) + animBeginPosX)

    local transPos = util_convertToNodeSpace(self.m_progress, self.m_effectStar:getParent())
    self.m_effectStar:setPosition(cc.p(transPos))

end

function ColorfulCircusBonusProgress:getCollectPos()
    -- local panda = self.m_anim
    -- local pos = panda:getParent():convertToWorldSpace(cc.p(panda:getPosition()))
    -- return pos
end

function ColorfulCircusBonusProgress:updatePercent(percent,callback)
    local oldPercent = self.m_progress:getPositionX() / PROGRESS_WIDTH * 100

    local addPercent = percent - oldPercent

    --(38/60) 进度条特效时间     按此时间增长
    local perAdd = addPercent * 0.016 /(38/60)
    

    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    
    self:showUpdateParticle( )
    if self.changeAction then
        
    end
    self.changeAction = false
    self.m_percentAction = schedule(self.m_scheduleNode, function()
        oldPercent = oldPercent + perAdd
        if oldPercent >= percent then
            self:hideUpdateParticle()
            self.m_scheduleNode:stopAction(self.m_percentAction)
            self.m_percentAction = nil
            self.changeAction = true
            if callback then
                callback()
            end
            oldPercent = percent
        end
        
        self:progressEffect(oldPercent)
    end, 0.016)

end

function ColorfulCircusBonusProgress:betUnlock(func)
    self.m_effectCollectFull:setVisible(true)
    self.m_effectCollectFull:runCsbAction("animation0",false,function (  )
        
    end)
    performWithDelay(self, function()
        self.m_effectCollectFull:setVisible(false)
    end, 75/60)

    if func then
        func()
    end
end

function ColorfulCircusBonusProgress:showJiMan(func)
    self:stopAllActions()
    

    

    -- self:runCsbAction("actionframe2",false,function (  )
        if func then
            func()
        end
    -- end)
end

function ColorfulCircusBonusProgress:collectFanKui( )
    -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_wildCollect_boom.mp3")
    -- self:runCsbAction("actionframe",false,function (  )
        self.changeAction = true
        -- self:runCsbAction("idle",true)
        -- self:findChild("Particle_3"):resetSystem()
        -- self:findChild("Particle_3"):setDuration(-1) 
    -- end)

    self.m_effectBalloon:runCsbAction("actionframe", false)
end

function ColorfulCircusBonusProgress:hideUpdateParticle( )
    -- self:resetAct(self.m_effectHead1)
    -- self.m_effectHead1:runCsbAction("over", false, function()
        -- self.m_effectHead1:setVisible(false)
    -- end)
    self.m_effectHead1:setVisible(false)
    -- self.m_effectHead2:findChild("Particle_1"):stopSystem()
end

function ColorfulCircusBonusProgress:showUpdateParticle( )
    -- self:findChild("Particle_1"):resetSystem()
    -- self:findChild("Particle_2"):resetSystem()
    -- self:findChild("Particle_3"):resetSystem()
    -- self:findChild("Particle_3"):setDuration(-1) 

    -- self.m_effectHead2:findChild("Particle_1"):resetSystem()
    -- self.m_effectHead2:findChild("Particle_1"):setDuration(-1) 

    self.m_effectHead1:setVisible(true)
    self.m_effectHead1:runCsbAction("actionframe", false, function()
        -- self.m_effectHead1:runCsbAction("idle", true)
    end)

    
end

function ColorfulCircusBonusProgress:resetAct(node)
    if node and not tolua.isnull(node) then
        if node.m_csbAct and not tolua.isnull(node.m_csbAct) then
            util_resetCsbAction(node.m_csbAct)
        end
    end
end

function ColorfulCircusBonusProgress:setUI(str)
    self.m_effectBalloon:setVisible(false)
    self.m_effectFAQ:setVisible(false)
    -- self.m_effectStar:setVisible(false)
    if str == "base" then
        self.m_effectBalloon:setVisible(true)
        self.m_effectFAQ:setVisible(true)
        -- self.m_effectStar:setVisible(true)
    elseif str == "free" then
    elseif str == "respin" then
    elseif str == "duck" then
    end
end

return ColorfulCircusBonusProgress