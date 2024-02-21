local AliceRubyBonusMapScrollView = class("AliceRubyBonusMapScrollView", util_require("base.BaseView"))
-- 构造函数
AliceRubyBonusMapScrollView.m_bIsShow = nil
AliceRubyBonusMapScrollView.m_currPos = nil
AliceRubyBonusMapScrollView.m_mapInfo = nil -- 地图位置信息

AliceRubyBonusMapScrollView.MOVE_IDLE = 0
AliceRubyBonusMapScrollView.MOVE_START = 1
AliceRubyBonusMapScrollView.MOVE_END = 2

AliceRubyBonusMapScrollView.MAX_MAP_NUM = 60
--11610
AliceRubyBonusMapScrollView.MAP_WIDTH = 9000

function AliceRubyBonusMapScrollView:initUI(data, pos)
    local resourceFilename = "AliceRuby_Map_biankuang.csb"
    self:createCsbNode(resourceFilename)

    self.m_mapInfo = data

    self.m_scrollView = self.m_csbOwner["ScrollView"]
    self.m_mapLayer = util_createView("CodeAliceRubySrc.AliceRubyMap.AliceRubyBonusMapLayer", self.m_mapInfo, pos)
    self.m_csbOwner["Alice_map"]:addChild(self.m_mapLayer)
    self.m_mapLayer:setPosition(0, 0)
    
    self.m_map1 = util_createView("CodeAliceRubySrc.AliceRubyMap.AliceRubyBonusMapLayer1", self.m_csbOwner["Alice_map"], cc.p(0,0))
    self.m_map1:setMoveLen(-self.MAP_WIDTH)
    self.m_map1:setParent(self)
    self.m_map1:setMoveFunc( function(  )
        local currPos = self:getCurrPos( )
        self:updateBtnEnable( currPos )
    end )

    self.m_moveStates = self.MOVE_IDLE

    self.m_bIsShow = false
    self.m_bMapCanTouch = true
    self.m_currPos = pos
    self:updatePos(pos)
    self:setVisible(false)
end

function AliceRubyBonusMapScrollView:updatePos(pos)

    self.m_mapLayer:vecNodeReset( pos ,self.m_mapInfo)

    self:updateBtnEnable( pos )
    

    local posX = self.m_mapLayer:getLevelPosX(pos) + 408
    if pos < 4 then
        posX = 0
    end

    self.m_csbOwner["Alice_map"]:setPositionX( posX )
end

function AliceRubyBonusMapScrollView:mapAppear(func)

    -- gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_map_close_open.mp3")

    self.m_bIsShow = true
    
    self:updatePos(self.m_currPos)
    self:setVisible(true)
    self:runCsbAction("start", false, function ()
        if func ~= nil then
            func()
        end
        
    end)
end

function AliceRubyBonusMapScrollView:mapDisappear(func)

    -- gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_map_close_open.mp3")
    
    self:runCsbAction("over", false, function ()
        if func ~= nil then
            func()
        end
        self.m_bMapCanTouch = true
        self.m_bIsShow = false
        self:setVisible(false)
    end)
end

function AliceRubyBonusMapScrollView:pandaMove(callBack, bonusData, pos,LitterGameWin)

    self.m_mapLayer:pandaMove(function()
        if callBack then
            callBack()
        end
        self.m_currPos = pos 
    end, bonusData, pos,LitterGameWin)
end

function AliceRubyBonusMapScrollView:moveMap(pos)


    local posX = math.floor(self.m_mapLayer:getLevelPosX(pos) + 408) 
    
    if pos < 4 then
        posX = 0
    end

    self.m_moveStates = self.MOVE_START 
    self.m_csbOwner["Alice_map"]:runAction(cc.Sequence:create(cc.MoveTo:create(0.4, cc.p(posX, 0)),cc.CallFunc:create(function(  )
        self.m_moveStates = self.MOVE_END
    end)))

end

function AliceRubyBonusMapScrollView:getMapIsShow()
    return self.m_bIsShow
end

function AliceRubyBonusMapScrollView:setMoveStop(isStop)
    self.m_bIsStop = isStop
end

function AliceRubyBonusMapScrollView:getMoveStop()
    return self.m_bIsStop
end

function AliceRubyBonusMapScrollView:getMapCanTouch()
    return self.m_bMapCanTouch
end

function AliceRubyBonusMapScrollView:setMapCanTouch(touch)
    self.m_bMapCanTouch = touch
end



-- 更新 小关赢钱
function AliceRubyBonusMapScrollView:updateLittleLevelCoins( pos,coins )
    
    self.m_mapLayer:updateCoins(pos,coins)
end

function AliceRubyBonusMapScrollView:onEnter()

end

function AliceRubyBonusMapScrollView:onExit()

end

--默认按钮监听回调
function AliceRubyBonusMapScrollView:clickFunc(_sender)
    local name = _sender:getName()
    local tag = _sender:getTag()

    if self.m_moveStates == self.MOVE_START then
        return
    end

    if not self.m_bIsShow  then
        return
    end

    -- gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_map_move_left_right.mp3")

    local currPos = self:getCurrPos( )

    if name == "btn_left" then

        if currPos >= 4 then
            currPos = currPos - 4 
            self:moveMap(currPos)
            self:updateBtnEnable( currPos )
        else
            self:moveMap(0)
            self:updateBtnEnable( 0 )
        end
        

    elseif  name == "btn_right" then 

        if currPos <= self.MAX_MAP_NUM - 4 then
            currPos = currPos + 4
            self:moveMap(currPos)
            self:updateBtnEnable( currPos )

        else

            self:moveMap(self.MAX_MAP_NUM)
            self:updateBtnEnable( self.MAX_MAP_NUM )
        end
        

    end

    
end

function AliceRubyBonusMapScrollView:showMoveBtn( )

    self:findChild("btn_left"):setEnabled(true)
    self:findChild("btn_right"):setEnabled(true)
    
end

function AliceRubyBonusMapScrollView:hidMoveBtn( )

    self:findChild("btn_left"):setEnabled(false)
    self:findChild("btn_right"):setEnabled(false)

end


function AliceRubyBonusMapScrollView:updateBtnEnable(_currPos )

    self:findChild("btn_left"):setEnabled(true)
    self:findChild("btn_right"):setEnabled(true)

    if _currPos <= 0 then
        self:findChild("btn_left"):setEnabled(false)
    end

    if _currPos >= self.MAX_MAP_NUM  then
         self:findChild("btn_right"):setEnabled(false)
    end
    
end

function AliceRubyBonusMapScrollView:getCurrPos( )
   local cutPosX =  self.MAP_WIDTH / self.MAX_MAP_NUM
    
   local posx =  self.m_csbOwner["Alice_map"]:getPositionX()
   local currPos = math.floor(posx / cutPosX) 

   return  - currPos

end

return AliceRubyBonusMapScrollView