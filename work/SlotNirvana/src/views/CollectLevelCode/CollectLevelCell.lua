local LevelBaseNode = util_require("views.lobby.LevelBaseNode")
local CollectLevelCell = class("CollectLevelCell", util_require("base.BaseView"))

CollectLevelCell.m_commingSoonSp = nil
CollectLevelCell.STATUS_NONE = 0 --未初始化
CollectLevelCell.STATUS_UNLOCK = 1 --未解锁
CollectLevelCell.STATUS_NOTDL = 2 --未下载
CollectLevelCell.STATUS_DOING = 3 ---下载中
CollectLevelCell.STATUS_DONE = 4 --已下载
CollectLevelCell.STATUS_COMMINGSOON = 5 --敬请期待
CollectLevelCell.STATUS_NEXTVERSION = 6 --下个版本可用
CollectLevelCell.STATUS_MAINTENANCE = 7 --维护中

function CollectLevelCell:ctor()
    CollectLevelCell.super.ctor(self)
    self:clearData()
end

function CollectLevelCell:clearData()
    self.m_isExist = false
    self.m_spinepath = ""
    self.m_spineTexture = ""
    self.m_curSpineAni = ""
    self.m_levelIconPath = ""
end

--子类重新创建的csb节点
function CollectLevelCell:getCsbName()
    self.m_nodeType = self.NODE_TYPE_SMALL

    return "newIcons/LevelSmallNode.csb"
end

function CollectLevelCell:initCsbNodes()
    self.m_node_content = self:findChild("node_content")
    self.m_node_load = self:findChild("node_load")
    self.m_node_jackpot = self:findChild("node_jackpot")
    self.m_bonusHunt = self:findChild("node_bonusHunt")
    self.m_luckyChallenge = self:findChild("node_luckyChallenge")
    self.m_node_tag = self:findChild("node_tag")
    self.m_node_ace = self:findChild("node_ace")
    self.m_node_dl = self:findChild("node_xiazai")
    self.m_touch = self:findChild("touch")
    self:addClick(self.m_touch)
    self.m_touch:setSwallowTouches(false)
    self.m_contents = self:findChild("sp_icon")
    self.m_nodeAvararFrame = self:findChild("node_frame")
    self.m_node_specialFeature = self:findChild("node_wanfa")
    self.m_node_specialFeature:setVisible(false)
    self.m_node_commonJackpot = self:findChild("node_commonJackpot")
    self.m_nodeMinz = self:findChild("node_minz")
    self:initUnlock()
    self:initLink()
end

function CollectLevelCell:initView()
    CollectLevelCell.super.initView(self)
end

function CollectLevelCell:updateInfo(info,_type)
    self.m_status = self.STATUS_NONE
    self.m_type = _type
    self:parseInfo(info)
    self:updateView()
end

--初始化配置
function CollectLevelCell:parseInfo(info)
    self.m_info = info
    self.m_csbName = info.p_csbName
    self.m_levelName = info.p_levelName
    self.m_levelId = info.p_id
    self.m_openLevel = info.p_openLevel
    self.m_md5 = info.p_md5
    self.m_freeOpen = info.p_freeOpen
    self.m_fastLevel = info.p_fastLevel
    self.m_maintain = info.p_maintain -- 维护中
    self.m_version = info.p_levelVersion

    -- self.m_isBonushuntLevel = self:isBonushuntLevel()
    -- if self.m_isBonushuntLevel then
    --     self.m_openLevel = 1
    -- end

    -- self.m_isOpenLuckyChallenge = self:isOpenLuckyChallenge()
    -- if self.m_isOpenLuckyChallenge then
    --     self.m_openLevel = 1
    -- end

    self.m_isOpenLv = self:isOpenLevel()
    self:regristDownloadEvent()
end

