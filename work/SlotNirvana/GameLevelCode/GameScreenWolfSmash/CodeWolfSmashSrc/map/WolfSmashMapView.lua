---
--xcyy
--2018年5月23日
--WolfSmashMapView.lua

--将地图上的27个节点分成三个组，对应三个移动位置，
local WolfSmashMapView = class("WolfSmashMapView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"

local numForMap = 10

local MOVE_DIS = -688

local TOTAL_DIS = -5794

local vertical_pos = -90
local verticalList = {11,12,13,25,26,27,28,38,39,40,41,52,53,54,55,56,66,67,68,69,80,81,82}
local downList = {4,5,6,7,16,17,18,19,20,21,32,33,34,35,44,45,46,47,48,49,60,61,62,63,72,73,74,75,76,77}

--上限为80
local MAP_SHOW_NUM = {
    10,
    18,
    26,
    35,
    45,
    53,
    61,
    71,
    80
}


function WolfSmashMapView:initUI(machine)

    self:createCsbNode("WolfSmash/DiTu.csb")

    self.pigNumForMap = 0           --地图上猪的数量
    self.m_machine = machine

    self.pigList = {}
    self.smashPigList = {}

    local firstPoint = util_createAnimation("WolfSmash_dituqidian.csb")
    self:findChild("Node_dituqidian"):addChild(firstPoint)

    self.m_wolfTips = util_createView("CodeWolfSmashSrc.map.WolfSmashWolfTipsView")
    self:findChild("Node_lang"):addChild(self.m_wolfTips)
    self.m_wolfTips.isChangeParent = false
    
    local panelLeft = util_convertToNodeSpace(self.m_machine:findChild("Node_leftTips"),self)
    local panelRight = util_convertToNodeSpace(self.m_machine:findChild("Node_rightTips"),self)
    self.panelDis = panelRight.x - panelLeft.x

    self.wolfPosIndex = 1               --狼头下标

    self.isMoveForVertical = false      --地图是否上下移动
    self.isMapMove = false              --增加小猪是否移动地图
    self.isMapMoveForUd = false
    self.updateMoveDis = 0            --增加小猪移动距离
    self.isMoveMapWithWolf = false      --地图是否跟随狼头移动
    self.isOneMoveMap = false

    --地图跟随狼头移动
    -- self.wolfPosForMapPos = 0
end

function WolfSmashMapView:setMachine(machine)
    self.m_machine = machine
end

--初始化狼头位置
function WolfSmashMapView:initWolfPos(curPos)
    self.m_wolfTips.isChangeParent = false
    if self:isVerticalMove(curPos) then
        if self.isMoveForVertical then

        else
            
            self.isMoveForVertical = true
            local posX = self:getPositionX()
            local posY = self:getPositionY()
            self:setPosition(cc.p(posX, posY + vertical_pos))
        end
    else
        if self.isMoveForVertical then
            self.isMoveForVertical = false
            local posX = self:getPositionX()
            local posY = self:getPositionY()
            self:setPosition(cc.p(posX, posY - vertical_pos))
        end
    end

    if curPos >= 7 and curPos <= 80 then
        if self.isMoveMapWithWolf then
            self:changeMapPos(6,curPos,false)
        end
        
    end
    
    local pos = util_convertToNodeSpace(self:findChild("Node_L"..curPos),self:findChild("Node_lang"))
    
    self.m_wolfTips:setPosition(pos)
    self.m_wolfTips:initPointPos(curPos)
    self:changeWolfTipsParent(curPos)
    self.wolfPosIndex = curPos
end

function WolfSmashMapView:resetWolfPosForPortrait(curPos)
    local pos = util_convertToNodeSpace(self:findChild("Node_L"..curPos),self:findChild("Node_lang"))
    self.m_wolfTips:setPosition(cc.p(pos.y,pos.x))
    self.m_wolfTips:initPointPos(curPos)
    self.wolfPosIndex = curPos
end

function WolfSmashMapView:changeWolfTipsParent(curPos)
    if self:isVerticalMove(curPos) then
        --提层
        if not self.m_wolfTips.isChangeParent then
            local wolfPos = util_convertToNodeSpace(self.m_wolfTips, self.m_machine.m_effectNode)
            util_changeNodeParent(self.m_machine.m_effectNode, self.m_wolfTips, 12)
            self.m_wolfTips:setPosition(wolfPos)
            self.m_wolfTips.isChangeParent = true
        else
            local pos = util_convertToNodeSpace(self:findChild("Node_L"..curPos),self:findChild("Node_lang"))
            util_changeNodeParent(self:findChild("Node_lang"), self.m_wolfTips)
            self.m_wolfTips:setPosition(pos)
            self.m_wolfTips.isChangeParent = false
        end
    else
        if self.m_wolfTips.isChangeParent then
            local pos = util_convertToNodeSpace(self:findChild("Node_L"..curPos),self:findChild("Node_lang"))
            util_changeNodeParent(self:findChild("Node_lang"), self.m_wolfTips)
            self.m_wolfTips:setPosition(pos)
            self.m_wolfTips.isChangeParent = false
        end
        
    end
end

function WolfSmashMapView:resetWolfTipsParent()
    if self.m_wolfTips.isChangeParent then
        local pos = util_convertToNodeSpace(self:findChild("Node_L"..self.wolfPosIndex),self:findChild("Node_lang"))
        util_changeNodeParent(self:findChild("Node_lang"), self.m_wolfTips)
        self.m_wolfTips:setPosition(pos)
        self.m_wolfTips.isChangeParent = false
    end
end

--改变狼头位置
function WolfSmashMapView:changeWolfPos(oldPos,newPos)
    local time = 0
    --判断地图是否上下移动
    if self:isVerticalMove(newPos) then
        if self.isMoveForVertical then

        else
            self.isMoveForVertical = true
            local posX = self:getPositionX()
            local posY = self:getPositionY()
            self:runAction(cc.MoveTo:create(0.2, cc.p(posX, posY + vertical_pos)))
        end
    else
        if self.isMoveForVertical then
            self.isMoveForVertical = false
            local posX = self:getPositionX()
            local posY = self:getPositionY()
            self:runAction(cc.MoveTo:create(0.1, cc.p(posX, posY - vertical_pos)))
        end
    end
    if newPos >= 7 and newPos <= 80 then
        if self.isMoveMapWithWolf then
            self:changeMapPos(oldPos,newPos,true)
        end
        
    end
    local pos = util_convertToNodeSpace(self:findChild("Node_L"..newPos),self:findChild("Node_lang"))
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_wolf_move)
    self:changeWolfTipsParent(self.wolfPosIndex)
    self.m_wolfTips:changePointPos(oldPos,newPos)
    local move = cc.MoveTo:create(0.2, pos)
    self.m_wolfTips:runAction(move)
    self.wolfPosIndex = newPos
    
    self:showPigIdeleFrame(newPos)
