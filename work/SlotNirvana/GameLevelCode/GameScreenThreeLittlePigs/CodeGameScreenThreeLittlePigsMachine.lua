local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenThreeLittlePigsMachine = class("CodeGameScreenThreeLittlePigsMachine", BaseFastMachine)

CodeGameScreenThreeLittlePigsMachine.SYMBOL_SCORE_10 = 9 -- 自定义的小块类型
CodeGameScreenThreeLittlePigsMachine.COLLECTZHUZHUCOIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 猪猪币收集
CodeGameScreenThreeLittlePigsMachine.CHANGEWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 高级图标变wild
CodeGameScreenThreeLittlePigsMachine.FREECHANGEWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- free下高级图标变wild
-- 构造函数
function CodeGameScreenThreeLittlePigsMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_isReconnection = false
    --是否重连
    self.m_houseTypeNum = 3
    --房子种类数量
    self.m_pigShopData = nil
    --商店的数据
    self.m_currSuperidx = 0
    --触发superfree的房子id，0时不是superfree
    self.m_clipNode = {}
    --存储提高层级的图标
    self.m_isReShowLine = false
    --商店关闭后是否重新播放连线
    self.m_showWinSoundId = nil
    --弹框弹出音效id
    self.m_isInSuperFreeEndWaiting = false
    --是否在superfree结束等待自动换房的时间里

    self.m_hummerAnimationOver = true

    self.m_isFeatureOverBigWinInFree = true
    --init
    self:initGame()
end

function CodeGameScreenThreeLittlePigsMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ThreeLittlePigsConfig.csv", "LevelThreeLittlePigsConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenThreeLittlePigsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ThreeLittlePigs"
end
--小块
function CodeGameScreenThreeLittlePigsMachine:getBaseReelGridNode()
    return "CodeThreeLittlePigsSrc.ThreeLittlePigsSlotsNode"
end