function CollectLevelCell:updateUnlockLv()
    if self.m_lockNode and not self.m_isOpenLv then
        local m_lb_level = self.m_lockNode:findChild("m_lb_level")
        if m_lb_level then
            m_lb_level:setString("LEVEL  " .. self.m_openLevel)
        end
    end
end

function CollectLevelCell:updateView()
    -- local curTime = socket.gettime()
    --如果存在资源下载不创建图片
    -- self:initContent()
    if self.m_isDownloadImg then
        -- local isInApp = LevelIconInApp[self.m_levelName]
        local isInApp = true -- 入口图移动到res整包中
        if isInApp then
            self:initNoSpinLogo()
        end
    end
    if self.m_luckyChallenge then
        if self:isOpenLuckyChallenge() then
            self:initChallengeTag()
            self.m_luckyChallenge:setVisible(true)
        else
            self.m_luckyChallenge:setVisible(false)
        end  
    end

    self:updateUnlockLv()
    self:initJackpot()
    -- self:initBonusHuntNode()
    -- self:initOtherUI()
    self:updateTag()
    self:updateUI()
    -- self:initMaintain()
    if self.m_type == 2 then
        self:initAvatarFrameTagUI()
    end
end

function CollectLevelCell:initChallengeTag()
    if self.m_luckyChallenge then
        local view = self.m_luckyChallenge:getChildByName("LuckyChallenge")
        if not view then
            view = util_createAnimation("newIcons/Level_kongjian/Level_luckyChallenge.csb")
            view:setName("LuckyChallenge")
            self.m_luckyChallenge:addChild(view)
        end
    end
end

function CollectLevelCell:initLink()
    -- 新手集卡期间不显示 link卡tag
    local bCardNovice = CardSysManager:isNovice()
    if bCardNovice then
        return
    end
    
    local linkCsb = self:getLinkCsbName()
    if not linkCsb or linkCsb == "" then
        return
    end

    local linkNode = self.m_node_ace:getChildByName("LinkTag")
    if not linkNode then
        printInfo("---initCsb = " .. linkCsb)
        linkNode = util_createView("views.lobby.Level_link", linkCsb)
        self.m_node_ace:addChild(linkNode)
        linkNode:setName("LinkTag")
    end
end

-- 子类可重写
function CollectLevelCell:getLinkCsbName()
    return "newIcons/Level_kongjian/Level_link.csb"
end

function CollectLevelCell:initUnlock()
    --锁
    self.m_lockNode = util_createAnimation("newIcons/Level_kongjian/Level_suo_small.csb")
    self:addChild(self.m_lockNode, 1)
    self.m_lockNode:playAction("suo2")
end

function CollectLevelCell:isOpenLuckyChallenge()
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData and #G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getCurLevelTask(self.m_info.p_id,true) > 0 then
        return true
    end
    return false
end

function CollectLevelCell:isOpenLevel()
    local isUnlock = false
    -- 判断是否在解锁等级的关卡分类中
    -- local LevelRecmdData = require("views.lobby.LevelRecmd.LevelRecmdData")
    if LevelRecmdData then
        isUnlock = isUnlock or LevelRecmdData:getInstance():isLevelUnlock(self.m_info.p_name)
    end

    -- AllGamesUnlockedData 活动判断
    isUnlock = isUnlock or G_GetMgr(ACTIVITY_REF.AllGamesUnlocked):isRunning()

    local curLevel = globalData.userRunData.levelNum
    isUnlock = isUnlock or (curLevel >= self.m_openLevel)

    return isUnlock
end

--刷新标签
function CollectLevelCell:updateTag()
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

    if not hasLink then
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

        if self.m_luckyChallenge then
            if self.m_isOpenLuckyChallenge then
                self.m_luckyChallenge:setVisible(true)
            end
        end
    end
end

--下个版本可用
function CollectLevelCell:updateNextVersion()
    self.m_status = self.STATUS_NEXTVERSION
    self.m_node_dl:setVisible(false)
end

