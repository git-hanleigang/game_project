--
--大厅关卡节点
--
local GameCrazeControl = util_getRequireFile("Activity/GameCrazeControl")
local LevelRecmdData = require("views.lobby.LevelRecmd.LevelRecmdData")
local LevelBaseNode = class("LevelBaseNode", util_require("base.BaseView"))
LevelBaseNode.STATUS_NONE = 0 --未初始化
LevelBaseNode.STATUS_UNLOCK = 1 --未解锁
LevelBaseNode.STATUS_NOTDL = 2 --未下载
LevelBaseNode.STATUS_DOING = 3 ---下载中
LevelBaseNode.STATUS_DONE = 4 --已下载
LevelBaseNode.STATUS_COMMINGSOON = 5 --敬请期待
LevelBaseNode.STATUS_NEXTVERSION = 6 --下个版本可用
LevelBaseNode.STATUS_MAINTENANCE = 7 --维护中
--配置
LevelBaseNode.m_info = nil --关卡配置
LevelBaseNode.m_csbName = nil --动画名称
LevelBaseNode.m_levelName = nil --关卡名称
LevelBaseNode.m_levelId = nil -- 关卡id
LevelBaseNode.m_openLevel = nil --开启等级
LevelBaseNode.m_md5 = nil --md5
LevelBaseNode.m_freeOpen = nil --是否是包内关卡
LevelBaseNode.m_maintain = nil -- 维护中
LevelBaseNode.m_version = nil --开启的版本
--动态获取
LevelBaseNode.m_contentLenX = nil --关卡宽度
LevelBaseNode.m_percent = nil --下载百分比
LevelBaseNode.m_status = nil --状态
--ui
LevelBaseNode.m_node_content = nil --基础容器
LevelBaseNode.m_node_load = nil --下载容器
LevelBaseNode.m_node_jackpot = nil --jackpot容器
LevelBaseNode.m_node_tag = nil --new hot feature标签容器
LevelBaseNode.m_node_ace = nil --ace highlimitb标签容器
LevelBaseNode.m_node_dl = nil --下载
LevelBaseNode.m_touch = nil --点击区域
LevelBaseNode.m_contents = nil --图标
LevelBaseNode.m_loadingProgress = nil --下载进度
LevelBaseNode.m_loadingProgressTxt = nil --下载进度文字

LevelBaseNode.NODE_TYPE_BIG = 1
LevelBaseNode.NODE_TYPE_SMALL = 2
LevelBaseNode.NODE_TYPE_Long = 3
LevelBaseNode.m_nodeType = nil

-- 在整包内的关卡图标
local LevelIconInApp = {
    GameScreenClassicRapid2 = true,
    GameScreenCharms = true,
    GameScreenMrCash = true,
    GameScreenMermaid = true,
    GameScreenFivePande = true,
    GameScreenWickedBlaze = true,
    GameScreenBeerGirl = true,
    GameScreenClassicCash = true,
    GameScreenReelRocks = true,
    GameScreenAliceRuby = true,
    GameScreenJungleKingpin = true,
    GameScreenKangaroos = true,
    GameScreenLightCherry = true,
    GameScreenLottoParty = true,
    GameScreenCloverHat = true,
    GameScreenWinningFish = true,
    GameScreenEaster = true,
    GameScreenGoldenMammoth = true,
    GameScreenCrazyBomb = true
}

function LevelBaseNode:ctor()
    LevelBaseNode.super.ctor(self)

    self.m_isShowedLogo = false
    self.m_isOpenDeluxe = false
    -- 关卡位置类型
    self.m_siteType = nil
    self.m_siteName = "Lobby"

    self.m_isDownloadImg = false --是否有资源需要下载
end

function LevelBaseNode:setSiteType(siteType)
    self.m_siteType = siteType
end

function LevelBaseNode:getSiteType()
    return self.m_siteType
end

