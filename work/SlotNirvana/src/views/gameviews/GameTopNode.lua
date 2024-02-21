--
-- 游戏中顶部UI
local GameTopNode = class("GameTopNode", util_require("base.BaseView"))

---变量初始化
GameTopNode.m_coinLabel = nil
GameTopNode.m_expBar = nil
GameTopNode.m_expLabel = nil
GameTopNode.m_mul = nil

-- 金币改变需要参数
GameTopNode.m_lCoinRiseNum = nil -- 金币增加步数
GameTopNode.m_showTargetCoin = nil -- 滚动最终钱数量
GameTopNode.m_curCoin = nil -- 当前显示的coin

-- 经验进度条相关
GameTopNode.m_scheduleID = nil --
GameTopNode.m_ctrSlider = nil --
GameTopNode.m_iAnmiaStepMoveVal = nil --  进度条变化步长
GameTopNode.m_iProgMoveCount = nil --
GameTopNode.m_proMoveHandlerID = nil -- 进度条移动hanlder id
GameTopNode.m_iLastProgressVal = nil --
GameTopNode.m_currTotalProVal = nil -- 当前总经验值
GameTopNode.m_waitTime = nil --
GameTopNode.m_menu = nil -- 按钮面板
GameTopNode.m_coinNode = nil
local COINS_DEFAULT_SCALE = 0.65
-- 注册的 schedule 回调
GameTopNode.m_showCoinHandlerID = nil --

GameTopNode.m_isOpenSale = nil

GameTopNode.m_isNotCanClick = nil -- 关卡内控制顶部UI按钮是否可点击

local AlternateTime = 10 --node_shop_freecoins节点的轮流展示时间

-- 跟TopNode 使用一样的值
local COINS_LABEL_WIDTH = 312 -- 金币控件的长度
local COINS_DEFAULT_SCALE = 0.60 -- 金币控件的缩放
local GEMS_LABEL_WIDTH = 149 -- 钻石控件的长度
local GEMS_DEFAULT_SCALE = 0.60 -- 钻石控件的缩放

--服务器下发需要打印的字段rtpControlType
-- local DEBUG_LOG_LIST = {"rtpType","rtpControlType","configType","loginSpinTimes","loginRtp","protectBuff","toHighRtp","purchaseTimes",
-- "purchaseAmount","betId","featureRtp","controlId","dropCardSpinTimes","dp","inactiveWaterPool","protectMultiple","protectType","purchaseWaterPool",
-- "newUserWaterPool","newGameWaterPool","coinsLimit", "peakCoins", "giftCoins","triggerCoins","questGameWaterPool","questBet","r","rewardJackpot",
-- "dailyTaskBetCoins","dailyTaskAvgSpinTimes","dailyTaskRate","dailyTaskRound","dailyTaskScale","dailyTaskAvgBet","dailyTaskAvgHighBet","gameCrazyWaterPool",
-- "dpPrizeCoinPool","dpPrizeInitCoinPool","dpPrizeCoinPoolRoof","dpPrizeSpinTimes","dpPrizeInitUserCoins"}
local DEBUG_LOG_LIST = {"rtpType", "rtpControlType", "protectBuff", "configType","betId", "protectMultiple", "protectType", "actualRtpType"}
--需要根据策划配置名字和服务器打印字段名字匹配列表 例如:策划配置protectBuff的名字叫ptcBuff  {protectBuff = "ptcBuff"}
local DEBUG_NAEM_LIST = {
    rtpType = "当前RTP",
    rtpControlType = "RTP控制类型",
    protectBuff = "触发原因",
    configType = "配置类型",
    betId = "本关累计SPIN次数",
    protectMultiple = "保护倍数",
    protectType = "保护类型",
    actualRtpType = "真实RTP"
}

GameTopNode.m_spinTxt = nil

GameTopNode.m_initPortrait = nil --初始化界面时是否是竖屏

function GameTopNode:initDatas()
    GameTopNode.super.initDatas(self)
    self:updateMulExpState()
end

function GameTopNode:initUI(machine)
    if globalData.slotRunData.isPortrait == true then
        COINS_DEFAULT_SCALE = 0.6
    end

    local deluxeName = ""
    local bOpenDeluxe = globalData.slotRunData.isDeluexeClub
    if bOpenDeluxe then
        deluxeName = "_1"
    end
    local csbName = "GameNode/GameTopNode" .. deluxeName .. ".csb"
    if globalData.slotRunData.isPortrait then
        csbName = "GameNode/GameTopNodePortrait" .. deluxeName .. ".csb"
        self.m_initPortrait = true
    end
    self:createCsbNode(csbName)

    if globalData.slotRunData.isPortrait then
        self.m_nodeBangOriPos = cc.p(self:findChild("bangNode"):getPosition())
        self.m_nodeMainOriPos = cc.p(self:findChild("mainNode"):getPosition())
        self:updateBangScreenPos()
    end

    self:runCsbAction("idle", true)

    self.m_isNotCanClick = false
    -- 商城特殊红点交替显示时间
    self.m_alternate_time = 0

    --促销新按钮
    self.two_buttom = self:findChild("two_buttom")
    self.two_buttom_tx = self:findChild("two_buttom_tx")
    self.m_btn_layout_buy_deal = self:findChild("btn_layout_buy_deal")
    self.m_xiao_deal_up = self:findChild("xiao_deal_up")
    self.m_xiao_deal_down = self:findChild("xiao_deal_down")
    self.m_xiao_buy_up = self:findChild("xiao_buy_up")
    self.m_xiao_buy_down = self:findChild("xiao_buy_down")
    self.m_one_buttom = self:findChild("one_buttom")
    self.m_one_buttom_tx = self:findChild("one_buttom_tx")
    -- self:findChild("UI_coin_dollarEffect_01_1"):setVisible(false)
    self.m_coinNode = self:findChild("lab_coin_bg")
    self.m_gemNode = self:findChild("lab_gem_bg")

    -- 按钮层
    self:initOptionBtn()

    -- 商城提示图标
    self.node_shop_freecoins = self:findChild("node_shop_freecoins")
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
    globalData.coinsSoundType = 0
    globalData.isOpenUserRate = nil

    local panel_rate = self:findChild("panel_rate")
    panel_rate:setVisible(false)

    self.m_lbInboxTipSp = self:findChild("sprite_inbox_tip")
    self:refreshInboxTip(0)
    --buy流光
    -- self.two_buttom_0 = self:findChild("two_buttom_0")
    -- self.buyeft = util_createView("views.lobby.BuyEft")
    -- self.two_buttom_0:addChild(self.buyeft) ---11  3
    -- self.two_buttom_0:setPosition(-0.06,-38.68)

    local node_wheel = self:findChild("node_wheel")

    self.m_topwheelIcon = util_createView("views.gameviews.GameTopWheelIcon")
    if globalData.slotRunData.isPortrait == true then
        self.m_topwheelIcon:setScale(0.98)
    else
        self.m_topwheelIcon:setScale(1.1)
    end
    if self.m_topwheelIcon then
        node_wheel:addChild(self.m_topwheelIcon)
    end

    self.m_node_coin_eff = self:findChild("node_coin_eff")
    self.m_particleShuzi = cc.ParticleSystemQuad:create("Lobby/Other/Shuzi.plist")
    self.m_node_coin_eff:addChild(self.m_particleShuzi, 3)
    self.m_particleShuzi:setPosition(-15, 0)
    self.m_particleShuzi:resetSystem()

    if globalData.slotRunData.isPortrait then
        self.m_particleShuzi:setScaleX(0.6)
    else
        self.m_particleShuzi:setScale(0.95)
    end
    self.m_particleShuzi:setVisible(false)

    self.m_level_Particle_1_1 = self:findChild("level_Particle_1_1")
    self.m_level_Particle_1_2 = self:findChild("level_Particle_1_2")
    self.m_level_Particle_2_1 = self:findChild("level_Particle_2_1")
    self.m_level_Particle_2_2 = self:findChild("level_Particle_2_2")

    self.m_coinLabel = self:findChild("txt_coins")
    self.m_expBar = self:findChild("Bar_level")
    self.m_expBar_0 = self:findChild("Bar_level_0")
    self.m_expLabel = self:findChild("lab_level")

    self:initProcessInfo()

    -- 初始化 玩家拥有金币数
    self:initCoinsInfo()

    -- 初始化钻石
    self.m_gemLabel = self:findChild("txt_gems")

    self:updateGemLabel(false, globalData.userRunData.gemNum)
    
    -- 初始化代币
    self:initBucksInfo()

    self.m_coinNumState = 0
    self:changeCoinsState()

    -- if globalData.slotRunData.isPortrait == true then
    if self.m_initPortrait then
        self.m_expLabel:setScale(1.1)

        util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, 269, 0.44)
        -- self:updateLabelSize({label = self.m_coinLabel, sx = 0.44, sy = 0.44}, 269)
    else
        self.m_expLabel:setScale(1.2)
        util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, COINS_LABEL_WIDTH, COINS_DEFAULT_SCALE)
    end

    -- 初始化 经验信息
    self:updateLevel(globalData.userRunData.levelNum)
    self:updateLevelPro()

    -- B组 关卡内 升级tip显示到层级高点新手期 改 cxc 2021年06月23日17:48:45
    local nodeLevelUpTipParent = self:findChild("node_levelup")
    if globalData.GameConfig:checkUseNewNoviceFeatures() and nodeLevelUpTipParent then
        nodeLevelUpTipParent:setLocalZOrder(2)
        local offsetY = -50
        if globalData.slotRunData.isPortrait then
            offsetY = -30
        end
        nodeLevelUpTipParent:setPositionY(nodeLevelUpTipParent:getPositionY() + offsetY)
    end

    local levelTip = self:findChild("levelTip")
    self:addClick(levelTip)

    -- 小猪
    self:initPiggys()

    self.m_showTipsNode = self:findChild("node_showTips")
    self.btn_layout_home = self:findChild("btn_layout_home")
    self.btn_layout_buy = self:findChild("btn_layout_buy")
    self.btn_layout_buy_0 = self:findChild("btn_layout_buy_0")
    self.btn_layout_option = self:findChild("btn_layout_option")
    self.btn_levelRoad = self:findChild("btn_levelRoad")
    self.btn_showTips = self:findChild("btn_showTips")
    self.btn_spNum = self:findChild("btn_spNum")
    self.m_spinTipNode = self:findChild("spinTip_node")
    self.btn_layout_buy_gem = self:findChild("btn_layout_buy_gem")
    self:addClick(self.btn_layout_home)
    self:addClick(self.m_btn_layout_buy_deal)
    self:addClick(self.btn_layout_buy)
    self:addClick(self.btn_layout_buy_0)
    self:addClick(self.btn_layout_option)
    self:addClick(self.btn_levelRoad)
    self:addClick(self.btn_showTips)
    self:addClick(self.btn_spNum)
    if self.btn_layout_buy_gem then
        self:addClick(self.btn_layout_buy_gem)
    end

    self.m_spinMulTips = util_createView("views.gameviews.spinMulTips")
    self.m_spinTipNode:addChild(self.m_spinMulTips)

    self.sp_home_0 = self:findChild("sp_home_0")
    self.sp_home = self:findChild("sp_home")
    self.sp_buy_0 = self:findChild("sp_buy_0")
    self.sp_buy = self:findChild("sp_buy")
    self:clickEndFunc()

    if self:isMinzLevel() or self:isDiyFeatureLevel() then
        self.sp_home_0:setVisible(false)
        self.sp_home:setVisible(false)
        self.btn_layout_home:setTouchEnabled(false)
    end

    if DEBUG ~= 2 then
        local seqLb = self:findChild("lb_seqids")
        if seqLb then
            seqLb:removeFromParent()
        end
    else
        local seqLb = self:findChild("lb_seqids")
        seqLb:setVisible(true)
    end
    self:initMulExp()

    self:initLevelTips()

    --促销初始化
    self.m_isOpenSale = nil
    self.two_buttom:setVisible(false)
    self.two_buttom_tx:setVisible(false)
    self.m_one_buttom:setVisible(true)
    self.m_one_buttom_tx:setVisible(true)
    self.m_btn_layout_buy_deal:setVisible(false)
    self:updateBasicSale()

    local Buy_bgsg = self:findChild("Buy_bgsg")
    if Buy_bgsg then
        Buy_bgsg:setVisible(false)
    end

    self:updateTopUIBg()
    -- globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.returnLobbyForGame,self.btn_layout_home)
    -- globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.levelUpFast,self.btn_showTips)

    self:initFrostFlameClashTopNode()

    self:initCurrencyBuckData()
