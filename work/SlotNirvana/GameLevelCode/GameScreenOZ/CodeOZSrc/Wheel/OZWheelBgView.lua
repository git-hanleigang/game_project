---
--xcyy
--2018年5月23日
--OZWheelBgView.lua

local OZWheelBgView = class("OZWheelBgView",util_require("base.BaseView"))

OZWheelBgView.m_overCallFunc = nil

function OZWheelBgView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("OZ/GameScreenOZ_wheel.csb")

    self.m_wheelGuoChangView = util_spineCreate("GameScreenOZ_wheel",true,true)
    self:findChild("bgActNode"):addChild(self.m_wheelGuoChangView)
    self.m_wheelGuoChangView:setVisible(true)
    util_spinePlay(self.m_wheelGuoChangView,"idleframe2")
    

    self.m_WheelJPView = util_createView("CodeOZSrc.JackpotGame.OZJPtMainView")
    self:findChild("OZ_rl_lvdiban"):addChild(self.m_WheelJPView)
    self.m_WheelJPView:setVisible(false)

    self:createWheelNode( false )

    self:initJackpotData( )

end

function OZWheelBgView:bgWheelAct( )
    
    self.m_WheelView:setVisible(true)
    self.m_WheelView:runCsbAction("open",false,function(  )

        self.m_WheelView:runCsbAction("idle",true)

        self.m_WheelView:findChild("click"):setVisible(true) 
    end)
    self.m_WheelView:showLittleIdle()

    self.m_WheelJPView:setVisible(true)
    self.m_WheelJPView:runCsbAction("open",false,function(  )
        self.m_WheelJPView:runCsbAction("idle2",true)
    end)
end

function OZWheelBgView:initJackpotData( )
    
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local collectBetCoins = selfdata.collectBetCoins or {Mini = 0,Major = 0,Minor = 0}
    local jackpotCounts = selfdata.jackpotCounts or { Mini = 0,Major = 0,Minor = 0}

    for k,v in pairs(collectBetCoins) do
        local coins = v
        local labname = k .. "_coins" 
        local lab =  self.m_WheelJPView:findChild(labname)
        if lab then
            lab:setString(util_formatCoins(coins,50) )
            self.m_WheelJPView:updateLabelSize({label=lab,sx=1,sy=1},208)
        end
    end

    for k,v in pairs(jackpotCounts) do
        local num = v
        for i=1,3 do

            local nodename = k .. "_node_" .. i .. "_Diamond" 
            local diamond =  self.m_WheelJPView[nodename]
            if diamond then
                diamond:setVisible(false)
                if num ~= 3 then
                    if num >= i then
                        diamond:setVisible(true)             
                    end 
                end
                
            end
        end
    end

end

function OZWheelBgView:createWheelNode(states )

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local wheelData = selfdata.wheels or {}
    local data = {}
    data.wheelData = wheelData
    data.machine = self.m_machine
    data.wheelBg = self
    

    self.m_WheelView = util_createView("CodeOZSrc.Wheel.OZBonus_WheelView",data)   
    self:findChild("OZ_wheel"):addChild(self.m_WheelView)
    self.m_WheelView:setVisible(states)
end



function OZWheelBgView:onEnter()
 

end

function OZWheelBgView:setOverCall( func)
    self.m_overCallFunc = function(  )
        if func then
            func()
        end
    end
end

function OZWheelBgView:onExit()
 
end

function OZWheelBgView:wheelWinCoins( )

    if self.m_WheelView then
        self.m_WheelView:removeFromParent()
        self.m_WheelView = nil
    end

    gLobalSoundManager:playSound("OZSounds/music_OZ_Wheel_Walk.mp3")

    util_spinePlay(self.m_wheelGuoChangView,"actionframe4")
    util_spineEndCallFunc(self.m_wheelGuoChangView, "actionframe4", function(  )
        util_spinePlay(self.m_wheelGuoChangView,"actionframe",false)
        util_spineEndCallFunc(self.m_wheelGuoChangView, "actionframe", function(  )
            util_spinePlay(self.m_wheelGuoChangView,"actionframe",false)
            util_spineEndCallFunc(self.m_wheelGuoChangView, "actionframe", function(  )
                util_spinePlay(self.m_wheelGuoChangView,"actionframe",false)
                util_spineEndCallFunc(self.m_wheelGuoChangView, "actionframe", function(  )
                    util_spinePlay(self.m_wheelGuoChangView,"actionframe",false)
                    util_spineEndCallFunc(self.m_wheelGuoChangView, "actionframe", function(  )
                        util_spinePlay(self.m_wheelGuoChangView,"actionframe",false)
                        util_spineEndCallFunc(self.m_wheelGuoChangView, "actionframe", function(  )
                            util_spinePlay(self.m_wheelGuoChangView,"actionframe",false)
                            util_spineEndCallFunc(self.m_wheelGuoChangView, "actionframe", function(  )
    
                                util_spinePlay(self.m_wheelGuoChangView,"actionframe3")


                                gLobalSoundManager:playSound("OZSounds/music_OZ_Wheel_Show.mp3")

                                self.m_WheelJPView:runCsbAction("open",false,function(  )
                                    self.m_WheelJPView:runCsbAction("idle2",true)
                                end)
                                
                                self:createWheelNode( true )
    
                            end)
                        end)
                    end)
                end)
            end)
        end)
    end)

    
    
   
