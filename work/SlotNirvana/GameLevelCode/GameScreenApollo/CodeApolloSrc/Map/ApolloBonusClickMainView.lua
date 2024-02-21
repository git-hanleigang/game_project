
local ApolloBonusClickMainView = class("ApolloBonusClickMainView", util_require("base.BaseView") )

ApolloBonusClickMainView.CLICK_DATA_TYPE_CRDIT = "credit" -- 获得钱
ApolloBonusClickMainView.CLICK_DATA_TYPE_ALLWIN = "allwin" -- 赢整行
ApolloBonusClickMainView.CLICK_DATA_TYPE_MULTI = "multi" -- 赢倍数
ApolloBonusClickMainView.CLICK_DATA_TYPE_END = "end" -- 结束

-- 从 底 到 顶 顺序去走  1 -> 5
ApolloBonusClickMainView.GROUP_1 = 1
ApolloBonusClickMainView.GROUP_2 = 2
ApolloBonusClickMainView.GROUP_3 = 3
ApolloBonusClickMainView.GROUP_4 = 4
ApolloBonusClickMainView.GROUP_5 = 5

ApolloBonusClickMainView.CLICK_POS_INDEX_GROUP = {{19,20,21,22,23,24},{14,15,16,17,18},{9,10,11,12,13} ,{4,5,6,7,8}, {0,1,2,3} }

ApolloBonusClickMainView.CLICK_MOVE_IMG_END_POS = {cc.p(0,-232),cc.p(0,-142),cc.p(0,-35),cc.p(0,85),cc.p(0,201)}
ApolloBonusClickMainView.CLICK_PICK_MOVE_IMG_ADD_POSY = 120

ApolloBonusClickMainView.CLICK_MOVE_IMG_END_SCALE = {1.13,1.09,1.03,0.99,0.93}

ApolloBonusClickMainView.MAX_INDEX = 25 -- 0 -> 24

ApolloBonusClickMainView.m_click = false

function ApolloBonusClickMainView:initUI(machine)
    self.m_machine = machine

    self:createCsbNode("Apollo/BonusGameGame_0.csb")

    self.m_preWinCoins = 0

    self.m_winBar = util_createAnimation("Apollo_BonusGame_jiesuan.csb")
    self:findChild("Node_total"):addChild(self.m_winBar)
    self.m_winBar:runCsbAction("idleframe1",true)

    self.m_samllMoveBg = util_createAnimation("BonusGameGame_0_huo.csb")
    self:findChild("move_tipBg_1"):addChild(self.m_samllMoveBg)
    
    self.m_samllMoveJT = util_createAnimation("BonusGameGame_0_jiantou.csb")
    self:findChild("move_tipBg_1"):addChild(self.m_samllMoveJT)

    self.m_pickOne = util_createAnimation("BonusGameGame_0_pickone.csb")
    self:findChild("move_pickOne"):addChild(self.m_pickOne)

    self:runCsbAction("idle",true)

    self:initLittleUINode()

    self:restBonusClickMainView()
end

function ApolloBonusClickMainView:restBonusClickMainView()
    self:findChild("move_tipBg_1"):setScale(self.CLICK_MOVE_IMG_END_SCALE[1])

    self.m_winBar:runCsbAction("idleframe1",true)
    self.m_winBar:findChild("m_lb_coins"):setString("")
    self.m_winBar:findChild("m_lb_num"):setString("X1")

    self.m_jinbiMaxClickedNun = self.GROUP_5
    self.m_jinbiClicked = false
    self.m_jinbiClickedNun = 0

    self:restAllJinBiAnim()

    self:findChild("move_pickOne"):setVisible(false)

    self.m_samllMoveBg:playAction("start",false,function ()
        self.m_samllMoveBg:playAction("idleframe",true)
    end)

    self.m_samllMoveJT:playAction("start",false,function ()
        self.m_samllMoveJT:playAction("idleframe",true)
    end)

    local currGroupId = self.m_jinbiClickedNun + 1
    self:setGroupAnimStates(currGroupId,true )
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
        self:findChild("move_pickOne"):setVisible(true)
        self:setMoveImgPos(0.1,self.GROUP_1)
        self.m_pickOne:playAction("start",false,function ()
            self:setGroupClickStates(currGroupId ,true)
        end)
    end)
end