end

function GameTopNode:initCurrencyBuckData(nValue)
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

function GameTopNode:initBucksInfo()
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

-- 是否是minz关卡
function GameTopNode:isMinzLevel()
    local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    if minzMgr then
        return minzMgr:isMinzLevel()
    end
    return false
end

-- 是否是minz关卡
function GameTopNode:isDiyFeatureLevel()
    local diyFeatureMgr = G_GetMgr(ACTIVITY_REF.DiyFeature)
    if diyFeatureMgr then
        return diyFeatureMgr:isDiyFeatureLevel()
    end
    return false
end

function GameTopNode:updateBangScreenPos()
    if globalData.slotRunData.isPortrait then
        local bangNode = self:findChild("bangNode")
        local mainNode = self:findChild("mainNode")
        local bangHeight = util_getBangScreenHeight()
        bangNode:setPositionY(self.m_nodeBangOriPos.y - bangHeight)
        mainNode:setPositionY(self.m_nodeMainOriPos.y - bangHeight)
    end
end

function GameTopNode:initCoinsInfo()
    local coinCount = globalData.userRunData.coinNum

    self:updateCoinLabel(false, coinCount)
end

-- 刷新背景
function GameTopNode:updateTopUIBg()
    -- local spNormalBgL = self:findChild("sp_bg")
    -- local spDeluxeBgL = self:findChild("sp_dcbg")
    local bOpenDeluxe = globalData.slotRunData.isDeluexeClub

    -- spNormalBgL:setVisible(not bOpenDeluxe)
    -- spDeluxeBgL:setVisible(bOpenDeluxe)

    local concatStr = bOpenDeluxe and "_deluxe" or ""

    if not globalData.slotRunData.isPortrait then
        -- local spNormalBgR = self:findChild("sp_bg_0")
        -- spNormalBgR:setVisible(not bOpenDeluxe)
        -- local spDeluxeBgR = self:findChild("sp_dcbg_0")
        -- spDeluxeBgR:setVisible(bOpenDeluxe)

        -- local spDeluxeSlideL = self:findChild("main_dcmap_up_bg10_3")
        -- local spDeluxeSlideR = self:findChild("main_dcmap_up_bg10_3_0")
        -- spDeluxeSlideL:setVisible(bOpenDeluxe)
        -- spDeluxeSlideR:setVisible(bOpenDeluxe)

        -- home 按钮
        -- local homeNImgPath = "GameNode/ui/btn_home_up" .. concatStr .. ".png"
        -- local homePImgPath = "GameNode/ui/btn_home_down" .. concatStr .. ".png"
        -- util_changeTexture(self.sp_home, homeNImgPath)
        -- util_changeTexture(self.sp_home_0, homePImgPath)

        -- option
        if tolua.isnull(self.m_menu) then
            return
        end
    -- local bOpenDeluxe = globalData.slotRunData.isDeluexeClub
    -- self.m_menu:updateDeluxeUI(bOpenDeluxe)
    end

    -- buyBg
    -- local spBuyBg = self:findChild("buy_bg")
    -- local buyBgImgPath = "GameNode/ui_lobbyTop/buy_bg" .. concatStr .. ".png"
    -- util_changeTexture(spBuyBg, buyBgImgPath)
end

function GameTopNode:initLevelTips()
    self.m_levelTips = util_createView("views.lobby.LevelTips", 2)
    self.m_showTipsNode:addChild(self.m_levelTips)
    if globalData.slotRunData.isPortrait then
        self.m_showTipsNode:setPositionX(self.m_showTipsNode:getPositionX() - 40)
    end
end

--[[
    @desc: 初始化经验条的信息， 主要是遮罩部分
    time:2019-10-08 18:26:19
    @return:
]]
function GameTopNode:initProcessInfo()
    self.m_panel_eff = self:findChild("panel_eff")
    local progessParent = self:findChild("processNode")

    local expBarPath = "#GameNode/ui_lobbyTop/ui_lobby_levelBar2.png"
    if globalData.slotRunData.isPortrait then
        expBarPath = "#GameNode/ui_lobbyTop/ui_lobby_levelBar_shu2.png"
    end
    local mask = display.newSprite(expBarPath) --11 +4
    -- local mask = display.newSprite(progessbg:getTexture())

    local clip_node = cc.ClippingNode:create()
    clip_node:setAlphaThreshold(0)
    clip_node:setStencil(mask)
    clip_node:setAnchorPoint(0, 0.5)
    progessParent:addChild(clip_node)

    -- self.m_panel_eff:retain()
    -- self.m_panel_eff:removeFromParent()
    -- clip_node:addChild(self.m_panel_eff)
    -- self.m_panel_eff:release()
    util_changeNodeParent(clip_node, self.m_panel_eff)
    self.m_panel_eff:setPosition(0, 0)
    local _maskSize = mask:getContentSize()
    if _maskSize then
        self.m_panel_eff_ori_width = _maskSize.width
        self.m_panel_eff_ori_height = _maskSize.height
    end
    -- if globalData.slotRunData.isPortrait then
    --     -- mask:setScale(0.7)
    --     -- clip_node:setPosition(5  ,-1)
    --     self.m_panel_eff_ori_width = 155
    --     self.m_panel_eff_ori_height = 30
    -- else
    --     -- clip_node:setPosition(-11  ,-1)
    --     self.m_panel_eff_ori_width = 203
    --     self.m_panel_eff_ori_height = 34
    -- end

    -- 设置进度条的遮罩处理
    mask:setPositionX(self.m_panel_eff_ori_width * 0.5)
end

function GameTopNode:showLevelParticle(type)
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

function GameTopNode:updateMulExpState()
    self.m_checkDoube = globalData.buffConfigData:checkBuff()
    self.m_bLevelRushOpen = gLobalLevelRushManager:pubGetLevelRushBuffOpen()
end

