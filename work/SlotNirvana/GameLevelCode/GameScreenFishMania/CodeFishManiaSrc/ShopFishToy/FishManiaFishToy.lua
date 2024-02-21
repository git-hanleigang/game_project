---
--xcyy
--2018年5月23日
--FishManiaFishToy.lua

local FishManiaFishToy = class("FishManiaFishToy",util_require("base.BaseView"))
--缩放的最大值最小值和递增值
FishManiaFishToy.SCALE_MIN = 0.5
FishManiaFishToy.SCALE_MAX = 1.5
FishManiaFishToy.SCALE_INTERVAL = 0.05
--摆放矩阵的宽高
FishManiaFishToy.LIMIT_WIDTH  = 540   --宽 减去 活动边栏
FishManiaFishToy.LIMIT_HEIGHT = 400   --鱼缸顶部 到 顶栏底边
--触摸状态
FishManiaFishToy.m_isTouch     = false
FishManiaFishToy.m_isCanTouch  = true
FishManiaFishToy.m_isMove      = false

--移动间距
FishManiaFishToy.MOVE_DISTANCE =  1
--[[
    物件在界面的层级       
    FishManiaFishToy:upDateOrder 
    1                    ～  FishToyCount       : 一般物件的层级 
    FishToyCount + 1     ～  2 * FishToyCount   : 鱼类物件的层级
    2 * FishToyCount + 1 ～  N                  : 触摸时的临时层级
]] 
--[[
    initData = {
        machine = _machine,          --主轮盘
        shopIndex = _viewId,         --商店索引
        commodityIndex = _index,     --商品索引/挂点索引
        commodityId = commodityId,   --商品图标id
        startPos = pos,              --起始点
    }
]]
function FishManiaFishToy:initUI(_initData)
    self.m_isTouch = false
    self.m_isMove  = false
    self.m_machine = _initData.machine
    self.m_initData = _initData

    local p_shopData = globalMachineController.p_fishManiaShopData
    local csbName = p_shopData:getFishToyCsdPath(self.m_initData.commodityId)
    self:createCsbNode(csbName)

    --要求装饰品在同一高度左右移动 需要一个范围矩阵变量,  self.m_machine.m_machineRootScale
    local width  = self.LIMIT_WIDTH  *  display.width  / DESIGN_SIZE.width
    local height = self.LIMIT_HEIGHT *  display.height / DESIGN_SIZE.height
    self.m_limitRect = cc.rect(-width/2, -height/2, width, height)
    --添加spine动画
    self.m_spineLogo = nil
    self:addSpineNode()

    self:addClick(self:findChild("click"))
    --设置按钮
    self.m_setLayer = util_createAnimation("FishMania_wujiancaozuo.csb")
    self:addChild(self.m_setLayer)
    self.m_setLayer:setPosition(cc.p(0, 0))
    self:setLayer_changeVisible(false)
    self.m_setLayer.clickFunc = function(target, sender)
        self:setLayer_clickFunc(sender)
    end 

    --设置初始状态
    self:setPosition(self.m_initData.startPos)
    self:setScale(1)
    --检测本地文件修改初始状态
    self:initLocalCashData()

end


function FishManiaFishToy:onExit()
    self:clearHandler()
    gLobalNoticManager:removeAllObservers(self)
    FishManiaFishToy.super.onExit(self)
end

function FishManiaFishToy:getFishToyData()
    return self.m_initData
end

function FishManiaFishToy:reSetFishToyState()
    local startPos = self.m_initData.startPos
    self:setFishToyPosition(startPos)

    self:setFishToyScale(1)
end
--需要存本地文件的修改坐标调用这个口
function FishManiaFishToy:setFishToyPosition(_pos)
    self:setPosition(_pos)

    local p_shopData = globalMachineController.p_fishManiaShopData
    local data = {
        shopIndex   = self.m_initData.shopIndex,
        commodityId = self.m_initData.commodityId,
        --
        pos = _pos,
    }
    p_shopData:upDateCommodityCash(data)

end

--有本地数据的话拿一下本地数据
function FishManiaFishToy:initLocalCashData()
    local p_shopData = globalMachineController.p_fishManiaShopData
    local cashData = p_shopData:getCommodityCash(self.m_initData.shopIndex, self.m_initData.commodityId)
    if not cashData then
        return
    end
    --位置
    if cashData.pos then
        self:setPosition(cashData.pos)
    end
    --缩放
    if cashData.scale then
        self:setFishToyScale(cashData.scale)
    end
