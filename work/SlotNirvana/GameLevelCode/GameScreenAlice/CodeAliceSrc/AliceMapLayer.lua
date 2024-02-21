---
--xcyy
--2018年5月23日
--AliceMapLayer.lua

local AliceMapLayer = class("AliceMapLayer",util_require("base.BaseView"))

local POS_ARRAY = 
{
    hat  = {cc.p(269, 136.11), cc.p(334.04, 79.87), cc.p(365.04, 61.87), cc.p(381.04, 36.87), cc.p(373.04, 8.87), cc.p(336.04, -1.13), cc.p(299.04, -14.13), cc.p(278.31, -45.15)},
    card = {cc.p(232, -80.80), cc.p(159.02, -138), cc.p(112.02, -151), cc.p(59.02, -157), cc.p(3.02, -160), cc.p(-52.98, -154), cc.p(-106.98, -147), cc.p(-154.98, -131)},
    tree = {cc.p(-250.30, -57.43), cc.p(-317.99, -47), cc.p(-346.99, -25), cc.p(-369.99, 6), cc.p(-383.99, 40), cc.p(-379.99, 75), cc.p(-357.99, 104), cc.p(-325.99, 129)},
    mushroom = {cc.p(-273.27, 187.98), cc.p(-209, 218), cc.p(-175, 233), cc.p(-133, 244), cc.p(-90.67, 246.08), cc.p(-50.67, 244.08), cc.p(-13.67, 237.08), cc.p(21.33, 226.08)},
    rose = {cc.p(81.31, 227.31), cc.p(148, 230), cc.p(186.02, 239.97), cc.p(227.02, 241.97), cc.p(266.02, 233.97), cc.p(303.01, 217.97), cc.p(320.01, 189.97), cc.p(321.01, 153.97)},
    castle = {cc.p(-13, 74)},
    hat_castle = {cc.p(269, 136.11), cc.p(197.02, 75), cc.p(167.02, 69), cc.p(134.02, 59), cc.p(104.02, 46), cc.p(-13, 74)},
    castle_hat = {cc.p(-13, 74), cc.p(104.02, 46), cc.p(134.02, 59), cc.p(167.02, 69), cc.p(197.02, 75)},
    card_castle = {cc.p(232, -80.80), cc.p(191.80, -28.84), cc.p(165.32, -10.60), cc.p(134.72, -0.60), cc.p(100.15, 7.26), cc.p(-13, 74)},
    castle_card = {cc.p(-13, 74), cc.p(100.15, 7.26), cc.p(134.72, -0.60), cc.p(165.32, -10.60), cc.p(191.80, -28.84)},
    tree_castle = {cc.p(-250.30, -57.43), cc.p(-208.98, 14), cc.p(-181.98, 33), cc.p(-146.98, 42), cc.p(-114.98, 46), cc.p(-13, 74)},
    castle_tree = {cc.p(-13, 74), cc.p(-114.98, 46), cc.p(-146.98, 42), cc.p(-181.98, 33), cc.p(-208.98, 14)},
    mushroom_castle = {cc.p(-273.27, 187.98), cc.p(-200.98, 150), cc.p(-163.98, 143), cc.p(-128.98, 131), cc.p(-95.98, 108), cc.p(-13, 74)},
    castle_mushroom = {cc.p(-13, 74), cc.p(-95.98, 108), cc.p(-128.98, 131), cc.p(-163.98, 143), cc.p(-200.98, 150)},
    rose_castle = {cc.p(81.31, 227.31), cc.p(121.02, 161), cc.p(113.02, 126), cc.p(87.02, 102), cc.p(51.02, 83), cc.p(-13, 74)},
    castle_rose = {cc.p(-13, 74), cc.p(51.02, 83), cc.p(87.02, 102), cc.p(113.02, 126), cc.p(121.02, 161)}
}

