local Config    = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")
local GamePusherMainUI = class("GamePusherMainUI",util_require("base.BaseView"))
local GamePusherManager   = require "CoinCircusSrc.GamePusherManager"

--p_ViewLayer child 类型
local ViewType = {
    TYPE_UI = 100,  --UI弹窗tag
}

GamePusherMainUI.m_overLeftTime = -1

GamePusherMainUI.m_currBoxLevel = 0

function GamePusherMainUI:initUI(_data)
    --[[
        _data = {
            machine = machine
        }
    ]]
    self.m_machine = _data.machine
    self:createCsbNode(Config.UICsbPath.MainUI, false)

    self.m_currBoxLevel = 0
    self.m_overLeftTime = -1
    -- 剩余可点击次数
    self.m_leftCoinsCsb = util_createAnimation( Config.UICsbPath.LeftCoinsCsb)
    self:findChild("pusherLevel_LeftNum"):addChild(self.m_leftCoinsCsb)
    self.m_leftFreeCoinsTimes    = self.m_leftCoinsCsb:findChild("m_lb_num")
    
    self.m_leftCoinsCsb:setVisible(false)

    -- 倒计时弹板
    self:findChild("daojishi"):setScale(0.85)

    self:findChild("daojishi"):setPositionY(display.height/2)

    self.m_daoJiShiMask = util_createAnimation("CoinCircus_Bonus_mask_0.csb")
    self:findChild("root"):addChild(self.m_daoJiShiMask,-1)
    self.m_daoJiShiMask:setVisible(false)

    self.m_daojishiWaitNode = cc.Node:create()
    self:addChild(self.m_daojishiWaitNode) 

    -- 道具面板
    self.m_propView = util_createView(Config.ViewPathConfig.PropView)
    self:findChild("pusherLevel_Item"):addChild(self.m_propView)
    self.m_propView:setVisible(false)

    
    -- 进度条
    self.m_progressCsb = util_createAnimation(Config.UICsbPath.ProgressCsb)
    self:findChild("pusherLevel_Progress"):addChild(self.m_progressCsb )
    self.m_progressCsb:runCsbAction("idle") 
    self.m_pgEnergyMaxWidth = {103,208,311,478,710}
    self.m_pgEnergyBeginWidth = {0,107,212,316,482}
    self.m_pgEnergyMaxNum = {10,20,30,40,50}
    self.m_progressCsb:setVisible(false)

    self.m_jpCollectNum     =   self:findChild("m_lb_num_0_0") -- 用作显示当前掉落有效金币的个数
    self.m_jpCollectNum:setVisible(false)

    self.m_pgEnergy   = self.m_progressCsb:findChild("Node_pgEnergy")

    self.m_loadingAni = util_createAnimation("CoinCircus_jindutiao_0.csb")
    self.m_pgEnergy:addChild(self.m_loadingAni)
    self.m_loadingAni.m_AniStates = "idle"

    -- 宝箱
    for i=1,5 do
        self["pgBaoXiang_"..i] = util_createAnimation("CoinCircus_baoxiang_" ..i  .. ".csb")
        self.m_progressCsb:findChild("baoxiang_"..i):addChild(self["pgBaoXiang_"..i])
        self["pgBaoXiang_"..i]:setTag(i)
        self["pgBaoXiang_"..i]:runCsbAction("idle2",true) 
    end

    -- 第二币值显示框
    -- self.m_topCoinsView = util_createAnimation( Config.UICsbPath.SecondPayCsb)
    -- self:findChild("Node_topCoins"):addChild(self.m_topCoinsView)
    -- self.m_topCoinsView:setVisible(false)



    
    self.m_nodeTop    = self:findChild("node_top")
    self.m_nodeDown    = self:findChild("node_down")
    
    self.m_tComboTable        = {}
    self.m_tSpecialComboTable = {}
    self.m_tDropEffectTable   = {}

    

    self.m_bStopComboEffect = false
    self.m_bTouchState      = false

    self.m_pGamePusherMgr = GamePusherManager:getInstance()                  -- Mgr对象

    self:initEnergyProgress(0)    
    self:adaptTopNode()
    self:adaptDownNode( )
    self:updateTopUserCoins( )
    self:setDaJiShiMask(false )

