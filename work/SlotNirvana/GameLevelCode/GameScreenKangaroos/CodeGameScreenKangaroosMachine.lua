---
-- island
-- 2018年6月4日
-- CodeGameScreenKangaroosMachine.lua
-- 
-- 玩法：
-- 
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local KangaroosShopData = util_require("CodeOutbackFrontierShopSrc.KangaroosShopData")
local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SendDataManager = require "network.SendDataManager"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local TuoWeiLiZiRes = "Kangaroos_jiaobiaoTrail.plist" -- 拖尾粒子资源

local FLY_DURATION = 0.4
local FLY_ROTATION_VALUE = 720

local SUPER_FREESPIN_DELAY_START = 0.8

local FLY_CORNER_BEFORE_SCALE_DELAY = 0
local FLY_CORNER_SCALE_TO_SMALL_TIME = 0.1
local FLY_CORNER_SCALE_TO_BIG_TIME = 0.3
local FLY_CORNER_SCALE_TO_SMALL2_TIME = 0.1
local FLY_CORNER_IDLE_TIME = 0.4

local FLY_CORNER_SCALE_TO_SMALL_VALUE = 0.7
local FLY_CORNER_SCALE_TO_BIG_VALUE = 1.2
local FLY_CORNER_SCALE_TO_SMALL2_VALUE = 1.1


local CodeGameScreenKangaroosMachine = class("CodeGameScreenKangaroosMachine", BaseSlotoManiaMachine)

CodeGameScreenKangaroosMachine.m_isMachineBGPlayLoop = true
CodeGameScreenKangaroosMachine.m_customSymbol_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenKangaroosMachine.m_customSymbol_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenKangaroosMachine.m_winSoundsId = nil

CodeGameScreenKangaroosMachine.m_poolSymbol_0x = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7
CodeGameScreenKangaroosMachine.m_poolSymbol_1x = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenKangaroosMachine.m_poolSymbol_2x = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenKangaroosMachine.m_poolSymbol_3x = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenKangaroosMachine.m_poolSymbol_4x = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenKangaroosMachine.m_poolSymbol_Grand = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenKangaroosMachine.m_poolSymbol_Major = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13
CodeGameScreenKangaroosMachine.m_poolSymbol_Minor = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14

CodeGameScreenKangaroosMachine.m_diamondFlyEffect = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenKangaroosMachine.m_kangaroosRunEffect = GameEffect.EFFECT_SELF_EFFECT
CodeGameScreenKangaroosMachine.m_kangaroosCornerMarkerFlyEffect = GameEffect.EFFECT_SELF_EFFECT + 1

CodeGameScreenKangaroosMachine.m_nodeFlyDiamonds = nil

CodeGameScreenKangaroosMachine.m_bIsSendBonusData = nil
CodeGameScreenKangaroosMachine.m_bonusResult = nil
CodeGameScreenKangaroosMachine.m_bonusView = nil

CodeGameScreenKangaroosMachine.m_vecReelRowNum = {4, 5, 6, 5, 4}
CodeGameScreenKangaroosMachine.m_iBetLevel = nil
CodeGameScreenKangaroosMachine.m_vecFreeSpinTimeByBet = nil
CodeGameScreenKangaroosMachine.m_vecFreeSpinTimeInitData = nil
CodeGameScreenKangaroosMachine.m_freespinTimes = nil
CodeGameScreenKangaroosMachine.m_bIsReconnectDiamond = nil

CodeGameScreenKangaroosMachine.m_spinActionType = nil -- 当前spin的类型

CodeGameScreenKangaroosMachine.m_currentSpinSound1 = nil
CodeGameScreenKangaroosMachine.m_currentSpinSound2 = nil
CodeGameScreenKangaroosMachine.m_waitEnter = nil

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136
-- 构造函数
function CodeGameScreenKangaroosMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_isOnceClipNode = false --是否只绘制一个矩形裁切 --小矮仙 袋鼠等不规则或者可变高度设置成false
    self.m_winSoundsId = nil
	--init
    self:initGame()
end

function CodeGameScreenKangaroosMachine:initGame()

	--初始化基本数据
    self:initMachine(self.m_moduleName)
    
    self.m_scatterBulingSoundArry = {}
    for i = 1, 5 do
        local soundPath = "KangaroosSounds/sound_Kangaroos_scatter_down_" .. i .. ".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end  

-- function CodeGameScreenKangaroosMachine:scaleMainLayer()
--     local uiW, uiH = self.m_topUI:getUISize()
--     local uiBW, uiBH = self.m_bottomUI:getUISize()

--     local mainHeight = display.height - uiH - uiBH
--     local mainPosY = (uiBH - uiH - 30) / 2

--     local winSize = display.size
--     local mainScale = 1

--     local hScale = mainHeight / self:getReelHeight()
--     local wScale = winSize.width / self:getReelWidth()
--     if hScale < wScale then
--         mainScale = hScale
--     else
--         mainScale = wScale
--         self.m_isPadScale = true
--     end
--     if globalData.slotRunData.isPortrait == true then
--         if display.height >= FIT_HEIGHT_MAX then
--             mainScale = (FIT_HEIGHT_MAX - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
--             mainScale = mainScale + 0.05
--             util_csbScale(self.m_machineNode, mainScale)
--             self.m_machineRootScale = mainScale
--             if (display.height / display.width) >= 2 then
--                 self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 14)
--                 self:findChild("m_shop"):setPositionY(self:findChild("m_shop"):getPositionY() - 120)
--             elseif (display.height / display.width) >= 1.7 then
--                 self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 22 )
--                 self:findChild("m_shop"):setPositionY(self:findChild("m_shop"):getPositionY() - 60)
--             else
--                 self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 22 )
--                 self:findChild("m_shop"):setPositionY(self:findChild("m_shop"):getPositionY() - 50)
--             end
--         elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
--             mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
--             util_csbScale(self.m_machineNode, mainScale)
--             self.m_machineRootScale = mainScale
--         else
--             mainScale = (display.height + 40 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
--             util_csbScale(self.m_machineNode, mainScale)
--             self.m_machineRootScale = mainScale
--             self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 25)
--         end
--     else
--         util_csbScale(self.m_machineNode, mainScale)
--         self.m_machineRootScale = mainScale
--         self.m_machineNode:setPositionY(mainPosY)
--     end
    

--     if globalData.slotRunData.isPortrait then
--         local bangHeight =  util_getBangScreenHeight()
--         self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - bangHeight )
--     end

-- end

function CodeGameScreenKangaroosMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    if globalData.slotRunData.isPortrait == true then
        if display.height <= DESIGN_SIZE.height then
            -- 1.78
            if display.height / display.width >= 1370/768 then
                mainScale = mainScale * 1.02
                mainPosY  = mainPosY + 10
            --1.59
            elseif display.height / display.width >= 1228/768 then
                mainScale = mainScale * 1.05
                mainPosY  = mainPosY + 20
            --1.5
            elseif display.height / display.width >= 1152/768 then
                mainScale = mainScale * 1.07
                mainPosY  = mainPosY + 25
            --1.19
            elseif display.height / display.width >= 920/768 then
                mainScale = mainScale * 1.2
                mainPosY  = mainPosY + 35
            end

            mainScale = math.min(1, mainScale)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale  = mainScale
            self.m_machineNode:setPositionY(mainPosY)
        elseif display.height / display.width >= 1970/768 then
            -- mainScale = mainScale * 1.1
            -- mainPosY  = 4
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end
----
--- 处理spin 成功消息
--
function CodeGameScreenKangaroosMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or spinData.action == "SPECIAL" then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )

        if spinData.action == "SPECIAL" then
            if spinData.result then
                self.m_runSpinResultData.p_features = spinData.result.features
                if spinData.result.freespin ~= nil then
                    self.m_runSpinResultData.p_freeSpinsTotalCount = spinData.result.freespin.freeSpinsTotalCount -- fs 总数量
                    self.m_runSpinResultData.p_freeSpinsLeftCount = spinData.result.freespin.freeSpinsLeftCount -- fs 剩余次数
                    self.m_runSpinResultData.p_fsMultiplier = spinData.result.freespin.fsMultiplier -- fs 当前轮数的倍数
                    self.m_runSpinResultData.p_freeSpinNewCount = spinData.result.freespin.freeSpinNewCount -- fs 增加次数
                    self.m_runSpinResultData.p_fsWinCoins = spinData.result.freespin.fsWinCoins -- fs 累计赢钱数量
                    self.m_runSpinResultData.p_freeSpinAddList = spinData.result.freespin.freeSpinAddList
                    self.m_runSpinResultData.p_newTrigger = spinData.result.freespin.newTrigger
                    self.m_runSpinResultData.p_fsExtraData = spinData.result.freespin.extra                  
                end
                self.m_runSpinResultData.p_selfMakeData = spinData.result.selfData
            end
            -- 网络请求状态重置
            KangaroosShopData:setNetState(false)
            -- 商店兑换后更新商店数据和UI
            self:exchangeSymbol()
        end
        
        -- self:updateNetWorkData()
        local istrue = false
        if self.m_runSpinResultData.p_features and #self.m_runSpinResultData.p_features > 0 then
            istrue = true
        end

        if spinData.action == "SPIN" or istrue  then
            self:updateNetWorkData()
        end
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

---
-- 处理spin 返回结果
function CodeGameScreenKangaroosMachine:spinResultCallFun(param)

    if self.m_bIsReconnectDiamond == true then
        self.m_bIsReconnectDiamond = false
    end

    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime
    
    self:checkTestConfigType(param)
    
    local isOpera = self:checkOpearReSpinAndSpecialReels(param)  -- 处理respin逻辑
    if isOpera == true then
        return 
    end

    if param[1] == true then                -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else                                    -- 处理spin失败
        self:checkOpearSpinFaild(param)                            
    end

    if param[1] == true then
        local spinData = param[2]

        self.m_spinActionType = spinData.action
        if spinData.action == "FEATURE" then
            self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)

            if self.m_bIsSendBonusData == true then
                self.m_bIsSendBonusData = false
                self:getBonusResult(self.m_runSpinResultData.p_selfMakeData.wheel)
                self.m_bonusView:setEndValue(self.m_bonusResult)
                self.m_bonusView:beginMove()
            end
        end

        if spinData.action == "SPIN" then
            -- 保存spin结果数据，滚动结束后做动效
            KangaroosShopData:parseSpinResultData(spinData.result.selfData)
        end
    end

    self.m_freespinTimes = self.m_runSpinResultData.p_selfMakeData.freespinTimes
    self.m_vecFreeSpinTimeByBet[tostring(globalData.slotRunData:getCurBetIndex())] = self.m_freespinTimes

end

-- 商店兑换后更新商店数据和UI
function CodeGameScreenKangaroosMachine:exchangeSymbol()
    local features = self.m_runSpinResultData.p_features
    if features and #features == 2 and (features[2] == SLOTO_FEATURE.FEATURE_FREESPIN) then 
        KangaroosShopData:setFreeSpinState(true)
    end
    KangaroosShopData:savePagesFree()
    KangaroosShopData:parseExchangeData(self.m_runSpinResultData.p_selfMakeData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_KANGAROOS_SHOP_PAGE, {exchange = true})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_KANGAROOS_SHOP_ENTER_UPDATE, {})
end

function CodeGameScreenKangaroosMachine:getBonusResult(wheel)
    if self.m_bonusResult == nil then
        self.m_bonusResult = {}
    end
    local vecStrs = util_string_split(wheel,",")
    self.m_bonusResult.type = vecStrs[1]
    self.m_bonusResult.score = tonumber(vecStrs[2])
end

function CodeGameScreenKangaroosMachine:initUI()

    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")

    -- local logo, act = util_csbCreate("Kangaroos/KangaroosTitle.csb")
    -- self.m_csbOwner["m_jackpot"]:addChild(logo)
    -- logo:setPositionY(-50)

    self.m_jackPotBar = util_createView("CodeKangaroosSrc.KangaroosTopBar")
    self.m_csbOwner["m_jackpot"]:addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    self.m_diamond = util_createView("CodeKangaroosSrc.KangaroosDiamond")
    self.m_csbOwner["m_collect"]:addChild(self.m_diamond)

    self.m_diamondLogo = util_csbCreate("Node_shuoming.csb")
    self.m_csbOwner["m_collect"]:addChild(self.m_diamondLogo)
    self.m_diamondLogo:setPosition(84, -227)
    util_getChildByName(self.m_diamondLogo, "Node_0"):setVisible(false)
    util_getChildByName(self.m_diamondLogo, "Node_1"):setVisible(false)
    
    self.m_kangaIdle = util_spineCreate("kangaroo", false, true)
    util_spinePlay(self.m_kangaIdle, "animation", true)
    self.m_csbOwner["m_kangaroo"]:addChild(self.m_kangaIdle)
    self.m_kangaIdle:setScale(0.8)
    self.m_kangaIdle:setPosition(90,20)

    self.m_kangaRun = util_spineCreate("kangaroo", false, true)
    self:addChild(self.m_kangaRun, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_kangaRun:setPosition(display.width*0.5, display.height*0.5)
    self.m_kangaRun:setScale(self.m_machineRootScale)
    self.m_kangaRun:setVisible(false)

    self.m_fresSpinBar = util_createView("CodeKangaroosSrc.KangaroosFreeSpinBar")
    self.m_csbOwner["m_freespin"]:addChild(self.m_fresSpinBar)
    self.m_fresSpinBar:setVisible(false)
    self.m_fresSpinBar:setScale(1.1)
    self.m_fresSpinBar:setPositionY(40)

    self.m_shopEnterView = util_createView("CodeOutbackFrontierShopSrc.KangaroosShopEnter", self)
    self.m_shopEnterNode = self:findChild("m_shop")
    self.m_shopEnterNode:addChild(self.m_shopEnterView)
    self.m_shopEnterView:initMachine(self)

    self.m_colorLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 220))
    self:addChild(self.m_colorLayer, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    self.m_colorLayer:setVisible(false)

    self:upDateKangaroosUiPosAndScale()

    local coinNode = self.m_shopEnterView:getFlyEndLabel()
    self.m_worldPos = coinNode:getParent():convertToWorldSpace(cc.p(coinNode:getPositionX(), coinNode:getPositionY()))    

    

end
function CodeGameScreenKangaroosMachine:upDateKangaroosUiPosAndScale()
    --奖池
    local nodeJackpot = self:findChild("m_jackpot")
    nodeJackpot:setPositionY(nodeJackpot:getPositionY() + 10)
    --收集栏
    local nodeCollect = self:findChild("m_collect")
    nodeCollect:setPositionY(nodeCollect:getPositionY() + 10)
    --角色
    local kangaroos = self:findChild("m_kangaroo")
    kangaroos:setPositionY(kangaroos:getPositionY() - 30)
    --商店栏
    self.m_shopEnterNode:setPositionY(self.m_shopEnterNode:getPositionY() + 50)

    -- if display.height > FIT_HEIGHT_MAX then
        -- local fitLen = 0
        -- if display.height >= 1500 then
        --     fitLen = (display.height - 1500) * 0.5
        -- end
        -- local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        -- local nodeLunpan = self:findChild("Node_lunpan")
        -- nodeLunpan:setPositionY(nodeLunpan:getPositionY() - posY + fitLen)
        -- local nodeCollect = self:findChild("m_collect")
        -- nodeCollect:setPositionY(nodeCollect:getPositionY() - posY + fitLen)
        -- local kangaroos = self:findChild("m_kangaroo")
        -- kangaroos:setPositionY(kangaroos:getPositionY() - posY + fitLen)
        -- local freespin = self:findChild("m_freespin")
        -- freespin:setPositionY(freespin:getPositionY() - posY + fitLen)

        -- local nodeJackpot = self:findChild("m_jackpot")
        -- if (display.height / display.width) >= 2 then
        --     nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY + 18 - 85 )

        --     self.m_jackPotBar:setScale(1.15)
        --     self.m_csbOwner["m_collect"]:setPositionY(1000)
        --     self.m_diamond:setScale(1.2)
        --     self.m_diamondLogo:setScale(1.2)
        --     self.m_diamondLogo:setPositionY(-270)

        --     self.m_kangaIdle:setScale(0.85)
        --     self.m_kangaIdle:setPositionX(130)  
            
        --     self.m_fresSpinBar:setScale(1.2)
        --     self.m_fresSpinBar:setPositionY(150)
        -- else
        --     nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY - 85  )
        -- end
    -- elseif display.height < FIT_HEIGHT_MIN then
        -- local nodeJackpot = self:findChild("m_jackpot")
        -- nodeJackpot:setPositionY(nodeJackpot:getPositionY() - 5 )
    -- end
