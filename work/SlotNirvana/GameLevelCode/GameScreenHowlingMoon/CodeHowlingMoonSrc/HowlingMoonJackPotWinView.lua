---
--island
--2018年4月12日
--HowlingMoonJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local HowlingMoonJackPotWinView = class("HowlingMoonJackPotWinView", util_require("base.BaseView"))

function HowlingMoonJackPotWinView:initUI(data)
    self.m_machine = data.machine
    self.m_click = false

    local resourceFilename = "HowlingMoon/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)
    self:findChild("jackpot_1"):setVisible(false)
    self:findChild("jackpot_2"):setVisible(false)
    self:findChild("jackpot_3"):setVisible(false)
    self:findChild("jackpot_4"):setVisible(false)
    self:findChild("jackpot_super"):setVisible(false)
    self:findChild("jackpot_mega"):setVisible(false)
end

function HowlingMoonJackPotWinView:initViewData(index,coins,callBackFun)
    self:createGrandShare(self.m_machine)
    self.m_jackpotIndex = 4 - index + 1

    self.m_index = index

    local status = self.m_machine.m_jackpot_status
    if index == 4 and status ~= "Normal" then
        self:findChild("jackpot_super"):setVisible(status == "Super")
        self:findChild("jackpot_mega"):setVisible(status == "Mega")
    else
        self:findChild("jackpot_"..index):setVisible(true)
    end
    
    local node = self:findChild("m_lb_coins")
    self.m_click = true
    self:runCsbAction("show_0", false, function()
        self.m_click = false
        self:jumpCoinsFinish()
    end)

    self.m_callFun = callBackFun
    node:setString(coins)
    self:updateLabelSize({label = node},630)
    

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function HowlingMoonJackPotWinView:onEnter()
end

function HowlingMoonJackPotWinView:onExit()

end

function HowlingMoonJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "backBtn" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_touch_view_btn.mp3")

        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                self:runCsbAction("over_0")
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
function HowlingMoonJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function HowlingMoonJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function HowlingMoonJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function HowlingMoonJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return HowlingMoonJackPotWinView