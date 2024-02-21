---
--xcyy
--2018年5月23日
--LuxuryDiamondScoreDetailView.lua

local LuxuryDiamondScoreDetailView = class("LuxuryDiamondScoreDetailView",util_require("Levels.BaseLevelDialog"))


function LuxuryDiamondScoreDetailView:initUI(machine)
    self.m_machine = machine

    self:createCsbNode("LuxuryDiamond/BillTips.csb")

    self:addClick(self:findChild("zhezhao"))

    self.m_canClick = true

    -- gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_chooseView_start.mp3")


    self.m_scoreNodes = {}
    for i=1,7 do
        local node = self:findChild("Node_" .. i)
        local numView = util_createAnimation("LuxuryDiamond_paytableshu.csb")
        node:addChild(numView)
        table.insert(self.m_scoreNodes, numView)

        -- util_setCascadeOpacityEnabledRescursion(node, true)
    end

    self:findChild("Button"):setTouchEnabled(false)
end

function LuxuryDiamondScoreDetailView:updateScore()
    if self.m_machine.m_signalCredit then
        local betCoin = globalData.slotRunData:getCurTotalBet() or 0
        -- betCoin = betCoin / self.m_machine:getCurBetLevelMulti()

        if self.m_machine.m_iAverageBet then
            betCoin = self.m_machine.m_iAverageBet
        end
        
        for i=1,#self.m_scoreNodes do
            local baseNum = 199
            baseNum = baseNum + i
            -- 7种普通符号的分数，用于右侧显示，该分数*玩家押注/上一条的betMulti
            local score = self.m_machine.m_signalCredit[tostring(baseNum)]
            local labelNum = self.m_scoreNodes[i]:findChild("m_lb_coins")
            
            labelNum:setString(util_formatCoins(score * betCoin, 3))
            self:updateLabelSize({label = labelNum, sx = 0.6, sy = 0.6}, 80)
            
        end

    end
    
end

function LuxuryDiamondScoreDetailView:initColBtn(col)
    for index = 1, 5 do
        self:findChild("tiao_"..index):setVisible(index <= col)
    end
end

function LuxuryDiamondScoreDetailView:initColBtnCoins(coins)
    local strCoins = util_formatCoins(coins,3)
    self:findChild("m_lb_coin"):setString(strCoins)
end


function LuxuryDiamondScoreDetailView:onEnter()
    LuxuryDiamondScoreDetailView.super.onEnter(self)

end

function LuxuryDiamondScoreDetailView:showAdd()
    
end

function LuxuryDiamondScoreDetailView:onExit()
    LuxuryDiamondScoreDetailView.super.onExit(self)
end

--默认按钮监听回调
function LuxuryDiamondScoreDetailView:clickFunc(sender)
    if not self.m_canClick then
        return
    end
    self.m_canClick = false
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "zhezhao" then
        self:hideView()
        gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")

    end
end

function LuxuryDiamondScoreDetailView:hideView(callBack)
    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_scoreDetailView_out.mp3")
    self:runCsbAction("over", false, function()
        if callBack then
            callBack()
        end
        self:setVisible(false)
    end)
end

function LuxuryDiamondScoreDetailView:showView()
    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_scoreDetailView_in.mp3")
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self.m_canClick = true
        self:playIdle()
    end)
end

function LuxuryDiamondScoreDetailView:playIdle()
    self:runCsbAction("idle", true)
end

return LuxuryDiamondScoreDetailView