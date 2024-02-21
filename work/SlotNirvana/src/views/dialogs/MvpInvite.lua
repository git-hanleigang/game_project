--[[
    VIP邀请邮件优化（增加二级弹板）
    author:zzy
    time:2023-08-31 19:47:04
]]

local MvpInviteLayer = class("MvpInviteLayer", BaseLayer)

function MvpInviteLayer:ctor()
    MvpInviteLayer.super.ctor(self) 

    -- 横屏资源
    self:setLandscapeCsbName("Dialog/MvpInvite.csb")
end

function MvpInviteLayer:initCsbNodes()
    self.m_particle1 = self:findChild("Particle_10")
    self.m_particle2 = self:findChild("Particle_20")
    self.m_particle3 = self:findChild("Particle_1_00")
    self.m_particle4 = self:findChild("Particle_2_00")
end

function MvpInviteLayer:initView()
    self:setButtonLabelContent("btn_ok","JOIN NOW")
end

function MvpInviteLayer:playParticle()
    self.m_particle1:resetSystem()
    self.m_particle2:resetSystem()
    self.m_particle3:resetSystem()
    self.m_particle4:resetSystem()
end

function MvpInviteLayer:playShowAction()
    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        performWithDelay(
            self,
            function()
                self:playParticle() --彩带
            end,
            5/60
        )
        self:runCsbAction(
            "show",
            false,
            function()
                self:runCsbAction("idle", true, nil, 60)
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    MvpInviteLayer.super.playShowAction(self, userDefAction)
end


function MvpInviteLayer:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_ok" then
        self:closeUI(function ()
            globalPlatformManager:openFB(globalData.constantData:getFbVipGroupsUrl(), "groups")  -- 跳转到FaceBook 社群
        end)
    elseif name == "btnClose" then
        self:closeUI()
    end

end

return MvpInviteLayer