local GAMES_ARRAY = {"hat", "card", "tree", "mushroom", "rose", "castle"}
local ROAD_NAME = 
{
    mushroom = 1,
    rose = 2,
    hat = 3,
    card = 4,
    tree = 5,
    mushroom_castle = 6,
    castle_mushroom = 6,
    rose_castle = 7,
    castle_rose = 7,
    hat_castle = 8,
    castle_hat = 8,
    card_castle = 9,
    castle_card = 9,
    tree_castle = 10,
    castle_tree = 10

}

local BONUS_GAME_NAME = 
{
    mushroom = "CodeAliceSrc.AliceBonusMushroomGame",
    rose = "CodeAliceSrc.AliceBonusRoseGame",
    hat = "CodeAliceSrc.AliceBonusHatGame",
    card = "CodeAliceSrc.AliceBonusCardGame",
    tree = "CodeAliceSrc.AliceBonusTreeGame",
    castle = "CodeAliceSrc.AliceBonusCastleGame"
}

local TOTAL_GAMES = 5

AliceMapLayer.m_isShowNotice = nil
AliceMapLayer.m_isCanChoose = nil
AliceMapLayer.m_isChooseLayerRemove = nil
AliceMapLayer.m_gameInfoMap = nil
AliceMapLayer.m_roadInfo = nil
AliceMapLayer.m_jackpotMore = nil

function AliceMapLayer:initUI(data)

    self:createCsbNode("Alice/BonusMap.csb")
    self.m_parent = data
    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self:resetMapUI()
end