function ApolloBonusClickMainView:showBonusClickMainView(_overfunc)
    self:setVisible(true)
    self:restBonusClickMainView()
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local avgBet = selfdata.avgBet or 1
    self:updateWinCoins(avgBet)
    self.m_endCall = _overfunc
end

function ApolloBonusClickMainView:hideBonusClickMainView()
    self.m_machine:showMapGuoChang(function ()
        self.m_machine:resetMusicBg(true)
        self.m_machine:removeSoundHandler() -- 移除监听
        self.m_machine:reelsDownDelaySetMusicBGVolume()
        self:setVisible(false)
        -- 最后一次点击结束玩法
        if self.m_endCall then
            self.m_endCall()
        end
    end)
end

function ApolloBonusClickMainView:onEnter()

end


function ApolloBonusClickMainView:onExit()

end

function ApolloBonusClickMainView:setMoveImgPos(_time,_groupIndex ,_overfunc)
    local endPos = self.CLICK_MOVE_IMG_END_POS[_groupIndex]
    util_playScaleToAction(self:findChild("move_tipBg_1"), _time , self.CLICK_MOVE_IMG_END_SCALE[_groupIndex])
    util_playMoveToAction(self:findChild("move_tipBg"), _time , endPos,function()
        if _overfunc then
            _overfunc()
        end
    end)

    if _groupIndex >= self.GROUP_5 then
        self:findChild("move_pickOne"):setVisible(false)
    else
        self:findChild("move_pickOne"):setVisible(true)
        util_playMoveToAction(self:findChild("move_pickOne"), _time , cc.p(endPos.x,endPos.y + self.CLICK_PICK_MOVE_IMG_ADD_POSY))
    end
end

function ApolloBonusClickMainView:updateMultiple(_multile)
    if  _multile <= 0 then
        _multile = 1
    end
    self.m_winBar:findChild("m_lb_num"):setString(_multile.."X")
end

--[[
    ***************************
    处理小金币点击
--]]

function ApolloBonusClickMainView:restAllJinBiAnim()
    for i=1,self.MAX_INDEX do
        local uiIndex = i - 1
        local jinbi = self["jinbi_"..uiIndex]
        jinbi:runCsbAction("darkidle")
        jinbi:findChild("click"):setVisible(false)
    end
end

function ApolloBonusClickMainView:createJinbiNode(_celltype,uiIndex )
    if self["jinbi_"..uiIndex] then
        self["jinbi_"..uiIndex]:removeFromParent()
        self["jinbi_"..uiIndex] = nil
    end

    local fatherNodeName = "jinbi_" .. uiIndex
    local csbName = self:getJinBiCsbName( _celltype )
    self["jinbi_"..uiIndex] = util_createAnimation(csbName..".csb")
    self["jinbi_"..uiIndex]:findChild("click"):addTouchEventListener(handler(self, self.jinBiClick))
    self["jinbi_"..uiIndex]:findChild("click"):setTag( uiIndex )
    self:findChild(fatherNodeName):addChild(self["jinbi_"..uiIndex])
end

function ApolloBonusClickMainView:initLittleUINode()
    for i=1,self.MAX_INDEX do
        local uiIndex = i - 1
        self:createJinbiNode(nil,uiIndex )
    end
end

function ApolloBonusClickMainView:setGroupClickStates(_groupId,_states)
    local group = self.CLICK_POS_INDEX_GROUP[_groupId]
    for i = 1,#group do
        local uiPosIndex = group[i]
        local Jinbi = self["jinbi_"..uiPosIndex]
        Jinbi:findChild("click"):setVisible(_states)
    end
end

function ApolloBonusClickMainView:setGroupAnimStates(_groupId,_states ,_index)
    local group = self.CLICK_POS_INDEX_GROUP[_groupId]
    for i = 1,#group do
        local uiPosIndex = group[i]
        if _index then
            if uiPosIndex ~= _index then
                local Jinbi = self["jinbi_"..uiPosIndex]
                if _states then
                    Jinbi:runCsbAction("idleframe",true)
                else
                    Jinbi:runCsbAction("darkidle")
                end
            end
        else
            local Jinbi = self["jinbi_"..uiPosIndex]
            if _states then
                Jinbi:runCsbAction("idleframe",true)
            else
                Jinbi:runCsbAction("darkidle")
            end
        end
    end
