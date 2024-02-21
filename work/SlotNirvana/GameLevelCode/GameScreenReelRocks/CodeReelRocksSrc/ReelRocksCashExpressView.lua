---
--xcyy
--2018年5月23日
--ReelRocksCashExpressView.lua
--cash express玩法
local ReelRocksCashExpressView = class("ReelRocksCashExpressView",util_require("base.BaseView"))

-- local beginPosX = 300
local currPosX = -300
local currPosY = 0


function ReelRocksCashExpressView:initUI()

    self:createCsbNode("ReelRocks/ReelRock_kaiche.csb")
    self.m_TraiNodeList = {}
    self.jackpotCoins = 0
    self.IsOver = false
    -- self.soundId = nil
end

function ReelRocksCashExpressView:onEnter()
 
end

function ReelRocksCashExpressView:onExit()
 
end

function ReelRocksCashExpressView:initTraiNode(data,carType)
    self.IsOver = false
    --服务器给到的火车数据
    local list = data or {}
    self.carNum = #list
    local carType = carType or nil
    local beginPos = self:findChild("Node_kuangche_0"):getPositionX()
    -- local TrainHead = self:createCarForColor(nil,carType)
    -- local posX = beginPos 
    -- TrainHead:setPosition(posX,currPosY)
    -- table.insert(self.m_TraiNodeList,TrainHead)
    
    for i=1,#list do
        local TrainData = list[i]
        local TrainBox = self:createCarForColor( TrainData,carType)
        TrainBox.isOver = false
        local posX = beginPos + (currPosX * i)  
        TrainBox:setPosition(posX,currPosY)
        table.insert(self.m_TraiNodeList,TrainBox)
    end
    -- table.remove( carTypeList,1)
end

--getSlotNodeBySymbolType/pushSlotNodeToPoolBySymobolType
--创建火车
function ReelRocksCashExpressView:createCarForColor( trainData , index)
    local train = util_createAnimation(self:getTrainBoxCsbName( index ))
    -- train:runCsbAction("idleframe",true)
    if trainData == nil then
        train:findChild("m_lb_coins"):setVisible(false)
        train:findChild("ReelRocks_tbmini_10"):setVisible(false)
            -- train:findChild("m_lb_coins"):setString(util_formatCoins(trainData,3))
        train.showJackpot = false
    else
        if index >= 100 then    --金色火车没有jackpot节点
            if self:isShowJackpot(index,trainData) then
                train:findChild("m_lb_coins"):setVisible(false)
                train:findChild("ReelRocks_tbmini_10"):setVisible(true)
                train.showJackpot = true
            else
                train:findChild("ReelRocks_tbmini_10"):setVisible(false)
                train:findChild("m_lb_coins"):setVisible(true)
                train:findChild("m_lb_coins"):setString(util_formatCoins(trainData,3))
                train.showJackpot = false
            end
        else
            train:findChild("m_lb_coins"):setVisible(true)
            train:findChild("m_lb_coins"):setString(util_formatCoins(trainData,3))
            train.showJackpot = false
        end
    end
    self:findChild("pan"):addChild(train)
    return train
end

function ReelRocksCashExpressView:getTrainBoxCsbName(type)
    if type == 101 then
        return "Socre_ReelRocks_CAR_1.csb"
    elseif type == 102 then
        return "Socre_ReelRocks_CAR_2.csb"
    elseif type == 103 then
        return "Socre_ReelRocks_CAR_3.csb"
    elseif type == 104 then
        return "Socre_ReelRocks_CAR_4.csb"
    elseif type == 97 then
        return "Socre_ReelRocks_CAR_5.csb"
    end
end

