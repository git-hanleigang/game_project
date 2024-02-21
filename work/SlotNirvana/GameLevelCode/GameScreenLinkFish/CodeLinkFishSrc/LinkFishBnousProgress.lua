local LinkFishBnousProgress = class("LinkFishBnousProgress", util_require("base.BaseView"))
-- 构造函数
local PROGRESS_WIDTH = 572
function LinkFishBnousProgress:initUI(data)
    local resourceFilename = "Bonus_LinkFish_jindu.csb"
    self:createCsbNode(resourceFilename)
    
    self.m_progress = self.m_csbOwner["LoadingBar_1"]
    self:addClick(self.m_csbOwner["btn_unlock"])
    self:addClick(self.m_csbOwner["btn_map"])

    self.m_effectLayer = self.m_csbOwner["Panel_1"]
    self.m_particleProgress = self.m_csbOwner["Particle_1"]
    self.m_particleAdd = self.m_csbOwner["Particle_2"]
    self.m_particleUnlock = self.m_csbOwner["Particle_3"]

    self.m_particleAdd:stopSystem()
    self.m_particleUnlock:stopSystem()
    
end

function LinkFishBnousProgress:lock(betLevel)
    self.m_iBetLevel = betLevel
    self:runCsbAction("idleframe0", false, function()
        self:idle()
    end)
end

function LinkFishBnousProgress:unlock(betLevel)
    self.m_iBetLevel = betLevel
    self:runCsbAction("click", false, function()
        self:idle()
    end)
end

function LinkFishBnousProgress:idle()
    if self.m_iBetLevel == nil or self.m_iBetLevel == 1 then
        self:runCsbAction("idleframe1", true)
    else
        self:runCsbAction("actionframe", true)
    end
    
end

--默认按钮监听回调
function LinkFishBnousProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_unlock" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
    elseif name == "btn_map" then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

function LinkFishBnousProgress:setPercent(percent, index)
    self:progressEffect(percent)
    if index == nil then
        self.m_csbOwner["reel_lunpan"]:setVisible(false)
        self.m_csbOwner["reel_zhusun"]:setVisible(true)
    else
        self.m_csbOwner["reel_lunpan"]:setVisible(true)
        self.m_csbOwner["reel_zhusun"]:setVisible(false)
        for i = 1, 4, 1 do
            self.m_csbOwner["reel_"..i]:setVisible(false)
        end
        self.m_csbOwner["reel_"..index]:setVisible(true)
    end
end

function LinkFishBnousProgress:resetProgress(index, func)
    local percent = 100
    self.m_action = schedule(self,function()
        percent = percent - 4
        self:progressEffect(percent)
        if percent == 0 then
            self:stopAction(self.m_action)
            self:setPercent(0, index)
            if func ~= nil then
                func()
            end
        end
    end,0.016)
end

function LinkFishBnousProgress:progressEffect(percent)
    self.m_progress:setPercent(percent)
    self.m_effectLayer:setContentSize(percent * 0.01 * PROGRESS_WIDTH, 61)
end

function LinkFishBnousProgress:getCollectPos()
    local panda = self:findChild("pand")
    local pos = panda:getParent():convertToWorldSpace(cc.p(panda:getPosition()))
    return pos
end

function LinkFishBnousProgress:updatePercent(percent)
    local oldPercent = self.m_progress:getPercent()

    performWithDelay(self, function()
        self.m_particleAdd:resetSystem()
        self.m_percentAction = schedule(self, function()
            oldPercent = oldPercent + 1
            if oldPercent >= percent then
                self:stopAction(self.m_percentAction)
                self.m_percentAction = nil
                oldPercent = percent
                self.m_particleAdd:stopSystem()
            end
            self.m_particleAdd:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
            self:progressEffect(oldPercent)
        end, 0.03)
    end, 0.5)
    
    self:runCsbAction("actionframe2", false, function()
        if percent >= 100 then
            -- gLobalSoundManager:playSound("CharmsSounds/sound_Charms_tramcar_enter.mp3")
            -- performWithDelay(self, function()
            --     self:completed()
            -- end, 2)
            gLobalSoundManager:playSound("LinkFishSounds/sound_LinkFish_collect_completed.mp3")
            self:runCsbAction("reel_shouji")
        else
            self:idle()
        end
    end)
end

function LinkFishBnousProgress:onEnter()
    
end

function LinkFishBnousProgress:onExit()
    
end

return LinkFishBnousProgress