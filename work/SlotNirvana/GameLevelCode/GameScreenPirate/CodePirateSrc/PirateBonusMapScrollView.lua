local PirateBonusMapScrollView = class("PirateBonusMapScrollView", util_require("base.BaseView"))
-- 构造函数
PirateBonusMapScrollView.m_bIsShow = nil
PirateBonusMapScrollView.m_currPos = nil
function PirateBonusMapScrollView:initUI(data, pos)

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local resourceFilename = "Bonus_Pirate_Map1.csb"
    self:createCsbNode(resourceFilename, isAutoScale)

    self.m_scrollView = self.m_csbOwner["ScrollView"]

    self.m_mapLayer = util_createView("CodePirateSrc.PirateBonusMapLayer", data, pos)
    self.m_csbOwner["moveNode1"]:addChild(self.m_mapLayer)
    self.m_mapLayer:setPosition(0, 230)
    local map1 = util_createView("CodePirateSrc.PirateBonusMapLayer1", self.m_csbOwner["moveNode1"], cc.p(0,0))
    map1:setMoveLen(-3800)
    map1:setParent(self)
    -- self.m_csbOwner["moveNode1"]:setPositionX(-2104)
    self.m_btouch = true
    self.m_bIsShow = false
    self.m_bMapCanTouch = true
    self.m_currPos = pos
    self:updatePos(pos)
    self:addClick(self:findChild("Button_1"))
end

--默认按钮监听回调
function PirateBonusMapScrollView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_btouch then
        self.m_btouch = false
    else
        return 
    end
    if name == "Button_1" then
        gLobalSoundManager:playSound("PirateSounds/sound_pirate_freespin_start.mp3")
        self:mapDisappear()
    end
end

function PirateBonusMapScrollView:updatePos(pos)
    if pos > 16 then
        pos = 16
    end
    local distance = 90
    if pos == 4 or pos == 8 or pos == 13 then
        distance = 170
    end

    local posX = self.m_mapLayer:getLevelPosX(pos)
    
    self.m_csbOwner["moveNode1"]:setPositionX(distance - posX)
    -- self.m_csbOwner["moveNode2"]:setPositionX(distance - posX)
    -- self.m_csbOwner["moveNode3"]:setPositionX(distance - posX)
end

function PirateBonusMapScrollView:mapAppear(func, isAuto)
    -- gLobalSoundManager:playSound("PirateSounds/sound_Pirate_map_show_hide.mp3")
    self.m_maskUI = util_newMaskLayer()
    self:addChild(self.m_maskUI,-1)
    self.m_maskUI:setOpacity(192)
    self.m_maskUI:setScale(3)
    self:setVisible(true)
    self.m_btouch = true
    if isAuto == true then
        self:findChild("Button_1"):setVisible(false)
    else
        self:findChild("Button_1"):setVisible(true)
    end
    self:updatePos(self.m_currPos)
    self:runCsbAction("start", false, function ()
        if func ~= nil then
            func()
        end
        self.m_bIsShow = true
    end)
end

function PirateBonusMapScrollView:mapDisappear(func)
    -- gLobalSoundManager:playSound("PirateSounds/sound_Pirate_map_show_hide.mp3")
    self:runCsbAction("over", false, function ()
        if func ~= nil then
            func()
        end
        self:setVisible(false)
        if self.m_maskUI then
            self.m_maskUI:removeFromParent()
            self.m_maskUI = nil
        end
        self.m_bMapCanTouch = true
        self.m_bIsShow = false
        self.m_btouch = true
    end)
end

function PirateBonusMapScrollView:pandaMove(callBack, bonusData, pos)
    if pos == 1 or pos == 5 or pos == 9 or pos == 10 or pos == 14 or pos == 15 or pos == 16 then
        -- 看不到玩法动画的点 需要移动到能显示 玩法
        performWithDelay(self, function()
            self:moveMap(pos)
        end, 0.8)
    end
    gLobalSoundManager:playSound("PirateSounds/sound_pirate_map_move.mp3")
    self.m_mapLayer:pandaMove(function()
        self:mapDisappear(callBack)
        self.m_currPos = pos
    end, bonusData, pos)
end

function PirateBonusMapScrollView:moveMap(pos)
    local distance = 80
    if pos == 5 then
        local distance = -180
    elseif pos == 9 or pos == 15 then
        distance = -240

    elseif pos == 14 then
        distance = -280
    end

    local posX = self.m_mapLayer:getLevelPosX(pos)
    distance = distance - posX
    self.m_csbOwner["moveNode1"]:runAction(cc.MoveTo:create(0.4, cc.p(distance, 0)))
    -- self.m_csbOwner["moveNode2"]:runAction(cc.MoveTo:create(0.4, cc.p(distance, 0)))
    -- self.m_csbOwner["moveNode3"]:runAction(cc.MoveTo:create(0.4, cc.p(distance * 0.3, 0)))
end

function PirateBonusMapScrollView:getMapIsShow()
    return self.m_bIsShow
end

function PirateBonusMapScrollView:setMoveStop(isStop)
    self.m_bIsStop = isStop
end

function PirateBonusMapScrollView:getMoveStop()
    return self.m_bIsStop
end

function PirateBonusMapScrollView:getMapCanTouch()
    return self.m_bMapCanTouch
end

function PirateBonusMapScrollView:setMapCanTouch(touch)
    self.m_bMapCanTouch = touch
end

function PirateBonusMapScrollView:mapReset(data)
    self.m_mapLayer:mapReset(data)
    self.m_currPos = 0
end

function PirateBonusMapScrollView:onEnter()

end

function PirateBonusMapScrollView:onExit()

end

return PirateBonusMapScrollView