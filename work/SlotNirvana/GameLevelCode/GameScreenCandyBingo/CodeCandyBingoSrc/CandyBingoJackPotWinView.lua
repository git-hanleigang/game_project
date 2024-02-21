---
--island
--2018年4月12日
--CandyBingo.lua
---- respin 玩法结算时中 mini mijor等提示界面
local CandyBingo = class("CandyBingo", util_require("base.BaseView"))
CandyBingo.m_strNodeName = {"Grand", "Major", "Minor", "Mini","Coins"}

function CandyBingo:initUI(data)
    self.m_click = true

    local resourceFilename = "CandyBingo/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)

end

function CandyBingo:initViewData(index,coins,mainMachine,callBackFun)
    self:createGrandShare(mainMachine)
    self.m_index = index

    self:runCsbAction("start",false,function(  )
        self:jumpCoinsFinish()
        self:runCsbAction("idle",true)
        self.m_click = false
    end)
    self:showJackPotType(index)
    self.m_callFun = callBackFun
    local labCoin = self:findChild("m_lb_coins")
    labCoin:setString(coins)
    
    self:updateLabelSize({label=labCoin,sx=1,sy=1},1616)
end

function CandyBingo:showJackPotType( index )
    for i,v in ipairs(self.m_strNodeName) do
        local node = self:findChild(v)

        if index == i then
            node:setVisible(true)
        else
            node:setVisible(false)
        end
    end
    
end

function CandyBingo:onEnter()
end

function CandyBingo:onExit()
    
end

function CandyBingo:clickFunc(sender)
    local name = sender:getName()
    if name == "backBtn" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_click.mp3")
                self:runCsbAction("over")
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,0.5)
            end)
        end
    end
end

--[[
    自动分享 | 手动分享
]]
function CandyBingo:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function CandyBingo:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_index)
    end
end

function CandyBingo:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function CandyBingo:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return CandyBingo