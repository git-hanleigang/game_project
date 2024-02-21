---
--xcyy
--2018年5月23日
--HouseOfBurgerCollectView.lua

local HouseOfBurgerCollectView = class("HouseOfBurgerCollectView",util_require("base.BaseView"))
local SlotsNode = require "Levels.SlotsNode"

HouseOfBurgerCollectView.m_reelList = nil
HouseOfBurgerCollectView.m_machine = nil
HouseOfBurgerCollectView.m_nodeList = nil
HouseOfBurgerCollectView.m_nodeHeight = 74
HouseOfBurgerCollectView.m_TriggerDropCount = 8
HouseOfBurgerCollectView.m_colNum = 5

-- HouseOfBurger_shouji
function HouseOfBurgerCollectView:initUI(data)
    self.m_machine = data
    self:createCsbNode("HouseOfBurger_shouji1.csb")

    self.m_reelList = {}
    self.m_nodeList = {}
    for i = 1 , self.m_colNum do
        local reel = self:findChild("reel_reel_"..(i-1))
        self.m_reelList[i] = reel
        self.m_nodeList[i] = {}
    end

end

function HouseOfBurgerCollectView:initData(data)
    self.m_burgeData = data
    local tempData = {}
    -- for i=1,#data.oldWilds do
    --     tempData[i] = data.oldWilds[i] + data.spinAddWilds[i] + data.scAddWilds[i] + data.chickenAddWilds[i]
    --     if data.startDrops[i] then
    --         tempData[i] = tempData[i] - self.m_TriggerDropCount/2
    --     end
    --     if data.middleDrops[i] then
    --         tempData[i] = tempData[i] - self.m_TriggerDropCount/2
    --     end
    --     if data.endDrops[i] then
    --         tempData[i] = tempData[i] - self.m_TriggerDropCount/2
    --     end
    -- end
    for i=1,self.m_colNum do
        tempData[i] = data.wilds[i]
    end
    for i=1,self.m_colNum do
        if tempData[i] > 0 then
            for j=1,tempData[i] do
                local tempNode = self.m_machine:getSlotNodeBySymbolType(92)
                local index = #self.m_nodeList[i]
                self.m_reelList[i]:addChild(tempNode)
                self.m_nodeList[i][index+1] = tempNode
                tempNode:runAnim("idleframe",true)
                -- tempNode:setScale(0.25)
                tempNode:setPosition(48,self:getPosy(j))
            end
        end
    end
end
function HouseOfBurgerCollectView:updateTxt()
    for i=1,5 do
        local txt = ""
        txt = "sum"..self.m_burgeData.wilds[i].."\n"
        -- txt = "sum"..self.m_burgeData.wilds[i].."\n"
        -- txt = "sum"..self.m_burgeData.wilds[i].."\n"
        -- txt = "sum"..self.m_burgeData.wilds[i].."\n"

        self:findChild("lbs_"..i):setString(self.m_burgeData.wilds[i])
    end
end
function HouseOfBurgerCollectView:updateData(type,data)
        -- "selfData":{"burgerData":{"drops":[false,false,false,false,true],
    -- "oldReels":[[8,4,3,8,90],[2,6,4,5,5],[4,8,8,2,2],[7,3,7,4,8]],"oldWilds":[0,3,0,0,8],"wilds":[0,3,0,0,4]}}
    -- spinAddWilds，scAddWilds，chickenAddWilds
    ----------------------------初始化数据-----------------------------
    self.m_burgeData = data
    self.m_addData = {}
    self.m_wildData = {}
        -- Type_SpinStart=1,
        -- Type_Spinning=2,
        -- Type_SpinEnd_Scatter=3,
        -- Type_SpinEnd_Bonus=4,
        -- Type_SpinEnd = 5}

    ----开始spin                掉落轮盘
    ----spin中        掉落橱柜   掉落轮盘  结算
    ----overScatter   掉落橱柜
    ----overbonus     掉落橱柜   掉落轮盘  结算

    if type == self.m_machine.DownType.Type_SpinStart then

    elseif type == self.m_machine.DownType.Type_Spinning then
        self.m_addData = data.spinAddWilds
        for i=1,self.m_colNum do
            self.m_wildData[i] = data.oldWilds[i] + data.spinAddWilds[i]
            print(i.."spining-------"..self.m_wildData[i].."---"..data.oldWilds[i].."----"..data.spinAddWilds[i])
            self:reduceDropNode(i,type)
            print(i.."spining1-------"..self.m_wildData[i])
        end
    elseif type == self.m_machine.DownType.Type_SpinEnd_Scatter then
        self.m_addData = data.scAddWilds
        for i=1,self.m_colNum do
            self.m_wildData[i] = data.oldWilds[i] + data.spinAddWilds[i] + data.scAddWilds[i]
            print(i.."spining-------"..self.m_wildData[i]..data.oldWilds[i].."---"..data.spinAddWilds[i].."----"..data.scAddWilds[i])
            self:reduceDropNode(i,type)
            print(i.."spining1-------"..self.m_wildData[i])
        end
    elseif type == self.m_machine.DownType.Type_SpinEnd_Bonus then
        self.m_addData = data.chickenAddWilds
        for i=1,self.m_colNum do
            self.m_wildData[i] = data.oldWilds[i] + data.spinAddWilds[i] + data.scAddWilds[i] + data.chickenAddWilds[i]
            print(i.."spining-------"..self.m_wildData[i]..data.oldWilds[i].."---"..data.spinAddWilds[i].."----"..data.scAddWilds[i])
            self:reduceDropNode(i,type)
            print(i.."spining1-------"..self.m_wildData[i])
        end
    elseif type == self.m_machine.DownType.Type_SpinEnd then

    end
    self:updateTxt()

