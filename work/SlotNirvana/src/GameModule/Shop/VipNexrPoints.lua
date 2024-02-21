local VipNexrPoints = class("VipNexrPoints", util_require("base.BaseView"))

function VipNexrPoints:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self.isClick = false

    self:createCsbNode("Shop_Res/shop_Vip.csb", isAutoScale)

    self:addClick(self:findChild("click"))
end

function VipNexrPoints:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "click" then
        local vip = G_GetMgr(G_REF.Vip):showMainLayer()
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(vip, name, DotUrlType.UrlName, false)
        end
    end
end

--
function VipNexrPoints:updatePoints()
    local vipLevel = globalData.userRunData.vipLevel
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if vipBoost and vipBoost:isOpenBoost() then
        local extraLevel = vipBoost:getBoostVipLevelIcon()
        if extraLevel > 0 then
            vipLevel = vipLevel + extraLevel
        end
    end

    local img = self:findChild("Bronze_1")
    if img then
        -- img:setPositionX(-17)
        local path = VipConfig.name_small .. vipLevel .. ".png"
        if path ~= "" and util_IsFileExist(path) then
            util_changeTexture(img, path)
        end
    end

    local imgVip = self:findChild("sp_vipIcon")
    if imgVip then
        local path = VipConfig.logo_small .. vipLevel .. ".png"
        if path ~= "" and util_IsFileExist(path) then
            util_changeTexture(imgVip, path)
        end
    -- imgVip:setScale(0.23)
    end

    local vipPoint = globalData.userRunData.vipPoints
    local vipData = G_GetMgr(G_REF.Vip):getData()
    local curVipData = vipData and vipData:getVipLevelInfo(vipLevel)
    if not curVipData or curVipData.levelPoints == -1 or vipLevel >= VipConfig.MAX_LEVEL then
        -- 最高等级
        self:findChild("lowLevel"):setVisible(false)
        self:findChild("maxLevel"):setVisible(true)
    else
        local differVipPoint = curVipData.levelPoints - tonumber(vipPoint)
        if differVipPoint < 0 then
            differVipPoint = 0
        end

        self:findChild("lowLevel"):setVisible(true)
        self:findChild("maxLevel"):setVisible(false)
        local str = util_getFromatMoneyStr(differVipPoint) .. " until next status"
        self:findChild("vipPoints"):setString(str)
        self:updateLabelSize({label = self:findChild("vipPoints"), sx = 0.7, sy = 0.7}, 320)
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_VIP)
end

return VipNexrPoints
