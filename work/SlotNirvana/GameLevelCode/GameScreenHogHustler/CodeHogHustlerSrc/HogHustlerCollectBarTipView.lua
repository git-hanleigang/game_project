---
--xcyy
--2018年5月23日
--HogHustlerCollectBarTipView.lua

local HogHustlerCollectBarTipView = class("HogHustlerCollectBarTipView",util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")


function HogHustlerCollectBarTipView:initUI()
    self:createCsbNode("HogHustler_shoujitiao_tip.csb")
    self:addClick(self:findChild("Panel_2"))
    self.m_dice_Label = self:findChild("m_lb_num")
    self.m_canClick = false
    
    self.m_roleNode = util_spineCreate("Socre_HogHustler_juese", true, true)
    self:findChild("juese"):addChild( self.m_roleNode)
    self:findChild("juese"):setScaleX(-1.45)
    self:findChild("juese"):setScaleY(1.45)
    util_spinePlay(self.m_roleNode, "D_startidle", true)
end


function HogHustlerCollectBarTipView:onEnter()
    HogHustlerCollectBarTipView.super.onEnter(self)
end

function HogHustlerCollectBarTipView:onExit()
    HogHustlerCollectBarTipView.super.onExit(self)
end

function HogHustlerCollectBarTipView:setDiceNum(num)
    self.m_diceNum = num
    self.m_dice_Label:setString(self.m_diceNum)

    self:updateLabelSize({label=self.m_dice_Label,sx=0.45,sy=0.45},79)
end

--默认按钮监听回调
function HogHustlerCollectBarTipView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_canClick then
        self.m_canClick = false
        -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_levelPrize_levelNum_up.mp3")
        self:runCsbAction("over", false, function()
            gLobalNoticManager:postNotification("MAP_SHOWFIRST_CLICK_SMELLYRICH")
        end, 60)
    end
end

function HogHustlerCollectBarTipView:playIdle()
    self:runCsbAction("idle", true) -- 播放时间线
end

function HogHustlerCollectBarTipView:resetClick()
    self.m_canClick = true
end

function HogHustlerCollectBarTipView:showTip()
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_guide_clickhere)

        self:resetClick()
        self:playIdle()
        --gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_clickOnit.mp3")
    end)
end

return HogHustlerCollectBarTipView