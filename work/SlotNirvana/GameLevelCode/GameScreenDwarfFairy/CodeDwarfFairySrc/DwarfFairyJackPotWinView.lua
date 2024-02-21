---
--island
--2018年4月12日
--JackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local JackPotWinView = class("JackPotWinView", util_require("base.BaseView"))
JackPotWinView.strAnimationName = {"grand", "major", "minor", "mini"}

function JackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "DwarfFairy/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    for i = 1, #self.strAnimationName, 1 do
        local jackpot = self:findChild(self.strAnimationName[i])
        if jackpot ~= nil then
            jackpot:setVisible(false)
        end
    end
end

function JackPotWinView:initViewData(index,coins,mainMachine,callBackFun)
    self.m_index = index
    
    local labCoin = self:findChild("m_lb_coin")

    local jackpot = self:findChild(self.strAnimationName[index])
    if jackpot ~= nil then
        jackpot:setVisible(true)
    end
    
    self:runCsbAction("show", false, function ()
        self:createGrandShare(mainMachine)
        self:jumpCoinsFinish()
        self:runCsbAction("idle", true)
        self.m_click = false
    end)

    self.m_callFun = callBackFun
    labCoin:setString(coins)
    self:updateLabelSize({label=labCoin,sx=0.55,sy=0.55},1110)
end

function JackPotWinView:onEnter()
end

function JackPotWinView:onExit()
    
end

function JackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "btnCollect" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_click.mp3")

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