--
--大厅关卡节点
--
local LevelBaseNode = util_require("views.lobby.LevelBaseNode")
local LevelBigNode = class("LevelBigNode", LevelBaseNode)

--子类重新创建的csb节点
function LevelBigNode:getCsbName()
    self.m_nodeType = self.NODE_TYPE_BIG
    return "newIcons/LevelBigNode.csb"
end

function LevelBigNode:initCsbNodes()
    LevelBigNode.super.initCsbNodes(self)
    -- 先隐藏边框，下载完成再刷新
    local spHighFrame = self:findChild("sp_highFrame")
    spHighFrame:setVisible(false)
end

--初始化图标子类重写
function LevelBigNode:initContent()
    self:updateLevelLogo()
end

-- 更新关卡Logo
function LevelBigNode:updateLevelLogo()
    -- 图的边框（高倍场开启显示金色边框）
    local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    self:updateDeluxeLevels(bOpenDeluxe)

    -- setDefaultTextureType("RGBA8888", nil)
    -- local createSpine = false
    local noSpinCallFunc = function()
        local path = globalData.GameConfig:getLevelIconPath(self.m_levelName, LEVEL_ICON_TYPE.BIG)
        -- display.removeImage(path)

        local _callback = function(textureInfo)
            if not tolua.isnull(self) then
                if textureInfo then
                    util_changeTexture(self.m_contents, path)
                    self.m_isShowedLogo = true
                else
                    util_changeTexture(self.m_contents, "newIcons/Order/cashlink_loading.png")
                end
            end
        end

        display.loadImage(path, _callback)
        -- local hasImage = util_changeTexture(self.m_contents, path)
        -- if hasImage == false then
        --     util_changeTexture(self.m_contents, "newIcons/Order/cashlink_loading.png")
        -- end
    end

    local spineLogo = self:getSpineLogo()
    if not spineLogo and self.m_levelName ~= "CommingSoon" then
        self:addSpineAnimNode(noSpinCallFunc)
    else
        noSpinCallFunc()
    end

    -- setDefaultTextureType("RGBA4444", nil)
end

-- 获得Spine资源名称
function LevelBigNode:getSpineFileName(levelName, prefixName)
    prefixName = prefixName or ""
    local fileName = prefixName .. "_level_spine_" .. levelName
    return fileName
end

-- 添加Spine动画
function LevelBigNode:addSpineAnimNode(noSpinCallback)
    local noSpinCallFunc = function()
        if noSpinCallback then
            noSpinCallback()
        end
    end

    local spineLogo = self:getSpineLogo()
    if not spineLogo and self.m_levelName ~= "CommingSoon" then
        local isExist = false
        local spinepath = ""
        local spineTexture = ""
        -- isExist, spinepath, spineTexture = self:getSpinFileInfo(self.m_levelName, "big")
        isExist, spinepath, spineTexture = globalData.slotRunData:getLobbySpinInfo(self.m_levelName, "big")

        if isExist then
            local _callback = function(textureInfo)
                if not tolua.isnull(self) then
                    if textureInfo then
                        local spineNode = util_spineCreate(spinepath, true, true)
                        spineNode:setName("SpineLogo")
                        self.m_contents:addChild(spineNode)
                        spineNode:setPosition(119, 236)
                        util_spinePlay(spineNode, "actionframe", true)

                        self.m_isShowedLogo = true
                    else
                        noSpinCallFunc()
                    end
                end
            end

            display.loadImage(spineTexture, _callback)
        else
            print("没有 动态图  = " .. spinepath)
            release_print("没有 动态图  = " .. spinepath)
            noSpinCallFunc()
        end
    end
end

-- 高倍场开启结束时 刷新nodeUI 子类重写
function LevelBigNode:updateDeluxeLevels(_bOpenDeluxe)
    local spNormalFrame = self:findChild("sp_normalFrame")
    local spHighFrame = self:findChild("sp_highFrame")

    spNormalFrame:setVisible(not bOpenDeluxe)
    spHighFrame:setVisible(_bOpenDeluxe)

    self.m_isOpenDeluxe = _bOpenDeluxe
end

--子类重写
function LevelBigNode:initOtherUI()
    self.m_contentLenX = 110
end

--解锁相关逻辑子类重写
function LevelBigNode:initUnlock()
    --锁
    self.m_lockNode = util_createAnimation("newIcons/Level_kongjian/Level_suo_big.csb")
    self:addChild(self.m_lockNode, 1)
    self.m_lockNode:playAction("suo2")
    local m_lb_level = self.m_lockNode:findChild("m_lb_level")
    if m_lb_level then
        m_lb_level:setString("LEVEL  " .. self.m_openLevel)
    end
end

