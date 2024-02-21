local Config    = require("CandyPusherSrc.GamePusherMain.GamePusherConfig")
local GamePusherMainUI = class("GamePusherMainUI",util_require("base.BaseView"))
local GamePusherManager   = require "CandyPusherSrc.GamePusherManager"

--p_ViewLayer child 类型
local ViewType = {
    TYPE_UI = 100,  --UI弹窗tag
}

GamePusherMainUI.m_overLeftTime = -1

GamePusherMainUI.m_currBoxLevel = 0

GamePusherMainUI.m_comBoCoinsNum = 0

function GamePusherMainUI:initUI(_data)
    
    self:createCsbNode(Config.UICsbPath.MainUI, false)

    self.m_pGamePusherMgr = GamePusherManager:getInstance()  -- Mgr对象



    -- q墙道具倒计时
    self.m_wallBar = util_createView(Config.ViewPathConfig.WallBar)
    self:findChild("pusherLevel_WallBar"):addChild(self.m_wallBar)
    self.m_wallBar:setVisible(false)


    self.m_currBoxLevel = 0
    self.m_overLeftTime = -1
    -- 剩余可点击次数
    self.m_leftCoinsCsb = util_createAnimation( Config.UICsbPath.LeftCoinsCsb)
    self:findChild("pusherLevel_LeftNum"):addChild(self.m_leftCoinsCsb)
    self.m_leftFreeCoinsTimes    = self.m_leftCoinsCsb:findChild("m_lb_num")
    self.m_leftCoinsCsb:setVisible(false)

    -- jackpotLogo显示
    self.m_jpLogoCsb = util_createAnimation( Config.UICsbPath.JpLogoCsbCsb)
    self:findChild("pusherLevel_jackpot"):addChild(self.m_jpLogoCsb)
    self.m_jpLogoCsb:setVisible(false)
    
    self.m_nodeTop    = self:findChild("node_top")
    self.m_nodeDown    = self:findChild("node_down")

    self.m_tDropEffectTable   = {}

    self.m_bTouchState      = false

                     

    self:adaptTopNode()
    self:adaptDownNode( )

    self.m_totalWin = util_createAnimation( Config.UICsbPath.totalWinCsb)
    self:findChild("Node_TotalWin"):addChild(self.m_totalWin)
    self.m_totalWin:setPosition(display.center.x,0)
    if display.height < DESIGN_SIZE.height then
        local cutScale = 0.3 / ( DESIGN_SIZE.height - 1024 )  
        self.m_totalWin:setScale(1 - (cutScale * (DESIGN_SIZE.height - display.height) ) )
    end
    self:updateTotaleCoins( 0 )

    self.m_comBoCoinsNum = 0
    self.m_comBoDelayNode = cc.Node:create()
    self:addChild(self.m_comBoDelayNode)
    
end




function GamePusherMainUI:adaptDownNode( )
    local designSize = DESIGN_SIZE

    local downPosY = - self:getCsbNodeScale() * (display.height / 2)  
    if display.height > DESIGN_SIZE.height then
        downPosY = downPosY + (display.height - DESIGN_SIZE.height) * 0.6
    end
    self.m_nodeDown:setPositionY(downPosY)
    
    local bangDownHeight = util_getSaveAreaBottomHeight()
    if bangDownHeight  then
        local downPositionY = self.m_nodeDown:getPositionY()
        self.m_nodeDown:setPositionY(downPositionY + bangDownHeight)
    end

end

function GamePusherMainUI:adaptTopNode(  )
    local designSize = DESIGN_SIZE

    local topPosY = self:getCsbNodeScale() * (display.height / 2) 
    self.m_nodeTop:setPositionY(topPosY)
    local bangHeight = util_getBangScreenHeight()
    if bangHeight then
        local topPositionY = self.m_nodeTop:getPositionY()
        self.m_nodeTop:setPositionY(topPositionY - bangHeight)
    end

end

function GamePusherMainUI:setTouchState(_bState)
    self.m_bTouchState = _bState
end

function GamePusherMainUI:upDataTimesLb(_nCount)

    self.m_leftFreeCoinsTimes:setString(tostring(_nCount))
    self:updateLabelSize({label = self.m_leftFreeCoinsTimes,sx = 1,sy = 1},66)

end

