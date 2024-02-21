--
--大厅顶部UI
-- csc 2021年12月14日19:42:28 修改ui结构
--
local AdsRewardIcon = class("AdsRewardIcon", util_require("base.BaseView"))
function AdsRewardIcon:initUI(data)
    self.m_isFreeCoins = false
    self.isLoading = false
    if data.res and string.len(data.res) > 0 then
        self:createCsbNode(data.res)
    else
        self:createCsbNode("ads/Ads_icon_new.csb")
    end
    self.m_sceneName = data.scene
    local adsInfo = globalData.adsRunData:getAdsInfoForPos(self.m_sceneName .. "Pos")
    if not adsInfo then
        adsInfo = {p_coins = 0}
    end
    self.m_labCoin = self:findChild("m_lb_coins_" .. self.m_sceneName)

    if self.m_sceneName == "Game" then
        self.m_coinLen = 6
        self.m_labCoin:setString(util_coinsLimitLen(tonumber(adsInfo.p_coins), self.m_coinLen))
        self:updateLabelSize({label = self.m_labCoin, sx = 0.6, sy = 0.6}, 100)
    else
        local sp_coins = self:findChild("sp_coins")
        if sp_coins then
            self.m_coinLen = 9
            self.m_labCoin:setString(util_coinsLimitLen(tonumber(adsInfo.p_coins), self.m_coinLen))
            self:updateLabelSize({label = self.m_labCoin}, 100)
        else
            self.m_coinLen = 30
            self.m_labCoin:setString(util_coinsLimitLen(tonumber(adsInfo.p_coins), self.m_coinLen))
            self:updateLabelSize({label = self.m_labCoin}, 150)
        end
    end
    if globalData.adsRunData:isGuidePlayAds() then
        if globalData.adsRunData.p_firstCoins then
            --第一次引导
            self.m_labCoin:setString(util_coinsLimitLen(tonumber(globalData.adsRunData.p_firstCoins), self.m_coinLen))
        end
    end

    -- csc 2021-12-14 新ui逻辑
    self.m_lobbyNode = self:findChild("Lobby_rukou")
    self.m_gameNode = self:findChild("Game_rukou")

    self:addClick(self:findChild(self.m_sceneName .. "_btn"))

    self:updateVisible(data.init)

    self:updateFirstAdsGuide()
end

function AdsRewardIcon:updateFirstAdsGuide()
    if self.m_sceneName == "Game" then
        local firstPlayRewardVedio = gLobalDataManager:getNumberByField("firstPlayRewardVedio", 0)
        if firstPlayRewardVedio == 0 and globalData.adsRunData:isPlayRewardForPos(self.m_sceneName .. "Pos") and globalData.adsRunData:isGuidePlayAds() then
            gLobalDataManager:setNumberByField("firstPlayRewardVedio", 1)

            self.m_adsTipNode = util_createAnimation("ads/AdsTipNode.csb")
            self:addChild(self.m_adsTipNode, 1)
            self.m_adsTipNode:setScale(1.5)
            self.m_adsTipNode:setPosition(-280 - 90, 0)

            -- 引导打点：广告引导-1.广告提示出现
            gLobalSendDataManager:getLogGuide():setGuideParams(10, {isForce = false, isRepeat = false, guideId = nil})
            gLobalSendDataManager:getLogGuide():sendGuideLog(10, 1)

            --点击不关闭
            performWithDelay(
                self,
                function()
                    self.m_adsTipNode:setVisible(false)
                end,
                3
            )
        end
    end
end

function AdsRewardIcon:updateVisible(_init)
    if globalData.adsRunData:isPlayRewardForPos(self.m_sceneName .. "Pos") then
        self.m_isFreeCoins = true
        local adsInfo = globalData.adsRunData:getAdsInfoForPos(self.m_sceneName .. "Pos")
        self.m_labCoin:setString(util_coinsLimitLen(tonumber(adsInfo.p_coins), self.m_coinLen))
        if globalData.adsRunData:isGuidePlayAds() then
            if globalData.adsRunData.p_firstCoins then
                --第一次引导
                self.m_labCoin:setString(util_coinsLimitLen(tonumber(globalData.adsRunData.p_firstCoins), self.m_coinLen))
            end
        end
        self:updateFirstAdsGuide()
    else
        self.m_isFreeCoins = false
    end

    self:setVisible(self.m_isFreeCoins)
    if self.m_isFreeCoins then
        if self.m_sceneName == "Game" then
            self.m_lobbyNode:setVisible(false)
            self.m_gameNode:setVisible(true)
        else
            self.m_lobbyNode:setVisible(true)
            self.m_gameNode:setVisible(false)
        end
        if _init then
            self:runCsbAction(
                "start",
                false,
                function()
                    self:runCsbAction("idle", true, nil, 60)
                end,
                60
            )
        else
            self:runCsbAction("idle", true, nil, 60)
        end
    end
end

function AdsRewardIcon:onEnter()
    --游戏内广告节点不在这里控制
    if self.m_sceneName == "Game" then
        return
    end

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateVisible()
        end,
        "ads_vedio"
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setVisible(false)
        end,
        "hide_vedio_icon"
    )
end

function AdsRewardIcon:clickFunc()
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "videoIcon")
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:setVisible(false)
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(self.m_sceneName .. "Pos")
    gLobalSendDataManager:getLogAds():setOpenType("TapOpen")
    gLobalSendDataManager:getLogAds():setOpenStatus("Allow")
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = self.m_sceneName .. "Pos"}, nil, "click")
    -- globalData.adsRunData:CheckAdByPosition(self.m_sceneName.."Pos")

    gLobalViewManager:addLoadingAnima()
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(self.m_sceneName .. "Pos")
    gLobalSendDataManager:getLogAdvertisement():setOpenType("TapOpen")
    gLobalAdsControl:playRewardVideo(self.m_sceneName .. "Pos")

    -- 引导打点：广告引导-2.点击广告图标
    if self.m_sceneName == "Game" then
        if gLobalSendDataManager:getLogGuide():isGuideBegan(10) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(10, 2)
        end
    end
end

-- 返回右边栏 entry 大小
function AdsRewardIcon:getRightFrameSize()
    self.m_Node_PanelSize = self:findChild("Node_PanelSize")

    local size = {widht = 110, height = 90}

    if self.m_Node_PanelSize ~= nil then
        local contentSize = self.m_Node_PanelSize:getContentSize()
        size.height = contentSize.height
    end
    
    return size
end

return AdsRewardIcon
