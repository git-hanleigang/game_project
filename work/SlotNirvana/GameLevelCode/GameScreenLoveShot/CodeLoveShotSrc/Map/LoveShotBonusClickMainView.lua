---
--xcyy
--2018年5月23日
--LoveShotBonusClickMainView.lua
--fixios0223
local LoveShotBonusClickMainView = class("LoveShotBonusClickMainView", util_require("base.BaseView") )

    
LoveShotBonusClickMainView.CLICK_DATA_TYPE_CRDIT = "credit" -- 获得钱
LoveShotBonusClickMainView.CLICK_DATA_TYPE_ALLWIN = "allwin" -- 赢整行
LoveShotBonusClickMainView.CLICK_DATA_TYPE_MULTI = "multi" -- 赢倍数
LoveShotBonusClickMainView.CLICK_DATA_TYPE_END = "end" -- 结束

-- 从 底 到 顶 顺序去走  1 -> 5
LoveShotBonusClickMainView.GROUP_1 = 1
LoveShotBonusClickMainView.GROUP_2 = 2
LoveShotBonusClickMainView.GROUP_3 = 3
LoveShotBonusClickMainView.GROUP_4 = 4
LoveShotBonusClickMainView.GROUP_5 = 5

LoveShotBonusClickMainView.CLICK_POS_INDEX_GROUP = {{19,20,21,22,23,24},{14,15,16,17,18} ,{9,10,11,12,13}, {4,5,6,7,8}, {0,1,2,3}} 

-- LoveShotBonusClickMainView.CLICK_MOVE_IMG_END_POS = {cc.p(0,-240),cc.p(0,-100),cc.p(0,40),cc.p(0,175)} 
LoveShotBonusClickMainView.CLICK_MOVE_IMG_END_POS = {cc.p(0,-275), cc.p(0,-165), cc.p(0,-45), cc.p(0,75), cc.p(0,195)} 
LoveShotBonusClickMainView.CLICK_PICK_MOVE_IMG_ADD_POSY = 120

LoveShotBonusClickMainView.CLICK_MOVE_IMG_END_SCALE = {1.15,1.12,1.08,1.02,0.96} 

LoveShotBonusClickMainView.MAX_INDEX = 25 -- 0 -> 24

LoveShotBonusClickMainView.m_click = false
LoveShotBonusClickMainView.m_preWinCoins = nil

function LoveShotBonusClickMainView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("LoveShot/BonusGameGame_0.csb")

    self.m_preWinCoins = 0
    
    self.m_fankui_coins = util_createAnimation("BonusGameGame_ClickFanKui.csb")
    self:findChild("Node_clickFanKui"):addChild(self.m_fankui_coins)
    self.m_fankui_coins:runCsbAction("idleframe")

    self.m_fankui_Mutil = util_createAnimation("BonusGameGame_ClickFanKui.csb")
    self:findChild("Node_clickFanKui"):addChild(self.m_fankui_Mutil)
    self.m_fankui_Mutil:runCsbAction("idleframe")
    
    self:runCsbAction("idle",true)

    self.MAX_INDEX = 25
    self:initLittleUINode( )

    self:restBonusClickMainView( )

    
end

function LoveShotBonusClickMainView:restBonusClickMainView( )
    
    self:findChild("move_tipBg_1"):setScale(self.CLICK_MOVE_IMG_END_SCALE[1])
    
    self.m_fankui_coins:runCsbAction("idleframe")
    self.m_fankui_Mutil:runCsbAction("idleframe")
    self:runCsbAction("idle",true)

    self.m_jinbiMaxClickedNun = self.GROUP_5
    self.m_jinbiClicked = false
    self.m_jinbiClickedNun = 0
    
    self:findChild("m_lb_coins"):setString("")
    self:findChild("m_lb_num"):setString("X1")

    self:restAllJinBiAnim()
    
    self:setMoveImgPos(0.1,self.GROUP_1 )

    self:findChild("move_pickOne"):setVisible(true)

    -- 4 -> 1 由底——>顶
    local currGroupId =  self.m_jinbiClickedNun + 1
    self:setGroupClickStates(currGroupId ,true)
    self:setGroupAnimStates(currGroupId,true )
