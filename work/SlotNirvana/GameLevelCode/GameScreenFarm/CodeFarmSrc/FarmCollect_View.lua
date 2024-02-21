---
--xcyy
--2018年5月23日
--FarmCollect_View.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local FarmCollect_View = class("FarmBonus_View", BaseGame)
FarmCollect_View.m_landNodeList = {-1, -1, -1, -1, -1, -1, -1, -1}

FarmCollect_View.m_PageIndex = 1
FarmCollect_View.m_machine = nil
FarmCollect_View.m_bonusEndCall = nil

FarmCollect_View.m_netShopData = nil
FarmCollect_View.m_netPageIndex = 1

FarmCollect_View.m_isStart_Over_Action = false
FarmCollect_View.m_shopFreeGames = {15, 15, 15, 8}

FarmCollect_View.m_shopFreeGames = {15, 15, 15, 8}

FarmCollect_View.m_ClickIndex = 1

FarmCollect_View.m_MoveAction = false
FarmCollect_View.m_startAction = false

local getFs = 1
local getCoins = 2
local getBonus = 3

function FarmCollect_View:initUI(machine)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("Farm/HarvestBonus.csb", isAutoScale)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)

    self.m_baseX = self:findChild("all_di"):getPositionX()

    self.m_MoveAction = false

    self.m_machine = machine

    self.m_Collect_Barn = util_createView("CodeFarmSrc.FarmCollect_BarnView")
    self:findChild("gucang"):addChild(self.m_Collect_Barn)
    self.m_Collect_Barn:initMachine(self)

    self.m_Collect_Corn = util_createView("CodeFarmSrc.FarmCollect_CornView")
    self:findChild("yumizi"):addChild(self.m_Collect_Corn)
    self.m_Collect_Corn:findChild("m_lb_coins"):setString(util_formatCoins(self.m_machine.m_localCornNum, 6, nil, nil, true))
    self.m_Collect_Corn:updateLabelSize({label = self.m_Collect_Corn:findChild("m_lb_coins"), sx = 0.5, sy = 0.5}, 297)

    self.m_animalQipao = util_createView("CodeFarmSrc.FarmCollect_AnimalQiPaoView")
    self:findChild("qipao"):addChild(self.m_animalQipao)
    self.m_animalQipao:runCsbAction("show")
    performWithDelay(
        self.m_animalQipao,
        function()
            if self.m_animalQipao:isVisible() then
                self.m_animalQipao:runCsbAction(
                    "over",
                    false,
                    function()
                        self.m_animalQipao:setVisible(false)
                    end
                )
            end
        end,
        3
    )

    self:initNetShopData()

    self:initLittleLand()
    self:updateLittleLand()

    self:update_L_R_Botton_Visible()
    self:updatePageSign(self.m_PageIndex)
    local freespinTimes = self.m_shopFreeGames[self.m_PageIndex] or 15
    self:updateGetFreespinTimes(freespinTimes)
    self:updateAnimal(self.m_PageIndex, true)
    self:updateLittleTipReels()

    self.m_isStart_Over_Action = true

    gLobalSoundManager:playSound("FarmSounds/music_Farm_showshop.mp3")

    self:runCsbAction(
        "start",
        false,
        function()
            self.m_isStart_Over_Action = false

            self:runCsbAction("idle", true)
        end
    )
end

