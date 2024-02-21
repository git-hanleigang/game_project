--[[--
    vip 主界面
]]
local VipMainUI = class("VipMainUI", BaseLayer)

function VipMainUI:initDatas(_data)
    self:setLandscapeCsbName("VipNew/csd/mainUI/VipMainUI.csb")
    self.m_isBubbleShow = false
    self:addClickSound("btn_vip_close", SOUND_ENUM.SOUND_HIDE_VIEW)
end

function VipMainUI:initCsbNodes()
    self.m_nodeBubble = self:findChild("node_qipao")
    self.m_spBoost = self:findChild("sp_boost")

    self.m_btnInfo = self:findChild("btn_explain")
    self.m_btnClose = self:findChild("btn_vip_close")
    self.m_btnReward = self:findChild("btn_vip_rewards")

    self.m_lbPro = self:findChild("lb_pro")
    self.m_progress = self:findChild("vip_pro")

    self.m_nodeNow = self:findChild("node_now")
    self.m_spVipIconNow = self:findChild("sp_vipIcon_now")
    self.m_spVipNameNow = self:findChild("sp_vipName_now")

    self.m_nodeNext = self:findChild("node_next")
    self.m_spVipIconNext = self:findChild("sp_vipIcon_next")
    self.m_spVipNameNext = self:findChild("sp_vipName_next")

    self.m_nodePointMax = self:findChild("node_point_max")
    self.m_nodePoint = self:findChild("node_point")
    self.m_lbPoint_Vip = self:findChild("lb_point_vip")
    self.m_spPoint_VipName = self:findChild("sp_point_vipName")
    self.m_lbPoint_Required = self:findChild("lb_Requered")
    self.m_lbPoint = self:findChild("lb_point")
    self.m_lbPoint_VipPoints = self:findChild("lb_Vip_points")

    self.m_nodeLogo = self:findChild("node_VIP_title")
    self.m_nodeTopDoublePoints = self:findChild("node_top_doublePoints")

    -- self.m_lbYearPointDes = self:findChild("lb_yearPoint_des")
    -- self.m_lbYearPoint = self:findChild("lb_yearPoint")
    -- self.m_btnResetBubble = self:findChild("btn_pointdec")

    self.m_sp_experience = self:findChild("sp_experience")
end

function VipMainUI:initView()
    -- self:initBubble()
    self:initVipLogo()
    self:initVipDoublePoints()
    self:initBoost()
    self:initCur()
    self:initNext()
    self:initPoint()
    self:initProgress()
    --下面这一行暂时不删，万一策划脑子抽了又要用
    --self:initYearPoint()
end

-- -- 说明气泡
-- function VipMainUI:initBubble()
--     self.m_infoBubble = util_createView("views.vipNew.mainUI.VipInfoBubble")
--     self.m_nodeBubble:addChild(self.m_infoBubble)
-- end

-- function VipMainUI:showBubble()
--     self.m_isBubbleShowing = true
--     self.m_infoBubble:playShow(
--         function()
--             self.m_isBubbleShowing = false
--             self.m_infoBubble:playIdle()
--         end
--     )
-- end

-- function VipMainUI:hideBubble()
--     self.m_isBubbleHiding = true
--     self.m_infoBubble:playOver(
--         function()
--             self.m_isBubbleHiding = false
--         end
--     )
-- end

-- function VipMainUI:clearBubbleTimer()
--     if self.m_bubbleTimer then
--         self:stopAction(self.m_bubbleTimer)
--         self.m_bubbleTimer = nil
--     end
-- end

-- function VipMainUI:startBubbleTimer()
--     self.m_bubbleTimer =
--         util_performWithDelay(
--         self.m_infoBubble,
--         function()
--             if not tolua.isnull(self) then
--                 if self.m_isBubbleShow == true then
--                     self.m_isBubbleShow = false
--                     self:hideBubble()
--                 end
--                 self:clearBubbleTimer()
--             end
--         end,
--         5
--     )
-- end

function VipMainUI:initVipLogo()
    self.m_vipLogo = util_createView("views.vipNew.mainUI.VipMainLogoNode")
    self.m_nodeLogo:addChild(self.m_vipLogo)
end

function VipMainUI:initVipDoublePoints()
    if self:isHasDoublePoints() then
        self.m_doublePoints = util_createView("views.vipNew.mainUI.VipMainDoublePointsNode")
        self.m_nodeTopDoublePoints:addChild(self.m_doublePoints)
    end