function CodeGameScreenThreeLittlePigsMachine:initUI()
    self.m_reelRunSound = "ThreeLittlePigsSounds/music_ThreeLittlePigs_quick_run.mp3"
    --快滚音效
    self:initFreeSpinBar()
    --添加背景遮罩
    self.m_bgTranslucentMask = util_createAnimation("ThreeLittlePigs/GameScreenThreeLittlePigsBg_0.csb")
    self:findChild("gameBg"):addChild(self.m_bgTranslucentMask, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
    self.m_bgTranslucentMask:setVisible(false)
    --添加大角色
    self.m_dajuese = util_spineCreate("ThreeLittlePigs_lang_dajuese", true, true)
    self:findChild("fg_logo"):addChild(self.m_dajuese)
    self:findChild("fg_logo"):setVisible(false)
    self.m_dajuese:setAnimation(0, "idleframe", true)
    --添加过场
    self.m_guochang1 = util_spineCreate("Socre_ThreeLittlePigs_guochang", true, true)
    self:addChild(self.m_guochang1, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
    self.m_guochang1:setScale(self.m_machineRootScale)
    local worldPos = self:findChild("guochangNode"):convertToWorldSpace(cc.p(0, 0))
    local pos = self:convertToNodeSpace(worldPos)
    self.m_guochang1:setPosition(cc.p(display.right, pos.y))
    self.m_guochang1:setVisible(false)

    self.m_guochang2 = util_createAnimation("ThreeLittlePigs_guochang.csb")
    self:addChild(self.m_guochang2, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
    self.m_guochang2:setScale(self.m_machineRootScale)
    self.m_guochang2:setPosition(display.center)
    self.m_guochang2:setVisible(false)

    self.m_guochang3 = util_spineCreate("Socre_ThreeLittlePigs_fanchang", true, true)
    self:addChild(self.m_guochang3, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
    self.m_guochang3:setScale(self.m_machineRootScale)
    self.m_guochang3:setPosition(display.right_center)
    self.m_guochang3:setVisible(false)
    --添加进度条
    self.m_littleLogoProgressNode = util_createAnimation("ThreeLittlePigs_LittleLogo_progress.csb")
    self:findChild("LittleLogo_progress"):addChild(self.m_littleLogoProgressNode)

    --添加三个小房子logo
    self.m_littleLogoTab = {}
    for i = 1, self.m_houseTypeNum do
        local littleLogo = util_createAnimation("ThreeLittlePigs_LittleLogo_" .. i .. ".csb")
        self:findChild("LittleLogo_" .. i):addChild(littleLogo)
        table.insert(self.m_littleLogoTab, littleLogo)
        littleLogo.state = 1
        --小房子logo状态，1为锁定，2为解锁，3为盖完
        self:addClick(littleLogo:findChild("wu" .. i .. "_click"))

        local tip = util_createAnimation("ThreeLittlePigs_LittleLogo_" .. i .. "_tip.csb")
        littleLogo:findChild("tip"):addChild(tip)
        tip:setVisible(false)
        littleLogo.m_tip = tip
        tip.isClosing = false
        --是否正在关闭
    end

    --添加三种房子
    self.m_housePageView = ccui.PageView:create()
    self.m_housePageView:setAnchorPoint(cc.p(0.5, 0))
    local worldPos = self:findChild("houseView"):getParent():convertToWorldSpace(cc.p(self:findChild("houseView"):getPosition()))
    local pos = self:convertToNodeSpace(worldPos)
    local height = (display.height - pos.y) / self.m_machineRootScale
    local width = math.max(display.width, 1300)
    self.m_housePageView:setContentSize(width, height)
    self:findChild("houseView"):addChild(self.m_housePageView)

    self.m_houseNodeTab = {}
    for i = 1, self.m_houseTypeNum do
        local layout = ccui.Layout:create()
        layout:setContentSize(cc.size(width, height))
        layout:setPosition(0, 0)
        self.m_housePageView:addPage(layout)

        local house = util_createAnimation("ThreeLittlePigs_wu" .. i .. ".csb")
        layout:addChild(house)
        local worldPos1 = self:findChild("house"):getParent():convertToWorldSpace(cc.p(self:findChild("house"):getPosition()))
        local pos1 = layout:convertToNodeSpace(worldPos1)
        house:setPosition(pos1)

        table.insert(self.m_houseNodeTab, house)
        --添加房子旁边的猪
        local zhu = util_spineCreate("Socre_ThreeLittlePigs_dajuese_zhu" .. i, true, true)
        house:findChild("Node_zhu"):addChild(zhu)
        house.m_zhu = zhu
        util_spinePlay(zhu, "idleframe", true)
        --添加盖房子的猪
        local gaizhu1 = util_spineCreate("Socre_ThreeLittlePigs_dajuese_zhu" .. i, true, true)
        house:findChild("Node_gaizhu_1"):addChild(gaizhu1)
        util_spinePlay(gaizhu1, "jianzao", true)

        local gaizhu2 = util_spineCreate("Socre_ThreeLittlePigs_dajuese_zhu" .. i, true, true)
        house:findChild("Node_gaizhu_2"):addChild(gaizhu2)
        util_spinePlay(gaizhu2, "jianzao", true)

        --添加房子logo
        local logo = util_createAnimation("ThreeLittlePigs_wu_logo.csb")
        house:findChild("logo"):addChild(logo)
        house.m_logo = logo
        logo:setVisible(false)
    end

    self.m_currChooseHouseIdx = gLobalDataManager:getNumberByField("ThreeLittlePigs_chooseHouseIdx", 1)
    self:chooseHouse(self.m_currChooseHouseIdx)
    self.m_housePageView:setCurrentPageIndex(self.m_currChooseHouseIdx - 1)

    --添加钱币显示条
    self.m_xiaozhuCoinCollectBar = util_createAnimation("ThreeLittlePigs_progress.csb")
    self:findChild("progress"):addChild(self.m_xiaozhuCoinCollectBar)
    -- self:addClick(self.m_xiaozhuCoinCollectBar:findChild("progress_tip"))
    self:addClick(self.m_xiaozhuCoinCollectBar:findChild("shangdian"))
    self.m_xiaozhuCoinCollectBar:playAction("idleframe", true)

    -- 添加锤子

    self.m_hammer = util_createAnimation("ThreeLittlePigs_progress_chuizi.csb")
    self.m_xiaozhuCoinCollectBar:findChild("Node_logo"):addChild(self.m_hammer)
    self.m_hammer:runCsbAction("idleframe1", true)

    -- 默认锤子颜色为银色
    self.m_hammerStatus = "silvery"

    --添加手
    local shou = util_createAnimation("ThreeLittlePigs_shangdian_shou.csb")
    self.m_xiaozhuCoinCollectBar:findChild("shouzhiNode"):addChild(shou)
    shou:playAction("actionframe", true)
    shou:setVisible(false)
    self.m_xiaozhuCoinCollectBar.m_shou = shou
    --添加钱币条上的tip
    -- self.m_xiaozhuCoinCollectBarTip = util_createAnimation("ThreeLittlePigs_progress_tip.csb")
    -- self.m_xiaozhuCoinCollectBar:findChild("progress_tip"):addChild(self.m_xiaozhuCoinCollectBarTip)
    -- self.m_xiaozhuCoinCollectBarTip:setVisible(false)
    --半透明遮罩初始化
    self:findChild("lunpanzhezhao"):setVisible(false)
    self:findChild("lunpanzhezhao"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)

    self.m_housePageView.isCallEvent = true
    --housepage事件是否生效
    self.m_housePageView:onEvent(
        function(event)
            if event.name == "TURNING" then
                if self.m_housePageView.isCallEvent == true then
                    self:updateHummerStatus(self.m_housePageView:getCurrentPageIndex() + 1)
                    if self.m_pigShopData.round == 1 then
                        if self.m_shopView then
                            gLobalDataManager:setNumberByField("ThreeLittlePigs_chooseHouseIdx", self.m_housePageView:getCurrentPageIndex() + 1, true)
                        end
                    else
                        gLobalDataManager:setNumberByField("ThreeLittlePigs_chooseHouseIdx", self.m_housePageView:getCurrentPageIndex() + 1, true)
                    end
                    if self.m_shopView then
                        self.m_shopView:setPageIndex(self.m_housePageView:getCurrentPageIndex() + 1, false, false)
                    end
                    --这里晚一些开启可购买，直接开启还是可能点到上一页的按钮导致出现错误
                    local node = cc.Node:create()
                    self:addChild(node)
                    performWithDelay(
                        node,
                        function()
                            gLobalNoticManager:postNotification("ThreeLittlePigsShopView_setIsCanBuy", {true})
                            node:removeFromParent()
                        end,
                        0.05
                    )
                end
                self.m_housePageView.isCallEvent = true
            end
        end
    )
    self.m_housePageView:onTouch(
        function(event)
            if event.name == "began" then
                gLobalNoticManager:postNotification("ThreeLittlePigsShopView_setIsCanBuy", {false})
            end
            if event.name == "ended" or event.name == "cancelled" then
                self.m_housePageView.isCallEvent = true
                gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_chooseHouse.mp3")
            end
        end
    )

    self:runCsbAction("normal")
    self.m_gameBg:runCsbAction("base", true)
end
-- 重置当前背景音乐名称
function CodeGameScreenThreeLittlePigsMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_currSuperidx > 0 then
            self.m_currentMusicBgName = "ThreeLittlePigsSounds/music_ThreeLittlePigs_superFreespinBG.mp3"
        else
            self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        end
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end
function CodeGameScreenThreeLittlePigsMachine:initFreeSpinBar()
    --添加普通free的次数条
    self.m_baseFreeSpinBar = util_createView("CodeThreeLittlePigsSrc.ThreeLittlePigsFreespinBarView", 1)
    self:findChild("FreeSpinNum"):addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    --添加superfree的次数条
    self.m_superFreeBar = util_createView("CodeThreeLittlePigsSrc.ThreeLittlePigsFreespinBarView", 2)
    self:findChild("SuperFreeSpinNum"):addChild(self.m_superFreeBar)
    util_setCsbVisible(self.m_superFreeBar, false)
end
--设置进度条
function CodeGameScreenThreeLittlePigsMachine:setLittleLogoProgress(completeHouseNum, isPlayAction)
    if isPlayAction == false or completeHouseNum == 0 then
        self.m_littleLogoProgressNode:playAction("idleframe" .. completeHouseNum, true)
    else
        self.m_littleLogoProgressNode:playAction(
            "actionframe" .. completeHouseNum,
            false,
            function()
                self.m_littleLogoProgressNode:playAction("idleframe" .. completeHouseNum, true)
            end
        )
        gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_completeHouseNumChangeProgress.mp3")
    end
end
--设置三个小房子logo的状态
function CodeGameScreenThreeLittlePigsMachine:setLittleLogoState()
    local pigShopData = self:getPigShopData()
    local completeHouseNum = 0
    if pigShopData then
        --有数据
        for i, littleLogo in ipairs(self.m_littleLogoTab) do
            if pigShopData.levels[i].finish then
                littleLogo.state = 3
                completeHouseNum = completeHouseNum + 1
            elseif pigShopData.levels[i].unlock then
                littleLogo.state = 2
            end
            if pigShopData.round > 1 then
                littleLogo.state = 3
            end
            littleLogo:playAction("idleframe" .. littleLogo.state, true)
        end
    end
    if pigShopData.round > 1 then
        completeHouseNum = self.m_houseTypeNum
    end
    self:setLittleLogoProgress(completeHouseNum, false)
end
--改变三个小房子logo的状态
function CodeGameScreenThreeLittlePigsMachine:changeLittleLogoState()
    local pigShopData = self:getPigShopData()
    local completeHouseNum = 0
    local state = 0
    if pigShopData then
        --有数据
        for i, littleLogo in ipairs(self.m_littleLogoTab) do
            if pigShopData.levels[i].finish then
                completeHouseNum = completeHouseNum + 1
                state = 3
            elseif pigShopData.levels[i].unlock then
                state = 2
            else
                state = 1
            end
            if pigShopData.round > 1 then
                state = 3
            end
            if littleLogo.state ~= state then
                littleLogo.state = state
                if littleLogo.state == 1 then
                    littleLogo:playAction("idleframe" .. littleLogo.state, true)
                else
                    littleLogo:playAction(
                        "actionframe" .. littleLogo.state,
                        false,
                        function()
                            littleLogo:playAction("idleframe" .. littleLogo.state, true)
                        end
                    )
                end
            end
        end
    end
    local isPlayAction = true
    if pigShopData.round > 1 then
        completeHouseNum = self.m_houseTypeNum
        isPlayAction = false
    end
    self:setLittleLogoProgress(completeHouseNum, isPlayAction)
end
--弹出小房子logo上的tip框
function CodeGameScreenThreeLittlePigsMachine:showLittleLogoTip(littleLogoIdx)
    if littleLogoIdx == nil then
        for i, littleLogo in ipairs(self.m_littleLogoTab) do
            if littleLogo.state == 2 then
                littleLogoIdx = i
                break
            end
        end
    end
    local littleLogo = self.m_littleLogoTab[littleLogoIdx]
    if littleLogo then
        if littleLogo.state <= 2 and littleLogo.m_tip:isVisible() == false then
            littleLogo.m_tip:setVisible(true)
            littleLogo.m_tip:playAction(
                "start",
                false,
                function()
                    littleLogo.m_tip:playAction("idle", true)
                    performWithDelay(
                        littleLogo.m_tip,
                        function()
                            self:hideLittleLogoTip(littleLogoIdx)
                        end,
                        3
                    )
                end
            )
        end
    end
end
--隐藏小房子logo上的tip框
function CodeGameScreenThreeLittlePigsMachine:hideLittleLogoTip(littleLogoIdx)
    if littleLogoIdx == nil then
        for i, littleLogo in ipairs(self.m_littleLogoTab) do
            if littleLogo.m_tip:isVisible() == true and littleLogo.m_tip.isClosing == false then
                littleLogoIdx = i
                break
            end
        end
    end

    local littleLogo = self.m_littleLogoTab[littleLogoIdx]
    if littleLogo then
        if littleLogo.m_tip:isVisible() == true and littleLogo.m_tip.isClosing == false then
            littleLogo.m_tip.isClosing = true
            littleLogo.m_tip:playAction(
                "over",
                false,
                function()
                    littleLogo.m_tip.isClosing = false
                    littleLogo.m_tip:setVisible(false)
                end
            )
        end
    end
end
--设置猪猪币的数量
function CodeGameScreenThreeLittlePigsMachine:setXiaozhuCoin(isPlayAni, coinNum)
    if isPlayAni == nil then
        isPlayAni = false
    end
    local num = 0
    if coinNum then
        num = coinNum
    else
        local pigShopData = self:getPigShopData()
        if pigShopData then
            num = pigShopData.scoreTotal
        end
    end

    self.m_xiaozhuCoinCollectBar:findChild("m_lb_coins"):setString(num)
    if isPlayAni then
        self.m_xiaozhuCoinCollectBar:findChild("Particle_1"):resetSystem()
        self.m_xiaozhuCoinCollectBar:playAction(
            "actionframe",
            false,
            function()
                self.m_xiaozhuCoinCollectBar:playAction("idleframe", true)
            end
        )
    end

    local isShowShop = gLobalDataManager:getBoolByField("ThreeLittlePigs_isShowShop", false)
    if isShowShop == false and num >= self:getPigShopData().scoreLimit[1] then
        self.m_xiaozhuCoinCollectBar.m_shou:setVisible(true)
    end
end
--显示tips
function CodeGameScreenThreeLittlePigsMachine:showXiaozhuCoinCollectBarTip()
    if self.m_xiaozhuCoinCollectBarTip:isVisible() == false then
        self.m_xiaozhuCoinCollectBarTip:setVisible(true)
        self.m_xiaozhuCoinCollectBarTip:playAction("show")
        performWithDelay(
            self,
            function()
                self:hideXiaozhuCoinCollectBarTip()
            end,
            2.5
        )
    end
end
--隐藏tips
function CodeGameScreenThreeLittlePigsMachine:hideXiaozhuCoinCollectBarTip()
    if self.m_xiaozhuCoinCollectBarTip then
        if self.m_xiaozhuCoinCollectBarTip:isVisible() == true then
            self.m_xiaozhuCoinCollectBarTip:playAction(
                "over",
                false,
                function()
                    self.m_xiaozhuCoinCollectBarTip:setVisible(false)
                end
            )
        end
    end
end
--更新所有房子
function CodeGameScreenThreeLittlePigsMachine:updateHouse()
    for i = 1, self.m_houseTypeNum do
        self:updateOneHouse(i)
    end
end
--获取当前房子的建造进度
function CodeGameScreenThreeLittlePigsMachine:getHouseBuildProgress(houseIdx)
    local houseConstructionProgress = 1
    --房子建造进度
    local pigShopData = self:getPigShopData()
    if pigShopData then
        local cards = pigShopData.levels[houseIdx].cards
        for i, goodsData in ipairs(cards) do
            if goodsData.purchase == false then
                break
            end
            houseConstructionProgress = i + 1
        end
    end
    return houseConstructionProgress
end
--更新某一个房子   isPlayBuild是否播放建造动画
function CodeGameScreenThreeLittlePigsMachine:updateOneHouse(houseIdx, isPlayBuild, func)
    if isPlayBuild == nil then
        isPlayBuild = false
    end
    local house = self.m_houseNodeTab[houseIdx]
    local houseConstructionProgress = self:getHouseBuildProgress(houseIdx)
    --房子建造进度
    if isPlayBuild then
        gLobalNoticManager:postNotification("ThreeLittlePigsShopView_updateBuyGoods", {houseConstructionProgress - 1})
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_buildHouse.mp3")
                house:playAction(
                    "actionframe" .. houseConstructionProgress,
                    false,
                    function()
                        if houseConstructionProgress > #self.m_pigShopData.levels[houseIdx].cards then
                            if house:findChild("Particle_1") then
                                house:findChild("Particle_1"):setPositionType(0)
                                house:findChild("Particle_1"):resetSystem()
                            end
                            if house:findChild("Particle_2") then
                                house:findChild("Particle_2"):setPositionType(0)
                                house:findChild("Particle_2"):resetSystem()
                            end
                            gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_buildHouseComplete.mp3")
                            util_spinePlay(house.m_zhu, "kaixin", true)
                            house:playAction(
                                "complete",
                                false,
                                function()
                                    --房子盖完回调
                                    if func then
                                        func()
                                    end
                                    house:playAction("idleframe" .. houseConstructionProgress, true)
                                    if house:findChild("Particle_3") then
                                        house:findChild("Particle_3"):setPositionType(0)
                                        house:findChild("Particle_3"):resetSystem()
                                    end
                                end
                            )
                            self.m_gameBg:runCsbAction(
                                "base_super",
                                false,
                                function()
                                    self.m_gameBg:runCsbAction("super_idle", true)
                                end
                            )
                            house.m_logo:setVisible(true)
                            house.m_logo:playAction(
                                "start",
                                false,
                                function()
                                    house.m_logo:playAction("idle", true)
                                end
                            )
                        else
                            house:playAction("idleframe" .. houseConstructionProgress, true)
                            --房子盖完回调
                            if func then
                                func()
                            end
                        end
                    end
                )
            end,
            25 / 60
        )
    else
        house:playAction("idleframe" .. houseConstructionProgress, true)
        util_spinePlay(house.m_zhu, "idleframe", true)
        if houseConstructionProgress > #self.m_pigShopData.levels[houseIdx].cards then
            util_spinePlay(house.m_zhu, "kaixin", true)
            if house:findChild("Particle_3") then
                house:findChild("Particle_3"):setPositionType(0)
                house:findChild("Particle_3"):resetSystem()
            end
        end
    end
end
--选择房子
function CodeGameScreenThreeLittlePigsMachine:chooseHouse(houseIdx)
    if houseIdx == nil then
        return
    end
    -- for i,houseNode in ipairs(self.m_houseNodeTab) do
    --     if i == houseIdx then
    --         houseNode:setVisible(true)
    --     else
    --         houseNode:setVisible(false)
    --     end
    -- end
    self.m_housePageView.isCallEvent = false
    if self.m_housePageView:getCurrentPageIndex() ~= (houseIdx - 1) then
        gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_chooseHouse.mp3")
    end
    self.m_housePageView:scrollToItem(houseIdx - 1)
end

function CodeGameScreenThreeLittlePigsMachine:clickFunc(sender)
    if self.m_hummerAnimationOver == false then
        return
    end

    local name = sender:getName()
    if name == "progress_tip" then
        if self.m_bottomUI.m_btn_add:isTouchEnabled() == true and self.m_shopView == nil then
            --弹出说明框
            self:showXiaozhuCoinCollectBarTip()
        end
    elseif name == "shangdian" then
        if self.m_isInSuperFreeEndWaiting == false and (self.m_bottomUI.m_btn_add:isTouchEnabled() == true or self.m_shopView) then
            local pigShopData = self:getPigShopData()
            -- local levelsInfo = pigShopData.levels
            --判断是否全部完成
            local isAllFinished = pigShopData.round > 1
            local houseIndex = self.m_currChooseHouseIdx
            if isAllFinished then
                -- for index = 1,3 do
                --     if pigShopData.scoreTotal >= pigShopData.scoreLimit[index] then
                --         houseIndex = index
                --         break
                --     end
                -- end
                houseIndex = self.m_housePageView:getCurrentPageIndex() + 1
            end

            if self.m_shopView == nil then
                --弹出商店框
                if self.m_xiaozhuCoinCollectBar.m_shou:isVisible() then
                    self.m_xiaozhuCoinCollectBar.m_shou:setVisible(false)
                    gLobalDataManager:setBoolByField("ThreeLittlePigs_isShowShop", true)
                end
                if self.m_winSoundsId then
                    gLobalSoundManager:stopAudio(self.m_winSoundsId)
                    self.m_winSoundsId = nil
                end
                -- self:removeSoundHandler()
                self:showShopView()

                self:updateHummerStatus(houseIndex)
            else
                --关闭商店框
                self:closeShopView()
                self:updateHummerStatus(houseIndex)
            end
        end
    elseif string.match(name, "wu%d_click") ~= nil then
        local index = tonumber(string.match(name, "%d"))
        if index == self.m_level then
            return
        end

        self:chooseHouse(index)
        self.m_housePageView.isCallEvent = true
        gLobalNoticManager:postNotification("ThreeLittlePigsShopView_setIsCanBuy", {false})
        if self.m_littleLogoTab[index].m_tip:isVisible() then
            self:hideLittleLogoTip(index)
        else
            self:hideLittleLogoTip()
            self:showLittleLogoTip(index)
        end
        self:updateHummerStatus(index)
        self.m_level = index
    end
end
--适配
function CodeGameScreenThreeLittlePigsMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize() --h 120
    local uiBW, uiBH = self.m_bottomUI:getUISize() --h 180
    --看资源实际的高度
    uiH = 120
    uiBH = 180

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1

    if display.height / display.width == DESIGN_SIZE.height / DESIGN_SIZE.width then
        --设计尺寸屏
    elseif display.height / display.width > DESIGN_SIZE.height / DESIGN_SIZE.width then
        --高屏
        local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale < wScale then
            mainScale = hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end
    else
        --宽屏
        local topAoH = 0
        --顶部条凹下去距离 在宽屏中会被用的尺寸(设计尺寸下没用的)
        local bottomMoveH = 0
        --底部空间尺寸，最后要下移距离
        local hScale1 = (mainHeight + topAoH) / (mainHeight + topAoH - bottomMoveH)
        --有效区域尺寸改变适配
        local hScale = (mainHeight + topAoH) / (DESIGN_SIZE.height - uiH - uiBH + topAoH)
        --有效区域屏幕适配
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale1 * hScale < wScale then
            mainScale = hScale1 * hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end

        local designDis = (DESIGN_SIZE.height / 2 - uiBH) * mainScale
        --设计离下条距离
        local dis = (display.height / 2 - uiBH)
        --实际离下条距离
        local move = designDis - dis
        --宽屏下轮盘跟底部条更接近，实际整体下移了
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + move - bottomMoveH)
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end
function CodeGameScreenThreeLittlePigsMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.isInBonus then
                        self:resetMusicBg()
                    end
                    self:reelsDownDelaySetMusicBGVolume()
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end
function CodeGameScreenThreeLittlePigsMachine:updateReelGridNode(node)
    if node:isLastSymbol() then
        if self.m_isReconnection then
            --重连不显示收集的图标
            return
        end
        self:addItemToSymbol(node, node.p_rowIndex, node.p_cloumnIndex)
    end
    if self.m_currSuperidx > 0 then
        local isChange = false
        if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
            isChange = true
        end
        if self.m_currSuperidx > 1 then
            if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
                isChange = true
            end
        end
        if self.m_currSuperidx > 2 then
            if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                isChange = true
            end
        end

        if isChange then
            node:runAnim("idleframe_jin")
            node:setLineAnimName("actionframe_jin")
            node:setIdleAnimName("idleframe_jin")
            if node.p_symbolImage ~= nil and node.p_symbolImage:getParent() ~= nil then
                node.p_symbolImage:removeFromParent()
                node.p_symbolImage = nil
            end
        end
    end
end

--在信号块上添加收集图标
function CodeGameScreenThreeLittlePigsMachine:addItemToSymbol(node, irow, icol)
    local reelsIndex = self:getPosReelIdx(irow, icol)
    local isHave, num = self:getSymbolIcon(reelsIndex)
    if isHave then
        if node.m_icon == nil then
            node.m_icon = util_createAnimation("ThreeLittlePigs_symbolCoin.csb")
            node.m_icon:findChild("num"):setString(num)
            node.m_icon:setPosition(cc.p(35, -35))
            node:addChild(node.m_icon, 2)
        end
    end
end
--获取某个位置是否有猪猪币数据
function CodeGameScreenThreeLittlePigsMachine:getSymbolIcon(pos)
    local isHave = false
    local num = 0
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.scorePositions then
        local posTable = self.m_runSpinResultData.p_selfMakeData.scorePositions
        for posStr, coinNum in pairs(posTable) do
            local index = tonumber(posStr)
            if pos == index then
                isHave = true
                num = coinNum
            end
        end
    end
    return isHave, num
end
function CodeGameScreenThreeLittlePigsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)
    self:addObservers()

    self:setLittleLogoState()
    self:showLittleLogoTip()
    self:setXiaozhuCoin()
    self:updateHouse()
    if self.m_currSuperidx > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
        --super触发轮
        self.m_gameBg:runCsbAction("super_idle", true)
        self.m_houseNodeTab[self.m_currSuperidx].m_logo:setVisible(true)
        self.m_houseNodeTab[self.m_currSuperidx].m_logo:playAction("idle", true)
    end
end

function CodeGameScreenThreeLittlePigsMachine:addObservers()
    BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.m_bIsBigWin then
                if not (self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == 0) then
                    return
                end
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 2
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 3
            else
                soundIndex = 3
                soundTime = 3
            end

            local soundName = "ThreeLittlePigsSounds/music_ThreeLittlePigs_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:closeShopView()
        end,
        "CodeGameScreenThreeLittlePigsMachine_closeShopView"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:closeShopViewEnd()
        end,
        "CodeGameScreenThreeLittlePigsMachine_closeShopViewEnd"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:chooseHouse(params[1])
        end,
        "CodeGameScreenThreeLittlePigsMachine_chooseHouse"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:buySuccessUpdate(params[1])
        end,
        "CodeGameScreenThreeLittlePigsMachine_buySuccessUpdate"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setShangdianTouchEnabled(params[1])
        end,
        "CodeGameScreenThreeLittlePigsMachine_setShangdianTouchEnabled"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setHousePageViewTouchEnabled(globalData.betFlag)
        end,
        "BET_ENABLE"
    )
