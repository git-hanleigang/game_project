local LevelBaseNode = util_require("views.lobby.LevelBaseNode")
local LevelSmallNode = class("LevelSmallNode", LevelBaseNode)

LevelSmallNode.m_commingSoonSp = nil

function LevelSmallNode:ctor()
    LevelSmallNode.super.ctor(self)
    self:clearData()
end

function LevelSmallNode:clearData()
    self.m_isExist = false
    self.m_spinepath = ""
    self.m_spineTexture = ""
    self.m_curSpineAni = ""
    self.m_levelIconPath = ""
end

--子类重新创建的csb节点
function LevelSmallNode:getCsbName()
    self.m_nodeType = self.NODE_TYPE_SMALL

    return "newIcons/LevelSmallNode.csb"
end

function LevelSmallNode:initCsbNodes()
    self.m_node_specialFeature = self:findChild("node_wanfa")
    self.m_node_specialFeature:setVisible(false)
    self.m_node_commonJackpot = self:findChild("node_commonJackpot")
    self.m_nodeMinz = self:findChild("node_minz")

    LevelSmallNode.super.initCsbNodes(self)
end

function LevelSmallNode:initView()
    LevelSmallNode.super.initView(self)
    self:initMinz()
end

function LevelSmallNode:initSpineFileInfo(levelName)
    -- self.m_isExist, self.m_spinepath, self.m_spineTexture = self:getSpinFileInfo(levelName, "small")
    self.m_isExist, self.m_spinepath, self.m_spineTexture = globalData.slotRunData:getLobbySpinInfo(levelName, "small")
end

--维护中
function LevelSmallNode:updateMaintenance()
    LevelSmallNode.super.updateMaintenance(self)
    self:hideNode(self.m_node_specialFeature)
    self:hideNode(self.m_node_commonJackpot)
    self:hideNode(self.m_nodeMinz)
end

--初始化图标子类重写
-- function LevelSmallNode:initContent()
-- end

function LevelSmallNode:updateCommingSoonLvIcon()
    -- setDefaultTextureType("RGBA8888", nil)
    if self.m_levelName == "CommingSoon" then
        if self.m_info.p_commingSoonIndex then
            util_changeTexture(self.m_contents, "newIcons/Order/comingsoo_logo.png")
        else
            local imgCS = "newIcons/Order/" .. self.m_info.p_showName ..".png"
            if globalData.GameConfig:checkABtestGroup("CommingSoon", "B") then
                local imgCS_b = string.gsub(imgCS, "CommingSoon", "CommingSoonB")
                if util_IsFileExist(imgCS_b) then
                    imgCS = imgCS_b
                end
            end
            util_changeTexture(self.m_contents, imgCS)
            if not self.m_commingSoonSp then
                if self.m_info.p_showTitle and self.m_info.p_showTitle == 1 then
                    local commingSoonSp = util_createSprite("newIcons/Order/comingsoon_top.png")
                    self.m_node_content:addChild(commingSoonSp)
                    commingSoonSp:setPosition(-80, 180)
                    self.m_commingSoonSp = commingSoonSp
                end
            end
            if self.m_commingSoonSp then
                self.m_commingSoonSp:setVisible(true)
            end
        end
    else
        if self.m_commingSoonSp then
            self.m_commingSoonSp:setVisible(false)
        end
    end
    -- setDefaultTextureType("RGBA4444", nil)
end

-- 初始化非Spin资源logo
function LevelSmallNode:initNoSpinLogo()
    local path = nil
    if self.m_levelName == "CommingSoon" then
        return
    end
    local _bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    if _bOpenDeluxe and (not self.m_isSlotMode) then
        path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.DELUXE)
    else
        path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.SMALL)
    end
    util_changeTexture(self.m_contents, path)
    self.m_levelIconPath = path
end

-- 更新关卡Logo
function LevelSmallNode:updateLevelLogo()
    if not LevelSmallNode.super.updateLevelLogo(self) then
        return
    end
    -- printInfo("updateLevelLogo ---- " .. self.m_levelName)
    if self.m_levelName and self.m_levelName ~= "CommingSoon" then
        local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
        self:updateDeluxeLevels(bOpenDeluxe)
    end
