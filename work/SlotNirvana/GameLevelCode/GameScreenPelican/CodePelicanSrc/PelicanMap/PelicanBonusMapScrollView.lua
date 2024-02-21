local PelicanBonusMapScrollView = class("PelicanBonusMapScrollView", util_require("base.BaseView"))
-- 构造函数
PelicanBonusMapScrollView.m_bIsShow = nil
PelicanBonusMapScrollView.m_currPos = nil
PelicanBonusMapScrollView.m_mapInfo = nil -- 地图位置信息

PelicanBonusMapScrollView.MOVE_IDLE = 0
PelicanBonusMapScrollView.MOVE_START = 1
PelicanBonusMapScrollView.MOVE_END = 2

PelicanBonusMapScrollView.MAX_MAP_NUM = 60

PelicanBonusMapScrollView.MAP_Height = 8500
PelicanBonusMapScrollView.MAP_Mini_Height = 7900 

local miniSizeY = 1024
local maxSizeY = 1660

function PelicanBonusMapScrollView:initUI(data, pos,machine)

    

    self.m_machine = machine
    self.m_mapInfo = data
    if display.height > miniSizeY then
        local cutSizeY = (self.MAP_Height - self.MAP_Mini_Height)/(maxSizeY - miniSizeY)
        self.MAP_Height = self.MAP_Height - (cutSizeY * (display.height - miniSizeY)) 
    end
    self:createCsbNode("Pelican_Map_bg_caiqie.csb")
    self.m_mapLayer = util_createView("CodePelicanSrc.PelicanMap.PelicanBonusMapLayer", self.m_mapInfo, pos)
    self:findChild("map"):addChild(self.m_mapLayer)

    self.m_map1 = util_createView("CodePelicanSrc.PelicanMap.PelicanBonusMapLayer1", self.m_mapLayer, cc.p(0,0))
    if display.height > 1370 then
        self.m_map1:setMoveLen(-self.MAP_Height - self:offsetPosY())
    else
        self.m_map1:setMoveLen(-self.MAP_Height)
    end
    
    self.m_map1:setParent(self)
    self.m_map1:setMoveFunc( function(  )

    end )
    
  
    self.m_moveStates = self.MOVE_IDLE

    self.m_bIsShow = false
    self.m_bMapCanTouch = true
    self.m_currPos = pos
    self:updatePos(pos)
    self:setVisible(false)
    self:setClickPosition()
end

function PelicanBonusMapScrollView:offsetPosY( )
    local offsetY = (1660 - 1370) / 130
    return (display.height - 1370) / offsetY
end

function PelicanBonusMapScrollView:updatePos(pos)
    self.m_mapLayer:vecNodeReset( pos ,self.m_mapInfo)

    local posY = self.m_mapLayer:getLevelPosY(pos)

    local size = self.m_machine.m_topPosY - self.m_machine.m_downPosY

    if  pos<= 4 and  math.abs(posY) < size then
        posY = 0
    else
        posY = - (math.abs(posY) - size + 720)
    end

    self.m_mapLayer:setPositionY( posY )

end


function PelicanBonusMapScrollView:mapAppear(func)

    -- gLobalSoundManager:playSound("PelicanSounds/Pelican_map_close_open.mp3")

    self.m_bIsShow = true
    
    self:updatePos(self.m_currPos)
    self:setVisible(true)
    gLobalSoundManager:playSound("PelicanSounds/Pelican_show_map.mp3")
    self:runCsbAction("start",false,function (  )
        self:runCsbAction("idle",true)
        if func ~= nil then
            func()
        end
    end)
    
        

end

function PelicanBonusMapScrollView:mapDisappear(func)

    -- gLobalSoundManager:playSound("PelicanSounds/Pelican_map_close_open.mp3")
    

    self.m_bMapCanTouch = true
    self.m_bIsShow = false
    gLobalSoundManager:playSound("PelicanSounds/Pelican_hide_map.mp3")
    self:runCsbAction("over",false,function (  )
        self:setVisible(false)
        if func ~= nil then
            func()
        end
    end)
end

function PelicanBonusMapScrollView:pandaMove(callBack, bonusData, pos,collectWin)

    self.m_mapLayer:pandaMove(function()
        if callBack then
            callBack()
        end
        self.m_currPos = pos 
    end, bonusData, pos,collectWin)
end

function PelicanBonusMapScrollView:moveMap(pos)

    local posY = math.floor(self.m_mapLayer:getLevelPosY(pos)) 
    
    self.m_moveStates = self.MOVE_START 
    self.m_mapLayer:runAction(cc.Sequence:create(cc.MoveTo:create(0.4, cc.p(0, posY)),cc.CallFunc:create(function(  )
        self.m_moveStates = self.MOVE_END
    end)))

end

function PelicanBonusMapScrollView:getMapIsShow()
    return self.m_bIsShow
end

function PelicanBonusMapScrollView:setMoveStop(isStop)
    self.m_bIsStop = isStop
end

function PelicanBonusMapScrollView:getMoveStop()
    return self.m_bIsStop
end

function PelicanBonusMapScrollView:getMapCanTouch()
    return self.m_bMapCanTouch
end

function PelicanBonusMapScrollView:setMapCanTouch(touch)
    self.m_bMapCanTouch = touch
end



-- 更新 小关赢钱
function PelicanBonusMapScrollView:updateLittleLevelCoins( pos,coins )
    
    self.m_mapLayer:updateCoins(pos,coins)
end



--默认按钮监听回调
function PelicanBonusMapScrollView:clickFunc(_sender)
    local name = _sender:getName()
    local tag = _sender:getTag()

    if self.m_moveStates == self.MOVE_START then
        return
    end

    if not self.m_bIsShow  then
        return
    end

    -- -- gLobalSoundManager:playSound("PelicanSounds/Pelican_map_move_left_right.mp3")

    local currPos = self:getCurrPos( )

    if name == "close" then

        -- self:mapDisappear( )
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end

    
end

function PelicanBonusMapScrollView:setClickPosition()
    local clickNode = self:findChild("close")
    local changeX = (300 / 768) * display.width
    local changeY = (1006 / 1370) * display.height
    if display.height >= 1024 and display.height < 1370 then
        changeY = (1006 / 1370) * display.height + 110
    end
    clickNode:setPosition(cc.p(changeX,changeY))
end

function PelicanBonusMapScrollView:getCurrPos( )
   local cutposY =  self.MAP_Height / self.MAX_MAP_NUM
    
   local posY =  self.m_mapLayer:getPositionY()
   local currPos = math.floor(posY / cutposY) 

   return  - currPos

end

return PelicanBonusMapScrollView