--维护中
function CollectLevelCell:updateMaintenance()
    self.m_status = self.STATUS_MAINTENANCE
    self:hideNode(self.m_node_dl)
    self:hideNode(self.m_node_jackpot)
    self:hideNode(self.m_node_tag)
    self:hideNode(self.m_node_ace)
    self:hideNode(self.m_bonusHunt)
    self:hidelock()
end

function CollectLevelCell:hideNode(node)
    if node and node.setVisible then
        node:setVisible(false)
    end
end

--刷新敬请期待
function CollectLevelCell:updateCommingSoon()
    if self.m_levelName == "CommingSoon" then
        self.m_status = self.STATUS_COMMINGSOON
        self.m_node_load:setVisible(false)
        self.m_node_dl:setVisible(false)
        return true
    end
    return false
end

--刷新未解锁状态
function CollectLevelCell:updateUnLock()
    self.m_status = self.STATUS_UNLOCK
    self.m_node_load:setVisible(false)
    self.m_node_dl:setVisible(false)
    self:showlock()
end
--刷新未下载状态
function CollectLevelCell:updateNotDL()
    self.m_status = self.STATUS_NOTDL
    self.m_node_load:setVisible(false)
    self.m_node_dl:setVisible(true)
    self:clearBlackLayer()
    self:hidelock()
end
--刷新下载完成状态
function CollectLevelCell:updateDoneDl()
    if not self.m_isOpenLv then
        self:updateUnLock()
        self:clearBlackLayer()
        return
    end
    self.m_status = self.STATUS_DONE
    self.m_node_load:setVisible(false)
    self.m_node_dl:setVisible(false)
    self:clearBlackLayer()
    self:hidelock()
end

function CollectLevelCell:creatContentFnt()
    local label = ccui.TextBMFont:create()
    label:setFntFile("Common/font_update.fnt")
    label:setName("txt_progress")
    return label
end

--增加黑色遮罩
function CollectLevelCell:addBlackLayer()
    self.m_contents:setColor(cc.c3b(100, 100, 100))
end

--移除遮罩
function CollectLevelCell:clearBlackLayer()
    self.m_contents:setColor(cc.c3b(255, 255, 255))
end

--刷新UI
function CollectLevelCell:updateUI()
    --敬请期待
    if self:updateCommingSoon() then
        return
    end

    --维护中
    if self.m_maintain then
        self:updateMaintenance()
        return
    end
    --当前版本不支持
    if not self:isOpenVersion() then
        self:updateNextVersion()
        return
    end
    --未解锁
    if not self.m_isOpenLv then
        self:updateUnLock()
    else
        --已解锁判断是否需要下载和更新
        -- local percent = gLobaLevelDLControl:getLevelPercent(self.m_levelName)
        -- if self.m_fastLevel then
        --     self:updateDoneDl()
        -- elseif percent then
        --     self:updatePercent(percent)
        -- elseif gLobaLevelDLControl:isDownLoadLevel(self.m_info) == 2 then --??? 判断条件不了解
        --     self:updateDoneDl()
        -- elseif self.m_freeOpen and gLobaLevelDLControl:isUpdateFreeOpenLevel(self.m_levelName, self.m_md5) == false then
        --     self:updateDoneDl()
        -- else
        --     self:updateNotDL()
        -- end
        self:updateDoneDl()
    end
end

function CollectLevelCell:isOpenVersion()
    if self.m_version then
        self.m_version = tonumber(self.m_version)
        local fieldValue = util_getUpdateVersionCode(false)
        local curVersion = tonumber(fieldValue)
        if curVersion < self.m_version then
            return false
        end
    end
    return true
end

