local PublicConfig = require "StarryXmasPublicConfig"
local StarryXmasBonusMapLayer = class("StarryXmasBonusMapLayer", util_require("base.BaseView"))

StarryXmasBonusMapLayer.JUMPNODE_ADD_POSY = 150

-- 构造函数
function StarryXmasBonusMapLayer:initUI(data, pos, machine)
    local resourceFilename = "StarryXmas_Map.csb"
    self:createCsbNode(resourceFilename)
    self.m_nodePanda = cc.Node:create()
    self.m_csbOwner["Node_0"]:getParent():addChild(self.m_nodePanda)
    self.m_panda = util_spineCreate("StarryXmas_Map_zhizhen", true, true)
    self.m_nodePanda:addChild(self.m_panda)

    self.m_machine = machine

    util_spinePlay(self.m_panda,"zhizhen_idleframe2",true)

    self.m_vecNodeLevel = {}
    for i = 1, #data, 1 do
        local info = data[i]
        local itemFile = nil
        local item = nil
        local BigLevelInfo = nil
        if info.type == "BIG" then
            
            itemFile = "CodeStarryXmasSrc.StarryXmasMap.StarryXmasBonusMapBigLevel"

            BigLevelInfo = {}
            BigLevelInfo.info = info
            BigLevelInfo.currLevel = pos
            BigLevelInfo.selfPos = i
        else
            itemFile = "CodeStarryXmasSrc.StarryXmasMap.StarryXmasBonusMapItem"
        end

        item = util_createView(itemFile, BigLevelInfo)
        
        self.m_vecNodeLevel[#self.m_vecNodeLevel + 1] = item
        self:findChild("Node_"..i):addChild(item)
        if info.type == "BIG" then
            item:setPositionY(item:getPositionY())
        end
        item:findChild("m_lb_num"):setString(i)
    end
    local node = self:findChild("Node_"..pos)
    self.m_panda:setPositionY(0)
    if data[pos] and data[pos].type == "BIG" then
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY()+self.JUMPNODE_ADD_POSY+100)
    elseif data[pos] and data[pos].type == "SMALL" then
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY()+self.JUMPNODE_ADD_POSY)
    else
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY())
    end
end

function StarryXmasBonusMapLayer:getLevelPosX(pos)

    local WorldPos = self:findChild("Node_"..pos):getParent():convertToWorldSpace(cc.p(self:findChild("Node_"..pos):getPosition()))
    local NodePos = self:convertToNodeSpace(WorldPos)
    return - cc.p(NodePos).x
end

function StarryXmasBonusMapLayer:pandaMove(callBack, bonusData, pos, LitterGameWin, isBigDuan)

    local info = bonusData[pos]
    local node = self:findChild("Node_"..pos)
    
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.Music_People_Jump)
        util_spinePlay(self.m_panda,"zhizhen_move",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(3/30)
    
    if info and info.type == "BIG" then
        actList[#actList + 1] = cc.JumpTo:create(13/30,cc.p(node:getPositionX(), node:getPositionY() + self.JUMPNODE_ADD_POSY+100) ,160 ,1)
    else
        actList[#actList + 1] = cc.JumpTo:create(13/30,cc.p(node:getPositionX(), node:getPositionY() + self.JUMPNODE_ADD_POSY),50,1)
    end
    actList[#actList + 1] = cc.DelayTime:create(4/30)
    actList[#actList + 1] = cc.CallFunc:create(function()
        util_spinePlay(self.m_panda,"zhizhen_idleframe2",true)
        if isBigDuan then
            gLobalSoundManager:playSound(PublicConfig.Music_Trigger_Play_Big)
        else
            gLobalSoundManager:playSound(PublicConfig.Music_Trigger_Play_Small)
        end
        self.m_vecNodeLevel[pos]:click(function()
            if callBack ~= nil then
                callBack()
            end
        end,LitterGameWin, self.m_machine)

    end)
    self.m_nodePanda:runAction(cc.Sequence:create(actList))
end

function StarryXmasBonusMapLayer:vecNodeReset( _pos,_data )
    for i = 1, #self.m_vecNodeLevel, 1 do
        local item = self.m_vecNodeLevel[i]
        if i <= _pos then
            item:completed()
        else
            item:idle()
        end
    end
    local node = self:findChild("Node_".._pos)
    self.m_panda:setPositionY(0)
    if _data[_pos] and _data[_pos].type == "BIG" then
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY()+self.JUMPNODE_ADD_POSY+100)
    elseif _data[_pos] and _data[_pos].type == "SMALL" then
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY()+self.JUMPNODE_ADD_POSY)
    else
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY())
    end
end

function StarryXmasBonusMapLayer:onEnter()

end

function StarryXmasBonusMapLayer:onExit()

end

--[[
    小关收集钱的 相关动效
]]
function StarryXmasBonusMapLayer:xiaoGuanGouByFly(pos)
    if self.m_vecNodeLevel[pos].playGou then
        self.m_vecNodeLevel[pos]:playGou()
    end
end

return StarryXmasBonusMapLayer