end

function HouseOfBurgerCollectView:reduceDropNode(index,type)
    -- if self.m_wildData[index] > self.m_TriggerDropCount then
    --     self.m_wildData[index] = self.m_TriggerDropCount
    -- end
    local reduce = self.m_TriggerDropCount/2
    -- startDrops   middleDrops   endDrops  drops
    if type == self.m_machine.DownType.Type_SpinStart then

    elseif type == self.m_machine.DownType.Type_Spinning then
        if self.m_burgeData.startDrops[index] then --下一轮的开始掉落
            self.m_wildData[index] = self.m_wildData[index] - reduce
        end
    elseif type == self.m_machine.DownType.Type_SpinEnd_Scatter then
        if self.m_burgeData.startDrops[index] then
            self.m_wildData[index] = self.m_wildData[index] - reduce
        end
        if self.m_burgeData.middleDrops[index] then
            self.m_wildData[index] = self.m_wildData[index] - reduce
        end
    elseif type == self.m_machine.DownType.Type_SpinEnd_Bonus then
        if self.m_burgeData.startDrops[index] then
            self.m_wildData[index] = self.m_wildData[index] - reduce
        end
        if self.m_burgeData.middleDrops[index] then
            self.m_wildData[index] = self.m_wildData[index] - reduce
        end
    elseif type == self.m_machine.DownType.Type_SpinEnd then

    end
end
--[[
    @desc: 掉落到橱柜
    author:{author}
    time:2019-08-22 11:16:47
    --@callFun:
    @return:
]]
function HouseOfBurgerCollectView:downNodeToCupboard(callFun)
    if self:checkNeedDown() then  -- down wild掉落到橱柜
        self.m_colIndex = 1  -- 列数
        self:addColumnSlotsNode(function()--汉堡掉落橱柜
            if callFun then
                callFun(true)
            end
        end)
    else
        if callFun then
            callFun(false)
        end
    end

end

--[[
    @desc: 满了
    author:{author}
    time:2019-08-22 11:16:47
    --@callFun:
    @return:
]]
function HouseOfBurgerCollectView:dropNodeToBaseWheel(type,callFun)
 --drop 是wild掉落到基础轮盘
    local isDrop = self:checkNeedDrop(type)
    if isDrop then
        if type == self.m_machine.DropType.Type_SpinStart then
            self.m_machine:showMask()
            self:startDropNode(function()
                if callFun then
                    callFun(isDrop,self.m_dropList)
                end
            end)  -- 橱柜掉落到基础轮盘
        elseif type == self.m_machine.DropType.Type_Spinning then
            self.m_machine:showMask()
            self:startDropNode(function()
                if callFun then
                    callFun(isDrop,self.m_dropList)
                end
            end)  -- 橱柜掉落到基础轮盘
        elseif type == self.m_machine.DropType.Type_SpinEnd then
            self:startDropNode(function()
                if callFun then
                    callFun(isDrop,self.m_dropList)
                end
            end)  -- 橱柜掉落到基础轮盘
        end

    else
        if callFun then
            callFun(isDrop)
        end
    end
end


--[[
    @desc: 逐行添加
    author:{author}
    time:2019-08-19 20:49:27
    --@callFun:
    @return:
]]
function HouseOfBurgerCollectView:addColumnSlotsNode(callFun)
    local inner = function()
        if self.m_colIndex <= #self.m_wildData then
            self:addColumnSlotsNode(callFun)
        else
            if callFun then
                callFun()
            end
        end

    end
    self.m_maxRow = self.m_wildData[self.m_colIndex]--该列的最大数
    if #self.m_nodeList[self.m_colIndex] == self.m_maxRow then
        self.m_colIndex = self.m_colIndex + 1
        inner()
    else
        self.m_rowIndex = #self.m_nodeList[self.m_colIndex] + 1--行数
        self:addRowSlotsNode(self.m_colIndex,function()
            inner()
        end)
        self.m_colIndex = self.m_colIndex + 1
    end
end