end
--刷新自己当前层级
function FishManiaFishToy:upDateOrder()
    local p_shopData = globalMachineController.p_fishManiaShopData
    local order = p_shopData:getCommodityOrder(self.m_initData.commodityId)
    local maxCount = p_shopData:getFishToyMaxCount()
    local commodityType = string.format("%d", self.m_initData.commodityId-1)
    local isFish = p_shopData:isFish(commodityType)
    --鱼类
    if isFish then
        order = order + maxCount
    end
    --被触摸 or 设置弹板正在展示
    if self.m_isTouch or self.m_setLayer:isVisible() then
        local addOrder = isFish and maxCount or 2 * maxCount
        order = order + addOrder
    end

    self:setLocalZOrder(order)
end
--[[
    spine相关
]]
function FishManiaFishToy:addSpineNode()
    local commodityId = self.m_initData.commodityId
    local spineName,pngName = globalMachineController.p_fishManiaShopData:getCommoditySpineName(commodityId)

    if spineName and "" ~= spineName then
        local logoSpite = self:findChild("logo")

        if logoSpite then
            logoSpite:setVisible(false)
            local pos = cc.p(logoSpite:getPosition())
            local size = logoSpite:getContentSize()

            self.m_spineParent = cc.Node:create()
            self:addChild(self.m_spineParent, -1)
            self.m_spineParent:setAnchorPoint(cc.p(0.5, 0))
            self.m_spineParent:setPosition(pos)

            if ""  == pngName then
                self.m_spineLogo =  util_spineCreate(spineName,true,true)
            else
                self.m_spineLogo =  util_spineCreateDifferentPath(spineName,pngName,true,true) 
            end
            self.m_spineParent:addChild(self.m_spineLogo)
            local spineSize= self.m_spineLogo:getBoundingBox()
            self.m_spineLogo:setPosition(cc.p(0, spineSize.height/2))
            self:runAnim("actionframe1", true)
        else
            -- print("[FishManiaFishToy:addSpineNode] error: logoSpite is nil")
        end
    end
end

function FishManiaFishToy:runAnim(_animName, _isLoop, _fun)
    if self.m_spineLogo then

        util_spinePlay(self.m_spineLogo, _animName, _isLoop)
        if _fun ~= nil then
            util_spineEndCallFunc(self.m_spineLogo, _animName, _fun)
        end

    else
        if _fun then
            _fun()
        end
    end
end
--获取一个需要做动作的 装饰品logo 节点
function FishManiaFishToy:getLogoNode()
    if self.m_spineParent then
        return self.m_spineParent
    end

    local logoSpite = self:findChild("logo")
    if logoSpite then
        return logoSpite
    end

    return nil
end

function FishManiaFishToy:getIsCanTouch()
    if not self.m_isCanTouch or 
        self:isInSpecialModel() then
        return false
    end

    return true
end
-- 外部修改点击响应状态
function FishManiaFishToy:setIsCanTouch(isCan)
    self.m_isCanTouch = isCan
end
-- 是否在特殊模式
function FishManiaFishToy:isInSpecialModel()
    local currSpinMode = globalData.slotRunData.currSpinMode
    if currSpinMode == FREE_SPIN_MODE then
        return true
    end

    return false
end


--点击监听
function FishManiaFishToy:clickStartFunc(sender)
    self.m_isMove  = false
    if not self:getIsCanTouch() then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
    if  name == "click"  then
        self.m_beginPos = sender:getTouchBeganPosition()
        self.m_senderPos = cc.p(self:getPosition())

        --触摸标记
        self.m_isTouch = true
        --移动前的设置按钮可见性
        self.m_setLayer_moveVis = self.m_setLayer:isVisible()
        --主轮盘切换设置按钮的展示
        self.m_machine:setLayer_switchSetLayerShow(self.m_initData.shopIndex)
        --层级
        self:upDateOrder()
        -- self.m_machine:setLayer_upDateLocalZOrder(self.m_initData.shopIndex,nil, self.m_initData.commodityIndex)
        
        --拖动时间线
        self:runAnim("actionframe2", true)

        --触摸音效
        self:playFishTouchSound()
    end
    
end

