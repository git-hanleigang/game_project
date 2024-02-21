--
--大厅关卡节点
--
local LevelBaseNode = util_require("views.lobby.LevelBaseNode")
local LevelLongNode = class("LevelLongNode", LevelBaseNode)

--子类重新创建的csb节点
function LevelLongNode:getCsbName()
    self.m_nodeType = self.NODE_TYPE_Long
    return "newIcons/LevelLongNode.csb"
end

function LevelLongNode:initCsbNodes()
    LevelLongNode.super.initCsbNodes(self)
    self.m_node_specialFeature = self:findChild("node_wanfa")
    self.m_node_specialFeature:setVisible(false)
end

function LevelLongNode:initSpineFileInfo(levelName)
    self.m_isExist, self.m_spinepath, self.m_spineTexture = globalData.slotRunData:getLobbySpinInfo(levelName, "long")
end

--维护中
function LevelLongNode:updateMaintenance()
    LevelLongNode.super.updateMaintenance(self)
    self:hideNode(self.m_node_specialFeature)
end

-- 初始化非Spin资源logo
function LevelLongNode:initNoSpinLogo()
    local path = nil
    if self.m_levelName == "CommingSoon" then
        return
    end
    local _bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    if _bOpenDeluxe and (not self.m_isSlotMode) then
        path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.LONG_DELUXE)
    else
        path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.LONG)
    end
    util_changeTexture(self.m_contents, path)
    self.m_levelIconPath = path
end

-- 更新关卡Logo
function LevelLongNode:updateLevelLogo()
    if not LevelLongNode.super.updateLevelLogo(self) then
        return
    end
    -- printInfo("updateLevelLogo ---- " .. self.m_levelName)
    if self.m_levelName and self.m_levelName ~= "CommingSoon" then
        local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
        self:updateDeluxeLevels(bOpenDeluxe)
    end
end

-- 获得Spine资源名称
function LevelLongNode:getSpineFileName(levelName, prefixName)
    prefixName = prefixName or ""
    local fileName = prefixName .. "_level_spine_" .. levelName
    if globalData.GameConfig:checkLevelGroupA(levelName) then
        -- 是AB Test的 A 组
        fileName = fileName .. "_abtest"
    end
    return fileName
end

function LevelLongNode:removeSpinAnimNode()
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
        self:clearData()
    end
end

-- logoSpine动画
function LevelLongNode:addSpineAnimNode(noSpinCallback)
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
                            util_changeTexture(self.m_contents, "newIcons/Order/cashlink_loading.png")
                            local spineNode = self:getSpineLogo()
                            if not spineNode and _isFind then
                                spineNode = util_spineCreate(spinepath, true, true, 2)
                                spineNode:setName("SpineLogo")
                                local size = self.m_contents:getContentSize()
                                self.m_contents:addChild(spineNode)
                                spineNode:setPositionX(size.width / 2)
                                spineNode:setPositionY(size.height / 2)
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
function LevelLongNode:updateDeluxeLevels(_bOpenDeluxe)
    if not self.m_levelName or self.m_levelName == "CommingSoon" then
        return
    end

    self.m_isOpenDeluxe = _bOpenDeluxe

    local noSpineFunc = function()
        local path = nil
        if _bOpenDeluxe and (not self.m_isSlotMode) then
            path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.LONG_DELUXE)
        else
            path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.LONG)
        end

        local _callback = function(textureInfo)
            if not tolua.isnull(self) then
                if textureInfo then
                    util_changeTexture(self.m_contents, path)
                    self.m_levelIconPath = path
                    self.m_isShowedLogo = true
                else
                    util_changeTexture(self.m_contents, "newIcons/Order/cashlink_loading.png")
                end
            end
        end
        display.loadImage(path, _callback)
    end
    self:addSpineAnimNode(noSpineFunc)
end

--jackpot
function LevelLongNode:initJackpot()
    LevelLongNode.super.initJackpot(self)
    -- self:initTopRightWanfa()
end

-- 关卡 右上角 玩法图标
function LevelLongNode:initTopRightWanfa()
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

function LevelLongNode:updateTag()
    --先隐藏
    if self.m_node_ace then
        self.m_node_ace:setVisible(false)
    end
    if self.m_node_tag then
        self.m_node_tag:setVisible(false)
    end
    if self.m_bonusHunt then
        self.m_bonusHunt:setVisible(false)
    end
    if self.m_luckyChallenge then
        self.m_luckyChallenge:setVisible(false)
    end
    if self.m_info.p_Log ~= "new" then
        return
    end
    -- link
    local hasLink = false
    -- local linkNode = self.m_node_ace:getChildByName("LinkTag")
    if self.m_node_ace and CardSysManager:canEnterCardCollectionSys() then
        if self.m_info.p_link then
            hasLink = true
            self.m_node_ace:setVisible(true)
        else
            local otherShowLink = false
            self.m_node_ace:setVisible(otherShowLink)
        end
    else
        self.m_node_ace:setVisible(false)
    end

    -- new hot feature
    local tagNode = self.m_node_tag:getChildByName("LevelTag")
    if tagNode and self.m_info.p_Log then
        self.m_node_tag:setVisible(true)
        if self.m_info.p_Log == "new" then
            tagNode:playIdleAction("idle_new")
        elseif self.m_info.p_Log == "hot" then
            tagNode:playIdleAction("idle_hot")
        elseif self.m_info.p_Log == "feature" then
            self.m_node_tag:setVisible(false)
        end
    end

    local linkNode = self.m_node_ace:getChildByName("LinkTag")
    if not tolua.isnull(linkNode) then
        if self.m_node_tag:isVisible() and hasLink then
            linkNode:setPosition(cc.p(0, -75))
        else
            linkNode:setPosition(cc.p(0, 0))
        end
    end
end

function LevelLongNode:isOpenLuckyChallenge()
    return false
end

--解锁相关逻辑子类重写
function LevelLongNode:initUnlock()
    --锁
    self.m_lockNode = util_createAnimation("newIcons/Level_kongjian/Level_suo_big.csb")
    self:addChild(self.m_lockNode, 1)
    self.m_lockNode:playAction("suo2")
end

--检测是否解锁
function LevelLongNode:playClickUnLockAction()
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
function LevelLongNode:showlock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(true)
    end
end

--隐藏锁
function LevelLongNode:hidelock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(false)
    end
end

function LevelLongNode:checkUnLockAction()
    if self.m_isPlayUnLock then
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

function LevelLongNode:clickFunc(sender)
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
    LevelLongNode.super.clickFunc(self, sender)
end

function LevelLongNode:checkGotoLevel()
    --下载入口记录
    if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL and self.m_info then
        gLobalSendDataManager:getLogGameLevelDL():setDownloadInfo(self.m_info.p_levelName, {type = "normal", siteType = "RegularArea"})
    end
    LevelLongNode.super.checkGotoLevel(self)
end

function LevelLongNode:getTagCsbName()
    return "newIcons/Level_kongjian/Level_tag_small.csb"
end

function LevelLongNode:updateCommingSoon()
    local isCommingSoon = LevelLongNode.super.updateCommingSoon(self)
    self:hidelock()
    return isCommingSoon
end

function LevelLongNode:isOpenDyLoadVer()
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

-- 是否显示 关卡 玩法 顶部居中的 角标
function LevelLongNode:isTopMiddleWanfa()
    local playTypeInfo  = self.m_info.p_playTypeInfo
    if not playTypeInfo or #playTypeInfo < 2 then
        return false
    end 
    local site = playTypeInfo[2]
    return site == "0"
end

return LevelLongNode