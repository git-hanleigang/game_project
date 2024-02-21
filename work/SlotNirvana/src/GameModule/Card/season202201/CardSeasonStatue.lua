--[[--
    小游戏入口
]]
local STATUE_STATE = {
    ready = 1,
    countDown = 2
}
local spgData = require("GameModule.CardMiniGames.Statue.StatuePick.data.StatuePickGameData")
local StatuePickGameData = nil
if spgData then
    StatuePickGameData = spgData:getInstance()
end
local CardSeasonStatue = class("CardSeasonStatue", BaseView)

function CardSeasonStatue:getComingBubbleLua()
    return "GameModule.Card.season202201.CardSeasonStatueComing"
end

function CardSeasonStatue:getCountdownBubbleLua()
    return "GameModule.Card.season202201.CardSeasonStatueBubble"
end

function CardSeasonStatue:getRedPointLua()
    return "GameModule.Card.season202201.CardRedPoint"
end

function CardSeasonStatue:initUI()
    CardSeasonStatue.super.initUI(self)

    self:initData()
    self:updateUI()
end

function CardSeasonStatue:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonStatueRes, "season202201")
end

function CardSeasonStatue:initCsbNodes()
    self.m_numLB = self:findChild("BitmapFontLabel_1") -- 倒计时数字
    self.m_touch = self:findChild("Panel_wheel")
    self.m_nodeRedPoind = self:findChild("Node_redPoint")
    self.m_nodeComing = self:findChild("suoding")
    self:addClick(self.m_touch)
end

function CardSeasonStatue:initData()
    self.m_statue = STATUE_STATE.ready
    if self:getStatuePickGameStatus() == "FINISH" then
        self.m_statue = STATUE_STATE.countDown
    end
end

function CardSeasonStatue:getStatuePickGameCooldown()
    return StatuePickGameData:getCooldownTime()
    -- self.m_t = self.m_t or 10
    -- self.m_t = self.m_t - 1
    -- if self.m_t < 0 then
    --     self.m_t = 0
    -- end
    -- return self.m_t
end

function CardSeasonStatue:getStatuePickGameStatus()
    return StatuePickGameData:getGameStatus()
end

function CardSeasonStatue:updateUI()
    if self:isComingsoon() then
        self:runCsbAction("comingsoon", true, nil, 60)
    else
        local curTime = self:getStatuePickGameCooldown()
        if curTime == 0 then
            self:runCsbAction("idle", true, nil, 60)
            self:updateRedPoint(1)
        else
            if self.m_statue == STATUE_STATE.ready then
                self:runCsbAction("idle", true, nil, 60)
                self:updateRedPoint(1)
            elseif self.m_statue == STATUE_STATE.countDown then
                self:runCsbAction("idle1", true, nil, 60)
                self:updateCountdown()
                self:updateRedPoint(0)
            end
        end
    end
end

function CardSeasonStatue:updateRedPoint(showNum)
    if showNum > 0 then
        if not self.m_redPoint then
            self.m_redPoint = util_createView(self:getRedPointLua())
            self.m_nodeRedPoind:addChild(self.m_redPoint)
        end
        showNum = math.min(999, showNum)
        self.m_redPoint:updateNum(showNum)
    else
        if self.m_redPoint ~= nil then
            self.m_redPoint:removeFromParent()
            self.m_redPoint = nil
        end
    end
end

function CardSeasonStatue:updateCountdown()
    local curTime = self:getStatuePickGameCooldown()
    self.m_numLB:setString(util_count_down_str(curTime))
end

function CardSeasonStatue:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_wheel" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        if self:isComingsoon() then
            self:showComingsoonBubble()
        else
            -- elseif self.m_statue == STATUE_STATE.countDown then
            --     -- 弹出气泡
            -- end
            -- if self.m_statue == STATUE_STATE.ready then
            if self.m_clickStatue then
                return
            end
            self.m_clickStatue = true
            performWithDelay(
                self,
                function()
                    self.m_clickStatue = false
                end,
                1
            )
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_STATUE_OPEN)
        end
    end
end

function CardSeasonStatue:onEnter()
    CardSeasonStatue.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initData()
            self:updateUI()
        end,
        CardSysConfigs.ViewEventType.CARD_STATUE_UPDATE_TIME
    )
end

function CardSeasonStatue:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function CardSeasonStatue:isComingsoon()
    if not CardSysManager:isUnlockStatue() then
        return true
    end
    return false
end

function CardSeasonStatue:showComingsoonBubble()
    if self.m_comingsoonBubbleUI ~= nil then
        return
    end
    local suoding = self:findChild("suoding")
    self.m_comingsoonBubbleUI = util_createView(self:getComingBubbleLua())
    self.m_comingsoonBubbleUI:setOverFunc(
        function()
            self.m_comingsoonBubbleUI = nil
        end
    )
    self.m_comingsoonBubbleUI:setPosition(cc.p(0, 74))
    suoding:addChild(self.m_comingsoonBubbleUI)
end

-- function CardSeasonStatue:showCooldownBubble()
--     if self.m_countdownUI ~= nil then
--         return
--     end
--     local spMachine = self:findChild("sp_machine")
--     local machineSize = spMachine:getContentSize()
--     self.m_countdownUI = util_createView(self:getCountdownBubbleLua())
--     self.m_countdownUI:setOverFunc(function()
--         self.m_countdownUI = nil
--     end)
--     self.m_countdownUI:setPosition(cc.p(machineSize.width*0.5, machineSize.height))
--     spMachine:addChild(self.m_countdownUI)

--     local finalTime = self:getWheelCountDown()
--     local curTime = os.time()
--     if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
--         curTime = globalData.userRunData.p_serverTime / 1000
--     end
--     local remainTime = finalTime - curTime
--     self.m_countdownUI:updateTime(remainTime)
-- end

return CardSeasonStatue