function LevelBaseNode:setSiteName(siteName)
    self.m_siteName = siteName
end

function LevelBaseNode:getSiteName()
    return self.m_siteName
end

function LevelBaseNode:initUI(info)
    self.m_status = self.STATUS_NONE
    self.m_contentLenX = 120
    -- setDefaultTextureType("RGBA8888", nil)
    self:createCsbNode(self:getCsbName())
    self:initView()
end

function LevelBaseNode:updateInfo(info)
    -- local _times = socket.gettime()
    self:parseInfo(info)
    -- printInfo(string.format("--levelnode-- updateInfo1 = %3f", socket.gettime() - _times))
    -- _times = socket.gettime()
    self:updateView()
    -- printInfo(string.format("--levelnode-- updateInfo2 = %3f", socket.gettime() - _times))
    -- setDefaultTextureType("RGBA4444", nil)
end

--子类重新创建的csb节点
function LevelBaseNode:getCsbName()
    return "newIcons/LevelBaseNode.csb"
end

--子类重写
function LevelBaseNode:initOtherUI()
end

--解锁相关逻辑子类重写
function LevelBaseNode:initUnlock()
end

function LevelBaseNode:updateUnlockLv()
    if self.m_lockNode and not self.m_isOpenLv then
        local m_lb_level = self.m_lockNode:findChild("m_lb_level")
        if m_lb_level then
            m_lb_level:setString("LEVEL  " .. self.m_openLevel)
        end
    end
end

--检测是否解锁
function LevelBaseNode:playClickUnLockAction()
end
--设置锁
function LevelBaseNode:showlock()
end
--隐藏锁
function LevelBaseNode:hidelock()
end

--初始化配置
function LevelBaseNode:parseInfo(info)
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
    self.m_isSlotMode = info:isSlotMod()

    self.m_isBonushuntLevel = self:isBonushuntLevel()
    if self.m_isBonushuntLevel then
        self.m_openLevel = 1
    end

    self.m_isOpenLuckyChallenge = self:isOpenLuckyChallenge()
    if self.m_isOpenLuckyChallenge then
        self.m_openLevel = 1
    end

    self.m_isOpenLv = self:isOpenLevel()

    --GameCraze buff
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         if params and not tolua.isnull(self) then
    --             self:updateBuffCoins(params[1], params[2])
    --         end
    --     end,
    --     ViewEventType.GAMECRAZE_UPDATE_BUFFCOINS
    -- )

    self:regristDownloadEvent()
end

function LevelBaseNode:regristDownloadEvent()
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

function LevelBaseNode:initCsbNodes()
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
end

function LevelBaseNode:initView()
    self:initUnlock()
    self:initChallengeTag()
    self:initTag()
    self:initLink()
end