end

function GamePusherMainUI:setDaJiShiMask(_isVisible )
    -- self.m_topCoinsView:findChild("CoinCircus_mask"):setVisible(_isVisible)
    self.m_leftCoinsCsb:findChild("CoinCircus_mask"):setVisible(_isVisible)
    self.m_daoJiShiMask:setVisible(_isVisible)
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
    self:updateLabelSize({label = self.m_leftFreeCoinsTimes,sx = 2,sy = 2},75)

end

function GamePusherMainUI:jumpTimesLb(_nCount,_callFunc)

    if self.m_jumpDoundId then
        gLobalSoundManager:stopAudio(self.m_jumpDoundId)
        self.m_jumpDoundId = nil
    end    
    self.m_jumpDoundId = gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_jumpTimesLb.mp3",true)
    

    local count     = _nCount
    local time      = 1
    local callFunc  = _callFunc

    local callback = function(  )

        if self.m_jumpDoundId then
            gLobalSoundManager:stopAudio(self.m_jumpDoundId)
            self.m_jumpDoundId = nil
        end 

        self.m_leftFreeCoinsTimes:setString(tostring(count))
        self:updateLabelSize({label = self.m_leftFreeCoinsTimes,sx = 2,sy = 2},75)

        if callFunc then
            callFunc()
        end
    end

    

    util_jumpNum(self.m_leftFreeCoinsTimes,0,count,count/60,time/60,{30},nil,nil,callback,function(  )
        self:updateLabelSize({label = self.m_leftFreeCoinsTimes,sx = 2,sy = 2},75)
    end)




end



function GamePusherMainUI:initEnergyProgress(_posX)
    self.m_pgEnergy:setPositionX(_posX)
end

function GamePusherMainUI:setEffectStop(_bState)
    self.m_bStopComboEffect = _bState
end