function GameTopNode:initMulExp()
    self:updateMulExpState()

    if not tolua.isnull(self.m_levelRushTipView) then
        self.m_levelRushTipView:removeFromParent()
        self:findChild("level_star_14"):setVisible(true)
        self:findChild("Sprite_1"):setVisible(true)
        self.m_levelRushTipView = nil
    end

    if self.m_bLevelRushOpen then
        if not tolua.isnull(self.m_mul) then
            self.m_mul:removeFromParent()
            self.m_mul = nil
        end
        self:showLevelRushTip()

        if self.m_checkDoube then
            self.m_expBar:setVisible(false)
            self.m_expBar_0:setVisible(true)
            self:showLevelParticle("exp")
        else
            self.m_expBar_0:setVisible(false)
            self.m_expBar:setVisible(true)
            self:showLevelParticle("normal")
        end
    else
        if self.m_checkDoube then
            if self.m_mul == nil or self.m_mul.m_changeUI == true then
                local x2 = self:findChild("x2")
                self.m_mul = util_createView("views.mulReward.ExpMulReward")
                x2:addChild(self.m_mul)
                self.m_mul:setOverFunc(
                    function()
                        self.m_mul = nil
                    end
                )
                self.m_expBar:setVisible(false)
                self.m_expBar_0:setVisible(true)
                self:showLevelParticle("exp")
            end
        else
            self.m_expBar_0:setVisible(false)
            self.m_expBar:setVisible(true)
            self:showLevelParticle("normal")
        end
    end
end

--获取当前buff类型
function GameTopNode:getCurBuff()
    if self.m_mul == nil or not self.m_mul.getCurBuff then
        return BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN
    end

    return self.m_mul:getCurBuff()
end

function GameTopNode:initPiggys()
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
    -- 新手引导 todo
    -- globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.piggyBank, self.m_piggyBank)
end

function GameTopNode:getPiggyNode(_name)
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
function GameTopNode:initActivityPiggyNodes()
    local refs = TrioPiggyConfig.TrioPiggyEffectiveRefs
    if refs and #refs > 0 then
        for i=1,#refs do
            local ref = refs[i]
            local mgr = G_GetMgr(ref)
            if mgr and mgr:getRunningData() then
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
function GameTopNode:initCoinPiggyNode()
    local coinPiggy = G_GetMgr(G_REF.PiggyBank):createTopPigNode()
    self:findChild("node_piggyeffect"):addChild(coinPiggy)
    -- coinPiggy:setScale(0.8)
    table.insert(self.m_piggyList, coinPiggy)
end

function GameTopNode:initChipPiggyNode()
    local chipPiggyMgr = G_GetMgr(ACTIVITY_REF.ChipPiggy)
    if chipPiggyMgr and chipPiggyMgr:getRunningData() then
        local chipPiggy = chipPiggyMgr:createTopPigNode()
        self:findChild("node_piggyeffect"):addChild(chipPiggy)
        table.insert(self.m_piggyList, coinPiggy)
    end
end

function GameTopNode:initGemPiggyNode()
    local gemPiggyMgr = G_GetMgr(ACTIVITY_REF.GemPiggy)
    if gemPiggyMgr and gemPiggyMgr:getRunningData() then
        local gemPiggy = gemPiggyMgr:createTopPigNode()
        self:findChild("node_piggyeffect"):addChild(gemPiggy)
        table.insert(self.m_piggyList, gemPiggy)
    end
end

function GameTopNode:addPiggyShowIndex()
    self.m_piggyShowIndex = self.m_piggyShowIndex + 1
    if self.m_piggyShowIndex > self.m_piggysLen then
        self.m_piggyShowIndex = 1
    end
end

function GameTopNode:refreshPiggyNode()
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
    end
end

-- 该函数弃用，为了不更改关卡底层代码，这里保留空函数
-- 用updataPiggyEx函数代替
function GameTopNode:updataPiggy(betCoin)
    -- self.m_piggyBank:addCollectCoin(betCoin)
    -- -- local curBetIdx = globalData.slotRunData.iLastBetIdx
    -- -- local curBetData = globalData.slotRunData:getBetDataByIdx(curBetIdx)
    -- self.m_topwheelIcon:updateMulView(function(mul)
    --     self.m_spinMulTips:showUp(mul)
    -- end)
end

function GameTopNode:updataPiggyEx(betCoin)
    local piggyBank = self:getPiggyNode("PiggyNode")
    if not tolua.isnull(piggyBank) then
        piggyBank:addCollectCoin(betCoin)
    end
    self.m_topwheelIcon:updateMulView(
        function(mul)
            self.m_spinMulTips:showUp(mul)
        end
    )
end

function GameTopNode:updateLevel(levelNum)
    print("curLevel " .. levelNum)
    self.m_expLabel:setString(levelNum)
end

function GameTopNode:updateLevelPro(value)
    if not value then
        local totalProVal = globalData.userRunData:getPassLevelNeedExperienceVal()
        value = math.floor((globalData.userRunData.currLevelExper / totalProVal) * 100)
        self.m_curProVal = value
    end
    if value > 100 then
        value = 100
    end
    self.m_expBar:setPercent(value)
    self.m_expBar_0:setPercent(value)
    -- if globalData.slotRunData.isPortrait == true then
    --     self.m_panel_eff:setContentSize(cc.size(self.m_panel_eff_ori_width * value * 0.01, self.m_panel_eff_ori_height))
    -- else
    self.m_panel_eff:setContentSize(cc.size(self.m_panel_eff_ori_width * value * 0.01, self.m_panel_eff_ori_height))
    -- end
end

function GameTopNode:getUISize()
    local spBg = self:findChild("size_for_level")
    local size = spBg:getContentSize()

    local csbScale = self.m_csbNode:getScale()

    return size.width * csbScale, size.height * csbScale
end

function GameTopNode:changeCoinsState()
    if globalData.nowBetValue then
        if toLongNumber(globalData.nowBetValue * 3) > globalData.userRunData.coinNum then --当前金币数量小于当前spin3ci次的数量
            if self.m_coinNumState == 1 then
                return
            end
            self.m_coinNumState = 1
            local count = 0
            local change = true

            if self.m_coinNumStateAction then
                self:stopAction(self.m_coinNumStateAction)
                self.m_coinNumStateAction = nil
            end

            self.m_coinNumStateAction =
                schedule(
                self,
                function()
                    --count = (count + 1) % 2
                    -- if count == 1 then
                    --     self.m_coinLabel:setColor(cc.c3b(255, 0, 0))
                    -- else
                    --     self.m_coinLabel:setColor(cc.c3b(255, 255, 255))
                    -- end

                    if change == true then
                        count = count + 25.5
                        if count >= 255 then
                            count = 255
                            change = false
                        end
                    else
                        count = count - 25.5
                        if count <= 0 then
                            count = 0
                            change = true
                        end
                    end
                    self.m_coinLabel:setColor(cc.c3b(255, count, count))
                end,
                0.03
            )
        else
            if self.m_coinNumStateAction then
                self:stopAction(self.m_coinNumStateAction)
                self.m_coinNumStateAction = nil
            end
            self.m_coinLabel:setColor(cc.c3b(255, 255, 255))
            self.m_coinNumState = 0
        end
    end
end

