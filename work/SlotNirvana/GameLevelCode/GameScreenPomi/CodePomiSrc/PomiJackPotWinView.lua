---
--island
--2018年4月12日
--PomiJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PomiJackPotWinView = class("PomiJackPotWinView", util_require("base.BaseView"))

function PomiJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "Pomi/JackpotWin.csb"
    self:createCsbNode(resourceFilename)

end

function PomiJackPotWinView:initViewData(machine,index,coins,callBackFun)
    self:createGrandShare(machine)
    self.m_jackpotIndex = index
    self.m_index = index

    local node1=self:findChild("m_lb_coins")

    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
        self:jumpCoinsFinish()
    end)

    local imgName = {"Pomi_Grand","Pomi_Major","Pomi_Minor","Pomi_Mini"}
    for k,v in pairs(imgName) do
        local img =  self:findChild(v)
        if img then
            if k == index then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end
    
    
    

    self.m_callFun = callBackFun
    node1:setString(coins)

    self:updateLabelSize({label=node1},518)


    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function PomiJackPotWinView:onEnter()
end

function PomiJackPotWinView:onExit()
    
end

function PomiJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound("PomiSounds/music_Pomi_common_Click.mp3")
        

        self.m_click = true

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

--[[
    自动分享 | 手动分享
]]
function PomiJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function PomiJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function PomiJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function PomiJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return PomiJackPotWinView