function GamePusherMainUI:getCurrEnergyProgressX(_nCount )

    if _nCount >  self.m_pgEnergyMaxNum[#self.m_pgEnergyMaxNum] then -- 认为数组最后一位是最大的
        _nCount = self.m_pgEnergyMaxNum[#self.m_pgEnergyMaxNum]
    end
    -- 找到当前是第几档
    local currLevel = 5
    for i = 1,#self.m_pgEnergyBeginWidth do
        local maxNum = self.m_pgEnergyMaxNum[i]
        if _nCount <= maxNum then

            currLevel = i

            break
        end
    end

    local maxWidth = self.m_pgEnergyMaxWidth[currLevel]
    local beginWidth = self.m_pgEnergyBeginWidth[currLevel]
    local cutNum = self.m_pgEnergyMaxNum[1]
    local maxCurrNum = self.m_pgEnergyMaxNum[currLevel]
    if currLevel ~= 1 then
        cutNum = self.m_pgEnergyMaxNum[currLevel] - self.m_pgEnergyMaxNum[currLevel - 1]
    end
    local addWidth = (maxWidth - beginWidth ) / cutNum

    local currX = maxWidth -  addWidth * (maxCurrNum - _nCount)

    return currX,currLevel
end

function GamePusherMainUI:getBoxIndex(_nCount )
    
     -- 找到当前是第几档
     local currLevel = 0
     for i = #self.m_pgEnergyMaxNum,1,-1 do
         local maxNum = self.m_pgEnergyMaxNum[i]
         if _nCount >= maxNum then
 
             currLevel = i
 
             break
         end
     end

     return currLevel
end

function GamePusherMainUI:setEnergyProgress(_nCount)
    local precentX = self:getCurrEnergyProgressX(_nCount )

    self.m_pgEnergy:setPositionX(precentX)
end

function GamePusherMainUI:playbaoXiangAnim(_nowPercentX )

    local nowPercentX = _nowPercentX
    for i=#self.m_pgEnergyMaxWidth,1,-1 do
        local maxWidth = self.m_pgEnergyMaxWidth[i]
        if nowPercentX >= maxWidth then
            if i > self.m_currBoxLevel then

                self.m_currBoxLevel = i

                local currlevel =  i 
                local animData = {}
                animData.nBoxIndex      = currlevel
                animData.nIsLoop        = false
                animData.nAnimName      = "actionframe"
                animData.nisPlay        = true
                animData.nCollectAnim   = true
                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayBaoXiangAnim,animData)  
            end
            
            break
        end
    end

end

function GamePusherMainUI:upDataEnergyProgress(_nCount)

    if self.m_pgEnergyUp then
        self:stopAction(self.m_pgEnergyUp)
        self.m_pgEnergyUp = nil
    end
    local maxCollectWidth = self.m_pgEnergyMaxWidth[#self.m_pgEnergyMaxWidth]
    local precentMax = self:getCurrEnergyProgressX(_nCount )
    local precentX = self:getCurrEnergyProgressX(_nCount )
    local nowPercentX = self.m_pgEnergy:getPositionX()

    if _nCount <= self.m_pgEnergyMaxNum[#self.m_pgEnergyMaxNum] then
        if self.m_loadingAni.m_AniStates == "idle" then
            self.m_loadingAni.m_AniStates = "actionframe"
            self.m_loadingAni:runCsbAction("actionframe",false,function(  )
                self.m_loadingAni.m_AniStates = "idle"
            end)
        end
    end

    self.m_pgEnergyUp = schedule(
        self,
        function()
            nowPercentX = nowPercentX + 1
            local stop = false

            if nowPercentX >= maxCollectWidth then
                nowPercentX = maxCollectWidth
                stop = true
            elseif nowPercentX > precentX then
                nowPercentX = precentX
                stop = true
            end
    
            self.m_pgEnergy:setPositionX(nowPercentX)


            self:playbaoXiangAnim(nowPercentX )
 

            if stop then
                self:stopAction(self.m_pgEnergyUp)
                self.m_pgEnergyUp = nil
            end
        end,
        0.001
    )

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





---------------------------------------连击动画 S------------------------------------------
function GamePusherMainUI:playComboEffect(_nComboindex, _vPos)
    if self.m_bStopComboEffect then
        return 
    end
    local displayWidth = display.width
    local posXLeft  = displayWidth / 4
    local posXRight = displayWidth / 4 * 3

    local spPos = nil
    if _vPos.x <= display.width / 2 then
        spPos = cc.p(posXLeft, 0)
    else
        spPos = cc.p(posXRight, 0)
    end

    local combolAnima = util_createAnimation(Config.UICsbPath.ComboCsb)
    combolAnima:setPosition(spPos)
    local nodeList = combolAnima:findChild("Node_1"):getChildren()
    for i=1,#nodeList do
        local node = nodeList[i]
        node:setVisible(false)
    end
    local child =  combolAnima:findChild("attack_" .. _nComboindex)
    child:setVisible(true)

    performWithDelay(self, function(  )
        for i=#self.m_tComboTable,1,-1 do
            local comboSp = self.m_tComboTable[i]
            if tolua.isnull(comboSp)  then
                table.remove(self.m_tComboTable, i)
            else
                comboSp:setVisible(false)
            end
        end
        self.m_tComboTable[ #self.m_tComboTable + 1] = combolAnima
    end, 0.5)

    combolAnima:playAction("start",false, function(  )
        combolAnima:removeFromParent()
    end)
    self:findChild("effect_layer"):addChild( combolAnima, Config.MainUIZorder.Combo)
   
    
end

function GamePusherMainUI:playSpecialCoinRewardEffect(_nComboindex, _vPos, _nId)
    if self.m_bStopComboEffect then
        return 
    end

    local displayWidth = display.width
    local posXLeft  = displayWidth / 4
    local posXRight = displayWidth / 4 * 3

    local spPos = nil
    if _vPos.x <= display.width / 2 then
        spPos = cc.p(posXLeft, 0)
    else
        spPos = cc.p(posXRight, 0)
    end

    local combolAnima = util_createAnimation(Config.UICsbPath.ComboCsb)
    combolAnima:setPosition(spPos)
    local nodeList = combolAnima:findChild("Node_1"):getChildren()
    for i=1,#nodeList do
        local node = nodeList[i]
        node:setVisible(false)
    end
    
    local child =  combolAnima:findChild("attack_" .. "COINS")
    child:setVisible(true)

    performWithDelay(self, function(  )
        for i=#self.m_tSpecialComboTable,1,-1 do
            local comboSp = self.m_tSpecialComboTable[i]
            if tolua.isnull(comboSp)  then
                table.remove(self.m_tSpecialComboTable, i)
            else
                comboSp:setVisible(false)
            end
        end
        self.m_tSpecialComboTable[ #self.m_tSpecialComboTable + 1] = combolAnima
    end, 0.5)

    combolAnima:playAction("start",false, function(  )
        combolAnima:removeFromParent()
    end)
    self:findChild("effect_layer"):addChild( combolAnima, Config.MainUIZorder.Combo + 10)
end

function GamePusherMainUI:setAllComboVisibel()
    for i=#self.m_tSpecialComboTable,1,-1 do
        local comboSp = self.m_tSpecialComboTable[i]
        if not tolua.isnull(comboSp)  then
            comboSp:setVisible(false)
        end
    end

    for i=#self.m_tComboTable,1,-1 do
        local comboSp = self.m_tComboTable[i]
        if not tolua.isnull(comboSp)  then
            comboSp:setVisible(false)
        end
    end
    for i=#self.m_tDropEffectTable,1,-1 do
        local comboSp = self.m_tDropEffectTable[i]
        if not tolua.isnull(comboSp)  then
            comboSp:setVisible(false)
        end
    end
end
---------------------------------------连击动画 E------------------------------------------

---------------------------------------金币掉落位置播放动画 S--------------------------------
function GamePusherMainUI:playCoinWinDropEffect(_vPos, _coinID)
    if self.m_bStopComboEffect then
        return 
    end
    
    local csbName = nil
    local zorder = Config.MainUIZorder.WinLight + 1
    if _coinID == Config.CoinEffectRefer.JACKPOT or _coinID == Config.CoinEffectRefer.RANDOM then
        csbName = "CoinPusher/CoinPusher_XFlizi1.csb"
    else
        csbName = "CoinPusher/CoinPusher_XFlizi.csb"
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
            winDropEffect:removeFromParent()
        end
    end)

    self.m_tDropEffectTable[#self.m_tDropEffectTable + 1] = winDropEffect
end

---------------------------------------弹窗弹出 S------------------------------------------


function GamePusherMainUI:showRewardLayer(path)
    local cardRewardLayer = util_createView(Config.ViewPathConfig.ShowView,path)
    gLobalViewManager:showUI(cardRewardLayer,ViewZorder.ZORDER_UI,false)
end

function GamePusherMainUI:showWheelView(_endIndex,_callBackFun,_jpindex,_winCoins )
    gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_Show_Wheel.mp3")

    local wheel = util_createView(Config.ViewPathConfig.WheelView, { machine = self.m_machine})
    wheel:setPosition(display.width/2,display.height/2)
    self:addChild(wheel,Config.MainUIZorder.ViewLayer)
    wheel:setScale(self.m_pGamePusherMgr:getSlotMainRootScale( ))

    local currCallFunc = function(  )

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            if _callBackFun then
                _callBackFun()
            end
            wheel:removeFromParent()
            waitNode:removeFromParent()
        end,0.1)
        
    end

    wheel:initCallBack(_endIndex,currCallFunc,_jpindex,_winCoins)
    wheel:playShowWheelAni( )
   
    if globalData.slotRunData.machineData.p_portraitFlag then
        wheel.getRotateBackScaleFlag = function(  ) return false end
    end

    wheel.viewType = ViewType.TYPE_UI
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = wheel})

end

function GamePusherMainUI:onEnter()
    self:registerObserver() 
end

function GamePusherMainUI:registerObserver()

    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新剩余可以点击的次数
        self:upDataTimesLb(params.ntimes)
        end, Config.Event.GamePusherMainUI_UpdateLeftFreeCoinsTimes
    )

    gLobalNoticManager:addObserver( self,function(self, params)                -- 更新剩余可以点击的次数
        self:jumpTimesLb(params.ntimes)
        end, Config.Event.GamePusherMainUI_JumpLeftFreeCoinsTimes
    )

    gLobalNoticManager:addObserver( self,function(self, params)  -- 更新进度条进度

        self.m_jpCollectNum:setString(params.nCount)
        if params.nInit then
            self:setEnergyProgress(params.nCount)
        else
            self:upDataEnergyProgress(params.nCount)
        end              
        end, Config.Event.GamePusherMainUI_UpdateProgressCount
    )


    gLobalNoticManager:addObserver( self,function(self, params)  -- 显示大转盘
        self:showWheelView(params.nEndIndex,params.nCallBackFun,params.njpindex,params.nwinCoins )    
        end, Config.Event.GamePusherMainUI_ShowWheelView
    )

    gLobalNoticManager:addObserver( self,function(self, params)  -- 显示道具栏显示状态
        if self.m_propView then
            self.m_propView:setVisible(params.nVisible)
        end        
        end, Config.Event.GamePusherMainUI_SetPropViewVisible
    ) 
    
    gLobalNoticManager:addObserver( self,function(self, params)  -- 播放道具栏动画
        if self.m_propView then
            self.m_propView:runCsbAction(params.nAnimName,params.nIsLoop,params.nCallFunc)
        end        
        end, Config.Event.GamePusherMainUI_PlayPropViewAnim
    )  

    gLobalNoticManager:addObserver( self,function(self, params)  -- 收集jpCoins道具栏动画
        if self.m_propView then
            self:playCollectJpCoinsAnim(params.nCallFunc)
        end        
        end, Config.Event.GamePusherMainUI_PlayPropCollectJpCoinsAnim
    ) 

    gLobalNoticManager:addObserver( self,function(self, params)  -- 收集jpCoins触发转盘动画
        if self.m_propView then
            self:playCollectJpTriggerCoinsAnim(params.nCallFunc)
        end        
        end, Config.Event.GamePusherMainUI_PlayPropCollectJpCoinsTriggerAnim
    ) 
    

    gLobalNoticManager:addObserver( self,function(self, params)  -- 设置进度条显示状态
        if self.m_progressCsb then
            self.m_progressCsb:setVisible(params.nVisible)

            if params.nScale then
                self.m_progressCsb:setScale(params.nScale)
            end
        end        
        end, Config.Event.GamePusherMainUI_SetProgressViewVisible
    ) 

    gLobalNoticManager:addObserver( self,function(self, params)  -- 播放进度条动画
        if self.m_progressCsb then
            self.m_progressCsb:runCsbAction(params.nAnimName,params.nIsLoop,params.nCallFunc)
        end     
        end, Config.Event.GamePusherMainUI_PlayProgressViewAnim
    ) 
    
    gLobalNoticManager:addObserver( self,function(self, params)  -- 设置s剩余可点击弹板显示状态
        if self.m_leftCoinsCsb  then
            self.m_leftCoinsCsb:setVisible(params.nVisible)
        end        
        end, Config.Event.GamePusherMainUI_SetLeftFreeCoinsViewVisible
    ) 

    gLobalNoticManager:addObserver( self,function(self, params)  -- 播放剩余可点击弹板栏动画
        if self.m_leftCoinsCsb then
            self.m_leftCoinsCsb:runCsbAction(params.nAnimName,params.nIsLoop,params.nCallFunc)
        end        
        end, Config.Event.GamePusherMainUI_PlayLeftFreeCoinsViewAnim
    ) 


    gLobalNoticManager:addObserver( self,function(self, params)  -- 设置s剩余可点击弹板显示状态
        
        self.m_pgEnergyMaxNum = {}

        for i=1,5 do
            local coins = params.nCollectData[i].coins
            local collectNum = params.nCollectData[i].collectNum
            self.m_pgEnergyMaxNum[i] = collectNum
            local coinsLab = self["pgBaoXiang_"..i]:findChild("BitmapFontLabel_3")
            if coinsLab then
                coinsLab:setString( util_formatCoins(coins,3) )
            end
        end   
        end, Config.Event.GamePusherMainUI_CollectData
    ) 

    gLobalNoticManager:addObserver( self,function(self, params)  -- 播放宝箱动画
        
        local boxIndex      = params.nBoxIndex
        local isLoop        = params.nIsLoop
        local aniName       = params.nAnimName
        local isPlay        = params.nisPlay
        local callFunc      = params.nCallFunc
        local isPlayIdle    = params.nisPlayIdle
        local isRest        = params.nisRest
        local collectAnim  = params.nCollectAnim

        local box = self["pgBaoXiang_"..boxIndex]
        if box then
            if isRest then
                box.isPlay = nil
            end
            if not box.isPlay then
                if collectAnim then
                    self:playCollectBoxCoinsAnim(boxIndex)
                else
                    box:runCsbAction(aniName,isLoop,function(  )
                        if isPlayIdle then
                            box:runCsbAction("idle",true)
                        end
                    end)  
                end
                
                
            end
        end
        

        box.isPlay = isPlay

        end, Config.Event.GamePusherMainUI_PlayBaoXiangAnim
    ) 


    gLobalNoticManager:addObserver( self,function(self, params) -- 第二币值显示板播放动效

        -- if self.m_topCoinsView then
        --     self.m_topCoinsView:setVisible(params.nVisible)
        -- end  
        end,Config.Event.GamePusherMainUI_setTopCoinsViewVisible
    )

    
    gLobalNoticManager:addObserver( self,function(self, params) -- 第二币值显示板播放动效

        -- if self.m_topCoinsView then

        --     local isLoop        = params.nIsLoop
        --     local aniName       = params.nAnimName
        --     local callFunc      = params.nCallFunc
        --     local isPlayIdle    = params.nisPlayIdle
        --     self.m_topCoinsView:runCsbAction(aniName,isLoop,function(  )
        --         if isPlayIdle then
        --             self.m_topCoinsView:runCsbAction("idle",true)
        --         end
        --     end)

        -- end  
        

        end,Config.Event.GamePusherMainUI_PlayTopCoinsViewAnim
    )
    
    gLobalNoticManager:addObserver( self,function(self, params) -- 第二币值更新玩家拥有钱数

            
        self:updateTopUserCoins( )

        -- 更新道具价钱
        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_updatePropPrice) 
        
        end,ViewEventType.NOTIFY_TOP_UPDATE_GEM
    )

   
