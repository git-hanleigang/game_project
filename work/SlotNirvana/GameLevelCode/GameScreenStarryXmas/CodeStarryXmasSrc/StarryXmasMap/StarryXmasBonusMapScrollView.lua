local PublicConfig = require "StarryXmasPublicConfig"
local StarryXmasBonusMapScrollView = class("StarryXmasBonusMapScrollView", util_require("base.BaseView"))
-- 构造函数
StarryXmasBonusMapScrollView.m_bIsShow = nil
StarryXmasBonusMapScrollView.m_currPos = nil
StarryXmasBonusMapScrollView.m_mapInfo = nil -- 地图位置信息

StarryXmasBonusMapScrollView.MOVE_IDLE = 0
StarryXmasBonusMapScrollView.MOVE_START = 1
StarryXmasBonusMapScrollView.MOVE_END = 2

StarryXmasBonusMapScrollView.MAX_MAP_NUM = 60
--11610
StarryXmasBonusMapScrollView.MAP_WIDTH = 11800

function StarryXmasBonusMapScrollView:initUI(data, pos, machine)
    local resourceFilename = "StarryXmas_Map_fanye.csb"
    self:createCsbNode(resourceFilename)

    self.m_mapInfo = data
    self.m_machine = machine

    self.m_scrollView = self.m_csbOwner["ScrollView"]
    self.m_mapLayer = util_createView("CodeStarryXmasSrc.StarryXmasMap.StarryXmasBonusMapLayer", self.m_mapInfo, pos, machine)
    self.m_csbOwner["map"]:addChild(self.m_mapLayer)
    self.m_mapLayer:setPosition(0, 0)
    
    self.m_map1 = util_createView("CodeStarryXmasSrc.StarryXmasMap.StarryXmasBonusMapLayer1", self.m_csbOwner["map"], cc.p(0,0))
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

function StarryXmasBonusMapScrollView:updatePos(pos)

    self.m_mapLayer:vecNodeReset( pos ,self.m_mapInfo)

    self:updateBtnEnable( pos )
    

    local posX = self.m_mapLayer:getLevelPosX(pos) + 408
    if pos < 3 then
        posX = 0
    end

    self.m_csbOwner["map"]:setPositionX( posX )
end

-- 打开地图
function StarryXmasBonusMapScrollView:mapAppear(func)

    self.m_bIsShow = true
    
    self:updatePos(self.m_currPos)
    self:setVisible(true)
    self:runCsbAction("start", false, function ()
        self.m_machine:showQiPanSymbolClose()

        if func ~= nil then
            func()
        end
    end)

    -- 显示主棋盘 线数消失
    self.m_machine:playLineShowOrOver(true)
end

-- 关闭地图
function StarryXmasBonusMapScrollView:mapDisappear(func)
    
    self:runCsbAction("over", false, function ()
        if func ~= nil then
            func()
        end
        self.m_bMapCanTouch = true
        self.m_bIsShow = false
        self:setVisible(false)
    end)

    -- 显示主棋盘 线数出现
    self.m_machine:playLineShowOrOver(false)

    self.m_machine:showQiPanSymbolOpen()
end

function StarryXmasBonusMapScrollView:pandaMove(callBack, bonusData, pos, LitterGameWin, isBigDuan)

    self.m_mapLayer:pandaMove(function()
        if callBack then
            callBack()
        end
        self.m_currPos = pos 
    end, bonusData, pos, LitterGameWin, isBigDuan)
end

function StarryXmasBonusMapScrollView:moveMap(pos)


    local posX = math.floor(self.m_mapLayer:getLevelPosX(pos) + 408) 
    
    if pos < 4 then
        posX = 0
    end

    if pos >= self.MAX_MAP_NUM then
        posX = -self.MAP_WIDTH
    end

    self.m_moveStates = self.MOVE_START 
    self.m_csbOwner["map"]:runAction(cc.Sequence:create(cc.MoveTo:create(0.4, cc.p(posX, 0)),cc.CallFunc:create(function(  )
        self.m_moveStates = self.MOVE_END
        self:updateBtnEnable()
    end)))

end

function StarryXmasBonusMapScrollView:getMapIsShow()
    return self.m_bIsShow
end

function StarryXmasBonusMapScrollView:setMoveStop(isStop)
    self.m_bIsStop = isStop
end

function StarryXmasBonusMapScrollView:getMoveStop()
    return self.m_bIsStop
end

function StarryXmasBonusMapScrollView:getMapCanTouch()
    return self.m_bMapCanTouch
end

function StarryXmasBonusMapScrollView:setMapCanTouch(touch)
    self.m_bMapCanTouch = touch
end


function StarryXmasBonusMapScrollView:onEnter()

end

function StarryXmasBonusMapScrollView:onExit()

end

--默认按钮监听回调
function StarryXmasBonusMapScrollView:clickFunc(_sender)
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
    gLobalSoundManager:playSound(PublicConfig.Music_Map_Move)
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

function StarryXmasBonusMapScrollView:showMoveBtn( )

    self:findChild("btn_left"):setEnabled(true)
    self:findChild("btn_right"):setEnabled(true)
    
end

function StarryXmasBonusMapScrollView:hidMoveBtn( )

    self:findChild("btn_left"):setEnabled(false)
    self:findChild("btn_right"):setEnabled(false)

end


function StarryXmasBonusMapScrollView:updateBtnEnable(_currPos )
    local posx =  self.m_csbOwner["map"]:getPositionX()
    self:findChild("btn_left"):setEnabled(true)
    self:findChild("btn_right"):setEnabled(true)

    if -posx <= 0 then
        self:findChild("btn_left"):setEnabled(false)
    end

    if -posx >= self.MAP_WIDTH  then
         self:findChild("btn_right"):setEnabled(false)
    end
    
end

function StarryXmasBonusMapScrollView:getCurrPos( )
   local cutPosX =  self.MAP_WIDTH / self.MAX_MAP_NUM
    
   local posx =  self.m_csbOwner["map"]:getPositionX()
   local currPos = math.floor(posx / cutPosX) 

   return  - currPos

end

return StarryXmasBonusMapScrollView