function FarmCollect_View:initNetShopData()
    local baseData = {
        shopFreeGames = {15, 15, 15, 8},
        shop = {
            {
                {score = 3500, index = 1, status = 0},
                {score = 3500, index = 2, status = 0},
                {score = 3500, index = 3, status = 0},
                {score = 3500, index = 4, status = 0},
                {score = 3500, index = 5, status = 0},
                {score = 3500, index = 6, status = 0},
                {score = 3500, index = 7, status = 0},
                {score = 3500, index = 8, status = 0}
            },
            {
                {score = 5000, index = 9, status = 0},
                {score = 5000, index = 10, status = 0},
                {score = 5000, index = 11, status = 0},
                {score = 5000, index = 12, status = 0},
                {score = 5000, index = 13, status = 0},
                {score = 5000, index = 14, status = 0},
                {score = 5000, index = 15, status = 0},
                {score = 5000, index = 16, status = 0}
            },
            {
                {score = 7000, index = 17, status = 0},
                {score = 7000, index = 18, status = 0},
                {score = 7000, index = 19, status = 0},
                {score = 7000, index = 20, status = 0},
                {score = 7000, index = 21, status = 0},
                {score = 7000, index = 22, status = 0},
                {score = 7000, index = 23, status = 0},
                {score = 7000, index = 24, status = 0}
            },
            {
                {score = 15000, index = 25, status = 0},
                {score = 15000, index = 26, status = 0},
                {score = 15000, index = 27, status = 0},
                {score = 15000, index = 28, status = 0},
                {score = 15000, index = 29, status = 0},
                {score = 15000, index = 30, status = 0},
                {score = 15000, index = 31, status = 0},
                {score = 15000, index = 32, status = 0}
            }
        },
        page = 1
    }

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or self.m_machine.m_runSpinResultData.p_shopExtra or baseData

    self.m_netShopData = selfdata.shop

    self.m_netPageIndex = selfdata.page
    self.m_PageIndex = selfdata.page

    self.m_machine.m_localCornNum = self.m_machine.m_localCornNum or 0 -- 玉米数
    self.m_shopFreeGames = selfdata.shopFreeGames

    self.m_ClickIndex = 1
end

function FarmCollect_View:updateNetShopData()
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}

    self.m_netShopData = selfdata.shop

    self.m_netPageIndex = selfdata.page

    self.m_machine.m_localCornNum = selfdata.collectScore or 0 -- 玉米数
end

function FarmCollect_View:updateGetFreespinTimes(times)
    self:findChild("font_fsTimes"):setString(times)
end

function FarmCollect_View:updatePageSign(num)
    self:findChild("fleld_font"):setString(num .. "/4")
end

function FarmCollect_View:updateAnimal(index, isinit)
    local childs = self:findChild("duibai"):getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if child then
            child:stopAllActions()
        end
    end
    self:findChild("duibai"):removeAllChildren()

    local animal = util_createView("CodeFarmSrc.FarmCollect_AnimalView", index)
    animal:setClickCall(
        function()
            self:showQIpao()
        end
    )
    self:findChild("duibai"):addChild(animal)
    animal:runCsbAction(
        "show",
        false,
        function()
        end
    )

    animal:animalSpeak(
        function()
        end
    )
end

function FarmCollect_View:initLittleLand()
    for i = 1, 8 do
        local ndoeName = "yimidi" .. i
        local land = util_createView("CodeFarmSrc.FarmCollect_LandView")
        self:findChild(ndoeName):addChild(land)
        self.m_landNodeList[i] = land
    end
end

function FarmCollect_View:updateLittleLand()
    -- 只作为 初始化 或者 翻页强制刷新使用
    local shopData = self.m_netShopData[self.m_PageIndex]

    for i = 1, #self.m_landNodeList do
        local land = self.m_landNodeList[i]

        local data = {}
        data.pos = i
        data.pageIndex = self.m_PageIndex
        data.state = shopData[i].status
        data.netIndex = self.m_netPageIndex
        data.netPos = shopData[i].index
        data.score = shopData[i].score
        data.buyType = shopData[i].buyType
        data.coins = shopData[i].coins
        data.view = self
        data.func = function(select, clickIndex)
            self.m_ClickIndex = clickIndex

            self:sendData(select)
        end
        land:setLandData(data)

        land:updateLandUI()
    end

    local freespinTimes = self.m_shopFreeGames[self.m_PageIndex] or 15
    self:findChild("font_fsTimes"):setString(freespinTimes)
end

-- function FarmCollect_View:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function FarmCollect_View:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function FarmCollect_View:checkAllBtnClickStates()
    local notClick = false

    if self.m_action == self.ACTION_SEND then
        notClick = true
    end

    if self.m_isStart_Over_Action then
        notClick = true
    end

    if self.m_MoveAction then
        notClick = true
    end

    return notClick
end

