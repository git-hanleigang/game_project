

local TrainYourDragonDragonGrowWinCoinView = class("TrainYourDragonDragonGrowWinCoinView", util_require("base.BaseView"))

function TrainYourDragonDragonGrowWinCoinView:initUI()
    local resourceFilename = "TrainYourDragon/JindutiaoZhongjiang_js.csb"
    self:createCsbNode(resourceFilename)
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_DragonGrowWinCoin.mp3")
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
    end)
end
function TrainYourDragonDragonGrowWinCoinView:initViewData(winCoinNum,showType)
    self.m_winCoins = winCoinNum
    self.m_showType = showType
    if self.m_showType == 1 then
        self:findChild("dalong"):setVisible(false)
    else
        self:findChild("xiaolong"):setVisible(false)
    end
    self:jumpCoins(winCoinNum)
    self.m_JumpSound = gLobalSoundManager:playSound("TrainYourDragonSounds/sound_TrainYourDragon_jackpot_jump.mp3",true)
end
function TrainYourDragonDragonGrowWinCoinView:jumpCoins(coins)
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
            curCoins = curCoins + coinRiseNum

            if curCoins >= coins then
                curCoins = coins

                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node,sx = 1,sy = 1},625)

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("TrainYourDragonSounds/sound_TrainYourDragon_jackpot_over.mp3")
                end
            else
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node,sx = 1,sy = 1},625)
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
                    gLobalSoundManager:playSound("TrainYourDragonSounds/sound_TrainYourDragon_jackpot_over.mp3")
                end
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node,sx = 1,sy = 1},625)
            end
        end,
        5
    )
end



function TrainYourDragonDragonGrowWinCoinView:onEnter()
end

function TrainYourDragonDragonGrowWinCoinView:onExit()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function TrainYourDragonDragonGrowWinCoinView:clickFunc(sender)
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
                self.m_JumpOver = gLobalSoundManager:playSound("TrainYourDragonSounds/sound_TrainYourDragon_jackpot_over.mp3")
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node,sx = 1,sy = 1},625)
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
        else
            self.m_click = true
            self:runCsbAction("over")
            performWithDelay(self,function()
                if self.m_showType == 1 then
                    gLobalNoticManager:postNotification("CodeGameScreenTrainYourDragonMachine_dragonGrowXiaoLongEnd")
                else
                    gLobalNoticManager:postNotification("CodeGameScreenTrainYourDragonMachine_bonusGameOver")
                end
                self:removeFromParent()
            end,1)
            gLobalNoticManager:postNotification("TrainYourDragonDragonGrowView_colseSelfView")
            gLobalNoticManager:postNotification("TrainYourDragonChooseGameView_colseSelfView")
            if self.m_showViewId then
                gLobalSoundManager:stopAudio(self.m_showViewId)
                self.m_showViewId = nil
            end
        end
    end
end
return TrainYourDragonDragonGrowWinCoinView