end

-- 获得Spine资源名称
function LevelSmallNode:getSpineFileName(levelName, prefixName)
    prefixName = prefixName or ""
    local fileName = prefixName .. "_level_spine_" .. levelName
    if globalData.GameConfig:checkLevelGroupA(levelName) then
        -- 是AB Test的 A 组
        fileName = fileName .. "_abtest"
    end
    return fileName
end

function LevelSmallNode:removeSpinAnimNode()
    if not self:isOpenDyLoadVer() then
        return
    end
    local spineNode = self:getSpineLogo()
    if spineNode then
        spineNode:removeFromParent()
        self.m_isShowedLogo = false
        if self.m_levelIconPath ~= "" then
            display.removeImage(self.m_levelIconPath)
        end
        -- local isExist, spinepath, spineTexture = self.m_isExist, self.m_spinepath, self.m_spineTexture
        -- if isExist and spinepath ~= "" and spineTexture ~= "" then
        --     xcyy.SlotsUtil:releaseSpineCacheDataByName(spinepath .. ".skel")
        --     display.removeImage(spineTexture)
        -- end
        self:clearData()
    end
end

-- logoSpine动画
function LevelSmallNode:addSpineAnimNode(noSpinCallback)
    if self.m_levelName == "CommingSoon" then
        return
    end

    local noSpinCallFunc = function()
        if noSpinCallback then
            noSpinCallback()
        end
    end

    local playSpineAction = function()
        local spineLogo = self:getSpineLogo()
        if spineLogo then
            local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
            local aniName = "actionframe"
            if bOpenDeluxe and (not self.m_isSlotMode) then
                aniName = "deluxeActionframe"
            end
            if self.m_curSpineAni ~= aniName then
                util_spinePlay(spineLogo, aniName, true)
                self.m_curSpineAni = aniName
            end
        end
    end

    if util_isLow_endMachine() then
        -- 内存小于2G不使用Spine动画
        noSpinCallFunc()
    else
        local spineLogo = self:getSpineLogo()
        if not spineLogo then
            local isExist = false
            local spinepath = ""
            local spineTexture = ""

            isExist, spinepath, spineTexture = self.m_isExist, self.m_spinepath, self.m_spineTexture

            if isExist and (not self.m_isDownloadImg) then
                local _callback = function(textureInfo)
                    if not tolua.isnull(self) then
                        if not tolua.isnull(textureInfo) then
                            local _path = textureInfo:getPath()
                            local _isFind = string.find(_path, spineTexture)
                            util_changeTexture(self.m_contents, "newIcons/Order/cashlink_Small_loading.png")
                            local spineNode = self:getSpineLogo()
                            if not spineNode and _isFind then
                                spineNode = util_spineCreate(spinepath, true, true, 2)
                                spineNode:setName("SpineLogo")
                                local size = self.m_contents:getContentSize()
                                self.m_contents:addChild(spineNode)
                                spineNode:setPositionX(size.width / 2)
                                spineNode:setPositionY(111)
                            end
                            self.m_isShowedLogo = true
                            playSpineAction()
                        else
                            noSpinCallFunc()
                        end
                    end
                end
                display.loadImage(spineTexture, _callback)
            else
                print("没有 动态spine  = " .. spinepath)
                release_print("没有 动态spine  = " .. spinepath)
                noSpinCallFunc()
            end
        else
            playSpineAction()
        end
    end
end

-- 高倍场开启结束时 刷新nodeUI 子类重写
function LevelSmallNode:updateDeluxeLevels(_bOpenDeluxe)
    if not self.m_levelName or self.m_levelName == "CommingSoon" then
        return
    end

    self.m_isOpenDeluxe = _bOpenDeluxe

    local noSpineFunc = function()
        local path = nil
        if _bOpenDeluxe and (not self.m_isSlotMode) then
            path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.DELUXE)
        else
            path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.SMALL)
        end

        local _callback = function(textureInfo)
            if not tolua.isnull(self) then
                if textureInfo then
                    util_changeTexture(self.m_contents, path)
                    self.m_levelIconPath = path
                    self.m_isShowedLogo = true
                else
                    util_changeTexture(self.m_contents, "newIcons/Order/cashlink_Small_loading.png")
                end
            end
        end
        display.loadImage(path, _callback)
    end
    self:addSpineAnimNode(noSpineFunc)
