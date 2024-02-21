--[[--
    Vip boost 获取界面
]]
local VipBoostUI = class("VipBoostUI", BaseLayer)

function VipBoostUI:initDatas()
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("VipNew/csd/boostUI/VipBoostUI.csb")
end

function VipBoostUI:initCsbNodes()
    self.sp_vipHead = self:findChild("sp_head")
    self.sp_vipHeadNew = self:findChild("sp_head_new")
    self.m_lizi1 = self:findChild("ef_lizi1")
    self.m_lizi2 = self:findChild("ef_lizi1")
end

function VipBoostUI:initUI(_vipLevel)
    VipBoostUI.super.initUI(self)
    util_changeTexture(self.sp_vipHead, VipConfig.logo_big .. _vipLevel .. ".png")
    util_changeTexture(self.sp_vipHeadNew, VipConfig.logo_big .. (_vipLevel + 1) .. ".png")
end

function VipBoostUI:onShowedCallFunc()
    self.m_isPlaying = true
    self:runCsbAction(
        "show",
        false,
        function()
            self.m_isPlaying = false
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
end

function VipBoostUI:closeUI(_over)
    if self.m_closed then
        return
    end
    self.m_closed = true

    self.m_lizi1:stopSystem()
    self.m_lizi1:setVisible(false)
    self.m_lizi2:stopSystem()
    self.m_lizi2:setVisible(false)

    VipBoostUI.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
        end
    )
end

function VipBoostUI:canClick()
    if self:isShowing() or self:isHiding() then
        return false
    end
    if self.m_isPlaying then
        return false
    end
    return true
end

function VipBoostUI:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "btn_vip" then
        self:closeUI(
            function()
                G_GetMgr(G_REF.Vip):showRewardLayer(nil,nil,1)
            end
        )
    elseif name == "btn_close" then
        self:closeUI(
            function()
                G_GetMgr(G_REF.Vip):exitVipSys()
            end
        )
    end
end

return VipBoostUI
