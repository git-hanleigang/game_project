local CloverHatBonusMapScrollView = class("CloverHatBonusMapScrollView", util_require("base.BaseView"))
-- 构造函数
CloverHatBonusMapScrollView.m_bIsShow = nil
CloverHatBonusMapScrollView.m_currPos = nil
CloverHatBonusMapScrollView.m_mapInfo = nil -- 地图位置信息

CloverHatBonusMapScrollView.MOVE_IDLE = 0
CloverHatBonusMapScrollView.MOVE_START = 1
CloverHatBonusMapScrollView.MOVE_END = 2

CloverHatBonusMapScrollView.MAX_MAP_NUM = 60

CloverHatBonusMapScrollView.MAP_WIDTH = 11610

function CloverHatBonusMapScrollView:initUI(data, pos)
    local resourceFilename = "CloverHat_Map_biankuang.csb"
    self:createCsbNode(resourceFilename)

    self.m_mapInfo = data

    self.m_scrollView = self.m_csbOwner["ScrollView"]
    self.m_mapLayer = util_createView("CodeCloverHatSrc.CloverHatMap.CloverHatBonusMapLayer", self.m_mapInfo, pos)
    self.m_csbOwner["Node_qianjing"]:addChild(self.m_mapLayer)


    self.m_mapLayer:setPosition(0, -90)
    self.m_map1 = util_createView("CodeCloverHatSrc.CloverHatMap.CloverHatBonusMapLayer1", self.m_csbOwner["Node_qianjing"], cc.p(0,0))
    self.m_map1:setMoveLen(-self.MAP_WIDTH)
    self.m_map1:setParent(self)
    self.m_map1:setMoveFunc( function(  )
        local currPos = self:getCurrPos( )
        self:updateBtnEnable( currPos )
    end )
    
    local node2 = util_csbCreate("CloverHat_Map_houjing.csb")
    self.m_csbOwner["Node_houjing"]:addChild(node2)
    local map2 = util_createView("CodeCloverHatSrc.CloverHatMap.CloverHatBonusMapLayer2", self.m_csbOwner["Node_houjing"], cc.p(0,0))
    node2:setPosition(0, -100)
    map2:setMoveLen(-self.MAP_WIDTH)
    map2:setParent(self)

    local node3 = util_csbCreate("CloverHat_Map_qianjing_cao.csb")
    self.m_csbOwner["Node_cao"]:addChild(node3)
    local map3 = util_createView("CodeCloverHatSrc.CloverHatMap.CloverHatBonusMapLayer3", self.m_csbOwner["Node_cao"], cc.p(0,0))
    node3:setPosition(0, -70)
    map3:setMoveLen(-self.MAP_WIDTH)
    map3:setParent(self)

    self.m_moveStates = self.MOVE_IDLE

    self.m_bIsShow = false
    self.m_bMapCanTouch = true
    self.m_currPos = pos
    self:updatePos(pos)
    self:setVisible(false)
end

function CloverHatBonusMapScrollView:updatePos(pos)

    self.m_mapLayer:vecNodeReset( pos ,self.m_mapInfo)

    self:updateBtnEnable( pos )
    

    local posX = self.m_mapLayer:getLevelPosX(pos) + 408
    if pos < 4 then
        posX = 0
    end

    self.m_csbOwner["Node_qianjing"]:setPositionX( posX )
    self.m_csbOwner["Node_houjing"]:setPositionX(posX )
    self.m_csbOwner["Node_cao"]:setPositionX(posX )
end

function CloverHatBonusMapScrollView:mapAppear(func)

    gLobalSoundManager:playSound("CloverHatSounds/CloverHat_map_close_open.mp3")

    self.m_bIsShow = true
    
    self:updatePos(self.m_currPos)
    self:setVisible(true)
    self:runCsbAction("start", false, function ()
        if func ~= nil then
            func()
        end
        
    end)
end

function CloverHatBonusMapScrollView:mapDisappear(func)

    gLobalSoundManager:playSound("CloverHatSounds/CloverHat_map_close_open.mp3")
    
    self:runCsbAction("over", false, function ()
        if func ~= nil then
            func()
        end
        self.m_bMapCanTouch = true
        self.m_bIsShow = false
        self:setVisible(false)
    end)
end

function CloverHatBonusMapScrollView:pandaMove(callBack, bonusData, pos)

    self.m_mapLayer:pandaMove(function()
        if callBack then
            callBack()
        end
        self.m_currPos = pos 
    end, bonusData, pos)
end

function CloverHatBonusMapScrollView:moveMap(pos)


    local posX = math.floor(self.m_mapLayer:getLevelPosX(pos) + 408) 
    
    if pos < 4 then
        posX = 0
    end

    self.m_moveStates = self.MOVE_START 
    self.m_csbOwner["Node_qianjing"]:runAction(cc.Sequence:create(cc.MoveTo:create(0.4, cc.p(posX, 0)),cc.CallFunc:create(function(  )
        self.m_moveStates = self.MOVE_END
    end)))
    self.m_csbOwner["Node_houjing"]:runAction(cc.MoveTo:create(0.4, cc.p(posX * 0.5, 0)))
    self.m_csbOwner["Node_cao"]:runAction(cc.MoveTo:create(0.4, cc.p(posX * 0.3, 0)))

end

function CloverHatBonusMapScrollView:getMapIsShow()
    return self.m_bIsShow
end

function CloverHatBonusMapScrollView:setMoveStop(isStop)
    self.m_bIsStop = isStop
end

function CloverHatBonusMapScrollView:getMoveStop()
    return self.m_bIsStop
end

function CloverHatBonusMapScrollView:getMapCanTouch()
    return self.m_bMapCanTouch
end

function CloverHatBonusMapScrollView:setMapCanTouch(touch)
    self.m_bMapCanTouch = touch
end



-- 更新 小关赢钱
function CloverHatBonusMapScrollView:updateLittleLevelCoins( pos,coins )
    
    self.m_mapLayer:updateCoins(pos,coins)
end

function CloverHatBonusMapScrollView:onEnter()

end

function CloverHatBonusMapScrollView:onExit()

end

--默认按钮监听回调
function CloverHatBonusMapScrollView:clickFunc(_sender)
    local name = _sender:getName()
    local tag = _sender:getTag()

    if self.m_moveStates == self.MOVE_START then
        return
    end

    if not self.m_bIsShow  then
        return
    end

    gLobalSoundManager:playSound("CloverHatSounds/CloverHat_map_move_left_right.mp3")

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

function CloverHatBonusMapScrollView:showMoveBtn( )

    self:findChild("btn_left"):setEnabled(true)
    self:findChild("btn_right"):setEnabled(true)
    
end

function CloverHatBonusMapScrollView:hidMoveBtn( )

    self:findChild("btn_left"):setEnabled(false)
    self:findChild("btn_right"):setEnabled(false)

end


function CloverHatBonusMapScrollView:updateBtnEnable(_currPos )

    self:findChild("btn_left"):setEnabled(true)
    self:findChild("btn_right"):setEnabled(true)

    if _currPos <= 0 then
        self:findChild("btn_left"):setEnabled(false)
    end

    if _currPos >= self.MAX_MAP_NUM  then
         self:findChild("btn_right"):setEnabled(false)
    end
    
end

function CloverHatBonusMapScrollView:getCurrPos( )
   local cutPosX =  self.MAP_WIDTH / self.MAX_MAP_NUM
    
   local posx =  self.m_csbOwner["Node_qianjing"]:getPositionX()
   local currPos = math.floor(posx / cutPosX) 

   return  - currPos

end

return CloverHatBonusMapScrollView