end

function CodeGameScreenKangaroosMachine:showFreeSpinTip(type)
    self.m_fresSpinBar:initUIByType(type and type or self.m_bonusResult.type)
    self.m_fresSpinBar:show()
    self.m_fresSpinBar:setVisible(true)
    self.m_diamond:setVisible(false)
    self.m_diamondLogo:setVisible(false)
    self.m_kangaIdle:setVisible(false)
end

function CodeGameScreenKangaroosMachine:hideFreeSpinTip()
    self.m_fresSpinBar:setVisible(false)
    self.m_diamond:setVisible(true)
    self.m_diamondLogo:setVisible(true)
    self.m_kangaIdle:setVisible(true)
end

function CodeGameScreenKangaroosMachine:kangaroosRun(func)
    gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_run.mp3")
    self.m_kangaRun:setVisible(true)
    util_spinePlay(self.m_kangaRun, "guochang", false)
    
    self.m_colorLayer:setVisible(true)
    self.m_colorLayer:setOpacity(220)
    util_spineEndCallFunc(self.m_kangaRun, "guochang", function()
        self.m_kangaRun:setVisible(false)
        if func ~= nil then
            func()
        else
            self.m_colorLayer:runAction(cc.FadeOut:create(0.3))
        end
    end)
end

function CodeGameScreenKangaroosMachine:initJackpotInfo(jackpotPool,lastBetId)
    self.m_jackPotBar:updateJackpotInfo()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenKangaroosMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "Kangaroos"  
end

function CodeGameScreenKangaroosMachine:getNetWorkModuleName()
    return "KangaroosV2"
end

--重写
function CodeGameScreenKangaroosMachine:updateReelGridNode(node)
    self:addCornermarketNode(node)
end
-- 重写 getSlotNodeWithPosAndType 方法
function CodeGameScreenKangaroosMachine:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType,iRow,iCol,isLastSymbol)
    self:addCornermarketNode(reelNode)
    return reelNode
end

function CodeGameScreenKangaroosMachine:addCornermarketNode(reelNode)
    if reelNode:getChildByName("cornerMarker") then
        reelNode:removeChildByName("cornerMarker")
    end
    if reelNode:getChildByName("nodeFlyDiamonds") then
        reelNode:removeChildByName("nodeFlyDiamonds")
    end
    if self.m_runSpinResultData.p_selfMakeData ~= nil and reelNode.m_isLastSymbol == true and self.m_bIsReconnectDiamond == false then
        local index = self:getPosReelIdx(reelNode.p_rowIndex, reelNode.p_cloumnIndex)
        if self.m_runSpinResultData.p_selfMakeData.diamond ~= nil then
            local position = self.m_runSpinResultData.p_selfMakeData.diamond.position
            if position ~= nil and index == position then
                -- local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
                -- reelNode:runAction(callFun)
                if self.m_nodeFlyDiamonds then
                    self.m_nodeFlyDiamonds:removeFromParent()
                    self.m_nodeFlyDiamonds = nil
                end
                local type = self.m_runSpinResultData.p_selfMakeData.diamond.type
                self.m_nodeFlyDiamonds = util_createAnimation("KangaroosDiamond"..type..".csb")
                reelNode:addChild(self.m_nodeFlyDiamonds, 10)
                self.m_nodeFlyDiamonds:setName("nodeFlyDiamonds")
                self.m_nodeFlyDiamonds:playAction("idle")
            end
        end
        if self.m_runSpinResultData.p_selfMakeData.multiplier ~= nil and reelNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            if self.m_runSpinResultData.p_selfMakeData.multiplier["2x"] ~= nil then
                local multipx2 = self.m_runSpinResultData.p_selfMakeData.multiplier["2x"]
                if multipx2 ~= nil then
                    for i = 1, #multipx2, 1 do
                        if multipx2[i] == index then
                            local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode, "2"})
                            reelNode:runAction(callFun)
                            break
                        end
                    end
                end
            end
            if self.m_runSpinResultData.p_selfMakeData.multiplier["3x"] ~= nil then
                local multipx3 = self.m_runSpinResultData.p_selfMakeData.multiplier["3x"]
                if multipx3 ~= nil then
                    for i = 1, #multipx3, 1 do
                        if multipx3[i] == index then
                            local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode, "3"})
                            reelNode:runAction(callFun)
                            break
                        end
                    end
                end
            end
        end
        -- 袋鼠商店掉落添加角标
        local coinsPosition = self.m_runSpinResultData.p_selfMakeData.coinsPosition
        if coinsPosition ~= nil then
            for pos,num in pairs(coinsPosition) do
                if index == tonumber(pos) then
                    self:createCornerMarker(reelNode, num)
                end
            end
        end
    end
end


