local CloverHatBonusProgress = class("CloverHatBonusProgress", util_require("base.BaseView"))
-- 构造函数
local PROGRESS_WIDTH = 713
function CloverHatBonusProgress:initUI(data)
    local resourceFilename = "CloverHat_progress.csb"
    self:createCsbNode(resourceFilename)

    self.m_progress = self.m_csbOwner["LoadingBar_3"]
    self.m_progress:setPercent(0)

    self:addClick(self.m_csbOwner["btn_map"])
    self:addClick(self.m_csbOwner["btn_show_Tip"])
    

    self.m_effectLayer = self.m_csbOwner["Panel_SaoGuang"]
    self.m_particleProgress = self.m_csbOwner["Particle_4"]
    self.m_particleAdd = self.m_csbOwner["Particle_2"]

    self.m_anim = self:findChild("zengzhanglizi") 


    if self.m_particleAdd then
        self.m_particleAdd:stopSystem()   
    end
    if self.m_particleProgress then
        self.m_particleProgress:stopSystem()
    end


    self.m_Act = util_createAnimation("CloverHat_progress_1.csb")
    self:findChild("Node_Act"):addChild(self.m_Act )
    self.m_Act:runCsbAction("idle")

    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)
end

function CloverHatBonusProgress:lock(betLevel)
    self.m_iBetLevel = betLevel
    self:runCsbAction("idle2", false, function()
        self:idle()
    end)
end

function CloverHatBonusProgress:unlock(betLevel)
    self.m_iBetLevel = betLevel
    self:findChild("Particle_3"):setPositionType(0)
    self:findChild("Particle_3"):resetSystem()
    self:findChild("Particle_3_0"):setPositionType(0)
    self:findChild("Particle_3_0"):resetSystem()

    self:runCsbAction("jiesuo", false, function()
        self:idle()
    end)
end

function CloverHatBonusProgress:idle()
    if self.m_iBetLevel == nil or self.m_iBetLevel == 0 then
        self:runCsbAction("idle2", true)
    else
        self:runCsbAction("idle", true)
    end
end

--默认按钮监听回调
function CloverHatBonusProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_map" then
        gLobalNoticManager:postNotification("SHOW_BONUS_Tip")

    elseif  name == "btn_show_Tip" then 
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")

    end
end

function CloverHatBonusProgress:setPercent(percent)
    self:progressEffect(percent)

end


function CloverHatBonusProgress:progressEffect(percent,isPlay)
    self.m_progress:setPercent(percent)
    self.m_effectLayer:setContentSize(percent * 0.01 * PROGRESS_WIDTH, 61)
    local oldPercent = self.m_progress:getPercent()

    self.m_anim:setPositionX((oldPercent * 0.01 * PROGRESS_WIDTH) - 3)

end

function CloverHatBonusProgress:restProgressEffect(_percent)

    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    
    self.m_progress:setPercent(_percent)
    self.m_effectLayer:setContentSize(_percent * 0.01 * PROGRESS_WIDTH, 61)
    local oldPercent = self.m_progress:getPercent()
    self.m_anim:setPositionX((oldPercent * 0.01 * PROGRESS_WIDTH) - 3)
end

function CloverHatBonusProgress:getCollectPos()
    local panda = self:findChild("pand_0")
    local pos = panda:getParent():convertToWorldSpace(cc.p(panda:getPosition()))
    return pos
end

function CloverHatBonusProgress:updatePercent(percent,callback)
    local oldPercent = self.m_progress:getPercent()

    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    
    self:showUpdateParticl( )
    
    gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_CollectFanKui.mp3")

    self.m_percentAction = schedule(self.m_scheduleNode, function()
        oldPercent = oldPercent + 1
        if oldPercent >= percent then
            self.m_scheduleNode:stopAction(self.m_percentAction)
            self.m_percentAction = nil
            if callback then
                callback()
            end
            oldPercent = percent
        end
        
        self:progressEffect(oldPercent)
    end, 0.03)


    self:runCsbAction("actionframe", false, function()

        self:hideUpdateParticl()
        
        if percent >= 100 then

            self:runCsbAction("actionframe")
        else
            self:idle()
        end
    end)
end

function CloverHatBonusProgress:hideUpdateParticl( )

    if self.m_particleAdd then
        self.m_particleAdd:stopSystem()   
    end

    if self.m_particleProgress then
        self.m_particleProgress:stopSystem()
    end


end

function CloverHatBonusProgress:showUpdateParticl( )

    if self.m_particleAdd then
        self.m_particleAdd:resetSystem()   
    end
    if self.m_particleProgress then
        self.m_particleProgress:resetSystem()
    end
 
end

function CloverHatBonusProgress:onEnter()

end

function CloverHatBonusProgress:onExit()

end

return CloverHatBonusProgress