function GameTopNode:onEnter() 
    self:saveNewPlayerUnlockLevelData()
    if self:checkNewPlayerUnlockLevel() == true then
        self:showNewPlayerUnlockLevelTip()
    end

    --清除关卡内 右边集卡掉落气泡数据
    CardSysManager:getDropMgr():clearDropBubble()

    --清除关卡内 右边大赢宝箱气泡数据
    G_GetMgr(ACTIVITY_REF.MegaWinParty):clearRewardBubbleDate()

    --引导提示
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 可以弹出每日任务引导
            if params == GUIDE_LEVEL_POP.ReturnLobbyForGame then
                -- local path = "MoreGames.csb"
                -- local size = self.sp_home:getContentSize()
                -- local pos = self.sp_home:getParent():convertToWorldSpace(cc.p(self.sp_home:getPositionX(),self.sp_home:getPositionY()-size.height/2))
                -- globalNoviceGuideManager:addNewPop(GUIDE_LEVEL_POP.ReturnLobbyForGame,pos,path)
                -- if globalFireBaseManager.sendFireBaseLogDirect then
                --     globalFireBaseManager:sendFireBaseLogDirect("guideBubbleReturnLobbyPopup",false)
                -- end
                -- -- 引导打点：返回游戏大厅提示-1.弹出返回游戏大厅提示 8级
                -- gLobalSendDataManager:getLogGuide():setGuideParams(5, {isForce = false, isRepeat = false, guideId = nil})
                -- gLobalSendDataManager:getLogGuide():sendGuideLog(5, 1)
                -- globalNoviceGuideManager.guideBubbleReturnLobbyPopup = true
            elseif params == GUIDE_LEVEL_POP.LevelUpFast then
                local path = "Level.csb"
                if globalData.slotRunData.isPortrait == true then
                    path = "LevelPortrait.csb"
                end
                local pos = self.m_showTipsNode:getParent():convertToWorldSpace(cc.p(self.m_showTipsNode:getPositionX(), self.m_showTipsNode:getPositionY()))
                globalNoviceGuideManager:addNewPop(GUIDE_LEVEL_POP.LevelUpFast, pos, path)
            end
        end,
        ViewEventType.NOTIFY_POPSPECIAL_NEWGUIDE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 有了 iLastBetIdx ，可以做后续的逻辑了
            self:initFlamingoJackpotTopNode()
        end,
        ViewEventType.NOTIFY_UPDATE_BETIDX
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:changeCoinsState()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
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

    self:registerEvents()

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.id == NOVICEGUIDE_ORDER.cashbonusMul.id then
                self.m_spinMulTips:show()
                globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.cashbonusMul)
            end
            --暂时不提层
            -- if params.id == NOVICEGUIDE_ORDER.payTable.id then
            --     if self.setGuide then
            --         self:setGuide()
            --     end
            -- end
        end,
        ViewEventType.NOTIFY_NOVICEGUIDE_SHOW
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, mailCount)
            self:refreshInboxTip(mailCount)
        end,
        ViewEventType.NOTIFY_REFRESH_MAIL_COUNT
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            if params.type == 2 and self.flyCoinsCallBack ~= nil then
                self:flyCoinsCallBack(params)
            end
        end,
        ViewEventType.NOTIFY_UPLEVEL_STATUS
    )

    globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.levelUp)

    globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.cashbonusMul)

    -- 扩圈玩家先引导 关卡规则 然后引导 noobTaskStart1
    -- 第一步引导
    if globalNoviceGuideManager:isNoobUsera() and not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.initIcons.id) then
        self:checkGuideClearGems()
        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.initIcons)
    else
        local bShowExpandGuide = G_GetMgr(G_REF.NewUserExpand):checkShowExpandLevelsRuleGuide()
        if not bShowExpandGuide then
            globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
        end
    end


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

    --打印信息
    self:checkPrintLog()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:checkPrintLog()
        end,
        ViewEventType.NOTIFY_UPDATE_DEBUGLOG
    )

    -- if globalData.slotRunData.isPortrait == true then
    if self.m_initPortrait then
        util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, 269, 0.44)
        -- self:updateLabelSize({label = self.m_coinLabel, sx = 0.44, sy = 0.44}, 269)
    else
        util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, COINS_LABEL_WIDTH, COINS_DEFAULT_SCALE)
    end

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
            self:showNewPlayerUnlockLevelTip()
        end,
        ViewEventType.NOTIFY_NEW_PLAYER_UNLOCK_LEVEL
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if globalData.openDebugCode == 1 then
                --预判spin消息返回错误
                if params and type(params) == "table" and params[1] == true then
                    if params and params[2] then
                        for i = 1, #DEBUG_LOG_LIST do
                            local keySpin = DEBUG_LOG_LIST[i]
                            local data = params[2][keySpin]
                            if self.m_spinTxt[keySpin] then
                                local strKey = keySpin
                                if DEBUG_NAEM_LIST[keySpin] then
                                    strKey = DEBUG_NAEM_LIST[keySpin]
                                end
                                if data then
                                    self.m_spinTxt[keySpin]:setString(strKey .. ":" .. data)
                                else
                                    self.m_spinTxt[keySpin]:setString(strKey .. ":")
                                end
                            end
                        end
                    end
                end
            end
            if params[1] == true then
                local spinData = params[2]
                if spinData.action == "SPIN" then
                    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE and globalData.slotRunData.currSpinMode ~= REWAED_SPIN_MODE and globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
                        if spinData.extend ~= nil and spinData.extend.multiple ~= nil then
                            G_GetMgr(G_REF.CashBonus):parseMultipleData(spinData.extend.multiple)
                        end
                        local betCoin = globalData.slotRunData:getCurTotalBet()
                        self:updataPiggyEx(betCoin)
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    -- 清除LOG_GUIDE中非强制性引导的后续打点
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.guideIndex == 5 then
                -- 非强制性引导【bet提升】，玩家如果拒绝了后续不打点
                if gLobalSendDataManager:getLogGuide():isGuideBegan(5) then
                    gLobalSendDataManager:getLogGuide():cleanParams(5)
                end
            end
        end,
        ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:refreshInboxTip()
        end,
        ViewEventType.NOTIFY_MENUNODE_CHANGED
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:resetMenuLocalZorder()
        end,
        ViewEventType.NOTIFY_CHANGE_GAMEMENU_ZORDER
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target)
            self:refreshOptionRedNode()
        end,
        ViewEventType.NOTIFY_CHECK_NEWMESSAGE
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
        function(self, params)
            self:checkCommonJackpotGuide()
        end,
        ViewEventType.NOTIFI_MACHINE_ONENTER
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

    gLobalNoticManager:addObserver(
        self,
        function(Target, mailCount)
            --levedashtop弹板
            self:playLeveDash()
        end,
        ViewEventType.NOTIFY_LEVEL_DASHLINK_TOP
    )

    self:refreshOptionRedNode()

    --
end -- self.m_testConfigType = creatBmt("testConfigType") -- self.m_testConfigType:setPosition(display.cx-60,-80) -- self:addChild(self.m_testConfigType, 1, 1) -- gLobalNoticManager:addObserver(self,function(self,params) --     if params then --         self.m_testConfigType:setString("testConfigType:"..params) --     else --         self.m_testConfigType:setString("testConfigType:") --     end -- end,ViewEventType.NOTIFY_SPIN_CONFIG_TYPE) -- --活动难度展示 -- self.m_testActivityDifficulty = creatBmt("testActivityDifficulty") -- self.m_testActivityDifficulty:setPosition(display.cx-60,-80-labelHeight) -- self:addChild(self.m_testActivityDifficulty, 1, 1) -- gLobalNoticManager:addObserver(self,function(self,params) --     if params then --         self.m_testActivityDifficulty:setString("difficulty:" .. params) --     else --         self.m_testActivityDifficulty:setString("difficulty:") --     end -- end,ViewEventType.NOTIFY_ACTIVITY_DIFFICULTY) -- --Quest -- self.m_questavgBet = creatBmt("questavgBet") -- self.m_questavgBet:setPosition(display.cx-60,-80-labelHeight*2) -- self:addChild(self.m_questavgBet, 1, 1) -- self.m_betDifficulty = creatBmt("betDifficulty") -- self.m_betDifficulty:setPosition(display.cx-60,-80-labelHeight*3) -- self:addChild(self.m_betDifficulty, 1, 1) -- --bingo -- self.m_bingoDifficulty = creatBmt("bingoDifficulty") -- self.m_bingoDifficulty:setPosition(display.cx-60,-80-labelHeight*4) -- self:addChild(self.m_bingoDifficulty, 1, 1) -- local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData() -- if questConfig and questConfig.p_avgBet then --     self.m_questavgBet:setString("p_avgBet:"..questConfig.p_avgBet) --     self.m_betDifficulty:setString("betDifficulty:"..questConfig.p_betDifficulty) -- end -- local bingoData = G_GetMgr(ACTIVITY_REF.Bingo):getRunningData() -- if bingoData and bingoData.difficulty ~= nil then --     self.m_bingoDifficulty:setString("bingoDifficulty:" .. tostring(bingoData.difficulty)) -- end --打印信息
-----

function GameTopNode:playLeveDash()
    if not self.m_top then
        local csbName = "Activity/LevelDashLink/csb/LevelDash_new/LevelDash_Tip.csb"
        if globalData.slotRunData.isPortrait == true then
            csbName = "Activity/LevelDashLink/csb/LevelDash_new/LevelDash_TipPro.csb"
        end
        self.m_top = util_createAnimation(csbName)
        if not self.m_top then
            return
        end
        local node = self:findChild("luckyChallengeNode")
        if not node then
            return
        end
        node:addChild(self.m_top)
        if globalData.slotRunData.isPortrait == true then
            self.m_top:setPosition(-80,130)
        else
            self.m_top:setPosition(-140,112)
        end
    end
    self.m_top:setVisible(true)
    local level = self.m_top:findChild("lb_level")
    local levelDashData = gLobalLevelRushManager:pubGetLevelRushData()
    if levelDashData then
        level:setString(util_formatCoins(levelDashData.p_endLevel, 14))
    end
    self.m_top:playAction("start",false,function()
        if tolua.isnull(self) then
            return
        end
        util_performWithDelay(
            self,
            function()
                if tolua.isnull(self) then
                    return
                end
                self.m_top:playAction("over",false,function()
                    self.m_top:setVisible(false)
                end)
            end,
            180 / 60
        )
    end)
end
function GameTopNode:checkCommonJackpotGuide()
    -- 公共jackpot关卡的引导
    if G_GetMgr(ACTIVITY_REF.CommonJackpot):checkGuide() then
        G_GetMgr(ACTIVITY_REF.CommonJackpot):startGuide(true)
    end
end

function GameTopNode:showFreecoinsAction(_isShow)
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

function GameTopNode:showSuperSpinAction(_isShow)
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

function GameTopNode:showScratchAction(_isShow)
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

--[[
    之前的打印信息
]]
function GameTopNode:checkPrintLog()
    if globalData.openDebugCode == 1 then
        local function creatBmt(name)
            -- local bmtLabel = ccui.TextBMFont:create()
            -- bmtLabel:setFntFile("Common/font_white.fnt")
            -- bmtLabel:setString("")
            -- bmtLabel:setName(name)
            -- bmtLabel:setScale(0.5)
            -- bmtLabel:setAnchorPoint(1, 0.5)
            -- return bmtLabel
            --支持汉字
            local label = cc.LabelTTF:create("", "Arial", 14)
            label:setName(name)
            label:setAnchorPoint(1, 0.5)
            return label
        end
        local labelHeight = 15
        --spin结果需要打印的字段
        if self.m_spinTxt then
            for k, v in pairs(self.m_spinTxt) do
                v:removeFromParent()
            end
        end
        self.m_spinTxt = {}
        for i = 1, #DEBUG_LOG_LIST do
            local keySpin = DEBUG_LOG_LIST[i]
            self.m_spinTxt[keySpin] = creatBmt(keySpin)
            self:addChild(self.m_spinTxt[keySpin], 1, 1)
            self.m_spinTxt[keySpin]:setPosition(display.cx - 10, -80 - labelHeight * (i - 1))
        end
    else
        if self.m_spinTxt then
            for k, v in pairs(self.m_spinTxt) do
                v:removeFromParent()
            end
        end
        self.m_spinTxt = {}
    end
end