function CodeGameScreenKangaroosMachine:setSpecialNodeScore(sender,parma)
    local symbolNode = parma[1]
    if parma[2] ~= nil then
        symbolNode:setLineAnimName("actionframe"..parma[2])
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenKangaroosMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.m_customSymbol_10 then
        return "Socre_Kangaroos_10"
    elseif symbolType == self.m_customSymbol_11 then
        return "Socre_Kangaroos_11"
    elseif symbolType == self.m_poolSymbol_0x then
        return "Kangaroos/KangaroosBonus0x"
    elseif symbolType == self.m_poolSymbol_1x then
        return "Kangaroos/KangaroosBonus1x"
    elseif symbolType == self.m_poolSymbol_2x then
        return "Kangaroos/KangaroosBonus2x"
    elseif symbolType == self.m_poolSymbol_3x then
        return "Kangaroos/KangaroosBonus3x"
    elseif symbolType == self.m_poolSymbol_4x then
        return "Kangaroos/KangaroosBonus4x"
    elseif symbolType == self.m_poolSymbol_Grand then
        return "KangaroosBonusGrand"
    elseif symbolType == self.m_poolSymbol_Major then
        return "KangaroosBonusMajor"
    elseif symbolType == self.m_poolSymbol_Minor then
        return "KangaroosBonusMinor"
    elseif symbolType == -1000 then
        return "Socre_Kangaroos_1"
    end 
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenKangaroosMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = {symbolType = self.m_customSymbol_10, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_customSymbol_11, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_poolSymbol_0x, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_poolSymbol_1x, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_poolSymbol_2x, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_poolSymbol_3x, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_poolSymbol_4x, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_poolSymbol_Grand, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_poolSymbol_Major, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_poolSymbol_Minor, count = 2}
    return loadNode
end

function CodeGameScreenKangaroosMachine:sendData()
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, betLevel = self.m_iBetLevel}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
    self.m_bIsSendBonusData = true
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenKangaroosMachine:upateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        self.m_iBetLevel = 1
    else
        self.m_iBetLevel = 0
    end
end

----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenKangaroosMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()
    
    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型
    
    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
    self:getCurrSpinMode() ~= RESPIN_MODE
    then
       
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = self.m_iBetLevel}
    -- local operaId = 
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName, 
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

