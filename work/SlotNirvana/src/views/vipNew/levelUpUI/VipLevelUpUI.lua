---
-- Vip 升级界面
--
--
local VipLevelUpUI = class("VipLevelUpUI", BaseLayer)

function VipLevelUpUI:initDatas()
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("VipNew/csd/levelUpUI/VipLevelUpUI.csb")
end

function VipLevelUpUI:initCsbNodes()
    self.m_spVipIcon = self:findChild("sp_vipIcon")
    self.m_spVipName = self:findChild("sp_vipName")
    self.m_lizi1 = self:findChild("Particle_1")
    self.m_lizi2 = self:findChild("Particle_2")
end

function VipLevelUpUI:initView()
    local vipLv = self:getCurVipLevel()
    util_changeTexture(self.m_spVipIcon, VipConfig.logo_big .. vipLv .. ".png")
    util_changeTexture(self.m_spVipName, VipConfig.name_big .. vipLv .. ".png")

    -- 通用按钮扫光
    self:startButtonAnimation("btn_go", "sweep", true)
end

function VipLevelUpUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 30)
end

function VipLevelUpUI:closeUI(_over)
    if self.m_closed then
        return
    end
    self.m_closed = true

    self.m_lizi1:stopSystem()
    self.m_lizi1:setVisible(false)
    self.m_lizi2:stopSystem()
    self.m_lizi2:setVisible(false)

    VipLevelUpUI.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
        end
    )
end

function VipLevelUpUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI(
            function()
                G_GetMgr(G_REF.Vip):exitVipSys()
            end
        )
    elseif name == "btn_go" then
        self:closeUI(
            function()
                local vip = G_GetMgr(G_REF.Vip):showRewardLayer(nil,nil,1)
                if vip then
                    gLobalSendDataManager:getLogPopub():addNodeDot(vip, name, DotUrlType.UrlName, false)
                end
            end
        )
    end
end

function VipLevelUpUI:getCurVipLevel()
    local curVipLevel = globalData.userRunData.vipLevel
    -- local data = G_GetMgr(G_REF.Vip):getData()
    -- if data then
    --     local VipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    --     if VipBoostData and VipBoostData:isOpenBoost() then
    --         local nextData = data:getVipLevelInfo(curVipLevel + VipBoostData.p_extraVipLevel) --获取下一个等级的VIP数据
    --         if nextData then
    --             curVipLevel = nextData.levelIndex
    --         end
    --     end
    -- end
    return curVipLevel
end

return VipLevelUpUI