end



function OZWheelBgView:wheelWinJackPot( rewordType , coins ,func )
    
    -- 停止播放背景音乐
    self.m_machine:clearCurMusicBg()

    -- if self.m_WheelView then
    --     self.m_WheelView:setVisible(false)
    -- end

    gLobalSoundManager:playSound("OZSounds/music_OZ_Jp_view_sound.mp3")
    
    local name = "OZ/JackpotOver"

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local jackpotCounts = selfdata.jackpotCounts or { Mini = 0,Major = 0,Minor = 0}
    if jackpotCounts[rewordType] == 0 or jackpotCounts[rewordType] == 3 then
        name = "OZ/FreeSpinOver_0"

        self.m_BonusWheelWin = util_createView("CodeOZSrc.BonusGame.OZBonusWinView",name)   
        self:findChild("wheelWinView"):addChild(self.m_BonusWheelWin)
        self.m_BonusWheelWin:setPosition(-display.width/2,-display.height/2)

        local bet = 1
        local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
        local clientMultiply = selfdata.clientMultiply or 1
        local wheelAllCoins = selfdata.wheelAllCoins or 0

        if clientMultiply then
            bet = clientMultiply
        end

        local lb1 = self.m_BonusWheelWin:findChild("m_lb_coins_0")
        if wheelAllCoins then
            if lb1 then
                lb1:setString(util_formatCoins(wheelAllCoins,50))
                self.m_BonusWheelWin:updateLabelSize({label=lb1,sx=0.76,sy=0.76},806)
            end
        end
        

        local csbname = self:getDiamondCsbName( rewordType )
        local Diamond  = util_createView("CodeOZSrc.JackpotGame.OZJPDiamonds",csbname)
        self.m_BonusWheelWin:findChild("zuan"):addChild(Diamond)


        self.m_BonusWheelWin:setEndCalFunc(function(  )
            
            self.m_machine:showOverGuoChang( function(  )
                self.m_machine:initJackpotData( )
                self.m_machine:updateGirlPos( )
    
                self.m_machine:resetMusicBg(true)

                if func then
                    func()
                end
    
                if self.m_overCallFunc then
                    self.m_overCallFunc()
                end
    
                self:removeFromParent()
            end )

        end) 

        self.m_BonusWheelWin:findChild("Button_1"):setTouchEnabled(true) 

        local oldCoins = coins - wheelAllCoins
        local lb2 = self.m_BonusWheelWin:findChild("m_lb_coins")
        if lb2 then
            lb2:setString(util_formatCoins(oldCoins,50))
            self.m_BonusWheelWin:updateLabelSize({label=lb2,sx=0.76,sy=0.76},806)
        end

  

    else
        self.m_JPWheelWin = util_createView("CodeOZSrc.Wheel.OZWheelWinView",name)   
        self:findChild("wheelWinView"):addChild(self.m_JPWheelWin)
        self.m_JPWheelWin:setPosition(-display.width/2,-display.height/2)
    
        local lb = self.m_JPWheelWin:findChild("m_lb_num")
        if lb then
            lb:setString(util_formatCoins(coins,50))
            self.m_JPWheelWin:updateLabelSize({label=lb,sx=0.76,sy=0.76},806)
        end
    
    
        local csbname = self:getDiamondCsbName( rewordType )
        local Diamond  = util_createView("CodeOZSrc.JackpotGame.OZJPDiamonds",csbname)
        self.m_JPWheelWin:findChild("zuan"):addChild(Diamond)
    
        self.m_JPWheelWin:setEndCalFunc(function(  )
            
    
            self.m_machine:showOverGuoChang( function(  )
                self.m_machine:initJackpotData( )
                self.m_machine:updateGirlPos( )
    
                self.m_machine:resetMusicBg(true)
                
                if func then
                    func()
                end
    
                if self.m_overCallFunc then
                    self.m_overCallFunc()
                end
    
                self:removeFromParent()
            end )
        end) 
    end

    