end

function GamePusherMainUI:playPropViewStopIdle( )

end

function GamePusherMainUI:playPropViewPowerfulIdle( )
      --load游戏数据
      local PuserPropData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
      local jpCollectCurrNum = PuserPropData.jpCollectCurrNum or 0
      local playPropData = {}
      if jpCollectCurrNum > 0 then
          playPropData.nAnimName = "idle5"
      else
          playPropData.nAnimName = "idle3"
      end
      playPropData.nIsLoop = true
      gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayPropViewAnim,playPropData)
end

function GamePusherMainUI:playPropViewWeakIdle( )
    --load游戏数据
    local PuserPropData = self:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    local jpCollectCurrNum = PuserPropData.jpCollectCurrNum or 0
    local playPropData = {}
    if jpCollectCurrNum > 0 then
        playPropData.nAnimName = "idle6"
    else
        playPropData.nAnimName = "idle2"
    end
    playPropData.nIsLoop = true
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayPropViewAnim,playPropData)
end

function GamePusherMainUI:playCollectJpTriggerCoinsAnim( _func )

    gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_WheelTrigger.mp3")

    local endNode =  self.m_propView:getPropIconNode("jackpot")
    local endPos = util_convertToNodeSpace(endNode,self)
    local time = 42/60
    local flyNode = util_createAnimation(Config.UICsbPath.JpCollectAniCsb)
    self:addChild(flyNode,Config.MainUIZorder.ViewLayer)
    flyNode:setPosition(endPos)

    flyNode:findChild("Particle_1"):resetSystem()
    flyNode:runCsbAction("actionframe2",false,function(  )
        flyNode:removeFromParent()

        if _func then
            _func()
        end

    end)
  
