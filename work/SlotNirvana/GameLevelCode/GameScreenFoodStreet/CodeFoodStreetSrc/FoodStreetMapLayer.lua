---
--xcyy
--2018年5月23日
--FoodStreetMapLayer.lua

local FoodStreetMapLayer = class("FoodStreetMapLayer", util_require("base.BaseView"))

local MAP_ARRAY = {"panda", "cow", "fox", "rabbit"}

function FoodStreetMapLayer:initUI(data)
    self.m_machine = data.machine
    self:createCsbNode("FoodStreet/xuanzejianzhu.csb")

    self.m_isClosing = false
    self.m_closeIsTouch = false
    self.m_btnClose = self:findChild("closeBtn")

    self.m_dogHead = util_createView("CodeFoodStreetSrc.FoodStreetHead", 0)
    self:findChild("head_0"):addChild(self.m_dogHead)
    self.m_dogHead:setTouchFlag(false)
    self.m_dogHead:setVisible(false)

    self.m_dogSign = util_createView("CodeFoodStreetSrc.FoodStreetSign", 0)
    self:findChild("paizi_0"):addChild(self.m_dogSign)
    self.m_dogSign:setTouchFlag(false)
    self.m_dogSign:setVisible(false)

    self.m_mapBtns = util_createView("CodeFoodStreetSrc.FoodStreetMapBtn",{machine = self.m_machine, parentLayer = self})
    self:findChild("buttonx3"):addChild(self.m_mapBtns)
    
    self.m_title = self:findChild("congratulations")

    self.m_norTipImg =  self:findChild("FoodStreet_shuoming1")
    self.m_norTipImg:setVisible(false)
    self.m_foodTipImg =  self:findChild("FoodStreet_shuoming2")
    self.m_foodTipImg:setVisible(false)


    local index = 1
    self.m_vecHeads = {}
    self.m_vecFoods = {}
    self.m_vecSigns = {}
    while true do
        local headParent = self:findChild("head_" .. index)
        local foodParent = self:findChild("food_" .. index)
        local signParent = self:findChild("paizi_" .. index)
        if headParent ~= nil then
            local head = util_createView("CodeFoodStreetSrc.FoodStreetHead", index)
            headParent:addChild(head)
            head:setTouchFlag(false)
            head:setVisible(false)
            self.m_vecHeads[#self.m_vecHeads + 1] = head

            local food = util_createView("CodeFoodStreetSrc.FoodStreetFood", index)
            foodParent:addChild(food)
            food:setTouchFlag(false)
            food:setVisible(false)
            self.m_vecFoods[#self.m_vecFoods + 1] = food

            local sign = util_createView("CodeFoodStreetSrc.FoodStreetSign", index)
            signParent:addChild(sign)
            sign:setTouchFlag(false)
            sign:setVisible(false)
            self.m_vecSigns[#self.m_vecSigns + 1] = sign
        else
            break
        end

        index = index + 1
    end
    self.m_mapData = {}

    self.m_wheelPanel = self:findChild("zhuanpanPanel")
    self.m_wheelPanel:setVisible(false)
    self.m_wheelPanel:setTouchEnabled(false)


    self.m_tipNode = util_createAnimation("FoodStreet_shouzhi.csb")
    self:findChild("Node_Tip"):addChild(self.m_tipNode)
    self.m_tipNode:runCsbAction("actionframe",true)
    self.m_tipNode:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_Tip"),true)
    
end

function FoodStreetMapLayer:updateTipNodePos( states)

    self.m_tipNode:setVisible(true)

    local Node_Tip = self:findChild("Node_Tip")

    if states == self.m_machine.m_pandaBoard then
        local paizi = self:findChild("paizi_1")
        
        if paizi then
            local pos = cc.p(paizi:getPosition())
            Node_Tip:setPosition(pos)
        end
        
    elseif states == self.m_machine.m_pandaHouse then
        local head = self:findChild("head_1")
        if head then
            local pos = cc.p(head:getPosition())
            Node_Tip:setPosition(pos)
        end
        
    elseif states == self.m_machine.m_pandaBaoZi then
        local food = self:findChild("food_1")
        if food then
            local pos = cc.p(food:getPosition())
            Node_Tip:setPosition(pos)
        end
        
    end


end


function FoodStreetMapLayer:updateMapData(mapData)
end

function FoodStreetMapLayer:initMapUI(mapData, mapProgress, saleFlag)
    if mapProgress == nil then
        self.m_btnClose:setVisible(false)
        self.m_mapBtns:updateChooseBtn(true)
        self.m_title:setVisible(true)
    else
        self.m_mapBtns:updateChooseBtn(false)
        self.m_title:setVisible(false)
    end

    for i,v in ipairs(self.m_vecHeads) do
        v:setTouchFlag(false)
        v:showStarIdle("")
        v:setVisible(false)
    end

    for i,v in ipairs(self.m_vecFoods) do
        v:setTouchFlag(false)
        v:setVisible(false)
    end

    for i,v in ipairs(self.m_vecSigns) do
        v:setTouchFlag(false)
        v:setVisible(false)
    end

    self.m_dogHead:setTouchFlag(false)
    self.m_dogHead:setVisible(false)

    self.m_dogSign:setTouchFlag(false)
    self.m_dogSign:setVisible(false)


    self.m_norTipImg:setVisible(true)
    self.m_foodTipImg:setVisible(false)

    local vecHeadTemp = {}
    local haveDog = true
    for i = 1, #mapData, 1 do
        local info = mapData[i]
        if info.type == "HOUSE" or info.type == "DOG" then
            if info.level == 0 then
                if info.groupId ~= 0 then
                    local house = self:findChild("house_" .. info.groupId)
                    house:setVisible(false)
                    self.m_vecSigns[info.groupId]:setHeadInfo(info.id, info.groupId)
                    if mapProgress == nil then
                        self.m_vecSigns[info.groupId]:setTouchFlag(true)
                    end
                    self.m_vecSigns[info.groupId]:setVisible(true)
                else
                    self.m_dogSign:setHeadInfo(info.id, info.groupId, mapData.dogPrice)
                    if mapProgress == nil then
                        self.m_dogSign:setTouchFlag(true)
                    end
                    self.m_dogHead:setVisible(false)
                    self.m_dogSign:setVisible(true)
                    haveDog = false
                end
            else
                if info.groupId == 0 then
                    self.m_dogHead:setVisible(true)
                    haveDog = false
                else
                    self.m_vecHeads[info.groupId]:setVisible(true)
                end
            end
        elseif info.type == "ANIMAL" then
            local house = self:findChild("house_" .. info.groupId)
            if house:isVisible() == true and info.level < info.maxLevel and mapProgress == nil then
                self.m_vecHeads[info.groupId]:setHeadInfo(info.id, info.groupId)
                self.m_vecHeads[info.groupId]:setTouchFlag(true)
                self.m_vecHeads[info.groupId]:setVisible(true)
            end
            self.m_vecHeads[info.groupId]:showStarIdle(info.level)
            if info.level > 0 then

                self.m_norTipImg:setVisible(false)
                self.m_foodTipImg:setVisible(true)
    
                self.m_vecHeads[info.groupId]:setVisible(true)
                self.m_vecFoods[info.groupId]:setVisible(true)
            end
            vecHeadTemp[info.groupId] = true
        elseif info.type == "FOOD" then
            self.m_vecFoods[info.groupId]:setFoodInfo(info.id, info.groupId)
            if mapProgress == nil then
                self.m_vecFoods[info.groupId]:setTouchFlag(true)
            end
            if vecHeadTemp[info.groupId] ~= true then
                self.m_vecHeads[info.groupId]:setVisible(true)
                self.m_vecHeads[info.groupId]:showStarIdle(5)
                self.m_vecFoods[info.groupId]:setVisible(true)

                self.m_norTipImg:setVisible(false)
                self.m_foodTipImg:setVisible(true)

            end
        end
    end
    if mapProgress ~= nil then
        self:collectProgress(mapProgress, (saleFlag or false))
    else
        if haveDog == true then
            self.m_dogHead:setVisible(true)
        end
        self.m_dogHead:hideEffect()
        for i = 1, #self.m_vecHeads, 1 do
            self.m_vecHeads[i]:hideEffect()
            self.m_vecFoods[i]:hideEffect()
        end
    end
    self.m_mapData = mapData

    self.m_mapBtns:updateSaleBtn(saleFlag)

    if  self.m_tipNode:isVisible() then
        self.m_mapBtns:updateChooseBtn(false)
    end
end

function FoodStreetMapLayer:collectProgress(data, saleFlag)
    self.m_mapBtns:updateChooseBtn(saleFlag)
    self:updateBtnFlag(false)
    if data.type == "DOG" then
        self.m_dogHead:showEffect()
        self.m_dogHead:setVisible(true)
        self.m_dogSign:setVisible(false)
    elseif data.type == "HOUSE" then
        if not self.m_buidingEffect then
            self.m_buidingEffect = util_createView("CodeFoodStreetSrc.FoodStreetBuilding",data.groupId)
            self:findChild("yanwu_" .. data.groupId):addChild(self.m_buidingEffect)
            self.m_vecHeads[data.groupId]:showEffect()
        end
    elseif data.type == "ANIMAL" then
        self.m_vecHeads[data.groupId]:showEffect()
    elseif data.type == "FOOD" then
        self.m_vecFoods[data.groupId]:showEffect()
    end
end

function FoodStreetMapLayer:updateBtnFlag(flag)
    self.m_dogHead:setTouchFlag(flag)
    self.m_dogSign:setTouchFlag(flag)
    for i = 1, #self.m_vecHeads, 1 do
        self.m_vecHeads[i]:setTouchFlag(flag)
        self.m_vecFoods[i]:setTouchFlag(flag)
        self.m_vecSigns[i]:setTouchFlag(flag)
    end
end

function FoodStreetMapLayer:updateUI(result, mapData, saleFlag)
    if self.m_buidingEffect ~= nil then
        self.m_buidingEffect:setCallFunc(
            function()

                local states = self.m_machine:getMapTipStates()
                if states and states ~= "" then
                    self:updateTipNodePos( states)
                end
                local states = self.m_machine:getMapTipStates()
                if states and states ~= "" then
                    self.m_mapBtns:updateChooseBtn(false)
                end

                self:findChild("Panel_devour"):setVisible(false)
                self.m_buidingEffect:removeFromParent()
                self.m_buidingEffect = nil

                if not result then
                    return
                end

                local house = self:findChild("house_" .. result.groupId)
                house:setVisible(true)
                self:initMapUI(mapData)
                self.m_vecHeads[result.groupId]:setVisible(true)

                local states = self.m_machine:getMapTipStates()
                if states and states ~= "" then
                    self.m_mapBtns:updateChooseBtn(false)
                end

            end
        )
    elseif result.type == "DOG" then
        self.m_dogHead:hideEffect()
        self:initMapUI(mapData)
        self:findChild("Panel_devour"):setVisible(false)
        local states = self.m_machine:getMapTipStates()
        if states and states ~= "" then
            self:updateTipNodePos( states)
        end

        local states = self.m_machine:getMapTipStates()
        if states and states ~= "" then
            self.m_mapBtns:updateChooseBtn(false)
        end

    elseif result.type == "ANIMAL" then
        self.m_vecHeads[result.groupId]:runStarAnim(
            result.level,
            function()
                self:initMapUI(mapData)
                self:findChild("Panel_devour"):setVisible(false)

                local states = self.m_machine:getMapTipStates()
                if states and states ~= "" then
                    self:updateTipNodePos( states)
                end

                local states = self.m_machine:getMapTipStates()
                if states and states ~= "" then
                    self.m_mapBtns:updateChooseBtn(false)
                end

            end
        )
    elseif result.type == "FOOD" then
        self:initMapUI(mapData)
        self:findChild("Panel_devour"):setVisible(false)

        local states = self.m_machine:getMapTipStates()
        if states and states ~= "" then
            self:updateTipNodePos( states)
        end

        local states = self.m_machine:getMapTipStates()
        if states and states ~= "" then
            self.m_mapBtns:updateChooseBtn(false)
        end

    end

    self.m_mapBtns:updateSaleBtn(saleFlag)


    

    
end

function FoodStreetMapLayer:collectOver(result, mapData, saleFlag, func)
    self.m_mapData = mapData
    self.m_closeCall = func
    self.m_result = result
    if self.m_result == nil then
        if self.m_buidingEffect then
            self.m_buidingEffect:removeFromParent()
            self.m_buidingEffect = nil
        end
        self:initMapUI(mapData)
    end

    self:findChild("Panel_devour"):setVisible(true)
    self.m_mapBtns:updateSaleBtn(false)
    self.m_mapBtns:updateChooseBtn(false)

   
    self.m_tipNode:setVisible(false)

    self:runCsbAction(
        "start",
        false,
        function()

            if self.m_result ~= nil then
                self:updateUI(result, mapData, saleFlag)
            else
                self:findChild("Panel_devour"):setVisible(false)

                self.m_mapBtns:updateChooseBtn(true)

                local states = self.m_machine:getMapTipStates()
                if states and states ~= "" then
                    self.m_mapBtns:updateChooseBtn(false)
                    self:updateTipNodePos( states)
                end
            end

        end
    )
end

function FoodStreetMapLayer:foodCompleted(wheelInfo, result, mapData, saleFlag, func)
    self.m_closeCall = func
    self.m_result = result

    self:findChild("Panel_devour"):setVisible(true)
    self.m_tipNode:setVisible(false)

    self:runCsbAction(
        "start",
        false,
        function()
            -- food animation
            performWithDelay(
                self,
                function()
                    wheelInfo.func = function()

                        local states = self.m_machine:getMapTipStates()
                        if states and states ~= "" then
                            self:updateTipNodePos( states)
                        end

                        self:findChild("Panel_devour"):setVisible(false)

                        local coins = wheelInfo.wheel[wheelInfo.select + 1]
                        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_show_wheel_win.mp3")
                        local layer = util_createView("CodeFoodStreetSrc.FoodStreetShowWinCoins", coins)
                        gLobalViewManager:showUI(layer)
                        layer:initViewData(coins,self.m_machine)
                        self:updateUI(result, mapData, saleFlag)

                        local states = self.m_machine:getMapTipStates()
                        if states and states ~= "" then
                            self.m_mapBtns:updateChooseBtn(false)
                        end
                    end
                    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_show_wheel.mp3")
                    local wheelLayer = util_createView("CodeFoodStreetSrc.FoodStreetWheelLayer", wheelInfo)
                    gLobalViewManager:showUI(wheelLayer)
                end,
                0.5
            )
        end
    )
end

function FoodStreetMapLayer:showMap(saleFlag, chooseFlag, showDog, func)
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_show_map.mp3")

    self:findChild("Panel_devour"):setVisible(true)


    self.m_tipNode:setVisible(false)

    if chooseFlag  then
        local states = self.m_machine:getMapTipStates()
        if states and states ~= "" then
            self:updateTipNodePos( states)
        end
    end

   

    self:runCsbAction("start",false,function(  )
        self:findChild("Panel_devour"):setVisible(false)
    end)
    self.m_mapBtns:updateChooseBtn(chooseFlag)
    self.m_mapBtns:updateSaleBtn(saleFlag)
    self.m_dogHead:setTouchFlag(false)
    self.m_dogHead:setVisible(showDog)
    self.m_func = func

    local states = self.m_machine:getMapTipStates()
    if states and states ~= "" then
        self.m_mapBtns:updateChooseBtn(false)
    end
end

function FoodStreetMapLayer:collectFailedRestMapTipStates( )
    
    local states = self.m_machine:getMapTipStates()
    if states and states ~= "" then
        if states == self.m_machine.m_pandaHouse then
            self.m_machine:setMapTipStates( self.m_machine.m_pandaBoard )
        elseif states == self.m_machine.m_pandaBaoZi then
            self.m_machine:setMapTipStates( self.m_machine.m_pandaHouse )
        end
    end

end

function FoodStreetMapLayer:clickChangeTipStates(data )

    if self.m_machine:isBuyDogOrCollect() then
        if not self:isVisible() then
            return
        else
            if data.groupId == 1 and data.level and data.level > 0 then
                self.m_machine:setMapTipStates( "" )
                return
            end
        end
        
    end

    if data.type == "DOG" then
        print("狗啥也不干")
    elseif data.type == "HOUSE" then

        self.m_tipNode:setVisible(false)

        if data.groupId == 1 then --如果点击的是熊猫就继续到房子的提示，不是就结束
            self.m_machine:setMapTipStates( self.m_machine.m_pandaHouse )
        else
            self.m_machine:setMapTipStates( "" )
        end
    elseif data.type == "ANIMAL" then

        self.m_tipNode:setVisible(false)
        if data.groupId == 1 then --如果刚收集完熊猫房子并且点击的是熊猫就继续到食物的提示，不是就结束
            local states = self.m_machine:getMapTipStates()
            if states == self.m_machine.m_pandaHouse then
                self.m_machine:setMapTipStates( self.m_machine.m_pandaBaoZi )
            else
                self.m_machine:setMapTipStates( "" )
            end

        else
            self.m_machine:setMapTipStates( "" )
        end
        
    elseif data.type == "FOOD" then --如果点击的是食物就结束

        self.m_tipNode:setVisible(false)
        self.m_machine:setMapTipStates( "" )
    end

    
end

function FoodStreetMapLayer:chooseOver(data, saleFlag)
    self:collectProgress(data, saleFlag)

    local states = self.m_machine:getMapTipStates()
    if states and states ~= "" then
        self:clickChangeTipStates(data )
    end

    

    if self:isVisible() then
        self.m_isClosing = true
        performWithDelay(
            self,
            function()
                self:hideMapLayer()
            end,
            1
        )
    end
end

function FoodStreetMapLayer:onEnter()
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         self:randomShowChooseLayer()
    --     end,
    --     "RANDOM_SHOW_CHOOSELAYER"
    -- )
end

function FoodStreetMapLayer:randomShowChooseLayer()
    local mapInfo = {}
    for i = 1, #self.m_mapData, 1 do
        local info = self.m_mapData[i]
        if info.type == "HOUSE" or info.type == "DOG" then
            if info.level == 0 then
                if info.groupId ~= 0 then
                    if self.m_vecSigns[info.groupId]:getTouchFlag() then
                        table.insert(mapInfo, info)
                    end
                else
                    if self.m_dogSign:getTouchFlag() then
                        table.insert(mapInfo, info)
                        table.insert(mapInfo, info) --提高狗出现的概率
                        table.insert(mapInfo, info)
                    end
                end
            end
        elseif info.type == "ANIMAL" then
            if self.m_vecHeads[info.groupId]:getTouchFlag() then
                table.insert(mapInfo, info)
            end
        elseif info.type == "FOOD" then
            if self.m_vecFoods[info.groupId]:getTouchFlag() then
                table.insert(mapInfo, info)
            end
        end
    end
    local mapLen = table_length(mapInfo)
    local randomNum = (xcyy.SlotsUtil:getArc4Random() % mapLen) + 1
    local randomIndo = mapInfo[randomNum]
    local info = {}
    info.type = randomIndo.type
    info.index = randomIndo.id
    info.group = randomIndo.groupId
    info.price = self.m_mapData.dogPrice

    local layer = util_createView("CodeFoodStreetSrc.FoodStreetChooseLayer", info)
    gLobalViewManager:showUI(layer)
end

function FoodStreetMapLayer:onExit()
    -- gLobalNoticManager:removeAllObservers(self)
end

function FoodStreetMapLayer:hideMapLayer(func)
    self.m_isClosing = true

    
    if self.m_mapBtns.m_FoodStreet_Tips then
        self.m_mapBtns.m_FoodStreet_Tips:removeFromParent()
        self.m_mapBtns.m_FoodStreet_Tips = nil
    end
    self:runCsbAction(
        "over",
        false,
        function()
            self:setVisible(false)
            if func ~= nil then
                func()
            end
            if self.m_func then
                self.m_func()
            end
            if self.m_closeCall ~= nil then
                self.m_closeCall()
                self.m_closeCall = nil
            end
            self.m_btnClose:setVisible(true)

            self.m_isClosing = false
            self.m_closeIsTouch = false
        end
    )
end

--默认按钮监听回调
function FoodStreetMapLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "closeBtn" then
        if self.m_closeIsTouch then
            return
        end
        self.m_closeIsTouch = true

        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")

        self:hideMapLayer()
    end
end

function FoodStreetMapLayer:showTitle(isShow)
    self.m_title:setVisible(isShow)
end

function FoodStreetMapLayer:addSuperWheel(data,callFunc)
    self.m_wheelPanel:setVisible(true)
    self.m_wheelPanel:setTouchEnabled(true)

    data.parentLayer = self
    data.callback = function (  )
        self.m_wheelPanel:setVisible(false)
        self.m_wheelPanel:setTouchEnabled(false)

        if callFunc then
            callFunc()
        end
    end
    local wheel = util_createView("CodeFoodStreetSrc.FoodStreetDoubleWheelView", data)
    self:findChild("zhuanpan"):addChild(wheel)
end

function FoodStreetMapLayer:addSuperWheelWinCoinView(coin,keepShop,callback)
    local coinView = util_createView("CodeFoodStreetSrc.FoodStreetDoubleWheelShowWinCoins", coin)
    coinView:initViewData(coin,keepShop,self.m_machine)
    coinView:setCallFunc(callback)
    self:addChild(coinView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
end

function FoodStreetMapLayer:getIsClosing()
    return self.m_isClosing
end

return FoodStreetMapLayer