--默认按钮监听回调
function FarmCollect_View:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    if name == "Button_close" then
        -- 在清除一遍玉米
        self:closeUi()
    elseif name == "Button_R" then
        gLobalSoundManager:playSound("FarmSounds/music_Farm_click_Turn_page.mp3")

        self:movePageAction_R(
            function()
                self:updatePageIndex(-1)
                self:update_L_R_Botton_Visible()
                self:updateCollectView()
                self:updateLittleTipReels()
            end
        )
    elseif name == "Button_L" then
        gLobalSoundManager:playSound("FarmSounds/music_Farm_click_Turn_page.mp3")

        self:movePageAction_L(
            function()
                self:updatePageIndex(1)
                self:update_L_R_Botton_Visible()
                self:updateCollectView()
                self:updateLittleTipReels()
            end
        )
    end
end

function FarmCollect_View:updatePageIndex(time)
    local oldPageIndex = self.m_PageIndex
    self.m_PageIndex = self.m_PageIndex + time

    -- 容错处理
    if self.m_PageIndex < 1 or self.m_PageIndex > 4 then
        self.m_PageIndex = oldPageIndex
    end
end

function FarmCollect_View:update_L_R_Botton_Visible()
    if self.m_PageIndex == 4 then
        self:findChild("Button_L"):setVisible(false)
        self:findChild("Button_R"):setVisible(true)
    elseif self.m_PageIndex == 1 then
        self:findChild("Button_L"):setVisible(true)
        self:findChild("Button_R"):setVisible(false)
    else
        self:findChild("Button_L"):setVisible(true)
        self:findChild("Button_R"):setVisible(true)
    end
end

function FarmCollect_View:updateCollectView()
    self:updatePageSign(self.m_PageIndex)
    self:updateAnimal(self.m_PageIndex)
    self:updateLittleLand()

    local freespinTimes = self.m_shopFreeGames[self.m_PageIndex] or 15
    self:findChild("font_fsTimes"):setString(freespinTimes)
end

function FarmCollect_View:landRunClickedAct(pos, getType, func)
    for i = 1, #self.m_landNodeList do
        local land = self.m_landNodeList[i]
        if pos == i then
            if land then
                gLobalSoundManager:playSound("FarmSounds/music_Farm_di_Zhang.mp3")

                land:runCsbAction(
                    "animation0",
                    false,
                    function()
                        local actName1 = nil
                        local actName2 = nil

                        land:findChild("Node_coins_2"):setVisible(false)
                        land:findChild("Node_Bonuswin"):setVisible(false)

                        if getType == getCoins then
                            actName1 = "font"
                            actName2 = "font_over"
                            local wincoins = self.m_serverWinCoins or 0
                            land:findChild("Node_coins_2"):setVisible(true)
                            land:findChild("m_lb_coins_2"):setString(util_formatCoins(wincoins, 3, nil, nil, true))
                            land:updateLabelSize({label = land:findChild("m_lb_coins_2"), sx = 1, sy = 1}, 182)
                        elseif getType == getBonus then
                            land:findChild("Node_Bonuswin"):setVisible(true)
                            actName1 = "bounswin"
                            actName2 = "bounswin_over"
                        else
                            actName1 = "font"
                            actName2 = "font_over"
                            local wincoins = self.m_serverWinCoins or 0
                            land:findChild("Node_coins_2"):setVisible(true)
                            land:findChild("m_lb_coins_2"):setString(util_formatCoins(wincoins, 3, nil, nil, true))
                            land:updateLabelSize({label = land:findChild("m_lb_coins_2"), sx = 1, sy = 1}, 182)
                        end

                        land:runCsbAction(
                            actName1,
                            false,
                            function()
                                performWithDelay(
                                    self,
                                    function()
                                        -- land:runCsbAction(actName2,false,function(  )
                                        if func then
                                            func()
                                        end
                                        -- end)
                                    end,
                                    1
                                )
                            end
                        )
                    end
                )
            end
        end
    end
end

function FarmCollect_View:getShopCoins()
    -- 说明触发的是获得钱数

    local clickNode = self:findChild("yimidi" .. self.m_ClickIndex)
    local startPos = clickNode:getParent():convertToWorldSpace(cc.p(clickNode:getPosition()))
    local endPos = globalData.flyCoinsEndPos
    local baseCoins = globalData.topUICoinCount
    gLobalViewManager:pubPlayFlyCoin(
        startPos,
        endPos,
        baseCoins,
        self.m_serverWinCoins,
        function()
            performWithDelay(
                self,
                function()
                    self.m_action = self.ACTION_RECV
                end,
                1
            )
        end
    )
