---
--xcyy
--2018年5月23日
--PiggyLegendPirateMapView.lua

local PiggyLegendPirateMapView = class("PiggyLegendPirateMapView",util_require("Levels.BaseLevelDialog"))

local MAP_SIZE = 528

local BIG_LEVEL = {
    LEVEL1 = 2,
    LEVEL2 = 7,
    LEVEL3 = 13,
    LEVEL4 = 20
}
function PiggyLegendPirateMapView:initUI(data, pos,machine)

    self:createCsbNode("PiggyLegendPirate/MapPiggyLegendPirate.csb")

    self.m_dituBgSpine = util_spineCreate("PiggyLegendPirate_ditu", true, true)
    self:findChild("ditubg"):addChild(self.m_dituBgSpine)
    self.m_dituBgSpine:setVisible(false)

    self.m_machine = machine
    self.m_mapInfo = data
    self.curPos = pos
    self.m_vecNodeLevel = {}
    self.m_bIsShow = false
    self.m_isTouch = false
    self.m_nodePanda = cc.Node:create()
    self:findChild("Node_guanqia"):addChild(self.m_nodePanda)
    self.m_panda = util_createView("CodePiggyLegendPirateSrc.map.PiggyLegendPirateMapMoveItem")
    self.m_nodePanda:addChild(self.m_panda)
    self:initMapItem()
    self:vecNodeReset( pos ,self.m_mapInfo)
    
end

function PiggyLegendPirateMapView:changePandaParent(isUp)
    -- if isUp then
    --     util_changeNodeParent(self:findChild("Node_21"),self.m_nodePanda,10)
    -- else
    --     util_changeNodeParent(self:findChild("Node_guadian"),self.m_nodePanda,10)
    -- end
end

function PiggyLegendPirateMapView:initMapItem()
    for i = 1, #self.m_mapInfo, 1 do
        local info = self.m_mapInfo[i]
        local itemFile = nil
        local item = nil
        local BigLevelInfo = nil
        if info.type == "BIG" then
            
            itemFile = "CodePiggyLegendPirateSrc.map.PiggyLegendPirateMapBigItem"

            BigLevelInfo = {}
            BigLevelInfo.selfPos = i
        else
            itemFile = "CodePiggyLegendPirateSrc.map.PiggyLegendPirateMapSmallItem"
            BigLevelInfo = {}
            BigLevelInfo.selfPos = i
        end

        item = util_createView(itemFile, BigLevelInfo)
        
        self.m_vecNodeLevel[#self.m_vecNodeLevel + 1] = item
        self:findChild("Node_"..i):addChild(item)
        util_setCascadeOpacityEnabledRescursion(self:findChild("Node_"..i), true)
        util_setCascadeColorEnabledRescursion(self:findChild("Node_"..i), true)
        if i <= self.curPos then
            item:completed()
        else
            item:idle()
        end
    end
end

function PiggyLegendPirateMapView:pandaMove(callBack, bonusData, pos,LitterGameWin)

    local info = bonusData[pos]
    local node = self:findChild("Node_"..pos)
    local oldNode = self:findChild("Node_"..(pos - 1))
    self.curPos = pos
    -- local startPos = cc.p(util_getConvertNodePos(oldNode,self.m_nodePanda))
    -- local endPos = cc.p(util_getConvertNodePos(node,self.m_nodePanda))
    local actList = {}
    
    actList[#actList + 1] = cc.MoveTo:create(1,cc.p(node:getPositionX(), node:getPositionY()-40))

    actList[#actList + 1] = cc.CallFunc:create(function()

        self.m_vecNodeLevel[pos]:click(function()

            if callBack ~= nil then

                callBack()

            end
        end,LitterGameWin)

    end)

    util_spinePlay(self.m_panda.m_chuanSpine, "run", false)   
    util_spineEndCallFunc(self.m_panda.m_chuanSpine,"run",function ()
        util_spinePlay(self.m_panda.m_chuanSpine, "idleframe", true)   
    end)
    if pos > 8 and pos < 15 then
        self.m_nodePanda:setScaleX(-1)
    else
        self.m_nodePanda:setScaleX(1)
    end
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_map_chuan_move.mp3")
    self.m_nodePanda:runAction(cc.Sequence:create(actList))

end

function PiggyLegendPirateMapView:onEnter()

    PiggyLegendPirateMapView.super.onEnter(self)

end

function PiggyLegendPirateMapView:onExit()
    PiggyLegendPirateMapView.super.onExit(self)

end

function PiggyLegendPirateMapView:mapAppear(func,isNoClick)

    self.m_isTouch = false
    self.m_bIsShow = true
    self:vecNodeReset( self.curPos ,self.m_mapInfo)
    self:setVisible(true)
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_map_open.mp3")
    self:findChild("Button_1"):setTouchEnabled(false)
    self:runCsbAction("open",false,function (  )
        self:changePandaParent(true)
        self:runCsbAction("idleframe",true)
        if not isNoClick then
            self:findChild("Button_1"):setTouchEnabled(true)
        end
        if func ~= nil then
            func()
        end
        
    end)
    self.m_dituBgSpine:setVisible(true)
    util_spinePlay(self.m_dituBgSpine, "open", false)   
    util_spineEndCallFunc(self.m_dituBgSpine,"open",function ()
        util_spinePlay(self.m_dituBgSpine, "idleframe", true)   
    end)

    if self.curPos > 8 and self.curPos < 15 then
        self.m_nodePanda:setScaleX(-1)
    else
        self.m_nodePanda:setScaleX(1)
    end

    util_spinePlay(self.m_panda.m_chuanSpine, "open", false)   
    util_spineEndCallFunc(self.m_panda.m_chuanSpine,"open",function ()
        util_spinePlay(self.m_panda.m_chuanSpine, "idleframe", true)   
    end)

end

function PiggyLegendPirateMapView:mapDisappear(func)

    -- gLobalSoundManager:playSound("PelicanSounds/Pelican_map_close_open.mp3")
    self:changePandaParent(false)
    self.m_bIsShow = false
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_map_over.mp3")
    self:runCsbAction("over",false,function (  )
        if func ~= nil then
            func()
        end
    end)

    util_spinePlay(self.m_dituBgSpine, "over", false)   
    util_spineEndCallFunc(self.m_dituBgSpine,"over",function ()
        self.m_dituBgSpine:setVisible(false)  
        
    end)

    util_spinePlay(self.m_panda.m_chuanSpine, "over", false)   
    util_spineEndCallFunc(self.m_panda.m_chuanSpine,"over",function ()
        self.m_panda.m_chuanSpine:setVisible(false)  
    end)
end

function PiggyLegendPirateMapView:vecNodeReset( _pos,_data )


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
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY()-40)
    else
        self.m_nodePanda:setPosition(node:getPositionX(), node:getPositionY()-40)
    end
end

function PiggyLegendPirateMapView:getMapIsShow()
    return self.m_bIsShow
end

-- 点击函数
function PiggyLegendPirateMapView:clickFunc(sender)

    if self.m_isTouch == true then
        return
    end
    self.m_isTouch = true
    
    local name = sender:getName()    
    
    if name == "Button_1" then
        -- self:setVisible(false)
        self.m_machine:hideMapScroll()
    end

end

return PiggyLegendPirateMapView