end

function LoveShotBonusClickMainView:showBonusClickMainView(  _overfunc )

    self:setVisible(true)

    self:restBonusClickMainView( )


    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local avgBet = selfdata.avgBet or 1
    self:updateWinCoins(avgBet )
    
    self.m_endCall = _overfunc
    
end



function LoveShotBonusClickMainView:hideBonusClickMainView( _hidefunc )


    self.m_machine:resetMusicBg(true) 
    
    self.m_machine:removeSoundHandler() -- 移除监听
    self.m_machine:reelsDownDelaySetMusicBGVolume( ) 


    self:setVisible(false)

     -- 最后一次点击结束玩法    
     if self.m_endCall then
        self.m_endCall()
    end
    

    if _hidefunc then
        _hidefunc()
    end

   


end


function LoveShotBonusClickMainView:onEnter()
 

end


function LoveShotBonusClickMainView:onExit()
 
end



function LoveShotBonusClickMainView:setMoveImgPos(_time,_groupIndex ,_overfunc )
    
    local endPos = self.CLICK_MOVE_IMG_END_POS[_groupIndex] 
    
    util_playScaleToAction(self:findChild("move_tipBg_1"), _time , self.CLICK_MOVE_IMG_END_SCALE[_groupIndex])

    util_playMoveToAction(self:findChild("move_tipBg"), _time , endPos,function()
        if _overfunc then
            _overfunc()
        end
    end)

    if _groupIndex >= self.m_jinbiMaxClickedNun then
        self:findChild("move_pickOne"):setVisible(false)
    else
        self:findChild("move_pickOne"):setVisible(true)
        util_playMoveToAction(self:findChild("move_pickOne"), _time , cc.p(endPos.x,endPos.y + self.CLICK_PICK_MOVE_IMG_ADD_POSY))
    end

   

end

function LoveShotBonusClickMainView:updateMultiple(_multile)

    if  _multile <= 0 then
        _multile = 1
    end

    self:findChild("m_lb_num"):setString( "X" .. _multile )
    self:updateLabelSize({ label = self:findChild("m_lb_num") , sx = 1,sy = 1 }, 166 )
end




--[[
    ***************************  
    处理小金币点击
--]]

function LoveShotBonusClickMainView:restAllJinBiAnim( )
    for i=1,self.MAX_INDEX do
        local uiIndex = i - 1
        local jinbi = self["m_jinbi_"..uiIndex] 
        jinbi:runCsbAction("idleframeDark")
        jinbi:findChild("click"):setVisible(false)
    end
end

function LoveShotBonusClickMainView:initLittleUINode( )
    
    for i=1,self.MAX_INDEX do

        local uiIndex = i - 1

        local fatherNodeName = "jinbi_" .. uiIndex
        self["m_jinbi_"..uiIndex] = util_createAnimation("LoveShot_jinbi.csb")
        self["m_jinbi_"..uiIndex]:findChild("click"):addTouchEventListener(handler(self, self.jinBiClick))
        self["m_jinbi_"..uiIndex]:findChild("click"):setTag( uiIndex )
        self:findChild(fatherNodeName):addChild(self["m_jinbi_"..uiIndex])

    end
end

function LoveShotBonusClickMainView:setGroupClickStates(_groupId,_states )

    local group = self.CLICK_POS_INDEX_GROUP[_groupId]
    for i=1,#group do
        local uiPosIndex = group[i]
        local Jinbi = self["m_jinbi_"..uiPosIndex]
        Jinbi:findChild("click"):setVisible(_states)
    end
end