end

function CodeGameScreenThreeLittlePigsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenThreeLittlePigsMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_ThreeLittlePigs_10"
    end
    return nil
end

function CodeGameScreenThreeLittlePigsMachine:initGameStatusData(gameData)
    if gameData.gameConfig and gameData.gameConfig.init and gameData.gameConfig.init.pigShop then
        self.m_pigShopData = gameData.gameConfig.init.pigShop
    end

    --将special 跟spin合并 并删除special
    if gameData.special then
        if not gameData.spin then
            gameData.spin = {}
        end
        table_merge(gameData.spin, gameData.special)
        gameData.special = nil
    end
    CodeGameScreenThreeLittlePigsMachine.super.initGameStatusData(self, gameData)

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.triggerSuperFree then
        self.m_currSuperidx = self.m_runSpinResultData.p_selfMakeData.triggerSuperFree
        self.m_configData.m_curSuperFreeIdx = self.m_currSuperidx
    end
end
function CodeGameScreenThreeLittlePigsMachine:MachineRule_afterNetWorkLineLogicCalculate()
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.pigShop then
        self.m_pigShopData = self.m_runSpinResultData.p_selfMakeData.pigShop
    end
end
-- 获取商店数据
function CodeGameScreenThreeLittlePigsMachine:getPigShopData()
    return self.m_pigShopData