function GameTopNode:checkSmallTip()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE or globalData.slotRunData.currSpinMode == RESPIN_MODE then
        return false
    end
    if
        (self.m_menu and self.m_menu.isShorten and (not self.m_menu:isShorten())) or self.m_pigTipsNode or self.m_levelUpShow or self.m_levelTips.m_isAction or
            (self.m_jackpotPushView and self.m_jackpotPushView.isOnShow)
     then
        return false
    end
    if globalData.slotRunData.gameEffStage == GAME_START_REQUEST_STATE then
        return false
    end

    if gLobalViewManager:getHasShowUI() then
        return false
    end
    return true
end

function GameTopNode:watchJackpotPush()
    if self:checkSmallTip() then
        if globalData.jackpotPushList and #globalData.jackpotPushList > 0 then
            local jackpotPushView = self.m_jackpotPushView
            if jackpotPushView == nil then
                jackpotPushView = util_createView("views.jackpotPushTip.JackpotPushTip")
                self.m_jackpotPushView = jackpotPushView
                self:findChild("NodeJackPot"):addChild(jackpotPushView)
                local offsetX = globalData.slotRunData.isPortrait and 25 or 50
                local distanceX = display.width - CC_DESIGN_RESOLUTION.width
                distanceX = distanceX > 0 and distanceX or 0
                local size = jackpotPushView:getMaxSize()
                jackpotPushView:setPosition(distanceX / 2 + size.width / 2 + offsetX, -size.height / 2)
            end
            jackpotPushView:setVisible(true)
            jackpotPushView:setData()
        end
    end
end

--检测是否开启促销
function GameTopNode:checkOpenSale()
    if self.m_isOpenSale then
        return
    end
    self.m_isOpenSale = true
    self.two_buttom:setVisible(true)
    self.two_buttom_tx:setVisible(true)
    self.m_one_buttom:setVisible(false)
    self.m_one_buttom_tx:setVisible(false)
    self.m_btn_layout_buy_deal:setVisible(true)
end
--检测是否可以关闭促销
function GameTopNode:checkCloseSale()
    if not self.m_isOpenSale then
        return
    end
    self.m_isOpenSale = nil
    self.two_buttom:setVisible(false)
    self.two_buttom_tx:setVisible(false)
    self.m_one_buttom:setVisible(true)
    self.m_one_buttom_tx:setVisible(true)
    self.m_btn_layout_buy_deal:setVisible(false)
    globalData.saleRunData:setShowTopeSale(false)
end

--刷新促销
function GameTopNode:updateBasicSale()
    local firstMultiData = G_GetMgr(G_REF.FirstSaleMulti):getData()
    if firstMultiData and not firstMultiData:isOver() and not firstMultiData:isRunning() then
        self:checkCloseSale()
        return
    end

    local firstCommSaleData = G_GetMgr(G_REF.FirstCommonSale):getData()
    if not globalData.saleRunData:isShowTopSale() or (firstCommSaleData and not firstCommSaleData:isCanShow()) then
        self:checkCloseSale()
        return
    end
    self:checkOpenSale()

    local saleData = G_GetMgr(G_REF.SpecialSale):getRunningData()
    local routineSaleData = G_GetMgr(G_REF.RoutineSale):getRunningData()
    if firstCommSaleData then
        saleData = firstCommSaleData
    elseif routineSaleData then
        saleData = routineSaleData
    end

    if firstMultiData and firstMultiData:isRunning() then
        local leftTime = util_getLeftTime(firstMultiData:getSaleExpireAt() * 1000)
        self:updateDeal(leftTime)
    elseif saleData then
        self:updateDeal(saleData:getLeftTime(), firstCommSaleData ~= nil)
        if saleData:getLeftTime() <= 0 then
            self:checkCloseSale()
        end
    else
        self:checkCloseSale()
    end
end

-- _bFirstSaleGift 是否是首冲礼包 促销
function GameTopNode:updateDeal(time, _bFirstSaleGift)
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

function GameTopNode:registerEvents()
    --增添观察者
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params == nil then
                return
            end
            -- local curCoinNum = self:getCurCoinNum()
            local curCoinNum = self.m_showTargetCoin
            local finalCoins = globalData.userRunData.coinNum
            -- 判断是不是立即改变钱
            local targetCoin = toLongNumber(0)
            local isPlayAnim = false
            printInfo("--GameTopNode update coin")
            if tolua.type(params) == "number" or iskindof(params, "LongNumber") then
                targetCoin:setNum("" .. params)
                isPlayAnim = true
            elseif tolua.type(params) == "table" then
                if params.coins then
                    targetCoin:setNum(params.coins)
                    printInfo("--GameTopNode setcoins = " .. targetCoin)
                    targetCoin = LongNumber.min(targetCoin, finalCoins)
                elseif params.varCoins then
                    targetCoin:setNum(curCoinNum + params.varCoins)
                    if targetCoin > finalCoins then
                        util_sendToSplunkMsg("addCoins", "game top coins greater than user coins!!!")
                    end
                    targetCoin = LongNumber.min(targetCoin, finalCoins)
                    printInfo("--GameTopNode preCoins = " .. curCoinNum)
                    printInfo("--GameTopNode varCoins = " .. params.varCoins)
                elseif (not params.coins) and (not params.varCoins) then
                    targetCoin:setNum(finalCoins)
                end
                isPlayAnim = params.isPlayEffect or false
            end

            if curCoinNum and targetCoin and targetCoin > toLongNumber(0) and curCoinNum >= targetCoin then
                isPlayAnim = false
            end
            self:notifyUpdateCoin(targetCoin, isPlayAnim)
        end,
        ViewEventType.NOTIFY_TOP_UPDATE_COIN
    )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, param)
    --         self:updateRate()
    --     end,
    --     "TopNode_updateRate"
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateExpPro(param)
        end,
        ViewEventType.NOTIFY_UPDATE_EXP_PRO
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            globalTestDataManager:levelUp(param[1])
            self:showLevelUp(param)

            self:initFrostFlameClashTopNode()
        end,
        ViewEventType.SHOW_LEVEL_UP
    )

    -- 资源下载好的事件
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:initFrostFlameClashTopNode()
        end,
        "DL_CompleteActivity_FrostFlameClash"
    )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, param)
    --         self:showPigTips(param)
    --     end,
    --     ViewEventType.NOTIFY_SHOW_PIG_TIPS
    -- )

    -- NOTIFY_USER_ENTER_LEVEL

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upCoinNode(params)
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

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upGemNode(params)
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

function GameTopNode:onExit()
    local bonusHuntData = G_GetActivityDataByRef(ACTIVITY_REF.BonusHunt) or G_GetActivityDataByRef(ACTIVITY_REF.BonusHuntCoin)
    if bonusHuntData then
        bonusHuntData.p_spinComplete = false
    end

    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        _mgr:removeCollectNodeInfo("MenuTop")
    end

    gLobalNoticManager:removeAllObservers(self)

    if self.m_scheduleID ~= nil then
        scheduler.unscheduleGlobal(self.m_scheduleID)
        self.m_scheduleID = nil
    end

    if self.m_proMoveHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_proMoveHandlerID)
        self.m_proMoveHandlerID = nil
    end

    self:stopCoinsSchedule()
    globalData.slotRunData.gameEffStage = GAME_EFFECT_OVER_STATE
    globalData.slotRunData.spinNetState = GAME_EFFECT_OVER_STATE
end

function GameTopNode:backLastWinCoinLable(addCoins)
    --停止金币滚动
    if self.m_showCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showCoinHandlerID)
        self.m_showCoinHandlerID = nil
    end

    local coinCount = globalData.userRunData.coinNum
    local coinNumLabel = self.m_coinLabel

    if addCoins and toLongNumber(addCoins) > toLongNumber(0) then
        coinCount = toLongNumber(coinCount - addCoins)
    elseif toLongNumber(globalData.recordLastWinCoin) > toLongNumber(0) then
        coinCount = toLongNumber(coinCount - globalData.recordLastWinCoin)
    end

    if coinCount > toLongNumber(0) then
        globalData.topUICoinCount = coinCount
        local coinStr = util_formatBigNumCoins(coinCount)
        coinNumLabel:setString(coinStr)

        if self.m_initPortrait then
            util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, 269, 0.44)
            -- self:updateLabelSize({label = self.m_coinLabel, sx = 0.44, sy = 0.44}, 269)
        else
            -- util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, 333,COINS_DEFAULT_SCALE)
            util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, COINS_LABEL_WIDTH, COINS_DEFAULT_SCALE)
        end
        self:changeCoinsState()
    end
end

function GameTopNode:upCoinNode(node)
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
        self.m_coinNode:setScale(self.m_csbNode:getScale())
        self.m_coinNode:setPosition(nodePos)
    -- self.m_coinNode:release()
    end
    -- self.m_coinNode:setOpacity(0)
    -- self.m_coinNode:runAction(cc.FadeIn:create(0.3))
end

function GameTopNode:refreshCoinLablePos(pos)
    if self.m_coinNodeParent then
        local coin_dollar_10 = self:findChild("coin_dollar_10")
        local diffX = coin_dollar_10:getPositionX() --金币便宜的坐标
        local size = self.m_coinNode:getContentSize()

        local nodePos = self.m_coinNode:getParent():convertToNodeSpace(cc.p(pos.x, pos.y))
        nodePos.x = nodePos.x + size.width / 2 - diffX
        self.m_coinNode:setPosition(nodePos)
    end
end

