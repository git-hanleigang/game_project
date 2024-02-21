local CloverHatBonusMapLayer = class("CloverHatBonusMapLayer", util_require("base.BaseView"))

CloverHatBonusMapLayer.JUMPNODE_ADD_POSY = 120

-- 构造函数
function CloverHatBonusMapLayer:initUI(data, pos)
    local resourceFilename = "CloverHat_Map_qianjing.csb"
    self:createCsbNode(resourceFilename)
    self.m_nodePanda = cc.Node:create()
    self.m_csbOwner["Node_0"]:getParent():addChild(self.m_nodePanda)
    self.m_panda = util_createView("CodeCloverHatSrc.CloverHatMap.CloverHatBonusMapPanda")
    self.m_nodePanda:addChild(self.m_panda)
    self.m_panda:runCsbAction("idle",true)

    self.m_vecNodeLevel = {}
    for i = 1, #data, 1 do
        local info = data[i]
        local itemFile = nil
        local item = nil
        local BigLevelInfo = nil
        if info.type == "BIG" then
            
            itemFile = "CodeCloverHatSrc.CloverHatMap.CloverHatBonusMapBigLevel"

            BigLevelInfo = {}
            BigLevelInfo.info = info
            BigLevelInfo.currLevel = pos
            BigLevelInfo.selfPos = i
        else
            itemFile = "CodeCloverHatSrc.CloverHatMap.CloverHatBonusMapItem"
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
        item:findChild("indexLab"):setString(i)
    end
    local node = self:findChild("Node_"..pos)
    if data[pos] and data[pos].type == "BIG" then
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY() + self.JUMPNODE_ADD_POSY)
    else
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY())
    end
    
    

    

end

function CloverHatBonusMapLayer:getLevelPosX(pos)

    local WorldPos = self:findChild("Node_"..pos):getParent():convertToWorldSpace(cc.p(self:findChild("Node_"..pos):getPosition()))
    local NodePos = self:convertToNodeSpace(WorldPos)


    return - cc.p(NodePos).x


end

function CloverHatBonusMapLayer:pandaMove(callBack, bonusData, pos)

    local info = bonusData[pos]
    local node = self:findChild("Node_"..pos)
    
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function()
        self.m_panda:runCsbAction("actionframe")
    end)
    actList[#actList + 1] = cc.DelayTime:create(0.3)
    if info and info.type == "BIG" then

        gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_pandaMove_BigDown.mp3")

        actList[#actList + 1] = cc.JumpTo:create(0.5,cc.p(node:getPositionX(), node:getPositionY() + self.JUMPNODE_ADD_POSY) ,320 ,1)
    else

        gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_SmallMan_Move.mp3")

        actList[#actList + 1] = cc.JumpTo:create(0.5,cc.p(node:getPositionX(), node:getPositionY()),100,1)
    end
    
    actList[#actList + 1] = cc.CallFunc:create(function()
        
        self.m_panda:runCsbAction("actionframe_luodi")
    end)

    actList[#actList + 1] = cc.DelayTime:create(0.6)
    
    if info and info.type == "BIG" then



        actList[#actList + 1] = cc.CallFunc:create(function()
        
            gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_BigLevel_jumpOver.mp3")

        end)
    end

    actList[#actList + 1] = cc.CallFunc:create(function()

        

        self.m_panda:runCsbAction("idle",true)

        self.m_vecNodeLevel[pos]:click(function()

            if callBack ~= nil then

                callBack()

            end
        end)

    end)

    self.m_nodePanda:runAction(cc.Sequence:create(actList))


end

function CloverHatBonusMapLayer:vecNodeReset( _pos,_data )


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
    else
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY())
    end
end


function CloverHatBonusMapLayer:updateCoins( pos,coins )
    
    local item = self.m_vecNodeLevel[pos]
    local lab = item:findChild("labCoins")
    if lab then --会有空的情况，大关没有这个节点
        lab:setString(util_formatCoins(coins,3))
    end

end

function CloverHatBonusMapLayer:onEnter()

end

function CloverHatBonusMapLayer:onExit()

end


return CloverHatBonusMapLayer