--移动监听
function FishManiaFishToy:clickMoveFunc(sender)
    if not self:getIsCanTouch() then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        if nil == self.m_beginPos then
            return
        end

        self.m_isMove  = true

        local movePos = sender:getTouchMovePosition()
        
        --触摸刚开始的位置
        local oldPos = self:getParent():convertToNodeSpaceAR(self.m_beginPos) 
        --触摸时不断变更的位置
        local newPos = self:getParent():convertToNodeSpaceAR(movePos)
        
        local offx = newPos.x - oldPos.x
        local offy = newPos.y - oldPos.y
        -- 节点实时坐标；
        local nPos = cc.p(self.m_senderPos.x + offx,self.m_senderPos.y + offy) 

        local isTouchIn = cc.rectContainsPoint(self.m_limitRect, nPos)
        --直接移动
        if isTouchIn then
            
        --找到离矩阵最近的点位
        else
            --X
            if nPos.x < cc.rectGetMinX(self.m_limitRect) then
                nPos.x = cc.rectGetMinX(self.m_limitRect)
            elseif nPos.x > cc.rectGetMaxX(self.m_limitRect) then
                nPos.x = cc.rectGetMaxX(self.m_limitRect)
            end
            --Y
            if nPos.y < cc.rectGetMinY(self.m_limitRect) then
                nPos.y = cc.rectGetMinY(self.m_limitRect)
            elseif nPos.y > cc.rectGetMaxY(self.m_limitRect) then
                nPos.y = cc.rectGetMaxY(self.m_limitRect)
            end
        end

        self:setPosition(nPos)
    end
    
end
--结束监听
function FishManiaFishToy:clickEndFunc(sender)
    if not self:getIsCanTouch() then
        return
    end

    local beginPos = sender:getTouchBeganPosition()
    local endPos = sender:getTouchEndPosition()
    local offPos = cc.p(math.abs(endPos.x - beginPos.x), math.abs(endPos.y - beginPos.y)) 
    if offPos.x > 5 or offPos.y > 5 then
        self:runAnim("actionframe1", true)
    end


    local name = sender:getName()
    if name == "click" then
        --触摸标记
        self.m_isTouch = false

        local curPos = cc.p(self:getPosition())
        self:setFishToyPosition(curPos)

        --主轮盘切换设置按钮的展示
        if not self.m_setLayer_moveVis then
            self.m_machine:setLayer_switchSetLayerShow(self.m_initData.shopIndex, nil, self.m_initData.commodityIndex)
        end
        
        --点击时间线
        self:runAnim("actionframe0", false, function()
            --默认时间线
            self:runAnim("actionframe1", true)
        end)
        
        --层级还原
        self:upDateOrder()

        if self.m_isMove then
            -- 打点
            local commodityType = string.format("%d", self.m_initData.commodityId-1)
            local pginfo = {level = self.m_initData.shopIndex ,Points = globalMachineController.p_fishManiaShopData:getPickScore()}
            local iInfo = {name = commodityType,level = self.m_initData.shopIndex }
            globalMachineController.p_LogFishManiaShop:sendGameUILog("Item", "Move", pginfo,nil,iInfo)

            self.m_isMove = false
        end
        

        self.m_beginPos = nil
    end
end

--默认按钮监听回调
-- function FishManiaFishToy:clickFunc(sender)
--     if not self:getIsCanTouch() then
--         return
--     end

--     local beginPos = sender:getTouchBeganPosition()
--     local endPos = sender:getTouchEndPosition()
--     local offPos = cc.p(math.abs(endPos.x - beginPos.x), math.abs(endPos.y - beginPos.y)) 
--     if offPos.x > 5 or offPos.y > 5 then
--         return
--     end

--     local name = sender:getName()

--     if name == "click" then
--         --主轮盘切换设置按钮的展示
--         if not self.m_setLayer_moveVis then
--             self.m_machine:setLayer_switchSetLayerShow(self.m_initData.shopIndex, nil, self.m_initData.commodityIndex)
--         end
        
--         --点击时间线
--         self:runAnim("actionframe0", false, function()
--             --默认时间线
--             self:runAnim("actionframe1", true)
--         end)
--     end
-- end

