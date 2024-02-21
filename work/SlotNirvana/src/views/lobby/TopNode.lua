--
--大厅顶部UI
--
local TopNode = class("TopNode", util_require("base.BaseView"))

TopNode.m_videoBtn = nil -- video 按钮
TopNode.m_menu = nil
TopNode.m_showCoinUpdateAction = nil
TopNode.m_showTargetCoin = nil
TopNode.m_curCoin = nil

TopNode.m_piggyBank = nil -- 小猪银行节点
TopNode.m_isOpenSale = nil
local COINS_LABEL_WIDTH = 312 -- 金币控件的长度
local COINS_DEFAULT_SCALE = 0.60 -- 金币控件的缩放
local GEMS_LABEL_WIDTH = 149 -- 钻石控件的长度
local GEMS_DEFAULT_SCALE = 0.60 -- 钻石控件的缩放

local AlternateTime = 10 --node_shop_freecoins节点的轮流展示时间

function TopNode:initCsbNodes()
    self.node_shop_freecoins = self:findChild("node_shop_freecoins")
    --促销新按钮
    self.two_buttom = self:findChild("two_buttom")
    -- self.two_buttom_tx = self:findChild("two_buttom_tx")

    self.m_btn_layout_buy_deal = self:findChild("btn_layout_buy_deal")
    self.m_xiao_deal_up = self:findChild("xiao_deal_up")
    self.m_xiao_deal_down = self:findChild("xiao_deal_down")
    self.m_xiao_buy_up = self:findChild("xiao_buy_up")
    self.m_xiao_buy_down = self:findChild("xiao_buy_down")
    self.m_one_buttom = self:findChild("one_buttom")
    -- self.m_one_buttom_tx =self:findChild("one_buttom_tx")

    --buy流光
    -- self.two_buttom_0 = self:findChild("two_buttom_0")
    self.m_sprOptionRedTips = self:findChild("sprite_option_redtips")
    -- 初始化经验、等级、金币等
    self.m_coinLabel = self:findChild("txt_coins")
    self.m_gemLabel = self:findChild("txt_gems")

    self.m_txtLevel = self:findChild("lab_level")

    self.m_reward_video = self:findChild("reward_video")
    self.m_showTipsNode = self:findChild("node_showTips")

    self.face_book = self:findChild("face_book")
    self.face_book_down = self:findChild("face_book_down")
    --头像上的红点跟fb小角标是放这里面的
    self.m_nodeHeadPoint = self:findChild("node_headPoint")
    -- 头像
    self.m_spHead = self:findChild("sp_head")
    --头像上fb的角标
    self.m_spHeadFacebook = self:findChild("sp_headfacebook")
    self.spHeadRedpoint = self:findChild("sp_headredpoint")
    --头像上的红点
    -- self.m_sp_vip_root = self:findChild("sp_vip_root")
    -- self.sp_vip_0 = self:findChild("sp_vip_0")
    -- self.sp_vip = self:findChild("sp_vip")
    self.m_sp_faceTop = self:findChild("sp_faceTop")
    self.m_sp_faceTop_0 = self:findChild("sp_faceTop_0")
    self.m_sp_faceTop_root = self:findChild("sp_faceTop_root")
    -- self.m_vipicon = self:findChild("vipicon")
    self.m_coinNode = self:findChild("lab_coin_bg")
    -- self.m_boostImg = self:findChild("boostImg")
    -- self.m_vip_liuguang = self:findChild("vip_liuguang")
    self.m_gemNode = self:findChild("node_lab_gem")

    self.sp_buy_0 = self:findChild("sp_buy_0")
    self.sp_buy = self:findChild("sp_buy")

    self.m_node_coin_eff = self:findChild("node_coin_eff")

    self.btn_layout_fb = self:findChild("btn_layout_fb")
    self.btn_layout_vip = self:findChild("btn_layout_vip")
    self.btn_layout_buy = self:findChild("btn_layout_buy")
    self.btn_layout_buy_0 = self:findChild("btn_layout_buy_0")
    self.btn_layout_buy_gem = self:findChild("btn_layout_buy_gem")
    self.btn_layout_option = self:findChild("btn_layout_option")
    self.btn_levelRoad = self:findChild("btn_levelRoad")
    self.btn_showTips = self:findChild("btn_showTips")
    self.btn_showFreeCoins = self:findChild("tishizhezhao")
    self.btn_showFreeCoins_0 = self:findChild("tishizhezhao_0")
    self.btn_showSale = self:findChild("btn_showSale")

    self.m_specialDealNode = self:findChild("Node_SpecialDeal")
    self.m_specialDealNode:setVisible(true)
    self.Limited_time_down = self:findChild("Limited-time_down")
    self.Limited_time_up = self:findChild("Limited-time_up")

    self.m_nodeEntrance = self:findChild("node_entrance")
end

function TopNode:initUI(data)
    -- setDefaultTextureType("RGBA8888", nil)
    self:createCsbNode("GameNode/TopNode.csb")
    -- self:findChild("ui_lg"):setVisible(false)
    -- self:findChild("sp_bg_glow_1"):setVisible(false)
    self:runCsbAction("idle", true)
    -- 商城提示图标
    self.isTrigger = true
    -- 商城特殊红点交替显示时间
    self.m_alternate_time = 0

    self.m_shop_freecoins_Action = util_createView("GameModule.Shop.ShopActionModular", "Shop_Res/node_shop_freecoins.csb")
    if self.m_shop_freecoins_Action then
        self.node_shop_freecoins:addChild(self.m_shop_freecoins_Action)
        self.m_shop_freecoins_Action:setVisible(false)
    end
    local path = "shop_title/superspin_special.csb"
    self.m_shop_lucky_spin = util_createView("GameModule.Shop.shopLuckySpinTip",path)
    if self.m_shop_lucky_spin then
        self.node_shop_freecoins:addChild(self.m_shop_lucky_spin)
        self.m_shop_lucky_spin:setVisible(false)
        self.m_shop_lucky_spin:setScale(0.6)
    end
    self.m_shop_scratch_card = util_createView("GameModule.Shop.ShopScratchTip")
    if self.m_shop_scratch_card then
        self.node_shop_freecoins:addChild(self.m_shop_scratch_card)
        self.m_shop_scratch_card:setVisible(false)
        self.m_shop_scratch_card:setScale(0.8)
    end

    -- self.buyeft = util_createView("views.lobby.BuyEft")
    -- self.two_buttom_0:addChild(self.buyeft)

    -- 初始化设置按钮
    self:initOptionBtn()

    if self.m_sprOptionRedTips then
        self.m_sprOptionRedTips:setVisible(false)
    end

    -- 小猪
    self:initPiggys()

    -- 初始化经验、等级、金币等
    self:initCoinsInfo()

    -- 初始化钻石
    self:initGemsInfo()

    -- 初始化代币
    self:initBucksInfo()

    local curLevel = globalData.userRunData.levelNum
    self.m_txtLevel:setString(curLevel)
    self.m_txtLevel:setScale(1.2)

    self:initProcessInfo()

    self:initAdsNode()

    self:initBtnClicks()

    -- 特殊交易
    self:initLimitedSale()

    --头像上fb的角标
    self.m_spHeadFacebook:setVisible(false)
    --头像上的红点
    self.spHeadRedpoint:setVisible(false)
    self.m_sp_faceTop_root:setVisible(false)

    self:clickEndFunc()

    self.m_particleShuzi = cc.ParticleSystemQuad:create("Lobby/Other/Shuzi.plist")
    self.m_node_coin_eff:addChild(self.m_particleShuzi, 3)
    self.m_particleShuzi:setPosition(-20, 0)
    self.m_particleShuzi:setScale(1)
    self.m_particleShuzi:setVisible(false)

    -- self:initBoostIcon()

    self:initMulExp()

    self:initLevelTips()

    --促销初始化
    self.m_isOpenSale = nil
    self.two_buttom:setVisible(false)
    --self.two_buttom_tx:setVisible(false)

    self.m_one_buttom:setVisible(true)
    --self.m_one_buttom_tx:setVisible(true)

    self.m_btn_layout_buy_deal:setVisible(false)
    self:updateUiBg()
    -- setDefaultTextureType("RGBA4444", nil)
    self:updateBasicSale()

    --刷新头像上面红点跟fb角标显示
    self:updateHeadRedPoint()
    --刷新头像
    self:updateHead()

    self:initTipBarRT()

    self:initCurrencyBuckData()

    self:setActive(true)
end

function TopNode:initCurrencyBuckData(nValue)
    if nValue == nil then
        local mgr = G_GetMgr(G_REF.ShopBuck)
        if mgr then
            nValue = mgr:getBuckNum()
        end
    end
    if nValue == nil then
        return
    end
    local mgr = G_GetMgr(G_REF.Currency)
    if mgr then
        mgr:setBucks(nValue)
    end
end

-- 右上角提示条
function TopNode:initTipBarRT()
    self.m_tipBarRT = util_createFindView("views/lobby/TipBar")
    if self.m_tipBarRT then
        self.m_nodeEntrance:addChild(self.m_tipBarRT)

        -- 回归用户
        self:initReturnSignLogo(self.m_tipBarRT)
        -- 成长基金
        self:initGrowthFundNode(self.m_tipBarRT)
        -- 新手七日目标
        self:initNewUser7Day(self.m_tipBarRT)

        self.m_tipBarRT:updatePosOffset()
    end
end

function TopNode:initCoinsInfo()
    globalData.coinsSoundType = 0
    self.m_showTargetCoin = toLongNumber(0)
    self.m_curCoin = toLongNumber(0)

    local coinCount = globalData.userRunData.coinNum
    self:updateCoinLabel(false, coinCount)
    self:updateCoinBg()
end

function TopNode:initGemsInfo()
    self.m_showTargetGem = 0
    self.m_curGem = 0

    self:updateGemLabel(false, globalData.userRunData.gemNum)
    self:updateGemBg()
end

function TopNode:initBucksInfo()
    local nValue = 0
    local buckMgr = G_GetMgr(G_REF.ShopBuck)
    if buckMgr then
        nValue = buckMgr:getBuckNum()
    end
    local mgr = G_GetMgr(G_REF.Currency)
    if mgr then
        mgr:setBucks(nValue)
    end    
end

function TopNode:setActive(bl_active)
    self.bl_active = bl_active
end

function TopNode:isActive()
    return self.bl_active
end

function TopNode:initAdsNode()
    self.m_reward_video = self:findChild("reward_video")
    if self.m_reward_video then
        self.m_reward_video:removeAllChildren()
        globalData.lobbyVedioNode = nil
    end

    if globalData.adsRunData.p_isNull == false and globalData.adsRunData:CheckAdByPosition(PushViewPosType.LobbyPos) then
        local viewParam = {scene = "Lobby", init = true}
        local vedio = util_createView("views.lobby.AdsRewardIcon", viewParam)
        self.m_reward_video:addChild(vedio)
        globalData.lobbyVedioNode = vedio
        -- 注册cleanup回调
        addCleanupListenerNode(
            vedio,
            function()
                globalData.lobbyVedioNode = nil
            end
        )
    end

    -- local reward_videoChallenge = self:findChild("reward_videoChallenge")
    -- if reward_videoChallenge then
    --     reward_videoChallenge:removeAllChildren()
    --     globalData.lobbyVedioChallgeNode = nil
    -- end
    -- if globalData.AdChallengeData:isHasAdChallengeActivity() and gLobalAdChallengeManager:checkOpenLevel() then
    --     local reward_videoChallenge = self:findChild("reward_videoChallenge") --reward_videoChallenge
    --     if reward_videoChallenge then
    --         local adsChallengeIconNode = util_createView("views.Ad_Challenge.AdsChallengeLobbyIconNode")
    --         reward_videoChallenge:addChild(adsChallengeIconNode)
    --         globalData.lobbyVedioChallgeNode = adsChallengeIconNode
    --     end
    -- end