function LoveShotBonusClickMainView:setGroupAnimStates(_groupId,_states ,_index)

    local group = self.CLICK_POS_INDEX_GROUP[_groupId]
    for i=1,#group do
        local uiPosIndex = group[i]
        if _index then
            if uiPosIndex ~= _index then
                local Jinbi = self["m_jinbi_"..uiPosIndex]
                if _states then
                    Jinbi:runCsbAction("idleframe")
                else
                    Jinbi:runCsbAction("idleframeDark")
                end
            end
        else

            local Jinbi = self["m_jinbi_"..uiPosIndex]
            if _states then
                Jinbi:runCsbAction("idleframe")
            else
                Jinbi:runCsbAction("idleframeDark")
            end

        end
        
        
        
    end
end



function LoveShotBonusClickMainView:getJinbiAnimName( _celltype )
    
  
    if _celltype == self.CLICK_DATA_TYPE_CRDIT then
        
        return "actionframe2"
    elseif _celltype == self.CLICK_DATA_TYPE_ALLWIN then
        
        return "actionframe4"
    elseif _celltype == self.CLICK_DATA_TYPE_MULTI then
        return "actionframe1"

    elseif _celltype == self.CLICK_DATA_TYPE_END then
        
        return "actionframe3"
    end

end

function LoveShotBonusClickMainView:getOtherDarkJinbiAnimName( _celltype )
    if _celltype == self.CLICK_DATA_TYPE_CRDIT then
        
        return "dark2"
    elseif _celltype == self.CLICK_DATA_TYPE_ALLWIN then
        return "dark4"

    elseif _celltype == self.CLICK_DATA_TYPE_MULTI then
        return "dark1"

    elseif _celltype == self.CLICK_DATA_TYPE_END then
        
        return "dark3"
    end
end

function LoveShotBonusClickMainView:setJinbiUiInfo(_jinbiNode,_celltype,_value )
    
  
    if _celltype == self.CLICK_DATA_TYPE_CRDIT then

        local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
        local avgBet = selfdata.avgBet or 1

        local lab_coins_1 = _jinbiNode:findChild("m_lb_coins_1")
        if lab_coins_1 then
            lab_coins_1:setString( util_formatCoins((avgBet * _value) , 3) )
        end
        local lab_coins_2 = _jinbiNode:findChild("m_lb_coins_2")
        if lab_coins_2 then
            lab_coins_2:setString(util_formatCoins((avgBet * _value) , 3) )
        end
        
        
    elseif _celltype == self.CLICK_DATA_TYPE_ALLWIN then
        

    elseif _celltype == self.CLICK_DATA_TYPE_MULTI then

        local lab_mul_1 = _jinbiNode:findChild("m_lb_mul_1")
        if lab_mul_1 then
            lab_mul_1:setString("X".._value)
            self:updateLabelSize({ label = lab_mul_1, sx = 1,sy = 1 }, 111)
        end
        local lab_mul_2 = _jinbiNode:findChild("m_lb_mul_2")
        if lab_mul_2 then
            lab_mul_2:setString("X".._value)
            self:updateLabelSize({ label = lab_mul_2, sx = 1,sy = 1 }, 111)
        end

    elseif _celltype == self.CLICK_DATA_TYPE_END then
        

    end
end

function LoveShotBonusClickMainView:showThisGroupWinAllOtherJinBi(_otherDatas,_currGroupId,_index, _showWinAllOtherFunc )
    
    local group = self.CLICK_POS_INDEX_GROUP[_currGroupId]
    
    local currGroup = clone(group)
    for i=1,#currGroup do
        local uiPosIndex = currGroup[i]
        if _index == uiPosIndex then
            table.remove( currGroup, i )
            break
        end
    end

    for i=1,#currGroup do
        local uiPosIndex = currGroup[i]
        local otherData = _otherDatas[i]
        local otherJinbi = self["m_jinbi_"..uiPosIndex]
        local otherTimeLineName =  self:getJinbiAnimName(otherData.type) or "idleframe"
        if otherData.type == self.CLICK_DATA_TYPE_END then
            otherTimeLineName =  self:getOtherDarkJinbiAnimName(otherData.type) or "idleframeDark"
        end

        otherJinbi:runCsbAction(otherTimeLineName)
        self:setJinbiUiInfo(otherJinbi,otherData.type,otherData.value )

        
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        if _showWinAllOtherFunc then
            _showWinAllOtherFunc()
        end
        waitNode:removeFromParent()
    end,30/60)