function CodeGameScreenKangaroosMachine:addDiamondFlyEffect()
    local diamondFlyEffect = GameEffectData.new()
    diamondFlyEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    diamondFlyEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    diamondFlyEffect.p_selfEffectType = self.m_diamondFlyEffect
    self.m_gameEffects[#self.m_gameEffects + 1] = diamondFlyEffect
end


function CodeGameScreenKangaroosMachine:addCornerMarkerFlyEffect()
    local shopCollectFlyEffect = GameEffectData.new()
    shopCollectFlyEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    shopCollectFlyEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    shopCollectFlyEffect.p_selfEffectType = self.m_kangaroosCornerMarkerFlyEffect
    self.m_gameEffects[#self.m_gameEffects + 1] = shopCollectFlyEffect
end

function CodeGameScreenKangaroosMachine:addSelfEffect()
    if self.m_nodeFlyDiamonds ~= nil then
        self:addDiamondFlyEffect()
    end

    if KangaroosShopData.m_preCollectCoins ~= KangaroosShopData:getShopCollectCoins() then
        self:addCornerMarkerFlyEffect()
    end
    
end

-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenKangaroosMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.m_diamondFlyEffect then
        self:showDiamondFly(effectData)
    end
    if effectData.p_selfEffectType == self.m_kangaroosRunEffect then
        --21.03.24 策划cyj要求 FreeGame->BaseGame切换,要在FreeGame结束弹板关闭时触发
        performWithDelay(self, function()
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"change_normal")
            -- self:hideFreeSpinTip()
        end, 1.0)
        
        self:kangaroosRun(function()
            self.m_colorLayer:runAction(cc.FadeOut:create(0.3))
            if effectData ~= nil then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end) 
    end
    if effectData.p_selfEffectType == self.m_kangaroosCornerMarkerFlyEffect then
        self:showCornerMarkerFly(effectData)
    end
    return true
end

function CodeGameScreenKangaroosMachine:showDiamondFly(effectData)
    gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_diamond_1.mp3")
    local type = self.m_runSpinResultData.p_selfMakeData.diamond.type
    local pos = self.m_nodeFlyDiamonds:getParent():convertToWorldSpace(cc.p(self.m_nodeFlyDiamonds:getPosition()))
    

    util_changeNodeParent(self, self.m_nodeFlyDiamonds, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_nodeFlyDiamonds:setPosition(pos)
    self.m_nodeFlyDiamonds:setScale(self.m_machineRootScale)

    self.m_nodeFlyDiamonds:playAction("zuanshi_chuxian", false, function()
        self.m_nodeFlyDiamonds:playAction("animation0", false, function()
            self.m_nodeFlyDiamonds:setVisible(false)
        end)
  
        gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_diamond_2.mp3")
        local diamond, act = util_csbCreate("KangaroosDiamond"..type..".csb")
        self:addChild(diamond, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
        diamond:setPosition(pos)
        diamond:setScale(self.m_machineRootScale)
        util_csbPlayForKey(act, "idle", false)

        local endPos = self.m_diamond:getEndPosition(type)
        local moveTo = cc.MoveTo:create(0.3, endPos)
        local seq = cc.Sequence:create(moveTo, cc.CallFunc:create(function ()
            self.m_diamond:addFreeTimes(type, self.m_freespinTimes, function()
                self.m_nodeFlyDiamonds:removeFromParent()
                self.m_nodeFlyDiamonds = nil
                if effectData ~= nil then
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end)
            diamond:removeFromParent()
        end))
        diamond:runAction(seq)
    end)
end

function CodeGameScreenKangaroosMachine:showCornerMarkerFly(effectData)
    local num = KangaroosShopData:getShopCollectCoins()   
    print("####################  719    "..num)
    local coinsPosition = self.m_runSpinResultData.p_selfMakeData.coinsPosition
    for iCol = 1, self.m_iReelColumnNum, 1 do
        for iRow = 1, self.m_iReelRowNum, 1 do
            local symbolNode = self:getFixSymbol(iCol, iRow)
            local cornerNode = symbolNode:getChildByName("cornerMarker")
            if cornerNode ~= nil then
                local flyStartWorldPos = cornerNode:getParent():convertToWorldSpace(cc.p(cornerNode:getPositionX(),cornerNode:getPositionY()))
                util_changeNodeParent(self, cornerNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
                cornerNode:setScale(self.m_machineRootScale) 
                
                local flyStartLocalPos = self:convertToNodeSpace(cc.p(flyStartWorldPos.x,flyStartWorldPos.y))
                cornerNode:setPosition(cc.p(flyStartLocalPos.x, flyStartLocalPos.y))

                self:scaleCornerMarkers(cornerNode, function()
                    self:flyCornerMarkers(cornerNode,num)
                end)
            end
        end
    end
    
    if effectData ~= nil then
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

function CodeGameScreenKangaroosMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) 
    and 
    (self:getGameSpinStage( ) ~= QUICK_RUN 
    or self.m_hasBigSymbol == true
    ) and
    self.m_bProduceSlots_InFreeSpin == false
    then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            gLobalSoundManager:playSound(self.m_reelDownSound)
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end


    ---本列是否开始长滚
    if self.m_bProduceSlots_InFreeSpin == false then
        isTriggerLongRun = self:setReelLongRun(reelCol)
    end
    
    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

function CodeGameScreenKangaroosMachine:slotReelDown()
    -- 点击spin按钮后 动效和UI更新
    self.m_currentSpinSound1 = false
    self.m_currentSpinSound2 = false

    BaseSlotoManiaMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

--设置长滚信息
function CodeGameScreenKangaroosMachine:setReelRunInfo()
    
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
        
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)
        end
        
        local runLen = reelRunData:getReelRunLen()
        
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)
        bRunLong = bRunLong and self.m_bProduceSlots_InFreeSpin == false
    end --end  for col=1,iColumn do

end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenKangaroosMachine:levelFreeSpinEffectChange()
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenKangaroosMachine:levelFreeSpinOverChangeEffect()
    
end
---------------------------------------------------------------------------

-- 掉落收集动画 start -------------------------------------------------------
function CodeGameScreenKangaroosMachine:createCornerMarker(symbolNode, num)
    local csb = util_createAnimation("OutbackFrontierShop/Socre_Kangaroos_jiaobiao.csb")
    csb:setName("cornerMarker")
    csb:findChild("BitmapFontLabel_1"):setString(tostring(num))
    csb:findChild("BitmapFontLabel_1"):setScale(1.25)
    csb:findChild("guang_1"):setOpacity(0)
    csb:findChild("guang_2"):setOpacity(0)
    csb:findChild("guang_3"):setOpacity(0)
    symbolNode:addChild(csb, 20000)
    csb:setPosition(cc.p(40, -30))
    csb.score = num
end

-- 做飞入动效
function CodeGameScreenKangaroosMachine:scaleCornerMarkers(node, flyOverCallFunc)
    local csb = node
    if not csb then
        if flyOverCallFunc then
            flyOverCallFunc()
        end
        return 
    end
    -- gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_shop_collectcoins.mp3"
    
    -- 延迟
    local delay = cc.DelayTime:create(FLY_CORNER_BEFORE_SCALE_DELAY)
    -- 变小
    local scaleToSmall1 = cc.EaseBackIn:create(cc.ScaleTo:create(FLY_CORNER_SCALE_TO_SMALL_TIME, FLY_CORNER_SCALE_TO_SMALL_VALUE))
    -- 变大
    local scaleToBig = cc.EaseBackIn:create(cc.ScaleTo:create(FLY_CORNER_SCALE_TO_BIG_TIME, FLY_CORNER_SCALE_TO_BIG_VALUE))
    local lightBigCallFunc = cc.CallFunc:create(function()
        csb:findChild("guang_1"):runAction(cc.FadeIn:create(FLY_CORNER_SCALE_TO_BIG_TIME))
        csb:findChild("guang_2"):runAction(cc.FadeIn:create(FLY_CORNER_SCALE_TO_BIG_TIME))
        csb:findChild("guang_3"):runAction(cc.FadeIn:create(FLY_CORNER_SCALE_TO_BIG_TIME))
    end)
    local spawnBig = cc.Spawn:create(scaleToBig, lightBigCallFunc)
    -- 变小
    local scaleToSmall2 = cc.EaseBackIn:create(cc.ScaleTo:create(FLY_CORNER_SCALE_TO_SMALL2_TIME, FLY_CORNER_SCALE_TO_SMALL2_VALUE))
    local lightSmallCallFunc = cc.CallFunc:create(function()
        csb:findChild("guang_1"):runAction(cc.FadeOut:create(FLY_CORNER_SCALE_TO_SMALL2_TIME))
        csb:findChild("guang_2"):runAction(cc.FadeOut:create(FLY_CORNER_SCALE_TO_SMALL2_TIME))
        csb:findChild("guang_3"):runAction(cc.FadeOut:create(FLY_CORNER_SCALE_TO_SMALL2_TIME))
    end)
    local spawnSmall = cc.Spawn:create(scaleToSmall2, lightSmallCallFunc)

    csb:runAction(cc.Sequence:create(delay, scaleToSmall1, spawnBig, spawnSmall, cc.CallFunc:create(flyOverCallFunc)))
end

function CodeGameScreenKangaroosMachine:flyCornerMarkers(node,_num)
        
    local aniNode = node
    local num = _num
    local callFunc = cc.CallFunc:create(function()
        if not self.m_currentSpinSound2 then
            gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_shop_collectcoins_2.mp3")
            self.m_currentSpinSound2 = true
        end
        -- 更新关卡商店入口UI
        self.m_shopEnterView:playLighting(nil,num)
        -- 更新上商店内UI
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_KANGAROOS_SHOP_PAGE, {})

    end)
    if not self.m_currentSpinSound1 then
        gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_shop_collectcoins_1.mp3")
        self.m_currentSpinSound1 = true
    end
    local csb = aniNode
    if not csb then
        callFunc()
        return 
    end

    local flyParticle = cc.ParticleSystemQuad:create(TuoWeiLiZiRes)
    if csb:findChild("particleNode") then
        flyParticle:setPosition(cc.p(0,0))
        csb:findChild("particleNode"):addChild(flyParticle)
    end

    -- 获取飞的终点位置
    local endPos = self:convertToNodeSpace(cc.p(self.m_worldPos.x,self.m_worldPos.y))
    local localPosx = csb:findChild("BitmapFontLabel_1"):getPositionX()
    local localPosy = csb:findChild("BitmapFontLabel_1"):getPositionY()
    endPos.x = endPos.x - localPosx
    endPos.y = endPos.y - localPosy
    -- 动作
    local moveTo = cc.MoveTo:create(FLY_DURATION, endPos)
    local fadeOutCallFunc = cc.CallFunc:create(function()
        local num = csb:findChild("BitmapFontLabel_1")
        num:runAction(cc.FadeOut:create(FLY_DURATION))
    end) 
    local rotateCallFunc = cc.CallFunc:create(function()
        local bg = csb:findChild("jiaobiao_bg") 
        bg:runAction(cc.RotateTo:create(FLY_DURATION, FLY_ROTATION_VALUE))
    end)
    local spawn = cc.Spawn:create(moveTo, fadeOutCallFunc, rotateCallFunc)
    
    csb:runAction(cc.Sequence:create(spawn, callFunc, cc.CallFunc:create(function()
        csb:removeFromParent()
    end)))
end

-- 掉落收集动画 end   -------------------------------------------------------


---
--添加金边
function CodeGameScreenKangaroosMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(self.m_vecReelRowNum[col]/self.m_iReelRowNum)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenKangaroosMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    self:showLineFrame()

    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 1)
    else
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
            or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            performWithDelay(self, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, 0.5)
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    
    return true

end

function CodeGameScreenKangaroosMachine:showEffect_Bonus(effectData)
    
    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    if scatterLineValue ~= nil then        
        -- 
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)            
            gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
            self:kangaroosRun(function ()
                self:showBonusView(effectData)
            end)
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue        
        -- 播放提示时播放音效        
        self:playScatterTipMusicEffect()
    else
        self:kangaroosRun(function ()
            self:showBonusView(effectData)
        end)
    end
    return true
end