end

function TopNode:refreshAdsNode()
    if globalData.adsRunData.p_isNull == false and globalData.adsRunData:CheckAdByPosition(PushViewPosType.LobbyPos) then
        if not globalData.lobbyVedioNode then
            local viewParam = {scene = "Lobby", init = true}
            local vedio = util_createView("views.lobby.AdsRewardIcon", viewParam)
            self.m_reward_video:addChild(vedio)
            globalData.lobbyVedioNode = vedio
            -- 注册cleanup回调
            addCleanupListenerNode(
                vedio,
                function()
                    globalData.lobbyVedioNode = nil
                end
            )
        end
    else
        if self.m_reward_video then
            self.m_reward_video:removeAllChildren()
            globalData.lobbyVedioNode = nil
        end
    end

    -- if globalData.AdChallengeData:isHasAdChallengeActivity() and gLobalAdChallengeManager:checkOpenLevel() then
    --     if not globalData.lobbyVedioChallgeNode then
    --         local reward_videoChallenge = self:findChild("reward_videoChallenge") --reward_videoChallenge
    --         if reward_videoChallenge then
    --             local adsChallengeIconNode = util_createView("views.Ad_Challenge.AdsChallengeLobbyIconNode")
    --             reward_videoChallenge:addChild(adsChallengeIconNode)
    --             globalData.lobbyVedioChallgeNode = adsChallengeIconNode
    --         end
    --     end
    -- else
    --     local reward_videoChallenge = self:findChild("reward_videoChallenge")
    --     if reward_videoChallenge then
    --         reward_videoChallenge:removeAllChildren()
    --         globalData.lobbyVedioChallgeNode = nil
    --     end
    -- end
end
--
function TopNode:updateUiByDeluxe(isOpen)
    self:updateUiBg(isOpen)
    self:updateOption(isOpen)
    self:clearOptionMenu()
    self:updateGemBg(isOpen)
    self:updateCoinBg(isOpen)
end
-- 更新设置
function TopNode:updateOption(bOpenDeluxe)
    local sp_Option = self:findChild("sp_option")
    bOpenDeluxe = bOpenDeluxe or globalData.deluexeClubData:getDeluexeClubStatus()
    if bOpenDeluxe then
        util_changeTexture(sp_Option, "GameNode/ui_lobbyTop/Options_btn_deluxe.png")
    else
        util_changeTexture(sp_Option, "GameNode/ui_lobbyTop/Options_btn_an.png")
    end
end

function TopNode:clearOptionMenu()
    if self.m_menu then
        self.m_menu:removeFromParent()
        self.m_menu = nil
    end
end

function TopNode:updateGemBg(bOpenDeluxe)
    local sp_gemBg = self:findChild("lab_gem_bg")
    bOpenDeluxe = bOpenDeluxe or globalData.deluexeClubData:getDeluexeClubStatus()
    if bOpenDeluxe then
        util_changeTexture(sp_gemBg, "GameNode/ui_lobbyTop/ui_lobby_gemBg_dc.png")
    else
        util_changeTexture(sp_gemBg, "GameNode/ui_lobbyTop/ui_lobby_gemBg.png")
    end
end

function TopNode:updateCoinBg(bOpenDeluxe)
    bOpenDeluxe = bOpenDeluxe or globalData.deluexeClubData:getDeluexeClubStatus()
    if bOpenDeluxe then
        util_changeTexture(self.m_coinNode, "GameNode/ui_lobbyTop/ui_lobby_coinBg_deluxe.png")
    else
        util_changeTexture(self.m_coinNode, "GameNode/ui_lobbyTop/ui_lobby_coinBg.png")
    end
end

function TopNode:updateUiBg(bOpenDeluxe)
    -- 边框
    local spNormalBgL = self:findChild("sp_bg")
    local spNormalBgR = self:findChild("sp_bg_0")

    local spDeluxeBgL = self:findChild("sp_dcbg")
    local spDeluxeBgR = self:findChild("sp_dcbg_0")
    if tolua.isnull(spDeluxeBgL) then
        -- bugly有人  attempt to index local 'spDeluxeBgL' (a nil value)
        return
    end

    bOpenDeluxe = bOpenDeluxe or globalData.deluexeClubData:getDeluexeClubStatus()

    spNormalBgL:setVisible(not bOpenDeluxe)
    spNormalBgR:setVisible(not bOpenDeluxe)
    spDeluxeBgL:setVisible(bOpenDeluxe)
    spDeluxeBgR:setVisible(bOpenDeluxe)

    -- local spDeluxeSlideL = self:findChild("main_dcmap_up_bg10_3")
    -- local spDeluxeSlideR = self:findChild("main_dcmap_up_bg10_3_0")
    -- spDeluxeSlideL:setVisible(bOpenDeluxe)
    -- spDeluxeSlideR:setVisible(bOpenDeluxe)

    local concatStr = bOpenDeluxe and "_deluxe" or ""

    -- buyBg
    local spBuyBg = self:findChild("buy_bg")
    local buyBgImgPath = "GameNode/UI_lobby_bottom_loding_2023/buy_bg" .. concatStr .. ".png"
    util_changeTexture(spBuyBg, buyBgImgPath)

    -- home 按钮
    local homeNImgPath = "GameNode/ui_top/btn_home_up" .. concatStr .. ".png"
    local homePImgPath = "GameNode/ui_top/btn_home_down" .. concatStr .. ".png"
    util_changeTexture(self.m_sp_faceTop, homeNImgPath)
    util_changeTexture(self.m_sp_faceTop_0, homePImgPath)

    -- 经验背景
    local progress_bg = self:findChild("main_progress_bg_13")
    if progress_bg then
        local _imgPath = "GameNode/ui_lobbyTop/ui_lobby_levelBottom" .. concatStr .. ".png"
        util_changeTexture(progress_bg, _imgPath)
    end

    -- option
    if tolua.isnull(self.m_menu) then
        return
    end
    -- if self.m_menu.updateDeluxeUI then
    --     -- bugly有人 attempt to call method 'updateDeluxeUI' (a nil value)
    --     self.m_menu:updateDeluxeUI(bOpenDeluxe)
    -- end
end

function TopNode:initLevelTips()
    self.m_levelTips = util_createView("views.lobby.LevelTips", 1)
    self.m_showTipsNode:addChild(self.m_levelTips)
end

function TopNode:initProcessInfo()
    self.m_bar_level = self:findChild("Bar_level")
    self.m_bar_level_0 = self:findChild("Bar_level_0")
    local currProVal = globalData.userRunData.currLevelExper
    local totalProVal = globalData.userRunData:getPassLevelNeedExperienceVal()
    local value = math.floor((currProVal / totalProVal) * 100)
    self.m_bar_level:setPercent(value)
    self.m_bar_level_0:setPercent(value)

    self.m_level_Particle_1_1 = self:findChild("level_Particle_1_1")
    self.m_level_Particle_1_2 = self:findChild("level_Particle_1_2")
    self.m_level_Particle_2_1 = self:findChild("level_Particle_2_1")
    self.m_level_Particle_2_2 = self:findChild("level_Particle_2_2")

    if value > 100 then
        value = 100
    end

    self.m_panel_eff = self:findChild("panel_eff")
    local progessParent = self:findChild("processNode")

    self.m_panel_eff_ori_width = 199 -- 跟csd中尺寸保持一致
    self.m_panel_eff_ori_height = 40 -- 跟csd中尺寸保持一致

    -- 设置进度条的遮罩处理
    local mask = display.newSprite("#GameNode/ui_lobbyTop/ui_lobby_levelBar.png")
    local clip_node = cc.ClippingNode:create()
    clip_node:setAlphaThreshold(0)
    clip_node:setStencil(mask)
    mask:setPositionX(mask:getContentSize().width * 0.5)
    clip_node:setPosition(0, 0)
    clip_node:setAnchorPoint(0, 0.5)
    progessParent:addChild(clip_node)
    -- self.m_panel_eff:retain()
    -- self.m_panel_eff:removeFromParent()
    -- clip_node:addChild(self.m_panel_eff)
    util_changeNodeParent(clip_node, self.m_panel_eff)
    self.m_panel_eff:setPosition(0, 0)
    self.m_panel_eff:setContentSize(cc.size(self.m_panel_eff_ori_width * value * 0.01, self.m_panel_eff_ori_height))
    -- self.m_panel_eff:release()
end

-- function TopNode:initBoostIcon()
--     local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
--     if vipBoost and vipBoost:isOpenBoost() then
--         self.m_boostImg:setVisible(true)
--     else
--         self.m_boostImg:setVisible(false)
--     end
-- end

--[[
    @desc: 初始化按钮点击回调
    time:2019-04-25 17:31:01
    @return:
]]
function TopNode:initBtnClicks()
    self:addClick(self.btn_layout_fb)
    self:addClick(self.btn_layout_vip)
    self:addClick(self.m_btn_layout_buy_deal)
    self:addClick(self.btn_layout_buy)
    self:addClick(self.btn_layout_buy_0)
    self:addClick(self.btn_layout_buy_gem)
    self:addClick(self.btn_layout_option)
    self:addClick(self.btn_levelRoad)
    self:addClick(self.btn_showTips)
    self:addClick(self.btn_showFreeCoins)
    self:addClick(self.btn_showFreeCoins_0)
    if globalData.GameConfig:getHotTodayConfigs() then
        self:addClick(self.btn_showSale)
    end
    self.btn_showFreeCoins:setVisible(false)
    self.btn_showFreeCoins_0:setVisible(false)
end

function TopNode:initPiggys()
    self.m_piggyShowIndex = 1
    self.m_piggySitchTime = 8
    self.m_piggyList = {}
    self:initActivityPiggyNodes()
    self:initCoinPiggyNode()
    -- 显示第一个，注意初始化的优先级
    self.m_piggysLen = table.nums(self.m_piggyList or {})
    if self.m_piggysLen > 0 then
        for i = 1, #self.m_piggyList do
            self.m_piggyList[i]:setVisible(i == self.m_piggyShowIndex)
        end
    end
end

function TopNode:getPiggyNode(_name)
    if _name == nil or _name == "" then
        return nil
    end
    if self.m_piggyList and #self.m_piggyList > 0 then
        for i=1,#self.m_piggyList do
            local piggy = self.m_piggyList[i]
            if piggy:getName() == _name then
                return piggy
            end
        end
    end
    return nil
end

-- 活动小猪
function TopNode:initActivityPiggyNodes()
    local refs = TrioPiggyConfig.TrioPiggyEffectiveRefs
    if refs and #refs > 0 then
        for i=1,#refs do
            local ref = refs[i]
            local mgr = G_GetMgr(ref)
            if mgr and mgr.createTopPigNode then
                local piggy = mgr:createTopPigNode()
                if piggy then
                    self:findChild("node_piggyeffect"):addChild(piggy)
                    piggy:setName(ref)
                    table.insert(self.m_piggyList, piggy)
                end
            end
        end
    end
