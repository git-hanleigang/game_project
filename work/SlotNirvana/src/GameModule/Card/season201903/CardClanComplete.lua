--[[
    -- 章节集齐面板
    author:{author}
    time:2019-10-16 11:29:36
]]
local BaseCardComplete = util_require("GameModule.Card.baseViews.BaseCardComplete")
local CardClanComplete = class("CardClanComplete", BaseCardComplete)
CardClanComplete.m_audioID_bg = nil
function CardClanComplete:initUI(params)
    CardClanComplete.super.initUI(self, params)
    self:clearMusic()
    self:updateUI()
end

function CardClanComplete:clickFunc(sender)
    CardClanComplete.super.clickFunc(self, sender)

    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_collect" then
        if self.m_clickCollect then
            return
        end
        self.m_clickCollect = true
        local Node_jinbi = self:findChild("bmf_coins")
        if Node_jinbi then
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
            self:flyCoins(
                sender,
                self.m_params.clanReward.coins,
                function()
                    CardSysManager:closeCardCollectComplete()
                end
            )
        else
            CardSysManager:closeCardCollectComplete()
        end
    end
end

function CardClanComplete:closeUI(_over)
    if self.isClose then
        return
    end
    self.isClose = true
    gLobalSoundManager:resumeBgMusic()
    self:clearMusic()
    CardClanComplete.super.closeUI(self, _over)
end

function CardClanComplete:clearMusic()
    if self.m_audioID_bg then
        gLobalSoundManager:stopAudio(self.m_audioID_bg)
        self.m_audioID_bg = nil
    end
    if self.m_coinjumpSound then
        gLobalSoundManager:stopAudio(self.m_coinjumpSound)
        self.m_coinjumpSound = nil
    end
    if self.m_goodjob then
        gLobalSoundManager:stopAudio(self.m_goodjob)
        self.m_goodjob = nil
    end
    if self.m_zhangjie then
        gLobalSoundManager:stopAudio(self.m_zhangjie)
        self.m_zhangjie = nil
    end
    if self.m_done then
        gLobalSoundManager:stopAudio(self.m_done)
        self.m_done = nil
    end
end

function CardClanComplete:updateUI()
    CardClanComplete.super.updateUI(self)
    self:updateClan()
end

function CardClanComplete:updateClan()
    -- 数据处理
    local coins = self.m_params.clanReward.coins
    local rewards = self.m_params.clanReward.rewards
    local clanID = self.m_params.clanId
    local clanIcon = CardResConfig.getCardClanIcon(clanID)

    -- UI处理
    local root = self:findChild("tanban3")
    local clanLogo = self:findChild("clan_logo")
    local clanLogoNode = self:findChild("Node_clanlogo")
    self.m_bmf_coins = self:findChild("bmf_coins")
    local sp_coins = self:findChild("sp_coins")
    --适配文字和金币
    self.m_bmf_coins:setString(util_getFromatMoneyStr(coins))
    self:updateLabelSize({label = self.m_bmf_coins}, 400)
    local width = math.min(416, self.m_bmf_coins:getContentSize().width) * 0.5
    local posx, posy = self.m_bmf_coins:getPosition()
    sp_coins:setPosition(posx - width - 60, posy - 3)

    self.m_bmf_coins:setString("")
    self.m_addStr = ""

    util_changeTexture(clanLogo, clanIcon)

    self.m_startValue = tonumber(coins) * 0.5
    self.m_endValue = tonumber(coins)
    self.m_addValue = (self.m_endValue - self.m_startValue) / 15
    gLobalSoundManager:pauseBgMusic()
    self.m_goodjob = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteGoodjob)
    performWithDelay(
        self,
        function()
            self.m_zhangjie = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteChinafortune)
        end,
        1
    )
    performWithDelay(
        self,
        function()
            self.m_done = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteDone)
        end,
        1.8
    )

    self:setCloseBtnVisible(false)
end

function CardClanComplete:playShowAction()
    local _action = function(callback)
        self:runCsbAction(
            "start_1",
            false,
            function()
                self.m_audioID_bg = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteBg)
                self.m_coinjumpSound = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.RecoverWheelCoinRaise2, true)
                util_jumpNum(
                    self.m_bmf_coins,
                    self.m_startValue,
                    self.m_endValue,
                    self.m_addValue,
                    0.05,
                    {30},
                    nil,
                    self.m_addStr,
                    function()
                        if self.m_coinjumpSound then
                            gLobalSoundManager:stopAudio(self.m_coinjumpSound)
                            self.m_coinjumpSound = nil
                        end
                        self:setCloseBtnVisible(true)
                        self:runCsbAction(
                            "start_2",
                            false,
                            function()
                                self:runCsbAction("idle", true, nil, 60)
                                if callback then
                                    callback()
                                end
                            end,
                            60
                        )
                    end
                )
            end,
            60
        )
    end
    CardClanComplete.super.playShowAction(self, _action)
end

function CardClanComplete:setCloseBtnVisible(isVisible)
    -- self.m_Button_x = self:findChild("Button_x")
    -- if self.m_Button_x then
    --     self.m_Button_x:setVisible(isVisible)
    -- end
end

return CardClanComplete