end
-- 断线重连
function CodeGameScreenThreeLittlePigsMachine:MachineRule_initGame()
    self.m_isReconnection = true
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_currSuperidx > 0 then
            self.m_gameBg:runCsbAction("super_idle", true)
            self:hideFreeSpinBar()
        end
    end
    if self.m_currSuperidx > 0 then
        self:chooseHouse(self.m_currSuperidx)
    else
        self:roundOneChooseHouse()
    end
    self:updateHummerStatus(self.m_currChooseHouseIdx)
end
--第一轮里选择房子
function CodeGameScreenThreeLittlePigsMachine:roundOneChooseHouse()
    if self.m_pigShopData.round == 1 then
        for i = 1, #self.m_pigShopData.levels do
            if self.m_pigShopData.levels[i].unlock == true and self.m_pigShopData.levels[i].finish == false then
                self:chooseHouse(i)
                gLobalDataManager:setNumberByField("ThreeLittlePigs_chooseHouseIdx", i, true)
                break
            end
        end
    end
end
--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
]]
function CodeGameScreenThreeLittlePigsMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "ThreeLittlePigsSounds/music_ThreeLittlePigs_Scatterbuling" .. i .. ".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
--所有滚轴停止调用
function CodeGameScreenThreeLittlePigsMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    CodeGameScreenThreeLittlePigsMachine.super.slotReelDown(self)
end
--
--单列滚动停止回调
--
function CodeGameScreenThreeLittlePigsMachine:slotOneReelDown(reelCol)
    CodeGameScreenThreeLittlePigsMachine.super.slotOneReelDown(self, reelCol)
    local sound = {scatter = 0, wild = 0}
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if targSp and targSp.p_symbolType then
            if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                targSp:runAnim("buling")
                sound.wild = 1
            elseif targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if self:isPlayTipAnima(targSp.p_cloumnIndex, targSp.p_rowIndex, targSp) == true then
                    self:setSymbolToClip(targSp)
                    targSp:runAnim("buling", false)
                    self:playScatterBonusSound(targSp)
                    sound.scatter = 1
                end
            end
        end
    end
    if sound.scatter == 0 and sound.wild == 1 then
        local soundPath = "ThreeLittlePigsSounds/music_ThreeLittlePigs_wildBuling.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds(reelCol, soundPath)
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
end

