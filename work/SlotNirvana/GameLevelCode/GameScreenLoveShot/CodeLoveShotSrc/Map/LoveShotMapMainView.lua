---
--xcyy
--2018年5月23日
--LoveShotMapMainView.lua
--fixios0223
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")

local LoveShotMapMainView = class("LoveShotMapMainView",BaseGame )

LoveShotMapMainView.TOWN_QIN = 2
LoveShotMapMainView.TOWN_JIAN = 7
LoveShotMapMainView.TOWN_GEZI = 13
LoveShotMapMainView.TOWN_PALACE = 20

LoveShotMapMainView.TOP_ZORDER = 50

LoveShotMapMainView.BIG_LEVEL_ADD_Y = 44

LoveShotMapMainView.MAX_INDEX = 19 -- 最后一个位置不用创建

LoveShotMapMainView.m_click = false

function LoveShotMapMainView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("LoveShot/BonusGameGame_1.csb")

    self.MAX_INDEX = 19
    self:initLittleUINode( )

    self:addClick(self:findChild("click"))

    self.m_tipaQiuBiTe = util_createAnimation("LoveShot_zhizhen.csb") 
    self:findChild("zhizhen_node"):addChild(self.m_tipaQiuBiTe,1000)
    self.m_tipaQiuBiTe:setVisible(false)
    self.m_tipaQiuBiTe:setPosition(7,98)
    self.m_tipaQiuBiTe:runCsbAction("idleframe",true)



end

function LoveShotMapMainView:sortUiDianZOrder( )
    
    
    for i=1,self.MAX_INDEX do
        local xiaojinbi = self:findChild("xiaojinbi_"..i)
        if xiaojinbi then
            xiaojinbi:setLocalZOrder(i)
        end
    end

    local zhizhen_node = self:findChild("zhizhen_node")
    if zhizhen_node then
        zhizhen_node:setLocalZOrder(self.MAX_INDEX + 1)
    end

    local zhizhen = self:findChild("zhizhen")
    if zhizhen then
        zhizhen:setLocalZOrder(self.MAX_INDEX + 2)
    end

    
end

function LoveShotMapMainView:showMap( _isBonus , _func )

    self:sortUiDianZOrder( )

    self:runCsbAction("idleframe")
   

    self:setVisible(true)
 
    if _isBonus then
        -- bonus触发不允许点击
        self.m_click = true
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            self:sendData() -- 服务器请求消息
            waitNode:removeFromParent()
        end,1)

        
    else
        self.m_click = false
        self:findChild("click"):setVisible(true)
    end
    

    self.m_endCall = _func
end

function LoveShotMapMainView:runPointAni( _node , _name , _loop ,_func )
    if  _node.m_isSpine then
        util_spinePlay(_node,_name,_loop)

        if not _loop then
            util_spineEndCallFunc(_node,_name,_func) 
        end
        
    else
        _node:runCsbAction(_name,_loop,_func,60)
    end
end

function LoveShotMapMainView:updateLittleUINodeAct( _nodePos )
    -- _nodePos 真实有效位置是从位置1开始
    -- node m_jinbi_ 有效位置是从0开始的

    local pointIndex = nil

    for i=1,self.MAX_INDEX do
        local uiIndex = i 
        local node = self["m_jinbi_"..uiIndex]
        self:runPointAni( node , "idleframe"  ) 
        if i <= _nodePos then
            if not node.m_isSpine then

                self:runPointAni( node , "hide" ) 
            end
            
            if i == _nodePos then
                pointIndex = i
            end
        end
    end

    self.m_tipaQiuBiTe:setVisible(true)

    local pos = nil

    if pointIndex then     
        pos = cc.p(self["m_jinbi_"..pointIndex ]:getParent():getPosition())

        if pointIndex == self.TOWN_QIN or pointIndex == self.TOWN_JIAN or pointIndex  == self.TOWN_GEZI then
            pos = cc.p(pos.x,pos.y + self.BIG_LEVEL_ADD_Y )
        end
        
    else
        pos = cc.p(self:findChild("zhizhen"):getPosition())
    end 

    

    self:findChild("zhizhen_node"):setPosition(pos)

end

function LoveShotMapMainView:getCsbName( _index )
    
    local name  = nil
    local isSpine = false

    if _index == self.TOWN_QIN then
        name = "LoveShot_qin" 
        isSpine = true
    elseif _index == self.TOWN_JIAN then
        name = "LoveShot_jian"
        isSpine = true
    elseif _index == self.TOWN_GEZI then
        name = "LoveShot_gezi"
        isSpine = true
    else
        name = "LoveShot_xiaojinbi"
    end

    return name,isSpine

end

function LoveShotMapMainView:initLittleUINode( )
    
    for i = 1,self.MAX_INDEX do

        local uiIndex = i 
        local csbName,isSpine = self:getCsbName( uiIndex)
        local fatherNodeName = "xiaojinbi_" .. uiIndex
        
        if isSpine then
            self["m_jinbi_"..uiIndex] = util_spineCreate(csbName,true,true)
            self["m_jinbi_"..uiIndex].m_isSpine = isSpine
        else
            self["m_jinbi_"..uiIndex] = util_createAnimation(csbName..".csb")
            self["m_jinbi_"..uiIndex].m_isSpine = isSpine
        end
        
        self:findChild(fatherNodeName):addChild(self["m_jinbi_"..uiIndex])

    end
end

function LoveShotMapMainView:onEnter()

    BaseGame.onEnter(self)

end


function LoveShotMapMainView:onExit()
    BaseGame.onExit(self)
end




function LoveShotMapMainView:closeUi( _func )

    self:setVisible(false)
    self.m_tipaQiuBiTe:setVisible(false)

    if _func then
        _func()
    end