end

function OZWheelBgView:wheelWinLucy( )

    -- 停止播放背景音乐
    self.m_machine:clearCurMusicBg()
    
    if self.m_WheelView then
        self.m_WheelView:removeFromParent()
        self.m_WheelView = nil
    end

    gLobalSoundManager:playSound("OZSounds/music_OZ_changeView_lucy.mp3")

    util_spinePlay(self.m_wheelGuoChangView,"actionframe2",false)
    util_spineFrameCallFunc(self.m_wheelGuoChangView, "actionframe2","Switch", function(  )

        local nameList = {"OZ_wheel","OZ_rl_lvdiban","wheelWinView"}
        for i=1,#nameList do
            local name = nameList[i]
            self:findChild(name):setVisible(false)
        end
        
        self.m_machine:showChestBonusView( function(  )
    
            if self.m_overCallFunc then
                self.m_overCallFunc()
            end

            self:removeFromParent()
            
        end,true ,true )

    end,function(  )

        

        self:setVisible(false)
    end)
 
end


function OZWheelBgView:getDiamondCsbName( rewordType )
    local csbType = nil
    if rewordType == "Mini" then
        csbType = "l"
    elseif rewordType == "Minor" then
        csbType = "z"
    else
        csbType = "h"
    end
    local csbname = "OZ_tb_zuan_" .. csbType

    return csbname
end

function OZWheelBgView:getNetShowDiamond( rewordType )

    local jackpotCounts = { Mini = 0,Major = 0,Minor = 0}

    for k,v in pairs(jackpotCounts) do
        local num = v
        if rewordType == tostring(k) then
            for i=1,3 do
                local nodename = k .. "_node_" .. i .. "_Diamond" 
                local diamond =  self.m_WheelJPView[nodename]
                if diamond then
                    if not diamond:isVisible() then
                       return diamond
                    end
                end
            end
        end
        
    end
end

function OZWheelBgView:runFlyWildActJumpTo(startNode,endNode,csbName,func,times,scale)


    local flytime = times or 0.5
    -- 创建粒子
    local flyNode =  util_createAnimation( csbName ..".csb")
    self.m_machine:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startPos = util_getConvertNodePos(startNode,flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = util_getConvertNodePos(endNode,flyNode)

    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        local actList_1 = {}
        actList_1[#actList_1 + 1] = cc.ScaleTo:create(flytime,scale or 1)
        local sq_1 = cc.Sequence:create(actList_1)
        flyNode:runAction(sq_1)
     end)
    actList[#actList + 1] = cc.JumpTo:create(flytime,cc.p(endPos),-80,1)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if func then
            func()
        end

        local actNode =  flyNode:findChild("Node_show")
        if actNode then
            actNode:setVisible(false)
        end
        
    end)
    actList[#actList + 1] = cc.DelayTime:create(flytime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:stopAllActions()
        flyNode:removeFromParent()
    end)

    local sq = cc.Sequence:create(actList)
    flyNode:runAction(sq)

    return flyNode

end

function OZWheelBgView:runFlyWildAct(startNode,endNode,csbName,func,times,scale)


    local flytime = times or 0.5
    -- 创建粒子
    local flyNode =  util_createAnimation( csbName ..".csb")
    self.m_machine:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startPos = util_getConvertNodePos(startNode,flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = util_getConvertNodePos(endNode,flyNode)


    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        local actList_1 = {}
        actList_1[#actList_1 + 1] = cc.ScaleTo:create(flytime,scale or 1)
        local sq_1 = cc.Sequence:create(actList_1)
        flyNode:runAction(sq_1)
     end)
    actList[#actList + 1] = cc.MoveTo:create(flytime,cc.p(endPos.x,endPos.y + 30))
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if func then
            func()
        end

        local actNode =  flyNode:findChild("Node_show")
        if actNode then
            actNode:setVisible(false)
        end
        
    end)
    actList[#actList + 1] = cc.DelayTime:create(flytime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:stopAllActions()
        flyNode:removeFromParent()
    end)

    local sq = cc.Sequence:create(actList)
    flyNode:runAction(sq)

    return flyNode

end

return OZWheelBgView