end


function GamePusherMainUI:playCollectJpCoinsAnim( _func )

    local endNode =  self.m_propView:getPropIconNode("jackpot")
    local endPos = util_convertToNodeSpace(endNode,self)
    local time = 42/60
    local flyNode = util_createAnimation(Config.UICsbPath.JpCollectAniCsb)
    self:addChild(flyNode,Config.MainUIZorder.ViewLayer)
    flyNode:setPosition(display.width/2,display.height/2)

    local begainID = self.m_propView.m_iAllPropsNum and self.m_propView.m_iAllPropsNum or 0
    local endID = begainID + 1
    local playPropData = {}
    playPropData.nAnimName = "actionframe"..begainID.."_"..endID
    playPropData.nIsLoop = false
    playPropData.nCallFunc = function(  )
        -- self:playPropViewWeakIdle( ) 
    end
    if begainID == 0 then
        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetPropViewVisible,{nVisible = true})
    end
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayPropViewAnim,playPropData)

    
    flyNode:runCsbAction("actionframe")

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        util_playMoveToAction(flyNode,time,endPos)
        performWithDelay(waitNode,function(  )

            local aniLightNode = util_createAnimation(Config.UICsbPath.CollectLightCsb )
            self:addChild(aniLightNode,Config.MainUIZorder.ViewLayer + 1)
            aniLightNode:setPosition(endPos)
            aniLightNode:runCsbAction("actionframe",false,function(  )
                aniLightNode:removeFromParent()
            end)

            if _func then
                _func()
            end

            flyNode:removeFromParent()
            waitNode:removeFromParent()
        end,42/60)
    end,18/60)

