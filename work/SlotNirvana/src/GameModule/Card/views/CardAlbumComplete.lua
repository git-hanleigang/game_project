--[[
    -- 赛季集齐面板
    author:{author}
    time:2019-10-16 11:26:53
]]
local BaseCardComplete = util_require("GameModule.Card.baseViews.BaseCardComplete")
local CardAlbumComplete = class("CardAlbumComplete", BaseCardComplete)
CardAlbumComplete.m_audioID_yanhua = nil
CardAlbumComplete.m_audioID_bg = nil
function CardAlbumComplete:initUI(params)
    BaseCardComplete.initUI(self, params)
    self:clearMusic()
    self:updateUI()
end

function CardAlbumComplete:clickFunc(sender)
    BaseCardComplete.clickFunc(self, sender)

    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_collect" then
        if self.m_clickCollect then
            return
        end
        self.m_clickCollect = true
        local Node_jinbi = self:findChild("ml_b_coins")
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        if Node_jinbi then
            self:flyCoins(
                sender,
                self.m_params.coins,
                function()
                    CardSysManager:closeCardCollectComplete()
                end
            )
        else
            CardSysManager:closeCardCollectComplete()
        end
    end
end

function CardAlbumComplete:closeUI()
    if self.isClose then
        return
    end
    gLobalSoundManager:resumeBgMusic()
    self:clearMusic()

    self.isClose = true
    self:runCsbAction(
        "over",
        false,
        function()
            self:removeFromParent()
        end,
        60
    )
end

function CardAlbumComplete:clearMusic()
    if self.m_audioID_bg then
        gLobalSoundManager:stopAudio(self.m_audioID_bg)
        self.m_audioID_bg = nil
    end
    if self.m_audioID_yanhua then
        gLobalSoundManager:stopAudio(self.m_audioID_yanhua)
        self.m_audioID_yanhua = nil
    end
    if self.m_coinjumpSound then
        gLobalSoundManager:stopAudio(self.m_coinjumpSound)
        self.m_coinjumpSound = nil
    end

    if self.m_goodjob then
        gLobalSoundManager:stopAudio(self.m_goodjob)
        self.m_goodjob = nil
    end
    if self.m_piaodai then
        gLobalSoundManager:stopAudio(self.m_piaodai)
        self.m_piaodai = nil
    end
end

function CardAlbumComplete:updateUI()
    CardAlbumComplete.super.updateUI(self)
    self:updateEffect(true, true)
    self:updateAlbum()
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
    local sp_coins = self:findChild("sp_coins")
    --适配文字和金币
    labelCoins:setString(util_getFromatMoneyStr(endValue))
    self:updateLabelSize({label = labelCoins}, 416)
    local width = math.min(416, labelCoins:getContentSize().width) * 0.5
    local posx, posy = labelCoins:getPosition()
    sp_coins:setPosition(posx - width - 60, posy)

    labelCoins:setString("0")
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
                end
            )
        end,
        60
    )

    -- TODO:
    local album_icon = self:findChild("album_icon")
    -- util_changeTexture(album_icon, )
end

return CardAlbumComplete
