---
--island
--2018年4月12日
--JackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local JackPotWinView = class("JackPotWinView", util_require("base.BaseView"))
JackPotWinView.strAnimationName = {"grand", "major", "minor", "mini"}

function JackPotWinView:initUI(data)
    self.m_click = false
    self.m_bGrowOver = nil
    local resourceFilename = "GoldenPig/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)
    self.m_labCoin = self:findChild("lab_coin")
    self.m_btnClose = self:findChild("btnClose")
    self.m_btnClose:setVisible(false)
    self:addClick(self:findChild("Panel_1"))
end

function JackPotWinView:initViewData(machine,index,coins,callBackFun)
    self:createGrandShare(machine)
    self.m_jackpotIndex = index

    self.m_index = index

    self.m_coinsNum = coins
    self.m_callFun = callBackFun
    self.m_labCoin:setString(util_formatCoins(coins,30))
    self:updateLabelSize({label=self.m_labCoin, sx = 1.25, sy = 1.25},774)
    self.m_labCoin:setString("")
    local addValue = coins / 240
    
    self:runCsbAction(self.strAnimationName[index].."start", false, function()
        self:runCsbAction(self.strAnimationName[index].."idle", true)
        self.m_bGrowOver = false
        self.m_soundID = gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_jackpot_coin.mp3", true)
        util_jumpNum(self.m_labCoin, 0, coins, addValue, 1 / 60, {30}, nil, nil, function()
            self:growNumOver()
        end)
    end)
end

function JackPotWinView:growNumOver()
    self.m_bGrowOver = true
    gLobalSoundManager:stopAudio(self.m_soundID)
    self.m_soundID = nil
    self.m_btnClose:setVisible(true)
    self.m_labCoin:setString(util_formatCoins(self.m_coinsNum,30))
    self:updateLabelSize({label=self.m_labCoin, sx = 1.25, sy = 1.25},774)
    self:jumpCoinsFinish()
end

function JackPotWinView:onEnter()

end

function JackPotWinView:onExit()
    
end

function JackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "btnClose" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound("GoldenPigSounds/music_GoldenPig_touch_view_btn.mp3")

        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                self:runCsbAction(self.strAnimationName[self.m_index].."over")
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,1)
            end)
        end
    elseif name == "Panel_1" and self.m_bGrowOver == false then
        self.m_labCoin:unscheduleUpdate()
        self:growNumOver()
    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

--[[
    自动分享 | 手动分享
]]
function JackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function JackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function JackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function JackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return JackPotWinView