end

function GamePusherMainUI:playCollectBoxCoinsAnim( _index,_func )

    
    self.m_pGamePusherMgr:restSendDt()

    local box = self["pgBaoXiang_".._index]
    box:setVisible(false)
    local index = box:getTag()

    if not _index then
        release_print("-------GamePusherMainUI-- _index == nil")
        print("-------GamePusherMainUI-- _index == nil")
    else
        release_print("-------GamePusherMainUI-- _index:".._index)
        print("-------GamePusherMainUI-- _index:".._index)
    end
    
    local starPos = util_convertToNodeSpace(box,self)
    local time = 40/60
    local flyNode = util_createAnimation("CoinCircus_baoxiang_" .. _index  .. ".csb")
    self:addChild(flyNode,Config.MainUIZorder.ViewLayer)
    flyNode:setPosition(starPos)
    flyNode:findChild("BitmapFontLabel_3"):setString(box:findChild("BitmapFontLabel_3"):getString())
    

    flyNode:runCsbAction("actionframe")

    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    util_playMoveToAction(flyNode,time,cc.p(display.width/2,display.height/2))
    performWithDelay(waitNode,function(  )

        local flyNode_1 = flyNode
        local waitNode_1 = waitNode
        
        self.m_pGamePusherMgr:restSendDt()

        performWithDelay(waitNode_1,function(  )
            
            self.m_pGamePusherMgr:restSendDt()
            
            gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_OpenBaoXiang".. index .. ".mp3")

            flyNode_1:findChild("Node_Anim"):setVisible(true)
            flyNode_1:findChild("Particle_anim"):resetSystem()

            box:setVisible(true)
            box:runCsbAction("idle",true)

            if _func then
                _func()
            end

            local waitNode_2 = waitNode_1
            local flyNode_2  = flyNode_1
            performWithDelay(waitNode,function(  )
                flyNode_2:removeFromParent()
                waitNode_2:removeFromParent()
            end,185/60)
            

        end,15/60)
        
    end,40/60)


end

function GamePusherMainUI:updateTopUserCoins( )
    local GEMS_LABEL_WIDTH = 100 -- 钻石控件的长度
    local GEMS_DEFAULT_SCALE = 1 -- 钻石控件的缩放

    -- local gemlab = self.m_topCoinsView:findChild("ml_coin_1")
    -- if gemlab then
    --     gemlab:setString(util_getFromatMoneyStr(globalData.userRunData.gemNum))
    --     util_scaleCoinLabGameLayerFromBgWidth(gemlab, GEMS_LABEL_WIDTH, GEMS_DEFAULT_SCALE)
    -- end
end
    
function GamePusherMainUI:onExit()
    if self.m_jumpDoundId then
        gLobalSoundManager:stopAudio(self.m_jumpDoundId)
        self.m_jumpDoundId = nil
    end 
    gLobalNoticManager:removeAllObservers(self)
end



return GamePusherMainUI