end

-- 金币小猪
function TopNode:initCoinPiggyNode()
    local piggy = G_GetMgr(G_REF.PiggyBank):createTopPigNode()
    self:findChild("node_piggyeffect"):addChild(piggy)
    piggy:setScale(0.9)
    piggy:setName("PiggyNode")
    table.insert(self.m_piggyList, piggy)
end

function TopNode:addPiggyShowIndex()
    self.m_piggyShowIndex = self.m_piggyShowIndex + 1
    if self.m_piggyShowIndex > self.m_piggysLen then
        self.m_piggyShowIndex = 1
    end
end

function TopNode:refreshPiggyNode()
    if self.m_piggysLen > 1 then
        if not self.m_piggyTime then
            self.m_piggyTime = self.m_piggySitchTime
        end
        self.m_piggyTime = self.m_piggyTime - 1
        if self.m_piggyTime <= 0 then
            self.m_piggyTime = self.m_piggySitchTime
            local curPiggy = self.m_piggyList[self.m_piggyShowIndex]
            if not tolua.isnull(curPiggy) then
                curPiggy:playHide(function()
                    if not tolua.isnull(curPiggy) then
                        curPiggy:setVisible(false)
                    end
                end)
            end
            self:addPiggyShowIndex()
            local nextPiggy = self.m_piggyList[self.m_piggyShowIndex]
            if not tolua.isnull(nextPiggy) then
                nextPiggy:setVisible(true)
                nextPiggy:playShow()
            end
        end
    else
        self.m_piggyShowIndex = 1
        local curPiggy = self.m_piggyList[self.m_piggyShowIndex]
        curPiggy:setVisible(true)
        curPiggy:updateUIStatus()
    end

    -- if not self.m_chipPiggy then
    --     self:initChipPiggyNode()
    --     return
    -- end
    -- if not tolua.isnull(self.m_chipPiggy) then
    --     if not self.m_piggyTime then
    --         self.m_piggyTime = self.m_piggySitchTime
    --     end
    --     self.m_piggyTime = self.m_piggyTime - 1
    --     if self.m_piggyTime <= 0 then
    --         self.m_piggyTime = self.m_piggySitchTime
    --         if self.m_chipPiggy:isVisible() then
    --             self.m_chipPiggy:playHide()
    --             self.m_piggyBank:playShow()
    --         else
    --             self.m_chipPiggy:playShow()
    --             self.m_piggyBank:playHide()
    --         end
    --     end
    -- else
    --     self.m_chipPiggy = nil
    --     self.m_piggyTime = nil
    -- end
end

--[[
    @desc: 初始化限时促销节点
    time:2019-04-25 17:17:29
    @return:
]]
function TopNode:initLimitedSale()
    -- self.m_guang1 = self:findChild("guang1")
    -- self.m_guang2 = self:findChild("guang2")
    if not globalData.GameConfig:getHotTodayConfigs() then
        local childs = self.m_specialDealNode:getChildren()
        for i = 1, #childs do
            childs[i]:setVisible(false)
        end
        self:findChild("Node_hottoday"):setVisible(false)
        self.Limited_time_down:setVisible(true)
        self.btn_showSale:setTouchEnabled(false)
    else
        local childs = self.m_specialDealNode:getChildren()
        for i = 1, #childs do
            childs[i]:setVisible(true)
        end
        -- self.m_guang1:setVisible(false)
        -- self.m_guang2:setVisible(true)
        self:findChild("Node_hottoday"):setVisible(true)
        self.Limited_time_up:setVisible(true)
        self.Limited_time_down:setVisible(false)
        self.btn_showSale:setTouchEnabled(true)
        self:updateHotTodayNum()
    end

    -- self.limited_time_eft = self:findChild("Limited_time_eft")  -- 注销掉限时促销 2019-04-25 17:19:40
    -- self.limitedTimeSpecial = util_createView("views.lobby.LimitedTimeSpecial")
    -- self.limited_time_eft:addChild(self.limitedTimeSpecial)
end

function TopNode:updateHotTodayNum()
    local spHotNum = self:findChild("Sprite_hotNum")
    local lbHotNum = self:findChild("hotTodayNum")
    local activityData = G_GetActivityDataByRef(ACTIVITY_REF.Entrance)
    if not activityData then
        spHotNum:setVisible(false)
        return
    end

    local _count = activityData:getShowRedPointCount()
    spHotNum:stopAllActions()
    local gameData = G_GetMgr(ACTIVITY_REF.Notification):getRunningData()
    if gameData then
        local updateTimeLable = function()
            local count = _count
            local gameData = G_GetMgr(ACTIVITY_REF.Notification):getRunningData()
            if gameData then
                local cdExpireAt = gameData:getCdExpired()
                if cdExpireAt <= util_getCurrnetTime() then
                    count = count + 1
                end
            else
                spHotNum:stopAllActions()
            end
    
            if count > 0 then
                spHotNum:setVisible(true)
                lbHotNum:setString("" .. count)
            else
                spHotNum:setVisible(false)
            end
        end
        util_schedule(spHotNum, updateTimeLable, 1)
        updateTimeLable()
    else
        if _count > 0 then
            spHotNum:setVisible(true)
            lbHotNum:setString("" .. _count)
        else
            spHotNum:setVisible(false)
        end
    end 
end

function TopNode:updateVipBtnSp(spVip, spPath)
    if spVip then
        local path = spPath
        if path ~= "" and util_IsFileExist(path) then
            util_changeTexture(spVip, path)
        end
    end
end

function TopNode:initMulExp()
    --levelDash优先级高于其他
    local checkDoube = globalData.buffConfigData:checkBuff()
    local bLevelRushOpen = gLobalLevelRushManager:pubGetLevelRushBuffOpen()
    if not tolua.isnull(self.m_levelDashTipView) then
        self.m_levelDashTipView:removeFromParent()
        self:findChild("level_star_14"):setVisible(true)
        self:findChild("Sprite_1"):setVisible(true)
        self.m_levelDashTipView = nil
    end

    if bLevelRushOpen then
        if not tolua.isnull(self.m_mul) then
            self.m_mul:removeFromParent()
            self.m_mul = nil
        end
        self:showLevelDashTip()

        if checkDoube then
            self.m_bar_level:setVisible(false)
            self.m_bar_level_0:setVisible(true)
            self:showLevelParticle("exp")
        else
            self.m_bar_level_0:setVisible(false)
            self.m_bar_level:setVisible(true)
            self:showLevelParticle("normal")
        end
    else
        if checkDoube then
            if self.m_mul == nil or self.m_mul.m_changeUI == true then
                local x2 = self:findChild("x2")
                self.m_mul = util_createView("views.mulReward.ExpMulReward")
                x2:addChild(self.m_mul)
                self.m_mul:setOverFunc(
                    function()
                        self.m_mul = nil
                    end
                )
                self.m_bar_level:setVisible(false)
                self.m_bar_level_0:setVisible(true)
                self:showLevelParticle("exp")
            end
        else
            self.m_bar_level_0:setVisible(false)
            self.m_bar_level:setVisible(true)
            self:showLevelParticle("normal")
        end
    end
end

--获取当前buff类型
function TopNode:getCurBuff()
    if self.m_mul == nil or not self.m_mul.getCurBuff then
        return BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN
    end

    return self.m_mul:getCurBuff()
end

function TopNode:showLevelParticle(type)
    if type == "normal" then
        self.m_level_Particle_1_1:setVisible(true)
        self.m_level_Particle_1_2:setVisible(true)
        self.m_level_Particle_2_1:setVisible(false)
        self.m_level_Particle_2_2:setVisible(false)
    elseif type == "exp" then
        self.m_level_Particle_1_1:setVisible(false)
        self.m_level_Particle_1_2:setVisible(false)
        self.m_level_Particle_2_1:setVisible(true)
        self.m_level_Particle_2_2:setVisible(true)
    end
end

function TopNode:stopCoinUpdateAction()
    if self.m_showCoinUpdateAction ~= nil then
        self:stopAction(self.m_showCoinUpdateAction)
        self.m_showCoinUpdateAction = nil
    end
end

function TopNode:removeBuff()
    if self.m_mul then
        self.m_mul:removeFromParent()
        self.m_mul = nil
    end
end

function TopNode:onExit()
    self:removeBuff()
    if self.m_menu ~= nil and self.m_menu:getParent() ~= nil then
        self.m_menu:removeFromParent()
        self.m_menu = nil
    end

    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        _mgr:removeCollectNodeInfo("MenuTop")
    end

    gLobalNoticManager:removeAllObservers(self)

    globalData.lobbyVedioNode = nil
    globalData.lobbyVedioChallgeNode = nil

    self:stopCoinUpdateAction()
end

-- function TopNode:getCurCoinNum()
--     local coinNumLabel = self.m_coinLabel
--     local coinStr = string.gsub(coinNumLabel:getString(), ",", "")
--     local curCoinNum = 0
--     if coinStr ~= nil then
--         curCoinNum = tonumber(coinStr)
--     end
--     return curCoinNum
-- end

function TopNode:recordLastWinCoins(targetCoin)
    -- local curCoinNum = self:getCurCoinNum()
    local updateCoin = toLongNumber(targetCoin - self.m_curCoin)
    if updateCoin > toLongNumber(0) then
        globalData.recordLastWinCoin = updateCoin
    end
end

--响应金币刷新
--
function TopNode:notifyUpdateCoin(targetCoin, isShowAnim)
    -- self:stopCoinUpdateAction()

    --记录下最近一次的赢钱
    self:recordLastWinCoins(targetCoin)

    if isShowAnim == false then
        self:updateCoinLabel(false, targetCoin)
    else
        -- self.m_showTargetCoin = targetCoin

        -- local curCoinNum = self:getCurCoinNum()
        -- self.m_curCoin = curCoinNum or 0

        local updateCoin = toLongNumber(targetCoin - self.m_curCoin)
        if updateCoin > toLongNumber(0) then
            --普通收集金币音乐
            if globalData.coinsSoundType == 0 then
                --赢钱音乐
                gLobalSoundManager:playSound("Sounds/sound_coin_reward.mp3")
            elseif globalData.coinsSoundType == 1 then
            else
                --不播放音乐
            end
        end
        -- 计算金币变化步长
        if isBN() then
            self.m_lCoinRiseNum = toLongNumber(util_replaceNum2Rand("" .. (updateCoin / 30)))
        else
            updateCoin = tonumber("" .. updateCoin)
            self.m_lCoinRiseNum = math.ceil(updateCoin / 30) -- 30帧变化完成， 也就是0.5秒
        end

        self:updateCoinLabel(true, targetCoin)
    end
    globalData.coinsSoundType = 0
end