function AliceMapLayer:resetMapUI()
    if self.m_roadInfo ~= nil then
        local lastWay = self.m_roadInfo[#self.m_roadInfo]
        local index = 2
        while true do
            if self["point_"..lastWay..index] ~= nil then
                self["point_"..lastWay..index]:removeFromParent()
                self["point_"..lastWay..index] = nil
            else
                break
            end
            index = index + 1
        end
    end

    for i = 1, #GAMES_ARRAY, 1 do
        local game = GAMES_ARRAY[i]
        local parentNode = self:findChild("Node_"..game)
        if parentNode ~= nil then
            local info = {}
            info.name = game
            if self["icon_"..game] == nil then
                self["icon_"..game] = util_createView("CodeAliceSrc.AliceMapGameIcon", info)
                parentNode:addChild(self["icon_"..game])
            end
            self["icon_"..game]:showDarkIdle()
        end
    end

    local pointParent = self:findChild("Point")
    for key, value in pairs(POS_ARRAY) do
        local startID = 2
        
        if string.find(key, "_castle") == nil then
            local vecPos = value
            for i = startID, #vecPos, 1 do
                if self["point_"..key..i] == nil then
                    self["point_"..key..i] = util_createView("CodeAliceSrc.AliceMapPoint")
                    pointParent:addChild(self["point_"..key..i])
                    self["point_"..key..i]:setPosition(vecPos[i])
                end
                self["point_"..key..i]:idle()
            end
        end
    end
    if self.m_npcAlice == nil then
        self.m_npcAlice = util_createView("CodeAliceSrc.AliceMapAlice")
        pointParent:addChild(self.m_npcAlice, 1000)
    end
    
    self.m_npcAlice:setVisible(false)

    local roadID = 1
    while true do
        local roadNode = self:findChild("Road_"..roadID)
        if roadNode ~= nil then
            if self["road_"..roadID] == nil then
                local road = util_createView("CodeAliceSrc.AliceMapRoad", roadID)
                roadNode:addChild(road)
                self["road_"..roadID] = road
            end
            roadNode:setVisible(false)
            
        else
            break
        end
        roadID = roadID + 1
    end

    self.m_progress = self:findChild("LoadingBar_1") 
    self.m_btnBackGame = self:findChild("tb_btn")
    self.m_btnBackGame:setEnabled(false)
    self.m_labJackpot = self:findChild("m_lb_jackpot")
    self.m_labStart = self:findChild("m_lb_start")

    self.m_progress:setPercent(0)
    self.m_labJackpot:setString("")
    self.m_labStart:setString("")

    self:updateLabelSize({label = self.m_labJackpot,sx = 0.7, sy = 0.7}, 344)
    self:updateLabelSize({label = self.m_labStart,sx = 0.7, sy = 0.7}, 344)

    self.m_roadInfo = nil
end

function AliceMapLayer:resetBuilding()
    self.m_isCanChoose = true
    self:runCsbAction("idle3", true)
    for i = 1, #GAMES_ARRAY, 1 do
        local game = GAMES_ARRAY[i]
        self["icon_"..game]:showClickEffect()  
    end
end

function AliceMapLayer:initIconBeforeGame()
    self:resetBuilding()
    self.m_guideIndex = 0
    -- self:showGuideHand(self.m_guideIndex)
    self.m_guideAction = schedule(self, function()
        self:showGuideHand(self.m_guideIndex)
    end, 3)
end

function AliceMapLayer:showGuideHand()
    if self.m_guideIndex == nil then
        self.m_guideIndex = 0
    end
    self.m_guideIndex = self.m_guideIndex + 1
    if self.m_guideIndex == #GAMES_ARRAY then
        self.m_guideIndex = 1
    end
    local game = GAMES_ARRAY[self.m_guideIndex]
    local parentNode = self:findChild("Node_"..game)
    if self.m_guideHand == nil then
        self.m_guideHand = util_spineCreate("DailyBonusGuide", true, true)
        util_spinePlay(self.m_guideHand, "idleframe", true)
        parentNode:getParent():addChild(self.m_guideHand, 10000)
    end
    self.m_guideHand:setPosition(cc.p(parentNode:getPosition()))

end

function AliceMapLayer:initRoadInfo(map)
    local vecGames = map.games
    if self.m_roadInfo == nil then
        self.m_roadInfo = {}
    else
        return
    end
    self.m_roadInfo[#self.m_roadInfo + 1] = "castle_"..vecGames[1]
    for i = 1, #vecGames - 1, 1 do
        local gameName = vecGames[i]
        self.m_roadInfo[#self.m_roadInfo + 1] = gameName
    end
    self.m_roadInfo[#self.m_roadInfo] = vecGames[#vecGames - 1].."_castle"

    local oldPointKey = "point_castle_"..vecGames[#vecGames - 1]
    local newPointKey = "point_"..self.m_roadInfo[#self.m_roadInfo]
    local index = 2
    while true do
        if self[oldPointKey..index] ~= nil then
            self[newPointKey..index] = self[oldPointKey..index]
            self[oldPointKey..index] = nil
        else
            return
        end
        index = index + 1
    end
end

function AliceMapLayer:initMapUI(map)
    -- road
    self.m_isCanChoose = false
    self.m_gameInfoMap = map
    self:initRoadInfo(map)
    self.m_btnBackGame:setEnabled(true)
    self.m_npcAlice:showIdle()

    local vecPosInfo = util_string_split(map.currentPosForClient, ":")
    local currRoadName = vecPosInfo[1]
    local roadID = tonumber(vecPosInfo[2]) + 1

    local currGamesNum = 0
    for i = 1, #self.m_roadInfo, 1 do
        local roadName = self.m_roadInfo[i]
        if string.find(roadName, "_castle") ~= nil then
            local lastGame = string.gsub(roadName, "_castle", "")
            self["icon_"..lastGame]:showLightIdle()
            
            if lastGame ~= map.nextGameName then
                currGamesNum = currGamesNum + 1
            end
        end
        if self["icon_"..roadName] ~= nil then
            self["icon_"..roadName]:showLightIdle()
            if roadName == map.nextGameName then
                break
            else
                self["icon_"..roadName]:showCompletedEffect()
            end
            currGamesNum = currGamesNum + 1
        end
        
        if string.find(roadName, map.nextGameName or "") ~= nil and string.find(roadName, "_castle") ~= nil then
            break
        end

        local index = 2
        while roadName ~= currRoadName do
            if self["point_"..roadName..index] ~= nil then
                self["point_"..roadName..index]:ponitIdle()
            else
                break
            end
            index = index + 1
        end
        local roadID = ROAD_NAME[roadName]
        self:findChild("Road_"..roadID):setVisible(true)
    end

    self.m_progress:setPercent(currGamesNum * 20)

    for i = 2, roadID, 1 do
        local index = i
        if string.find(currRoadName, "_castle") ~= nil then
            index = 7 - i
            self["icon_castle"]:showLightIdle()
        end
        if self["point_"..currRoadName..index] ~= nil then
            self["point_"..currRoadName..index]:ponitIdle()
        end
    end
    local index = ROAD_NAME[currRoadName]
    if index ~= nil then
        self:findChild("Road_"..index):setVisible(true)
    end
    
    if currRoadName == "castle" then
        self["icon_castle"]:showLightIdle()
    end

    self.m_npcAlice:setVisible(true)
    self.m_npcAlice:showIdle()
    local distance = 15
    if roadID == 1 then
        distance = -15
    end
    self.m_npcAlice:setPosition(cc.pAdd(POS_ARRAY[currRoadName][roadID], cc.p(0, distance)))
end

function AliceMapLayer:updateMapUI(map)

    self:updateLab(map)

    local oldRoadName = self.m_gameInfoMap
    self.m_gameInfoMap = map
    self:initRoadInfo(map)
    local vecPosInfo = util_string_split(map.currentPosForClient, ":")
    local roadName = vecPosInfo[1]
    local roadID = tonumber(vecPosInfo[2]) + 1
    self.m_npcAlice:moveAnimation()
    local distance = 15
    if roadID == 1 then
        distance = -15
    end
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_alice_move.mp3")
    
    local moveTo = cc.MoveTo:create(0.67, cc.pAdd(POS_ARRAY[roadName][roadID], cc.p(0, distance)))
    self.m_npcAlice:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(function()
        local index = vecPosInfo[2] + 1
        if string.find(roadName, "_castle") ~= nil then
            index = 7 - index
        end
        if self["point_"..roadName..index] then
            self["point_"..roadName..index]:pointAnimation()
        end

        if map.triggerBonusGame == true then
            self["icon_"..map.triggerGameName]:showTriggerEffect()
            local randomID = math.random(1, 3)
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_building_"..randomID..".mp3")
        end
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_alice_move_down.mp3")
        
        local roadID = ROAD_NAME[roadName]

        performWithDelay(self, function()
            if map.triggerBonusGame == true then
                gLobalSoundManager:playBgMusic("AliceSounds/music_bonus_game_bg.mp3")
                local bonusView = util_createView(BONUS_GAME_NAME[map.triggerGameName])
                if bonusView.initBonusBoard then
                    bonusView:initBonusBoard(map.gameConfig)
                end
                if bonusView.initJackpot then
                    bonusView:initJackpot(map.jackpot)
                end
                if bonusView.showGuideHand then
                    bonusView:showGuideHand(function()
                        self.m_guideIndex = 0
                        gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_2_map.mp3")
                        self.m_guideAction = schedule(self, function()
                            self:showGuideHand(self.m_guideIndex)
                        end, 3)
                    end)
                end
                
                bonusView:initViewData(map.startPrize, function()
                    gLobalSoundManager:playBgMusic("AliceSounds/music_Alice_map_bg.mp3")
                    self.m_parent:updateGameIcon()
                    if map.triggerGameName == "castle" then
                        local jackpot = self.m_gameInfoMap.jackpotB
                        self.m_gameInfoMap = nil
                        self:resetMapUI()
                        self:resetBuilding()
                        self.m_parent.m_bChooseGame = true
                        if jackpot and jackpot > 0 then
                            self.m_labJackpot:setString(util_formatCoins(jackpot, 50))
                        end
                    else
                        self.m_labStart:setString("")
                        map.startPrize = 0
                        if roadID ~= nil and self:findChild("Road_"..roadID):isVisible() == false then
                            self:findChild("Road_"..roadID):setVisible(true)
                            self["road_"..roadID]:showRoadAnim()
                            self["icon_"..map.nextGameName]:showSelectedEffect()
                            gLobalSoundManager:playSound("AliceSounds/sound_Alice_alice_move_down.mp3")
                        end
                        gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_2_map.mp3")
                        performWithDelay(self, function()
                            self:showWheel()
                        end, 2)
                        
                    end
                end)
                self:findChild("windows"):addChild(bonusView)
                bonusView:setPosition(-display.width * 0.5, -display.height * 0.5)
                local oldPercent = self.m_progress:getPercent()
                self.m_progress:setPercent(oldPercent + 20)
            else
                self:showWheel()
            end
        end, 2)
        
    end)))
end

function AliceMapLayer:showGameMap(func, map)
    if func == nil and self.m_gameInfoMap ~= nil then
        self.m_btnBackGame:setEnabled(true)
    else
        self.m_btnBackGame:setEnabled(false)
    end
    self:runCsbAction("start", false, function()
        if func ~= nil then
            self:updateMapUI(map)
            self.m_backGameCall = func
        end
    end)
    self:updateLab(map)
end

function AliceMapLayer:showWheel()
    self.m_parent:showWheel()
end

function AliceMapLayer:openGameEffect(netReturn, map)
    if map ~= nil then
        self.m_gameInfoMap = map
    end
    if self.m_isChooseLayerRemove == true and netReturn == true then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_alice_move_down.mp3")
        self.m_isChooseLayerRemove = false
        for i = 1, #GAMES_ARRAY, 1 do
            local game = GAMES_ARRAY[i]
            if game ~= self.m_gameInfoMap.initPosition then
                self["icon_"..game]:showDarkIdle()
            else
                self["icon_"..game]:showSelectedEffect()
            end
        end

        local vecPosInfo = util_string_split(self.m_gameInfoMap.currentPosForClient, ":")
        local roadName = vecPosInfo[1]
        local roadID = tonumber(vecPosInfo[2]) + 1
        self.m_npcAlice:setVisible(true)
        self.m_npcAlice:setPosition(cc.pAdd(POS_ARRAY[roadName][roadID], cc.p(0, -15)))
        self.m_npcAlice:showAppear()

        local roadID = ROAD_NAME[roadName]
        self:findChild("Road_"..roadID):setVisible(true)
        self["road_"..roadID]:showRoadAnim()

        performWithDelay(self, function()
            self:showWheel()
        end, 1.5)
    end
end

function AliceMapLayer:wheelRotationOver(map, index)
    self.m_gameInfoMap = map
    local result = map.wheel[index]
    if result == 0 then
        self:updateMapUI(map)
    else
        self:closeMap()
    end
end

function AliceMapLayer:reconnetBonusGame(map, featureData) 
    self:updateLab(map)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self.m_gameInfoMap = map
    self:reconnectShowMap(function()
        gLobalSoundManager:playBgMusic("AliceSounds/music_bonus_game_bg.mp3")
        local bonusView = util_createView(BONUS_GAME_NAME[map.triggerGameName])
        if bonusView.initBonusBoard then
            bonusView:initBonusBoard(map.gameConfig)
        end
        if bonusView.initJackpot then
            bonusView:initJackpot(map.jackpot)
        end
        if bonusView.showGuideHand then
            bonusView:showGuideHand(function()
                self.m_guideIndex = 0
                gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_2_map.mp3")
                self.m_guideAction = schedule(self, function()
                    self:showGuideHand(self.m_guideIndex)
                end, 3)
            end)
        end
        
        bonusView:resetView(map.startPrize,  featureData, function()
            self.m_parent:updateGameIcon()
            gLobalSoundManager:playBgMusic("AliceSounds/music_Alice_map_bg.mp3")
            if map.triggerGameName == "castle" then
                local jackpot = self.m_gameInfoMap.jackpotB
                self.m_gameInfoMap = nil
                self:resetMapUI()
                self:resetBuilding()
                self.m_parent.m_bChooseGame = true
                if jackpot and jackpot > 0 then
                    self.m_labJackpot:setString(util_formatCoins(jackpot, 50))
                end
            else
                gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_2_map.mp3")
                performWithDelay(self, function()
                    self:showWheel()
                end, 2)
            end
        end)
        self:findChild("windows"):addChild(bonusView)
        bonusView:setPosition(-display.width * 0.5, -display.height * 0.5)
    end)
    
end

function AliceMapLayer:reconnetWheel(map)
    self:updateLab(map)
    gLobalSoundManager:playBgMusic("AliceSounds/music_Alice_map_bg.mp3")
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self.m_gameInfoMap = map
    self:reconnectShowMap(function()
        self:showWheel()
    end)
end

function AliceMapLayer:reconnectShowMap(func)
    self.m_btnBackGame:setEnabled(false)
    self:runCsbAction("start", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function AliceMapLayer:onEnter()

end

function AliceMapLayer:showAdd()
    
end
function AliceMapLayer:onExit()
 
end

--默认按钮监听回调
function AliceMapLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "tb_btn_wenhao" then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_map_click.mp3")
        if self.m_isShowNotice ~= true then
            self.m_isShowNotice = true
            self:runCsbAction("idle2") -- 播放时间线

            -- performWithDelay(self, function ()
            --     if self.m_isShowNotice == true then
            --         self.m_isShowNotice = false
            --         self:runCsbAction("over2", false, function()
            --             if self.m_isCanChoose == true then
            --                 self:runCsbAction("idle3", true)
            --             end
            --         end)
            --     end
            -- end, 5)
        else
            self.m_isShowNotice = false
            self:runCsbAction("over2", false, function()
                if self.m_isCanChoose == true then
                    self:runCsbAction("idle3", true)
                end
            end)
        end
        
    elseif name == "tb_btn" then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_map_click.mp3")
        self:closeMap()
    else
        if self.m_isCanChoose ~= true then
            return
        end
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_map_click.mp3")
        if self.m_guideAction ~= nil then
            self:stopAction(self.m_guideAction)
            self.m_guideAction = nil
        end
        if self.m_guideHand ~= nil then
            self.m_guideHand:removeFromParent()
            self.m_guideHand = nil
        end
        
        local data = {}
        data.name = name
        data.chooseCall = function()
            self.m_isChooseLayerRemove = true
            self.m_isCanChoose = false
            -- self["icon_"..name]:showLightIdle()
            self:openGameEffect()
            
        end
        data.closeCall = function()
            -- self:initIconBeforeGame()
            self:showGuideHand(self.m_guideIndex)
            self.m_guideAction = schedule(self, function()
                self:showGuideHand(self.m_guideIndex)
            end, 3)
        end
        data.clickOK = function()
            self:runCsbAction("idle")
        end
        local chooseView = util_createView("CodeAliceSrc.AliceMapChoose", data)
        gLobalViewManager:showUI(chooseView)
    end
end

function AliceMapLayer:closeMap()
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_map_disappear.mp3")
    self:runCsbAction("over", false, function()
        if self.m_backGameCall ~= nil then
            self.m_backGameCall()
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
        self:setVisible(false)
        self.m_parent:normalBgmControl()
    end)
end

function AliceMapLayer:updateLab(map)
    if map.jackpot ~= nil and map.jackpot > 0 then
        self.m_labJackpot:setString(util_formatCoins(map.jackpot, 50))
        self:updateLabelSize({label = self.m_labJackpot,sx = 0.7, sy = 0.7}, 344)
    end
    if map.startPrize ~= nil and map.startPrize > 0 then
        self.m_labStart:setString(util_formatCoins(map.startPrize, 50))
        self:updateLabelSize({label = self.m_labStart,sx = 0.7, sy = 0.7}, 344)
    end
end

return AliceMapLayer