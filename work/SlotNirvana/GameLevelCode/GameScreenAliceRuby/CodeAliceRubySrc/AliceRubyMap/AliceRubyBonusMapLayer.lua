local AliceRubyBonusMapLayer = class("AliceRubyBonusMapLayer", util_require("base.BaseView"))

AliceRubyBonusMapLayer.JUMPNODE_ADD_POSY = 90

-- 构造函数
function AliceRubyBonusMapLayer:initUI(data, pos)
    local resourceFilename = "AliceRuby_Map.csb"
    self:createCsbNode(resourceFilename)
    self.m_nodePanda = cc.Node:create()
    self.m_csbOwner["Node_0"]:getParent():addChild(self.m_nodePanda)
    self.m_panda = util_createView("CodeAliceRubySrc.AliceRubyMap.AliceRubyBonusMapPanda")
    self.m_nodePanda:addChild(self.m_panda)
    self.m_panda:runCsbAction("idle",true)

    self.m_vecNodeLevel = {}
    for i = 1, #data, 1 do
        local info = data[i]
        local itemFile = nil
        local item = nil
        local BigLevelInfo = nil
        if info.type == "BIG" then
            
            itemFile = "CodeAliceRubySrc.AliceRubyMap.AliceRubyBonusMapBigLevel"

            BigLevelInfo = {}
            BigLevelInfo.info = info
            BigLevelInfo.currLevel = pos
            BigLevelInfo.selfPos = i
        else
            itemFile = "CodeAliceRubySrc.AliceRubyMap.AliceRubyBonusMapItem"
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
        item:findChild("Alice_guanshu_font"):setString(i)
    end
    local node = self:findChild("Node_"..pos)
    if data[pos] and data[pos].type == "BIG" then
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY() + self.JUMPNODE_ADD_POSY)
    elseif data[pos] and data[pos].type == "SMALL" then
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY()+70)
    else
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY())
    end
end

function AliceRubyBonusMapLayer:getLevelPosX(pos)

    local WorldPos = self:findChild("Node_"..pos):getParent():convertToWorldSpace(cc.p(self:findChild("Node_"..pos):getPosition()))
    local NodePos = self:convertToNodeSpace(WorldPos)
    return - cc.p(NodePos).x
end

function AliceRubyBonusMapLayer:pandaMove(callBack, bonusData, pos,LitterGameWin)

    local info = bonusData[pos]
    local node = self:findChild("Node_"..pos)
    
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function()
        self.m_panda:runCsbAction("actionframe")
    end)
    actList[#actList + 1] = cc.DelayTime:create(0.3)
    gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_panda_move.mp3")
    if info and info.type == "BIG" then

        -- gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_pandaMove_BigDown.mp3")
        self.m_panda:runCsbAction("actionframe_big")
        actList[#actList + 1] = cc.JumpTo:create(0.5,cc.p(node:getPositionX(), node:getPositionY() + self.JUMPNODE_ADD_POSY) ,160 ,1)
    else

        -- gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_SmallMan_Move.mp3")
        self.m_panda:runCsbAction("actionframe_smart")
        actList[#actList + 1] = cc.JumpTo:create(0.5,cc.p(node:getPositionX(), node:getPositionY()+70),50,1)
    end
    
    actList[#actList + 1] = cc.CallFunc:create(function()
        
        self.m_panda:runCsbAction("actionframe_luodi")
    end)

    actList[#actList + 1] = cc.DelayTime:create(0.6)
    
    if info and info.type == "BIG" then

        actList[#actList + 1] = cc.CallFunc:create(function()

            -- gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_BigLevel_jumpOver.mp3")
        end)
    end

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

function AliceRubyBonusMapLayer:vecNodeReset( _pos,_data )
    for i = 1, #self.m_vecNodeLevel, 1 do
        local item = self.m_vecNodeLevel[i]
        if i <= _pos then
            item:completed()
        else
            item:idle()
        end
    end
    local node = self:findChild("Node_".._pos)
    if _data[_pos] and _data[_pos].type == "BIG" then
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY() + self.JUMPNODE_ADD_POSY)
    elseif _data[_pos] and _data[_pos].type == "SMALL" then
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY()+70)
    else
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY())
    end
end


function AliceRubyBonusMapLayer:updateCoins( pos,coins )
    
    local item = self.m_vecNodeLevel[pos]
    local lab = item:findChild("labCoins")
    if lab then --会有空的情况，大关没有这个节点
        lab:setString(util_formatCoins(coins,3))
    end

end

function AliceRubyBonusMapLayer:onEnter()

end

function AliceRubyBonusMapLayer:onExit()

end


return AliceRubyBonusMapLayer