function LevelBigNode:initJackpot()
    if not self.m_info.p_showJackpot or self.m_info.p_showJackpot == 0 then
        -- 无jackpot
        -- 特殊玩法
        if self.m_info.p_specialFeature then
            if tonumber(self.m_info.p_specialFeature) > 1000 then
                -- -- 配置大于1000的，用小图标
                -- local icon = self.LEVEL_SPCIAL_FEATURE_ICON.big[tonumber(self.m_info.p_specialFeature)-1000]
                -- local smallFeature = cc.Sprite:create(icon)
                -- smallFeature:setPosition(cc.p(81,-53))
                -- self.m_node_jackpot:addChild(smallFeature)
            else
                local icon = self.LEVEL_SPCIAL_FEATURE_ICON.big[tonumber(self.m_info.p_specialFeature)]
                if icon and icon ~= "" then -- 没有配置不添加
                    local csbName = "newIcons/Level_kongjian/Level_wanfa_big.csb"
                    local noJackpot = util_createView("views.lobby.LevelSpecialFeature", csbName, icon)
                    self.m_node_jackpot:addChild(noJackpot)
                end
            end
        end
    else
        -- 有jackpot
        if self.m_info.p_specialFeature then
            if tonumber(self.m_info.p_specialFeature) > 1000 then
                -- 配置大于1000的，用小图标
                -- local icon = self.LEVEL_SPCIAL_FEATURE_ICON.big[tonumber(self.m_info.p_specialFeature)-1000]
                -- local smallFeature = cc.Sprite:create(icon)
                -- smallFeature:setPosition(cc.p(81,-53))
                -- self.m_node_jackpot:addChild(smallFeature)
                local jackPotItemUI = util_createView("views.lobby.LevelJackpotItem", self.m_info)
                self.m_node_jackpot:addChild(jackPotItemUI)
            else
                local icon = self.LEVEL_SPCIAL_FEATURE_ICON.big[tonumber(self.m_info.p_specialFeature)]
                if icon and icon ~= "" then -- 没有配置不添加
                    local jackPotItemUI = util_createView("views.lobby.LevelSpecialFeatureItem", self.m_info, icon)
                    self.m_node_jackpot:addChild(jackPotItemUI)
                else
                    local jackPotItemUI = util_createView("views.lobby.LevelJackpotItem", self.m_info)
                    self.m_node_jackpot:addChild(jackPotItemUI)
                end
            end
        else
            local jackPotItemUI = util_createView("views.lobby.LevelJackpotItem", self.m_info)
            self.m_node_jackpot:addChild(jackPotItemUI)
        end
    end
end

function LevelBigNode:updateTag()
    self.m_bonusHunt:setVisible(false)
    self.m_luckyChallenge:setVisible(false)
    -- link
    local hasLink = false
    local linkNode = self.m_node_ace:getChildByName("LinkTag")

    if linkNode and CardSysManager:canEnterCardCollectionSys() then
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
            tagNode:playIdleAction("idle_feature")
        end
    end

    if not hasLink then
        if self.m_luckyChallenge then
            if self:isOpenLuckyChallenge() then
                self.m_luckyChallenge:setVisible(true)
            end
        end
    end
end

--检测是否解锁
function LevelBigNode:playClickUnLockAction()
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
function LevelBigNode:showlock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(true)
    end
end
--隐藏锁
function LevelBigNode:hidelock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(false)
    end
end

function LevelBigNode:checkUnLockAction()
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

function LevelBigNode:clickFunc(sender)
    gLobalSendDataManager:getLogSlots():resetEnterLevel()
    gLobalSendDataManager:getLogSlots():setEnterLevelSiteType("RecommendedArea")
    LevelBaseNode.clickFunc(self, sender)
end

function LevelBigNode:checkGotoLevel()
    --下载入口记录
    if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
        gLobalSendDataManager:getLogGameLevelDL():setDownloadInfo(self.m_info.p_levelName, {type = "normal", siteType = "RecommendedArea"})
    end
    LevelBaseNode.checkGotoLevel(self)
end

function LevelBigNode:getTagCsbName()
    return "newIcons/Level_kongjian/Level_tag_big.csb"
end

function LevelBigNode:updateCommingSoon()
    LevelBaseNode.updateCommingSoon(self)
    self:hidelock()
end

function LevelBigNode:changeBonusHuntIcon(view)
    if view ~= nil then
        -- local bonusHuntIcon = view:findChild("sp_bg")
        local bonusHuntIcon = view
        util_changeTexture(bonusHuntIcon, "newIcons/Other/wanfa_bonshuntBig.png")
    end
end

--添加buff子类重写
function LevelBigNode:updateBuffCoins(buffCoin, levelId)
    if levelId == self.m_info.p_id and not self:getChildByName("GAMECRAZE_BUFF") then
        buffCoin:setName("GAMECRAZE_BUFF")
        local size = self.m_contents:getContentSize()
        -- local pos = cc.p(-size.width/2, -size.height / 4)
        local pos = self:getHuntPos()
        buffCoin:setPosition(pos)
        self:addChild(buffCoin)
    end
end
return LevelBigNode