--将图标提到clipParent层
function CodeGameScreenThreeLittlePigsMachine:setSymbolToClip(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = slotNode:getPositionY()
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX, slotNode.m_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex * 10)
    self.m_clipNode[#self.m_clipNode + 1] = slotNode

    local linePos = {}
    linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
    slotNode:setLinePos(linePos)
end
--将图标恢复到轮盘层
function CodeGameScreenThreeLittlePigsMachine:setSymbolToReel()
    for i, slotNode in ipairs(self.m_clipNode) do
        local preParent = slotNode.m_preParent
        if preParent ~= nil then
            slotNode.p_layerTag = slotNode.m_preLayerTag

            local nZOrder = slotNode.m_showOrder
            nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.m_showOrder

            util_changeNodeParent(preParent, slotNode, nZOrder)
            slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)
            slotNode:runIdleAnim()
        end
    end
    self.m_clipNode = {}
end

-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenThreeLittlePigsMachine:levelFreeSpinEffectChange()
    self:runCsbAction("freespin")
    self.m_littleLogoProgressNode:setVisible(false)
    for i, littleLogo in ipairs(self.m_littleLogoTab) do
        littleLogo:setVisible(false)
    end
    self:findChild("progress"):setVisible(false)
    if self.m_currSuperidx == 0 then
        self.m_gameBg:findChild("Particle_7"):setPositionType(0)
        self.m_gameBg:findChild("Particle_7"):resetSystem()

        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"free", true})
        self:findChild("houseView"):setVisible(false)
        self:findChild("fg_logo"):setVisible(true)
    else
        self.m_gameBg:findChild("Particle_1"):setPositionType(0)
        self.m_gameBg:findChild("Particle_1"):resetSystem()
        -- self.m_gameBg:runCsbAction("supchufa_superfree",false,function ()
        --     gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"superfree",true})
        -- end)
        self.m_houseNodeTab[self.m_currSuperidx].m_logo:playAction(
            "over",
            false,
            function()
                self.m_houseNodeTab[self.m_currSuperidx].m_logo:setVisible(false)
            end
        )
        self.m_bottomUI:showAverageBet()
        util_setCsbVisible(self.m_superFreeBar, true)
    end
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenThreeLittlePigsMachine:levelFreeSpinOverChangeEffect()
end
--freespin结束
function CodeGameScreenThreeLittlePigsMachine:freeSpinOverChangeView()
    self:runCsbAction("normal")
    if self.m_currSuperidx > 0 then
        self.m_gameBg:runCsbAction(
            "super_base",
            false,
            function()
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"base", true})
            end
        )
    else
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"base", true})
    end
    self:findChild("houseView"):setVisible(true)
    self:findChild("fg_logo"):setVisible(false)
    self.m_littleLogoProgressNode:setVisible(true)
    for i, littleLogo in ipairs(self.m_littleLogoTab) do
        littleLogo:setVisible(true)
    end
    self:findChild("progress"):setVisible(true)
    self:updateHouse()
    self:setLittleLogoState()
    self.m_bottomUI:hideAverageBet()
    self.m_currSuperidx = 0
    self.m_configData.m_curSuperFreeIdx = self.m_currSuperidx
    self:hideFreeSpinBar()
    util_setCsbVisible(self.m_superFreeBar, false)
end

function CodeGameScreenThreeLittlePigsMachine:playGuochang1(func1, func2)
    performWithDelay(
        self.m_guochang1,
        function()
            gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_guochang1.mp3")
        end,
        0.2
    )

    self.m_guochang1:setVisible(true)
    util_spinePlay(self.m_guochang1, "actionframe", false)
    util_spineEndCallFunc(
        self.m_guochang1,
        "actionframe",
        function()
            self.m_guochang1:setVisible(false)
            if func2 then
                func2()
            end
        end
    )
    performWithDelay(
        self.m_guochang1,
        function()
            if func1 then
                func1()
            end
        end,
        120 / 30
    )
end
function CodeGameScreenThreeLittlePigsMachine:playGuochang2(func1, func2)
    gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_guochang2.mp3")
    self.m_guochang2:setVisible(true)

    self.m_dajuese:setAnimation(0, "actionframe_yangban", false)
    self.m_dajuese:addAnimation(0, "idleframe", true)

    performWithDelay(
        self.m_guochang2,
        function()
            self.m_guochang2:playAction(
                "actionframe",
                false,
                function()
                    self.m_guochang2:setVisible(false)
                    if func2 then
                        func2()
                    end
                end
            )
            performWithDelay(
                self.m_guochang2,
                function()
                    if func1 then
                        func1()
                    end
                end,
                95 / 60
            )
        end,
        8 / 30
    )
end
function CodeGameScreenThreeLittlePigsMachine:playGuochang3(func1, func2, func3)
    gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_guochang3.mp3")
    local house = self.m_houseNodeTab[self.m_currSuperidx]
    house.m_zhu:setVisible(false)
    self.m_bgTranslucentMask:setVisible(true)
    self.m_bgTranslucentMask:playAction("actionframe", false)
    self.m_guochang3:setVisible(true)
    util_spinePlay(self.m_guochang3, "actionframe", false)
    util_spineEndCallFunc(
        self.m_guochang3,
        "actionframe",
        function()
            self.m_bgTranslucentMask:setVisible(false)
            self.m_guochang3:setVisible(false)
            house.m_zhu:setVisible(true)
            if func2 then
                func2()
            end
        end
    )
    util_spineFrameCallFunc(
        self.m_guochang3,
        "actionframe",
        "chufa",
        function()
            house:playAction("guochang", false)
        end
    )
    performWithDelay(
        self.m_guochang3,
        function()
            if func1 then
                func1()
            end
        end,
        93 / 30
    )
end
----------- FreeSpin相关
---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenThreeLittlePigsMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode == nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        if slotNode == nil then
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end
function CodeGameScreenThreeLittlePigsMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            slotNode:runAnim("actionframe", false)
        else
            slotNode:runLineAnim()
        end
    end
    return slotNode