end

function LoveShotBonusClickMainView:showThisGroupOtherJinBi(_otherDatas,_currGroupId,_index, _showOtherfunc )
    
    local group = self.CLICK_POS_INDEX_GROUP[_currGroupId]
    local currGroup = clone(group)
    for i=1,#currGroup do
        local uiPosIndex = currGroup[i]
        if _index == uiPosIndex then
            table.remove( currGroup, i )
            break
        end
    end
    for i=1,#currGroup do

        local uiPosIndex = currGroup[i]
        local otherData = _otherDatas[i]
        local otherJinbi = self["m_jinbi_"..uiPosIndex]
        local otherTimeLineName =  self:getOtherDarkJinbiAnimName(otherData.type) or "idleframeDark"
        otherJinbi:runCsbAction(otherTimeLineName)
        self:setJinbiUiInfo(otherJinbi,otherData.type,otherData.value )
        
        
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        if _showOtherfunc then
            _showOtherfunc()
        end
        waitNode:removeFromParent()
    end,30/60)
end

function LoveShotBonusClickMainView:jinBiClickFunc(_sender )

    if self.m_jinbiClicked  then
        return
    end

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_mapBonus_click.mp3")

    self.m_jinbiClicked = true
    self.m_jinbiClickedNun = self.m_jinbiClickedNun + 1

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local cellTable = selfdata.cellTable or {}
    local rowPoints = selfdata.rowPoints or {}
    local rowMultiples = selfdata.rowMultiples or {}
    local hitPositions = selfdata.hitPositions or {}
    local bonusWinCoins = self.m_machine.m_serverWinCoins or 0
    

    local currGroupId = self.m_jinbiClickedNun

    self:setGroupClickStates( currGroupId ,false )
    
    local clickDataIndex = hitPositions[currGroupId] + 1
    local currData = cellTable[currGroupId]
    local cloneCurrData = clone(currData)
    local clickData = cloneCurrData[clickDataIndex]
    table.remove(cloneCurrData,clickDataIndex)
    local otherDatas = cloneCurrData
    local clickWinCoins = rowPoints[currGroupId]
    local clickMultipleCoins = rowMultiples[currGroupId]

    -- 播放点击Node的效果
    local index = _sender:getTag()
    local jinbi = self["m_jinbi_"..index] 

    local timeLineName =  self:getJinbiAnimName(clickData.type) or "idleframe"
    jinbi:runCsbAction(timeLineName)
    self:setJinbiUiInfo(jinbi,clickData.type,clickData.value )

    
    

    local clickFunc = function(  )
            local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
            local avgBet = selfdata.avgBet or 1

            if clickData.type == self.CLICK_DATA_TYPE_CRDIT  then
                self:updateWinCoins( clickWinCoins * avgBet )
            elseif clickData.type == self.CLICK_DATA_TYPE_MULTI then
                self:updateMultiple( clickMultipleCoins )
            elseif clickData.type == self.CLICK_DATA_TYPE_ALLWIN  then
                self:updateMultiple( clickMultipleCoins)
                self:updateWinCoins( clickWinCoins * avgBet )
            end
            
            

            if self.m_jinbiClickedNun >= self.m_jinbiMaxClickedNun then
                
                local waitNdoe = cc.Node:create()
                self:addChild(waitNdoe)
                performWithDelay(waitNdoe,function(  )

                    if bonusWinCoins > 0 then

                        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_FanBeiZa.mp3")

                        -- 播放翻倍动画
                        self:runCsbAction("actionframe")

                        performWithDelay(waitNdoe,function(  )

                            self.m_fankui_coins:runCsbAction("jiesuan2")

                            self:jumpWinCoins(self:findChild("m_lb_coins"),self.m_preWinCoins,bonusWinCoins)

                          
                            performWithDelay(waitNdoe,function(  )
                            
                                self:hideBonusClickMainView()

                                waitNdoe:removeFromParent()
                            end,2)

                        end,45/60)
                    else
                        performWithDelay(waitNdoe,function(  )
                            
                            self:hideBonusClickMainView()

                            waitNdoe:removeFromParent()
                        end,1)
                    end

                    

                end,1)


            else

                performWithDelay(self,function(  )

                    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_mapBonus_MoveImg.mp3")

                    self:setMoveImgPos(0.5,currGroupId + 1 , function(  )
    
                        self:setGroupClickStates(currGroupId + 1,true)
                        self:setGroupAnimStates(currGroupId + 1,true )

                        self.m_jinbiClicked = false
    
                    end )

                end ,0.3)


            end
    end


    local waitNdoe_1 = cc.Node:create()
    self:addChild(waitNdoe_1)
    performWithDelay(waitNdoe_1,function(  )

        self:setGroupAnimStates(currGroupId,false ,index)
        -- 播放未点击 node的效果
        if clickData.type == self.CLICK_DATA_TYPE_ALLWIN  then
            self:showThisGroupWinAllOtherJinBi(otherDatas,currGroupId,index)
        else
            self:showThisGroupOtherJinBi(otherDatas,currGroupId,index)
        end


        self:playCollectAni( jinbi , clickData , currGroupId,otherDatas ,index ,function(  )

            clickFunc()

        end )


    end,60/60)

   
