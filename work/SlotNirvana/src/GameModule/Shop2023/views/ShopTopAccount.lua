local ShopTopAccount = class("ShopTopAccount", util_require("base.BaseView"))

local COINS_LABEL_WIDTH = 100 -- 290 -- 金币控件的长度
local COINS_LABEL_WIDTH_V = 100 -- 290 -- 金币控件的长度
local COINS_DEFAULT_SCALE = 1 -- 0.6 -- 金币控件的缩放
local GEMS_LABEL_WIDTH = 100 -- 钻石控件的长度
local GEMS_DEFAULT_SCALE = 1 -- 0.6 -- 钻石控件的缩放
function ShopTopAccount:initUI(_type, _isPortrait)
    self:createCsbNode(self:getCsbName(_isPortrait))
    local coinNum = "0"
    local gemNum = 0
    local mgr = G_GetMgr(G_REF.Currency)
    if mgr then
        coinNum = mgr:getCoins()
        gemNum = mgr:getGems()
    else
        coinNum = globalData.userRunData.coinNum
        gemNum = globalData.userRunData.gemNum
    end

    self:updateCoinLabel(false, "" .. coinNum)

    self:updateGemLabel(false, gemNum or 0)
end

function ShopTopAccount:getCsbName(_isPortrait)
    if _isPortrait then
        return SHOP_RES_PATH.AccountNodeV
    end
    return SHOP_RES_PATH.AccountNodeH
end

function ShopTopAccount:initCsbNodes()
    self.m_coinNode = self:findChild("lab_coin_bg")
    self.m_coinLabel = self:findChild("txt_coins")
    self.m_labGems = self:findChild("txt_gems")
    self.m_gemNode = self:findChild("node_lab_gem")
end

function ShopTopAccount:setMainLayerScale(_scale)
    self.m_shopMainLayerScale = _scale or self.m_csbNode:getScale()
end

function ShopTopAccount:resetGlobalFlyCoinNode()
    -- 从新设置金币飞行的终点位置
    self.m_orgflyCoinsEndPos = globalData.flyCoinsEndPos
    local nodeCoins = self:findChild("coin_dollar")
    local endPos = nodeCoins:getParent():convertToWorldSpace(cc.p(nodeCoins:getPosition()))
    globalData.flyCoinsEndPos = endPos
    -- 金币钻石位置
    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        local isPortrait = globalData.slotRunData.isPortrait
        local coinNode = self:findChild("coin_dollar")
        _mgr:addCollectNodeInfo(FlyType.Coin, coinNode, "ShopTop", isPortrait)
        local gemNode = self:findChild("gem_dollar")
        _mgr:addCollectNodeInfo(FlyType.Gem, gemNode, "ShopTop", isPortrait)
    end
end

function ShopTopAccount:upCoinNode(node)
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
        local _scale = self.m_shopMainLayerScale
        self.m_coinNode:setScale(_scale)
        self.m_coinNode:setPosition(nodePos)
        -- self.m_coinNode:release()
        
    end
end

function ShopTopAccount:refreshCoinLabel(addPre, targetCoin, addCoinTime, bShowSelfCoins)
    -- self:stopCoinUpdateAction()
    local addPerCoins = addPre
    local addTargetCoin = 0
    if not targetCoin then
        addTargetCoin = self.m_showTargetCoin + (addPre * addCoinTime)
    else
        addTargetCoin = targetCoin
    end

    -- self.m_showTargetCoin = addTargetCoin
    self.m_lCoinRiseNum = toLongNumber(util_replaceNum2Rand("" .. addPerCoins))
    self:updateCoinLabel(true, addTargetCoin)
end

-- function ShopTopAccount:getCurCoinNum()
--     local coinNumLabel = self.m_coinLabel
--     local coinStr = string.gsub(coinNumLabel:getString(), ",", "")
--     local curCoinNum = 0
--     if coinStr ~= nil then
--         curCoinNum = tonumber(coinStr)
--     end
--     return curCoinNum
-- end