---
-- @param playUpdateAnim bool 是否播放金币变化动画
-- @param updateCoinCount number 金币变化数量， 这个与是否播放动画成对出现
--
-- 这里已经更改了COIN_NUM的数量，只是通知了变化
--
function TopNode:updateCoinLabel(playUpdateAnim, targetCoinCount)
    if tolua.isnull(self) then
        return
    end

    -- 转成 LongNumber
    targetCoinCount = toLongNumber(targetCoinCount)

    self:stopCoinUpdateAction()

    self.m_showTargetCoin = targetCoinCount
    -- 记录下显示金币数量
    globalData.topUICoinCount = targetCoinCount

    local _updateCoinsLabel = function(_coins)
        self.m_curCoin = _coins
        local coinNumLabel = self.m_coinLabel
        coinNumLabel:setString(util_formatBigNumCoins(_coins))
        util_scaleCoinLabGameLayerFromBgWidth(coinNumLabel, COINS_LABEL_WIDTH, COINS_DEFAULT_SCALE)
    end

    local setFinalValue = function(nValue)
        local mgr = G_GetMgr(G_REF.Currency)
        if mgr then
            mgr:setCoins(nValue)
        end
    end

    if playUpdateAnim == true then
        -- self.m_showCoinHandlerID = scheduler.scheduleUpdateGlobal(function(delayTime)
        -- end)

        local _curCoins = self.m_curCoin
        self.m_showCoinUpdateAction =
            schedule(
            self,
            function()
                _curCoins = _curCoins + self.m_lCoinRiseNum

                -- 判断是否到达目标
                if (toLongNumber(self.m_lCoinRiseNum) <= toLongNumber(0) and _curCoins <= self.m_showTargetCoin) or (toLongNumber(self.m_lCoinRiseNum) >= toLongNumber(0) and _curCoins >= self.m_showTargetCoin) then
                    _curCoins = self.m_showTargetCoin
                    setFinalValue(_curCoins)
                    self:stopCoinUpdateAction()
                end

                _updateCoinsLabel(_curCoins)
            end,
            1 / 60
        )
    else
        setFinalValue(self.m_showTargetCoin)

        if globalNoviceGuideManager:isNoobUsera() then --新用户
            if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.initIcons.id) then
                --新手金币指引没完成不刷新金币
                -- self.m_curCoin = self.m_showTargetCoin
                local coins = LongNumber.max(globalData.userRunData.coinNum - globalData.constantData.NOVICE_SERVER_INIT_COINS, 0)
                _updateCoinsLabel(coins)
                self.m_showTargetCoin = coins
                globalData.topUICoinCount = coins
                setFinalValue(globalData.userRunData.coinNum)
                return
            end
        end

        _updateCoinsLabel(self.m_showTargetCoin)
    end
end

-- function TopNode:updateGemLabel(isPlayAction, gemNum)
--     self.m_gemLabel:setString(util_getFromatMoneyStr(gemNum))
--     util_scaleCoinLabGameLayerFromBgWidth(self.m_gemLabel, GEMS_LABEL_WIDTH, GEMS_DEFAULT_SCALE)
-- end

function TopNode:checkGuideClearCoins()
    if self.m_coinLabel then
        local guideBoxCoins = math.max(globalData.constantData.NOVICE_SERVER_INIT_COINS - FIRST_LOBBY_COINS, 0)
        local userShowCoins = toLongNumber(globalData.userRunData.coinNum - guideBoxCoins)
        self.m_coinLabel:setString(util_formatBigNumCoins(userShowCoins))
        globalData.topUICoinCount = userShowCoins
        self.m_showTargetCoin = userShowCoins
        util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, COINS_LABEL_WIDTH, COINS_DEFAULT_SCALE)
    end
end

function TopNode:checkGuideClearGems()
    if self.m_gemLabel then
        self.m_gemLabel:setString(0)
        -- globalData.topUICoinCount = FIRST_LOBBY_COINS
        -- self.m_showTargetCoin = FIRST_LOBBY_COINS
        self.m_showTargetGem = 0
        util_scaleCoinLabGameLayerFromBgWidth(self.m_gemLabel, GEMS_LABEL_WIDTH, GEMS_DEFAULT_SCALE)
    end
end

function TopNode:updateLevelProcess()
    local curLevel = globalData.userRunData.levelNum
    self.m_txtLevel:setString(curLevel)

    local currProVal = globalData.userRunData.currLevelExper
    local totalProVal = globalData.userRunData:getPassLevelNeedExperienceVal()
    local value = math.floor((currProVal / totalProVal) * 100)
    if self.m_bar_level then
        self.m_bar_level:setPercent(value)
    end
    if self.m_bar_level_0 then
        self.m_bar_level_0:setPercent(value)
    end
    if self.m_panel_eff then
        self.m_panel_eff:setContentSize(cc.size(self.m_panel_eff_ori_width * value * 0.01, self.m_panel_eff_ori_height))
    end
end

function TopNode:updateCuyFlyPos()
    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        local coinNode = self:findChild("coin_dollar")
        _mgr:addCollectNodeInfo(FlyType.Coin, coinNode, "MenuTop", false)
        local gemNode = self:findChild("gem_dollar")
        _mgr:addCollectNodeInfo(FlyType.Gem, gemNode, "MenuTop", false)
    end
end

function TopNode:onEnterFinish()
    TopNode.super.onEnterFinish(self)
    
    self:updateCuyFlyPos()
end

function TopNode:onEnter()
    TopNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- self:updateHotTodayNum()
            self:initLimitedSale()
        end,
        ViewEventType.NOTIFY_ENTRENCE_HOT_TODAY_NUM
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:refreshAdsNode()
        end,
        ViewEventType.NOTIFY_AFTER_REQUEST_ZERO_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params[1] == PushViewPosType.LobbyPos then
                self:refreshAdsNode()
            end
        end,
        ViewEventType.NOTIFY_ADS_REWARDS_END
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- self:updateHotTodayNum()
            self:initLimitedSale()
        end,
        ViewEventType.NOTIFY_ENTRENCE_CLOSE_LAYER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:initMulExp()
        end,
        ViewEventType.NOTIFY_MULEXP_END
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            if questConfig and questConfig.m_isQuestLobby then
                return
            end
            if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterQuestLayer() then
                return 
            end
            if params == PushViewTipsType.PushViewTipsType_ShopReward then
                self:openShopTishi()
            end
        end,
        ViewEventType.NOTIFY_NOVICEGUIDE_SHOW
    )

    self:registerEvents()
    self.tishizhezhao = true
    schedule(
        self,
        function()
            -- 商城奖励刷新
            if self.m_alternate_time == 0 then --每日礼盒
                if globalData.shopRunData:getShpGiftCD() == 0 then
                    self:showFreecoinsAction(true)
                    self:showSuperSpinAction(false)
                    self:showScratchAction(false)
                else
                    self:showFreecoinsAction(false)
                    self:showSuperSpinAction(false)
                    self:showScratchAction(false)
                    local luckySpinLevel = globalData.shopRunData:getLuckySpinLevel()
                    if luckySpinLevel <= 6 then
                        self:showSuperSpinAction(true)
                    else
                        local scrtchMgr = G_GetMgr(ACTIVITY_REF.ScratchCards)
                        if scrtchMgr and scrtchMgr:isCanShowLobbyLayer() then
                            self:showScratchAction(true)
                        end
                    end
                end
            elseif self.m_alternate_time == AlternateTime then --Super Spin
                local luckySpinLevel = globalData.shopRunData:getLuckySpinLevel()
                if luckySpinLevel <= 6 then
                    self:showSuperSpinAction(true)
                    self:showFreecoinsAction(false)
                    self:showScratchAction(false)
                else
                    self:showFreecoinsAction(false)
                    self:showSuperSpinAction(false)
                    self:showScratchAction(false)
                    local scrtchMgr = G_GetMgr(ACTIVITY_REF.ScratchCards)
                    if scrtchMgr and scrtchMgr:isCanShowLobbyLayer() then
                        self:showScratchAction(true)
                    else
                        if globalData.shopRunData:getShpGiftCD() == 0 then
                            self:showFreecoinsAction(true)
                        end
                    end
                end
            elseif self.m_alternate_time == AlternateTime * 2 then --刮刮卡
                local scrtchMgr = G_GetMgr(ACTIVITY_REF.ScratchCards)
                if scrtchMgr and scrtchMgr:isCanShowLobbyLayer() then
                    self:showScratchAction(true)
                    self:showSuperSpinAction(false)
                    self:showFreecoinsAction(false)
                else
                    self:showFreecoinsAction(false)
                    self:showSuperSpinAction(false)
                    self:showScratchAction(false)
                    if globalData.shopRunData:getShpGiftCD() == 0 then
                        self:showFreecoinsAction(true)
                    else
                        local luckySpinLevel = globalData.shopRunData:getLuckySpinLevel()
                        if luckySpinLevel <= 6 then
                            self:showSuperSpinAction(true)
                        end
                    end
                end
            end
            self.m_alternate_time = self.m_alternate_time + 1
            if self.m_alternate_time >= AlternateTime * 3 then
                self.m_alternate_time = 0
            end

            --促销倒计时刷新
            self:updateBasicSale()
            --小猪切换倒计时
            self:refreshPiggyNode()
        end,
        1
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:watchJackpotPush()
        end,
        ViewEventType.NOTIFY_JACKPOT_PUSH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:initMulExp()
        end,
        ViewEventType.NOTIFY_LEVEL_DASH_TIMEOUT
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:initMulExp()
        end,
        ViewEventType.NOTIFY_LEVEL_RUSH_REFRESH_EXP_BUFF
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:refreshOptionRedNode()
        end,
        ViewEventType.NOTIFY_MENUNODE_CHANGED
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target)
            self:refreshOptionRedNode()
        end,
        ViewEventType.NOTIFY_CHECK_NEWMESSAGE
    )

    --关闭个人信息界面
    gLobalNoticManager:addObserver(
        self,
        function(self, _index)
            self:updateHeadRedPoint()
            self:updateHead()
        end,
        ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER
    )

    self.popViewCount = 0
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if not tolua.isnull(self) then
                self:checkAddEntrenceGuide(params.node)
            end
        end,
        ViewEventType.NOTIFY_SHOW_UI
    )

    -- 接受到quest界面关闭消息
    gLobalNoticManager:addObserver(
        self,
        function(self, _index)
            self:setActive(false)
        end,
        ViewEventType.NOTIFY_ON_GAMETOP_ACTIVE
    )

    -- 接受到quest界面关闭消息
    gLobalNoticManager:addObserver(
        self,
        function(self, _index)
            self:setActive(true)
        end,
        ViewEventType.NOTIFY_ON_GAMETOP_INACTIVE
    )

    -- 刷新经验值
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateLevelProcess(param)
        end,
        ViewEventType.NOTIFY_UPDATE_EXP_PRO
    )

    -- 隐藏新手七日目标活动入口
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:hideNewUser7Day()
        end,
        ViewEventType.NOTIFY_HIDE_NEW_USER_7DAY_ENTRANCE
    )

    -- 头像框资源下载结束
    gLobalNoticManager:addObserver(
        self,
        function()
            self:updateHead()
        end,
        ViewEventType.NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE
    )

    -- self:updateVip() --刷新vip 放在注册消息后面
    self:refreshOptionRedNode() -- 刷新一次红点信息
end

function TopNode:showFreecoinsAction(_isShow)
    if not self.m_shop_freecoins_Action then
        return
    end
    local isShow = _isShow or false
    if isShow then
        if not self.m_shop_freecoins_Action:isVisible() then
            self.m_shop_freecoins_Action:setVisible(true)
            self.m_shop_freecoins_Action:runCsbAction("animation0", true)
            if not globalData.isShopTishi then
                globalData.isShopTishi = true
                globalNoviceGuideManager:addRepetitionQueue(NOVICEGUIDE_ORDER.shopReward3)
                globalNoviceGuideManager:attemptShowRepetition()
            end
        end
    else
        if self.m_shop_freecoins_Action:isVisible() then
            self.m_shop_freecoins_Action:setVisible(false)
            self.m_shop_freecoins_Action:runCsbAction("animation0", false)
            globalData.isShopTishi = false
        end
    end