function LevelBaseNode:updateView()
    -- local curTime = socket.gettime()
    --如果存在资源下载不创建图片
    -- self:initContent()
    if self.m_isDownloadImg then
        -- local isInApp = LevelIconInApp[self.m_levelName]
        local isInApp = true -- 入口图移动到res整包中
        if isInApp then
            self:initNoSpinLogo()
        end
    else
        self:initContent()
    end

    -- addCostRecord("lv_initContent", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    self:updateUnlockLv()
    -- addCostRecord("lv_initUnlock", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    -- self:initDLNode()
    self:initJackpot()
    -- addCostRecord("lv_initJackpot", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    -- self:initProgress()
    self:initBonusHuntNode()
    -- addCostRecord("lv_initBonusHuntNode", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    -- self:updateChallengeTag()
    -- addCostRecord("lv_initChallengeTag", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    self:initOtherUI()
    -- addCostRecord("lv_initOtherUI", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    -- self:updateTag()
    -- addCostRecord("lv_initTag", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    -- self:updateLink()
    -- addCostRecord("lv_initLink", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    self:updateTag()
    -- addCostRecord("lv_updateTag", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    self:updateUI()
    -- self:initHighBetUI()
    -- addCostRecord("lv_updateUI", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    -- self:initBuffCoins()
    -- addCostRecord("lv_initBuffCoins", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    --测试关卡顺序
    -- local test = self:creatContentFnt()
    -- test:setString(self.m_info.p_showOrder)
    -- test:setPosition(cc.p(0,0))
    -- self:addChild(test,1)

    self:addTestLevelName()
    -- addCostRecord("lv_addTestLevelName", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    self:initMaintain()
    -- addCostRecord("lv_initMaintain", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    self:initAvatarFrameTagUI()
    -- addCostRecord("lv_initAvatarFrameTagUI", socket.gettime() - curTime)
    -- curTime = socket.gettime()
    -- printCostRecord()
end

function LevelBaseNode:initMaintain()
    -- local curTime = socket.gettime()
    if not self.m_maintainTipsNode then
        self.m_maintainTipsNode = util_createAnimation("newIcons/Level_kongjian/Level_maintain.csb")
        self:addChild(self.m_maintainTipsNode, 1)
    end

    if not self.m_maintain then
        self.m_maintainTipsNode:setVisible(false)
        self:clearBlackLayer()
    else
        self.m_maintainTipsNode:setVisible(true)
        self:addBlackLayer()
    end
    -- addCostRecord("lv_initMaintain", socket.gettime() - curTime)
end

--初始化图标子类重写
function LevelBaseNode:initContent()
end

-- 初始化非Spin资源logo
function LevelBaseNode:initNoSpinLogo()
end

-- 是否需要刷新logo
function LevelBaseNode:isNeedUpdateLogo()
    if self.m_isDownloadImg then
        return false
    end

    if not self:isShowedLogo() then
        return true
    else
        local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
        if self.m_isOpenDeluxe ~= bOpenDeluxe then
            return true
        end
    end

    return false
end

function LevelBaseNode:initSpineFileInfo(levelName)
end

-- 刷新关卡logo
function LevelBaseNode:updateLevelLogo()
    if not self:isVisible() then
        return false
    else
        return true
    end
end

-- 获得关卡入口spine动画
function LevelBaseNode:getSpineLogo()
    return self.m_contents:getChildByName("SpineLogo")
end

function LevelBaseNode:addSpinAnimNode()
end

function LevelBaseNode:removeSpinAnimNode()
end

-- logo已显示
function LevelBaseNode:isShowedLogo()
    return self.m_isShowedLogo
end

-- 获得Spine资源名称
function LevelBaseNode:getSpineFileName(levelName, prefixName)
    return ""
end

-- 获得Spin资源信息
-- function LevelBaseNode:getSpinFileInfo(levelName, prefixName)
--     local spineName = self:getSpineFileName(self.m_levelName, prefixName)
--     local spinepath = "LevelNodeSpine/" .. spineName
--     local spinePngName = self:getSpineFileName(self.m_levelName, "common")
--     local spinePngPath = "LevelNodeSpine/" .. spinePngName
--     local spineTexture = spinePngPath .. ".png"

--     local pngFullPath = cc.FileUtils:getInstance():fullPathForFilename(spineTexture)
--     local isPngExist = cc.FileUtils:getInstance():isFileExist(pngFullPath)
--     if not isPngExist then
--         spineTexture = spinepath .. ".png"
--     end

--     local fileNamePath = cc.FileUtils:getInstance():fullPathForFilename(spinepath .. ".skel")
--     local isExist = cc.FileUtils:getInstance():isFileExist(fileNamePath)
--     if not isExist then
--         return false, "", ""
--     else
--         return true, spinepath, spineTexture
--     end
-- end

-- 高倍场开启结束时 刷新nodeUI 子类重写
function LevelBaseNode:updateDeluxeLevels(_bOpenDeluxe)
end

-- function LevelBaseNode:initBuffCoins()
--     -- local GameCrazeControl = util_getRequireFile("Activity/GameCrazeControl")
--     if GameCrazeControl then
--         GameCrazeControl:getInstance():createBuffIcoins(self.m_info.p_id)
--     end
-- end
--添加buff子类重写
function LevelBaseNode:updateBuffCoins(buffCoin, levelId)
end

function LevelBaseNode:initDLNode()
    local view = util_createAnimation("newIcons/Level_kongjian/Level_xiazai.csb")
    self.m_node_dl:addChild(view)
end

function LevelBaseNode:initBonusHuntNode()
    local view = self.m_bonusHunt:getChildByName("BonusHunt")
    if not view then
        view = cc.Sprite:create()
        view:setName("BonusHunt")
        self.m_bonusHunt:addChild(view)
    end

    if not self.m_isBonushuntLevel then
        view:setVisible(false)
    else
        self:changeBonusHuntIcon(view)
        view:setVisible(true)
    end
end

function LevelBaseNode:getHuntPos()
    local pos = cc.p(self.m_bonusHunt:getPosition())
    return pos
end

function LevelBaseNode:changeBonusHuntIcon(view)
end

function LevelBaseNode:initChallengeTag()
    if self.m_luckyChallenge then
        local view = self.m_luckyChallenge:getChildByName("LuckyChallenge")
        if not view then
            view = util_createAnimation("newIcons/Level_kongjian/Level_luckyChallenge.csb")
            view:setName("LuckyChallenge")
            self.m_luckyChallenge:addChild(view)
        end
    end
end

-- function LevelBaseNode:updateChallengeTag()
--     if self.m_luckyChallenge then
--         if not self.m_isOpenLuckyChallenge then
--             self.m_luckyChallenge:setVisible(false)
--         else
--             self.m_luckyChallenge:setVisible(true)
--         end
--     end
-- end

function LevelBaseNode:specialEnterLevel()
    -- 打开 选择level界面
    if globalData.GameConfig:checkChooseBetOpen() then
        self:enterChooseLevelUI(true)
    else
        self:enterLevel()
    end
end

-- 高倍场UI 显示
function LevelBaseNode:initHighBetUI()
end

--jackpot
function LevelBaseNode:initJackpot()
end

function LevelBaseNode:initProgress()
    -- 创建进度条
    local img = display.newSprite(self.m_contents:getTexture())
    if not img then
        release_print("initProgress = " .. self.m_contents:getTexture())
        return
    end

    self.m_loadingProgress = cc.ProgressTimer:create(img)
    self.m_loadingProgress:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.m_loadingProgress:setPercentage(0)
    self.m_loadingProgress:setAnchorPoint(0.5, 0)
    self.m_loadingProgress:setPosition(cc.p(0, 0))
    self.m_loadingProgress:setScaleX(self.m_contents:getScaleX())
    self.m_loadingProgress:setScaleY(self.m_contents:getScaleY())
    self.m_node_load:addChild(self.m_loadingProgress, 1)
    self.m_loadingProgress:setVisible(false)
    -- 创建进度条数字
    self.m_loadingProgressTxt = self:creatContentFnt()
    self.m_loadingProgressTxt:setString("0%")
    self.m_loadingProgressTxt:setAnchorPoint(0.5, 0)
    self.m_loadingProgress:setPosition(cc.p(0, 0))
    self.m_node_load:addChild(self.m_loadingProgressTxt, 1)
    self.m_loadingProgressTxt:setVisible(false)
end
--刷新进度
function LevelBaseNode:updateProgress()
    if self.m_loadingProgress then
        local img = display.newSprite(self.m_contents:getTexture())
        self.m_loadingProgress:setSprite(img)
    end
end

-- 子类重写
function LevelBaseNode:getTagCsbName()
    return ""
end

-- 子类可重写
function LevelBaseNode:getLinkCsbName()
    return "newIcons/Level_kongjian/Level_link.csb"
end

function LevelBaseNode:initTag()
    -- if not self.m_info.p_Log then
    --     return
    -- end
    local tagCsb = self:getTagCsbName()
    if not tagCsb or tagCsb == "" then
        return
    end

    local tagNode = self.m_node_tag:getChildByName("LevelTag")
    if not tagNode then
        printInfo("---initCsb = " .. tagCsb)
        tagNode = util_createView("views.lobby.Level_tag", tagCsb)
        self.m_node_tag:addChild(tagNode)
        tagNode:setName("LevelTag")
    end
end

-- function LevelBaseNode:updateTag()
--     if not self.m_info.p_Log then
--         self.m_node_tag:setVisible(false)
--     else
--         self.m_node_tag:setVisible(true)
--     end
-- end

function LevelBaseNode:initLink()
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

-- function LevelBaseNode:updateLink()
--     if not self.m_info.p_link then
--         self.m_node_ace:setVisible(false)
--     else
--         self.m_node_ace:setVisible(false)
--     end
-- end

-- 头像框标识
function LevelBaseNode:initAvatarFrameTagUI()
    -- local bOpen = G_GetMgr(G_REF.AvatarFrame):checkCurSlotOpen(self.m_info.p_id)
    -- if not bOpen then
    --     return
    -- end

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
end

--刷新标签
function LevelBaseNode:updateTag()
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

    -- if not hasLink then
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

        if self.m_luckyChallenge then
            if self.m_isOpenLuckyChallenge then
                self.m_luckyChallenge:setVisible(true)
            end
        end
    -- end
end

function LevelBaseNode:isOpenLuckyChallenge()
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData and #G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getCurLevelTask(self.m_info.p_id,true) > 0 then
        return true
    end
    return false
end

function LevelBaseNode:isBonushuntLevel()
    local bonusHuntData = G_GetActivityDataByRef(ACTIVITY_REF.BonusHunt) or G_GetActivityDataByRef(ACTIVITY_REF.BonusHuntCoin)
    if bonusHuntData and bonusHuntData:isOpen() and bonusHuntData:isBonusHuntLevel(self.m_info.p_id) then
        return true
    end
    return false
end

function LevelBaseNode:creatContentFnt()
    local label = ccui.TextBMFont:create()
    label:setFntFile("Common/font_update.fnt")
    label:setName("txt_progress")
    return label
end

--增加黑色遮罩
function LevelBaseNode:addBlackLayer()
    self.m_contents:setColor(cc.c3b(100, 100, 100))
end

--移除遮罩
function LevelBaseNode:clearBlackLayer()
    self.m_contents:setColor(cc.c3b(255, 255, 255))
end

function LevelBaseNode:isOpenVersion()
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

function LevelBaseNode:getContentLen()
    return self.m_contentLenX
end

function LevelBaseNode:getOffsetPosX()
    return self.m_contentLenX
end

function LevelBaseNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function LevelBaseNode:onEnter()
    LevelBaseNode.super.onEnter(self)
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         if not tolua.isnull(self) then
    --             self:initBuffCoins()
    --         end
    --     end,
    --     ViewEventType.GAMECRAZE_REFRESH_BUFF
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not self.updateTag then
                return
            end
            --刷新标签
            performWithDelay(
                self,
                function()
                    self:updateTag()
                end,
                0.1
            )
        end,
        ViewEventType.NOTIFY_UPDATE_LOBBY_CARD_INFO
    )

    -- 监听关卡下载进度
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         if self and self.updatePercent then
    --             self:updatePercent(params)
    --         end
    --     end,
    --     "LevelPercent_" .. self.m_levelName
    -- )
end

--刷新开始下载状态
function LevelBaseNode:updateStartDl()
    self:updatePercent(0.01)
end
--刷新下载中问题
function LevelBaseNode:updateDling()
    if self.m_fastLevel then
        return
    end
    if self.m_status == self.STATUS_DOING then
        return
    end
    self.m_node_load:setVisible(true)
    self.m_status = self.STATUS_DOING
    self.m_loadingProgress:setVisible(true)
    --self.m_loadingProgressTxt:setVisible(true)
    self:addBlackLayer()
    self.m_node_dl:setVisible(false)
    self:hidelock()
end

--刷新下载状态
function LevelBaseNode:updatePercent(percent)
    if self.m_fastLevel then
        return
    end
    self.m_percent = percent
    local extra = {}
    extra.levelName = self.m_levelName
    if percent == -1 then
        -- 下载失败
        -- 提示弹框
        if self.m_nodeType and self.m_nodeType == self.NODE_TYPE_SMALL then
            gLobalViewManager:showDialog(
                "Dialog/DowanLoadLevelFailed.csb",
                function()
                end,
                nil,
                nil,
                nil,
                {
                    {buttomName = "btn_ok", labelString = "RETRY"}
                }
            )
        end
        self.m_loadingProgress:setPercentage(0)
        self.m_loadingProgress:setVisible(false)
        self.m_loadingProgressTxt:setString("0%")
        self.m_loadingProgressTxt:setVisible(false)
        self:updateNotDL()
    elseif percent == 2 then
        -- self:enterLevel()
        -- 下载成功
        self:updateDoneDl()
    else
        self:updateDling()
        if self.m_loadingProgress then
            self.m_loadingProgress:setPercentage(math.ceil(percent * 100))
        end
        if self.m_loadingProgressTxt then
            self.m_loadingProgressTxt:setString(math.ceil(percent * 100) .. "%")
        end
    end
end

--下个版本可用
function LevelBaseNode:updateNextVersion()
    self.m_status = self.STATUS_NEXTVERSION
    self.m_node_dl:setVisible(false)
end

--维护中
function LevelBaseNode:updateMaintenance()
    self.m_status = self.STATUS_MAINTENANCE
    self:hideNode(self.m_node_dl)
    self:hideNode(self.m_node_jackpot)
    self:hideNode(self.m_node_tag)
    self:hideNode(self.m_node_ace)
    self:hideNode(self.m_bonusHunt)
    self:hidelock()
end

function LevelBaseNode:hideNode(node)
    if node and node.setVisible then
        node:setVisible(false)
    end
end

--刷新敬请期待
function LevelBaseNode:updateCommingSoon()
    if self.m_levelName == "CommingSoon" then
        self.m_status = self.STATUS_COMMINGSOON
        self.m_node_load:setVisible(false)
        self.m_node_dl:setVisible(false)
        return true
    end
    return false
end

--刷新未解锁状态
function LevelBaseNode:updateUnLock()
    self.m_status = self.STATUS_UNLOCK
    self.m_node_load:setVisible(false)
    self.m_node_dl:setVisible(false)
    self:showlock()
end
--刷新未下载状态
function LevelBaseNode:updateNotDL()
    self.m_status = self.STATUS_NOTDL
    self.m_node_load:setVisible(false)
    self.m_node_dl:setVisible(true)
    self:clearBlackLayer()
    self:hidelock()
end
--刷新下载完成状态
function LevelBaseNode:updateDoneDl()
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

--刷新UI
function LevelBaseNode:updateUI()
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
--点击回调
function LevelBaseNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch" then
        if self.m_status ~= self.STATUS_DOING then
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_theme)
            end

            self:checkGotoLevel()
        end
    end
end
--是否解锁
function LevelBaseNode:isOpenLevel()
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

--点击关卡图标跳转相关逻辑
function LevelBaseNode:checkGotoLevel()
    if not self.m_info then
        return
    end

    -- 入口图移动到res整包中
    -- if self.m_isDownloadImg and not LevelIconInApp[self.m_levelName] then
    --     --入口未下载
    --     return
    -- end
    self:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1, 0.95), cc.ScaleTo:create(0.1, 1)))
    local isPlayBtnMusic = false

    if not globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.comeCust) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        isPlayBtnMusic = true
    end

    if self.m_status == self.STATUS_NEXTVERSION then
        gLobalViewManager:showDialog(
            "Dialog/NewVersionLayer.csb",
            function()
                xcyy.GameBridgeLua:rateUsForSetting()
            end,
            nil,
            nil,
            nil
        )
        return
    end

    if self.m_status == self.STATUS_UNLOCK then
        self:playClickUnLockAction()
        return
    end

    if self.m_status == self.STATUS_COMMINGSOON or self.m_status == self.STATUS_DOING or self.m_status == self.STATUS_MAINTENANCE then
        self:checkShowStatusTips()
        return
    end

    -- 处理打点
    gL_logData:createGameSessionId(self.m_info.p_name)
    globalData.slotRunData.currLevelEnter = FROM_LOBBY
    -- 新手引导相关
    if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.comeCust) then
        -- 引导打点：进入关卡-2.点击进入关卡
        gLobalSendDataManager:getLogGuide():sendGuideLog(1, 2)
        globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.comeCust)
        self:enterLevel()
        return
    end
    -------------------------------------------------------------------------
    -- 判断下载，下载后直接进入关卡
    if self.m_status == self.STATUS_NOTDL then
        local downType = gLobaLevelDLControl:isDownLoadLevel(self.m_info)
        if downType == 1 or downType == 0 then
            -- 1 已下载未更新 0未下载
            self:updateDling()
            gLobaLevelDLControl:checkDownLoadLevel(self.m_info)
        end
        if isPlayBtnMusic == false then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        end
    elseif self.m_status == self.STATUS_DONE then
        if globalData.GameConfig:checkChooseBetOpen() then
            self:enterChooseLevelUI()
        else
            self:enterLevel()
        end
    end
end
-- 进入关卡选择页面 (选择普通场 还是 高倍场)
function LevelBaseNode:enterChooseLevelUI(_bIgnoreNodeType)
    local bHideArrowBtn = false
    if not _bIgnoreNodeType and self.m_nodeType == self.NODE_TYPE_BIG then
        bHideArrowBtn = true
    end
    local view = util_createView("views.ChooseLevel.ChooseLevelLayer", self.m_levelId, bHideArrowBtn)
    if view then
        view:setSiteType(self:getSiteType())
        view:setSiteName(self:getSiteName())
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

--进入关卡
function LevelBaseNode:enterLevel()
    gLobalViewManager:lobbyGotoGameScene(self.m_info.p_id)
end

-- FOR TEST
function LevelBaseNode:addTestLevelName()
    if not CC_SHOW_LEVELNAME_IN_LOBBY then
        return
    end
    local testLb1 = self:getChildByName("Level_Name")
    if not testLb1 then
        testLb1 = cc.Label:create()
        self:addChild(testLb1, 100000)
        testLb1:setSystemFontSize(20)
        testLb1:setColor(cc.c3b(255, 255, 255))
        testLb1:setAnchorPoint(cc.p(0, 0))
        local pos = cc.p(self.m_node_dl:getPosition())
        testLb1:setPosition(cc.p(pos.x, pos.y - 40))
        testLb1:setName("Level_Name")
    end

    testLb1:setString(tostring(self.m_info.p_serverShowName) .. "/" .. tostring(self.m_info.p_showName))
end

--提示维护中
function LevelBaseNode:checkShowStatusTips()
    if self.m_isPlayTips then
        return
    end

    --维护
    if self.m_maintain then
        self.m_isPlayTips = true
        self.m_maintainTipsNode:playAction("show")
        performWithDelay(
            self,
            function()
                self.m_maintainTipsNode:playAction(
                    "hide",
                    false,
                    function()
                        self.m_isPlayTips = nil
                    end,
                    60
                )
            end,
            1
        )
        return
    end
end

return LevelBaseNode