-- function GameTopNode:getCurCoinNum()
--     local coinNumLabel = self.m_coinLabel
--     local coinStr = string.gsub(coinNumLabel:getString(), ",", "")
--     local curCoinNum = 0
--     if coinStr ~= nil then
--         curCoinNum = tonumber(coinStr)
--     end
--     return curCoinNum
-- end

function GameTopNode:refreshCoinLabel(addPre, targetCoin, addCoinTime, bShowSelfCoins)
    local addPerCoins = addPre
    local addTargetCoin = 0

    local addCoins = addPre * addCoinTime
    addTargetCoin = self.m_showTargetCoin + addCoins
    printInfo("--GameTopNode refresh1 addCoins = " .. addCoins)

    local finalCoin = globalData.userRunData.coinNum

    --防止其他地方更新金币造成targetCion数值不对的情况  这里以globalData.userRunData.coinNum 为targetCoin 重新纠正下金币滚动参数
    if addTargetCoin > finalCoin then
        local curCoin = finalCoin - addCoins
        if toLongNumber(curCoin) >= toLongNumber(0) then
            self:updateCoinLabel(false, curCoin)
            addTargetCoin = finalCoin
        else
            local errMsg = string.format("GameTopNode||targetCoins:%s|showCoins:%s|finalCoins:%s|addCoins:%s|", "" .. addTargetCoin, "" .. self.m_showTargetCoin, "" .. finalCoin, "" .. addCoins)
            if DEBUG == 2 then
                if isMac() then
                    assert(false, errMsg)
                end
            else
                util_sendToSplunkMsg("coinsError", errMsg)
            end
        end
    end

    self.m_lCoinRiseNum = toLongNumber(util_replaceNum2Rand("" .. addPerCoins))
    printInfo("--GameTopNode refreshCoinLabel true")
    self:updateCoinLabel(true, addTargetCoin)
end

function GameTopNode:resetCoinNode()
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
    -- self.m_coinNode:runAction(cc.FadeOut:create(0.2))
    end
end

function GameTopNode:checkGuideClearGems()
    if self.m_gemLabel then
        self.m_gemLabel:setString(0)
        self.m_showTargetGem = 0
        util_scaleCoinLabGameLayerFromBgWidth(self.m_gemLabel, GEMS_LABEL_WIDTH, GEMS_DEFAULT_SCALE)
    end
end

function GameTopNode:refreshGemLabel(addPer, targetGem, addGemTime, bShowSelfCoins)
    local addTargetGem = 0
    if not targetGem then
        addTargetGem = self.m_showTargetGem + (addPer * addGemTime)
    else
        addTargetGem = targetGem
    end

    self.m_lGemRiseNum = addPer
    self:updateGemLabel(true, addTargetGem)
end

function GameTopNode:updateGemLabel(playUpdateAnim, targetGemCount)
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

function GameTopNode:upGemNode(node)
    local _node = self.m_gemNode
    if not self.m_gemNodeParent and _node then
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

function GameTopNode:resetGemNode()
    if self.m_gemNodeParent then
        if self.m_gemNode then
            -- self.m_gemNode:retain()
            -- self.m_gemNode:removeFromParent()
            -- self.m_gemNodeParent:addChild(self.m_gemNode)
            util_changeNodeParent(self.m_gemNodeParent, self.m_gemNode, self.m_gemNode:getZOrder())
            self.m_gemNode:setPosition(self.m_gemPos)
            self.m_gemNode:setScale(self.m_gemScale)
        -- self.m_gemNode:release()
        end
        self.m_gemNodeParent = nil
        self.m_gemPos = nil
        self.m_gemScale = nil
    end
end

function GameTopNode:stopGemUpdateAction()
    if self.m_showGemUpdateAction ~= nil then
        self:stopAction(self.m_showGemUpdateAction)
        self.m_showGemUpdateAction = nil
    end
end

function GameTopNode:updateRate()
    --测试
    if globalData.isOpenUserRate then
        local panel_rate = self:findChild("panel_rate")
        local m_lb_rate = self:findChild("m_lb_rate")
        panel_rate:setVisible(globalData.isOpenUserRate)
        local info = globalData.userRate:getLevelInfo()
        local globalInfo = globalData.userRate:getGlobalInfo()
        local msg =
            "关卡统计: \n 消耗BET = " ..
            info.usedCoins ..
                "\n 关卡赢钱 = " ..
                    info.coins ..
                        "\n SPIN次数 = " ..
                            info.spinCount ..
                                "\n FREESPIN次数 = " ..
                                    info.freeSpinCount ..
                                        "\n FREESPIN赢钱 = " ..
                                            info.freeSpinCoins ..
                                                "\n 赔率 = " ..
                                                    info.rate ..
                                                        "\n \n全局统计: \n 总计消耗BET = " ..
                                                            globalInfo.usedCoins ..
                                                                "\n 总计赢钱 = " ..
                                                                    globalInfo.coins ..
                                                                        "\n SPIN次数 = " ..
                                                                            globalInfo.spinCount ..
                                                                                "\n FREESPIN次数 = " ..
                                                                                    globalInfo.freeSpinCount .. "\n FREESPIN赢钱 = " .. globalInfo.freeSpinCoins .. "\n 赔率 = " .. globalInfo.rate .. "\n"
        m_lb_rate:setString(msg)
    else
        local panel_rate = self:findChild("panel_rate")
        panel_rate:setVisible(globalData.isOpenUserRate)
    end
end

function GameTopNode:recordLastWinCoins(targetCoin)
    -- local curCoinNum = self:getCurCoinNum()
    local updateCoin = toLongNumber(targetCoin - self.m_curCoin)
    if updateCoin > toLongNumber(0) then
        globalData.recordLastWinCoin = updateCoin
    end
end

--响应金币刷新
--
function GameTopNode:notifyUpdateCoin(targetCoin, isShowAnim)
    --记录下最近一次的赢钱
    self:recordLastWinCoins(targetCoin)

    if isShowAnim == false then
        printInfo("--GameTopNode notifyUpdateCoin false")
        self:updateCoinLabel(false, targetCoin)
    else
        local updateCoin = toLongNumber(targetCoin - self.m_curCoin)
        if toLongNumber(updateCoin) > toLongNumber(0) then
            -- gLobalSoundManager:playSound("Sounds/sound_coin_reward.mp3")
            self.m_particleShuzi:setVisible(true)
            self.m_particleShuzi:resetSystem()

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
            self.m_lCoinRiseNum = toLongNumber(util_replaceNum2Rand("" .. (updateCoin * (1 / 30))))
        else
            updateCoin = tonumber("" .. updateCoin)
            self.m_lCoinRiseNum = math.ceil(updateCoin / 30) -- 30帧变化完成， 也就是0.5秒
        end
        printInfo("--GameTopNode notifyUpdateCoin true")
        self:updateCoinLabel(true, targetCoin)
    end
    globalData.coinsSoundType = 0
end

function GameTopNode:stopCoinsSchedule()
    if self.m_showCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showCoinHandlerID)
        self.m_showCoinHandlerID = nil
    end
end
---
-- @param playUpdateAnim bool 是否播放金币变化动画
-- @param updateCoinCount number 金币变化数量， 这个与是否播放动画成对出现
--
-- 这里已经更改了COIN_NUM的数量，只是通知了变化
--
function GameTopNode:updateCoinLabel(playUpdateAnim, targetCoinCount)
    if tolua.isnull(self) then
        return
    end

    -- 转成 LongNumber
    targetCoinCount = toLongNumber(targetCoinCount)

    self:stopCoinsSchedule()

    self.m_showTargetCoin = targetCoinCount
    globalData.topUICoinCount = targetCoinCount
    printInfo("--GameTopNode targetCoin = " .. targetCoinCount)

    local _updateCoinsLabel = function(_coins)
        self.m_curCoin = _coins
        self.m_coinLabel:setString(util_formatBigNumCoins(_coins))
        if self.m_initPortrait then
            util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, 269, 0.44)
            -- self:updateLabelSize({label = self.m_coinLabel, sx = 0.44, sy = 0.44}, 269)
        else
            util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, COINS_LABEL_WIDTH, COINS_DEFAULT_SCALE)
        end
        self:changeCoinsState()

        -- if not self.m_showCoinHandlerID then
        --     printInfo("--GameTopNode curCoin    = " .. self.m_curCoin)
        -- end
    end

    local setFinalValue = function(nValue)
        local mgr = G_GetMgr(G_REF.Currency)
        if mgr then
            mgr:setCoins(nValue)
        end
    end

    if playUpdateAnim == true then
        local _curCoins = self.m_curCoin

        self.m_showCoinHandlerID =
            scheduler.scheduleUpdateGlobal(
            function(delayTime)
                _curCoins = _curCoins + self.m_lCoinRiseNum

                -- 判断是否到达目标
                if (toLongNumber(self.m_lCoinRiseNum) <= toLongNumber(0) and _curCoins <= self.m_showTargetCoin) or (toLongNumber(self.m_lCoinRiseNum) >= toLongNumber(0) and _curCoins >= self.m_showTargetCoin) then
                    _curCoins = self.m_showTargetCoin
                    setFinalValue(self.m_showTargetCoin)
                    self:stopCoinsSchedule()
                end

                _updateCoinsLabel(_curCoins)
            end
        )
    else
        if not self.m_showCoinHandlerID then
            setFinalValue(self.m_showTargetCoin)
            _updateCoinsLabel(self.m_showTargetCoin)
        end

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

    end
end