function CodeGameScreenKangaroosMachine:showBonusView( effectData )
    local bonusView = util_createView("CodeKangaroosSrc.JackPotView", self.m_runSpinResultData.p_selfMakeData.wheels)
    --传入信号池
    bonusView:setNodePoolFunc(
        function(symbolType)
            return self:getSlotNodeBySymbolType(symbolType)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end)
    bonusView:setSendDataFunc(function()
        self:sendData()
    end)

    bonusView:initFeatureUI()
    --21.03.24 策划cyj要求改为:BonusGame->FreeGame切换,在轮盘转出FreeGame时就触发
    bonusView:setMoveEndCallBackFun(function()
        if self.m_bonusResult.type == "Grand" 
        or self.m_bonusResult.type == "Major"
        or self.m_bonusResult.type == "Minor" then
            
        else
            self:showFreeSpinTip()
        end
    end)

    bonusView:setOverCallBackFun(function()
        bonusView:removeFromParent()
        if self.m_bonusResult.type == "Grand" 
        or self.m_bonusResult.type == "Major"
        or self.m_bonusResult.type == "Minor" then
            self:showRespinJackpot(self.m_bonusResult.type, tonumber(self.m_bonusResult.score), function()
                -- self:kangaroosRun(function()
                    self.m_colorLayer:runAction(cc.FadeOut:create(0.2))
                    effectData.p_isPlay = true
                    self:playGameEffect()
                -- end)
            end)
        else
            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
            globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
            globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes
            self.m_fresSpinBar:show()
            --21.03.24 策划cyj要求改为:BonusGame->FreeGame切换,在轮盘转出FreeGame时就触发
            performWithDelay(self, function()
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"change_freespin")
                -- self:showFreeSpinTip()
            end, 1.0)
            
            self:kangaroosRun(
                function()
                    self.m_colorLayer:runAction(cc.FadeOut:create(0.3))
                    self:freeSpinStart(effectData)
                end
            )
            
        end
    end)
    if globalData.slotRunData.machineData.p_portraitFlag then
        bonusView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(bonusView)
    self.m_bonusView = bonusView
end

function CodeGameScreenKangaroosMachine:showFreeSpinView(effectData)
    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- if self.m_runSpinResultData.p_fsExtraData.level ~= nil then
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_pop_window.mp3")
        self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,true)
    else
        if self.m_runSpinResultData.p_fsExtraData ~= nil and self.m_runSpinResultData.p_fsExtraData.level ~= nil then
            local delaytime = 0
            -- if not self.m_bIsReconnectDiamond then
            --     delaytime = SUPER_FREESPIN_DELAY_START
            -- end
            performWithDelay(self, function()
                self.m_bottomUI:showAverageBet()
                self:showFreeSpinTip("0x")
                self:showSuperFreeSpin(KangaroosShopData.m_requestPageIndex,function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)    
            end, delaytime)
        else
            performWithDelay(self, function()
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"change_freespin")
                self:showFreeSpinTip()
            end, 1.0)
            self:kangaroosRun(function()
                self.m_colorLayer:runAction(cc.FadeOut:create(0.3))
                performWithDelay(self, function()
                    self:freeSpinStart(effectData)
                end, 1.0)
            end)
        end
        
        
    end
end

function CodeGameScreenKangaroosMachine:showSuperFreeSpin(pageIndex,func)
    local function newFunc()
        -- self:resetMusicBg(true)  
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end
    self.m_fsReelDataIndex = pageIndex
    local view = util_createView("CodeOutbackFrontierShopSrc.KangaroosShopSuperFreeSpin", pageIndex, newFunc)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
end

function CodeGameScreenKangaroosMachine:freeSpinStart( effectData )

    gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_pop_window.mp3")
    self:showFreeSpinStart(self.m_iFreeSpinTimes, function()
        gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_click_btn.mp3")

        self:triggerFreeSpinCallFun()

        effectData.p_isPlay = true
        self:playGameEffect()       
    end)
end

function CodeGameScreenKangaroosMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num1"]=num
    ownerlist["m_lb_num2"]=num

    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    local node1 = util_getChildByName(view, "BG1")
    local node2 = util_getChildByName(view, "BG2")
    if self.m_bonusResult.type == "0x" or self.m_bonusResult.type == "1x" then
        node1:setVisible(true)
        node2:setVisible(false)
    else
        node1:setVisible(false)
        node2:setVisible(true)
        util_getChildByName(view, "2x"):setVisible(false)
        util_getChildByName(view, "3x"):setVisible(false)
        util_getChildByName(view, "4x"):setVisible(false)
        util_getChildByName(view, self.m_bonusResult.type):setVisible(true)

    end
end

function CodeGameScreenKangaroosMachine:showFreeSpinOverView()
    KangaroosShopData:setFreeSpinState(false)
    gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_pop_window.mp3")

    local overCallFunc = function()
        gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_click_btn.mp3")
        --21.03.24 策划cyj要求 FreeGame->BaseGame切换,要在FreeGame结束弹板关闭时触发
        self:hideFreeSpinTip()
        local kangaroosRunEffect = GameEffectData.new()
        kangaroosRunEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        kangaroosRunEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        kangaroosRunEffect.p_selfEffectType = self.m_kangaroosRunEffect
        self.m_gameEffects[#self.m_gameEffects + 1] = kangaroosRunEffect

        -- 判断当前freespin是商店触发的特殊玩法
        if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.level ~= nil then
            self.m_bottomUI:hideAverageBet()
            self.m_fsReelDataIndex = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_KANGAROOS_SHOP_FREE_SPIN, "over")
        end
        self:triggerFreeSpinOverCallFun()
        self:updateSpinTimesLab()        
    end
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,overCallFunc)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.4,sy=1.4},390)

end

function CodeGameScreenKangaroosMachine:MachineRule_initGame( spinData )
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_runSpinResultData.p_fsExtraData.level ~= nil then
            -- 商店触发的特殊freespin
            self:showFreeSpinTip("0x")
            self.m_bottomUI:showAverageBet()
        else
            if self.m_bonusResult == nil then
                self.m_bonusResult = {}
            end
            self.m_bonusResult.type = self.m_runSpinResultData.p_fsExtraData.multiple
            self:showFreeSpinTip(self.m_bonusResult.type)
        end
    end
    self.m_bIsReconnectDiamond = true    
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenKangaroosMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    self.m_winSoundsId = nil

    return false
end

function CodeGameScreenKangaroosMachine:showRespinJackpot(jackPot,coins,func)
    gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_pop_window.mp3")
    local jackPotWinView = util_createView("CodeKangaroosSrc.KangaroosJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self,jackPot,coins,func)

    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(coins))
    self:checkFeatureOverTriggerBigWin(coins , GameEffect.EFFECT_RESPIN_OVER)
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,true,true})
    globalData.slotRunData.lastWinCoin = lastWinCoin
end