function CollectLevelCell:regristDownloadEvent()
    if device.platform == "mac" then
        self.m_isDownloadImg = false
        self:initSpineFileInfo(self.m_levelName)
    else
        if self.m_notifyName then
            gLobalNoticManager:removeObserver(self, self.m_notifyName)
            self.m_notifyName = nil
        end

        local notifyName = util_getFileName(self.m_info.p_csbName)
        self.m_isDownloadImg = globalDynamicDLControl:checkDownloading(notifyName)
        if self.m_isDownloadImg then
            --注册下载通知
            gLobalNoticManager:addObserver(
                self,
                function(self, params)
                    self.m_isDownloadImg = false
                    -- self:initContent()
                    -- 刷新Spine信息
                    -- globalData.slotRunData:updateLobbyEntryInfo(self.m_levelName)
                    self:initSpineFileInfo(self.m_levelName)
                    self:updateLevelLogo()
                    -- self:updateProgress()
                end,
                notifyName
            )

            self.m_notifyName = notifyName
        end
        self:initSpineFileInfo(self.m_levelName)
        -- self:updateLevelLogo()
    end
end

function CollectLevelCell:updateLevelVisible(isVisible)
    self:setVisible(isVisible)

    self:updateLevelLogo(isVisible)
end

function CollectLevelCell:initSpineFileInfo(levelName)
    -- self.m_isExist, self.m_spinepath, self.m_spineTexture = self:getSpinFileInfo(levelName, "small")
    self.m_isExist, self.m_spinepath, self.m_spineTexture = globalData.slotRunData:getLobbySpinInfo(levelName, "small")
end

--维护中
function CollectLevelCell:updateMaintenance()
    CollectLevelCell.super.updateMaintenance(self)
    self:hideNode(self.m_node_specialFeature)
    self:hideNode(self.m_node_commonJackpot)
    self:hideNode(self.m_nodeMinz)
end

--初始化图标子类重写
-- function CollectLevelCell:initContent()
-- end

function CollectLevelCell:updateCommingSoonLvIcon()
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
function CollectLevelCell:initNoSpinLogo()
    local path = nil
    if self.m_levelName == "CommingSoon" then
        return
    end
    local _bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    if _bOpenDeluxe then
        path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.DELUXE)
    else
        path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.SMALL)
    end
    util_changeTexture(self.m_contents, path)
    self.m_levelIconPath = path
end

-- 更新关卡Logo
function CollectLevelCell:updateLevelLogo()
    if self.m_levelName and self.m_levelName ~= "CommingSoon" then
        local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
        self:updateDeluxeLevels(bOpenDeluxe)
    end
end

-- 获得Spine资源名称
function CollectLevelCell:getSpineFileName(levelName, prefixName)
    prefixName = prefixName or ""
    local fileName = prefixName .. "_level_spine_" .. levelName
    if globalData.GameConfig:checkLevelGroupA(levelName) then
        -- 是AB Test的 A 组
        fileName = fileName .. "_abtest"
    end
    return fileName
end

function CollectLevelCell:removeSpinAnimNode()
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

-- 获得关卡入口spine动画
function CollectLevelCell:getSpineLogo()
    return self.m_contents:getChildByName("SpineLogo")
end

-- logoSpine动画
function CollectLevelCell:addSpineAnimNode(noSpinCallback)
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
            if bOpenDeluxe then
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
function CollectLevelCell:updateDeluxeLevels(_bOpenDeluxe)
    if not self.m_levelName or self.m_levelName == "CommingSoon" then
        return
    end

    self.m_isOpenDeluxe = _bOpenDeluxe

    local noSpineFunc = function()
        local path = nil
        if _bOpenDeluxe then
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
function CollectLevelCell:initOtherUI()
end

--解锁相关逻辑子类重写
function CollectLevelCell:initUnlock()
    --锁
    self.m_lockNode = util_createAnimation("newIcons/Level_kongjian/Level_suo_small.csb")
    self:addChild(self.m_lockNode, 1)
    self.m_lockNode:playAction("suo2")
end
--检测是否解锁
function CollectLevelCell:playClickUnLockAction()
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
function CollectLevelCell:showlock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(true)
    end
end
--隐藏锁
function CollectLevelCell:hidelock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(false)
    end
