local GoldExpressBonusProgress = class("GoldExpressBonusProgress", util_require("base.BaseView"))
-- 构造函数
local PROGRESS_WIDTH = 592
function GoldExpressBonusProgress:initUI(data)
    local resourceFilename = "GoldExpress_bonus_jindutiao.csb"
    self:createCsbNode(resourceFilename)

    self.m_progress = self.m_csbOwner["LoadingBar_1"]
    self:addClick(self.m_csbOwner["btn_unlock"])
    self:addClick(self.m_csbOwner["btn_map"])

    self.m_effectLayer = self.m_csbOwner["Panel_1"]
    self.m_particleProgress = self.m_csbOwner["Particle_1"]
    self.m_particleAdd = self.m_csbOwner["Particle_2"]
    self.m_particleUnlock = self.m_csbOwner["Particle_3"]
    if self.m_particleAdd then
        self.m_particleAdd:stopSystem()
        self.m_particleProgress:stopSystem()
    end
    self.m_anim = util_createAnimation("GoldExpress_bonus_jindutiao_1.csb")
    self:findChild("Panel_3"):addChild(self.m_anim)
    self.m_anim:setPositionY(55)
    self.m_anim:setVisible(false)

    self.m_particleNew = self.m_anim:findChild("Particle_2")
    self.m_particleNew:stopSystem()
    if self.m_particleUnlock then
        self.m_particleUnlock:stopSystem()
    end
end

function GoldExpressBonusProgress:lock(betLevel)
    self.m_iBetLevel = betLevel
    self:runCsbAction("idleframe0", false, function()
        self:idle()
    end)
end

function GoldExpressBonusProgress:unlock(betLevel)
    self.m_iBetLevel = betLevel
    self:runCsbAction("click", false, function()
        self:idle()
    end)
end

function GoldExpressBonusProgress:idle()
    if self.m_iBetLevel == nil or self.m_iBetLevel == 1 then
        self:runCsbAction("idleframe1", true)
    else
        self:runCsbAction("actionframe", true)
    end

end

--默认按钮监听回调
function GoldExpressBonusProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_unlock" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
    elseif name == "btn_map" then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

function GoldExpressBonusProgress:setPercent(percent, index)
    self:progressEffect(percent)
    if index == nil then
        self.m_csbOwner["reel_lunpan"]:setVisible(false)
        self.m_csbOwner["reel_s"]:setVisible(true)
    else
        self.m_csbOwner["reel_lunpan"]:setVisible(true)
        self.m_csbOwner["reel_s"]:setVisible(false)
        for i = 1, 4, 1 do
            self.m_csbOwner["reel_little_"..i]:setVisible(false)
        end
        self.m_csbOwner["reel_little_"..index]:setVisible(true)
    end
end

function GoldExpressBonusProgress:resetProgress(index, func)
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

function GoldExpressBonusProgress:progressEffect(percent,isPlay)
    self.m_progress:setPercent(percent)
    self.m_effectLayer:setContentSize(percent * 0.01 * PROGRESS_WIDTH, 61)
    local oldPercent = self.m_progress:getPercent()

    self.m_anim:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)

    if self.m_particleAdd then


        -- self.m_particleAdd:resetSystem()
        -- self.m_particleProgress:resetSystem()
        -- self.m_particleAdd:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
        -- self.m_particleProgress:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
    end

end

function GoldExpressBonusProgress:getCollectPos()
    local panda = self:findChild("pand_0")
    local pos = panda:getParent():convertToWorldSpace(cc.p(panda:getPosition()))
    return pos
end

function GoldExpressBonusProgress:updatePercent(percent,callback)
    local oldPercent = self.m_progress:getPercent()

    performWithDelay(self, function()
        -- if self.m_particleAdd then
        --     self.m_particleAdd:resetSystem()
        --     self.m_particleProgress:resetSystem()
        -- end
        self.m_anim:setVisible(true)
        self.m_particleNew:resetSystem()
        self.m_anim:playAction("animation0",true,function()
            self.m_anim:setVisible(false)
            self.m_particleNew:stopSystem()

        end)
        if self.m_percentAction ~= nil then
            self:stopAction(self.m_percentAction)
            self.m_percentAction = nil
        end
        
        self.m_percentAction = schedule(self, function()
            oldPercent = oldPercent + 1
            if oldPercent >= percent then
                self:stopAction(self.m_percentAction)
                self.m_percentAction = nil
                if callback then
                    callback()
                end
                oldPercent = percent


                -- if self.m_particleAdd then
                --     self.m_particleAdd:stopSystem()
                --     self.m_particleProgress:stopSystem()

                -- end
            end
            -- self.m_anim:setVisible(true)
            -- self.m_particleNew:resetSystem()
            -- self.m_particleNew:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
            -- self.m_anim:playAction("animation0",false,function()
            --     self.m_anim:setVisible(false)
            -- end)
            -- if self.m_particleAdd then
            --     self.m_particleAdd:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
            --     self.m_particleProgress:setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)

            -- end
            self:progressEffect(oldPercent)
        end, 0.03)
    end, 0.5)

    self:runCsbAction("actionframe2", false, function()
        if percent >= 100 then
            -- gLobalSoundManager:playSound("CharmsSounds/sound_Charms_tramcar_enter.mp3")
            -- performWithDelay(self, function()
            --     self:completed()
            -- end, 2)
            gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_collect_completed.mp3")
            self:runCsbAction("reel_shouji")
        else
            self:idle()
        end
    end)
end

function GoldExpressBonusProgress:onEnter()

end

function GoldExpressBonusProgress:onExit()

end

return GoldExpressBonusProgress