function ReelRocksCashExpressView:updataCarPos( func )
    local pos = self:findChild("Node_kuangche_1"):getPositionX()
    local moveDis = 10
    if #self.m_TraiNodeList > 0 then
        local removeTrainBox = self.m_TraiNodeList[1]
        if removeTrainBox:getPositionX() >= pos * 3 then  --如果第一个超出边框
            table.remove(self.m_TraiNodeList,1)
            removeTrainBox:removeFromParent()
        end
        for i=1,#self.m_TraiNodeList do
            local car = self.m_TraiNodeList[i]
            local newPosX = car:getPositionX() + moveDis
            if car.isHead then      --是否是头车
                self:playTrainMoveByActOther( car,cc.p(newPosX,currPosY))
            else
                if newPosX >= pos and car.isOver == false then
                    self.curNode = car
                    self:playTrainMoveByAct( car,cc.p(newPosX,currPosY),function (  )
                        if func then
                            func()      --飞车上的钱数并刷新收集
                            car.isOver = true
                        end
                    end)
                else
                    self:playTrainMoveByActOther( car,cc.p(newPosX,currPosY))
                end
            end
            
        end
    end
end

function ReelRocksCashExpressView:getCurNode( )
    return self.curNode
end

function ReelRocksCashExpressView:carRunAct( )
    for i,v in ipairs(self.m_TraiNodeList) do
        local car = self.m_TraiNodeList[i]
        if car.isHead then
            print("111")
        else
            car:runCsbAction("idleframe",true)
            -- self.soundId = gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_carCollectIdle.mp3",true)
        end
        
    end
end

-- function ReelRocksCashExpressView:getSoundId( )
--     return self.soundId
-- end

function ReelRocksCashExpressView:removeAllCar( )
    for i=1,#self.m_TraiNodeList do
        local car = self.m_TraiNodeList[i]
        car:removeFromParent()
    end
    self.m_TraiNodeList = {}
end

function ReelRocksCashExpressView:getIsOver( )
    return self.IsOver
end

function ReelRocksCashExpressView:setIsOver( )
    for i=1,#self.m_TraiNodeList do
        local car = self.m_TraiNodeList[i]
        if car.isOver == false then
            return false
        end
    end
    return true
end

function ReelRocksCashExpressView:playTrainMoveByAct( node,moveDis , func )
    local actList = {}
    node:stopAllActions()
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_carCollectActionframe.mp3")
        node:runCsbAction("actionframe2",false,function(  )
            node:runCsbAction("idleframe",true)
        end)
    end)
    actList[#actList + 1]  = cc.CallFunc:create(function (  )
        node:setPosition(moveDis)
    end )
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        if func then
            func()
        end
    end)
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end

function ReelRocksCashExpressView:playTrainMoveByActOther( node,moveDis)
    local actList = {}
    actList[#actList + 1]  = cc.CallFunc:create(function (  )
        node:setPosition(moveDis)
    end )
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end


--根据车的类型获取jackpot的索引值
function ReelRocksCashExpressView:getCarIndex(carType)
    if carType == 101 then
        return 4
    elseif carType == 102 then
        return 3
    elseif carType == 103 then
        return 2
    elseif carType == 104 then
        return 1
    end
    return nil
end

--判断钱数是否是jackpot
function ReelRocksCashExpressView:isShowJackpot(carType,coins)
    local index = self:getCarIndex(carType)
    if index == nil then
        return false
    end
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local bet = coins/totalBet
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    local poolData = jackpotPools[index]
    local configData = poolData.p_configData
    if configData.p_initMin and configData.p_initMax then
        if bet >= configData.p_initMin and bet <= configData.p_initMax then
            self.jackpotCoins = coins
            return true
        end
    else
        if bet >= configData.p_multiple then
            self.jackpotCoins = coins
            return true
        end
    end
    
    return false
end

function ReelRocksCashExpressView:getIsHaveJackpot()
    return self.jackpotCoins
end

function ReelRocksCashExpressView:setIsHaveJackpot()
    self.jackpotCoins = 0
end

function ReelRocksCashExpressView:insetHeadToList(node)
    local nodeParent = node:getParent()
    node.m_preX = node:getPositionX()
    node.m_preY = node:getPositionY()
    local pos = nodeParent:convertToWorldSpace(cc.p(node.m_preX, node.m_preY))
    pos = self:findChild("pan"):convertToNodeSpace(pos)
    util_changeNodeParent(self:findChild("pan"),node)       --修改父节点
    node:setPosition(pos.x, pos.y)
    node:runCsbAction("idleframe",true)
    table.insert( self.m_TraiNodeList, node)
end

function ReelRocksCashExpressView:setHeadCarPosY(posY)
    self.headPosY = posY + 1
end
return ReelRocksCashExpressView