--[[
    @desc:  每行的列添加
    author:{author}
    time:2019-08-19 20:49:50
    --@col:
	--@callFun:
    @return:
]]
function HouseOfBurgerCollectView:addRowSlotsNode(col,callFun)

    local tempNode = self.m_machine:getSlotNodeBySymbolType(92)
    local index = #self.m_nodeList[col]

    self.m_reelList[col]:addChild(tempNode)
    self.m_nodeList[col][index+1] = tempNode
    tempNode:setPosition(cc.p(48,self:getPosy(index+1)))

    tempNode:runAnim("diaoluo8",false)
    performWithDelay(self,function()
        tempNode:runAnim("idleframe1",true)

        for i=index,-1,1 do
            self.m_nodeList[col][i]:runAnim("yasuo1")
        end
        if self.m_rowIndex <= self.m_maxRow then
            self:addRowSlotsNode(col,callFun)
        else
            if callFun then
                callFun()
            end
        end
    end,13/30)
    -- self:runDownSymbolAction(tempNode,1,cc.p(48,self:getPosy(index+1)+1000),cc.p(48,self:getPosy(index+1)),function()
    --     tempNode:runAnim("idleframe1",false,function()
    --     --     -- tempNode:runAnim("idleframe",true)

    --     end)
    --     if self.m_rowIndex <= self.m_maxRow then
    --         self:addRowSlotsNode(col,callFun)
    --     else
    --         if callFun then
    --             callFun()
    --         end
    --     end
    -- end)
    self.m_rowIndex = self.m_rowIndex+1
end




function HouseOfBurgerCollectView:startDropNode(callFun)
    -- self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    local isCallBack = false
    for i=1,#self.m_dropList do
        if self.m_dropList[i] then
            for j=1,self.m_TriggerDropCount/2 do
                local dropNode = self.m_nodeList[i][j]
                local startPos = cc.p(dropNode:getPosition())
                local endPos = cc.p(dropNode:getPositionX(),dropNode:getPositionY()-336)
                dropNode:runAnim("diaoluo8")
                self:runMoveToAction(dropNode,13/30,startPos,endPos,function()
                    -- dropNode:runAnim("idleframe2")
                    if j == 1 and isCallBack == false then
                        isCallBack = true
                        performWithDelay(self,function()
                            if callFun then
                                callFun()
                            end
                        end,0.5)
                    end
                end)
            end
            for j=self.m_TriggerDropCount/2+1,#self.m_nodeList[i] do
                local dropNode = self.m_nodeList[i][j]
                local startPos = cc.p(dropNode:getPosition())
                local endPos = cc.p(dropNode:getPositionX(),self:getPosy(j-4))
                dropNode:runAnim("diaoluo4")
                self:runMoveToAction(dropNode,13/30,startPos,endPos,function()
                    dropNode:runAnim("idleframe1",true)
                end)
            end
            self:addToDropList(i)

        end
    end

end

function HouseOfBurgerCollectView:runDownSymbolAction(node,flyTime,startPos,endPos,callback)
    local actionList = {}
    local moveto=cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = moveto
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)
    node:runAction(cc.Sequence:create(actionList))
end


function HouseOfBurgerCollectView:runMoveToAction(node,flyTime,startPos,endPos,callback)
    local actionList = {}
    node:setPosition(startPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
    end)
    local moveto=cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = moveto
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)
    node:runAction(cc.Sequence:create(actionList))
end


function HouseOfBurgerCollectView:getPosy(index)
    return (index - 1/2) * self.m_nodeHeight
end


function HouseOfBurgerCollectView:onEnter()


end


function HouseOfBurgerCollectView:onExit()

end

--默认按钮监听回调
function HouseOfBurgerCollectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

-- down wild掉落到橱柜
function HouseOfBurgerCollectView:checkNeedDown()
    local need = false
    for i=1,#self.m_addData do
        if self.m_addData[i] ~= 0 then
            need = true
            break
        end
    end
    return need
end
--drop 是wild掉落到基础轮盘
function HouseOfBurgerCollectView:checkNeedDrop(type)
    if type == self.m_machine.DropType.Type_SpinStart then--上次spin的数据
        self.m_dropList = self.m_burgeData.drops
    elseif type == self.m_machine.DropType.Type_Spinning then--本次spin的数据
        self.m_dropList = self.m_burgeData.middleDrops
    elseif type == self.m_machine.DropType.Type_SpinEnd then
        self.m_dropList = self.m_burgeData.endDrops
    end
    local need = false
    for i=1,#self.m_dropList do
        if self.m_dropList[i] then
            need = true
            break
        end
    end
    return need
end

function HouseOfBurgerCollectView:addToDropList(index)
    if self.m_dropNodeList == nil then
        self.m_dropNodeList = {}
    end
    local temp = self.m_nodeList[index]
    for j=1,self.m_TriggerDropCount/2 do
        self.m_dropNodeList[#self.m_dropNodeList+1] = temp[j]
        temp[j] = temp[j+self.m_TriggerDropCount/2]
        temp[j+self.m_TriggerDropCount/2] = nil
    end
end

function HouseOfBurgerCollectView:clearDropedNode()
    if self.m_dropNodeList then
        for i=1,#self.m_dropNodeList do
            self.m_dropNodeList[i]:removeFromParent()
        end
        self.m_dropNodeList = {}
    end

end

return HouseOfBurgerCollectView