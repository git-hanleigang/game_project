---
--xcyy
--2018年5月23日
--FortuneGodMapView.lua

local FortuneGodMapView = class("FortuneGodMapView",util_require("Levels.BaseLevelDialog"))

local MAP_SIZE = 528

local BIG_LEVEL = {
    LEVEL1 = 2,
    LEVEL2 = 7,
    LEVEL3 = 13,
    LEVEL4 = 20
}
function FortuneGodMapView:initUI(data, pos,machine)

    self:createCsbNode("FortuneGod/GameMap.csb")
    self.m_machine = machine
    self.m_mapInfo = data
    self.curPos = pos
    self.m_vecNodeLevel = {}
    self.m_bIsShow = false
    self.m_nodePanda = cc.Node:create()
    self:findChild("Node_guadian"):addChild(self.m_nodePanda)
    self.m_panda = util_createView("CodeFortuneGodSrc.map.FortuneGodMapMoveItem")
    self.m_nodePanda:addChild(self.m_panda)
    self:initMapItem()
    self:vecNodeReset( pos ,self.m_mapInfo)
    
end

function FortuneGodMapView:changePandaParent(isUp)
    if isUp then
        util_changeNodeParent(self:findChild("Node_21"),self.m_nodePanda,10)
    else
        util_changeNodeParent(self:findChild("Node_guadian"),self.m_nodePanda,10)
    end
end

function FortuneGodMapView:initMapItem()
    for i = 1, #self.m_mapInfo, 1 do
        local info = self.m_mapInfo[i]
        local itemFile = nil
        local item = nil
        local BigLevelInfo = nil
        if info.type == "BIG" then
            
            itemFile = "CodeFortuneGodSrc.map.FortuneGodMapBigItem"

            BigLevelInfo = {}
            BigLevelInfo.selfPos = i
        else
            itemFile = "CodeFortuneGodSrc.map.FortuneGodMapSmallItem"
        end

        item = util_createView(itemFile, BigLevelInfo)
        
        self.m_vecNodeLevel[#self.m_vecNodeLevel + 1] = item
        self:findChild("Node_"..i):addChild(item)
        if i <= self.curPos then
            item:completed()
        else
            item:idle()
        end
    end
end

function FortuneGodMapView:pandaMove(callBack, bonusData, pos,LitterGameWin)

    local info = bonusData[pos]
    local node = self:findChild("Node_"..pos)
    local oldNode = self:findChild("Node_"..(pos - 1))
    self.curPos = pos
    -- local startPos = cc.p(util_getConvertNodePos(oldNode,self.m_nodePanda))
    -- local endPos = cc.p(util_getConvertNodePos(node,self.m_nodePanda))
    local actList = {}
    
    actList[#actList + 1] = cc.DelayTime:create(0.3)

    actList[#actList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_pandaMove.mp3")
    end)
    if pos == BIG_LEVEL.LEVEL4 then
        actList[#actList + 1] = cc.JumpTo:create(0.5,cc.p(self:findChild("Node_final"):getPositionX(), self:findChild("Node_final"):getPositionY()),50,1)
    else
        actList[#actList + 1] = cc.JumpTo:create(0.5,cc.p(node:getPositionX(), node:getPositionY() + 100),50,1)
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

function FortuneGodMapView:onEnter()

    FortuneGodMapView.super.onEnter(self)

end

function FortuneGodMapView:onExit()
    FortuneGodMapView.super.onExit(self)

end

function FortuneGodMapView:mapAppear(func)

    -- gLobalSoundManager:playSound("PelicanSounds/Pelican_map_close_open.mp3")
    
    self.m_bIsShow = true
    self:vecNodeReset( self.curPos ,self.m_mapInfo)
    self:setVisible(true)
    -- gLobalSoundManager:playSound("PelicanSounds/Pelican_show_map.mp3")
    self:runCsbAction("start",false,function (  )
        self:changePandaParent(true)
        self:runCsbAction("idle",true)
            if func ~= nil then
                func()
            end
        
    end)
    
        

end

function FortuneGodMapView:mapDisappear(func)

    -- gLobalSoundManager:playSound("PelicanSounds/Pelican_map_close_open.mp3")
    self:changePandaParent(false)
    self.m_bIsShow = false
    -- gLobalSoundManager:playSound("PelicanSounds/Pelican_hide_map.mp3")
    self:runCsbAction("over",false,function (  )
        self:setVisible(false)
        if func ~= nil then
            func()
        end
    end)
end

function FortuneGodMapView:vecNodeReset( _pos,_data )


    for i = 1, #self.m_vecNodeLevel, 1 do
        local item = self.m_vecNodeLevel[i]
        if i <= _pos then
            item:completed()
        else
            item:idle()
        end
        
    end

    local node = self:findChild("Node_".._pos)
    
    -- local endPos = util_getConvertNodePos(node,self.m_nodePanda)
    if _data[_pos] and _data[_pos].type == "BIG" then
        if _pos == BIG_LEVEL.LEVEL4 then
            self.m_nodePanda:setPosition(self:findChild("Node_final"):getPositionX(), self:findChild("Node_final"):getPositionY())
        else
            self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY() + 100)
        end
        
    else
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY() + 100)
    end
end

function FortuneGodMapView:getMapIsShow()
    return self.m_bIsShow
end

return FortuneGodMapView