--设置装饰品缩放
function FishManiaFishToy:setFishToyScale(_scale)
    --设置节点
    local setLayer_scale = 1/_scale
    self.m_setLayer:setScale(setLayer_scale)
    --本体
    self:setScale(_scale)

    self:setLayer_upDatePosition()


    local p_shopData = globalMachineController.p_fishManiaShopData
    local data = {
        shopIndex = self.m_initData.shopIndex,
        commodityId = self.m_initData.commodityId,
        --
        scale = _scale,
    }
    p_shopData:upDateCommodityCash(data)
end

--[[
    装饰品非触摸状态下自由移动
]]
function FishManiaFishToy:clearHandler()
    if self.m_moveHandlerID then
        scheduler.unscheduleGlobal(self.m_moveHandlerID)
        self.m_moveHandlerID = nil
    end
end
-- 移动计时器 放置状态修改时 暂停或开始移动
function FishManiaFishToy:playFishToyMoveAction()
    if self.m_moveHandlerID then
        return
    end

    local moveParams = globalMachineController.p_fishManiaPlayConfig.ToyMove[self.m_initData.commodityId]
    if not moveParams then
        return
    end

    self.m_moveData = {
        dir = moveParams.dir    --当前朝向
    }
    --运动前先初始化一下方向
    local logo = self:getLogoNode()
    local curScaleX = logo:getScaleX()
    logo:setScaleX(self.m_moveData.dir * math.abs(curScaleX))

    self.m_moveHandlerID = scheduler.scheduleUpdateGlobal(function()
        --正在被触摸
        if self.m_isTouch then
            return
        end
        --正在被设置
        if self.m_setLayer:isVisible() then
            return
        end


        local curPosX = self:getPositionX()
        local distance = self.m_moveData.dir * self.MOVE_DISTANCE
        local nextPosX = curPosX + distance

        local oldDir = self.m_moveData.dir
        
        --X
        if nextPosX < cc.rectGetMinX(self.m_limitRect) then
            self.m_moveData.dir = 1
            nextPosX = cc.rectGetMinX(self.m_limitRect)
        elseif nextPosX > cc.rectGetMaxX(self.m_limitRect) then
            self.m_moveData.dir = -1
            nextPosX = cc.rectGetMaxX(self.m_limitRect)
        end
        
        --修改坐标和朝向
        self:setPositionX(nextPosX)
        if oldDir ~= self.m_moveData.dir then

            local curScaleX = logo:getScaleX()
            local nextScaleX = moveParams.dir * self.m_moveData.dir * math.abs(curScaleX)
            logo:setScaleX(nextScaleX)

        end
    end)
end
--🐟被触摸的音效
function FishManiaFishToy:playFishTouchSound()
    if self.m_touchSoundId then
        return
    end

    local p_shopData = globalMachineController.p_fishManiaShopData
    local commodityType = string.format("%d", self.m_initData.commodityId-1)
    if p_shopData:isFish(commodityType) then
        local soundName = string.format("FishManiaSounds/FishMania_fishToy_click%d.mp3", math.random(1,2))
        self.m_touchSoundId = gLobalSoundManager:playSound(soundName)

        performWithDelay(self,function()
            self.m_touchSoundId = nil
        end, 3)
    end
end
--[[
    设置按钮相关
]]
--设置按钮点击回调
function FishManiaFishToy:setLayer_clickFunc(sender)
    if not self:getIsCanTouch() then
        return
    end

    local btnName = sender:getName()

    if "Button_da" == btnName then
        self:setLayer_enlargeBtnClick()
        self:setLayer_upDateScaleBtnEnable()
    elseif "Button_xiao" == btnName then
        self:setLayer_narrowBtnClick()
        self:setLayer_upDateScaleBtnEnable()
    elseif "Button_set" == btnName then
        self:setLayer_recoveryBtnClick()
    end
end
--缩小
function FishManiaFishToy:setLayer_narrowBtnClick()
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_setLayer_narrow.mp3")

    local curScale = self:getScale()
    local scale = curScale - self.SCALE_INTERVAL
    if scale < self.SCALE_MIN then
        scale = self.SCALE_MIN
    end

    -- 打点
    local commodityType = string.format("%d", self.m_initData.commodityId-1)
    local pginfo = {level = self.m_initData.shopIndex ,Points = globalMachineController.p_fishManiaShopData:getPickScore()}
    local iInfo = {name = commodityType,level = self.m_initData.shopIndex }
    globalMachineController.p_LogFishManiaShop:sendGameUILog("Item", "Down", pginfo,nil,iInfo)

    self:setFishToyScale(scale)