end

function ApolloBonusClickMainView:getJinBiCsbName(_celltype)
    if _celltype == self.CLICK_DATA_TYPE_CRDIT then
        return "Apollo_BonusGame_jinbi_Coins"
    elseif _celltype == self.CLICK_DATA_TYPE_ALLWIN then
        return "Apollo_BonusGame_jinbi_WinAll"
    elseif _celltype == self.CLICK_DATA_TYPE_MULTI then
        return "Apollo_BonusGame_jinbi_Coins"
    elseif _celltype == self.CLICK_DATA_TYPE_END then
        return "Apollo_BonusGame_jinbi_End"
    else
        return "Apollo_BonusGame_jinbi_Coins"
    end
end

function ApolloBonusClickMainView:getJinbiAnimName( _celltype )
    if _celltype == self.CLICK_DATA_TYPE_CRDIT then
        return "actionframe"
    elseif _celltype == self.CLICK_DATA_TYPE_ALLWIN then
        return "actionframe"
    elseif _celltype == self.CLICK_DATA_TYPE_MULTI then
        return "actionframe"
    elseif _celltype == self.CLICK_DATA_TYPE_END then
        return "actionframe"
    end
end

function ApolloBonusClickMainView:getOtherDarkJinbiAnimName( _celltype )
    if _celltype == self.CLICK_DATA_TYPE_CRDIT then
        return "dark1"
    elseif _celltype == self.CLICK_DATA_TYPE_ALLWIN then
        return "dark1"
    elseif _celltype == self.CLICK_DATA_TYPE_MULTI then
        return "dark1"
    elseif _celltype == self.CLICK_DATA_TYPE_END then
        return "dark1"
    end
end

function ApolloBonusClickMainView:setJinbiUiInfo(_jinbiNode,_celltype,_value )
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
        local lab_mul_1 = _jinbiNode:findChild("m_lb_num")
        if lab_mul_1 then
            lab_mul_1:setString(_value.."X")
        end
    elseif _celltype == self.CLICK_DATA_TYPE_END then

    end
end

function ApolloBonusClickMainView:showThisGroupWinAllOtherJinBi(_otherDatas,_currGroupId,_index, _showWinAllOtherFunc )
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
        self:createJinbiNode(otherData.type,uiPosIndex )
        local otherJinbi = self["jinbi_"..uiPosIndex]
        local otherTimeLineName =  self:getJinbiAnimName(otherData.type) or "idleframe"
        if otherData.type == self.CLICK_DATA_TYPE_END then
            otherTimeLineName =  self:getOtherDarkJinbiAnimName(otherData.type) or "darkidle"
        end

        otherJinbi:runCsbAction(otherTimeLineName)
        self:setJinbiUiInfo(otherJinbi,otherData.type,otherData.value )
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        if _showWinAllOtherFunc then
            _showWinAllOtherFunc()
        end
        waitNode:removeFromParent()
    end,30/60)
end

function ApolloBonusClickMainView:showThisGroupOtherJinBi(_otherDatas,_currGroupId,_index, _showOtherfunc )
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
        self:createJinbiNode(otherData.type,uiPosIndex )
        local otherJinbi = self["jinbi_"..uiPosIndex]
        local otherTimeLineName =  self:getOtherDarkJinbiAnimName(otherData.type) or "darkidle"
        otherJinbi:runCsbAction(otherTimeLineName)
        self:setJinbiUiInfo(otherJinbi,otherData.type,otherData.value )
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        if _showOtherfunc then
            _showOtherfunc()
        end
        waitNode:removeFromParent()
    end,30/60)
end

