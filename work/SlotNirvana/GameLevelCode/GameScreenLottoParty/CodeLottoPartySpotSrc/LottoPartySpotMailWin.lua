---
local LottoPartySpotMailWin = class("LottoPartySpotMailWin", util_require("base.BaseView"))

function LottoPartySpotMailWin:initUI(data)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local resourceFilename = "LottoParty/BonusGameOver_Mail.csb"
    self:createCsbNode(resourceFilename, isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil
end
function LottoPartySpotMailWin:setFunc(_func)
    self.m_func = _func
end
function LottoPartySpotMailWin:initViewData(coins)
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_click = false
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
    local node1 = self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label = node1, sx = 0.75, sy = 0.75}, 692)
    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_jump.mp3", true)
end

function LottoPartySpotMailWin:jumpCoins(coins)
    local node = self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum = coins / (5 * 60) -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = 0

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            -- print("++++++++++++  " .. curCoins)

            curCoins = curCoins + coinRiseNum

            if curCoins >= coins then
                curCoins = coins

                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_over.mp3")
                end
            else
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
            end
        end
    )
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_over.mp3")
                end
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
            end
        end,
        5
    )
end

function LottoPartySpotMailWin:onEnter()
end

function LottoPartySpotMailWin:onExit()
    if self.m_JumpOver then
        gLobalSoundManager:stopAudio(self.m_JumpOver)
        self.m_JumpOver = nil
    end

    if self.m_JumpSound then
        gLobalSoundManager:stopAudio(self.m_JumpSound)
        self.m_JumpSound = nil
    end

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function LottoPartySpotMailWin:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        if self.m_click == true then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then
                gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_over.mp3")
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node, sx = 1, sy = 1}, 550)
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle", true, nil, 60)
        else
            self.m_click = true
            self:sendCollectMail()
        end
    end
end

function LottoPartySpotMailWin:closeUI()
    self:runCsbAction(
        "over",
        false,
        function()
            if self.m_func then
                self.m_func()
            end
            self:removeFromParent()
        end,
        60
    )
end


function LottoPartySpotMailWin:sendCollectMail()
    local gameName = "LottoParty"
    gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(
        gameName,
        -1,
        function(data)
            if not tolua.isnull(self) then
                self:changeSuccess()
            end
        end,
        function(errorCode, errorData)
            print("-----LottoParty errorCode -----", errorCode)
            self:changeFailed()
        end
    )
end

function LottoPartySpotMailWin:changeSuccess()
    self:closeUI()
end

function LottoPartySpotMailWin:changeFailed()
end

return LottoPartySpotMailWin
