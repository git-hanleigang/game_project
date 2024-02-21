---
--island
--2018年4月12日
--JackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local JackPotWinView = class("JackPotWinView", util_require("base.BaseView"))

function JackPotWinView:initUI(data)
    self.m_click = false
    self.m_machine = data

    local resourceFilename = "ChineseStyle/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)

end

function JackPotWinView:initViewData(index,coins,callBackFun)

    self.m_index = index
    self.m_jackpotIndex = 4 - index + 1
    self:createGrandShare(self.m_machine)

    local node1=self:findChild("m_lb_coins1")
    local node2=self:findChild("m_lb_coins2")
    local node3=self:findChild("m_lb_coins3")
    local node4=self:findChild("m_lb_coins4")
    self:runCsbAction("show_"..(index-1), false, function()
        self:jumpCoinsFinish()
    end)

    self.m_callFun = callBackFun
    node1:setString(coins)
    node2:setString(coins)
    node3:setString(coins)
    node4:setString(coins)
    self:updateLabelSize({label=node1},807)
    self:updateLabelSize({label=node2},807)
    self:updateLabelSize({label=node3},807)
    self:updateLabelSize({label=node4},807)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function JackPotWinView:onEnter()
end

function JackPotWinView:onExit()
    
end

function JackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "backBtn" then
        if self:checkShareState() then
            return
        end
        if self.m_click == true then
            return 
        end
        self:jackpotViewOver(function()
            
            self.m_click = true
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:runCsbAction("over_"..(self.m_index - 1))
            performWithDelay(self,function()
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end,1)
        end)

        

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

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return JackPotWinView