end

--默认按钮监听回调
function LoveShotMapMainView:clickFunc(_sender)
    local name = _sender:getName()
    local tag = _sender:getTag()

    if self.m_click  then
        return
    end

    self.m_click = true

    if name ==  "click" then
        
        self:closeUi( function(  )

            self.m_machine:clearCurMusicBg()
            self.m_machine:resetMusicBg(true) 

            self.m_machine:removeSoundHandler() -- 移除监听
            self.m_machine:reelsDownDelaySetMusicBGVolume( ) 

        end  )
    end

end


function LoveShotMapMainView:QiuBiTeJump( _pos,_func)
    
    local time = 0.37
    local actionList = {}
    actionList[#actionList + 1] = cc.JumpTo:create(time,_pos,60,1)
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        if _func then
            _func()
        end
    end)
    local sq = cc.Sequence:create(actionList)
    self:findChild("zhizhen_node"):runAction(sq)
end

function LoveShotMapMainView:beginLittleUiQiuBiTeAct(_nodePos,_func )

    self.m_tipaQiuBiTe:setVisible(true)
    local endPos = cc.p(self:findChild("xiaojinbi_" .. _nodePos):getPosition())
    if _nodePos == self.TOWN_QIN or _nodePos == self.TOWN_JIAN or _nodePos  == self.TOWN_GEZI then
        endPos = cc.p(endPos.x,endPos.y + self.BIG_LEVEL_ADD_Y )
    end

    self:QiuBiTeJump( endPos,function(  )
        if _func then
            _func()
        end
    end)
end


--[[
    +++++++++++++
    触发游戏时向服务器请求数据 
]]

--数据发送
function LoveShotMapMainView:sendData()

    
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        messageData={msg=MessageDataType.MSG_BONUS_COLLECT , data= self.m_collectDataList}
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)

end

function LoveShotMapMainView:checkBigLevel(_index )
    local curPos = _index 
    if curPos == self.TOWN_QIN then
        return true
    elseif curPos == self.TOWN_JIAN then
        return true
    elseif curPos == self.TOWN_GEZI then
        return true
    elseif curPos == self.TOWN_PALACE then
        return true
    end

    return false
end

--数据接收 只用作一进bonus向服务器请求最终数据
function LoveShotMapMainView:recvBaseData(featureData)

    self.m_action = self.ACTION_RECV

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local cellTable = selfdata.cellTable
    local bonusPosition = self.m_machine.m_bonusPosition or 0
    if bonusPosition == 0 and cellTable and #cellTable > 0 then
        -- 说明是地图最后一次的收集 
        bonusPosition = 20
    end
    self:beginLittleUiQiuBiTeAct(bonusPosition,function(  )
        
        local bigLevel = self:checkBigLevel(bonusPosition )

        if bigLevel then

            local enterClickMain = function(  )
                 -- 大关触发 宫殿点击玩法
                 self.m_machine:showBonusClickGameGuoChang(function(  )

                    self:closeUi(  )

                    self.m_machine:triggerBonusClickGame( )
                end,nil,function()

                end)
            end
            
            if bonusPosition == 20 then

                gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_BigLevel_Trigger.mp3")

                self:runCsbAction("actionframe",false,function(  )
                        
                    enterClickMain()
                        
                end,60)

            else
                
                enterClickMain()

            end

            

        else

            gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_XiaoGuanYingQian.mp3")

            -- 小关直接赢钱
            performWithDelay(self,function(  )

                self:closeUi( function(  )
                    
                    self.m_machine:clearCurMusicBg()
                    self.m_machine:resetMusicBg(true)

                    self.m_machine:removeSoundHandler() -- 移除监听
                    self.m_machine:reelsDownDelaySetMusicBGVolume( ) 
 

                    if self.m_machine.m_BonusGameOverCall then
                        self.m_machine.m_BonusGameOverCall()
                    end
                end )

            end,2)
            

        end

        if bonusPosition ~= 20 then

            
            local fatherNode= self:findChild("xiaojinbi_" .. bonusPosition)
            if fatherNode then

                fatherNode:setLocalZOrder(self.TOP_ZORDER)
                
            end

            local node = self["m_jinbi_"..bonusPosition]

            if not (bonusPosition == self.TOWN_QIN or bonusPosition == self.TOWN_JIAN or bonusPosition  == self.TOWN_GEZI)  then
                
                local lab = node:findChild("m_lb_coins")
                if lab then
                    lab:setString(util_formatCoins(self.m_serverWinCoins,3))
                end 
            end
        
            
            self:runPointAni( node , "actionframe",false) 
        end
        

    end )
   
end


function LoveShotMapMainView:checkIsOver( )
    local bonusStatus = self.p_status 

    if bonusStatus == "CLOSED" then
        return true
    end

    return false
    
end

--开始结束流程
function LoveShotMapMainView:gameOver(isContinue)

end

--弹出结算奖励
function LoveShotMapMainView:showReward()

   
end


function LoveShotMapMainView:featureResultCallFun(param)

    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            if DEBUG == 2 then
                print("=========" .. cjson.encode(spinData.result) )
            end
            
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_totleWimnCoins = spinData.result.winAmount
            -- print("赢取的总钱数为=" .. self.m_totleWimnCoins)
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
    
            if spinData.action == "FEATURE" then

                self.m_featureData:parseFeatureData(spinData.result)
                self.m_spinDataResult = spinData.result
    
                self.m_machine:SpinResultParseResultData( spinData)
                self:recvBaseData(self.m_featureData)
    
            end
        else
            -- 处理消息请求错误情况
    
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
    
        end
    end
    
end

return LoveShotMapMainView