function GamePusherMainUI:jumpTimesLb(_nCount,_callFunc,_beginNum,_jumpTime)

    if self.m_jumpDoundId then
        gLobalSoundManager:stopAudio(self.m_jumpDoundId)
        self.m_jumpDoundId = nil
    end    
    self.m_jumpDoundId = gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_jumpTimesLb.mp3",true)
    

    local count     = _nCount
    local time      = _jumpTime or 1
    local callFunc  = _callFunc

    local callback = function(  )

        if self.m_jumpDoundId then
            gLobalSoundManager:stopAudio(self.m_jumpDoundId)
            self.m_jumpDoundId = nil
        end 

        self:upDataTimesLb(_nCount)

        if callFunc then
            callFunc()
        end
    end

    
    local beginNum = _beginNum or 0
    util_jumpNum(self.m_leftFreeCoinsTimes,beginNum,count,count/60,time/60,{30},nil,nil,callback,function(  )
        self:updateLabelSize({label = self.m_leftFreeCoinsTimes,sx = 1,sy = 1},65)
    end)




end



function GamePusherMainUI:clickFunc( sender )
    if not self.m_bTouchState then
        return 
    end
    local name = sender:getName()
    local tag = sender:getTag()



end

---------------------------------------播放背景音乐 S---------------------------------------


function GamePusherMainUI:setBuffState(bExist)
    if self.m_bBuffExist ~= bExist then
        self.m_bBuffExist = bExist
    end
end


---------------------------------------显示掉落币的钱数 S------------------------------------------
function GamePusherMainUI:playCoinsShowEffect( _num,_vPos,_id,_testNum)

    gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_CoinsShow.mp3")
    local scoreAnima = util_createAnimation(Config.UICsbPath.ShowSocreCsb)
    
    if _id == Config.CoinModelRefer.BIG then
        _vPos.y = 120
        scoreAnima:runCsbAction("show2",false,function(  )

            if not tolua.isnull(scoreAnima) then
                scoreAnima:removeFromParent()
            end

        end) 
    elseif _id == Config.CoinModelRefer.SLOTS then

        _vPos.y = 160
        scoreAnima:runCsbAction("show3",false,function(  )
            if not tolua.isnull(scoreAnima) then
                scoreAnima:removeFromParent()
            end
        end) 

    else
        _vPos.y = math.random(-1200,1000) / 10
        scoreAnima:runCsbAction("show",false,function(  )
            if not tolua.isnull(scoreAnima) then
                scoreAnima:removeFromParent()
            end
        end)  
    end

    scoreAnima:setPosition(_vPos)

    local coins = _num * self.m_pGamePusherMgr:getPusherTotalBet( )
    if _testNum then
        coins = _testNum
    end
    local lab = scoreAnima:findChild("m_lb_coins")
    if lab then
        lab:setString(util_formatCoins(coins,3))
    end
    local lab1 = scoreAnima:findChild("m_lb_coins_big")
    if lab1 then
        lab1:setString(util_formatCoins(coins,3))
    end

    self:findChild("effect_layer"):addChild( scoreAnima, Config.MainUIZorder.Combo)
   
end



function GamePusherMainUI:setAllComboVisibel()
    for i=#self.m_tDropEffectTable,1,-1 do
        local comboSp = self.m_tDropEffectTable[i]
        if not tolua.isnull(comboSp)  then
            comboSp:setVisible(false)
        end
    end
end
---------------------------------------连击动画 E------------------------------------------
function GamePusherMainUI:playComBoCoinsDropEffect(_coinID )

    self.m_comBoDelayNode:stopAllActions()
    self.m_comBoCoinsNum = self.m_comBoCoinsNum + 1

    performWithDelay(self.m_comBoDelayNode,function(  )
        local level = 0
        for i=#Config.ComBoLevel,1,-1 do
            local num = Config.ComBoLevel[i]
            if self.m_comBoCoinsNum >= num then
                level = i
                break
            end
        end
        self.m_comBoCoinsNum = 0
        if level > 0 then
            
        end
        
        
        print("level-------"..level)
    end, Config.ComBoDelayTime)