function ShopTopAccount:updateCoinLabel(playUpdateAnim, targetCoinCount)
    if tolua.isnull(self) then
        return
    end

    -- 转成 LongNumber
    targetCoinCount = toLongNumber(targetCoinCount)

    self:stopCoinUpdateAction()

    self.m_showTargetCoin = targetCoinCount
    --记录下显示金币数量
    globalData.topUICoinCount = targetCoinCount

    -- 金币长度
    local coinW = globalData.slotRunData.isPortrait and COINS_LABEL_WIDTH_V or COINS_LABEL_WIDTH

    local _updateCoinsLabel = function(_coins)
        self.m_curCoin = _coins
        -- self.m_coinLabel:setString(util_formatBigNumCoins(_coins, 4, nil, 2))
        self.m_coinLabel:setString(util_formatCoins(_coins, 4, nil, 2, nil, nil, nil, true, " "))
        util_scaleCoinLabGameLayerFromBgWidth(self.m_coinLabel, coinW, COINS_DEFAULT_SCALE)
    end

    local setFinalValue = function(nValue)
        local mgr = G_GetMgr(G_REF.Currency)
        if mgr then
            mgr:setCoins(nValue)
        end
    end

    if playUpdateAnim == true then
        -- self.m_showCoinHandlerID = scheduler.scheduleUpdateGlobal(function(delayTime)
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

function ShopTopAccount:resetCoinNode()
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
end

function ShopTopAccount:stopCoinUpdateAction()
    if self.m_showCoinUpdateAction ~= nil then
        self:stopAction(self.m_showCoinUpdateAction)
        self.m_showCoinUpdateAction = nil
    end
end

function ShopTopAccount:refreshGemLabel(addPer, targetGem, addGemTime, bShowSelfCoins)
    local addTargetGem = 0
    if not targetGem then
        addTargetGem = self.m_showTargetGem + (addPer * addGemTime)
    else
        addTargetGem = targetGem
    end

    self.m_lGemRiseNum = addPer
    self:updateGemLabel(true, addTargetGem)
end

function ShopTopAccount:updateGemLabel(playUpdateAnim, targetGemCount)
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
        if self.m_labGems then
            gemNum = gemNum or globalData.userRunData.gemNum
            -- 取整，防止长度不断变化
            -- 取整，防止长度不断变化
            gemNum = math.floor(gemNum or 0)
            self.m_labGems:setString(util_formatCoins(gemNum, 4, nil, 2))
            -- self.m_labGems:setString(util_getFromatMoneyStr(gemNum))
            util_scaleCoinLabGameLayerFromBgWidth(self.m_labGems, GEMS_LABEL_WIDTH, GEMS_DEFAULT_SCALE)
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

function ShopTopAccount:upGemNode(node)
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
        local _scale = self.m_shopMainLayerScale
        _node:setScale(_scale)
        _node:setPosition(nodePos)
        -- _node:release()
    end
end

function ShopTopAccount:resetGemNode()
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

function ShopTopAccount:stopGemUpdateAction()
    if self.m_showGemUpdateAction ~= nil then
        self:stopAction(self.m_showGemUpdateAction)
        self.m_showGemUpdateAction = nil
    end
end

function ShopTopAccount:onEnter()
    -- 金币刷新相关
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upCoinNode(params)
        end,
        ViewEventType.NOTIFY_NEWSHOP_UP_COIN_LABEL
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
            local gems = params or globalData.userRunData.gemNum
            self:updateGemLabel(false, gems)
        end,
        ViewEventType.NOTIFY_TOP_UPDATE_GEM
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upGemNode(params)
        end,
        ViewEventType.NOTIFY_NEWSHOP_UP_GEM_LABEL
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

function ShopTopAccount:onExit()
    -- 还原回去 可能存在动画还没播放完毕就点击了关闭按钮
    if self.m_orgflyCoinsEndPos then
        globalData.flyCoinsEndPos = self.m_orgflyCoinsEndPos
    end

    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        _mgr:removeCollectNodeInfo("ShopTop")
    end

    ShopTopAccount.super.onExit(self)
end

return ShopTopAccount