function CodeGameScreenKangaroosMachine:enterGamePlayMusic(  )
    self.m_waitEnter = true
    scheduler.performWithDelayGlobal(function(  )
        gLobalSoundManager:playSound("KangaroosSounds/music_Kangaroos_enter.mp3") 
        scheduler.performWithDelayGlobal(function()
            self:resetMusicBg()
            self:setMinMusicBGVolume()
            print("!!! ----------- bgmusicid == ", gLobalSoundManager:getBGMusicId())

            self.m_waitEnter = false
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenKangaroosMachine:initGameStatusData(gameData)

    local feature = gameData.feature or {}
    local bonus = feature.bonus or {}
    local status = bonus.status or {}
    if status and (status == "CLOSED") then
        gameData.spin.freespin = feature.freespin
        if not gameData.spin.reels then
            gameData.spin.reels = table_createTwoArr(self.m_iReelRowNum,self.m_iReelColumnNum,TAG_SYMBOL_TYPE.SYMBOL_WILD)
            for iCol = 1, self.m_iReelColumnNum, 1 do
                for iRow = 1,self.m_iReelRowNum , 1 do
                    gameData.spin.reels[iRow][iCol] = math.random(1,10) -1
                end
            end
        end 
    end

    if gameData.gameConfig ~= nil and gameData.gameConfig.init ~= nil and gameData.gameConfig.init.freespinTimes ~= nil then
        self.m_vecFreeSpinTimeInitData = gameData.gameConfig.init.freespinTimes
    end

    if gameData.gameConfig ~= nil and gameData.gameConfig.betData ~= nil then
        self.m_vecFreeSpinTimeByBet = gameData.gameConfig.betData
    end

    ------father start---------------------------------------------------------
    if not globalData.userRate then
        local UserRate = require "data.UserRate"
        globalData.userRate = UserRate:create()
    end
    globalData.userRate:enterLevel(self:getModuleName())
    if gameData.gameConfig ~= nil and  gameData.gameConfig.isAllLine ~= nil then
        self.m_isAllLineType = gameData.gameConfig.isAllLine
    end

    -- spin  
    -- feature  
    -- sequenceId
    local operaId = gameData.sequenceId

    self.m_initBetId = (gameData.betId or -1)

    local spin = gameData.spin
    -- spin = nil
    local freeGameCost = gameData.freeGameCost
    local feature = gameData.feature
    local collect = gameData.collect
    local jackpot = gameData.jackpot
    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end
 
    self.m_freeSpinStartCoins = globalData.userRunData.coinNum ---gameData.totalWinCoins
    self.m_freeSpinOffSetCoins = 0--gameData.totalWinCoins
    self:setLastWinCoin( totalWinCoins )

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin,self.m_lineDataPool,self.m_symbolCompares,feature)
        self.m_initSpinData = self.m_runSpinResultData
    end

    if gameData.special then
        -- self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData.p_features = gameData.special.features
        if gameData.special.freespin ~= nil then
            self.m_runSpinResultData.p_freeSpinsTotalCount = gameData.special.freespin.freeSpinsTotalCount -- fs 总数量
            self.m_runSpinResultData.p_freeSpinsLeftCount = gameData.special.freespin.freeSpinsLeftCount -- fs 剩余次数
            self.m_runSpinResultData.p_fsMultiplier = gameData.special.freespin.fsMultiplier -- fs 当前轮数的倍数
            self.m_runSpinResultData.p_freeSpinNewCount = gameData.special.freespin.freeSpinNewCount -- fs 增加次数
            self.m_runSpinResultData.p_fsWinCoins = gameData.special.freespin.fsWinCoins -- fs 累计赢钱数量
            self.m_runSpinResultData.p_freeSpinAddList = gameData.special.freespin.freeSpinAddList
            self.m_runSpinResultData.p_newTrigger = gameData.special.freespin.newTrigger
            self.m_runSpinResultData.p_fsExtraData = gameData.special.freespin.extra
        end

        self.m_runSpinResultData.p_selfMakeData = gameData.special.selfData

        self.m_initSpinData = self.m_runSpinResultData
    end

    if feature ~= nil then
        self.m_initFeatureData = SpinFeatureData.new()
        if feature.bonus then
            if feature.bonus then
                if feature.bonus.status == "CLOSED" and feature.bonus.content ~= nil then
                    local bet = feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1]
                    feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1] = - bet
                end
                feature.choose = feature.bonus.choose
                feature.content = feature.bonus.content
                feature.extra = feature.bonus.extra
                feature.status = feature.bonus.status
    
            end
        end 
        self.m_initFeatureData:parseFeatureData(feature)
        -- self.m_initFeatureData:setAllLine(self.m_isAllLineType)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost 
    end
    
    if collect and type(collect)=="table" and #collect>0 then
        for i=1,#collect do
            self.m_collectDataList[i]:parseCollectData(collect[i])
        end
    end
    if jackpot and type(jackpot)=="table" and #jackpot>0 then
        self.m_jackpotList=jackpot
    end
    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    if gameData.gameConfig ~= nil and  gameData.gameConfig.bonusReels ~= nil then
        self.m_runSpinResultData["p_bonusReels"] = gameData.gameConfig.bonusReels
    end

    self:initMachineGame()
    ------father end---------------------------------------------------------


    if gameData.feature ~= nil then
        -- self:checkReconnectFeatures(gameData.feature)
        self:getBonusResult(gameData.feature.selfData.wheel)
        -- self:checkJackPot()
    end

    -- 袋鼠商店触发的freespin的断线重连
    if gameData.special ~= nil then
        self.m_gameDataSpecial = gameData.special
        self.m_spinActionType = "SPECIAL" 
    end
    -- 初始化袋鼠商店数据
    local data = clone(gameData.gameConfig.init)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectCoins = selfdata.collectCoins
    if collectCoins then
        data.collectCoins = collectCoins
    end
    KangaroosShopData:parseData(data)
end


function CodeGameScreenKangaroosMachine:checkNetDataCloumnStatus()
    local isPlayGameEffect = BaseSlotoManiaMachine.checkNetDataCloumnStatus(self)
    if not isPlayGameEffect then
        if self.m_gameDataSpecial then
            local isTrigger = self:checkReconnectSpecial(self.m_gameDataSpecial)
            if isTrigger then
                isPlayGameEffect = true
            end
            self.m_gameDataSpecial = nil
        end
    end
    return isPlayGameEffect
end

-- 袋鼠商店触发的freespin的断线重连
function CodeGameScreenKangaroosMachine:checkReconnectSpecial(special)
    local featureDatas = special.features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            self.m_isRunningEffect = true

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = special.freespin.freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = special.freespin.freeSpinsTotalCount


            self.m_iFreeSpinTimes = special.freespin.freeSpinsTotalCount
            KangaroosShopData:setRequestPageIndex(special.freespin.extra.level+1)

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{special.freespin.fsWinCoins,false,false})
            return true
        end
    end
end

function CodeGameScreenKangaroosMachine:checkReconnectFeatures(feature)
    local featureDatas = feature.features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = feature.freespin.freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = feature.freespin.freeSpinsTotalCount      

            self.m_iFreeSpinTimes = feature.freespin.freeSpinsTotalCount

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{feature.freespin.fsWinCoins,false,false})


        end
    end

end

function CodeGameScreenKangaroosMachine:updateFreeSpinTimesByBet()
    if self.m_vecFreeSpinTimeByBet == nil then
        self.m_vecFreeSpinTimeByBet = {}
    end
    self.m_freespinTimes = self.m_vecFreeSpinTimeByBet[tostring(globalData.slotRunData:getCurBetIndex())]
    if self.m_freespinTimes == nil then
        self.m_freespinTimes = self.m_vecFreeSpinTimeInitData
    end
end

