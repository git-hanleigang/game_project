---
--xcyy
--2018年5月23日
--BeerGirlFastWinView.lua

local BeerGirlFastWinView = class("BeerGirlFastWinView",util_require("base.BaseView"))

BeerGirlFastWinView.SYMBOL_Blank = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7  -- 100 
BeerGirlFastWinView.SYMBOL_JackPot_Grand = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8  -- 101 
BeerGirlFastWinView.SYMBOL_JackPot_Major = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9  -- 102 
BeerGirlFastWinView.SYMBOL_JackPot_Minor = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10  -- 103 
BeerGirlFastWinView.SYMBOL_JackPot_Mini = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11  -- 104 

local grandName = "grand"
local majorName = "major"
local minorName = "minor"
local miniName = "mini"

BeerGirlFastWinView.m_isOverAct = false
BeerGirlFastWinView.m_isJumpOver = false

function BeerGirlFastWinView:initUI(data)

    self:createCsbNode("BeerGirl/Jackpotover.csb")

    self.m_soundId =  gLobalSoundManager:playSound("BeerGirlSounds/BeerGirl_JackPotWinShow.mp3",true)

    self.m_endCoins = data.coins
    self.m_func = data.func

    self:jumpCoins(data.coins )

    performWithDelay(self,function(  )
        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)

    self:updateImg( data)

    self:findChild("BeerGirl_fs_7_5"):setVisible(false)
    
    self.m_jp_girl = util_spineCreate("Socre_BeerGirl_Jackpot", true, true)
    self:findChild("spinNode"):addChild(self.m_jp_girl)
    util_spinePlay(self.m_jp_girl,"show")

    self.m_isOverAct = true
    self.m_isJumpOver = false
    self.m_isEndOverAct = false

    self:addClick(self:findChild("click"))

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)
    
    self:runCsbAction("start",false,function(  )
        self.m_isOverAct = false
        util_spinePlay(self.m_jp_girl,"idleframe",true)

        self:runCsbAction("idle",false,function(  )
            -- util_spinePlay(self.m_jp_girl,"over")

            self.m_isEndOverAct = true

            performWithDelay(self.m_actNode,function(  )
                self:runCsbAction("over",false,function(  )
                    if data.func then
                         data.func()
                    end 

                    self:removeFromParent()
                 end)
            end,2)

            
        end)
    end)

    

end

--默认按钮监听回调
function BeerGirlFastWinView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_isOverAct then

        return 
        
    end


    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
        gLobalSoundManager:playSound("BeerGirlSounds/BeerGirl_JackPotWinEnd.mp3")
    end
    

    if name == "click" then
        self.m_isOverAct = true

       
        if self.m_isJumpOver or self.m_isEndOverAct then


            self.m_actNode:stopAllActions()

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

            local node=self:findChild("BitmapFontLabel_1")
            node:setString(util_formatCoins(self.m_endCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},737)

            self:runCsbAction("over",false,function(  )
                if self.m_func then
                    self.m_func()
                end 
                self:removeFromParent()
             end)
        else
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            
            local node=self:findChild("BitmapFontLabel_1")
            node:setString(util_formatCoins(self.m_endCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},737)

            self:runCsbAction("idle",true)

            performWithDelay(self.m_actNode,function(  )
                self:runCsbAction("over",false,function(  )
                    if self.m_func then
                        self.m_func()
                    end 
     
                    self:removeFromParent()
                 end)
            end,2)
        end

        

        
    end

end

function BeerGirlFastWinView:jumpCoins(coins )

    local node=self:findChild("BitmapFontLabel_1")
    node:setString("")

    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("BitmapFontLabel_1")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},737)

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
                gLobalSoundManager:playSound("BeerGirlSounds/BeerGirl_JackPotWinEnd.mp3")
            end


            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("BitmapFontLabel_1")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},737)
        end
        

    end)



end

function BeerGirlFastWinView:updateImg( data)

    self:findChild(grandName):setVisible(false)
    self:findChild(majorName):setVisible(false)
    self:findChild(minorName):setVisible(false)
    self:findChild(miniName):setVisible(false)

    if data.symbolType == self.SYMBOL_JackPot_Grand then

        self:findChild(grandName):setVisible(true)
        
    elseif data.symbolType == self.SYMBOL_JackPot_Major then
        self:findChild(majorName):setVisible(true)
        
    elseif data.symbolType == self.SYMBOL_JackPot_Minor then

        self:findChild(minorName):setVisible(true)
        
    elseif data.symbolType == self.SYMBOL_JackPot_Mini then

        self:findChild(miniName):setVisible(true)
        
    end
end


function BeerGirlFastWinView:onEnter()
 
    
end


function BeerGirlFastWinView:onExit()

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

return BeerGirlFastWinView