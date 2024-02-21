---
--island
--2018年4月12日
--AllStarJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local AllStarJackPotWinView = class("AllStarJackPotWinView", util_require("base.BaseView"))

local VEC_JACKPOT_ID = {4, 3, 2, 1}

function AllStarJackPotWinView:initUI(_machine)

    self:createCsbNode("AllStar/AllStar_jackpotView.csb")
    self.m_isCanTouch = false
    self.m_func = nil
    
    self:findChild("Button_1"):setTouchEnabled(false)

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        performWithDelay(self,function(  )
            self:findChild("Button_1"):setTouchEnabled(true)
            self.m_isCanTouch = true 
        end,0.1)
    end)

    self:createGrandShare(_machine)
end

function AllStarJackPotWinView:updateCoins( coins)
    local lab = self:findChild("m_lb_coins") 
    if lab and coins then
        lab:setString(util_formatCoins(coins,50))

        self:updateLabelSize({label=lab,sx=0.85,sy=0.85},750)

    end
end

function AllStarJackPotWinView:initCallFunc(strCoins, jackPotType,func)
    self.m_func = func
    self.m_jackpotIndex = VEC_JACKPOT_ID[jackPotType]

    self:updateJackPotTitle(jackPotType)
    self:updateJackPotCommon(jackPotType)
    self:updateCoins(strCoins)
    self:jumpCoinsFinish()
    globalData.jackpotRunData:notifySelfJackpot(strCoins, self.m_jackpotIndex)
end

--默认按钮监听回调
function AllStarJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    
    if self.m_isCanTouch then
        self.m_isCanTouch = false
        if name == "Button_1" then
            gLobalSoundManager:playSound("AllStarSounds/music_AllStar_btn_click.mp3")
            self:jackpotViewOver(function()
                performWithDelay(self,function(  )
                    if self.m_func then
                        self.m_func()
                    end
                end,0.2)
                self:runCsbAction("over",false,function(  )
                    if self then
                        self:removeFromParent()
                    end
                end)
            end)
        end
    end
    
end

function AllStarJackPotWinView:updateJackPotTitle(jackType)
    local nameList = {
        "ClassicCash_mini1_3", 
        "ClassicCash_minor1_4",
        "ClassicCash_major1_2", 
        "ClassicCash_grand1_1", 
    }
    for i,v in ipairs(nameList) do
        local node = self:findChild(v)      
        if(node)then
            node:setVisible(i==jackType)
        end
    end

end

function AllStarJackPotWinView:updateJackPotCommon(jackType)
    local nameList = {
        "AllStar_minibaoxiang_5", 
        "AllStar_minorbaoxiang_4",
        "AllStar_majorbaoxiang_3", 
        "AllStar_grandbaoxiang_2", 
    }
    for i,v in ipairs(nameList) do
        local node = self:findChild(v)      
        if(node)then
            node:setVisible(i==jackType)
        end
    end

end

--[[
    自动分享 | 手动分享
]]
function AllStarJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function AllStarJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function AllStarJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function AllStarJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return AllStarJackPotWinView