end

function LoveShotBonusClickMainView:playWinCoinsEffect(_startNode,_coinsfunc )

   

    local endworldPos = self:findChild("Node_Coins"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_Coins"):getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endworldPos))
    
    local startWorldPos = _startNode:getParent():convertToWorldSpace(cc.p(_startNode:getPosition()))
    local startPos =  self:convertToNodeSpace(cc.p(startWorldPos))
    local time = 0.5
    self:createParticleFly(startPos,endPos,time,function(  )
        
        self.m_fankui_coins:runCsbAction("jiesuan2")

        if _coinsfunc then
            _coinsfunc()
        end

    end)
end

function LoveShotBonusClickMainView:playWinMultiEffect(_startNode,_multifunc )
    local endworldPos = self:findChild("Node_Multiple"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_Multiple"):getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endworldPos))
    
    local startWorldPos = _startNode:getParent():convertToWorldSpace(cc.p(_startNode:getPosition()))
    local startPos =  self:convertToNodeSpace(cc.p(startWorldPos))
    local time = 0.5
    self:createParticleFly(startPos,endPos,time,function(  )

        self.m_fankui_Mutil:runCsbAction("jiesuan1")
        

        if _multifunc then
            _multifunc()
        end

    end)
end

function LoveShotBonusClickMainView:playWinAllEffec(_groupId,_index, _clickData,_otherDatas,_winAllfunc)

    local group = self.CLICK_POS_INDEX_GROUP[_groupId]

    local currGroup = clone(group)
    for i=1,#currGroup do
        local uiPosIndex = currGroup[i]
        if _index == uiPosIndex then
            table.remove( currGroup, i )
            break
        end
    end

    for i=1,#currGroup do
        local uiPosIndex = currGroup[i]
        local Jinbi = self["m_jinbi_"..uiPosIndex]

        if _index ~= uiPosIndex then
            local otherData = _otherDatas[i]
            if otherData.type == self.CLICK_DATA_TYPE_CRDIT  then
               
                self:playWinCoinsEffect(Jinbi,function(  )
                   
                end )
                    
            elseif otherData.type == self.CLICK_DATA_TYPE_MULTI  then
                self:playWinMultiEffect(Jinbi,function(  )
                 
                end )
            end


        else
            if _clickData.type == self.CLICK_DATA_TYPE_CRDIT  then


                self:playWinCoinsEffect(Jinbi,function(  )
   
                end )
            elseif _clickData.type == self.CLICK_DATA_TYPE_MULTI  then
                self:playWinMultiEffect(Jinbi,function(  )
      
                end )
            end
        end
        
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        if _winAllfunc then
            _winAllfunc()
        end
        
        waitNode:removeFromParent()
    end,0.5)
end

function LoveShotBonusClickMainView:playCollectAni(_startNode , _clickData , _groupId,_otherDatas ,_index,_collectfunc)
    
    local celltype =  _clickData.type -- 点击信号的类似


    if celltype == self.CLICK_DATA_TYPE_CRDIT then

        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_mapBonus_Collect_Coins_Multi.mp3")

        self:playWinCoinsEffect(_startNode,function(  )
            
            if _collectfunc then
                _collectfunc()
            end
        end )
           
    elseif celltype == self.CLICK_DATA_TYPE_ALLWIN then
        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_mapBonus_Collect_Coins_Multi.mp3")

        self:playWinAllEffec(_groupId,_index, _clickData,_otherDatas,function(  )
            if _collectfunc then
                _collectfunc()
            end
        end)
       
    elseif celltype == self.CLICK_DATA_TYPE_MULTI then
        
        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_mapBonus_Collect_Coins_Multi.mp3")

        self:playWinMultiEffect(_startNode,function(  )

            
            if _collectfunc then
                _collectfunc()
            end
        end )

    elseif celltype == self.CLICK_DATA_TYPE_END then

        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_mapBonus_Collect_click_End.mp3")

        -- 点到end 直接结束
        self.m_jinbiClickedNun = self.m_jinbiMaxClickedNun

        if _collectfunc then
            _collectfunc()
        end
        
    end

    

end


-- 处理点击
function LoveShotBonusClickMainView:jinBiClick(_sender,_eventType )
    if _eventType == ccui.TouchEventType.ended then

        local beginPos = _sender:getTouchBeganPosition()
        local endPos = _sender:getTouchEndPosition()
        local offx=math.abs(endPos.x-beginPos.x)
        if offx<50 and globalData.slotRunData.changeFlag == nil then
            self:jinBiClickFunc(_sender )
        end
   
    end
end

-- 创建收集飞行粒子
function LoveShotBonusClickMainView:createParticleFly(_startPos,_endPos,_time,_flyEndFunc)

    local fly =  util_createAnimation("Socre_LoveShot_CashRush_Lizi.csb")
    self:addChild(fly,1000)

    fly:findChild("Particle_1"):setDuration(-1)
    fly:findChild("Particle_1"):setPositionType(0)

    fly:findChild("Particle_2"):setDuration(-1)
    fly:findChild("Particle_2"):setPositionType(0)
    
    fly:setPosition(cc.p(_startPos))

    local endPos = _endPos

    local animation = {}
    animation[#animation + 1] = cc.MoveTo:create(_time, cc.p(endPos.x,endPos.y) )
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        fly:findChild("Particle_1"):stopSystem()
        fly:findChild("Particle_2"):stopSystem()

        if _flyEndFunc then
            _flyEndFunc()
        end


    end)
    animation[#animation + 1] = cc.DelayTime:create(1)
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        fly:removeFromParent()

    end)

    fly:runAction(cc.Sequence:create(animation))

    
    
end

function LoveShotBonusClickMainView:updateWinCoins(_coins )
    self.m_preWinCoins = _coins
    self:findChild("m_lb_coins"):setString(util_formatCoins((_coins),50))
    self:updateLabelSize({ label = self:findChild("m_lb_coins") , sx = 1,sy = 1 }, 537 )
end


function LoveShotBonusClickMainView:jumpWinCoins(_lab,_startCoins,_endCoins)
    local labNode = _lab
    local addValue = _endCoins / 60
    util_jumpNum(labNode, _startCoins, _endCoins, addValue, 1 / 60, {30}, nil, nil, function()
        self:updateLabelSize({label=labNode,sx=1,sy=1},537)
    end)
end

return LoveShotBonusClickMainView