end
-- FreeSpinstart
function CodeGameScreenThreeLittlePigsMachine:showFreeSpinView(effectData)
    local showFSView = function()
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self.m_showWinSoundId = gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_showFreeSpinStart.mp3")
            local view =
                self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    if self.m_showWinSoundId then
                        gLobalSoundManager:stopAudio(self.m_showWinSoundId)
                        self.m_showWinSoundId = nil
                    end
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
            view:setPosition(display.center)
            local lang = util_spineCreate("ThreeLittlePigs_lang_dajuese", true, true)
            util_spinePlay(lang, "idleframe", true)
            view:findChild("Node_lang"):addChild(lang)
        else
            local view =
                self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    if self.m_currSuperidx > 0 then
                        self:triggerFreeSpinCallFun()
                        util_setCsbVisible(self.m_baseFreeSpinBar, false)
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    else
                        if self.m_showWinSoundId then
                            gLobalSoundManager:stopAudio(self.m_showWinSoundId)
                            self.m_showWinSoundId = nil
                        end
                        self:playGuochang1(
                            function()
                                self:triggerFreeSpinCallFun()
                            end,
                            function()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        )
                    end
                end
            )
            view:setPosition(display.center)
            if self.m_currSuperidx > 0 then
                view:findChild("txt_wu" .. self.m_currSuperidx):setVisible(true)
            else
                local lang = util_spineCreate("ThreeLittlePigs_lang_dajuese", true, true)
                util_spinePlay(lang, "idleframe", true)
                view:findChild("Node_lang"):addChild(lang)
            end
        end
    end

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.triggerSuperFree then
        self.m_currSuperidx = self.m_runSpinResultData.p_selfMakeData.triggerSuperFree
        self.m_configData.m_curSuperFreeIdx = self.m_currSuperidx
    end

    if self.m_currSuperidx > 0 then
        performWithDelay(
            self,
            function()
                showFSView()
            end,
            1.0
        )
    else
        performWithDelay(
            self,
            function()
                showFSView()
            end,
            1.5
        )
    end
end
--显示freespin开始弹框
function CodeGameScreenThreeLittlePigsMachine:showFreeSpinStart(num, func)
    local ownerlist = {}
    local fileName = BaseDialog.DIALOG_TYPE_FREESPIN_START
    if self.m_currSuperidx > 0 then
        fileName = "SuperFreeSpinStart"
        self.m_showWinSoundId = gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_showBonusOverView.mp3")
    else
        ownerlist["m_lb_num"] = num
        self.m_showWinSoundId = gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_showFreeSpinStart.mp3")
    end
    return self:showDialog(fileName, ownerlist, func)
end
function CodeGameScreenThreeLittlePigsMachine:showFreeSpinOverView()
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            if self.m_showWinSoundId then
                gLobalSoundManager:stopAudio(self.m_showWinSoundId)
                self.m_showWinSoundId = nil
            end
            if self.m_currSuperidx > 0 then
                self:playGuochang3(
                    function()
                        self:freeSpinOverChangeView()
                    end,
                    function()
                        if self.m_pigShopData.round == 1 then
                            self.m_isInSuperFreeEndWaiting = true
                        end
                        self:triggerFreeSpinOverCallFun()
                    end
                )
            else
                self:playGuochang2(
                    function()
                        self:freeSpinOverChangeView()
                    end,
                    function()
                        self:triggerFreeSpinOverCallFun()
                    end
                )
            end
        end
    )
    view:setPosition(display.center)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.61, sy = 0.61}, 1074)

    self.m_currChooseHouseIdx = self.m_currChooseHouseIdx + 1
    if self.m_currChooseHouseIdx > 3 then
        self.m_currChooseHouseIdx = 3
    end
    -- self.m_housePageView:setCurrentPageIndex(self.m_currChooseHouseIdx - 1)
    if self.m_housePageView:getCurrentPageIndex() + 1 < 3 then
        self:updateHummerStatus(self.m_housePageView:getCurrentPageIndex() + 1 + 1)
    else
        self:updateHummerStatus(self.m_housePageView:getCurrentPageIndex() + 1)
    end
end
function CodeGameScreenThreeLittlePigsMachine:showFreeSpinOver(coins, num, func)
    self.m_showWinSoundId = gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_showFreeSpinOver.mp3")
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    local fileName = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    if self.m_currSuperidx > 0 then
        fileName = "SuperFreeSpinOver"
    end
    return self:showDialog(fileName, ownerlist, func)
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenThreeLittlePigsMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    return false -- 用作延时点击spin调用
end

function CodeGameScreenThreeLittlePigsMachine:beginReel()
    self.m_isReconnection = false
    self.m_isReShowLine = false
    if self.m_isInSuperFreeEndWaiting == true then
        self.m_isInSuperFreeEndWaiting = false
        self:roundOneChooseHouse()
    end
    self:hideXiaozhuCoinCollectBarTip()
    self:setSymbolToReel()
    CodeGameScreenThreeLittlePigsMachine.super.beginReel(self)
    if self.m_shopView and self.m_xiaozhuCoinCollectBar:findChild("shangdian"):isTouchEnabled() then
        -- gLobalNoticManager:postNotification("ThreeLittlePigsShopView_removeGetSpinresult")
        self:closeShopView()
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenThreeLittlePigsMachine:addSelfEffect()
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.scorePositions then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECTZHUZHUCOIN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECTZHUZHUCOIN_EFFECT
    end
    --normal下变wild
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.wildChangePositions then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.CHANGEWILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CHANGEWILD_EFFECT
    end
    --superfree和freespin下变wild
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.wildChange then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.FREECHANGEWILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FREECHANGEWILD_EFFECT
    end
end

-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenThreeLittlePigsMachine:MachineRule_playSelfEffect(effectData)
    --收集猪猪币
    if effectData.p_selfEffectType == self.COLLECTZHUZHUCOIN_EFFECT then
        --高级图标变wild
        self:collectSymbolIconFly(effectData)
    elseif effectData.p_selfEffectType == self.CHANGEWILD_EFFECT then
        self:normalWildPlayChange()
    elseif effectData.p_selfEffectType == self.FREECHANGEWILD_EFFECT then
        if self.m_currSuperidx > 0 then
            --superfree
            self:addMultiple()

            effectData.p_isPlay = true
            self:playGameEffect()
        else
            self:freespinPlayDajuese()
        end
    end
    return true
end
--所有effect播放完之后调用
function CodeGameScreenThreeLittlePigsMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    CodeGameScreenThreeLittlePigsMachine.super.playEffectNotifyNextSpinCall(self)
end
----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenThreeLittlePigsMachine:operaEffectOver()
    CodeGameScreenThreeLittlePigsMachine.super.operaEffectOver(self)
    if self.m_isInSuperFreeEndWaiting == true then
        self:setHousePageViewTouchEnabled(false)
        performWithDelay(
            self,
            function()
                self.m_isInSuperFreeEndWaiting = false
                if self.m_bottomUI.m_btn_add:isTouchEnabled() == true then
                    self:setHousePageViewTouchEnabled(true)
                end
                self:roundOneChooseHouse()
            end,
            0.5
        )
    end
end
-- 通知某种类型动画播放完毕
function CodeGameScreenThreeLittlePigsMachine:notifyGameEffectPlayComplete(param)
    local effectType
    if type(param) == "table" then
        effectType = param[1]
    else
        effectType = param
    end
    local effectLen = #self.m_gameEffects
    if effectType == nil or effectType == EFFECT_NONE or effectLen == 0 then
        return
    end

    if effectType == GameEffect.EFFECT_QUEST_DONE then
        return
    end

    for i = 1, effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == effectType and effectData.p_isPlay == false then
            if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT then
                if effectData.p_selfEffectType == param[2] then
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 继续播放动画
                    break
                end
            else
                effectData.p_isPlay = true
                self:playGameEffect() -- 继续播放动画
                break
            end
        end
    end