end

function TopNode:showSuperSpinAction(_isShow)
    if not self.m_shop_lucky_spin then
        return
    end
    local isShow = _isShow or false
    if isShow then
        self.m_shop_lucky_spin:setVisible(true)
    else
        self.m_shop_lucky_spin:setVisible(false)
    end
end

function TopNode:showScratchAction(_isShow)
    if not self.m_shop_scratch_card then
        return
    end
    local isShow = _isShow or false
    if isShow then
        self.m_shop_scratch_card:setVisible(true)
    else
        self.m_shop_scratch_card:setVisible(false)
    end
end

function TopNode:checkAddEntrenceGuide(node)
    self.popViewCount = self.popViewCount + 1
    self:addEntrenceGuide(true)
    addExitListenerNode(
        node,
        function()
            if not tolua.isnull(self) then
                self.popViewCount = self.popViewCount - 1
                util_afterDrawCallBack(
                    function()
                        if not tolua.isnull(self) and self.popViewCount == 0 then
                            self:addEntrenceGuide(false)
                        end
                    end
                )
            end
        end
    )
end

function TopNode:checkSmallTip()
    if (self.m_menu and self.m_menu.isShorten and not self.m_menu:isShorten()) or (self.m_levelTips and self.m_levelTips.m_isAction) then
        return false
    end
    if self.m_jackpotPushView and self.m_jackpotPushView.isOnShow then
        return false
    end
    if gLobalViewManager:getHasShowUI() then
        return false
    end
    return true
end

function TopNode:watchJackpotPush()
    if self:checkSmallTip() then
        if globalData.jackpotPushList and #globalData.jackpotPushList > 0 then
            local jackPotPushView = self.m_jackpotPushView
            if jackPotPushView == nil then
                jackPotPushView = util_createView("views.jackpotPushTip.JackpotPushTip")
                self.m_jackpotPushView = jackPotPushView
                self:findChild("NodeJackPot"):addChild(jackPotPushView)
                local distanceX = display.width / globalData.lobbyScale - CC_DESIGN_RESOLUTION.width
                distanceX = distanceX > 0 and distanceX or 0
                local size = jackPotPushView:getMaxSize()
                jackPotPushView:setPosition(distanceX / 2 + size.width / 2 + 50, -size.height / 2)
            end
            jackPotPushView:setVisible(true)
            jackPotPushView:setData()
        end
    end
end

--检测是否开启促销
function TopNode:checkOpenSale()
    if self.m_isOpenSale then
        return
    end
    self.m_isOpenSale = true
    self.two_buttom:setVisible(true)
    --setVisible(true)

    self.m_one_buttom:setVisible(false)
    --self.m_one_buttom_tx:setVisible(false)

    self.m_btn_layout_buy_deal:setVisible(true)
end
--检测是否可以关闭促销
function TopNode:checkCloseSale()
    if not self.m_isOpenSale then
        return
    end
    self.m_isOpenSale = nil
    self.two_buttom:setVisible(false)
    --self.two_buttom_tx:setVisible(false)

    self.m_one_buttom:setVisible(true)
    --self.m_one_buttom_tx:setVisible(true)

    self.m_btn_layout_buy_deal:setVisible(false)
    globalData.saleRunData:setShowTopeSale(false)
end

--刷新促销
function TopNode:updateBasicSale()
    local firstMultiData = G_GetMgr(G_REF.FirstSaleMulti):getData()
    if firstMultiData and not firstMultiData:isOver() and not firstMultiData:isRunning() then
        self:checkCloseSale()
        return
    end

    local firstCommSaleData = G_GetMgr(G_REF.FirstCommonSale):getData()
    if firstCommSaleData and not firstCommSaleData:isCanShow() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FIRST_SALE_BUYSUCCESS)
        self:checkCloseSale()
        return
    end

    local routineSaleData = G_GetMgr(G_REF.RoutineSale):getRunningData()
    if routineSaleData then
        globalData.saleRunData:setShowTopeSale(true)
    end

    if not globalData.saleRunData:isShowTopSale() then
        self:checkCloseSale()
        return
    end
    self:checkOpenSale()

    local saleData = G_GetMgr(G_REF.SpecialSale):getRunningData()
    if firstCommSaleData then
        saleData = firstCommSaleData
    elseif routineSaleData then
        saleData = routineSaleData
    end

    if firstMultiData and firstMultiData:isRunning() then
        local leftTime = util_getLeftTime(firstMultiData:getSaleExpireAt() * 1000)
        self:updateDeal(leftTime)
    elseif saleData then
        -- if leftTime <= 0 then
        --     self:checkCloseSale()
        -- end
        local leftTime = saleData:getLeftTime()
        self:updateDeal(leftTime, firstCommSaleData ~= nil)
    else
        self:checkCloseSale()
    end
end

-- _bFirstSaleGift 是否是首冲礼包 促销
function TopNode:updateDeal(time, _bFirstSaleGift)
    local Node_deal = self:findChild("Node_deal")

    local dealView_firstSaleGift = Node_deal:getChildByName("DealView_FirstSaleGift")
    local dealView = Node_deal:getChildByName("DealView")
    if _bFirstSaleGift and not dealView_firstSaleGift then
        dealView_firstSaleGift = util_createView("views.gameviews.DealTopFirstSaleGiftNode")
        Node_deal:addChild(dealView_firstSaleGift)
        dealView_firstSaleGift:setName("DealView_FirstSaleGift")
    elseif not dealView and not _bFirstSaleGift then
        if dealView_firstSaleGift then
            -- 首充礼包 切换到 常规促销 移除 首冲礼包
            dealView_firstSaleGift:removeSelf()
            dealView_firstSaleGift = nil
        end
        dealView = util_createView("views.gameviews.DealTopNode")
        Node_deal:addChild(dealView)
        dealView:setName("DealView")
    end
    
    if dealView_firstSaleGift then
        dealView_firstSaleGift:setVisible(_bFirstSaleGift)
        dealView_firstSaleGift:updateCountDown(time)
    end
    if dealView then
        dealView:setVisible(not _bFirstSaleGift)
        dealView:updateCountDown(time)
    end
end

function TopNode:openShopTishi()
    self.m_isOpenShopTishi = true
    local sp_tips_A = self:findChild("sp_tips_A")
    local sp_tips_B = self:findChild("sp_tips_B")
    if globalData.GameConfig:checkNewShowTips() then
        --A分组提示
        if sp_tips_A then
            sp_tips_A:setVisible(true)
        end
        if sp_tips_B then
            sp_tips_B:setVisible(false)
        end
    else
        --B分组提示
        if sp_tips_A then
            sp_tips_A:setVisible(false)
        end
        if sp_tips_B then
            sp_tips_B:setVisible(true)
        end
    end
    self.btn_showFreeCoins:setVisible(true)
    self.btn_showFreeCoins_0:setVisible(true)
    self:runCsbAction(
        "tishi_show",
        false,
        function()
            self.tishizhezhao = false
        end
    )
end
function TopNode:closeShopTishi(flg)
    if self.tishizhezhao then
        return
    end
    self.tishizhezhao = true
    self.m_shopRewad_force = false
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if flg then
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        self:runCsbAction(
            "tishi_over",
            false,
            function()
                self:runCsbAction("idle", true)
                self.btn_showFreeCoins:setVisible(false)
                self.btn_showFreeCoins_0:setVisible(false)
                globalNoviceGuideManager:attemptShowRepetition()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                --弹窗逻辑执行下一个事件
            end
        )
    else
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        self:runCsbAction("idle", true)
        self.btn_showFreeCoins:setVisible(false)
        self.btn_showFreeCoins_0:setVisible(false)
    end
    self.m_isOpenShopTishi = false
end

function TopNode:registerEvents()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- local curCoinNum = globalData.topUICoinCount
            local curCoinNum = self.m_showTargetCoin
            -- 判断是不是立即改变钱
            local targetCoin = toLongNumber(0)
            local isPlayAnim = false
            local isPlayEffect = true
            if tolua.type(params) == "number" or iskindof(params, "LongNumber") then
                targetCoin:setNum("" .. params)
                isPlayAnim = true
            elseif tolua.type(params) == "table" then
                if params.coins then
                    targetCoin:setNum(params.coins)
                elseif params.varCoins then
                    targetCoin:setNum(curCoinNum + params.varCoins)
                elseif (not params.coins) and (not params.varCoins) then
                    targetCoin:setNum(globalData.userRunData.coinNum)
                end
                isPlayAnim = params.isPlayEffect or false
            end
            if isPlayAnim then
                self.m_particleShuzi:setVisible(true)
                self.m_particleShuzi:resetSystem()
            end

            if curCoinNum and targetCoin and targetCoin > toLongNumber(0) and curCoinNum > targetCoin then
                isPlayAnim = false
            end
            self:notifyUpdateCoin(targetCoin, isPlayAnim)
        end,
        ViewEventType.NOTIFY_TOP_UPDATE_COIN
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local gems = params or globalData.userRunData.gemNum
            self:updateGemLabel(false, gems)
        end,
        ViewEventType.NOTIFY_TOP_UPDATE_GEM
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local refs = TrioPiggyConfig.TrioPiggyEffectiveRefs
            if refs and #refs > 0 then
                for i = 1, #refs do
                    if params.name == refs[i] then
                        self:initPiggys()
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         if not tolua.isnull(self) then
    --             self:updateVip()
    --         end
    --     end,
    --     ViewEventType.NOTIFY_UPDATE_VIP
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self:isActive() then
                self:upCoinNode(params)
            end
        end,
        ViewEventType.NOTIFY_UP_COIN_LABEL
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:refreshCoinLabel(params[1], params[2], params[3], params[4])
        end,
        ViewEventType.FRESH_COIN_LABEL
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:resetCoinNode()
        end,
        ViewEventType.RESET_COIN_LABEL
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:backLastWinCoinLable(params)
        end,
        ViewEventType.BACK_LAST_WIN_COINS
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not tolua.isnull(self) and params then
                self:refreshCoinLablePos(params)
            end
        end,
        ViewEventType.REFRESH_FLY_COINS_LABEL_POS
    )

    --新手引导提高上UI层级 使用飞金币自带的子里就弃用了
    -- gLobalNoticManager:addObserver(self,function(target,flag)
    --     if self.changeCoinsZorder then
    --         self:changeCoinsZorder(flag)
    --     end
    -- end, ViewEventType.NOTIFY_CHANGE_LOBBYCOINS_ZORDER)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self:isActive() then
                self:upGemNode(params)
            end
        end,
        ViewEventType.NOTIFY_UP_GEM_LABEL
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:refreshGemLabel(params[1], params[2], params[3], params[4])
        end,
        ViewEventType.FRESH_GEM_LABEL
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:resetGemNode()
        end,
        ViewEventType.RESET_GEM_LABEL
    )
end

function TopNode:backLastWinCoinLable(addCoins)
    --停止金币滚动
    self:stopCoinUpdateAction()

    local coinNumLabel = self.m_coinLabel
    local coinCount = globalData.userRunData.coinNum
    if addCoins and toLongNumber(addCoins) > toLongNumber(0) then
        coinCount = toLongNumber(coinCount - addCoins)
    elseif toLongNumber(globalData.recordLastWinCoin) > toLongNumber(0) then
        coinCount = toLongNumber(coinCount - globalData.recordLastWinCoin)
    end

    if coinCount > toLongNumber(0) then
        globalData.topUICoinCount = coinCount
        -- self.m_showTargetCoin = coinCount
        
        local coinStr = util_formatBigNumCoins(coinCount)
        coinNumLabel:setString(coinStr)
        util_scaleCoinLabGameLayerFromBgWidth(coinNumLabel, COINS_LABEL_WIDTH, COINS_DEFAULT_SCALE)
    end
