--[[
    -- 章节集齐面板
    author:{author}
    time:2019-10-16 11:29:36
]]
local BaseCardComplete = util_require("GameModule.Card.baseViews.BaseCardComplete")
local CardClanComplete = class("CardClanComplete", BaseCardComplete)
CardClanComplete.m_audioID_bg = nil
function CardClanComplete:initUI(params)
    BaseCardComplete.initUI(self, params)
    self:clearMusic()

    -- 通用按钮 201902年老按钮用的另一个描述
    if params and params.csb and string.find(params.csb, "CardComplete201902_zhangjie") then
        local LanguageKey = "CardClanComplete:Button_collect201902"
        local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "COLLECT NOW"
        self:setButtonLabelContent("Button_collect", refStr)
    end

    self:updateUI()
end

function CardClanComplete:clickFunc(sender)
    BaseCardComplete.clickFunc(self, sender)

    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_collect" then
        if self.m_clickCollect then
            return
        end
        self.m_clickCollect = true
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        local Node_jinbi = self:findChild("bmf_coins")
        release_print("---------------------- 1778667, crash report setPoint, CardClanComplete 1--------")
        if Node_jinbi then
            self:flyCoins(
                sender,
                self.m_params.clanReward.coins,
                function()
                    release_print("---------------------- 1778667, crash report setPoint, CardClanComplete 2--------")
                    CardSysManager:closeCardCollectComplete()
                end
            )
        else
            CardSysManager:closeCardCollectComplete()
        end
    end
end

function CardClanComplete:closeUI()
    if self.isClose then
        return
    end
    release_print("---------------------- 1778667, crash report setPoint, CardClanComplete:closeUI 1--------")
    gLobalSoundManager:resumeBgMusic()
    release_print("---------------------- 1778667, crash report setPoint, CardClanComplete:closeUI 2--------")
    self:clearMusic()
    release_print("---------------------- 1778667, crash report setPoint, CardClanComplete:closeUI 3--------")
    self.isClose = true
    self:runCsbAction(
        "over",
        false,
        function()
            release_print("---------------------- 1778667, crash report setPoint, CardClanComplete:closeUI 4--------")
            self:removeFromParent()
        end,
        60
    )
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
    self:updateEffect(true, true)
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
    local bmf_coins = self:findChild("bmf_coins")
    local sp_coins = self:findChild("sp_coins")
    --适配文字和金币
    bmf_coins:setString(util_getFromatMoneyStr(coins))
    self:updateLabelSize({label = bmf_coins}, 440)
    local width = math.min(416, bmf_coins:getContentSize().width) * 0.5
    local posx, posy = bmf_coins:getPosition()
    sp_coins:setPosition(posx - width - 60, posy - 3)

    bmf_coins:setString("")

    util_changeTexture(clanLogo, clanIcon)

    local str = string.sub(clanID, 1, 6)
    -- 因为一些数据没有进入集卡系统时是空的，只能临时判断， 资源整理的太乱了
    if str == "201901" then
        clanLogoNode:setScale(1)
    elseif str == "201902" then
        if tonumber(clanID) == 20190221 or tonumber(clanID) == 20190222 or tonumber(clanID) == 20190223 then
            clanLogoNode:setScale(0.7)
        else
            clanLogoNode:setScale(1.3)
        end
    end

    local startValue = tonumber(coins) * 0.5
    local endValue = tonumber(coins)
    local addValue = (endValue - startValue) / 15
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

    -- local Button_x = self:findChild("Button_x")
    -- Button_x:setVisible(false)
    self:runCsbAction(
        "start_1",
        false,
        function()
            self.m_audioID_bg = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompleteBg)
            self.m_coinjumpSound = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.RecoverWheelCoinRaise2, true)
            util_jumpNum(
                bmf_coins,
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
                    -- Button_x:setVisible(true)
                    self:runCsbAction(
                        "start_2",
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
end

return CardClanComplete