end

--子类重写
function LevelSmallNode:initOtherUI()
end

--解锁相关逻辑子类重写
function LevelSmallNode:initUnlock()
    --锁
    self.m_lockNode = util_createAnimation("newIcons/Level_kongjian/Level_suo_small.csb")
    self:addChild(self.m_lockNode, 1)
    self.m_lockNode:playAction("suo2")
end
--检测是否解锁
function LevelSmallNode:playClickUnLockAction()
    if not self.m_lockNode then
        return
    end
    if self.m_isPlayUnLock then
        return
    end
    self.m_isPlayUnLock = true
    self:addBlackLayer()
    self.m_lockNode:playAction("suo")
    local time = 1
    performWithDelay(
        self,
        function()
            self.m_lockNode:playAction("fromlevel_over")
        end,
        time
    )
    performWithDelay(
        self,
        function()
            self.m_isPlayUnLock = false
            self:clearBlackLayer()
        end,
        time + 0.3
    )
end
--设置锁
function LevelSmallNode:showlock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(true)
    end
end
--隐藏锁
function LevelSmallNode:hidelock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(false)
    end
end

function LevelSmallNode:checkUnLockAction()
    if self.m_isPlayUnLock then
        return
    end

    if not self.m_lockNode then
        return
    end

    self.m_isPlayUnLock = true
    self.m_lockNode:playAction("suo")
    local time = 1
    performWithDelay(
        self,
        function()
            self.m_lockNode:playAction("fromlevel_over")
        end,
        time
    )
    performWithDelay(
        self,
        function()
            self.m_isPlayUnLock = false
        end,
        time + 0.3
    )
end

--清空jackpot逻辑小关卡不需要
function LevelSmallNode:initJackpot()
    LevelSmallNode.super.initJackpot(self)
    self:initTopRightWanfa()
end
-- 头像框标识
function LevelSmallNode:initAvatarFrameTagUI()
    LevelSmallNode.super.initAvatarFrameTagUI(self)

    if self.m_node_specialFeature:isVisible() then
        self.m_nodeAvararFrame:setVisible(false)
    end
end

function LevelSmallNode:clickFunc(sender)
    gLobalSendDataManager:getLogSlots():resetEnterLevel()
    local siteName = self:getSiteName()
    gLobalSendDataManager:getLogSlots():setEnterLevelSiteName(siteName)
    local siteType = self:getSiteType()
    if siteType then
        gLobalSendDataManager:getLogSlots():setEnterLevelSiteType(siteType)
    else
        if globalData.deluexeClubData:getDeluexeClubStatus() == true then
            if self.m_info.p_highBetFlag then
                gLobalSendDataManager:getLogSlots():setEnterLevelSiteType("HightArea")
            else
                gLobalSendDataManager:getLogSlots():setEnterLevelSiteType("RegularArea")
            end
        else
            gLobalSendDataManager:getLogSlots():setEnterLevelSiteType("RegularArea")
        end
    end
    LevelSmallNode.super.clickFunc(self, sender)
end

function LevelSmallNode:checkGotoLevel()
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
    --下载入口记录
    if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL and self.m_info then
        gLobalSendDataManager:getLogGameLevelDL():setDownloadInfo(self.m_info.p_levelName, {type = "normal", siteType = "RegularArea"})
    end
    LevelSmallNode.super.checkGotoLevel(self)
end

function LevelSmallNode:getTagCsbName()
    return "newIcons/Level_kongjian/Level_tag_small.csb"
end

function LevelSmallNode:updateCommingSoon()
    local isCommingSoon = LevelSmallNode.super.updateCommingSoon(self)

    self:updateCommingSoonLvIcon()

    self:hidelock()

    return isCommingSoon
end

function LevelSmallNode:changeBonusHuntIcon(view)
    if view ~= nil then
        local bonusHuntIcon = view
        util_changeTexture(bonusHuntIcon, "newIcons/Other/wanfa_bonshuntSmall.png")
    end