end

--改变地图位置（狼头移动  地图跟随）
function WolfSmashMapView:changeMapPos(index1,index2,isMove)
    local curWolfPos = util_convertToNodeSpace(self:findChild("Node_P"..index1),self)
    local moveWolfPos = util_convertToNodeSpace(self:findChild("Node_P"..index2),self)
    local moveMapDis = moveWolfPos.x - curWolfPos.x
    -- self.wolfPosForMapPos = self.wolfPosForMapPos + moveMapDis
    local posX = self:getPositionX()
    local posY = self:getPositionY()
    local moveDis = posX - moveMapDis
    if moveDis < TOTAL_DIS then
        moveDis = TOTAL_DIS
    end
    if isMove then
        self:runAction(cc.MoveTo:create(0.8, cc.p(moveDis, posY)))
        self:delayCallBack(0.8,function ()
            self:changeWolfTipsParent(self.wolfPosIndex)
        end)
    else
        self:setPosition(cc.p(moveDis, posY))
    end
    
end

--增加小猪是否移动地图
function WolfSmashMapView:isMoveMap(num)
    
    local pigPos = util_convertToNodeSpace(self:findChild("Node_P"..num),self)
    local rightPos = util_convertToNodeSpace(self.m_machine:findChild("Node_rightTips"),self)
    --
    if (pigPos.x - rightPos.x) > 0 or (rightPos.x - pigPos.x) < 40 then
        local among = self.m_machine:findChild("Node_among")
        local endPos = util_convertToNodeSpace(among,self)
        local curPigPos = util_convertToNodeSpace(self:findChild("Node_P"..self.wolfPosIndex),self)
        self.addMove = curPigPos.x - endPos.x
        if num == 11 and self.wolfPosIndex >= 7 then
            self.isOneMoveMap = true
        end
        return true
    end
    return false
