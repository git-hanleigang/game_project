---
--island
--2018年4月12日
--FarmJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local FarmJackPotWinView = class("FarmJackPotWinView", util_require("base.BaseView"))

local GrandId = 1
local MajorId = 2
function FarmJackPotWinView:initUI(data)
    self.m_click = false

    local resourceFilename = "Farm/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)

end

function FarmJackPotWinView:initViewData(machine,index,coins,callBackFun)
    self:createGrandShare(machine)
    self.m_jackpotIndex = index

    self.m_index = index

    local node1=self:findChild("m_lb_coins")
    self.m_click = true
    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
        self:jumpCoinsFinish()
    end)
    self:findChild("farm_grand"):setVisible(false)
    self:findChild("farm_major"):setVisible(false)

    if index == GrandId then
        self:findChild("farm_grand"):setVisible(true)

    else
        self:findChild("farm_major"):setVisible(true)
    end

    self.m_callFun = callBackFun
    node1:setString(coins)

    self:updateLabelSize({label=node1},724)
    

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function FarmJackPotWinView:onEnter()
end

function FarmJackPotWinView:onExit()
    
end

function FarmJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                self:runCsbAction("over",false,function(  )
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end)
            end)
        end
    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

--[[
    自动分享 | 手动分享
]]
function FarmJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function FarmJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function FarmJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function FarmJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return FarmJackPotWinView