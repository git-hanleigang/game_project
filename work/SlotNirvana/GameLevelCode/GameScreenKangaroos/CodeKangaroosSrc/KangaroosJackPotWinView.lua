---
--island
--2018年4月12日
--JackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local JackPotWinView = class("JackPotWinView", util_require("base.BaseView"))

function JackPotWinView:initUI(data)
    local resourceFilename = "Kangaroos/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)
end

function JackPotWinView:initViewData(machine,jackPot,coins,callBackFun)
    self:createGrandShare(machine)
    if jackPot == "Grand" then
        self.m_jackpotIndex = 1
    elseif jackPot == "Major" then
        self.m_jackpotIndex = 2
    elseif jackPot == "Minor" then
        self.m_jackpotIndex = 3
    end

    -- local node1=self:findChild("m_lb_coins1")
    -- local node2=self:findChild("m_lb_coins2")
    local node3=self:findChild("m_lb_coins3")

    self.m_click = true
    self:runCsbAction("show", false, function()
        self.m_click = false
        self:jumpCoinsFinish()
        self:runCsbAction("idle", true)
    end)

    self.m_callFun = callBackFun
    -- node1:setString(util_formatCoins(coins, 30))
    -- node2:setString(util_formatCoins(coins, 30))
    node3:setString(util_formatCoins(coins, 30))

    -- self:updateLabelSize({label=node1,sx=1.4,sy=1.4},390)
    -- self:updateLabelSize({label=node2,sx=1.4,sy=1.4},390)
    self:updateLabelSize({label=node3,sx=1.4,sy=1.4},390)

    self:findChild("Grand"):setVisible(false)
    self:findChild("Major"):setVisible(false)
    self:findChild("Minor"):setVisible(false)

    self:findChild(jackPot):setVisible(true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_jackpotIndex)
end

function JackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "backBtn" then
        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_click_btn.mp3")

        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                self:runCsbAction("over")
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,1)
            end)
        end
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