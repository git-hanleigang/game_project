local PelicanBonusProgress = class("PelicanBonusProgress", util_require("base.BaseView"))
-- 构造函数
local PROGRESS_WIDTH = 548
local animBeginPosX = -320
local animEndPosX = 268
function PelicanBonusProgress:initUI(data)
    local resourceFilename = "Pelican_loadingbar.csb"
    self:createCsbNode(resourceFilename)

    self.m_progress = self.m_csbOwner["loadingbar"]
    self.m_progress:setPositionX(60)

    self:addClick(self.m_csbOwner["touchBtn"])
    self:addClick(self.m_csbOwner["Button_1"])
    
    self:runCsbAction("idle",true)

    self.m_anim = cc.Node:create()
    self:findChild("Node_1"):addChild(self.m_anim)
    self.m_anim:setPositionX(animBeginPosX)

    self.changeAction = true


    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)
end

function PelicanBonusProgress:lock(betLevel)
    self.m_iBetLevel = betLevel
    self:stopAllActions()
    self:runCsbAction("lock",false,function (  )
        self:idle()
    end)
end

function PelicanBonusProgress:unlock(betLevel)
    self.m_iBetLevel = betLevel
    self:stopAllActions()
    self:findChild("Particle_5"):resetSystem()
    self:findChild("Particle_6"):resetSystem()
    self:runCsbAction("unlock", false, function()
        self:findChild("Particle_5"):stopSystem()
        self:findChild("Particle_6"):stopSystem()
        self:idle()

    end)
end

function PelicanBonusProgress:idle()
    if self.m_iBetLevel == nil or self.m_iBetLevel == 0 then
        self:runCsbAction("lock",true)
    else
        self:runCsbAction("idle",true)
        self:findChild("Particle_3"):resetSystem()
        self:findChild("Particle_3"):setDuration(-1) 
    end
end


--默认按钮监听回调
function PelicanBonusProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_1" then
        gLobalNoticManager:postNotification("SHOW_BONUS_Tip")

    elseif  name == "touchBtn" then 
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")

    end
end

function PelicanBonusProgress:setPercent(percent)
    self:progressEffect(percent)

end


function PelicanBonusProgress:progressEffect(percent,isPlay)

    self.m_progress:setPositionX(percent * 0.01 * PROGRESS_WIDTH + 7)
    self.m_anim:setPositionX((percent * 0.01 * PROGRESS_WIDTH) + animBeginPosX)

end

function PelicanBonusProgress:restProgressEffect(_percent)

    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    
    self.m_progress:setPositionX(_percent * 0.01 * PROGRESS_WIDTH + 7)
    self.m_anim:setPositionX((_percent * 0.01 * PROGRESS_WIDTH) + animBeginPosX)

end

function PelicanBonusProgress:getCollectPos()
    local panda = self.m_anim
    local pos = panda:getParent():convertToWorldSpace(cc.p(panda:getPosition()))
    return pos
end

function PelicanBonusProgress:updatePercent(percent,callback)
    local oldPercent = self.m_progress:getPositionX() / PROGRESS_WIDTH * 100

    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    
    self:showUpdateParticl( )
    if self.changeAction then
        
    end
    self.changeAction = false
    self.m_percentAction = schedule(self.m_scheduleNode, function()
        oldPercent = oldPercent + 1
        if oldPercent >= percent then
            self.m_scheduleNode:stopAction(self.m_percentAction)
            self.m_percentAction = nil
            self.changeAction = true
            if callback then
                callback()
            end
            oldPercent = percent
        end
        
        self:progressEffect(oldPercent)
    end, 0.03)

end

function PelicanBonusProgress:showJiMan(func)
    self:stopAllActions()
    
    self:runCsbAction("actionframe2",false,function (  )
        if func then
            func()
        end
    end)
end

function PelicanBonusProgress:collectFanKui( )
    gLobalSoundManager:playSound("PelicanSounds/Pelican_wildCollect_boom.mp3")
    self:runCsbAction("actionframe",false,function (  )
        self.changeAction = true
        self:runCsbAction("idle",true)
        self:findChild("Particle_3"):resetSystem()
        self:findChild("Particle_3"):setDuration(-1) 
    end)
end

function PelicanBonusProgress:hideUpdateParticl( )


end

function PelicanBonusProgress:showUpdateParticl( )
    self:findChild("Particle_1"):resetSystem()
    self:findChild("Particle_2"):resetSystem()
    self:findChild("Particle_3"):resetSystem()
    self:findChild("Particle_3"):setDuration(-1) 
end

return PelicanBonusProgress