end

function VipMainUI:initBoost()
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if vipBoost and vipBoost:isOpenBoost() then
        self.m_spBoost:setVisible(not vipBoost:isExperienceItemType())
        self.m_sp_experience:setVisible(vipBoost:isExperienceItemType())
    else
        self.m_spBoost:setVisible(false)
        self.m_sp_experience:setVisible(false)
    end
end

function VipMainUI:initCur()
    local curLevel = globalData.userRunData.vipLevel

    local curVipData = nil
    -- if curLevel == VipConfig.MAX_LEVEL then
    --     curVipData = self:getVipData(curLevel - 1)
    -- else
    --     curVipData = self:getVipData(curLevel)
    -- end
    curVipData = self:getVipData(curLevel)
    if not curVipData then
        return
    end
    -- icon
    local curIconPath = VipConfig.logo_middle .. curVipData.levelIndex .. ".png"
    util_changeTexture(self.m_spVipIconNow, curIconPath)
    -- name
    local curNamePath = VipConfig.name_big .. curVipData.levelIndex .. ".png"
    util_changeTexture(self.m_spVipNameNow, curNamePath)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_spVipNameNow, 270, 1)
end

function VipMainUI:initNext()
    local curLevel = globalData.userRunData.vipLevel
    local nextVipData = nil
    -- if curLevel == VipConfig.MAX_LEVEL then
    --     nextVipData = self:getVipData(curLevel)
    -- else
    --     nextVipData = self:getVipData(curLevel + 1)
    -- end
    nextVipData = self:getVipData(curLevel + 1)

    if nextVipData then
        self.m_nodeNext:setVisible(true)
        -- icon
        local nextIconPath = VipConfig.logo_middle .. nextVipData.levelIndex .. ".png"
        util_changeTexture(self.m_spVipIconNext, nextIconPath)
        -- name
        local nextNamePath = VipConfig.name_big .. nextVipData.levelIndex .. ".png"
        util_changeTexture(self.m_spVipNameNext, nextNamePath)
        util_scaleCoinLabGameLayerFromBgWidth(self.m_spVipNameNext, 270, 1)
    else
        self.m_nodeNext:setVisible(false)
    end
end

function VipMainUI:initPoint()
    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    local curLevel = globalData.userRunData.vipLevel
    if curLevel == VipConfig.MAX_LEVEL then
        -- 最大
        self.m_nodePoint:setVisible(false)
        self.m_nodePointMax:setVisible(true)
    else
        self.m_nodePoint:setVisible(true)
        self.m_nodePointMax:setVisible(false)
        -- name
        local curNamePath = VipConfig.name_small .. (curLevel + 1) .. ".png"
        util_changeTexture(self.m_spPoint_VipName, curNamePath)
        -- point
        local point = self:getVipPoint()
        self.m_lbPoint:setString(util_getFromatMoneyStr(point))
        -- 居中对齐
        local UIList = {}
        table.insert(UIList, {node = self.m_lbPoint_Vip})
        table.insert(UIList, {node = self.m_spPoint_VipName, scale = 1.2, alignX = 5})
        table.insert(UIList, {node = self.m_lbPoint_Required, alignX = 5})
        table.insert(UIList, {node = self.m_lbPoint, alignX = 5})
        table.insert(UIList, {node = self.m_lbPoint_VipPoints, alignX = 5})
        util_alignCenter(UIList)
    end
end

function VipMainUI:initProgress()
    local vipPoint = globalData.userRunData.vipPoints
    local curLevel = globalData.userRunData.vipLevel
    local curVipData = self:getVipData(curLevel)
    if not curVipData or curVipData.levelPoints == -1 then
        self.m_lbPro:setString(util_getFromatMoneyStr(vipPoint) .. "/MAX")
        self.m_progress:setPercent(100)
    else
        self.m_lbPro:setString(util_getFromatMoneyStr(vipPoint) .. "/" .. util_getFromatMoneyStr(curVipData.levelPoints))
        self.m_progress:setPercent(tonumber(vipPoint) / curVipData.levelPoints * 100)
    end
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbPro, 190, 1)
end

