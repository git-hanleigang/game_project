local GoldExpressBonusMapScrollView = class("GoldExpressBonusMapScrollView", util_require("base.BaseView"))
-- 构造函数
GoldExpressBonusMapScrollView.m_bIsShow = nil
GoldExpressBonusMapScrollView.m_currPos = nil
function GoldExpressBonusMapScrollView:initUI(data, pos)
    local resourceFilename = "Bonus_GoldExpress_Map.csb"
    self:createCsbNode(resourceFilename)

    self.m_scrollView = self.m_csbOwner["ScrollView"]
    self.m_mapLayer = util_createView("CodeGoldExpressSrc.GoldExpressBonusMapLayer", data, pos)
    self.m_csbOwner["moveNode1"]:addChild(self.m_mapLayer)
    self.m_mapLayer:setPosition(0, 200)
    local map1 = util_createView("CodeGoldExpressSrc.GoldExpressBonusMapLayer1", self.m_csbOwner["moveNode1"], cc.p(0,0))
    map1:setMoveLen(-2460)
    map1:setParent(self)
    -- self.m_csbOwner["moveNode1"]:setPositionX(-2104)

    local node2 = util_csbCreate("Bonus_GoldExpress_Map3.csb")
    node2:setPosition(0, 200)
    self.m_csbOwner["moveNode3"]:addChild(node2)
    local map2 = util_createView("CodeGoldExpressSrc.GoldExpressBonusMapLayer2", self.m_csbOwner["moveNode3"], cc.p(0,0))
    map2:setMoveLen(-2460)
    map2:setParent(self)

    local node3 = util_csbCreate("Bonus_GoldExpress_Map4.csb")
    node3:setPosition(0, 96)
    self.m_csbOwner["moveNode2"]:addChild(node3)
    local map3 = util_createView("CodeGoldExpressSrc.GoldExpressBonusMapLayer3", self.m_csbOwner["moveNode2"], cc.p(0,0))
    map3:setMoveLen(-2460)
    map3:setParent(self)

    self.m_bIsShow = false
    self.m_bMapCanTouch = true
    self.m_currPos = pos
    self:updatePos(pos)
    self:setVisible(false)
end

function GoldExpressBonusMapScrollView:updatePos(pos)
    if pos > 16 then
        pos = 16
    end
    local distance = 90
    if pos == 4 or pos == 8 or pos == 13 then
        distance = 130
    end

    local posX = self.m_mapLayer:getLevelPosX(pos)
    if pos == 0 then
        distance = posX
    end
    self.m_csbOwner["moveNode1"]:setPositionX(distance - posX)
    self.m_csbOwner["moveNode2"]:setPositionX(distance - posX)
    self.m_csbOwner["moveNode3"]:setPositionX(distance - posX)
end

function GoldExpressBonusMapScrollView:mapAppear(func)
    -- gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_map_show_hide.mp3")
    self:updatePos(self.m_currPos)
    self:setVisible(true)
    self:runCsbAction("start", false, function ()
        if func ~= nil then
            func()
        end
        self.m_bIsShow = true
    end)
end

function GoldExpressBonusMapScrollView:mapDisappear(func)
    -- gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_map_show_hide.mp3")
    self:runCsbAction("over", false, function ()
        if func ~= nil then
            func()
        end
        self.m_bMapCanTouch = true
        self.m_bIsShow = false
        self:setVisible(false)
    end)
end

function GoldExpressBonusMapScrollView:pandaMove(callBack, bonusData, pos)
    if pos == 1 or pos == 5 or pos == 9 or pos == 10 or pos == 14 or pos == 15 or pos == 16 then
        -- 看不到玩法动画的点 需要移动到能显示 玩法
        performWithDelay(self, function()
            self:moveMap(pos)
        end, 0.8)
    end
    self.m_mapLayer:pandaMove(function()
        self:mapDisappear(callBack)
        self.m_currPos = pos
    end, bonusData, pos)
end

function GoldExpressBonusMapScrollView:moveMap(pos)
    local distance = 90
    if pos == 9 or pos == 15 then
        distance = 0
    end
    if pos == 14 then
        distance = -127
    end

    local posX = self.m_mapLayer:getLevelPosX(pos)
    distance = distance - posX
    self.m_csbOwner["moveNode1"]:runAction(cc.MoveTo:create(0.4, cc.p(distance, 0)))
    self.m_csbOwner["moveNode2"]:runAction(cc.MoveTo:create(0.4, cc.p(distance * 0.5, 0)))
    self.m_csbOwner["moveNode3"]:runAction(cc.MoveTo:create(0.4, cc.p(distance * 0.3, 0)))
end

function GoldExpressBonusMapScrollView:getMapIsShow()
    return self.m_bIsShow
end

function GoldExpressBonusMapScrollView:setMoveStop(isStop)
    self.m_bIsStop = isStop
end

function GoldExpressBonusMapScrollView:getMoveStop()
    return self.m_bIsStop
end

function GoldExpressBonusMapScrollView:getMapCanTouch()
    return self.m_bMapCanTouch
end

function GoldExpressBonusMapScrollView:setMapCanTouch(touch)
    self.m_bMapCanTouch = touch
end

function GoldExpressBonusMapScrollView:mapReset()
    self.m_mapLayer:mapReset()
    self.m_currPos = 0
end

function GoldExpressBonusMapScrollView:onEnter()

end

function GoldExpressBonusMapScrollView:onExit()

end

return GoldExpressBonusMapScrollView