end

--获取增加小猪时移动距离
function WolfSmashMapView:getMovePosDis(num)
    local num = num - 1
    local pigPos = util_convertToNodeSpace(self:findChild("Node_P"..num),self)
    local leftPos = util_convertToNodeSpace(self.m_machine:findChild("Node_leftTips"),self)
    local dis = pigPos.x - leftPos.x - 140
    return dis
end

function WolfSmashMapView:updateVerticalMove(isReset)
    local posX = self:getPositionX()
    local posY = self:getPositionY()
    if isReset then
        self.isMoveForVertical = true
        self.isMapMoveForUd = false
        self:runAction(cc.MoveTo:create(0.4, cc.p(posX, posY + vertical_pos)))
        self:delayCallBack(0.4,function ()
            self:changeWolfTipsParent(self.wolfPosIndex)
        end)
    else
        self.isMoveForVertical = false
        self.isMapMoveForUd = true
        self:changeWolfTipsParent(self.wolfPosIndex)
        self:runAction(cc.MoveTo:create(0.8, cc.p(posX, posY - vertical_pos)))
    end
    
end

--增加小猪时更新地图位置
function WolfSmashMapView:updateMapPos(num)

    local dis = self:getMovePosDis(num)
    local posX = self:getPositionX()
    local posY = self:getPositionY()
    if self.isMoveForVertical then
        posY = posY - vertical_pos
    end
    local moveDis = posX - dis
    self.updateMoveDis =  self.updateMoveDis + dis
    if moveDis < TOTAL_DIS then
        moveDis = TOTAL_DIS
    end
    self.isMapMove = true
    if self.m_wolfTips.isChangeParent then
        self:changeWolfTipsParent(self.wolfPosIndex)
    end
    
    self:runAction(cc.MoveTo:create(0.8, cc.p(moveDis, posY)))

end

--移动地图后是否移动回来
function WolfSmashMapView:isResetMapPos()
    return self.isMapMove
end

function WolfSmashMapView:isResetMapPosForUd()
    return self.isMapMoveForUd
end

--移动地图后，移回地图
function WolfSmashMapView:resetMapPos()
    local posX = self:getPositionX()
    local posY = self:getPositionY()
    local moveDis = posX
    local m_updateMoveDis = 0
    if self:isVerticalMove(self.wolfPosIndex) then
        self.isMoveForVertical = true
        posY = posY + vertical_pos
    end
    if self.updateMoveDis == nil then
        self.updateMoveDis = 0
    end
    if self.isOneMoveMap then
        self.isOneMoveMap = false
        
        m_updateMoveDis = self.updateMoveDis - self.addMove
    else
        m_updateMoveDis = self.updateMoveDis
    end
    

    moveDis = posX + m_updateMoveDis
    
    if moveDis > 0 then
        moveDis = 0
    end
    self.isMapMove = false
    self:runAction(cc.MoveTo:create(0.4, cc.p(moveDis, posY)))
    self:delayCallBack(0.4,function ()
        self.updateMoveDis = 0
        self:changeWolfTipsParent(self.wolfPosIndex)
    end)
end