end

function TopNode:upCoinNode(node)
    if not self.m_coinNodeParent then
        self.m_coinNodeParent = self.m_coinNode:getParent()
        self.m_coinPos = cc.p(self.m_coinNode:getPosition())
        self.m_coinScale = self.m_coinNode:getScale()
        local wdPos = self.m_coinNodeParent:convertToWorldSpace(cc.p(self.m_coinPos))
        local nodePos = node:convertToNodeSpace(wdPos)
        -- self.m_coinNode:retain()
        -- self.m_coinNode:removeFromParent()
        -- node:addChild(self.m_coinNode)
        util_changeNodeParent(node, self.m_coinNode, self.m_coinNode:getZOrder())
        -- local _scale = self.m_csbNode:getScale()
        local _scale = globalData.lobbyScale or 1
        self.m_coinNode:setScale(_scale)
        self.m_coinNode:setPosition(nodePos)
    -- self.m_coinNode:release()
    end
    -- self.m_coinNode:setOpacity(0)
    -- self.m_coinNode:runAction(cc.FadeIn:create(0.3))
end

function TopNode:refreshCoinLablePos(pos)
    if self.m_coinNodeParent then
        local nodePos = self.m_coinNode:getParent():convertToNodeSpace(pos)
        self.m_coinNode:setPosition(nodePos)
    end
end

function TopNode:refreshCoinLabel(addPre, targetCoin, addCoinTime, bShowSelfCoins)
    -- self:stopCoinUpdateAction()
    local addPerCoins = addPre
    local addCoins = addPre * addCoinTime
    local addTargetCoin = 0
    -- if not targetCoin then
        addTargetCoin = self.m_showTargetCoin + addCoins
    -- else
    --     addTargetCoin = targetCoin
    -- end
    local finalCoin = globalData.userRunData.coinNum
    if addTargetCoin > finalCoin then
        local curCoin = finalCoin - addCoins
        if toLongNumber(curCoin) >= toLongNumber(0) then
            self:updateCoinLabel(false, curCoin)
            -- self.m_curCoin = LongNumber.min(addTargetCoin - addCoins, self.m_curCoin)
            addTargetCoin = finalCoin
        else
            local errMsg = string.format("TopNode||targetCoins:%s|showCoins:%s|finalCoins:%s|addCoins:%s|", "" .. addTargetCoin, "" .. self.m_showTargetCoin, "" .. finalCoin, "" .. addCoins)
            if DEBUG == 2 then
                if isMac() then
                    assert(false, errMsg)
                end
            else
                util_sendToSplunkMsg("coinsError", errMsg)
            end
        end
    end

    -- self.m_showTargetCoin = addTargetCoin
    self.m_lCoinRiseNum = toLongNumber(util_replaceNum2Rand("" .. addPerCoins))
    self:updateCoinLabel(true, addTargetCoin)
end

function TopNode:resetCoinNode()
    if self.m_coinNodeParent then
        -- self.m_coinNode:retain()
        -- self.m_coinNode:removeFromParent()
        -- self.m_coinNodeParent:addChild(self.m_coinNode)
        util_changeNodeParent(self.m_coinNodeParent, self.m_coinNode, self.m_coinNode:getZOrder())
        self.m_coinNode:setPosition(self.m_coinPos)
        self.m_coinNode:setScale(self.m_coinScale)
        -- self.m_coinNode:release()
        self.m_coinNodeParent = nil
        self.m_coinPos = nil
        self.m_coinScale = nil
    end
    -- self.m_coinNode:runAction(cc.FadeOut:create(0.2))
end

function TopNode:refreshGemLabel(addPer, targetGem, addGemTime, bShowSelfCoins)
    local addTargetGem = 0
    if not targetGem then
        addTargetGem = self.m_showTargetGem + (addPer * addGemTime)
    else
        addTargetGem = targetGem
    end

    self.m_lGemRiseNum = addPer
    self:updateGemLabel(true, addTargetGem)
end

function TopNode:updateGemLabel(playUpdateAnim, targetGemCount)
    if tolua.isnull(self) then
        return
    end

    self:stopGemUpdateAction()

    local setFinalValue = function(nValue)
        local mgr = G_GetMgr(G_REF.Currency)
        if mgr then
            mgr:setGems(nValue)
        end
    end

    self.m_showTargetGem = targetGemCount
    -- globalData.topUICoinCount = targetCoinCount
    local _updateGemLabel = function(gemNum)
        self.m_curGem = gemNum
        if self.m_gemLabel then
            gemNum = gemNum or globalData.userRunData.gemNum
            self.m_gemLabel:setString(util_getFromatMoneyStr(gemNum))
            util_scaleCoinLabGameLayerFromBgWidth(self.m_gemLabel, GEMS_LABEL_WIDTH, GEMS_DEFAULT_SCALE)
        end
    end

    if playUpdateAnim == true then
        local _curGem = self.m_curGem
        self.m_showGemUpdateAction =
            schedule(
            self,
            function()
                _curGem = _curGem + self.m_lGemRiseNum
                -- 判断是否到达目标
                if (self.m_lGemRiseNum <= 0 and _curGem <= self.m_showTargetGem) or (self.m_lGemRiseNum >= 0 and _curGem >= self.m_showTargetGem) then
                    _curGem = self.m_showTargetGem
                    setFinalValue(_curGem)
                    self:stopGemUpdateAction()
                end

                _updateGemLabel(_curGem)
            end,
            1 / 60
        )
    else
        setFinalValue(self.m_showTargetGem)
        _updateGemLabel(self.m_showTargetGem)
    end
end

function TopNode:upGemNode(node)
    if not self.m_gemNodeParent then
        local _node = self.m_gemNode
        self.m_gemNodeParent = _node:getParent()
        self.m_gemPos = cc.p(_node:getPosition())
        self.m_gemScale = _node:getScale()
        local wdPos = self.m_gemNodeParent:convertToWorldSpace(cc.p(self.m_gemPos))
        local nodePos = node:convertToNodeSpace(wdPos)
        -- _node:retain()
        -- _node:removeFromParent()
        -- node:addChild(_node)
        util_changeNodeParent(node, _node, _node:getZOrder())
        local _scale = globalData.lobbyScale or 1
        _node:setScale(_scale)
        _node:setPosition(nodePos)
    -- _node:release()
    end
end

function TopNode:resetGemNode()
    if self.m_gemNodeParent then
        -- self.m_gemNode:retain()
        -- self.m_gemNode:removeFromParent()
        -- self.m_gemNodeParent:addChild(self.m_gemNode)
        util_changeNodeParent(self.m_gemNodeParent, self.m_gemNode, self.m_gemNode:getZOrder())
        self.m_gemNode:setPosition(self.m_gemPos)
        self.m_gemNode:setScale(self.m_gemScale)
        -- self.m_gemNode:release()
        self.m_gemNodeParent = nil
        self.m_gemPos = nil
        self.m_gemScale = nil
    end
end

function TopNode:stopGemUpdateAction()
    if self.m_showGemUpdateAction ~= nil then
        self:stopAction(self.m_showGemUpdateAction)
        self.m_showGemUpdateAction = nil
    end
end

-- fb 点击事件
function TopNode:fbBtnTouchEvent()
    if gLobalSendDataManager:getIsFbLogin() == false then
        if globalFaceBookManager:getFbLoginStatus() then
            release_print("xcyy : FbLoginStatus")
            globalData.skipForeGround = true
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_TopIcon)
        else
            gLobalSendDataManager:getNetWorkLogon().m_fbLoginPos = LOG_ENUM_TYPE.BindFB_TopIcon
            globalFaceBookManager:fbLogin()
            release_print("xcyy : FbLoginStatus fail")
        end
    else
        globalFaceBookManager:fbLogOut()
        gLobalSendDataManager:getNetWorkLogon():logoutGame()
    end
end

--点击监听
function TopNode:clickStartFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    -- if name == "btn_layout_option" then
    --     self:updateOptionBtn("start")
    -- else
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)
    -- end
    -- if name ~= "suotou_but_layout" then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUESTMSG_OPEN)
    -- end
    -- if name ~= "suotou_but_layout_0" then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSIONMSG_OPEN)
    -- end
    self.m_isTestDialog = nil

    if name == "btn_layout_fb" then
        -- if gLobalSendDataManager:getIsFbLogin() == false then
        --     self.face_book_down:setVisible(true)
        --     self.face_book:setVisible(false)
        -- end
        -- self.m_sp_faceTop_0:setVisible(true)
        -- self.m_sp_faceTop:setVisible(false)
    elseif name == "btn_layout_vip" then
        -- self.sp_vip_0:setVisible(true)
        -- self.sp_vip:setVisible(false)
    elseif name == "btn_layout_buy_deal" then
        self.m_xiao_deal_up:setVisible(false)
        self.m_xiao_deal_down:setVisible(true)
    elseif name == "btn_layout_buy" then
        self.sp_buy_0:setVisible(true)
        self.sp_buy:setVisible(false)
        self.m_xiao_buy_up:setVisible(false)
        self.m_xiao_buy_down:setVisible(true)
    elseif name == "btn_showSale" then
        self.Limited_time_down:setVisible(true)
        self.Limited_time_up:setVisible(false)
    end
end

function TopNode:clickMoveFunc(sender)
    local name = sender:getName()
    if name == "btn_showSale" then
        local rect = sender:getBoundingBox()

        local touchPos = sender:getTouchMovePosition()
        local pos = sender:getParent():convertToNodeSpace(touchPos)
        if not cc.rectContainsPoint(rect, pos) then
            self.Limited_time_down:setVisible(false)
            self.Limited_time_up:setVisible(true)
        end
    end
end

--结束监听
function TopNode:clickEndFunc(sender)
    if gLobalSendDataManager:getIsFbLogin() == false then
        self.face_book_down:setVisible(false)
    end

    -- self.sp_vip_0:setVisible(false)
    -- self.sp_vip:setVisible(true)
    self.m_sp_faceTop_0:setVisible(false)
    self.m_sp_faceTop:setVisible(true)
    self.m_xiao_deal_up:setVisible(true)
    self.m_xiao_deal_down:setVisible(false)
    self.sp_buy_0:setVisible(false)
    self.sp_buy:setVisible(true)
    self.m_xiao_buy_up:setVisible(true)
    self.m_xiao_buy_down:setVisible(false)

    if sender then
        local name = sender:getName()
        if name == "btn_layout_vip" then
            local endPos = sender:getTouchEndPosition()
            if endPos.y < 100 then
            -- gLobalViewManager:showTestDialog("udid="..globalData.userRunData.userUdid)
            end
        elseif name == "btn_showSale" then
            self.Limited_time_down:setVisible(false) -- 屏蔽掉限时促销节点  2019-04-25 17:19:09
            self.Limited_time_up:setVisible(true)
        elseif name == "btn_layout_option" then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:updateOptionBtn("end")
        end
    end
end

