--[[
    大奖单独界面
]]
local CardNadoWheelBigCoinOver = class("CardNadoWheelBigCoinOver", BaseLayer)

function CardNadoWheelBigCoinOver:initDatas(_count, _coinNum, _over)
    self.m_count = _count
    self.m_coinNum = _coinNum
    self.m_over = _over
    self.m_unClickBigIcon = true
    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardNadoWheelBigCoinOverRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
end

function CardNadoWheelBigCoinOver:initCsbNodes()
    self.m_root = self:findChild("root")
    self.m_nodeBigCoinIcon = self:findChild("node_bigcoin")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
    self.m_btnCollect = self:findChild("Button_collect")
    self.m_btnCollect:setTouchEnabled(false)
end

function CardNadoWheelBigCoinOver:onShowedCallFunc()
end

function CardNadoWheelBigCoinOver:initView()
    self:initCoins()
    self.m_bigCoinIcon = self:createBigCoinIcon()

    self.m_isPlayingStart = true
    self:playShow1()
    util_performWithDelay(
        self,
        function()
            if not tolua.isnull(self) and self.m_bigCoinIcon then
                self.m_bigCoinIcon:playShow(
                    function()
                        self.m_isPlayingStart = false
                    end
                )
            end
        end,
        15 / 30
    )
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
end

function CardNadoWheelBigCoinOver:createBigCoinIcon()
    local bigIcon =
        util_createView(
        "GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelBigCoinIcon",
        self.m_count,
        function()
            if not tolua.isnull(self) and self.clickBigIcon then
                self:clickBigIcon()
            end
        end
    )
    self.m_nodeBigCoinIcon:addChild(bigIcon)
    return bigIcon
end

function CardNadoWheelBigCoinOver:initCoins()
    self.m_lbCoin:setString(util_formatCoins(self.m_coinNum, 30))
    local UIList = {}
    table.insert(UIList, {node = self.m_spCoin})
    table.insert(UIList, {node = self.m_lbCoin, alignY = 4})
    util_alignCenter(UIList)
end

function CardNadoWheelBigCoinOver:playShow1(_over)
    self:runCsbAction(
        "show1",
        false,
        function()
            if _over then
                _over()
            end
        end,
        30
    )
end

function CardNadoWheelBigCoinOver:playShow2(_over)
    self:runCsbAction(
        "show2",
        false,
        function()
            if _over then
                _over()
            end
        end,
        30
    )
end

function CardNadoWheelBigCoinOver:flyCoins(_coinNum, _flyOver)
    -- 屏蔽点击
    if not (self.m_btnCollect and _coinNum > 0) then
        if _flyOver then
            _flyOver()
        end
        return
    end
    self.m_isFlyingCoins = true
    local startPos = self.m_btnCollect:getParent():convertToWorldSpace(cc.p(self.m_btnCollect:getPosition()))
    local endPos = globalData.flyCoinsEndPos
    local baseCoins = globalData.topUICoinCount
    local view = gLobalViewManager:getFlyCoinsView()
    view:pubShowSelfCoins(true)
    local view =
        gLobalViewManager:pubPlayFlyCoin(
        startPos,
        endPos,
        baseCoins,
        _coinNum,
        function()
            self.m_isFlyingCoins = false
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {coins = baseCoins + _coinNum, isPlayEffect = false})
            if _flyOver then
                _flyOver()
            end
        end
    )
end

function CardNadoWheelBigCoinOver:canClickCollect()
    if self.m_closed then
        return false
    end
    if self.m_isPlayingStart then
        return false
    end
    if self.m_isClickingBigIcon then -- 正在点击大奖icon，并且播放大奖icon的动作，不能点击
        return false
    end
    if self.m_unClickBigIcon then -- 未点击过大奖icon，不能点击
        return false
    end
    if self.m_isFlyingCoins then
        return false
    end
    if self.m_isClickedCollect then
        return true
    end
    return true
end

function CardNadoWheelBigCoinOver:canClickBigIcon()
    if self.m_closed then
        return false
    end
    if self.m_isPlayingStart then
        return false
    end
    if self.m_isClickingBigIcon then -- 正在点击大奖icon，并且播放大奖icon的动作，不能点击
        return false
    end
    return true
end

function CardNadoWheelBigCoinOver:clickBigIcon()
    if not self:canClickBigIcon() then
        return
    end
    print("---clickBigIcon---1")
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.m_unClickBigIcon = false
    self.m_isClickingBigIcon = true
    self.m_bigCoinIcon:playOpen1(
        function()
            print("---clickBigIcon---2")
            if not tolua.isnull(self) and self.m_bigCoinIcon then
                self.m_bigCoinIcon:playOpen2()
                util_performWithDelay(
                    self,
                    function()
                        print("---clickBigIcon---3")
                        self:playShow2(
                            function()
                                print("---clickBigIcon---4")
                                self.m_isClickingBigIcon = false
                                if not tolua.isnull(self) and self.m_btnCollect then
                                    self.m_btnCollect:setTouchEnabled(true)
                                end
                            end
                        )
                    end,
                    5 / 30
                )
            end
        end
    )
end

function CardNadoWheelBigCoinOver:onClickMask()
    self:onClickCollect()
end

function CardNadoWheelBigCoinOver:onClickCollect()
    if not self:canClickCollect() then
        return
    end

    self.m_isClickedCollect = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:flyCoins(
        self.m_coinNum,
        function()
            if not tolua.isnull(self) and self.closeUI then
                self:closeUI()
            end
        end
    )
end

function CardNadoWheelBigCoinOver:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_collect" then
        self:onClickCollect()
    end
end

function CardNadoWheelBigCoinOver:closeUI()
    if self.m_closed then
        return
    end
    self.m_closed = true
    self:runCsbAction(
        "over",
        false,
        function()
            CardNadoWheelBigCoinOver.super.closeUI(
                self,
                function()
                    if self.m_over then
                        self.m_over()
                    end
                end
            )
        end,
        30
    )
end

return CardNadoWheelBigCoinOver