end

function FarmCollect_View:getFreeGame()
    -- 说明触发的 特殊玩法
    self.m_machine:checkCollectViewTriggerFeatures()
    self:closeUi(
        function()
            if self.m_machine.gameEffectRunPause then
                if self.m_machine.gameEffectRunIngPause then
                else
                    globalData.slotRunData.gameResumeFunc = nil
                end

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)

                if self.m_machine.gameEffectRunIngPause then
                else
                    self.m_machine:playGameEffect()
                end

                print(" 暂停了什么都不用做")
                self.m_machine.gameEffectRunPause = false
                self.m_machine.gameEffectRunIngPause = false
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)

                print(" 没有暂停回调 playeffect")
                self.m_machine:playGameEffect()

                self.m_machine.gameEffectRunPause = false
            end
        end
    )
end

function FarmCollect_View:getFsGameAndCoins()
    local clickNode = self:findChild("yimidi" .. self.m_ClickIndex)
    local startPos = clickNode:getParent():convertToWorldSpace(cc.p(clickNode:getPosition()))
    local endPos = globalData.flyCoinsEndPos
    local baseCoins = globalData.topUICoinCount

    gLobalViewManager:pubPlayFlyCoin(
        startPos,
        endPos,
        baseCoins,
        self.m_serverWinCoins,
        function()
            performWithDelay(
                self,
                function()
                    performWithDelay(
                        self,
                        function()
                            self:getFreeGame()
                        end,
                        1.5
                    )
                end,
                1
            )
        end
    )
end

--数据接收
function FarmCollect_View:recvBaseData(featureData)
    --数据赋值
    self:updateNetShopData()

    local getType = nil
    local featureDatas = self.m_machine.m_runSpinResultData.p_features
    if featureDatas and #featureDatas > 1 then
        if featureDatas[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
            getType = getFs
        else
            getType = getBonus
        end
    else
        getType = getCoins
    end

    self:landRunClickedAct(
        self.m_ClickIndex,
        getType,
        function()
            self:updateLittleLand()

            if getType == getCoins then
                self:getShopCoins()
            elseif getType == getFs then
                -- 说明的是先触发钱数 又触发freespin
                self:getFsGameAndCoins()
            else
                self.m_action = self.ACTION_RECV

                -- 说明触发的 特殊玩法
                self:getFreeGame()
            end
        end
    )

    self.m_Collect_Corn:findChild("m_lb_coins"):setString(util_formatCoins(self.m_machine.m_localCornNum, 6, nil, nil, true))
    self.m_Collect_Corn:updateLabelSize({label = self.m_Collect_Corn:findChild("m_lb_coins"), sx = 0.5, sy = 0.5}, 297)

end

--数据发送
function FarmCollect_View:sendData(pos)
    gLobalSoundManager:playSound("FarmSounds/music_Farm_click_di.mp3")

    self.m_action = self.ACTION_SEND

    self.m_animalQipao:stopAllActions()
    if self.m_animalQipao:isVisible() then
        self.m_animalQipao:runCsbAction(
            "over",
            false,
            function()
                self.m_animalQipao:setVisible(false)
            end
        )
    end

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil
    local shopPosData = {}
    shopPosData.pageCellIndex = pos

    messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = shopPosData}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function FarmCollect_View:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "SPECIAL" then
            self.m_spinDataResult = spinData.result

            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)

            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

--弹出结算奖励
function FarmCollect_View:showReward()
    --    if self.m_bonusEndCall then
    --         self.m_bonusEndCall()
    --    end
end

function FarmCollect_View:setEndCall(func)
    self.m_bonusEndCall = func
end

function FarmCollect_View:closeUi(func)
    self.m_machine:forceRefreshCorn()

    gLobalSoundManager:playSound("FarmSounds/music_Farm_closeshop.mp3")
    self.m_isStart_Over_Action = true
    self:runCsbAction(
        "over",
        false,
        function()
            self.m_isStart_Over_Action = false
            if func then
                func()
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
            end

            if self.m_bonusEndCall then
                self.m_bonusEndCall()
            end
        end
    )
end