--改变创建的成倍显示
function WolfSmashMapView:changeChengBeiShow(coinsView,multiple)
    local curChild = {
        "Node_X2",
        "Node_X3",
        "Node_X5",
        "Node_X10",
    }
    for i,v in ipairs(curChild) do
        coinsView:findChild(v):setVisible(false)
    end
    if multiple == 2 then
        coinsView:findChild(curChild[1]):setVisible(true)
    elseif multiple == 3 then
        coinsView:findChild(curChild[2]):setVisible(true)
    elseif multiple == 5 then
        coinsView:findChild(curChild[3]):setVisible(true)
    elseif multiple == 10 then
        coinsView:findChild(curChild[4]):setVisible(true)
    end
end

--根据成倍获取小猪
function WolfSmashMapView:getPigMultiple(multiple)
    local pigSpine = util_spineCreate("Socre_WolfSmash_Bonus",true,true)
    if multiple == 10 then
        pigSpine:setSkin("gold")
    else
        pigSpine:setSkin("red")
    end
    local cocosName = "WolfSmash_chengbei.csb"
    local coinsView = util_createAnimation(cocosName)
    self:changeChengBeiShow(coinsView,multiple)
    util_spinePushBindNode(pigSpine,"cb",coinsView)
    util_spinePlay(pigSpine, "idleframe2_2", true)
    coinsView:runCsbAction("idle")
    pigSpine.coinsView = coinsView
    pigSpine.multiple = multiple
    return pigSpine
end