end

--添加buff子类重写
function LevelSmallNode:updateBuffCoins(buffCoin, levelId)
    if levelId == self.m_info.p_id and not self:getChildByName("GAMECRAZE_BUFF") then
        buffCoin:setName("GAMECRAZE_BUFF")
        local size = self.m_contents:getContentSize()
        -- local pos = cc.p(-size.width/2, -size.height / 4)
        local pos = self:getHuntPos()
        buffCoin:setPosition(pos)
        self:addChild(buffCoin)
    end
end

function LevelSmallNode:openScheduleEnter()
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
    self.activityAction =
        util_performWithDelay(
        self,
        function()
            gLobalSendDataManager:getLogSlots():resetEnterLevel()
            if globalData.deluexeClubData:getDeluexeClubStatus() == true then
                if self.m_info.p_highBetFlag then
                    gLobalSendDataManager:getLogSlots():setEnterLevelSiteType("HightArea")
                else
                    gLobalSendDataManager:getLogSlots():setEnterLevelSiteType("RegularArea")
                end
            else
                gLobalSendDataManager:getLogSlots():setEnterLevelSiteType("RegularArea")
            end
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_theme)
            end
            self:checkGotoLevel()
        end,
        4 -- csc 2021-11-18 16:39:03 新手期5.0 需要再延长2s进入游戏
    )
end

-- 是否显示 关卡 玩法 顶部居中的 角标
function LevelSmallNode:isTopMiddleWanfa()
    local playTypeInfo  = self.m_info.p_playTypeInfo
    if not playTypeInfo or #playTypeInfo < 2 then
        return false
    end 
    local site = playTypeInfo[2]
    return site == "0"
end

function LevelSmallNode:isCommonJackpot()
    -- 判断是否要添加公共jackpot的节点
    if not G_GetMgr(ACTIVITY_REF.CommonJackpot):isRecmdJackpotLevel(self.m_info.p_name) then
        return false
    end

    -- 判断活动时间
    local data = G_GetMgr(ACTIVITY_REF.CommonJackpot):getRunningData()
    if not (data and data:getLeftTime() > 0) then
        return false
    end

    -- 判断资源下载
    if not G_GetMgr(ACTIVITY_REF.CommonJackpot):isDownloadRes() then
        return false
    end

    if not globalDynamicDLControl:checkDownloaded("LevelFloderThemes") then
        return false
    end    

    return true
end

function LevelSmallNode:isFlamingoJackpot()
    local data = G_GetMgr(ACTIVITY_REF.FlamingoJackpot):getRunningData()
    if not data then
        return false
    end
    -- 判断关卡
    if not data:checkLevelByLevelId(self.m_info.p_id) then
        return false
    end
    -- 判断关卡分类的资源是否下载
    -- 判断资源下载
    if not G_GetMgr(ACTIVITY_REF.FlamingoJackpot):isDownloadRes() then
        return false
    end

    if not globalDynamicDLControl:checkDownloaded("LevelFloderThemes") then
        return false
    end

    return true   
end

function LevelSmallNode:isDiyFeature()
    local data = G_GetMgr(ACTIVITY_REF.DiyFeature):getRunningData()
    if not data then
        return false
    end
    -- 判断关卡
    if not self.m_info.p_diyFeatureGame then
        return false
    end
    -- 判断关卡分类的资源是否下载
    -- 判断资源下载
    if not G_GetMgr(ACTIVITY_REF.DiyFeature):isDownloadRes() then
        return false
    end

    if not globalDynamicDLControl:checkDownloaded("LevelFloderThemes") then
        return false
    end

    return true   
end