end
-- 收集动画
function CodeGameScreenThreeLittlePigsMachine:collectSymbolIconFly(effectData)
    gLobalSoundManager:playSound("ThreeLittlePigsSounds/sound_ThreeLittlePigs_collect_fly.mp3")
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.scorePositions then
        local posTable = self.m_runSpinResultData.p_selfMakeData.scorePositions
        local isUpdateCoins = true
        --是否更新猪猪币显示数量
        local pigShopData = self:getPigShopData()
        local currCoinNum = 0
        if pigShopData then
            currCoinNum = self:getPigShopData().scoreTotal
        end
        for posStr, coinNum in pairs(posTable) do
            local rowColData = self:getRowAndColByPos(tonumber(posStr))
            local symbolNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.m_icon then
                --创建上飞的猪猪币
                local flyCoin = util_createAnimation("ThreeLittlePigs_symbolCoin.csb")
                flyCoin:findChild("num"):setString(coinNum)
                self:addChild(flyCoin, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                flyCoin:playAction("actionframe")
                --添加拖尾
                local tuowei = util_createAnimation("ThreeLittlePigs_shop_tuowei.csb")
                flyCoin:addChild(tuowei, -1)
                tuowei:findChild("Particle_1"):setPositionType(0)
                tuowei:findChild("Particle_1"):resetSystem()

                local startPos = cc.p(util_getConvertNodePos(symbolNode.m_icon, flyCoin))
                flyCoin:setPosition(startPos)
                local endWorldPos = self.m_xiaozhuCoinCollectBar:findChild("jinbi"):getParent():convertToWorldSpace(cc.p(self.m_xiaozhuCoinCollectBar:findChild("jinbi"):getPosition()))
                local endPos = self:convertToNodeSpace(endWorldPos)
                local delay = cc.DelayTime:create(15 / 60)
                local move = cc.MoveTo:create(13 / 60, endPos)
                local call =
                    cc.CallFunc:create(
                    function()
                        flyCoin:removeFromParent()
                        if isUpdateCoins then
                            isUpdateCoins = false
                            self:setXiaozhuCoin(true, currCoinNum)
                            gLobalSoundManager:playSound("ThreeLittlePigsSounds/sound_ThreeLittlePigs_collect_flyend.mp3")
                        end
                    end
                )

                local call2 =
                    cc.CallFunc:create(
                    function()
                        self:updateHummerStatus(self.m_housePageView:getCurrentPageIndex() + 1)
                    end
                )
                local seq = cc.Sequence:create(delay, move, call, call2)
                flyCoin:runAction(seq)

                symbolNode.m_icon:stopAllActions()
                symbolNode.m_icon:removeFromParent()
                symbolNode.m_icon = nil
            end
        end
    end

    effectData.p_isPlay = true
    self:playGameEffect()
end
--normal下wild狼吹气
function CodeGameScreenThreeLittlePigsMachine:normalWildPlayChange()
    self:removeSoundHandler()
    self:setMinMusicBGVolume()
    self:setSymbolToReel()

    local changePosTab = self.m_runSpinResultData.p_selfMakeData.wildChangePositions
    for i, pos in ipairs(changePosTab) do
        local rowColData = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
        if symbolNode then
            -- symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) + 10 * rowColData.iY - rowColData.iX )
            self:setSymbolToClip(symbolNode)
        end
    end
    self:findChild("lunpanzhezhao"):setVisible(true)
    util_nodeFadeIn(
        self:findChild("lunpanzhezhao"),
        0.2,
        0,
        255,
        nil,
        function()
            gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_wildLangjiao.mp3")
            for row = 1, self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(5, row, SYMBOL_NODE_TAG)
                if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    self:setSymbolToClip(symbolNode)
                    symbolNode:runAnim("actionframe_bianjinzhu")
                    symbolNode:setIdleAnimName("idleframe2")
                end
            end

            performWithDelay(
                self,
                function()
                    self:normalSymbolChangeToWild()
                end,
                42 / 30
            )
            performWithDelay(
                self,
                function()
                    util_nodeFadeIn(
                        self:findChild("lunpanzhezhao"),
                        0.2,
                        255,
                        0,
                        nil,
                        function()
                            self:findChild("lunpanzhezhao"):setVisible(false)
                            self:setSymbolToReel()

                            local winLines = self.m_runSpinResultData.p_winLines
                            if winLines == nil or #winLines <= 0 then
                                self:setMaxMusicBGVolume()
                                self:checkTriggerOrInSpecialGame(
                                    function()
                                        self:reelsDownDelaySetMusicBGVolume()
                                    end
                                )
                            else
                                performWithDelay(
                                    self,
                                    function()
                                        self:setMaxMusicBGVolume()
                                        self:checkTriggerOrInSpecialGame(
                                            function()
                                                self:reelsDownDelaySetMusicBGVolume()
                                            end
                                        )
                                    end,
                                    1
                                )
                            end
                            self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT, self.CHANGEWILD_EFFECT})
                        end
                    )
                end,
                75 / 30
            )
        end
    )
end
--freespin下大角色吹气
function CodeGameScreenThreeLittlePigsMachine:freespinPlayDajuese()
    self:setSymbolToReel()
    local changePosTab = self.m_runSpinResultData.p_selfMakeData.wildChange
    for pos, multipleNum in pairs(changePosTab) do
        local rowColData = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
        if symbolNode then
            -- symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) + 10 * rowColData.iY - rowColData.iX )
            self:setSymbolToClip(symbolNode)
        end
    end
    self:findChild("lunpanzhezhao"):setVisible(true)
    util_nodeFadeIn(
        self:findChild("lunpanzhezhao"),
        0.2,
        0,
        255,
        nil,
        function()
            local worldPos = self.m_dajuese:getParent():convertToWorldSpace(cc.p(self.m_dajuese:getPosition()))
            local pos = self:convertToNodeSpace(worldPos)
            -- self.m_dajuese:retain()
            -- self.m_dajuese:removeFromParent()
            -- self:addChild(self.m_dajuese,GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT - 1)
            -- self.m_dajuese:setPosition(pos)
            -- self.m_dajuese:release()
            performWithDelay(
                self,
                function()
                    gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_freelangchuiqi.mp3")
                end,
                0.2
            )
            self.m_dajuese:setAnimation(0, "actionframe_yangban", false)
            util_spineEndCallFunc(
                self.m_dajuese,
                "actionframe_yangban",
                function()
                    util_nodeFadeIn(
                        self:findChild("lunpanzhezhao"),
                        0.2,
                        255,
                        0,
                        nil,
                        function()
                            -- self.m_dajuese:retain()
                            -- self.m_dajuese:removeFromParent()
                            -- self:findChild("fg_logo"):addChild(self.m_dajuese)
                            -- self.m_dajuese:setPosition(cc.p(0,0))
                            -- self.m_dajuese:release()
                            self.m_dajuese:setAnimation(0, "idleframe", true)
                            self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT, self.FREECHANGEWILD_EFFECT})
                        end
                    )
                end
            )
            performWithDelay(
                self,
                function()
                    self:freeSymbolChangeToWild()
                end,
                30 / 30
            )
        end
    )
end
-- normal下图标变wild
function CodeGameScreenThreeLittlePigsMachine:normalSymbolChangeToWild()
    gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_bianjinzhu.mp3")
    local changePosTab = self.m_runSpinResultData.p_selfMakeData.wildChangePositions
    for i, pos in ipairs(changePosTab) do
        local rowColData = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
        if symbolNode then
            -- symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) + 10 * rowColData.iY - rowColData.iX )
            -- symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
            symbolNode:runAnim("actionframe_bianjin")
            symbolNode:setLineAnimName("actionframe_jin")
            symbolNode:setIdleAnimName("idleframe_jin")
            if symbolNode.p_symbolImage ~= nil and symbolNode.p_symbolImage:getParent() ~= nil then
                symbolNode.p_symbolImage:removeFromParent()
                symbolNode.p_symbolImage = nil
            end
        end
    end
end
--free下图标变wild
function CodeGameScreenThreeLittlePigsMachine:freeSymbolChangeToWild()
    gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_bianjinzhu.mp3")
    local changePosTab = self.m_runSpinResultData.p_selfMakeData.wildChange
    for pos, multipleNum in pairs(changePosTab) do
        local rowColData = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
        if symbolNode then
            -- symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
            symbolNode:runAnim("actionframe_bianjin")
            symbolNode:setLineAnimName("actionframe_jin")
            symbolNode:setIdleAnimName("idleframe_jin")
            -- symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) + 10 * rowColData.iY - rowColData.iX )
            if symbolNode.p_symbolImage ~= nil and symbolNode.p_symbolImage:getParent() ~= nil then
                symbolNode.p_symbolImage:removeFromParent()
                symbolNode.p_symbolImage = nil
            end
        end
    end