function ApolloBonusClickMainView:jinBiClickFunc(_sender )
    if self.m_jinbiClicked  then
        return
    end

    self.m_jinbiClicked = true
    self.m_jinbiClickedNun = self.m_jinbiClickedNun + 1

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local cellTable = selfdata.cellTable or {}
    local rowPoints = selfdata.rowPoints or {}
    local rowMultiples = selfdata.rowMultiples or {}
    local hitPositions = selfdata.hitPositions or {}
    local bonusWinCoins = self.m_machine.m_serverWinCoins or 0

    local currGroupId = self.m_jinbiClickedNun

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

    self:createJinbiNode(clickData.type,index )

    self:setGroupClickStates( currGroupId ,false )

    local jinbi = self["jinbi_"..index]

    local timeLineName =  self:getJinbiAnimName(clickData.type) or "idleframe"
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_bigLeveljinbiclicked.mp3",false)
    jinbi:runCsbAction(timeLineName)
    self:setJinbiUiInfo(jinbi,clickData.type,clickData.value )

    local clickFunc = function()
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
            performWithDelay(waitNdoe,function ()
                self.m_machine:clearCurMusicBg()
                gLobalSoundManager:playSound("ApolloSounds/music_Apollo_biglevelEnd.mp3")
            end,0.5)
            performWithDelay(waitNdoe,function()
                if bonusWinCoins > 0 then
                    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_biglevelFanBeiZa.mp3")
                    -- 播放翻倍动画
                    self.m_winBar:runCsbAction("actionframe",false,function ()
                        self:jumpWinCoins(self.m_winBar:findChild("m_lb_coins_1"),self.m_preWinCoins,bonusWinCoins)
                        performWithDelay(waitNdoe,function()
                            self:hideBonusClickMainView()
                            waitNdoe:removeFromParent()
                        end,2)
                    end)
                else
                    performWithDelay(waitNdoe,function()
                        self:hideBonusClickMainView()
                        waitNdoe:removeFromParent()
                    end,1)
                end
            end,2)
        else
            performWithDelay(self,function()
                gLobalSoundManager:playSound("ApolloSounds/music_Apollo_biglevelZhizhenshangyi.mp3")
                self:setMoveImgPos(0.5,currGroupId + 1 , function()
                    self:setGroupClickStates(currGroupId + 1,true)
                    self:setGroupAnimStates(currGroupId + 1,true )
                    self.m_jinbiClicked = false
                end )
            end ,0.3)
        end
    end

    local waitNdoe_1 = cc.Node:create()
    self:addChild(waitNdoe_1)
    performWithDelay(waitNdoe_1,function()
        self:setGroupAnimStates(currGroupId,false ,index)
        -- 播放未点击 node的效果
        if clickData.type == self.CLICK_DATA_TYPE_ALLWIN  then
            self:showThisGroupWinAllOtherJinBi(otherDatas,currGroupId,index)
        else
            self:showThisGroupOtherJinBi(otherDatas,currGroupId,index)
        end
        self:setGroupClickStates( currGroupId ,false )
        self:playCollectAni( jinbi , clickData , currGroupId,otherDatas ,index ,function()
            clickFunc()
        end )
    end,60/60)
end

function ApolloBonusClickMainView:playWinCoinsEffect(_startNode,_coinsfunc )
    local endworldPos = self:findChild("Node_Coins"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_Coins"):getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endworldPos))

    local startWorldPos = _startNode:getParent():convertToWorldSpace(cc.p(_startNode:getPosition()))
    local startPos =  self:convertToNodeSpace(cc.p(startWorldPos))
    local time = 0.5
    self:createParticleFly(startPos,endPos,time,function()
        -- self.m_fankui_coins:runCsbAction("jiesuan2")
        if _coinsfunc then
            _coinsfunc()
        end
    end)
end

function ApolloBonusClickMainView:playWinMultiEffect(_startNode,_multifunc )
    
    local endworldPos = self.m_winBar:findChild("m_lb_num"):getParent():convertToWorldSpace(cc.p(self.m_winBar:findChild("m_lb_num"):getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endworldPos))

    local startWorldPos = _startNode:getParent():convertToWorldSpace(cc.p(_startNode:getPosition()))
    local startPos =  self:convertToNodeSpace(cc.p(startWorldPos))
    local time = 0.5
    self:createParticleFly(startPos,endPos,time,function()
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_bigLevelShoujifankui.mp3",false)
        self.m_winBar:runCsbAction("shouji")
        if _multifunc then
            _multifunc()
        end
    end)
end

function ApolloBonusClickMainView:playWinAllEffec(_groupId,_index, _clickData,_otherDatas,_winAllfunc)
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
        local Jinbi = self["jinbi_"..uiPosIndex]
        if _index ~= uiPosIndex then
            local otherData = _otherDatas[i]
            if otherData.type == self.CLICK_DATA_TYPE_CRDIT  then
                self:playWinCoinsEffect(Jinbi,function()

                end )
            elseif otherData.type == self.CLICK_DATA_TYPE_MULTI  then
                self:playWinMultiEffect(Jinbi,function()

                end )
            end
        else
            if _clickData.type == self.CLICK_DATA_TYPE_CRDIT  then
                self:playWinCoinsEffect(Jinbi,function()

                end )
            elseif _clickData.type == self.CLICK_DATA_TYPE_MULTI  then
                self:playWinMultiEffect(Jinbi,function()

                end )
            end
        end
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        if _winAllfunc then
            _winAllfunc()
        end
        waitNode:removeFromParent()
    end,0.5)
