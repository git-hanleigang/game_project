---
--island
--2018年4月12日
--JackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local JackPotWinView = class("JackPotWinView", util_require("base.BaseView"))
JackPotWinView.m_strNodeName = {"Grand", "Major", "Minor", "Mini"}

function JackPotWinView:ctor()
    JackPotWinView.super.ctor(self)
    self.m_sharePosY = nil
end

function JackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "CrazyBomb/LockSpinJackpot.csb"
    self:createCsbNode(resourceFilename)

    local nodeShare = self:findChild("Node_share")
    if not tolua.isnull(nodeShare) then
        if not self.m_sharePosY then
            self.m_sharePosY = nodeShare:getPositionY()
        end

        nodeShare:setPositionY(self.m_sharePosY + 25)
    end
end

function JackPotWinView:initViewData(index,coins,mainMachine,callBackFun)
    
    self.m_index = index

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        self:createGrandShare(mainMachine)
        self:jumpCoinsFinish()
        self.m_click = false
    end)
    self:showJackPotType(index)
    
    self.m_callFun = callBackFun
    local labCoin = self:findChild("m_lb_coins")
    labCoin:setString(coins)
    
    self:updateLabelSize({label=labCoin,sx=1.0,sy=1.0},677)
    
end

function JackPotWinView:showJackPotType( index )
    for i,v in ipairs(self.m_strNodeName) do
        local node = self:findChild(v)

        if index == i then
            node:setVisible(true)
        else
            node:setVisible(false)
        end
    end
    
end

function JackPotWinView:onEnter()
end

function JackPotWinView:onExit()
    
end

function JackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_touch_view_btn.mp3")

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