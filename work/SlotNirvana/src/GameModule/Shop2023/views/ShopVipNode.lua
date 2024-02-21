local ShopVipNode = class("ShopVipNode", util_require("base.BaseView"))

function ShopVipNode:initUI()
    self:createCsbNode(SHOP_RES_PATH.VipNode)
    self:addClick(self:findChild("touch_open"))
    self:addClick(self:findChild("touch_close"))
    self:addClick(self:findChild("touch_vip"))
    self:addClick(self:findChild("touch_sidekicks"))

    self._totalPayEx = 1

    self:initVipPointsUI()
    self:initPetAddExUI()
    self:initTotalAddExUI()

    self:runCsbAction("idle1")
end

function ShopVipNode:updatePoints()
    self._totalPayEx = 1
    self:initVipPointsUI()
    self:initPetAddExUI()
    self:initTotalAddExUI()
end

function ShopVipNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch_open" then
        self:playShowAct()
    elseif name == "touch_close" then
        self:playHideAct()
    elseif name == "touch_vip" then
        local vip = G_GetMgr(G_REF.Vip):showMainLayer()
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(vip, name, DotUrlType.UrlName, false)
        end
    elseif name == "touch_sidekicks" then
        local selectSeasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
        local view = G_GetMgr(G_REF.Sidekicks):showMainLayer(selectSeasonIdx)
        if view then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWSHOP_CLOSE)
        end
    end
end

-- 宠物加成
function ShopVipNode:initPetAddExUI()
    local data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    local petAddEx = 1
    local lbPetAddEx = self:findChild("lb_jiacheng_pet")
    if data then
        petAddEx = (math.max(data:getTotalSkillNum("PayEx"), 0) / 100) + 1
        lbPetAddEx:setString("Store Coins" .. " X" .. petAddEx)
    else
        lbPetAddEx:setString("UNLOCK AT LV" .. (globalData.constantData.SIDE_KICKS_OPEN_LEVEL or 60))
    end
    self._totalPayEx = self._totalPayEx * petAddEx
end

-- vip加成
function ShopVipNode:initVipPointsUI()
    local vipLevel = globalData.userRunData.vipLevel
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if vipBoost and vipBoost:isOpenBoost() then
        local extraLevel = vipBoost:getBoostVipLevelIcon()
        if extraLevel > 0 then
            vipLevel = vipLevel + extraLevel
        end
    end

    local imgVipLevel = math.min(vipLevel, VipConfig.MAX_LEVEL)

    local img = self:findChild("sp_vipName")
    if img then
        -- img:setPositionX(-17)
        local path = VipConfig.name_small .. imgVipLevel .. ".png"
        if path ~= "" and util_IsFileExist(path) then
            util_changeTexture(img, path)
        end
        util_scaleCoinLabGameLayerFromBgWidth(img, 170, 1)
    end

    local imgVip = self:findChild("sp_vipIcon")
    if imgVip then
        local path = VipConfig.logo_shop .. imgVipLevel .. ".png"
        if path ~= "" and util_IsFileExist(path) then
            util_changeTexture(imgVip, path)
        end
    -- imgVip:setScale(0.23)
    end

    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    local label_multip = self:findChild("lb_jiacheng_vip")
    local curVipData = vipData:getVipLevelInfo(vipLevel)
    if curVipData then
        local vipAddEx = curVipData.coinPackages or 1
        self._totalPayEx = self._totalPayEx + (vipAddEx - 1)
        label_multip:setString("Store Coins" .. " X" .. vipAddEx)
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_VIP)
end

-- 总加成
function ShopVipNode:initTotalAddExUI()
    local lbAddEx = self:findChild("lb_bonus_num")
    lbAddEx:setString("X" .. self._totalPayEx)
end

function ShopVipNode:playShowAct()
    if self._bActing then
        return
    end
    self._bActing = true
    self:stopAllActions()
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle2")
        self._bActing = false
    end, 60)

    performWithDelay(self, function ()
        self:playHideAct()
    end, 3)
end
function ShopVipNode:playHideAct()
    if self._bActing then
        return
    end
    self._bActing = true
    self:stopAllActions()
    self:runCsbAction("over", false, function()
        self:runCsbAction("idle1")
        self._bActing = false
    end, 60)
end

return ShopVipNode
