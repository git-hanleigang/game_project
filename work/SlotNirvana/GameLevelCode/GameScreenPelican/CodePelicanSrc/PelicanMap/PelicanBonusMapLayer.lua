local PelicanBonusMapLayer = class("PelicanBonusMapLayer", util_require("base.BaseView"))

PelicanBonusMapLayer.JUMPNODE_ADD_POSY = 0

-- 构造函数
function PelicanBonusMapLayer:initUI(data, pos)
    local resourceFilename = "Pelican_Map_bg.csb"
    self:createCsbNode(resourceFilename)
    self.m_nodePanda = cc.Node:create()
    self:addChild(self.m_nodePanda)
    self.m_panda = util_createView("CodePelicanSrc.PelicanMap.PelicanBonusMapPanda")
    self.m_nodePanda:addChild(self.m_panda)

    self.m_vecNodeLevel = {}
    for i = 1, #data, 1 do
        local info = data[i]
        local itemFile = nil
        local item = nil
        local BigLevelInfo = nil
        if info.type == "BIG" then
            
            itemFile = "CodePelicanSrc.PelicanMap.PelicanBonusMapBigLevel"

            BigLevelInfo = {}
            BigLevelInfo.info = info
            BigLevelInfo.currLevel = pos
            BigLevelInfo.selfPos = i
        else
            itemFile = "CodePelicanSrc.PelicanMap.PelicanBonusMapItem"
        end

        item = util_createView(itemFile, BigLevelInfo)
        
        self.m_vecNodeLevel[#self.m_vecNodeLevel + 1] = item
        self:findChild("Node_"..i):addChild(item)
        if info.type == "BIG" then
            item:setPositionY(item:getPositionY())
        end
        if i <= pos then
            item:completed()
        else
            item:idle()
        end
        local indexlab = item:findChild("indexLab")
        if indexlab then
            indexlab:setString(i)
        end
        
    end
    local node = self:findChild("Node_"..pos )
    local endPos = cc.p(util_getConvertNodePos(node,self.m_nodePanda))
    if data[pos] and data[pos].type == "BIG" then
        self.m_nodePanda:setPosition(endPos.x, endPos.y + self.JUMPNODE_ADD_POSY)
    else
        self.m_nodePanda:setPosition(endPos.x, endPos.y)
    end
    if display.height > 1370 then
        self:findChild("Node_zong"):setPositionY(self:changePosY())
    end
end

function PelicanBonusMapLayer:changePosY( )
    local offsetY = (1660 - 1370) / 130
    return (display.height - 1370) / offsetY
end

function PelicanBonusMapLayer:getLevelPosY(pos)

    local WorldPos = self:findChild("Node_"..pos):getParent():convertToWorldSpace(cc.p(self:findChild("Node_"..pos):getPosition()))
    local NodePos = self:convertToNodeSpace(WorldPos)

    return - cc.p(NodePos).y
end

function PelicanBonusMapLayer:pandaMove(callBack, bonusData, pos,LitterGameWin)

    local info = bonusData[pos]
    local node = self:findChild("Node_"..pos)
    local oldNode = self:findChild("Node_"..(pos - 1))
    local startPos = cc.p(util_getConvertNodePos(oldNode,self.m_nodePanda))
    local endPos = cc.p(util_getConvertNodePos(node,self.m_nodePanda))
    local actList = {}
    
    actList[#actList + 1] = cc.DelayTime:create(0.3)

    local nodeMove = self:getNodeMove(pos,startPos,endPos)

    actList[#actList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("PelicanSounds/Pelican_collect_move.mp3")
    end)

    actList[#actList + 1] = nodeMove

    actList[#actList + 1] = cc.CallFunc:create(function()

        self.m_panda:runCsbAction("idle",true)

        self.m_vecNodeLevel[pos]:click(function()

            if callBack ~= nil then

                callBack()

            end
        end,LitterGameWin)

    end)

    self.m_nodePanda:runAction(cc.Sequence:create(actList))


end

--
--[[
    地图上每八个点为一个周期，分为八个阶段
    根据不同的阶段获取中间点坐标
]]
function PelicanBonusMapLayer:getNodeMove(pos,startPos,endPos)
    local remainder = math.fmod(pos,8)
    local waitTime = 1
    local nodeMove = cc.MoveTo:create(waitTime,endPos)
    if remainder == 1 then
        nodeMove = cc.MoveTo:create(waitTime,endPos)
    elseif remainder == 2 then
        nodeMove = cc.BezierTo:create(waitTime,{cc.p(startPos.x, startPos.y), cc.p(startPos.x + 50, endPos.y), endPos})
    elseif remainder == 3 then
        nodeMove = cc.MoveTo:create(waitTime,endPos)
    elseif remainder == 4 then
        nodeMove = cc.BezierTo:create(waitTime,{cc.p(startPos.x, startPos.y), cc.p(endPos.x - 50, startPos.y + 50), endPos})
    elseif remainder == 5 then
        nodeMove = cc.BezierTo:create(waitTime,{cc.p(startPos.x, startPos.y), cc.p(startPos.x + 50, endPos.y), endPos})
    elseif remainder == 6 then
        nodeMove = cc.BezierTo:create(waitTime,{cc.p(startPos.x, startPos.y), cc.p(startPos.x + 50, endPos.y - 50), endPos}) 
    elseif remainder == 7 then
        nodeMove = cc.BezierTo:create(waitTime,{cc.p(startPos.x, startPos.y), cc.p(startPos.x - 50, endPos.y + 50), endPos})
    elseif remainder == 0 then
        nodeMove = cc.BezierTo:create(waitTime,{cc.p(startPos.x, startPos.y), cc.p(startPos.x + 50, endPos.y), endPos})
    end
    return nodeMove
end

function PelicanBonusMapLayer:vecNodeReset( _pos,_data )


    for i = 1, #self.m_vecNodeLevel, 1 do
        local item = self.m_vecNodeLevel[i]
        if i <= _pos then
            item:completed()
        else
            item:idle()
        end
        
    end

    local node = self:findChild("Node_".._pos)
    local endPos = cc.p(util_getConvertNodePos(node,self.m_nodePanda))
    if _data[_pos] and _data[_pos].type == "BIG" then
        self.m_nodePanda:setPosition(endPos.x, endPos.y + self.JUMPNODE_ADD_POSY)
    else
        self.m_nodePanda:setPosition(endPos.x, endPos.y)
    end
end


function PelicanBonusMapLayer:updateCoins( pos,coins )
    
    local item = self.m_vecNodeLevel[pos]
    local lab = item:findChild("m_lb_coins")
    if lab then --会有空的情况，大关没有这个节点
        lab:setString(util_formatCoins(coins,3))
    end

end



return PelicanBonusMapLayer