function CodeGameScreenKangaroosMachine:updateSpinTimesLab()
    self:updateFreeSpinTimesByBet()
    self.m_diamond:updateFreeTimes(self.m_freespinTimes)

    local betCoin = globalData.slotRunData:getCurTotalBet()
    local betLevel = 0
    if betCoin >= self.m_BetChooseGear then
        betLevel = 1
    end

    local node0 = util_getChildByName(self.m_diamondLogo, "Node_0")
    local node1 = util_getChildByName(self.m_diamondLogo, "Node_1")
    if betLevel == 0 and node0:isVisible() == false then
        node0:setVisible(true)
        node1:setVisible(false)
        local particle = cc.ParticleSystemQuad:create("Kangaroos_shuoming_lizi.plist")    --加粒子效果 
        self.m_diamondLogo:addChild(particle)
        particle:setPosition(0,40)
        particle:setAutoRemoveOnFinish(true)
    end
    if betLevel == 1 and node1:isVisible() == false then
        node0:setVisible(false)
        node1:setVisible(true)
        local particle = cc.ParticleSystemQuad:create("Kangaroos_shuoming_lizi.plist")    --加粒子效果 
        self.m_diamondLogo:addChild(particle)
        particle:setPosition(0,40)
        particle:setAutoRemoveOnFinish(true)
    end
    
end

function CodeGameScreenKangaroosMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
    self:upateBetLevel()
    self:updateSpinTimesLab()
    self.m_jackPotBar:updateJackpotInfo() 

    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setPositionY(self.m_touchSpinLayer:getPositionY() - self.m_SlotNodeH )
    end
    
end

function CodeGameScreenKangaroosMachine:addObservers()
	BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateSpinTimesLab()
        self:upateBetLevel()
   end,ViewEventType.NOTIFY_BET_CHANGE)

   gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end
        if KangaroosShopData:getEnterShopView() then
            return 
        end        

        local winAmonut =  params[1]
        if type(winAmonut) == "number" then
            local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
            local winRatio = winAmonut / lTatolBetNum
            local soundName = nil
            local soundTime = 1
            if winRatio > 0 then
                if winRatio <= 1 then
                    soundName = "KangaroosSounds/sound_Kangaroos_win_1.mp3"
                elseif winRatio > 1 and winRatio <= 3 then
                    soundName = "KangaroosSounds/sound_Kangaroos_win_2.mp3"
                elseif winRatio > 3 then
                    soundName = "KangaroosSounds/sound_Kangaroos_win_3.mp3"
                end
            end

            if soundName ~= nil then
                gLobalSoundManager:setBackgroundMusicVolume(0.4)
                self.m_winSoundsId = gLobalSoundManager:playSound(soundName,false)
                performWithDelay(self,function()
                    if KangaroosShopData:getEnterShopView() then
                        return 
                    end
                    gLobalSoundManager:setBackgroundMusicVolume(1)
                end,soundTime)
    
            end

        end
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN) 

    gLobalNoticManager:addObserver(self,function(self,params)
        if params == "start" then
            performWithDelay(self, function()
                self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
                globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes     

                local bonusGameEffect = GameEffectData.new()
                bonusGameEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
                bonusGameEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
                self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
                -- self:triggerFreeSpinCallFun()
                self:playGameEffect()    
            end, SUPER_FREESPIN_DELAY_START)
        end
    end,ViewEventType.NOTIFY_KANGAROOS_SHOP_FREE_SPIN)
end

function CodeGameScreenKangaroosMachine:onExit()
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_timer then
        scheduler.unscheduleGlobal(self.m_timer)
        self.m_timer = nil
    end

    KangaroosShopData:release()
end

function CodeGameScreenKangaroosMachine:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)

    local childs = {}
    if not tolua.isnull(slotParent) then
        childs = slotParent:getChildren()
    end
    
    if  not tolua.isnull(slotParentBig) then
        local newChilds = slotParentBig:getChildren()
        for i=1,#newChilds do
            childs[#childs+1]=newChilds[i]
        end
    end
    
    for childIndex = 1, #childs do

        local child = childs[childIndex]
        child:setVisible(true)
        child:removeFromParent()
        local symbolType = child.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, child)
    end

    local index = 1
    local cloumnIndex = parentData.cloumnIndex
    while index <= self.m_vecReelRowNum[cloumnIndex] do

        self:createSlotNextNode(parentData)
        
        local node = self:getSlotNodeWithPosAndType(parentData.symbolType,
                                        parentData.rowIndex,parentData.cloumnIndex,parentData.m_isLastSymbol)
        local posY = columnData.p_showGridH * (parentData.rowIndex - 0.5) - parentPosY

        node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

        -- print("col == "..cloumnIndex.."  posY = "..posY.." index = "..index)

        node.p_cloumnIndex = parentData.cloumnIndex
        node.p_rowIndex = parentData.rowIndex
        node.m_isLastSymbol = parentData.m_isLastSymbol
        
        node.p_slotNodeH = columnData.p_showGridH
        node.p_symbolType = parentData.symbolType
        node.p_preSymbolType = parentData.preSymbolType
        node.p_showOrder = parentData.order

        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
        node.p_layerTag = parentData.layerTag
        node:setTag(parentData.tag)
        node:setLocalZOrder(parentData.order)

        if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
            slotParentBig:addChild(node, parentData.order, parentData.tag)
        else
            slotParent:addChild(node, parentData.order, parentData.tag)
        end

        node:runIdleAnim()

        if parentData.isLastNode == true then -- 本列最后一个节点移动结束
            -- 执行回弹, 如果不执行回弹判断是否执行
            parentData.isReeling = false
            -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
            -- 创建一个假的小块 在回滚停止后移除
            
            self:createResNode(parentData, node)
        end

        if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
            local addCount = self.m_bigSymbolInfos[parentData.symbolType]
            index = addCount + node.p_rowIndex
        else
            index = index + 1
        end
    end
    
end

-- 背景音乐点击spin后播放
function CodeGameScreenKangaroosMachine:normalSpinBtnCall()
    BaseSlotoManiaMachine.normalSpinBtnCall(self)
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
end

function CodeGameScreenKangaroosMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and #self.m_runSpinResultData.p_features > 0 then
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i = 1, featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的，
            -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
                featureID = SLOTO_FEATURE.FEATURE_FREESPIN
            end
            if featureID ~= 0 then
                if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                    self:addAnimationOrEffectType(GameEffect.EFFECT_FREE_SPIN)

                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)


                    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinNewCount
                    
                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then -- 触发respin 玩法
                    globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                    if self:getCurrSpinMode() == RESPIN_MODE then
                    else
                        local respinEffect = GameEffectData.new()
                        respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                        respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                        if globalData.slotRunData.iReSpinCount == 0 and #self.m_runSpinResultData.p_storedIcons == 15 then
                            respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                        end
                        self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then -- 其他小游戏
                    -- 添加 BonusEffect
                    self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end
            end
        end
    end
end

---
--保留本轮数据
function CodeGameScreenKangaroosMachine:keepCurrentSpinData()
    self:insterReelResultLines()

    --TODO   wuxi update on
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen do
        local value = self.m_vecSymbolEffectType[i]
        local effectData = GameEffectData.new()
        effectData.p_effectType = value
        --                                effectData.p_effectData = data
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

return CodeGameScreenKangaroosMachine