function VipMainUI:initYearPoint()
    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    local resetData = vipData:getResetData()
    if not resetData then
        return
    end
    local UIList = {}
    local thisYear = resetData:getYear()
    local onlineYear = resetData:getOnlineYear()
    local tYearPoints = resetData:getThisYearVipPoints()
    local tRegisterPoints = resetData:getRegisterTotalVipPoints()

    -- 描述文本
    local yearDes = (thisYear == onlineYear) and "REGISTRATION" or thisYear
    self.m_lbYearPointDes:setString("VIP POINTS SINCE " .. yearDes .. ":")
    table.insert(UIList, {node = self.m_lbYearPointDes, alignX = 5})
    -- 本年度总积分
    self.m_lbYearPoint:setString(util_formatCoins(((thisYear == onlineYear) and tRegisterPoints or tYearPoints), 30))
    table.insert(UIList, {node = self.m_lbYearPoint, alignX = 5})
    -- 问号按钮
    table.insert(UIList, {node = self.m_btnResetBubble, alignX = 5})
    -- 对齐
    util_alignCenter(UIList)
end

function VipMainUI:showResetBubble()
    local resetBubble = util_createView("views.vipNew.mainUI.VipMainResetBubble")
    self.m_btnResetBubble:addChild(resetBubble)
    local btnSize = self.m_btnResetBubble:getContentSize()
    resetBubble:setPosition(cc.p(btnSize.width + 20, btnSize.height / 2))
end

-- function VipMainUI:clickBtnInfo()
--     if self.m_isBubbleShowing or self.m_isBubbleHiding then
--         return
--     end
--     self:clearBubbleTimer()
--     self.m_isBubbleShow = not self.m_isBubbleShow
--     if self.m_isBubbleShow == true then
--         self:startBubbleTimer()
--         self:showBubble()
--     else
--         self:hideBubble()
--     end
-- end

function VipMainUI:closeUI(_over)
    VipMainUI.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
            globalNoviceGuideManager:attemptShowRepetition()
        end
    )
end

function VipMainUI:canClick()
    if self:isShowing() or self:isHiding() then
        return false
    end
    return true
end

function VipMainUI:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "btn_vip_close" then
        self:closeUI(
            function()
                G_GetMgr(G_REF.Vip):exitVipSys()
            end
        )
    elseif name == "btn_vip_rewards" then
        -- self:closeUI(
        --     function()
        --         local view = G_GetMgr(G_REF.Vip):showRewardLayer()
        --         if view then
        --             gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_vip_rewards", DotUrlType.UrlName, false)
        --         end
        --     end
        -- )
        self.m_btnReward:setTouchEnabled(false)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_touchEnable then
            return
        end
        self.m_touchEnable = true
        self:runCsbAction("over",false,function()
            if not tolua.isnull(self) then
                local view = G_GetMgr(G_REF.Vip):showRewardLayer()
                if view then
                    gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_vip_rewards", DotUrlType.UrlName, false)
                end
                self.m_touchEnable = false
            end
        end)
    elseif name == "btn_explain" then
        -- self:clickBtnInfo()
        G_GetMgr(G_REF.Vip):showInfoLayer()
    end
end

function VipMainUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function VipMainUI:getVipPoint()
    local curLevel = tonumber(globalData.userRunData.vipLevel)
    local vipPoint = tonumber(globalData.userRunData.vipPoints)
    local vipData = G_GetMgr(G_REF.Vip):getData()
    local curVipData = vipData and vipData:getVipLevelInfo(curLevel)
    if not curVipData or curVipData.levelPoints == -1 then
        return vipPoint
    else
        local differVipPoint = curVipData.levelPoints - vipPoint
        return math.max(0, differVipPoint)
    end
end

function VipMainUI:getVipData(_vipLevel)
    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    local curVipData = vipData:getVipLevelInfo(_vipLevel)
    -- assert(curVipData ~= nil, "VipData is nil")
    return curVipData
end

function VipMainUI:isHasDoublePoints()
    local doublePointsData = G_GetMgr(ACTIVITY_REF.VipDoublePoint):getData()
    if doublePointsData and doublePointsData:isRunning() then
        return true
    end
    return false
end

function VipMainUI:registerListener()
    VipMainUI.super.registerListener(self)
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:runCsbAction("start",false,function( ... )
                self:runCsbAction("idle",true)
                self.m_btnReward:setTouchEnabled(true)
            end)
        end,
        ViewEventType.VIP_REWARDUI_CLOSE
    )
end

return VipMainUI
