local CardAlbumComplete201903 = util_require("GameModule.Card.season201903.CardAlbumComplete")
local CardAlbumComplete = class("CardAlbumComplete", CardAlbumComplete201903)

function CardAlbumComplete:initUI(params)
    CardAlbumComplete.super.initUI(self, params)
    self:initTimeLimitExpansionLogo()
end

function CardAlbumComplete:initTimeLimitExpansionLogo()
    local node = self:findChild("Node_TimeLimitExpansion")
    local mgr = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion)
    if node and mgr then
        local logo = mgr:getTimeLimitExpansionIcon()
        if logo then
            node:addChild(logo)
        end
    end
end

function CardAlbumComplete:updateAlbum()
    -- 数据处理
    local coins = self.m_params.coins
    local rewards = self.m_params.rewards
    local albumId = self.m_params.albumId

    local startValue = 0
    local endValue = tonumber(coins)
    local addValue = (endValue - startValue) / 15

    self.m_goodjob = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteGoodjob)
    -- UI处理
    local labelCoins = self:findChild("ml_b_coins")
    local spCoins = self:findChild("sp_coins")
    labelCoins:setString("")
    spCoins:setVisible(false)
    performWithDelay(
        self,
        function()
            self.m_piaodai = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteLvpiaodai)
        end,
        2
    )
    gLobalSoundManager:pauseBgMusic()
    self:runCsbAction(
        "show_a",
        false,
        function()
            self.m_audioID_bg = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteBg)
            self.m_audioID_yanhua = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteYanhua, true)
            self.m_coinjumpSound = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.RecoverWheelCoinRaise2, true)
            util_jumpNum(
                labelCoins,
                startValue,
                endValue,
                addValue,
                0.05,
                {30},
                nil,
                nil,
                function()
                    if self.m_coinjumpSound then
                        gLobalSoundManager:stopAudio(self.m_coinjumpSound)
                        self.m_coinjumpSound = nil
                    end
                    self:runCsbAction(
                        "show_b",
                        false,
                        function()
                            self:runCsbAction("idle", true, nil, 60)
                        end,
                        60
                    )
                end,
                function()
                    spCoins:setVisible(true)
                    util_alignCenter(
                        {
                            {node = spCoins, scale = 1, anchor = cc.p(0.5, 0.5)},
                            {node = labelCoins, scale = 0.7, anchor = cc.p(0.5, 0.5)}
                        }
                    )
                end
            )
        end,
        60
    )
end

return CardAlbumComplete