--进入地图时创建小猪
function WolfSmashMapView:initCreatePigForMap(selectList)
    if selectList then
        local multiple = clone(selectList)
        for i,v in ipairs(multiple) do
            if i <= 80 then     --设计上限是80，大于80的数据就不创建了
                local pigItem = self:getPigMultiple(tonumber(v))
                self.pigNumForMap = self.pigNumForMap + 1
                pigItem.index = i
                self.pigList[#self.pigList + 1] = pigItem
                self:findChild("Node_P"..i):addChild(pigItem)
            end
            
        end
    end
    if self.pigNumForMap > 10 then
        self.isMoveMapWithWolf = true
    end
    self:showPigIdeleFrame(1)
end

--有小猪增加时创建小猪
function WolfSmashMapView:createNewPigForMap(index,multiple)

    local pigItem = self:getPigMultiple(tonumber(multiple))
    self.pigNumForMap = self.pigNumForMap + 1
    pigItem.index = index
    self.pigList[#self.pigList + 1] = pigItem
    self:findChild("Node_P"..index):addChild(pigItem)
    util_spinePlay(pigItem, "start", false)
    util_spineEndCallFunc(pigItem, "start", function()
        util_spinePlay(pigItem, "idleframe2_2", true)
    end)
    if self.pigNumForMap > 10 then
        self.isMoveMapWithWolf = true
    end
end

--获取猪节点的名字
function WolfSmashMapView:getEndNode(index)
    return self:findChild("Node_P"..index)
end

----对应猪播动画
function WolfSmashMapView:showPigIdeleFrame(index)
    local pig = self.pigList[index]
    if pig then
        util_spinePlay(pig, "idleframe2_4", true)
    end
end

--是否上下移动
function WolfSmashMapView:isVerticalMove(newPos)
    for i,v in ipairs(verticalList) do
        if v == newPos then
            return true
        end
    end
    return false
end

function WolfSmashMapView:isDownList(newPos)
    for i,v in ipairs(downList) do
        if v == newPos then
            return true
        end
    end
    return false
end

--[[
    @desc: 砸碎小猪相关
    author:{author}
    time:2023-02-09 12:03:14
    --@multiple: 
    @return:
]]
--根据成倍获取砸碎小猪
function WolfSmashMapView:getSmashPigMultiple(multiple)
    local smashPigSpine = util_spineCreate("Socre_WolfSmash_zkz",true,true)
    if multiple == 10 then
        smashPigSpine:setSkin("gold")
    else
        smashPigSpine:setSkin("red")
    end
    local cocosName = "WolfSmash_chengbei.csb"
    local coinsView = util_createAnimation(cocosName)
    self:changeChengBeiShow(coinsView,multiple)
    util_spinePushBindNode(smashPigSpine,"cb",coinsView)
    coinsView:runCsbAction("idle")
    smashPigSpine.multiple = multiple
    smashPigSpine.coinsView = coinsView
    return smashPigSpine
end

function WolfSmashMapView:getSmashPig(index)
    local smashPig = self.smashPigList[index]
    return smashPig
end

--进入地图时创建砸碎的小猪
function WolfSmashMapView:initSmashPig(index)
    for i = 1, index - 1 do
        local pigItem = self.pigList[i]
        if pigItem then
            util_spinePlay(pigItem, "kb", false)
        end
        local multiple = self:getCurPigMultiple(i)
        --创建砸碎的小猪
        local SmashPig = self:getSmashPigMultiple(multiple)
        self:findChild("Node_P"..i):addChild(SmashPig,100)
        util_spinePlay(SmashPig, "over")
        self.smashPigList[#self.smashPigList + 1] = SmashPig
    end
end

--获取狼头
function WolfSmashMapView:getWolfTips()
    return self.m_wolfTips
end

--根据key值获取小猪
function WolfSmashMapView:getSelectPig(index)
    return self.pigList[index]
end

--展示狼头砸小猪
function WolfSmashMapView:showWolfSmashPig(index)
    local node = cc.Node:create()
    self:addChild(node)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        local pigItem = self.pigList[index]
        if pigItem then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_smash_gold_lighting)
            util_spinePlay(pigItem, "idleframe2_3", false)
        end
    end)
    actList[#actList + 1] = cc.DelayTime:create(15/30)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_wolf_smash_pig)
        self.m_wolfTips:showSmash()
    end)
    actList[#actList + 1] = cc.DelayTime:create(19/30)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        local pigItem = self.pigList[index]
        if pigItem then
            util_spinePlay(pigItem, "kb", false)
        end
        local multiple = self:getCurPigMultiple(index)
        --创建砸碎的小猪
        local SmashPig = self:getSmashPigMultiple(multiple)
        self:findChild("Node_P"..index):addChild(SmashPig,100)
        self.m_machine:changeSmashForSelf(SmashPig)
        util_spinePlay(SmashPig, "jida", false)
        util_spineEndCallFunc(SmashPig, "jida", function()
            util_spinePlay(SmashPig, "idle", true)
        end)
        self.smashPigList[#self.smashPigList + 1] = SmashPig
    end)
    actList[#actList + 1] = cc.DelayTime:create(21/30)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create( actList))
    
end

--改变砸碎的小猪的父节点
function WolfSmashMapView:changeSmashPigParent(index)
    local smashPig = self.smashPigList[index]
    if smashPig then
        util_changeNodeParent(self:findChild("Node_P"..index), smashPig, 1000)
        smashPig:setPosition(cc.p(0,0))
    end
    
end

--砸碎的小猪压暗
function WolfSmashMapView:showSmashPigIdle()
    local pig = self.smashPigList[#self.smashPigList]
    if pig then
        util_spinePlay(pig, "over", false)
    end
    
end

--获取猪的成倍数
function WolfSmashMapView:getCurPigMultiple(index)
    local pigItem = self.pigList[index]
    if pigItem then
        return pigItem.multiple or 2
    end
    return 2
end

--清理所有小猪
function WolfSmashMapView:clearAllPig()
    for i,v in ipairs(self.pigList) do
        if v then
            v:removeFromParent()
        end
        
    end
    self.pigList = {}
end

--清理所有砸碎的小猪
function WolfSmashMapView:clearAllSmashPig()
    for i,v in ipairs(self.smashPigList) do
        if v then
            v:removeFromParent()
        end
    end
    self.smashPigList = {}
end

--重置地图位置
function WolfSmashMapView:resetSelfPos()
    self:setPosition(cc.p(0,0))
end


--[[
    延迟回调
]]
function WolfSmashMapView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end


return WolfSmashMapView