end
function FishManiaFishToy:setLayer_getNarrowBtnEnable()
    local curScale = self:getScale()
    local enable = curScale > self.SCALE_MIN
    return enable
end
--放大
function FishManiaFishToy:setLayer_enlargeBtnClick()
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_setLayer_enlarge.mp3")

    local curScale = self:getScale()
    local scale = curScale + self.SCALE_INTERVAL
    if scale > self.SCALE_MAX then
        scale = self.SCALE_MAX
    end
    
    -- 打点
    local commodityType = string.format("%d", self.m_initData.commodityId-1)
    local pginfo = {level = self.m_initData.shopIndex ,Points = globalMachineController.p_fishManiaShopData:getPickScore()}
    local iInfo = {name = commodityType,level = self.m_initData.shopIndex }
    globalMachineController.p_LogFishManiaShop:sendGameUILog("Item", "Up", pginfo,nil,iInfo)
    

    self:setFishToyScale(scale)
end
function FishManiaFishToy:setLayer_getEnlargeBtnEnable()
    local curScale = self:getScale()
    local enable = curScale < self.SCALE_MAX
    return enable
end
function FishManiaFishToy:setLayer_upDateScaleBtnEnable()
    local enlargeBtn = self.m_setLayer:findChild("Button_da")
    local enlargeBtnEnable = self:setLayer_getEnlargeBtnEnable()
    enlargeBtn:setBright(enlargeBtnEnable)
    enlargeBtn:setTouchEnabled(enlargeBtnEnable)

    local narrowBtn = self.m_setLayer:findChild("Button_xiao")
    local narrowBtnEnable = self:setLayer_getNarrowBtnEnable()
    narrowBtn:setBright(narrowBtnEnable)
    narrowBtn:setTouchEnabled(narrowBtnEnable)
end

--回收
function FishManiaFishToy:setLayer_recoveryBtnClick()
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_setLayer_recovery.mp3")

    self:clearHandler()
    self:setLayer_changeVisible(false)
    self:setIsCanTouch(false)
    self.m_machine:fishToy_flyToShop(self)

    -- 打点
    local commodityType = string.format("%d", self.m_initData.commodityId-1)
    local pginfo = {level = self.m_initData.shopIndex ,Points = globalMachineController.p_fishManiaShopData:getPickScore()}
    local iInfo = {name = commodityType,level = self.m_initData.shopIndex }
    globalMachineController.p_LogFishManiaShop:sendGameUILog("Item", "Recovery", pginfo,nil,iInfo)

end
function FishManiaFishToy:setLayer_upDateRecoveryBtnEnable(_enable)
    local recoveryBtn = self.m_setLayer:findChild("Button_set")
    recoveryBtn:setBright(_enable)
    recoveryBtn:setTouchEnabled(_enable)
end
function FishManiaFishToy:setLayer_changeVisible(_isVis)
    --修改一下设置层的位置
    if _isVis then
        self:setLayer_upDatePosition()
    end

    self.m_setLayer:setVisible(_isVis)
    
    --层级变化
    self:upDateOrder()
end
--根据当前在矩形内的坐标 决定设置按钮 在上面或下面展示
function FishManiaFishToy:setLayer_upDatePosition()
    local curPosY = self:getPositionY()

    local parentScale = self:getScale() 

    local setLaterSprite = self.m_setLayer:findChild("FishMania_buttondi_1")
    local setLater_scaleY = setLaterSprite:getScaleY()
    local setLater_size = setLaterSprite:getContentSize()

    local setLater_height =  (1 / parentScale ) * setLater_size.height/2 

    if curPosY >= cc.rectGetMidY(self.m_limitRect) then
        self.m_setLayer:setPositionY(- setLater_height)
    else
        -- local logoSprite = self:findChild("logo")
        -- local logo_size = logoSprite:getContentSize()
        -- local spineScale = globalMachineController.p_fishManiaPlayConfig.ToySpineScale
        -- local logo_height = (logo_size.height * spineScale)  
        local logo_rect = self.m_spineLogo:getBoundingBox()
        local logo_height = logo_rect.height
        
        self.m_setLayer:setPositionY(logo_height + setLater_height)
    end
    
end


return FishManiaFishToy