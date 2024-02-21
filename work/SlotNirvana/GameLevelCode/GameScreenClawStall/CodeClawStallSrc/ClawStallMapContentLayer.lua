---
--xcyy
--2018年5月23日
--ClawStallMapContentLayer.lua

local ClawStallMapContentLayer = class("ClawStallMapContentLayer",util_require("Levels.BaseLevelDialog"))

local MAX_LEVELS_COUNT      =       4

function ClawStallMapContentLayer:initUI(params)
    self.m_machine = params.machine
    self.m_parentView = params.parent

    --玩家进度标签
    self.m_item_player = util_createAnimation("ClawStall_Map_juese.csb")
    self:addChild(self.m_item_player,1000)
end

function ClawStallMapContentLayer:loadData( )
    self.m_mapList = self.m_machine.m_mapList
    local itemCount = math.floor(#self.m_mapList / MAX_LEVELS_COUNT) 

    local maxMoveLen = 0
    local itemWidth = 0
    self.m_items = {}
    for index = 1,itemCount do
        local item = util_createView("CodeClawStallSrc.ClawStallMapLevelsNode",{index = index,machine = self.m_machine})
        self:addChild(item)
        local size = item:findChild("Panel"):getContentSize()
        item:setPositionX(size.width * (index - 1))
        itemWidth = size.width
        self.m_items[#self.m_items + 1] = item
    end

    maxMoveLen = itemWidth * (itemCount - 1)
    return maxMoveLen
end

function ClawStallMapContentLayer:refreshView( )
    local posIndex = self.m_machine.m_collectProcess.pos or 0
    for k,item in pairs(self.m_items) do
        item:refreshView(posIndex)
    end
end

--[[
    获取玩家位置
]]
function ClawStallMapContentLayer:getPlayerPos(posIndex)
    if posIndex == 0 then
        local pos = util_convertToNodeSpace(self.m_parentView:findChild("Node_start"),self)
        -- self.m_item_player:setPosition(pos)
        return pos,0
    else
        local itemIndex = math.ceil(posIndex / MAX_LEVELS_COUNT)
        local nodeIndex = posIndex % MAX_LEVELS_COUNT
        if nodeIndex == 0 then
            nodeIndex = 4
        end

        local item = self.m_items[itemIndex]
        
        local targetNode = item.m_items[nodeIndex]:findChild("Node_juese")
        local pos = util_convertToNodeSpace(targetNode,self)
        -- self.m_item_player:setPosition(pos)

        local size = item:findChild("Panel"):getContentSize()
        local distance = pos.x - 200
        return pos,distance
    end
end

--[[
    设置玩家位置
]]
function ClawStallMapContentLayer:setPlayerPos(pos,posIndex)
    self.m_item_player:setPosition(pos)
    for k,item in pairs(self.m_items) do
        item:refreshView(posIndex)
    end
end

--[[
    移动玩家位置
]]
function ClawStallMapContentLayer:movePlayer(startIndex,endIndex,func)
    local startPos = self:getPlayerPos(startIndex)
    local endPos = self:getPlayerPos(endIndex)
    self:setPlayerPos(startPos,startIndex)
    self.m_item_player:runAction(cc.Sequence:create({
        cc.DelayTime:create(7 / 60),
        cc.MoveTo:create(12 / 60,endPos),
        cc.CallFunc:create(function ()
            local itemIndex = math.floor((endIndex - 1) / MAX_LEVELS_COUNT) + 1
            local item = self.m_items[itemIndex]
            --显示赢钱
            item:showWinCoinsAni(endIndex,function(  )
                if type(func) == "function" then
                    func()
                end
            end)
        end)
    }))
    self.m_item_player:runCsbAction("switch")
end


return ClawStallMapContentLayer