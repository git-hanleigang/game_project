local CashBonusVipAddView = class("CashBonusVipAddView", util_require("base.BaseView"))

function CashBonusVipAddView:initUI()
    local mgr = G_GetMgr(G_REF.CashBonus)
    if mgr then
        local bonusCfg = mgr:getBonusConfig()
        if bonusCfg then
            -- setDefaultTextureType("RGBA8888", nil)
            local CashPickGameVipAdd = bonusCfg.commonCsb.CashPickGameVipAdd
            self:createCsbNode(CashPickGameVipAdd)
            -- setDefaultTextureType("RGBA4444", nil)

            self:initVipIcon()
        else
            self:closeUI()
            return
        end
    else
        self:closeUI()
        return
    end
end

function CashBonusVipAddView:initVipIcon()
    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    local path = "PBRes/CommonItemRes/icon/Vip"
    for i = 1, VipConfig.MAX_LEVEL do
        local levelInfo = vipData:getVipLevelInfo(i)
        local spIcon = self:findChild("sp_vip" .. i)
        spIcon:setScale(0.5)
        util_changeTexture(spIcon, path .. i .. ".png")
    end
end

function CashBonusVipAddView:initData()
    local boostVipLv = nil
    local boostVipLvIcon = nil
    -- lb_vipAdd1
    local sp_vipBoostTip = self:findChild("sp_vipBoostTip")
    if sp_vipBoostTip then
        sp_vipBoostTip:setVisible(false)
        local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
        if vipBoost and vipBoost:isOpenBoost() then
            sp_vipBoostTip:setVisible(true)
            boostVipLv = vipBoost:getBoostVipLevel()
            boostVipLvIcon = vipBoost:getBoostVipLevelIcon()
        end
    end
    local vipLevel = globalData.userRunData.vipLevel
    local userVipLevel = globalData.userRunData.vipLevel
    local vipLevelIcon = globalData.userRunData.vipLevel
    if boostVipLv then
        vipLevel = vipLevel + boostVipLv
    end
    if boostVipLvIcon then
        vipLevelIcon = vipLevelIcon + boostVipLvIcon
    end

    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    for i = 1, VipConfig.MAX_LEVEL do
        local vip = i
        if i == userVipLevel then
            vip = vipLevel
        end
        local levelInfo = vipData:getVipLevelInfo(vip)
        local lb_vipAdd = self:findChild("lb_vipAdd" .. i)
        if i <= VipConfig.MULTI then
            lb_vipAdd:setString("X" .. levelInfo.cashBonus)
        end
        if i == vipLevelIcon then
            self:addVipEff(vipLevelIcon)
            if boostVipLv then
                sp_vipBoostTip:setPositionX(lb_vipAdd:getPositionX())
            end
            self.m_nowVipLab = lb_vipAdd
        end
    end
end

function CashBonusVipAddView:runShowAction()
    self:runCsbAction("show", false, nil, 30)
end

function CashBonusVipAddView:addVipEff(vipLv)
    local anim = util_createAnimation("Hourbonus_new3/Dailybonus_vip_lizi.csb")
    self:findChild("VIP_" .. vipLv):addChild(anim)
    anim:playAction(
        "start",
        false,
        function()
            anim:playAction("idle", true)
        end
    )
end
function CashBonusVipAddView:closeUI(callback)
    self:runCsbAction(
        "over",
        false,
        function()
            if callback then
                callback()
            end
            if not tolua.isnull(self) then
                self:removeFromParent()
            end
        end,
        30
    )
end

--用于 DialyBonus--------
function CashBonusVipAddView:initData2()
    local boostVipLv = nil
    local boostVipLvIcon = nil
    -- lb_vipAdd1
    local sp_vipBoostTip = self:findChild("sp_vipBoostTip")
    if sp_vipBoostTip then
        sp_vipBoostTip:setVisible(false)
        local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
        if vipBoost and vipBoost:isOpenBoost() then
            sp_vipBoostTip:setVisible(true)
            boostVipLv = vipBoost:getBoostVipLevel()
            boostVipLvIcon = vipBoost:getBoostVipLevelIcon()
        end
    end
    local vipLevel = globalData.userRunData.vipLevel
    local userVipLevel = globalData.userRunData.vipLevel
    local vipLevelIcon = globalData.userRunData.vipLevel
    if boostVipLv then
        vipLevel = vipLevel + boostVipLv
    end
    if boostVipLvIcon then
        vipLevelIcon = vipLevelIcon + boostVipLvIcon
    end

    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    for i = 1, VipConfig.MAX_LEVEL do
        local vip = i
        if i == userVipLevel then
            vip = vipLevel
        end
        local levelInfo = vipData:getVipLevelInfo(vip)
        local lb_vipAdd = self:findChild("lb_vipAdd" .. i)
        if i <= VipConfig.MULTI then
            lb_vipAdd:setString("X" .. levelInfo.cashBonus)
        end
        if i == vipLevelIcon then
            self:initVipEffect(vipLevelIcon)
            if boostVipLv then
                sp_vipBoostTip:setPositionX(lb_vipAdd:getPositionX())
            end
            self.m_nowVipLab = lb_vipAdd
        end
    end
end

function CashBonusVipAddView:initVipEffect(vipLv)
    self.m_vipEffect = util_createAnimation("Hourbonus_new3/Dailybonus_vip_lizi.csb")
    local vipNode = self:findChild("VIP_" .. vipLv)

    vipNode:addChild(self.m_vipEffect)

    self.m_vipEffect:setVisible(false)
end

function CashBonusVipAddView:getNowVipNodeWorldPos()
    local worldPos = self.m_nowVipLab:getParent():convertToWorldSpace(cc.p(self.m_nowVipLab:getPosition()))

    return worldPos
end

function CashBonusVipAddView:playVipEffect(startActionEndCallBack)
    self.m_vipEffect:setVisible(true)
    self.m_vipEffect:playAction(
        "start",
        false,
        function()
            startActionEndCallBack() ---start播放结束 调用飞数字的回调
            self.m_vipEffect:playAction("idle", true)
        end
    )
end

----------DialyBonus--------end
return CashBonusVipAddView