end
--super下金猪上添加倍数
function CodeGameScreenThreeLittlePigsMachine:addMultiple()
    local changePosTab = self.m_runSpinResultData.p_selfMakeData.wildChange
    for pos, multipleNum in pairs(changePosTab) do
        local rowColData = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
        if symbolNode then
            symbolNode:addMultiple(multipleNum)
        end
    end
end
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenThreeLittlePigsMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end
--显示商店界面
function CodeGameScreenThreeLittlePigsMachine:showShopView()
    if self.m_shopView == nil then
        self:clearWinLineEffect()
        if self.m_isReconnection == false then
            self.m_isReShowLine = true
        end
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        self.m_shopView = util_createView("CodeThreeLittlePigsSrc.ThreeLittlePigsShopView", self)
        self:findChild("shopNode"):addChild(self.m_shopView)
    end
end
--商店购买成功刷新界面
function CodeGameScreenThreeLittlePigsMachine:buySuccessUpdate(pageIndex)
    self:clearCurMusicBg()
    self:setXiaozhuCoin()
    self:hideLittleLogoTip()
    local isHaveFree = false --是否触发superfreespin
    local featureDatas = self.m_runSpinResultData.p_features
    if featureDatas then
        --检测是否触发superfree
        for i = 1, #featureDatas do
            local featureId = featureDatas[i]
            if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
                gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
                isHaveFree = true
                -- 添加freespin effect
                local freeSpinEffect = GameEffectData.new()
                freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
                freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
                self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
                freeSpinEffect.p_BonusTrigger = true

                -- 保留freespin 数量信息
                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

                self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

                --更新fs次数ui 显示
                gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                break
            end
        end
    end

    self:updateOneHouse(
        pageIndex,
        true,
        function()
            if isHaveFree then
                self.m_bottomUI:checkClearWinLabel()
                self:closeShopView()
                self:changeLittleLogoState()
            else
                performWithDelay(
                    self,
                    function()
                        globalData.slotRunData.lastWinCoin = 0
                        local winCoin = self.m_runSpinResultData.p_winAmount
                        self:showBonusOverView(
                            pageIndex,
                            winCoin,
                            function()
                                if self.m_showWinSoundId then
                                    gLobalSoundManager:stopAudio(self.m_showWinSoundId)
                                    self.m_showWinSoundId = nil
                                end
                                self:resetMusicBg()
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {winCoin, true})
                                gLobalNoticManager:postNotification("ThreeLittlePigsShopView_buySuccess")

                                self:updateHummerStatus(self.m_housePageView:getCurrentPageIndex() + 1)
                            end
                        )
                    end,
                    0.5
                )
            end
        end
    )
end
--显示bonus弹框
function CodeGameScreenThreeLittlePigsMachine:showBonusOverView(pageIndex, coins, func)
    self.m_showWinSoundId = gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_showBonusOverView.mp3")
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local view =
        self:showDialog(
        "BonusOver",
        ownerlist,
        function()
            if func then
                func()
            end
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.61, sy = 0.61}, 1038)
    view:setPosition(display.center)

    local goodsIdx = self:getHouseBuildProgress(pageIndex) - 1
    local fileName = "common/ThreeLittlePigs_shop_ui_wu" .. pageIndex .. "_" .. goodsIdx .. ".png"
    view:findChild("item"):addChild(util_createSprite(fileName))
end
function CodeGameScreenThreeLittlePigsMachine:setShangdianTouchEnabled(isCanTouch)
    self.m_xiaozhuCoinCollectBar:findChild("shangdian"):setTouchEnabled(isCanTouch)
end
function CodeGameScreenThreeLittlePigsMachine:setHousePageViewTouchEnabled(isCanTouch)
    self.m_housePageView:setTouchEnabled(isCanTouch)
    for i, littleLogo in ipairs(self.m_littleLogoTab) do
        littleLogo:findChild("wu" .. i .. "_click"):setTouchEnabled(isCanTouch)
    end
end
--关闭商店界面
function CodeGameScreenThreeLittlePigsMachine:closeShopView()
    self:setShangdianTouchEnabled(false)
    gLobalNoticManager:postNotification("ThreeLittlePigsShopView_closeSelf")
end
--商店界面关闭结束
function CodeGameScreenThreeLittlePigsMachine:closeShopViewEnd()
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self:playGameEffect()
    else
        self:roundOneChooseHouse()
        if self.m_isReShowLine == true then
            self.m_isReShowLine = false
            self:showLineFrame(false)
        end
    end
    self.m_shopView:removeFromParent()
    self.m_shopView = nil
    self:setShangdianTouchEnabled(true)
end
--择点击界面获得数据解析
function CodeGameScreenThreeLittlePigsMachine:SpinResultParseResultData(spinData)
    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
    self:MachineRule_afterNetWorkLineLogicCalculate()
end

function CodeGameScreenThreeLittlePigsMachine:showLineFrame(isUpdateCoin)
    local winLines = self.m_runSpinResultData.p_winLines
    if winLines == nil or #winLines <= 0 then
        return
    end
    if isUpdateCoin == nil then
        isUpdateCoin = true
    end

    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime()

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    if isUpdateCoin then
        self:checkNotifyUpdateWinCoin()
    end

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                if frameIndex > #winLines then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                        self:showAllFrame(winLines)
                        self:playInLineNodes()
                        showLienFrameByIndex()
                    end
                    return
                end
                self:playInLineNodesIdle()
                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end
                    -- print("showLine ... ")
                    local lineData = winLines[frameIndex]

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- end
        self:showAllFrame(winLines) -- 播放全部线框

        -- if #winLines > 1 then
        showLienFrameByIndex()
    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end

        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines, 1)
        end
    end
end
function CodeGameScreenThreeLittlePigsMachine:getNormalType()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,
        self.SYMBOL_SCORE_10
    }
    return symbolList[math.random(1, #symbolList)]
end
--初始化的 wild、scatter图标变为普通图标
function CodeGameScreenThreeLittlePigsMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolType = self:getNormalType()
            end
            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            --            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

function CodeGameScreenThreeLittlePigsMachine:updateHummerStatus(_curLevel)
    local curLevel = 1

    if not _curLevel then
        -- curLevel = gLobalDataManager:getNumberByField("ThreeLittlePigs_chooseHouseIdx", 1)
        if self.m_level then
            curLevel = self.m_level
            self.m_level = nil
        end
    else
        curLevel = _curLevel
    end

    local limitMoney = 0
    local pigShopData = self:getPigShopData()

    local cardInfo = pigShopData.levels[1].cards[1]
    if curLevel == 1 and cardInfo.unlock == true and cardInfo.purchase == false then
        limitMoney = pigShopData.firstCard or pigShopData.scoreLimit[curLevel]
    else
        limitMoney = pigShopData.scoreLimit[curLevel]
    end

    if self.m_hummerAnimationOver == false then
        return
    end

    local levelInfo = pigShopData.levels[curLevel]
    -- 每个橱窗最后一个商品购买是否完成
    local isPurchase = levelInfo.cards[#levelInfo.cards].purchase

    if self.m_hammerStatus == "silvery" then
        if pigShopData.scoreTotal >= limitMoney then
            if isPurchase == false then
                self.m_hummerAnimationOver = false
                self.m_hammer:runCsbAction(
                    "actionframe1",
                    false,
                    function()
                        self.m_hammer:runCsbAction("idleframe", true)
                        self.m_hammerStatus = "golden"
                        self.m_hummerAnimationOver = true
                    end
                )
            end
        end
    elseif self.m_hammerStatus == "golden" then
        if pigShopData.scoreTotal < limitMoney or isPurchase then
            self.m_hummerAnimationOver = false
            self.m_hammer:runCsbAction(
                "actionframe",
                false,
                function()
                    self.m_hammer:runCsbAction("idleframe1", true)
                    self.m_hammerStatus = "silvery"
                    self.m_hummerAnimationOver = true
                end
            )
        end
    end
end
return CodeGameScreenThreeLittlePigsMachine