end

function CollectLevelCell:checkUnLockAction()
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
function CollectLevelCell:initJackpot()
    self:initTopRightWanfa()
end

-- 头像框标识
function CollectLevelCell:initAvatarFrameTagUI()
    if self.m_nodeAvararFrame then
        local view = self.m_nodeAvararFrame:getChildByName("Level_frame")
        if not view then
            view = util_createAnimation("newIcons/Level_kongjian/Level_frame.csb")
            view:setName("Level_frame")
            self.m_nodeAvararFrame:addChild(view)
        end

        local bOpen = G_GetMgr(G_REF.AvatarFrame):checkCurSlotOpen(self.m_info.p_id)
        if not bOpen then
            self.m_nodeAvararFrame:setVisible(false)
            view:playAction("idle", false)
        else
            self.m_nodeAvararFrame:setVisible(true)
            view:playAction("idle", true)
        end
    end
    if self.m_node_specialFeature:isVisible() then
        self.m_nodeAvararFrame:setVisible(false)
    end
end

function CollectLevelCell:clickFunc(sender)
   self:checkGotoLevel()
end

--点击关卡图标跳转相关逻辑
function CollectLevelCell:checkGotoLevel()
    if not self.m_info then
        return
    end

    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
    if self.m_status == self.STATUS_UNLOCK then
        self:playClickUnLockAction()
        return
    end

    if globalData.GameConfig:checkChooseBetOpen() then
        self:enterChooseLevelUI()
    else
        self:enterLevel()
    end
end
-- 进入关卡选择页面 (选择普通场 还是 高倍场)
function CollectLevelCell:enterChooseLevelUI(_bIgnoreNodeType)
    local bHideArrowBtn = false
    if not _bIgnoreNodeType and self.m_nodeType == self.NODE_TYPE_BIG then
        bHideArrowBtn = true
    end
    local view = util_createView("views.ChooseLevel.ChooseLevelLayer", self.m_levelId, bHideArrowBtn)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

--进入关卡
function CollectLevelCell:enterLevel()
    gLobalViewManager:lobbyGotoGameScene(self.m_info.p_id)
end

function CollectLevelCell:getTagCsbName()
    return "newIcons/Level_kongjian/Level_tag_small.csb"
end

function CollectLevelCell:changeBonusHuntIcon(view)
    if view ~= nil then
        local bonusHuntIcon = view
        util_changeTexture(bonusHuntIcon, "newIcons/Other/wanfa_bonshuntSmall.png")
    end
end

--添加buff子类重写
function CollectLevelCell:updateBuffCoins(buffCoin, levelId)
    if levelId == self.m_info.p_id and not self:getChildByName("GAMECRAZE_BUFF") then
        buffCoin:setName("GAMECRAZE_BUFF")
        local size = self.m_contents:getContentSize()
        -- local pos = cc.p(-size.width/2, -size.height / 4)
        local pos = self:getHuntPos()
        buffCoin:setPosition(pos)
        self:addChild(buffCoin)
    end
end

function CollectLevelCell:openScheduleEnter()
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
function CollectLevelCell:isTopMiddleWanfa()
    local playTypeInfo  = self.m_info.p_playTypeInfo
    if not playTypeInfo or #playTypeInfo < 2 then
        return false
    end 
    local site = playTypeInfo[2]
    return site == "0"
end

function CollectLevelCell:isCommonJackpot()
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

function CollectLevelCell:isFlamingoJackpot()
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

function CollectLevelCell:isDiyFeature()
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
function CollectLevelCell:initCommonJackpot()
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
function CollectLevelCell:getMinzCsbName()
    return "newIcons/Level_kongjian/Level_minz.csb"
end

function CollectLevelCell:initMinz()
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

function CollectLevelCell:isOpenDyLoadVer()
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
function CollectLevelCell:initTopRightWanfa()
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

return CollectLevelCell
