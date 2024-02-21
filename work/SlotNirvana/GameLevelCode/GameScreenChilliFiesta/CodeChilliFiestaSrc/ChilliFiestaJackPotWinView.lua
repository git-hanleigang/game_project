---
--island
--2018年4月12日
--ChilliFiestaJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local ChilliFiestaJackPotWinView = class("ChilliFiestaJackPotWinView", util_require("base.BaseView"))
ChilliFiestaJackPotWinView.titleName = {"ChiliFiesta_grand","ChiliFiesta_major","ChiliFiesta_minor","ChiliFiesta_mini"}
function ChilliFiestaJackPotWinView:initUI(data)--ChiliFiesta_grand
    self.m_click = false
    self.m_machine = data.machine

    local resourceFilename = "ChilliFiesta/Jackpotover.csb"
    self:createCsbNode(resourceFilename)

    self.m_callFun = data.callback
    -- gLobalSoundManager:setBackgroundMusicVolume(0.4)
    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_jackSound.mp3",false)
    self:findChild("m_lb_coins"):setString(data.coins)
    self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=0.75,sy=0.75},469)
    self:findChild("ChiliFiesta_mega"):setVisible(false)
    self:findChild("ChiliFiesta_super"):setVisible(false)

    self:createGrandShare(self.m_machine)
    self.m_jackpotIndex = data.index

    for i=1,#self.titleName do
        if i == data.index then
            if data.index == 1 then
                local status = self.m_machine.m_jackpot_status
                if status == "Normal" then
                    self:findChild(self.titleName[i]):setVisible(true)
                else
                    self:findChild(self.titleName[i]):setVisible(false)
                    self:findChild("ChiliFiesta_mega"):setVisible(status == "Mega")
                    self:findChild("ChiliFiesta_super"):setVisible(status == "Super")
                end
            else
                self:findChild(self.titleName[i]):setVisible(true)
            end
            
        else
            self:findChild(self.titleName[i]):setVisible(false)
        end
    end

    self:runCsbAction("start",false,function()
        if self.m_click == false then
            self:runCsbAction("idle",true)
        end
        self:jumpCoinsFinish()
    end)
end

function ChilliFiestaJackPotWinView:onEnter()
    gLobalSoundManager:setBackgroundMusicVolume(0)
end

function ChilliFiestaJackPotWinView:onExit()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    if self.m_callFun then
        self.m_callFun()
    end
end

function ChilliFiestaJackPotWinView:clickFunc(sender)
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
                self:runCsbAction("over",false,function()
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
function ChilliFiestaJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function ChilliFiestaJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function ChilliFiestaJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function ChilliFiestaJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return ChilliFiestaJackPotWinView