function FarmCollect_View:updateLittleTipReels()
    local tipdata = {
        {reel = 2, row = 4, wildReels = {1, 3}},
        {reel = 3, row = 4, wildReels = {1, 3}},
        {reel = 3, row = 4, wildReels = {2, 3, 4}},
        {reel = 4, row = 4, wildReels = {1, 2, 3, 4}}
    }
    -- 创建tipreels
    local lunpanNode = self:findChild("lunpan")
    lunpanNode:removeAllChildren()

    if lunpanNode then
        -- lunpanNode:setScale(0.7)
        local selfdata = tipdata[self.m_PageIndex]
        local data = {}
        data.m_reelNum = selfdata.reel or 1
        data.m_reelRow = selfdata.row or 3
        data.m_wildCols = selfdata.wildReels or {}

        local m_ReelsTip = util_createView("CodeFarmSrc.FarmBonus_ReelsTipView", data)
        lunpanNode:addChild(m_ReelsTip)
        if data.m_reelNum == 2 then
            m_ReelsTip:setScale(0.9)
            m_ReelsTip:setPositionX(-21)
        end
    end
end

function FarmCollect_View:movePageAction_L(func)
    -- self.m_baseX
    util_setCascadeOpacityEnabledRescursion(self, true)

    self.m_MoveAction = true

    local actionList = {}
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            local actionList_1 = {}
            actionList_1[#actionList_1 + 1] = cc.FadeOut:create(0.3)
            local sq_1 = cc.Sequence:create(actionList_1)
            self:findChild("all_di"):runAction(sq_1)
        end
    )
    actionList[#actionList + 1] = cc.MoveTo:create(0.3, cc.p(self.m_baseX - 100, self:findChild("all_di"):getPositionY()))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if func then
                func()
            end
        end
    )
    -- actionList[#actionList + 1] = cc.DelayTime:create(0.2)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            self:findChild("all_di"):setPositionX(self.m_baseX + 100)

            local actionList_2 = {}
            actionList_2[#actionList_2 + 1] = cc.FadeIn:create(0.3)
            local sq_2 = cc.Sequence:create(actionList_2)
            self:findChild("all_di"):runAction(sq_2)
        end
    )
    actionList[#actionList + 1] = cc.MoveTo:create(0.3, cc.p(self.m_baseX, self:findChild("all_di"):getPositionY()))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            self.m_MoveAction = false
        end
    )

    local sq = cc.Sequence:create(actionList)

    self:findChild("all_di"):runAction(sq)
end

function FarmCollect_View:movePageAction_R(func)
    util_setCascadeOpacityEnabledRescursion(self, true)
    self.m_MoveAction = true

    local actionList = {}
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            local actionList_1 = {}
            actionList_1[#actionList_1 + 1] = cc.FadeOut:create(0.3)
            local sq_1 = cc.Sequence:create(actionList_1)
            self:findChild("all_di"):runAction(sq_1)
        end
    )
    actionList[#actionList + 1] = cc.MoveTo:create(0.3, cc.p(self.m_baseX + 100, self:findChild("all_di"):getPositionY()))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if func then
                func()
            end
        end
    )
    -- actionList[#actionList + 1] = cc.DelayTime:create(0)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            self:findChild("all_di"):setPositionX(self.m_baseX - 100)

            local actionList_2 = {}
            actionList_2[#actionList_2 + 1] = cc.FadeIn:create(0.3)
            local sq_2 = cc.Sequence:create(actionList_2)
            self:findChild("all_di"):runAction(sq_2)
        end
    )
    actionList[#actionList + 1] = cc.MoveTo:create(0.3, cc.p(self.m_baseX, self:findChild("all_di"):getPositionY()))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            self.m_MoveAction = false
        end
    )

    local sq = cc.Sequence:create(actionList)

    self:findChild("all_di"):runAction(sq)
end

function FarmCollect_View:showQIpao()
    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    if not self.m_animalQipao:isVisible() then
        self.m_animalQipao:setVisible(true)
        self.m_animalQipao:runCsbAction("show")
        performWithDelay(
            self.m_animalQipao,
            function()
                if self.m_animalQipao:isVisible() then
                    self.m_animalQipao:runCsbAction(
                        "over",
                        false,
                        function()
                            self.m_animalQipao:setVisible(false)
                        end
                    )
                end
            end,
            3
        )
    end
end

return FarmCollect_View
