---
--island
--2018年4月12日
--CharmsJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local CharmsJackPotWinView = class("CharmsJackPotWinView", util_require("base.BaseView"))

CharmsJackPotWinView.AnimationName = {3,2,1,0}

CharmsJackPotWinView.jpTipIndex = {4,3,2,1}

function CharmsJackPotWinView:initUI(_machine)
    self.m_click = false

    local resourceFilename = "Charms/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)

    self:createGrandShare(_machine)
end

function CharmsJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_jackpotIndex = self.jpTipIndex[index]

    local node1=self:findChild("m_lb_coins")
    
    self.m_click = true
    self:runCsbAction("show_0",false,function(  )
        self.m_click = false
        self:runCsbAction("normal_0",true)
        self:jumpCoinsFinish()
    end)

    local nameList = {"mini","minor","major","grand"}
    for i=1,#nameList do
        if i == index then
            local node = self:findChild(nameList[i])
            if node then
                node:setVisible(true)
            end
        else
            local node = self:findChild(nameList[i])
            if node then
                node:setVisible(false)
            end
        end

    end

    self.m_callFun = callBackFun
    node1:setString(coins)
    self:updateLabelSize({label=node1,sx = 1,sy = 1},298)
    

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_jackpotIndex)
end

function CharmsJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    local name = sender:getName()
    if name == "backBtn" then
        if self.m_click == true then
            return 
        end
        self:jackpotViewOver(function()
            self.m_click = true
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            util_playFadeOutAction(self,0.2,function(  )
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end)
        end)
    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

--[[
    自动分享 | 手动分享
]]
function CharmsJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function CharmsJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function CharmsJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function CharmsJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return CharmsJackPotWinView