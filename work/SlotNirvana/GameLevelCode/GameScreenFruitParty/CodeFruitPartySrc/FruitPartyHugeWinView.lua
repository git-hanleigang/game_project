---
--island
--2018年4月12日
--FruitPartyHugeWinView.lua
local FruitPartyHugeWinView = class("FruitPartyHugeWinView", util_require("base.BaseView"))


FruitPartyHugeWinView.m_isOverAct = false
FruitPartyHugeWinView.m_isJumpOver = false

function FruitPartyHugeWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "FruitParty/PlayerWin.csb"
    self:createCsbNode(resourceFilename)
end



function FruitPartyHugeWinView:onEnter()
end

function FruitPartyHugeWinView:onExit()
    
end

function FruitPartyHugeWinView:showView(data,endFunc,frameFunc)

    local coins = data.coins
    if data.udid == globalData.userRunData.userUdid then
        self:jumpCoins(coins)
    else
        self:findChild("m_lb_coins"):setString(util_formatCoins(coins,50))
        local info={label = self:findChild("m_lb_coins"),sx = 1,sy = 1}
        self:updateLabelSize(info,573)
    end
    
    self:findChild("sp_head"):removeAllChildren(true)
    util_setHead(self:findChild("sp_head"), data.facebookId, data.head, nil, true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("sp_head"), true)
    

    local isMe = (globalData.userRunData.userUdid == data.udid)

    self:findChild("sp_headFrame_me"):setVisible(isMe)
    self:findChild("sp_headFrame"):setVisible(not isMe)

    local txt_name = self:findChild("Text_1")
    txt_name:setString(data.nickName or "")
    txt_name:stopAllActions()
    local clipNode = txt_name:getParent()
    local clipSize = clipNode:getContentSize()
    txt_name:setAnchorPoint(cc.p(0.5,0.5))
    txt_name:setPosition(cc.p(clipSize.width / 2,clipSize.height / 2))

    util_wordSwing(txt_name, 1, clipNode, 2, 30, 2)

    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_player_win.mp3")
    self:runCsbAction("auto",false,function(  )
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        waitNode:removeFromParent()
        if type(frameFunc) == "function" then
            frameFunc()
        end
    end,210 / 60)
end


function FruitPartyHugeWinView:jumpCoins(coins)

    local node=self:findChild("m_lb_coins")
    node:setString("")

    -- self.m_soundId = gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_jackpot_collect_coins.mp3",true)

    local coinRiseNum =  coins / 60  

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0
    self:stopAllActions()


    
    util_schedule(self,function()

        print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            local info={label = self:findChild("m_lb_coins"),sx = 1,sy = 1}
            self:updateLabelSize(info,573)

            self.m_isJumpOver = true

            if self.m_soundId then

                -- gLobalSoundManager:playSound("sound_FruitPartySounds/sound_FruitParty_jackpot_jump_over.mp3")

                

                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            self:stopAllActions()

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))

            local info={label = self:findChild("m_lb_coins"),sx = 1,sy = 1}
            self:updateLabelSize(info,573)
        end
        

    end,2 / 60)

end


return FruitPartyHugeWinView