end
---------------------------------------金币掉落位置播放动画 S--------------------------------
function GamePusherMainUI:playCoinWinDropEffect(_vPos, _coinID)

    self:playComBoCoinsDropEffect(_coinID )

    local csbName = nil
    local zorder = Config.MainUIZorder.WinLight + 1
    if  _coinID == Config.CoinModelRefer.SLOTS then
        csbName = "CandyPusherMainUI/CoinPusher_XFlizi1.csb"
    else
        csbName = "CandyPusherMainUI/CoinPusher_XFlizi.csb"
    end
    
    local winDropEffect = util_createAnimation(csbName)
     winDropEffect:setScale(0.8)
     self:findChild("effect_layer"):addChild( winDropEffect, zorder)
    winDropEffect:setPosition(_vPos)

    
    winDropEffect:playAction("actionframe",false,function(  )
        if not tolua.isnull(winDropEffect) then
            for i=#self.m_tDropEffectTable,1,-1 do
                if self.m_tDropEffectTable[i] == winDropEffect  then
                    table.remove(self.m_tDropEffectTable, i)
                    break
                end
            end

            if not tolua.isnull(winDropEffect) then
                winDropEffect:removeFromParent()
            end

        end
    end)

    self.m_tDropEffectTable[#self.m_tDropEffectTable + 1] = winDropEffect
end


function GamePusherMainUI:onEnter()
    self:registerObserver() 
end

function GamePusherMainUI:registerObserver()

    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新剩余可以点击的次数
        self:upDataTimesLb(params.ntimes)
    end, Config.Event.GamePusherMainUI_UpdateLeftFreeCoinsTimes)

    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新剩余可以点击的次数
        self:jumpTimesLb(params.ntimes,params.callfunc,params.beginNum,params.jumpTime)
    end, Config.Event.GamePusherMainUI_JumpLeftFreeCoinsTimes)

    gLobalNoticManager:addObserver( self,function(self, params)  -- 播放剩余可点击弹板栏动画
        self:updateTotaleCoins(params.coinNum,params.jpNum )        
    end, Config.Event.GamePusherMainUI_updateTotaleCoins) 
  
end

function GamePusherMainUI:onExit()
    if self.m_jumpDoundId then
        gLobalSoundManager:stopAudio(self.m_jumpDoundId)
        self.m_jumpDoundId = nil
    end 
    gLobalNoticManager:removeAllObservers(self)
end


function GamePusherMainUI:updateTotaleCoins(_coinNum )
    


    if self.m_totalWin and _coinNum > 0 then
        local totalCoins = _coinNum * self.m_pGamePusherMgr:getPusherTotalBet( )
        local labCoins   = self.m_totalWin:findChild("m_lb_coins")
        labCoins:setString(util_formatCoins(totalCoins,50))
        self:updateLabelSize({label = labCoins,sx = 0.8,sy = 0.8},670)
    else
        self.m_totalWin:findChild("m_lb_coins"):setString("")
    end 
    
end

function GamePusherMainUI:playLeftCoinsAnim( nAnimName,nIsLoop,nCallFunc)
    if self.m_leftCoinsCsb then
        self.m_leftCoinsCsb:setVisible(true)
        self.m_leftCoinsCsb:runCsbAction(nAnimName,nIsLoop,nCallFunc)
    end 
end

function GamePusherMainUI:initJpLogoImg(_index )
    
    local imgName = {"grand", "major", "minor" ,"mini"}
    for i=1,#imgName do
        local img = self.m_jpLogoCsb:findChild(imgName[i])
        if i == _index then
            img:setVisible(true)
        else
            img:setVisible(false)
        end
    end
    
end

function GamePusherMainUI:showJackpotView(jpType,coins,func,machine)

    gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_jpEnAnim.mp3")

    self.m_jpLogoCsb:setVisible(true)
    self.m_jpLogoCsb:runCsbAction("actionframe2",false,function(  )
        self.m_jpLogoCsb:runCsbAction("tanban_start",false,function(  )
            self.m_jpLogoCsb:setVisible(false)
        end)

         local index = self.m_pGamePusherMgr:getJpTypeIndex(jpType)
         self.m_jackPotWinView = util_createView("CandyPusherSrc.CandyPusherJackPotWinView",self,machine)
         machine:addChild(self.m_jackPotWinView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
         self.m_jackPotWinView:setPosition(util_getConvertNodePos(self:findChild("Node_jackpotView"),self.m_jackPotWinView))
         

         self.m_jackPotWinView:initViewData(index,coins,function()
     
            self.m_jackPotWinView:runCsbAction("over",false,function(  )
         
                     if func ~= nil then 
                         func()
                     end 
                     self.m_jackPotWinView:removeFromParent()
                     self.m_jackPotWinView = nil
                 end)
                 
         end)
    end)
    
  
 end

return GamePusherMainUI