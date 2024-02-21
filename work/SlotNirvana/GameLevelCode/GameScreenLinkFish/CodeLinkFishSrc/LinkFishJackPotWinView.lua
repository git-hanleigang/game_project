---
--island
--2018年4月12日
--JackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local JackPotWinView = class("JackPotWinView", util_require("base.BaseView"))

function JackPotWinView:initUI(data)
    self.m_click = true
    self.m_machine = data.machine
    local resourceFilename = "LinkFish/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)
end

function JackPotWinView:initViewData(index, coins, mainMachine, callBackFun)
    self.m_index = index
    self:findChild("ChineseStyle_font_Grand"):setVisible(false)
    self:findChild("ChineseStyle_font_major"):setVisible(false)
    self:findChild("ChineseStyle_font_minor"):setVisible(false)
    self:findChild("ChineseStyle_font_mini"):setVisible(false)
    self:findChild("ChineseStyle_font_Super"):setVisible(false)
    self:findChild("ChineseStyle_font_Mega"):setVisible(false)

    if index == 1 then
        self:findChild("ChineseStyle_font_mini"):setVisible(true)
        self.m_index = 4
    elseif index == 2 then
        self:findChild("ChineseStyle_font_minor"):setVisible(true)
        self.m_index = 3
    elseif index == 3 then
        self:findChild("ChineseStyle_font_major"):setVisible(true)
        self.m_index = 2
    elseif index == 4 then
        local status = self.m_machine.m_jackpot_status
        if status ~= "Normal" then
            self:findChild("ChineseStyle_font_Super"):setVisible(status == "Super")
            self:findChild("ChineseStyle_font_Mega"):setVisible(status == "Mega")
        else
            self:findChild("ChineseStyle_font_Grand"):setVisible(true)
        end
        
        self.m_index = 1
    end
    local node1 = self:findChild("m_lb_coins4")
    node1:setString(coins)
    self:updateLabelSize({label=node1,sx=0.8,sy=0.8},632)
    
    self:runCsbAction("show_0", false, function()
        self:createGrandShare(mainMachine)
        self.m_click = false
        self:jumpCoinsFinish()

        self.m_callFun = callBackFun
        
        --通知jackpot
        globalData.jackpotRunData:notifySelfJackpot(coins, self.m_index)
    end)
end

function JackPotWinView:onEnter()
end

function JackPotWinView:onExit()
end

function JackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "backBtn" then
        if self.m_click == true then
            return
        end
        self.m_click = true
        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_touch_view_btn.mp3")

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

--[[
    自动分享 | 手动分享
]]
function JackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function JackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_index)
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

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return JackPotWinView