function TopNode:clickCancelFunc(sender)
    if self.m_isNotCanClick then
        return
    end

    -- if gLobalSendDataManager:getIsFbLogin() == false then
    --     self.face_book_down:setVisible(false)
    --     self.face_book:setVisible(true)
    --     self.m_nodeHeadPoint:setVisible(true)
    -- end

    -- self.sp_vip_0:setVisible(false)
    -- self.sp_vip:setVisible(true)
    -- self.m_sp_faceTop_0:setVisible(false)
    -- self.m_sp_faceTop:setVisible(true)
    self.m_xiao_deal_up:setVisible(true)
    self.m_xiao_deal_down:setVisible(false)
    self.sp_buy_0:setVisible(false)
    self.sp_buy:setVisible(true)
    self.m_xiao_buy_up:setVisible(true)
    self.m_xiao_buy_down:setVisible(false)

    if sender then
        local name = sender:getName()
        if name == "btn_layout_option" then
            self:updateOptionBtn("cancel")
        end
    end
end

function TopNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "tishizhezhao" or name == "tishizhezhao_0" then
        if self.m_shopRewad_force then
            return
        end
        --清理引导log
        gLobalSendDataManager:getLogFeature().m_uiActionSid = nil

        -- 清理引导后续打点
        if gLobalSendDataManager:getLogGuide():isGuideBegan(9) then
            gLobalSendDataManager:getLogGuide():cleanParams(9)
        end

        self:closeShopTishi(true)
    elseif name == "btn_layout_fb" then
        -- gLobalViewManager:addLoadingAnima()
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- performWithDelay(self,function()
        --     self:fbBtnTouchEvent()
        -- end,0.2)
        if self.m_sp_faceTop_root:isVisible() then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:hideQuestActivityView()
            return
        end

        --globalNotifyNodeManager:showNotify()
        -- if gLobalSendDataManager:getIsFbLogin() == true then
        --     return
        -- end
        -- local view = util_createView("views.UserInfo.UserInfoMainLayer")
        -- view:setRootStartPos(sender:getTouchEndPosition())
        -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        G_GetMgr(G_REF.UserInfo):showMainLayer()
    elseif name == "btn_layout_vip" then
        local vip = G_GetMgr(G_REF.Vip):showMainLayer()
        if vip then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_vip)
            gLobalSendDataManager:getLogPopub():addNodeDot(vip, name, DotUrlType.UrlName, true, DotEntrySite.UpView, DotEntryType.Lobby)
        end
    elseif name == "btn_levelRoad" then
        G_GetMgr(G_REF.LevelRoad):showMainLayer()
    elseif name == "btn_showTips" then
        local bLevelRushOpen = gLobalLevelRushManager:pubGetLevelRushBuffOpen()
        --levelDash 开启时 优先打开leveldash
        if bLevelRushOpen and not tolua.isnull(self.m_levelDashTipView) then
            self:showLevelDashView()
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            local curBuffType = self:getCurBuff()
            self.m_levelTips:show(curBuffType)
        end
    elseif name == "btn_layout_buy_deal" then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_NormalSale)
        end
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "upDealIcon")

        -- 判断是否首充活动
        local bCanShowFirstSaleMulti = G_GetMgr(G_REF.FirstSaleMulti):isCanShowLayer()
        local _firstCommomSaleData = G_GetMgr(G_REF.FirstCommonSale):getData()
        local bCanShowRoutineSale = G_GetMgr(G_REF.RoutineSale):canShowMainLayer()
        local view = nil
        if bCanShowFirstSaleMulti then
            view = G_GetMgr(G_REF.FirstSaleMulti):showMainLayer({pos = "Store", playAds = true})
        elseif _firstCommomSaleData and _firstCommomSaleData:isCanShow() then
            view = G_GetMgr(G_REF.FirstCommonSale):showMainLayer({pos = "Store", playAds = true})
        elseif bCanShowRoutineSale then
            view = G_GetMgr(G_REF.RoutineSale):showMainLayer({pos = "Store", playAds = true})
        else
            if _firstCommomSaleData and _firstCommomSaleData:getRequestFirstSaleTpye() == 1 then
                return
            end
            view = G_GetMgr(G_REF.SpecialSale):showMainLayer({pos = "Store", playAds = true})
        end

        -- 按钮名字  类型是url
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(view, name, DotUrlType.UrlName, true, DotEntrySite.UpView, DotEntryType.Lobby)
        end
    elseif name == "btn_layout_buy" or name == "btn_layout_buy_0" then
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "upStoreIcon")
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.tishizhezhao = false
        self:closeShopTishi()
        -- 引导打点：免费领取商店金币-2.点击商城图标
        if gLobalSendDataManager:getLogGuide():isGuideBegan(9) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(9, 2)
        end
        -- if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.shopReward) or globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.shopReward3) then
        -- end

        --新手firebase打点
        globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.click_shop)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_shop)
        end

        local params = {
            rootStartPos = sender:getTouchEndPosition(),
            shopPageIndex = 1,
            dotKeyType = name,
            dotUrlType = DotUrlType.UrlName,
            dotIsPrep = true,
            dotEntrySite = DotEntrySite.UpView,
            dotEntryType = DotEntryType.Lobby
        }
        G_GetMgr(G_REF.Shop):showMainLayer(params)
    elseif name == "btn_layout_buy_gem" then
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.tishizhezhao = false
        self:closeShopTishi()
        -- 引导打点：免费领取商店金币-2.点击商城图标
        if gLobalSendDataManager:getLogGuide():isGuideBegan(9) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(9, 2)
        end
        --新手firebase打点
        globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.click_shop)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_shop)
        end

        local params = {
            rootStartPos = sender:getTouchEndPosition(),
            shopPageIndex = 2,
            dotKeyType = name,
            dotUrlType = DotUrlType.UrlName,
            dotIsPrep = true,
            dotEntrySite = DotEntrySite.UpView,
            dotEntryType = DotEntryType.Lobby
        }
        G_GetMgr(G_REF.Shop):showMainLayer(params)
    elseif name == "btn_showSale" then -- hottoday
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local temp = globalData.GameConfig:getHotTodayConfigs()
        if temp then
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_HotToday)
            end
            gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "HotToday")
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():setClickUrl(DotEntrySite.UpView, DotEntryType.Lobby, "btn_showSale")
            end

            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ONLY_OPEN_POPUP_VIEW,temp)
            -- local layer = util_createView("Activity.Activity_Entrance")
            -- gLobalViewManager:showUI(layer)
            local _mgr = G_GetMgr(ACTIVITY_REF.Entrance)
            if _mgr then
                _mgr:showMainLayer()
                gLobalDataManager:setBoolByField("activityEntrenceGuide", true)
            end
        end
    end
end

function TopNode:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if not self.clickStartFunc then
            return
        end
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        if not self.clickMoveFunc then
            return
        end
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        if not self.clickEndFunc then
            return
        end
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offx = math.abs(endPos.x - beginPos.x)
        if offx < 50 then
            self:clickFunc(sender)
            self:clickEndFunc(sender)
        else
            self:clickCancelFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        if not self.clickCancelFunc then
            return
        end
        self:clickCancelFunc(sender)
    end
end

function TopNode:showLevelDashTip()
    if tolua.isnull(self.m_levelDashTipView) then
        self.m_levelDashTipView = gLobalLevelRushManager:showExpTipView(true)
        if self.m_levelDashTipView ~= nil then
            self:findChild("level_star_14"):setVisible(false)
            self:findChild("Sprite_1"):setVisible(false)
            local level_star_node = self:findChild("level_star_node")
            level_star_node:addChild(self.m_levelDashTipView)
            self.m_levelDashTipView:setOverFunc(
                function()
                    self.m_levelDashTipView = nil
                end
            )
        end
    end
end

function TopNode:showLevelDashView()
    if gLobalLevelRushManager:isDownloadRes() then
        local view = util_createFindView("Activity/LevelLinkSrc/LevelRush_UpView")
        if view ~= nil then
            gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "levelDash")
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_showTips", DotUrlType.UrlName, true, DotEntrySite.UpView, DotEntryType.Lobby)
            end
            gLobalViewManager:showUI(view)
        end
    else
        gLobalViewManager:showDownloadTip()
    end
end

--[[
    @desc: 时间戳转换为时间
    author:{author}
    time:2018-11-27 13:52:57
    @return:
]]
function TopNode:getTimeStamp(unixTime)
    -- body
    local tb = nil

    if unixTime and unixTime >= 0 then
        tb = {}
        tb.year = tonumber(os.date("%Y", unixTime))
        tb.month = tonumber(os.date("%m", unixTime))
        tb.day = tonumber(os.date("%d", unixTime))
        tb.hour = tonumber(os.date("%H", unixTime))
        tb.minute = tonumber(os.date("%M", unixTime))
        tb.second = tonumber(os.date("%S", unixTime))
    end
    return tb
end

--[[
    @desc: 比对时间戳
    author:{author}
    time:2018-11-27 13:52:57
    @return:
]]
function TopNode:compareTimeStamp(nowTime, oldTime)
    -- body
    local isShow = false

    if nowTime.year > oldTime.year then
        isShow = true
        return isShow
    end

    if nowTime.month > oldTime.month then
        isShow = true
        return isShow
    end

    if nowTime.day > oldTime.day then
        isShow = true
        return isShow
    end

    local nowGear = 0
    local oldGear = 0

    if nowTime.hour >= SHOP_RESET_TIME_LIST[1] and nowTime.hour < SHOP_RESET_TIME_LIST[2] then
        -- body
        nowGear = 0
    elseif nowTime.hour >= SHOP_RESET_TIME_LIST[2] and nowTime.hour < SHOP_RESET_TIME_LIST[3] then
        nowGear = 1
    elseif nowTime.hour >= SHOP_RESET_TIME_LIST[3] and nowTime.hour < SHOP_RESET_TIME_LIST[4] then
        nowGear = 2
    end

    if oldTime.hour >= SHOP_RESET_TIME_LIST[1] and oldTime.hour < SHOP_RESET_TIME_LIST[2] then
        -- body
        oldGear = 0
    elseif oldTime.hour >= SHOP_RESET_TIME_LIST[2] and oldTime.hour < SHOP_RESET_TIME_LIST[3] then
        oldGear = 1
    elseif oldTime.hour >= SHOP_RESET_TIME_LIST[3] and oldTime.hour < SHOP_RESET_TIME_LIST[4] then
        oldGear = 2
    end

    if nowGear ~= oldGear then
        -- body
        isShow = true
        return isShow
    end

    return isShow
end

--[[
    @desc: 检测是否应该弹出每日商城奖励
    author:{author}
    time:2018-11-27 13:52:57
    @return:
]]
function TopNode:showShopBonusView(t)
    -- body
    local isShowShopBonus = false

    local nowTime = self:getTimeStamp(os.time())

    if nowTime and t then
        --比对时间戳
        local oldTime = self:getTimeStamp(t)

        isShowShopBonus = self:compareTimeStamp(nowTime, oldTime)
    end

    return isShowShopBonus
end

-- 设置按钮初始化
function TopNode:initOptionBtn()
    self:updateOption()
end