end

function ApolloBonusClickMainView:playCollectAni(_startNode , _clickData , _groupId,_otherDatas ,_index,_collectfunc)
    local celltype =  _clickData.type -- 点击信号的类似
    if celltype == self.CLICK_DATA_TYPE_CRDIT then
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_mapBonus_Collect_Coins_Multi.mp3")

        self:playWinCoinsEffect(_startNode,function()

            if _collectfunc then
                _collectfunc()
            end
        end )

    elseif celltype == self.CLICK_DATA_TYPE_ALLWIN then
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_mapBonus_Collect_Coins_Multi.mp3")

        self:playWinAllEffec(_groupId,_index, _clickData,_otherDatas,function()
            if _collectfunc then
                _collectfunc()
            end
        end)

    elseif celltype == self.CLICK_DATA_TYPE_MULTI then
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_mapBonus_Collect_Coins_Multi.mp3")

        self:playWinMultiEffect(_startNode,function()
            if _collectfunc then
                _collectfunc()
            end
        end )

    elseif celltype == self.CLICK_DATA_TYPE_END then
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_mapBonus_Collect_click_End.mp3")
        -- 点到end 直接结束
        self.m_jinbiClickedNun = self.m_jinbiMaxClickedNun

        if _collectfunc then
            _collectfunc()
        end
    end
end

-- 处理点击
function ApolloBonusClickMainView:jinBiClick(_sender,_eventType )
    if _eventType == ccui.TouchEventType.ended then
        local beginPos = _sender:getTouchBeganPosition()
        local endPos = _sender:getTouchEndPosition()
        local offx=math.abs(endPos.x-beginPos.x)
        if offx < 50 and globalData.slotRunData.changeFlag == nil then
            self:jinBiClickFunc(_sender )
        end
    end
end

-- 创建收集飞行粒子
function ApolloBonusClickMainView:createParticleFly(_startPos,_endPos,_time,_flyEndFunc)
    local fly = util_createAnimation( "Apollo_jiesuan_tuowei.csb" )
    self:addChild(fly,1000)

    local angle = util_getAngleByPos(_startPos,_endPos)
    fly:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( _startPos.x - _endPos.x ,2) + math.pow( _startPos.y - _endPos.y,2 ))
    fly:setScaleX(scaleSize / 535 )

    fly:setPosition(cc.p(_startPos))

    fly:runCsbAction("actionframe",false,function()
        fly:stopAllActions()
        fly:removeFromParent()
    end)

    performWithDelay(fly,function ()
        if _flyEndFunc then
            _flyEndFunc()
        end
    end,30/60)
end

function ApolloBonusClickMainView:updateWinCoins(_coins )
    self.m_preWinCoins = _coins
    self.m_winBar:findChild("m_lb_coins"):setString(util_formatCoins((_coins),50))
    self.m_winBar:findChild("m_lb_coins_1"):setString(util_formatCoins((_coins),50))
    self:updateLabelSize({ label = self.m_winBar:findChild("m_lb_coins") , sx = 0.4,sy = 0.4}, 1252 )
    self:updateLabelSize({ label = self.m_winBar:findChild("m_lb_coins_1") , sx = 0.4,sy = 0.4}, 1252 )
end

function ApolloBonusClickMainView:jumpWinCoins(_lab,_startCoins,_endCoins)
    local labNode = _lab
    local addValue = _endCoins / 60
    self.m_soundId = gLobalSoundManager:playSound("ApolloSounds/music_Apollo_JackPotWinCoins.mp3",true)
    util_jumpNum(labNode, _startCoins, _endCoins, addValue, 1 / 60, {30}, nil, nil, function()
        self:updateLabelSize({label = labNode,sx = 0.4,sy = 0.4},1252)
        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end)
end

return ApolloBonusClickMainView