--
-- 刷新经验
function GameTopNode:updateExpPro(param)
    local exp = param[1]
    local levelNum = param[3]
    if levelNum == nil then
        levelNum = globalData.userRunData.levelNum
    end

    --设置最终目标值
    local nextProVal = param[4] or globalData.userRunData.currLevelExper
    local nextTotalProVal = globalData.userRunData:getLevelUpgradeNeedExp(levelNum)
    self.m_targetProVal = math.floor(nextProVal / nextTotalProVal * 100)

    if exp == 0 then
        self:updateLevel(levelNum)
        self:updateLevelPro(self.m_targetProVal)
        return
    end
    --立刻刷新到最新进度并且结束刷帧
    local function stopProFunc()
        self:updateLevel(levelNum)
        self:updateLevelPro(self.m_targetProVal)
        if self.m_proMoveHandlerID then
            scheduler.unscheduleGlobal(self.m_proMoveHandlerID)
            self.m_proMoveHandlerID = nil
        end
    end
    --是否升级
    local isUpgrade = param[2] or false
    if self.m_lastUpgrade then
        if isUpgrade then
            stopProFunc()
            self.m_lastUpgrade = nil
        end
        return
    end
    self.m_lastUpgrade = isUpgrade
    --设置当前值
    if not self.m_curProVal then
        local curLevel = param[3] or levelNum
        local totalProVal = globalData.userRunData:getPassLevelNeedExperienceVal()
        self.m_curProVal = math.floor(globalData.userRunData.currLevelExper / totalProVal * 100)
    end
    -- 立即停止上次的逻辑， 并且设置当前最新的数据
    if self.m_proMoveHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_proMoveHandlerID)
        self.m_proMoveHandlerID = nil
    end
    --设置速度
    local speedVal = self.m_targetProVal - self.m_curProVal + 100
    if speedVal > 100 then
        speedVal = speedVal - 100
    end
    speedVal = speedVal * 0.025
    -- 播放进度条动画
    self.m_proMoveHandlerID =
        scheduler.scheduleUpdateGlobal(
        function(dt)
            local rate = dt * 60
            self.m_curProVal = self.m_curProVal + speedVal * rate
            if isUpgrade then
                if self.m_curProVal >= 100 then
                    --需要先涨满经验值
                    self.m_curProVal = 0
                    isUpgrade = false
                    self.m_lastUpgrade = isUpgrade
                    self:updateLevel(levelNum)
                    self:updateLevelPro(100)
                    return
                end
            else
                if self.m_curProVal >= self.m_targetProVal then
                    --到了目标进度值
                    stopProFunc()
                    return
                end
            end
            --正常刷新进度动画
            self:updateLevelPro(self.m_curProVal)
        end
    )
end

-- 显示升级界面
function GameTopNode:showLevelUp(data)
    local curLevel = globalData.userRunData.levelNum
    self:initMulExp()
    globalAdjustManager:sendAdjustLevelUpLog(curLevel)

    -- csc 2021-10-25 新手期4.0优化 5.10级弹小面板
    local canPop = false
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        if curLevel == 5 or curLevel == 10 then
            canPop = true
        end
    end
    -- csc 补充原先新手期1.0 15级不弹出的问题
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        if curLevel == 15 then
            canPop = true
        end
    end

    if not canPop and (curLevel % 5 == 0 or curLevel == 2) then
    else
        self.m_levelUpShow = true
        local levelUp = util_createView("views.levelup.LevelUpNode")
        levelUp:initLevelUpData(data)
        local levelNode = self.m_csbOwner["node_levelup"]
        levelNode:addChild(levelUp)
    end
end

function GameTopNode:flyCoinsCallBack(params)
    local curLevel = params.level
    local data = params.levelUpData
    local multipleExp1 = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_LEVEL_BOOM)
    local multipleExp2 = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_LEVEL_BURST)
    if (multipleExp1 and multipleExp1 > 1) or (multipleExp2 and multipleExp2 > 1) then
        if curLevel % 10 == 9 then
            local BoostMeTip =
                util_createView(
                "GameModule.Shop.BoostMeTip",
                1,
                data,
                function()
                    self.m_levelUpShow = false
                end
            )
            if BoostMeTip then
                local levelNode = self.m_csbOwner["node_levelup"]
                levelNode:addChild(BoostMeTip)
                BoostMeTip:setPosition(0, 80)
            end
        end
    else
        self.m_levelUpShow = false
    end
end

-- --显示小猪
-- function GameTopNode:showPigTips(data)
--     if self.m_pigTipsNode then
--         return
--     end
--     self.m_pigTipsNode = util_createView("views.piggy.PiggyTips")
--     if self.m_pigTipsNode.isCsbExist ~= nil and self.m_pigTipsNode:isCsbExist() then
--         self:findChild("node_piggyeffect"):addChild(self.m_pigTipsNode)
--         self.m_pigTipsNode:setPosition(0, -50)
--         self.m_pigTipsNode:setOverFunc(
--             function()
--                 self.m_pigTipsNode = nil
--             end
--         )
--     else
--         self.m_pigTipsNode = nil
--     end
-- end

function GameTopNode:onHomeClicked()
    if globalData.userRunData:isEnterUpdateFormLevelToLobby() then
        globalData.userRunData:saveLeveToLobbyRestartInfo()
        if globalData.slotRunData.isPortrait == true then
            globalData.slotRunData.isChangeScreenOrientation = true
            globalData.slotRunData:changeScreenOrientation(false)
        end

        util_restartGame()
    else
        if globalNoviceGuideManager.guideBubbleReturnLobbyPopup then
            globalNoviceGuideManager.guideBubbleReturnLobbyPopup = nil
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect("guideBubbleReturnLobbyClick", false)
            end
        end
        if gLobalSendDataManager:getLogGuide():isGuideBegan(5) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(5, 2)
        end
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)

        -- 刷新活动数据
        gLobalSendDataManager:getNetWorkFeature():refreshActivityData()
    end
end

--点击监听
function GameTopNode:clickStartFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_isNotCanClick then
        return
    end

    if name == "btn_layout_home" then
        self.sp_home_0:setVisible(true)
        self.sp_home:setVisible(false)
    end
    if name == "btn_layout_buy_deal" then
        self.m_xiao_deal_up:setVisible(false)
        self.m_xiao_deal_down:setVisible(true)
    end
    if name == "btn_layout_buy" then
        self.sp_buy_0:setVisible(true)
        self.sp_buy:setVisible(false)
        self.m_xiao_buy_up:setVisible(false)
        self.m_xiao_buy_down:setVisible(true)
    end

    if name == "btn_layout_option" then
        self:updateOptionBtn("start")
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)
    end
end
--结束监听
function GameTopNode:clickEndFunc(sender)
    if self.m_isNotCanClick then
        return
    end

    if not self:isMinzLevel() and not self:isDiyFeatureLevel() then
        self.sp_home_0:setVisible(false)
        self.sp_home:setVisible(true)
    end
    self.m_xiao_deal_up:setVisible(true)
    self.m_xiao_deal_down:setVisible(false)
    self.sp_buy_0:setVisible(false)
    self.sp_buy:setVisible(true)
    self.m_xiao_buy_up:setVisible(true)
    self.m_xiao_buy_down:setVisible(false)

    if sender then
        local name = sender:getName()
        if name == "btn_layout_home" then
            local endPos = sender:getTouchEndPosition()
            if endPos.x > display.cx and endPos.y < 100 then
                if globalData.isOpenUserRate then
                    globalData.isOpenUserRate = false
                else
                    globalData.isOpenUserRate = true
                end
            -- self:updateRate()
            end
        elseif name == "btn_layout_option" then
            self:updateOptionBtn("end")
        end
    end
end

function GameTopNode:clickCancelFunc(sender)
    if self.m_isNotCanClick then
        return
    end

    if not self:isMinzLevel() and not self:isDiyFeatureLevel() then
        self.sp_home_0:setVisible(false)
        self.sp_home:setVisible(true)
    end
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

--
function GameTopNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_PIG_TIPS)

    if self.m_isNotCanClick then
        return
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 4})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 7})
    if name ~= "btn_layout_home" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 5})
    end

    if name == "btn_layout_home" then
        release_print("!!! click btn_layout_home")
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:onHomeClicked()
    elseif name == "btn_layout_option" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
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
            gLobalSendDataManager:getLogPopub():addNodeDot(view, name, DotUrlType.UrlName, true, DotEntrySite.UpView, DotEntryType.Game)
        end
    elseif name == "btn_spNum" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local funcShowTips = function()
            self.m_spinMulTips:show()
        end
        -- 将点击事件转送到节点里处理
        self.m_topwheelIcon:touchFunc(funcShowTips)
    elseif name == "btn_layout_buy_0" then
        --新手firebase打点
        globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.click_shop)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_shop)
        end
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "upStoreIcon")

        local params = {
            rootStartPos = sender:getTouchEndPosition(),
            shopPageIndex = 1,
            dotKeyType = name,
            dotUrlType = DotUrlType.UrlName,
            dotIsPrep = true,
            dotEntrySite = DotEntrySite.UpView,
            dotEntryType = DotEntryType.Game
        }
        G_GetMgr(G_REF.Shop):showMainLayer(params)
    elseif name == "btn_layout_buy" then
        --新手firebase打点
        globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.click_shop)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_shop)
        end
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "upStoreIcon")
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local params = {
            rootStartPos = sender:getTouchEndPosition(),
            shopPageIndex = 1,
            dotKeyType = name,
            dotUrlType = DotUrlType.UrlName,
            dotIsPrep = true,
            dotEntrySite = DotEntrySite.UpView,
            dotEntryType = DotEntryType.Game
        }
        G_GetMgr(G_REF.Shop):showMainLayer(params)
    elseif name == "btn_levelRoad" then
        G_GetMgr(G_REF.LevelRoad):showMainLayer()
    elseif name == "btn_showTips" then
        self.m_bLevelRushOpen = gLobalLevelRushManager:pubGetLevelRushBuffOpen()
        if self.m_bLevelRushOpen and not tolua.isnull(self.m_levelRushTipView) then
            self:showLevelRushView()
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            local curBuffType = self:getCurBuff()
            self.m_levelTips:show(curBuffType)
        end
    elseif name == "btn_level" then
        -- globalData.userRate:clearData()
        -- self:updateRate()
    elseif name == "btn_global" then
        -- globalData.userRate:clearGlobalData()
        -- self:updateRate()
    elseif name == "btn_layout_buy_gem" then
        --新手firebase打点
        globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.click_shop)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_shop)
        end
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "upStoreIcon")
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        local params = {
            rootStartPos = sender:getTouchEndPosition(),
            shopPageIndex = 2,
            dotKeyType = name,
            dotUrlType = DotUrlType.UrlName,
            dotIsPrep = true,
            dotEntrySite = DotEntrySite.UpView,
            dotEntryType = DotEntryType.Game
        }
        G_GetMgr(G_REF.Shop):showMainLayer(params)
    end
    -- btn_lobby  btn_pig   btn_menu   btn_buy  btn_deal