-- 设置按钮状态更换
function TopNode:updateOptionBtn(status)
    local menuNode = self:findChild("node_option")
    self.m_menu = menuNode:getChildByName("optionMenu")
    if not self.m_menu then
        local bDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
        self.m_menu = util_createView("views.menu.MenuNode", nil, bDeluxe)
        self.m_menu:setName("optionMenu")
        menuNode:addChild(self.m_menu)
    end
    if status == "start" then
        if self.m_menu:isShorten() == true then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self.m_menu:beginLengthen()
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self.m_menu:beginShorten()
        end
    elseif status == "end" then
        globalNoviceGuideManager:removeMaskUI()
        if self.m_menu:isShorten() == true then
            self.m_menu:endLengthen()
        else
            self.m_menu:endShorten()
        end
    elseif status == "cancel" then
        if self.m_menu:isShorten() == true then
            self.m_menu:idleLengthen()
        else
            self.m_menu:idleShorten()
        end
    end
end
--TODO-NEWGUIDE 修改金币层级
-- function TopNode:changeCoinsZorder(flag)
--     local lab_coin_bg = self.m_coinNode
--     if lab_coin_bg then
--         if flag then
--             self.m_coinsPos = cc.p(lab_coin_bg:getPosition())
--             local wordPos = lab_coin_bg:getParent():convertToWorldSpace(self.m_coinsPos)
--             util_changeNodeParent(gLobalViewManager:getViewLayer(), lab_coin_bg, ViewZorder.ZORDER_GUIDE + 1)
--             lab_coin_bg:setPosition(wordPos)
--             lab_coin_bg:setScale(self.m_csbNode:getScale())
--         elseif self.m_coinsPos then
--             util_changeNodeParent(self.m_csbNode, lab_coin_bg, 1)
--             lab_coin_bg:setPosition(self.m_coinsPos)
--             lab_coin_bg:setScale(1)
--         end
--     end
-- end

-- 大厅新增设置按钮体现小红点
function TopNode:refreshOptionRedNode()
    if self.m_menu and not self.m_menu:isShorten() then
        self.m_sprOptionRedTips:setVisible(false)
    else
        if globalData.newMessageNums and globalData.newMessageNums > 0 then
            self.m_sprOptionRedTips:setVisible(true)
        else
            self.m_sprOptionRedTips:setVisible(false)
        end
    end
end

--上条头像红点跟fb角标显示逻辑
function TopNode:updateHeadRedPoint()
    local bIsGoInUserInfo = G_GetMgr(G_REF.UserInfo):isGoInUserInfoMainLayer()
    if not bIsGoInUserInfo then
        local sMail = globalData.userRunData.mail
        if sMail == nil or string.len(sMail) == 0 or gLobalSendDataManager:getIsFbLogin() == false then
            self.spHeadRedpoint:setVisible(true)
            self.m_spHeadFacebook:setVisible(false)
        else
            self.spHeadRedpoint:setVisible(false)
            self.m_spHeadFacebook:setVisible(false)
        end
    else
        if gLobalSendDataManager:getIsFbLogin() == false then
            self.spHeadRedpoint:setVisible(false)
            self.m_spHeadFacebook:setVisible(true)
        else
            self.spHeadRedpoint:setVisible(false)
            self.m_spHeadFacebook:setVisible(false)
        end
    end
end

--刷新头像
function TopNode:updateHead()
    local head_avte = self.m_spHead:getChildByName("m_spHead")
    if head_avte ~= nil and not tolua.isnull(head_avte) then
        self.m_spHead:removeChildByName("m_spHead")
    end
    local fbid = globalData.userRunData.facebookBindingID
    local headName = globalData.userRunData.HeadName or 1
    local frameId = globalData.userRunData.avatarFrameId
    local headSize = self.m_spHead:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, headSize, false)
    nodeAvatar:registerTakeOffEvt()
    nodeAvatar:setName("m_spHead")
    self.m_spHead:addChild(nodeAvatar)
    nodeAvatar:setPosition(headSize.width * 0.5, headSize.height * 0.5)
end

-- =============右上角==================
-- 回归签到
function TopNode:initReturnSignLogo(rootNode)
    local userChurnReturnInfo = globalData.userRunData:getUserChurnReturnInfo()
    if userChurnReturnInfo then
        if userChurnReturnInfo:isNewVersion2() then
            local entryNode = G_GetMgr(G_REF.Return):createEntryNode()
            if entryNode then
                rootNode:addItem(entryNode, "ReturnSign")
            end
        elseif userChurnReturnInfo and userChurnReturnInfo.p_returnUser and userChurnReturnInfo:isRunning() then
            local logo = util_createFindView("Activity/Activity_ReturnSignInLogo")
            if logo then
                -- logo:setName("ReturnSign")
                -- self:findChild("node_entrance"):addChild(logo)
                rootNode:addItem(logo, "ReturnSign")
            end
        end
    end
end

-- 成长基金节点
function TopNode:initGrowthFundNode(rootNode)
    local _node = G_GetMgr(G_REF.GrowthFund):createEntryNode()
    if _node then
        -- _node:setName("GrowthFund")
        -- self:findChild("node_entrance"):addChild(_node)
        rootNode:addItem(_node, "GrowthFund")

        -- 领取成长基金后更新
        gLobalNoticManager:addObserver(
            self,
            function()
                local isRunning = G_GetMgr(G_REF.GrowthFund):isRunning()
                if not isRunning then
                    if not tolua.isnull(rootNode) then
                        rootNode:removeFromRT("GrowthFund")
                        rootNode:updatePosOffset()
                    end
                end
            end,
            ViewEventType.NOTIFY_GROWTH_FUND_COLLECT
        )

        return _node
    end
end

function TopNode:initNewUser7Day(rootNode)
    -- 判断当前是否有数据
    local newUser7DayData = G_GetMgr(G_REF.NewUser7Day):getData()
    if newUser7DayData and newUser7DayData:checkFuncOpen() then
        -- local nodeEntrance = self:findChild("node_entrance")
        -- local signInChild = nodeEntrance:getChildByName("ReturnSign")
        -- if signInChild then
        --     signInChild:setPosition(cc.p(-100, 0))
        -- end

        local logo = util_createFindView("Main/NewUser7DayEntranceView")
        if logo then
            -- logo:setName("NewUser7Day")
            -- nodeEntrance:addChild(logo)
            rootNode:addItem(_node, "NewUser7Day")
        end
    end
end

function TopNode:hideNewUser7Day()
    local newUser7Day = self.m_nodeEntrance:getChildByName("NewUser7Day")
    if newUser7Day and newUser7Day:isVisible() then
        newUser7Day:setVisible(false)
    end
end
-- =========================================

-- 添加引导
function TopNode:addEntrenceGuide(isRemove)
    -- 活动总入口引导 添加 引导最低等级
    if globalData.userRunData.levelNum < globalData.constantData.NOVICE_ACT_ENTRANCE_GUIDE_LEVEL then
        return
    end

    if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.dallyWhell.id) then
        -- 轮盘未引导就不显示
        return
    end

    if isRemove then
        if self.nodeHotnewsParentInfo ~= nil then
            util_changeNodeParent(self.nodeHotnewsParentInfo.parentNode, self.btn_showSale, self.nodeHotnewsParentInfo.zOrder)
            self.btn_showSale:setPosition(self.nodeHotnewsParentInfo.pos)
            self.nodeHotnewsParentInfo = nil
        end
        if self.nodeGuideParentInfo ~= nil then
            util_changeNodeParent(self.nodeGuideParentInfo.parentNode, self.m_specialDealNode, self.nodeGuideParentInfo.zOrder)
            self.m_specialDealNode:setPosition(self.nodeGuideParentInfo.pos)
            self.m_specialDealNode:setScale(self.nodeGuideParentInfo.scale)
            self.nodeGuideParentInfo = nil
        end
        if self.hotnewsNode ~= nil then
            self.hotnewsNode:removeFromParent()
            self.hotnewsNode = nil
        end
        return
    end

    if gLobalDataManager:getBoolByField("activityEntrenceGuide", false) == true then
        util_afterDrawCallBack(
            function()
                if self.popViewCount == 0 then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBYNODE_BATTLEPASS)
                end
            end
        )
        return
    end

    --没有hottoday数据则返回
    local hotTodayConfig = globalData.GameConfig:getHotTodayConfigs()
    if hotTodayConfig == nil then
        return
    end

    --不在Quest中
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.m_isQuestLobby then
        return
    end

    if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterQuestLayer() then
        return
    end

    --不在高倍场中
    if globalData.deluexeHall then
        return
    end

    --处于常规促销小游戏中
    local luckyChooseManager = util_require("manager/System/LuckyChooseManager"):getInstance()
    if luckyChooseManager:checkShowLuckyChooseLayer() then
        return
    end

    local _entranceMgr = G_GetMgr(ACTIVITY_REF.Entrance)
    if _entranceMgr and _entranceMgr:isCanShowLayer() and self.hotnewsNode == nil then
        self.nodeHotnewsParentInfo = {
            parentNode = self.btn_showSale:getParent(),
            pos = cc.p(self.btn_showSale:getPosition()),
            zOrder = self.btn_showSale:getLocalZOrder()
        }
        self.nodeGuideParentInfo = {
            parentNode = self.m_specialDealNode:getParent(),
            pos = cc.p(self.m_specialDealNode:getPosition()),
            zOrder = self.m_specialDealNode:getLocalZOrder(),
            scale = self.m_specialDealNode:getParent():getScale()
        }

        local hotnewsNode = cc.Node:create()
        gLobalViewManager:getViewLayer():addChild(hotnewsNode, ViewZorder.ZORDER_GUIDE)
        self.hotnewsNode = hotnewsNode

        local newbieMask = util_newMaskLayer(true)
        hotnewsNode:addChild(newbieMask)

        newbieMask:onTouch(
            function(event)
                --解决穿透问题
                util_afterDrawCallBack(
                    function()
                        if not tolua.isnull(self) then
                            gLobalDataManager:setBoolByField("activityEntrenceGuide", true)
                            --点击消失
                            self:addEntrenceGuide(true)
                            performWithDelay(
                                self,
                                function()
                                    if self.popViewCount == 0 then
                                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBYNODE_BATTLEPASS)
                                    end
                                end,
                                0.1
                            )
                        end
                    end
                )
                return true
            end,
            false,
            true
        )

        local hotnewGuideSpine = util_spineCreate("Activity/spine/Entrance", true, true, 1)
        util_spinePlay(hotnewGuideSpine, "idleframe", true)
        hotnewsNode:addChild(hotnewGuideSpine, 2)

        --转换hotnew显示层级
        local specialDealNodoPos = util_getConvertNodePos(self.m_specialDealNode, hotnewGuideSpine)
        util_changeNodeParent(hotnewsNode, self.m_specialDealNode, 1)
        self.m_specialDealNode:setScale(globalData.lobbyScale or 1)
        self.m_specialDealNode:setPosition(specialDealNodoPos)
        hotnewGuideSpine:setPosition(specialDealNodoPos)

        --转换layer按钮层级
        local btnShowSaleSize = self.btn_showSale:getContentSize()
        local btnShowSaleAnchorPoint = self.btn_showSale:getAnchorPoint()
        local btnShowSaleWorldPos = self.btn_showSale:convertToWorldSpace(cc.p(btnShowSaleAnchorPoint.x * btnShowSaleSize.width, btnShowSaleAnchorPoint.y * btnShowSaleSize.height))
        local btnShowSalePos = hotnewsNode:convertToNodeSpace(cc.p(btnShowSaleWorldPos.x, btnShowSaleWorldPos.y))
        util_changeNodeParent(hotnewsNode, self.btn_showSale, 1)
        self.btn_showSale:setPosition(btnShowSalePos)
    end
end

return TopNode