--[[--
    关卡入口上的帽子标签，会覆盖整个顶部，像个帽子一样大
    逻辑上只显示一个标题
    DIY FEATURE/FLAMINGO JACKPOT/ COMMON JACKPOT/MINZ＞关卡玩法标签 ＞其他标签
]]
function LevelSmallNode:initCommonJackpot()
    self.m_nodeMinz:setVisible(false)
    self.m_node_commonJackpot:setVisible(false)
    self.m_node_commonJackpot:removeAllChildren()

    local cjTitleNode = self.m_node_commonJackpot:getChildByName("CommonJackpot")
    if cjTitleNode then
        cjTitleNode:stopHandle()
    end
    local fjTitleNode = self.m_node_commonJackpot:getChildByName("FlamingoJackpot")
    if fjTitleNode then
        fjTitleNode:stopHandle()
    end
        
    if self:isDiyFeature() then
        if not fjTitleNode then
            fjTitleNode = util_createView("views.lobby.LevelSmallCommonDiyFeatureNode")
            fjTitleNode:setName("DiyFeatureNode")
            self.m_node_commonJackpot:addChild(fjTitleNode)
        end
        self.m_node_commonJackpot:setVisible(true)
    elseif self:isFlamingoJackpot() then
        if not fjTitleNode then
            fjTitleNode = util_createView("views.lobby.LevelSmallFlamingoJackpotNode")
            fjTitleNode:setName("FlamingoJackpot")
            self.m_node_commonJackpot:addChild(fjTitleNode)
        end
        if fjTitleNode then
            fjTitleNode:startHandle()
        end
        self.m_node_commonJackpot:setVisible(true)
    elseif self:isCommonJackpot() then
        if not cjTitleNode then
            cjTitleNode = util_createView("views.lobby.LevelSmallCommonJackpotNode")
            cjTitleNode:setName("CommonJackpot")
            self.m_node_commonJackpot:addChild(cjTitleNode)
        end
        if cjTitleNode then
            cjTitleNode:startHandle()
        end
        self.m_node_commonJackpot:setVisible(true)
    elseif self.m_nodeMinz and self.m_info.p_minzGame then
        -- minz
        self.m_nodeMinz:setVisible(true)
    elseif self:isTopMiddleWanfa() then
        -- 关卡玩法
        local playTypeInfo  = self.m_info.p_playTypeInfo
        local icon = util_createSprite(string.format("newIcons/wanfa/%s.png", playTypeInfo[1]))
        if icon then
            self.m_node_commonJackpot:addChild(icon)
            self.m_node_commonJackpot:setVisible(true)
        end
    end
end

-- minz资源路径
function LevelSmallNode:getMinzCsbName()
    return "newIcons/Level_kongjian/Level_minz.csb"
end

function LevelSmallNode:initMinz()
    local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    if not minzMgr then
        return
    end
    local data = minzMgr:getRunningData()
    if not data then
        return
    end
    if not self.m_nodeMinz then
        return
    end
    self.m_nodeMinz:setVisible(false)
    local minzCsb = self:getMinzCsbName()
    if not minzCsb or minzCsb == "" then
        return
    end

    local minzNode = self.m_nodeMinz:getChildByName("MinzTag")
    if not minzNode then
        printInfo("---initCsb = " .. minzCsb)
        minzNode = util_createView("views.lobby.Level_link", minzCsb)
        self.m_nodeMinz:addChild(minzNode)
        minzNode:setName("MinzTag")
    end
end

function LevelSmallNode:isOpenDyLoadVer()
    if device.platform == "ios" then
        if util_isSupportVersion("1.7.2") then
            return true
        end
    elseif device.platform == "android" then
        if util_isSupportVersion("1.6.4") then
            return true
        end
    else
        if util_isSupportVersion("1.7.1") then
            return true
        end
    end

    return false
end

-- 关卡 右上角 玩法图标
function LevelSmallNode:initTopRightWanfa()
    self.m_node_specialFeature:setVisible(false)
    
    local playTypeInfo  = self.m_info.p_playTypeInfo
    if not playTypeInfo or #playTypeInfo < 2 then
        return false
    end 
    local site = playTypeInfo[2]
    if site ~= "1" then
        return false
    end

    local icon = self.m_node_specialFeature:getChildByName("node_wanfaIcon")
    local iconPath = string.format("newIcons/wanfa/%s.png", playTypeInfo[1])
    if not icon then
        icon = cc.Sprite:create()
        icon:setName("node_wanfaIcon")
        self.m_node_specialFeature:addChild(icon)
    end
    local bSuccess = util_changeTexture(icon, iconPath)
    self.m_node_specialFeature:setVisible(bSuccess)
end

return LevelSmallNode