end

function GameTopNode:baseTouchEvent(sender, eventType)
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

function GameTopNode:showLevelRushTip()
    if tolua.isnull(self.m_levelRushTipView) then
        self.m_levelRushTipView = gLobalLevelRushManager:showExpTipView()
        if self.m_levelRushTipView then
            self:findChild("level_star_14"):setVisible(false)
            self:findChild("Sprite_1"):setVisible(false)
            local level_star_node = self:findChild("level_star_node")
            level_star_node:addChild(self.m_levelRushTipView)
            self.m_levelRushTipView:setOverFunc(
                function()
                    self.m_levelRushTipView = nil
                end
            )
        end
    end
end

function GameTopNode:showLevelRushView()
    if gLobalLevelRushManager:isDownloadRes() then
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "levelDash")
        local view = util_createFindView("Activity/LevelLinkSrc/LevelRush_UpView")
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
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
function GameTopNode:getTimeStamp(unixTime)
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
function GameTopNode:compareTimeStamp(nowTime, oldTime)
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
function GameTopNode:showShopBonusView(t)
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

function GameTopNode:refreshInboxTip(params)
    -- 点击option时没有params传进来，所以每次赋值要记录一下
    if params and params >= 0 then
        self.m_inboxTipNum = params
    end

    if self.m_menu and not self.m_menu:isShorten() then
        self.m_lbInboxTipSp:setVisible(false)
    else
        if self.m_inboxTipNum <= 0 then
            self.m_lbInboxTipSp:setVisible(false)
        else
            self.m_lbInboxTipSp:setVisible(true)
        end
    end

    -- 刷新inbox的同时也判断下当前是否有未读消息
    self:refreshOptionRedNode()
end
-- 5级新手新关卡提示UI start -----------------
function GameTopNode:saveNewPlayerUnlockLevelData()
    -- 记录数据
    local isEnterOtherLevel = gLobalDataManager:getNumberByField("NewPlayerUnlockLevelTip_" .. globalData.userRunData.uid, 0)
    if globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_levelName ~= "GameScreenLightCherry" then
        if isEnterOtherLevel == -1 then
            -- 进入了其他关卡
            gLobalDataManager:setNumberByField("NewPlayerUnlockLevelTip_" .. globalData.userRunData.uid, 1)
        end
    else
        if isEnterOtherLevel == 0 and globalData.userRunData.levelNum < 5 then
            -- 进入樱桃关卡如果没有赋值 设置为-1
            gLobalDataManager:setNumberByField("NewPlayerUnlockLevelTip_" .. globalData.userRunData.uid, -1)
        end
    end
end

-- 判断是否要显示5级新关卡提示ui
function GameTopNode:checkNewPlayerUnlockLevel()
    -- 判断是否要初始化创建右侧新关卡
    -- 当前关卡是否是樱桃关卡；玩家没有进入过其他关卡
    local isEnterOtherLevel = gLobalDataManager:getNumberByField("NewPlayerUnlockLevelTip_" .. globalData.userRunData.uid, 0)
    -- cxc 2021年06月23日16:09:54 不弹出这个板子了
    if
        not globalData.GameConfig:checkUseNewNoviceFeatures() and globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_levelName == "GameScreenLightCherry" and
            isEnterOtherLevel == -1 and
            globalData.userRunData.levelNum >= globalData.constantData.MOREGAME_TIPS_LEVEL
     then
        return true
    end
    return false
end

function GameTopNode:showNewPlayerUnlockLevelTip()
    if not self.m_unlockLevelTip then
        self.m_unlockLevelTip = util_createView("views.UnlockLevelTip.UnlockLevelTip")
        self:addChild(self.m_unlockLevelTip, -1)
        self.m_unlockLevelTip:setPosition(cc.p(display.cx, -display.cy + 70))
        if globalData.slotRunData.isPortrait == true then
            self.m_unlockLevelTip:setScale(0.7)
        end
    end
end
-- 5级新手新关卡提示UI end -----------------

-- 设置按钮初始化
function GameTopNode:initOptionBtn()
    local menuNode = self:findChild("node_option")
    self.m_menu = menuNode:getChildByName("optionMenu")
    if not self.m_menu then
        local bDeluxe = globalData.slotRunData.isDeluexeClub
        self.m_menu = util_createView("views.menu.MenuNode", 1, bDeluxe)
        self.m_menu:setName("optionMenu")
        menuNode:addChild(self.m_menu)
    end

    self.m_menu:idleLengthen()

    --csc 2021年05月19日21:44:06 去掉 2级paytable 引导
    if not globalData.GameConfig:checkUseNewNoviceFeatures() then
        globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.payTable, menuNode)
    end
    --升级界面要在他上面
    -- if globalData.slotRunData.isPortrait == true then
    --     menuNode:setLocalZOrder(-2)
    --     local lbInboxTipSp = self:findChild("sprite_inbox_tip")
    --     if lbInboxTipSp then
    --         lbInboxTipSp:setLocalZOrder(-1)
    --     end
    -- end
end

-- 设置按钮状态更换
function GameTopNode:updateOptionBtn(status)
    if not self.m_menu then
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_GAMEMENU_ZORDER)
    if status == "start" then
        if self.m_menu:isShorten() == true then
            -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self.m_menu:beginLengthen()
        else
            -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
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
--开启引导
function GameTopNode:setGuide()
    if not self.m_menuLastPos and self.m_menu then
        self.m_menuLastPos = cc.p(self.m_menu:getPosition())
        self.m_menuScale = self.m_menu:getScale()
        local wordPos = self.m_menu:getParent():convertToWorldSpace(self.m_menuLastPos)
        util_changeNodeParent(gLobalViewManager:getViewLayer(), self.m_menu, ViewZorder.ZORDER_GUIDE)
        self.m_menu:setPosition(wordPos)
        self.m_menu:setScale(self.m_csbNode:getScale())
    end
end
--重置层级
function GameTopNode:resetMenuLocalZorder()
    if self.m_menuLastPos and self.m_menu then
        local menuNode = self:findChild("node_option")
        util_changeNodeParent(menuNode, self.m_menu)
        self.m_menu:setPosition(self.m_menuLastPos)
        self.m_menu:setScale(self.m_menuScale)
        self.m_menuScale = nil
        self.m_menuLastPos = nil
    end
end

-- 新增设置按钮体现小红点
function GameTopNode:refreshOptionRedNode()
    if self.m_menu and not self.m_menu:isShorten() then
        self.m_lbInboxTipSp:setVisible(false)
    else
        if globalData.newMessageNums and globalData.newMessageNums > 0 then
            self.m_lbInboxTipSp:setVisible(true)
        else
            self.m_lbInboxTipSp:setVisible(false)
        end
    end
end

-- function GameTopNode:updateGemLabel(isPlayAction, gemNum)
--     if self.m_gemLabel then
--         self.m_gemLabel:setString(util_getFromatMoneyStr(gemNum))
--         util_scaleCoinLabGameLayerFromBgWidth(self.m_gemLabel, 149, 0.6)
--     end
-- end

function GameTopNode:initFlamingoJackpotTopNode()
    local FJackpotNode = self:findChild("node_FlamingoJackpot")
    if FJackpotNode then
        if G_GetMgr(ACTIVITY_REF.FlamingoJackpot):checkGameTopNode() then
            if not self.m_flamingoJackpotTopNode then
                self.m_flamingoJackpotTopNode = G_GetMgr(ACTIVITY_REF.FlamingoJackpot):createGameTopNode()
                FJackpotNode:addChild(self.m_flamingoJackpotTopNode)
            end
        end
    end
end


function GameTopNode:initFrostFlameClashTopNode()
    local FrostFlameClashNode = self:findChild("node_FrostFlameClash")
    if FrostFlameClashNode then
        if tolua.isnull(self.m_frostFlameClashTopNode) and G_GetMgr(ACTIVITY_REF.FrostFlameClash):checkGameTopNode() then
            self.m_frostFlameClashTopNode = G_GetMgr(ACTIVITY_REF.FrostFlameClash):createGameTopNode()
            FrostFlameClashNode:addChild(self.m_frostFlameClashTopNode)
        end
    end
end

return GameTopNode
