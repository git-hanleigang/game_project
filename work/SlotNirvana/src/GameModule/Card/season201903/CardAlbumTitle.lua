--[[--
    章节选择界面的标题
]]
local CardAlbumTitle = class("CardAlbumTitle", BaseView)

function CardAlbumTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardAlbumTitleRes, "season201903")
end

function CardAlbumTitle:getTimeLua()
    return "GameModule.Card.season201903.CardSeasonTime"
end

function CardAlbumTitle:initUI(mainClass)
    self.m_mainClass = mainClass
    CardAlbumTitle.super.initUI(self)
    self:initView()
end

function CardAlbumTitle:initCsbNodes()
    self.m_lb_coins = self:findChild("coins")
    self.m_lb_pro = self:findChild("process")
    -- self.m_sp_zi = self:findChild("zi_1")
    self.m_posNode = self:findChild("Node_pos")
    self.m_timeNode = self:findChild("Node_time")
    self.m_btnClose = self:findChild("Button_x")
end

function CardAlbumTitle:initView()
    self:initTime()
end

function CardAlbumTitle:initTime()
    -- 赛季结束时间戳
    local ui = util_createView(self:getTimeLua())
    self.m_timeNode:addChild(ui)
end

function CardAlbumTitle:updateUI(isPlayStart)
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    if not albumData then
        return
    end

    self.m_lb_pro:setString(albumData.current .. "/" .. albumData.total)

    local isCompleted = albumData.current >= albumData.total
    if isCompleted then
        if isPlayStart then
            self:runCsbAction(
                "show1",
                false,
                function()
                    self:runCsbAction("idle1", true, nil)
                end
            )
        else
            self:runCsbAction("idle1", true, nil)
        end
    else
        local coins = tonumber(albumData.coins)
        local specialReward = 1
        if G_GetMgr(ACTIVITY_REF.CardEndSpecial):getRunningData() then
            specialReward = globalData.constantData.CARD_SPECIAL_REWAR or 1
        end
        self.m_lb_coins:setString(util_formatCoins(coins * specialReward, 33))

        -- local size = self.m_lb_coins:getContentSize()
        -- local scale = self.m_lb_coins:getScale()
        -- local pos = cc.p(self.m_lb_coins:getPosition())
        -- self.m_sp_zi:setPositionX(pos.x + (size.width * scale) / 2 + 5)
        if isPlayStart then
            self:runCsbAction(
                "show2",
                false,
                function()
                    self:runCsbAction("idle2", true, nil)
                end
            )
        else
            self:runCsbAction("idle2", true, nil)
        end
    end
end

function CardAlbumTitle:closeUI()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    local isCompleted = albumData.current >= albumData.total
    if isCompleted then
        self:runCsbAction("over1")
    else
        self:runCsbAction("over2")
    end
end

-- 点击事件 --
function CardAlbumTitle:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_x" then
        if CardSysRuntimeMgr:isClickOtherInAlbum() then
            return
        end
        CardSysRuntimeMgr:setClickOtherInAlbum(true)

        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeCardAlbumView(
            function()
                CardSysManager:exitCardAlbum()
            end
        )
    end
end

return CardAlbumTitle
