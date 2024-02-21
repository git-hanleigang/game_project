---
-- island li
-- 2019年1月26日
-- CodeGameScreenMuchoChilliMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "MuchoChilliPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenMuchoChilliMachine = class("CodeGameScreenMuchoChilliMachine", BaseNewReelMachine)

CodeGameScreenMuchoChilliMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenMuchoChilliMachine.SYMBOL_EMPTY = 100   -- 空信号
CodeGameScreenMuchoChilliMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- 普通bonus 94
CodeGameScreenMuchoChilliMachine.SYMBOL_SPECIAL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2  -- 特殊bonus 95
CodeGameScreenMuchoChilliMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  -- 自定义的小块类型 9

CodeGameScreenMuchoChilliMachine.SYMBOL_LOCAL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 17  -- 普通bonus 假滚的时候用 110
CodeGameScreenMuchoChilliMachine.SYMBOL_LOCAL_SPECIAL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 18  -- 特殊bonus 假滚的时候用 111

CodeGameScreenMuchoChilliMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集辣椒

CodeGameScreenMuchoChilliMachine.REPLACE_BONUS_LIST = {
    [CodeGameScreenMuchoChilliMachine.SYMBOL_BONUS] = CodeGameScreenMuchoChilliMachine.SYMBOL_LOCAL_BONUS,
    [CodeGameScreenMuchoChilliMachine.SYMBOL_SPECIAL_BONUS] = CodeGameScreenMuchoChilliMachine.SYMBOL_LOCAL_SPECIAL_BONUS,
}
--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

-- 构造函数
function CodeGameScreenMuchoChilliMachine:ctor()
    CodeGameScreenMuchoChilliMachine.super.ctor(self)

    self.REPIN_NODE_TAG = 1000
    self.m_spinRestMusicBG = true
    self.m_lightScore = 0
    self.m_iBetLevel = 0 -- bet等级
    self.m_isTriggerLongRun = false --是否触发了快滚
    self.m_showScatterQuick = false --是否存在scatter快滚
    self.m_showBonusQuick = false --是否存在bonus快滚
    self.m_bigRoleStage = 1 --当前大角色处于第几阶段 默认1，总共3个阶段，1 2 3
    self.m_isPlayUpdateRespinNums = true --是否播放刷新respin次数
    self.m_playRoleIdleIndex = 0 --播放大角色的索引 普通idle至少播放两次 在播放特殊idle
    self.m_playBigWinSayIndex = 1
    self.m_bonusBgMusicName = "MuchoChilliSounds/music_MuchoChilli_bonus.mp3"
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}
    self.m_isRespinQuickRunLast = false --是否是respin最后一次 拉伸镜头
    self.m_isAddBigWinLightEffect = true
    self.m_isFeatureOverBigWinInFree = true
    self.m_isDuanXian = false

    self.m_publicConfig = PublicConfig
	--init
	self:initGame()
end

function CodeGameScreenMuchoChilliMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("MuchoChilliConfig.csv", "LevelMuchoChilliConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMuchoChilliMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MuchoChilli"  
end

-- 继承底层respinView
function CodeGameScreenMuchoChilliMachine:getRespinView()
    return "CodeMuchoChilliSrc.MuchoChilliRespinView"
end
-- 继承底层respinNode
function CodeGameScreenMuchoChilliMachine:getRespinNode()
    return "CodeMuchoChilliSrc.MuchoChilliRespinNode"
end

function CodeGameScreenMuchoChilliMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:initFreeSpinBar() -- FreeSpinbar

    -- 飞行动画节点
    self.m_effectNode = cc.Node:create()
    self:findChild("Node_1"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    -- 跳过节点
    self.m_skipNode = cc.Node:create()
    self:findChild("Node_1"):addChild(self.m_skipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 101)

    -- respin快滚
    self.m_lightEffectNode = cc.Node:create()
    self:findChild("Node_1"):addChild(self.m_lightEffectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 200)

    --mini轮盘
    self.m_miniMachine = util_createView("CodeMuchoChilliSrc.MuchoChilliMiniMachine",{parent = self})
    self:findChild("Node_reel_up"):addChild(self.m_miniMachine)
    self.m_miniMachine:setVisible(false)
    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniMachine.m_touchSpinLayer)
    end

    -- 创建jackpot
    self.m_baseJackpotView = util_createView("CodeMuchoChilliSrc.MuchoChilliJackPotBarView")
    self:findChild("Node_BaseJackpot"):addChild(self.m_baseJackpotView)
    self.m_baseJackpotView:initMachine(self)
    self.m_baseJackpotView:showRespinOrBaseJackpot(false)

    -- 大角色框
    self.m_bigRoleKuang = util_spineCreate("MuchoChilli_base_juesekuang", true, true)
    self:findChild("Node_juesekuang"):addChild(self.m_bigRoleKuang)

    -- 三阶段角色后面的火
    self.m_bigRoleKuangHuo = util_spineCreate("MuchoChilli_base_juesekuang", true, true)
    self:findChild("Node_juesekuang"):addChild(self.m_bigRoleKuangHuo)
    self.m_bigRoleKuangHuo:setVisible(false)

    -- 大角色
    self.m_bigRole = util_spineCreate("MuchoChilli_JS", true, true)
    self:findChild("Node_juese"):addChild(self.m_bigRole)

    -- 大角色阶段变化的时候 升级动画
    self.m_bigRoleShengJiEffect = util_createAnimation("MuchoChilli_fankui.csb")
    self:findChild("shengji"):addChild(self.m_bigRoleShengJiEffect)
    self.m_bigRoleShengJiEffect:setVisible(false)

    -- 收集辣椒的时候 反馈动画
    self.m_fanKuiEffect = util_createAnimation("MuchoChilli_fankui.csb")
    self:findChild("fankui"):addChild(self.m_fanKuiEffect)
    self.m_fanKuiEffect:setVisible(false)

    -- 大赢前 预告动画
    self.m_bigWinEffect = util_spineCreate("MuchoChilli_DY", true, true)
    self:findChild("Node_daying"):addChild(self.m_bigWinEffect)
    self.m_bigWinEffect:setVisible(false)

    -- 预告动画
    self.m_yugaoSpineEffect = util_spineCreate("MuchoChilli_yugao2", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpineEffect)
    self.m_yugaoSpineEffect:setVisible(false)

    -- 过场动画free
    self.m_guochangFreeEffect = util_spineCreate("MuchoChilli_GC2", true, true)
    self:findChild("Node_yugao"):addChild(self.m_guochangFreeEffect)
    self.m_guochangFreeEffect:setVisible(false)

    -- 过场动画respin
    self.m_guochangRespinEffect = util_spineCreate("MuchoChilli_GC", true, true)
    self:findChild("Node_yugao"):addChild(self.m_guochangRespinEffect)
    self.m_guochangRespinEffect:setVisible(false)

    -- 过场动画bonus
    self.m_guochangBonusEffect = util_spineCreate("MuchoChilli_JS", true, true)
    self:findChild("Node_yugao"):addChild(self.m_guochangBonusEffect)
    self.m_guochangBonusEffect:setVisible(false)

    -- respin 类型提醒
    self.m_respinFeatureNode = util_createAnimation("MuchoChilli_RespinFeatureName.csb")
    self:findChild("Node_RespinFeatureName1"):addChild(self.m_respinFeatureNode)
    self.m_respinFeatureNode:setVisible(false)

    --棋盘集满效果
    self.m_respinMansNode = util_createAnimation("MuchoChilli_mans.csb")
    self:findChild("mans"):addChild(self.m_respinMansNode)
    self.m_respinMansNode:setVisible(false)

    self.m_respinManxNode = util_createAnimation("MuchoChilli_manx.csb")
    self:findChild("manx"):addChild(self.m_respinManxNode)
    self.m_respinManxNode:setVisible(false)

    self.m_respinChengBeiNode = util_createAnimation("MuchoChilli_chengbei.csb")
    self:findChild("chengbei"):addChild(self.m_respinChengBeiNode)
    self.m_respinChengBeiNode:setVisible(false)

    --棋盘压暗
    self.m_darkUI = util_createAnimation("MuchoChilli_dark.csb")
    self:findChild("Node_dark"):addChild(self.m_darkUI)
    self.m_darkUI:setVisible(false)

    self:changeCoinWinEffectUI(self:getModuleName(), "MuchoChilli_fankui.csb")

    self:setReelBg(1)
    self:clickBigRole()
    self:createDoubleReelFeature()
    self:addColorLayer()
end

--[[
    每列添加滚动遮罩
]]
function CodeGameScreenMuchoChilliMachine:addColorLayer()
    self.m_colorLayers = {}
    for i = 1, self.m_iReelColumnNum do
        --单列卷轴尺寸
        local reel = self:findChild("sp_reel_"..i-1)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()
        --棋盘尺寸
        local offsetSize = cc.size(4.5, 4.5)
        reelSize.width = reelSize.width * scaleX + offsetSize.width
        reelSize.height = reelSize.height * scaleY + offsetSize.height
        --遮罩尺寸和坐标
        local clipParent = self.m_onceClipNode or self.m_clipParent
        local panelOrder = 10000--REEL_SYMBOL_ORDER.REEL_ORDER_4--SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1

        local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
        panel:setOpacity(0)
        panel:setContentSize(reelSize.width, reelSize.height)
        panel:setPosition(cc.p(posX - offsetSize.width / 2, posY - offsetSize.height / 2))
        clipParent:addChild(panel, panelOrder)
        panel:setVisible(false)
        self.m_colorLayers[i] = panel
    end
end

--[[
    显示滚动遮罩
]]
function CodeGameScreenMuchoChilliMachine:showColorLayer()
    for index, maskNode in ipairs(self.m_colorLayers) do
        maskNode:setVisible(true)
        maskNode:setOpacity(0)
        maskNode:runAction(cc.FadeTo:create(0.3, 150))
    end
end

--[[
    列滚动停止 渐隐
]]
function CodeGameScreenMuchoChilliMachine:reelStopHideMask(col)
    local maskNode = self.m_colorLayers[col]
    local fadeAct = cc.FadeTo:create(0.1, 0)
    local func = cc.CallFunc:create( function()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct, func))
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2free 3respin 4表示base下大角色第三阶段
]]
function CodeGameScreenMuchoChilliMachine:setReelBg(_BgIndex, _isChange)
    
    if _BgIndex == 1 then
        self:findChild("base_reel"):setVisible(true)
        self:findChild("free_reel"):setVisible(false)
        self:findChild("Node_respinlines"):setVisible(false)

        self.m_gameBg:findChild("base"):setVisible(true)
        self.m_gameBg:findChild("base_0"):setVisible(false)
        self.m_gameBg:findChild("fg"):setVisible(false)
        self.m_gameBg:findChild("respin1_0"):setVisible(false)

    elseif _BgIndex == 2 then
        self:findChild("base_reel"):setVisible(false)
        self:findChild("free_reel"):setVisible(true)
        self:findChild("Node_respinlines"):setVisible(false)

        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("base_0"):setVisible(false)
        self.m_gameBg:findChild("fg"):setVisible(true)
        self.m_gameBg:findChild("respin1_0"):setVisible(false)
    elseif _BgIndex == 3 then
        self:findChild("base_reel"):setVisible(false)
        self:findChild("free_reel"):setVisible(false)
        self:findChild("Node_respinlines"):setVisible(true)

        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("base_0"):setVisible(false)
        self.m_gameBg:findChild("fg"):setVisible(false)
        self.m_gameBg:findChild("respin1_0"):setVisible(true)
    elseif _BgIndex == 4 then
        self:findChild("base_reel"):setVisible(true)
        self:findChild("free_reel"):setVisible(false)
        self:findChild("Node_respinlines"):setVisible(false)

        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("base_0"):setVisible(true)
        self.m_gameBg:findChild("fg"):setVisible(false)
        self.m_gameBg:findChild("respin1_0"):setVisible(false)

        if _isChange then
            util_nodeFadeIn(self.m_gameBg:findChild("base_0"), 0.5, 0, 255, nil, nil)
        end
    end
end

--[[
    创建双棋盘的提醒
]]
function CodeGameScreenMuchoChilliMachine:createDoubleReelFeature( )
    self.m_respinFeatureDoubleNode = {}
    local featureTypeName = {"bonusBoost", "doubleSet", "extraSpin"}
    -- bonus玩法需要显示三种
    for index=1,3 do
        -- respin 类型提醒
        self.m_respinFeatureDoubleNode[index] = util_createAnimation("MuchoChilli_RespinFeatureName.csb")
        self:findChild("Feature"..index):addChild(self.m_respinFeatureDoubleNode[index])
        self.m_respinFeatureDoubleNode[index]:setVisible(false)
        self:showRespinFeatureType(self.m_respinFeatureDoubleNode[index], featureTypeName[index])
    end
    
    -- 三选一玩法显示一种
    -- respin 类型提醒
    self.m_respinFeatureDoubleNode[4] = util_createAnimation("MuchoChilli_RespinFeatureName.csb")
    self:findChild("Feature1"):addChild(self.m_respinFeatureDoubleNode[4])
    self.m_respinFeatureDoubleNode[4]:setVisible(false)
    self:showRespinFeatureType(self.m_respinFeatureDoubleNode[4], "doubleSet")
end

--[[
    显示不同提醒类型
]]
function CodeGameScreenMuchoChilliMachine:showRespinFeatureType(_node, _type)
    _node:findChild("Node_Feature1"):setVisible(_type == "bonusBoost")
    _node:findChild("Node_Feature2"):setVisible(_type == "doubleSet")
    _node:findChild("Node_Feature3"):setVisible(_type == "extraSpin")
end

--[[
    不同小玩法下显示 feature
]]
function CodeGameScreenMuchoChilliMachine:showRespinFeature(_isShow)
    local reSpinMode =  self:getRespinType() 

    if reSpinMode == "bonusBoost" then
        self:showRespinFeatureType(self.m_respinFeatureNode, "bonusBoost")
        self.m_respinFeatureNode:setVisible(_isShow == true)
    elseif reSpinMode == "extraSpin" then
        self:showRespinFeatureType(self.m_respinFeatureNode, "extraSpin")
        self.m_respinFeatureNode:setVisible(_isShow == true)
    elseif reSpinMode == "doubleSet" then
        self.m_respinFeatureDoubleNode[4]:setVisible(_isShow == true)
    else
        for index = 1, 3 do
            self.m_respinFeatureDoubleNode[index]:setVisible(_isShow == true)
        end
    end
end

--[[
    base下点击角色
]]
function CodeGameScreenMuchoChilliMachine:clickBigRole( )
    -- 点击事件
    local Panel = self:findChild("Panel_click")
    Panel:addTouchEventListener(function(...)
        return self:playCilckBigRoleEffect()
    end)
end

--[[
    base下点击角色 反馈动画
]]
function CodeGameScreenMuchoChilliMachine:playCilckBigRoleEffect()
    -- 只在base下点击
    if self:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
        return
    end

    -- 触发玩法的时候 不点击
    local features = self.m_runSpinResultData.p_features or {}
    if #features > 1 then
        return
    end

    -- 放住连续点击
    if self.m_isCanClickRole then
        return 
    end

    if self.m_bigRoleStage == 1 or self.m_bigRoleStage == 2 then
        local random = math.random(1, 2)
        local randomSound = math.random(1, 100)
        if randomSound <= 20 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_MuchoChilli_click_role_stage"..self.m_bigRoleStage.. "_"..random])
        end
    end
    self.m_isCanClickRole = true
    self:playBigRoleEffect("fankui")
end

--[[
    随机播放大角色idle动画
]]
function CodeGameScreenMuchoChilliMachine:playRoleIdle(_stage)
    self.m_playRoleIdleIndex = self.m_playRoleIdleIndex + 1
    local idleframeName = ""
    local random = math.random(1, 100)
    if random <= 50 then
        idleframeName = "idleframe"..((_stage-1)*3+1)
    else
        if _stage == 1 then
            idleframeName = "idleframe"
        elseif _stage == 2 then
            idleframeName = "idleframe3"
        elseif _stage == 3 then
            idleframeName = "idleframe6"
        end
    end
    if self.m_playRoleIdleIndex > 2 then
        local random = math.random(1, 100)
        if random <= 5 then
            idleframeName = "idleframe"..((_stage-1)*3+2)
            self.m_playRoleIdleIndex = 0
        end
    end

    util_spinePlay(self.m_bigRole, idleframeName, false)
    util_spineEndCallFunc(self.m_bigRole, idleframeName ,function ()
        self:playRoleIdle(self.m_bigRoleStage)
    end)
end

--[[
    respin玩法里随机播放idle
]]
function CodeGameScreenMuchoChilliMachine:playRoleIdleByRespin( )
    local random = math.random(1, 100)
    local idleName = "idleframe9"
    if random <= 30 then
        idleName = "idleframe10"
    end
    util_spinePlay(self.m_bigRole, idleName, false)
    util_spineEndCallFunc(self.m_bigRole, idleName ,function ()
        self:playRoleIdleByRespin()
    end)
end

--[[
    大角色动画
]]
function CodeGameScreenMuchoChilliMachine:playBigRoleEffect(_actionframe)
    local idleframeName
    if self.m_bigRoleStage == 1 then
        idleframeName = _actionframe
    else
        idleframeName = _actionframe .. (self.m_bigRoleStage - 1)
    end
    util_spinePlay(self.m_bigRole, idleframeName, false)
    util_spineEndCallFunc(self.m_bigRole, idleframeName ,function ()
        self:playRoleIdle(self.m_bigRoleStage)
    end)

    if _actionframe == "fankui" then
        self:delayCallBack(35/30, function()
            self.m_isCanClickRole = false
        end)
    end
end

--[[
    大角色阶段变化
]]
function CodeGameScreenMuchoChilliMachine:changeBigRoleStage( )
    local newBigRoleStage = 1
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.bonusProgress then
        newBigRoleStage = self.m_runSpinResultData.p_selfMakeData.bonusProgress
    end

    -- 阶段不变化
    if self.m_bigRoleStage == newBigRoleStage then
        self:playRoleIdle(self.m_bigRoleStage)
    else-- 触发了 阶段变化
        -- 第一阶段直接变成第二阶段
        if self.m_bigRoleStage == 1 and newBigRoleStage == 2 then
            self:changeBigRoleStageEffect("switch1", newBigRoleStage)
        end

        -- 第一阶段直接变成第三阶段
        if self.m_bigRoleStage == 1 and newBigRoleStage == 3 then
            self:changeBigRoleStageEffect("switch3", newBigRoleStage)
            self:setReelBg(4, true)
        end

        -- 第二阶段直接变成第三阶段
        if self.m_bigRoleStage == 2 and newBigRoleStage == 3 then
            self:changeBigRoleStageEffect("switch2", newBigRoleStage)
            self:setReelBg(4, true)
        end
    end
end

--[[
    获得大角色是否发生阶段变化
]]
function CodeGameScreenMuchoChilliMachine:getIsBigRoleChangeStage( )
    local newBigRoleStage = 1
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.bonusProgress then
        newBigRoleStage = self.m_runSpinResultData.p_selfMakeData.bonusProgress
    end
    if self.m_bigRoleStage == newBigRoleStage then
        return false
    end 
    return true
end
--[[
    大角色阶段变化动画
]]
function CodeGameScreenMuchoChilliMachine:changeBigRoleStageEffect(_actionframe, _newBigRoleStage)
    self.m_bigRoleStage = _newBigRoleStage
    util_spinePlay(self.m_bigRole, _actionframe, false)
    util_spineEndCallFunc(self.m_bigRole, _actionframe ,function ()
        self:playRoleIdle(self.m_bigRoleStage)
    end)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_role_switch)

    self.m_bigRoleShengJiEffect:setVisible(true)
    self.m_bigRoleShengJiEffect:runCsbAction("shengji", false, function()
        self.m_bigRoleShengJiEffect:setVisible(false)
    end)

    if _newBigRoleStage == 3 then
        local kuangSpineNode = util_spineCreate("MuchoChilli_base_juesekuang", true, true)
        self:findChild("Node_juesekuang"):addChild(kuangSpineNode)

        util_spinePlay(kuangSpineNode, "idleframe3", false)
        util_spineEndCallFunc(kuangSpineNode, "idleframe3" ,function ()
            self:delayCallBack(0.1, function()
                kuangSpineNode:removeFromParent()
            end)
        end)

        self.m_bigRoleKuangHuo:setVisible(true)
        util_spinePlay(self.m_bigRoleKuangHuo, "idleframe2", true)
        util_spinePlay(self.m_bigRoleKuang, "idleframe4", true)
    else
        self.m_bigRoleKuangHuo:setVisible(false)
        util_spinePlay(self.m_bigRoleKuang, "idleframe", true)
    end
end

--[[
    大角色触发动画
]]
function CodeGameScreenMuchoChilliMachine:playBigRoleTriggerEffect(_func)
    -- 停掉背景音乐
    self:clearCurMusicBg()
    
    self:delayCallBack(41/30, function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_penhuo)
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_jackpot_respin_bonus_role_trigger)
    
    -- 大角色触发
    util_spinePlay(self.m_bigRole, "actionframe", false)
    util_spineEndCallFunc(self.m_bigRole, "actionframe" ,function ()
        self:playRoleIdle(self.m_bigRoleStage)
        if _func then
            _func()
        end
    end)

    local kuangSpineNode = util_spineCreate("MuchoChilli_base_juesekuang", true, true)
    self:findChild("Node_juesekuang"):addChild(kuangSpineNode)

    util_spinePlay(kuangSpineNode, "idleframe1", false)
    util_spineEndCallFunc(kuangSpineNode, "idleframe1" ,function ()
        self:delayCallBack(0.1, function()
            kuangSpineNode:removeFromParent()
        end)
    end)

    self:delayCallBack(55/30, function()
        local huoSpineNode = util_spineCreate("MuchoChilli_GC", true, true)
        self:findChild("Node_yugao"):addChild(huoSpineNode)

        util_spinePlay(huoSpineNode, "actionframe", false)
        util_spineEndCallFunc(huoSpineNode, "actionframe" ,function ()
            self:delayCallBack(0.1, function()
                huoSpineNode:removeFromParent()
            end)
        end)
    end)
end

--[[
    进入 结束respin玩法的时候 大角色相关
    bonusBoost extraSpin 切换动画
    doubleSet 不显示大角色
]]
function CodeGameScreenMuchoChilliMachine:changeBigRoleByRespin(_isBeginRespin)
    local reSpinMode = self:getRespinType()

    if _isBeginRespin then
        
        if reSpinMode == "bonusBoost" or reSpinMode == "extraSpin" then
            self:playRoleIdleByRespin()
        elseif reSpinMode == "doubleSet" or reSpinMode == nil then
            self.m_bigRole:setVisible(false)
        end
        self.m_bigRoleKuang:setVisible(false)
    else
        if self:getRespinType() == nil then
            self.m_bigRoleStage = 1
        end
        self.m_bigRole:setVisible(true)
        self.m_bigRoleKuang:setVisible(true)
        self:playRoleIdle(self.m_bigRoleStage)
    end
end

function CodeGameScreenMuchoChilliMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_freegames")
    self.m_baseFreeSpinBar = util_createView("CodeMuchoChilliSrc.MuchoChilliFreespinBarView",{machine = self})
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)

    -- respin 计数框
    self.m_respinBarView = util_createView("CodeMuchoChilliSrc.MuchoChilliRespinBar", {machine = self})
    self:findChild("Node_SingleBoard"):addChild(self.m_respinBarView)
    self.m_respinBarView:setVisible(false)
end

function CodeGameScreenMuchoChilliMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )

        self:playEnterGameSound( self.m_publicConfig.SoundConfig.sound_MuchoChilli_enter_game )
       
    end,0.4,self:getModuleName())
end

function CodeGameScreenMuchoChilliMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_isDuanXian = true
    CodeGameScreenMuchoChilliMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:playRoleIdle(self.m_bigRoleStage)
    if self.m_bigRoleStage == 3 then
        util_spinePlay(self.m_bigRoleKuang, "idleframe4", true)
    else
        util_spinePlay(self.m_bigRoleKuang, "idleframe", true)
    end

    -- 进入关卡先初始化一遍jackpot解锁情况
    self:changeBetCallBack(nil, true)
end

function CodeGameScreenMuchoChilliMachine:addObservers()
    CodeGameScreenMuchoChilliMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
        end

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_MuchoChilli_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_MuchoChilli_winLines" .. soundIndex]
        end

        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)


    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            -- 切换bet解锁进度条
            self:changeBetCallBack()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    -- 点击解锁jackpot
    gLobalNoticManager:addObserver(self,function(self,params)

        if self:isNormalStates( ) then
            if self.m_iBetLevel == 0 then
                self:unlockHigherBet()
            end
        end
    end,"SHOW_UNLOCK_JACKPOT")

end

function CodeGameScreenMuchoChilliMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMuchoChilliMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMuchoChilliMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_EMPTY then
        return "Socre_MuchoChilli_Empty"
    end

    if symbolType == self.SYMBOL_BONUS then
        return "Socre_MuchoChilli_Bonus1"
    end

    if symbolType == self.SYMBOL_SPECIAL_BONUS then
        return "Socre_MuchoChilli_Bonus"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_MuchoChilli_10"
    end

    if symbolType == self.SYMBOL_LOCAL_BONUS then
        return "Socre_MuchoChilli_Common_Bonus"
    end

    if symbolType == self.SYMBOL_LOCAL_SPECIAL_BONUS then
        return "Socre_MuchoChilli_Special_Bonus"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMuchoChilliMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMuchoChilliMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECIAL_BONUS,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count = 2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LOCAL_BONUS,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_LOCAL_SPECIAL_BONUS,count = 2}

    return loadNode
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenMuchoChilliMachine:initGameStatusData(gameData)
    if gameData.feature then
        gameData.spin.selfData = gameData.feature.selfData
        gameData.spin.reels = gameData.feature.reels
        gameData.spin.storedIcons = gameData.feature.storedIcons
        gameData.spin.respin = gameData.feature.respin
        gameData.spin.features = gameData.feature.features
    end
    if not self.m_specialBets then
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    CodeGameScreenMuchoChilliMachine.super.initGameStatusData(self, gameData)
    if gameData.spin then
        if gameData.spin.selfData and gameData.spin.selfData.bonusProgress then
            self.m_bigRoleStage = gameData.spin.selfData.bonusProgress
        end
    end
end

-- 初始化小块时 规避某个信号接口 （包含随机创建的两个函数，根据网络消息创建的函数）
function CodeGameScreenMuchoChilliMachine:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        -- bonus玩法 94要显示成95 
        if self:getRespinType() == nil then
            if symbolType == self.SYMBOL_BONUS then
                return self.SYMBOL_SPECIAL_BONUS
            end
        else-- respin玩法 95 要显示成94
            if symbolType == self.SYMBOL_SPECIAL_BONUS then
                return self.SYMBOL_BONUS
            end
        end
    else
        if self:checkHasFeature() then
            if symbolType == self.SYMBOL_SPECIAL_BONUS then
                return self.SYMBOL_BONUS
            end
        end
    end
    return symbolType
end

--[[
    切换bet jackpot变化
]]
function CodeGameScreenMuchoChilliMachine:changeBetCallBack(_betCoins, _isFirstComeIn)
    self.m_iBetLevel = 0
    local betCoins =_betCoins or globalData.slotRunData:getCurTotalBet()

    for _betLevel,_betData in ipairs(self.m_specialBets) do
        if betCoins < _betData.p_totalBetValue then
            break
        end
        self.m_iBetLevel = _betLevel
    end

    -- 上锁
    if self.m_iBetLevel == 0 then
        self.m_baseJackpotView:lockGrand(_isFirstComeIn)
    -- 解锁
    else
        self.m_baseJackpotView:unLockGrand(_isFirstComeIn)
    end
end

--[[
    点击解锁jackpot
]]
function CodeGameScreenMuchoChilliMachine:unlockHigherBet()
    if self.m_bProduceSlots_InFreeSpin == true or
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and
    self:getGameSpinStage() ~= IDLE ) or
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end

    self.m_baseJackpotView:unLockGrand()

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

--[[
    判断是否可以点击解锁
]]
function CodeGameScreenMuchoChilliMachine:isNormalStates( )
    
    local featureLen = self.m_runSpinResultData.p_features or {}

    if #featureLen >= 2 then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        return false
    end

    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return false
    end

    return true
end

--[[
    获取解锁进度条对应的bet
]]
function CodeGameScreenMuchoChilliMachine:getMinBet()
    local minBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end
    return minBet
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenMuchoChilliMachine:MachineRule_initGame(  )
    self.m_isDuanXian = true
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:setReelBg(2)
    else
        if self.m_bigRoleStage == 3 then
            self:setReelBg(4)
        else
            self:setReelBg(1)
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenMuchoChilliMachine:slotOneReelDown(reelCol)    
    local isTriggerLongRun = CodeGameScreenMuchoChilliMachine.super.slotOneReelDown(self,reelCol) 
    if not self.m_isTriggerLongRun then
        self.m_isTriggerLongRun = isTriggerLongRun
    end

    return isTriggerLongRun
   
end

function CodeGameScreenMuchoChilliMachine:symbolBulingEndCallBack(_symbolNode)

    if _symbolNode and (_symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _symbolNode.p_symbolType == self.SYMBOL_BONUS or
        _symbolNode.p_symbolType == self.SYMBOL_SPECIAL_BONUS) then
        if self.m_isTriggerLongRun and _symbolNode.p_cloumnIndex ~= self.m_iReelColumnNum then
            local Col = _symbolNode.p_cloumnIndex
            for iCol = 1, Col do
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol,iRow)
                    if symbolNode and symbolNode.p_symbolType and symbolNode.m_currAnimName ~= "idleframe3" then
                        if self.m_showScatterQuick then 
                            if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                                symbolNode:runAnim("idleframe3", true)
                            end
                            if symbolNode.m_currAnimName ~= "idleframe2" and (symbolNode.p_symbolType == self.SYMBOL_BONUS or symbolNode.p_symbolType == self.SYMBOL_SPECIAL_BONUS) then
                                symbolNode:runAnim("idleframe2", true)
                            end
                        end
                        if self.m_showBonusQuick then 
                            if (symbolNode.p_symbolType == self.SYMBOL_BONUS or symbolNode.p_symbolType == self.SYMBOL_SPECIAL_BONUS) then
                                symbolNode:runAnim("idleframe3", true)
                            end
                            if symbolNode.m_currAnimName ~= "idleframe2" and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                                symbolNode:runAnim("idleframe2", true)
                            end
                        end
                    end
                end
            end
        else
            _symbolNode:runAnim("idleframe2", true)
        end
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenMuchoChilliMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                if _slotNode.p_symbolType == self.SYMBOL_BONUS or _slotNode.p_symbolType == self.SYMBOL_SPECIAL_BONUS then
                    if _slotNode.p_cloumnIndex < self.m_iReelColumnNum then
                        return true
                    else
                        if self:getReelsBonusNums() > 1 then
                            return true
                        else
                            return false
                        end
                    end
                end
                return true
            end
        end
    end

    return false
end

--[[
    获取服务器数据 前四列bonus个数
]]
function CodeGameScreenMuchoChilliMachine:getReelsBonusNums()
    local reels = self.m_runSpinResultData.p_reels or {}
    local bonusNums = 0
    for _row, _colData in ipairs(reels) do
        for _col, _symbolType in ipairs(_colData) do
            if _col < self.m_iReelColumnNum and (_symbolType == self.SYMBOL_BONUS or _symbolType == self.SYMBOL_SPECIAL_BONUS) then
                bonusNums = bonusNums + 1
            end
        end
    end
    return bonusNums
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMuchoChilliMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMuchoChilliMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

-- 显示free spin
function CodeGameScreenMuchoChilliMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self:stopLinesWinSound()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end

    if scatterLineValue ~= nil then
        --
        self:delayCallBack(0.5, function()
            -- 角色动画
            self:playBigRoleEffect("daying")

            self:showBonusAndScatterLineTip(
                scatterLineValue,
                function()
                    -- self:visibleMaskLayer(true,true)
                    -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                    self:delayCallBack(0.5, function()
                        self:showFreeSpinView(effectData)
                    end)
                end
            )
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue

            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                -- 播放提示时播放音效
                self:playScatterTipMusicEffect()
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_freeMore_trigger)
            end
        end)
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

---
----- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenMuchoChilliMachine:showBonusAndScatterLineTip(lineValue, callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=symPosData.iX})
        if slotNode == nil then
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX)
        end

        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]
                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=bigSymbolInfo.startRowIndex})
                        break
                    end
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end
    animTime = animTime - 0.3
    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenMuchoChilliMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("MuchoChilliSounds/music_MuchoChilli_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_freeMoreView)

            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                self.m_baseFreeSpinBar:playFreeMoreEffect()

                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:playGuoChangFreeEffect(function()
                    self:setReelBg(2)
                    self:triggerFreeSpinCallFun()
                end, function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_freeStartView_start)
            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_MuchoChilli_click
            view:setBtnClickFunc(function(  )
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_freeStartView_over)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenMuchoChilliMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(
        function()
            self:resetTriggerEffectNodes()
            callFun()
        end,
        animTime,
        self:getModuleName()
    )
end

function CodeGameScreenMuchoChilliMachine:resetTriggerEffectNodes()
    for lineNodeIndex = 1, #self.m_lineSlotNodes do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]
        if lineNode ~= nil then
            lineNode:runIdleAnim()
        end
    end
end

function CodeGameScreenMuchoChilliMachine:showFreeSpinOverView()
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:playGuoChangFreeEffect(function()
                self.m_baseFreeSpinBar:setVisible(false)

                if self.m_bigRoleStage == 3 then
                    self:setReelBg(4)
                else
                    self:setReelBg(1)
                end
            end, function()
                self:triggerFreeSpinOverCallFun()
            end)
    end)
    if globalData.slotRunData.lastWinCoin ~= 0 then
        local node=view:findChild("m_lb_coins")
        if node then
            view:updateLabelSize({label=node,sx=1,sy=1},560)
        end
        local numNode = view:findChild("m_lb_num")
        if numNode then
            if tonumber(self.m_runSpinResultData.p_freeSpinsTotalCount) > 99 then
                numNode:setScale(0.8)
            else
                numNode:setScale(1)
            end
        end
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_freeOverView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_MuchoChilli_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_freeOverView_over)
    end)
end

function CodeGameScreenMuchoChilliMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    if coins == "0" then
        return self:showDialog("NoWin",ownerlist,func)
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    end
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMuchoChilliMachine:MachineRule_SpinBtnCall()
    -- 重置数据
    self.m_isTriggerLongRun = false
    self.m_showScatterQuick = false --是否存在scatter快滚
    self.m_showBonusQuick = false --是否存在bonus快滚
    self.m_isDuanXian = false
    self:stopLinesWinSound()

    self:setMaxMusicBGVolume( )
    return false -- 用作延时点击spin调用
end

function CodeGameScreenMuchoChilliMachine:beginReel()
    self:showColorLayer()

    CodeGameScreenMuchoChilliMachine.super.beginReel(self)
end

--重写列停止
function CodeGameScreenMuchoChilliMachine:reelSchedulerCheckColumnReelDown(parentData)
    local  slotParent = parentData.slotParent
    if parentData.isDone ~= true then
        parentData.isDone = true
        slotParent:stopAllActions()
        local slotParentBig = parentData.slotParentBig 
        if slotParentBig then
            slotParentBig:stopAllActions()
        end
        self:slotOneReelDown(parentData.cloumnIndex)
        local speedActionTable = nil
        local addTime = nil
        local quickStopY = -35 --快停回弹距离
        if self.m_quickStopBackDistance then
            quickStopY = -self.m_quickStopBackDistance
        end
        -- local quickStopY = -self.m_configData.p_reelResDis --不读取配置
        if self.m_isNewReelQuickStop then
            slotParent:setPositionY(quickStopY)
            if slotParentBig then
                slotParentBig:setPositionY(quickStopY)
            end
            speedActionTable = {}
            speedActionTable[1], addTime = self:MachineRule_BackAction(slotParent, parentData)
        else
            speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
        end
        if slotParentBig then
            local seq = cc.Sequence:create(speedActionTable)
            slotParentBig:runAction(seq:clone())
        end
        local tipSlotNoes = nil
        local nodeParent = parentData.slotParent
        local nodes = nodeParent:getChildren()
        if slotParentBig then
            local nodesBig = slotParentBig:getChildren()
            for i=1,#nodesBig do
                nodes[#nodes+1]=nodesBig[i]
            end
        end

        -- 播放配置信号的落地音效
        self:playSymbolBulingSound(nodes)
        -- 播放配置信号的落地动效
        self:playSymbolBulingAnim(nodes, speedActionTable)

        --添加提示节点
        tipSlotNoes = self:addReelDownTipNode(nodes)
 
        if tipSlotNoes ~= nil then
            local nodeParent = parentData.slotParent
            for i = 1, #tipSlotNoes do
                --播放提示动画
                self:playReelDownTipNode(tipSlotNoes[i])
            end -- end for
        end

        self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)

        local actionFinishCallFunc = cc.CallFunc:create(
        function()
            parentData.isResActionDone = true
            if self.m_quickStopReelIndex and self.m_quickStopReelIndex == parentData.cloumnIndex then
                self:newQuickStopReel(self.m_quickStopReelIndex)
            end
            self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
        end)

        
        speedActionTable[#speedActionTable + 1] = actionFinishCallFunc
        slotParent:runAction(cc.Sequence:create(speedActionTable))

        self:reelStopHideMask(parentData.cloumnIndex)
    end
    return 0.1
end

function CodeGameScreenMuchoChilliMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        return true
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMuchoChilliMachine:addSelfEffect()
    if #self:isTriggerBonusCollect() > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMuchoChilliMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
        self:collectSpecialBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
	return true
end

--[[
    判断是否触发收集辣椒
]]
function CodeGameScreenMuchoChilliMachine:isTriggerBonusCollect()
    local reels = self.m_runSpinResultData.p_reels or {}
    local specialBonusList = {}
    for _row, _colData in ipairs(reels) do
        for _col, _symbolType in ipairs(_colData) do
            if _symbolType == self.SYMBOL_SPECIAL_BONUS then
                local pos = (_row - 1) * self.m_iReelColumnNum + (_col - 1)
                table.insert(specialBonusList, pos)
            end
        end
    end
    return specialBonusList
end

--[[
    收集特殊bonus
]]
function CodeGameScreenMuchoChilliMachine:collectSpecialBonus(_func)
    local specialBonusList = self:isTriggerBonusCollect()
    for _index, _pos in ipairs(specialBonusList) do
        local fixPos = self:getRowAndColByPos(_pos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if slotsNode and slotsNode.p_symbolType then
            if _index == 1 then
                self:delayCallBack(5/50, function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_special_bonus_fly)
                end)
            end
            self:playBonusSymbolCollectAnim(slotsNode, function()
                if _index == #specialBonusList then
                    local delayTime = 6/30
                    if self:isTriggerBonus() then
                        delayTime = 0
                    end

                    if self:isTriggerBonus() or self:getRespinType() ~= nil then
                        self.m_skipNode:stopAllActions()
                    end

                    self:delayCallBack(delayTime, function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_special_bonus_fly_end)

                        -- 角色反馈动画
                        util_spinePlay(self.m_bigRole, "shouji"..self.m_bigRoleStage, false)
                        util_spineEndCallFunc(self.m_bigRole, "shouji"..self.m_bigRoleStage, function ()
                            if not self:isTriggerBonus() then
                                self:changeBigRoleStage()
                            else
                                -- 第一阶段直接变成第三阶段
                                if self.m_bigRoleStage == 1 then
                                    self:changeBigRoleStageEffect("switch3", 3)
                                end

                                -- 第二阶段直接变成第三阶段
                                if self.m_bigRoleStage == 2 then
                                    self:changeBigRoleStageEffect("switch2", 3)
                                end
                            end
                        end)

                        -- 界面上的反馈动画
                        self.m_fanKuiEffect:setVisible(true)
                        self.m_fanKuiEffect:runCsbAction("jsfankui", false, function()
                            self.m_fanKuiEffect:setVisible(false)
                        end)
                    end)
                    
                    if not self:isTriggerBonus() and not self:getIsBigRoleChangeStage() then
                        if _func then
                            _func()
                        end
                    else
                        performWithDelay(self.m_skipNode, function()
                            if _func then
                                _func()
                            end
                        end, (20+50)/30)
                    end
                end
            end)
        end
    end
end

--[[
    收集特殊bonus 飞行动画
]]
function CodeGameScreenMuchoChilliMachine:playBonusSymbolCollectAnim(_slotsNode, _func)
    local startPos = util_convertToNodeSpace(_slotsNode, self.m_effectNode)
    local endPos = util_convertToNodeSpace(self:findChild("Node_collect"), self.m_effectNode)

    local flyNode = util_createAnimation("MuchoChilli_lizi.csb")
    flyNode.bonusSpine = util_spineCreate("Socre_MuchoChilli_Bonus", true, true)
    flyNode:findChild("Node_spine"):addChild(flyNode.bonusSpine)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local particle = nil
    if not tolua.isnull(flyNode) then
        particle = flyNode:findChild("Particle_1")
        if particle then
            particle:setDuration(1)     --设置拖尾时间(生命周期)
            particle:setPositionType(0)   --设置可以拖尾
            particle:resetSystem()
        end
    end

    util_spinePlay(flyNode.bonusSpine, "shouji_2", false)

    flyNode:runAction(cc.Sequence:create(
        cc.DelayTime:create(5/50),
        cc.CallFunc:create(function()
            if not self:isTriggerBonus() then
                self:changeSpecialBonus(_slotsNode, _func)
            end
        end),
        cc.MoveTo:create(12/30, endPos),
        cc.CallFunc:create(function()
            if self:isTriggerBonus() then
                if _func then
                    _func()
                end
            end
            if particle then
                particle:stopSystem()
            end
            flyNode.bonusSpine:setVisible(false)
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
end

--[[
    收集之后 特殊bonus 变成普通bonus
]]
function CodeGameScreenMuchoChilliMachine:changeSpecialBonus(_slotsNode, _func)
    -- 特殊bonus 变成普通bonus
    _slotsNode:runAnim("bian", false, function()
        self:changeSymbolType(_slotsNode, self.SYMBOL_BONUS)
        self:setSpecialNodeScore(_slotsNode)
        _slotsNode:runAnim("idleframe2", true)
        if _func then
            _func()
        end
    end)
end

--[[
    判断是否触发bonus玩法
]]
function CodeGameScreenMuchoChilliMachine:isTriggerBonus()
    local features = self.m_runSpinResultData.p_features or {}
    if #features == 2 and features[2] == 3 and self:getRespinType() == nil then
        return true
    end
    return false
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenMuchoChilliMachine:showBigWinLight(func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bigwin_yugao)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_MuchoChilli_bigwin_yugao_say"..self.m_playBigWinSayIndex])
    self.m_playBigWinSayIndex = self.m_playBigWinSayIndex + 1
    if self.m_playBigWinSayIndex > 2 then
        self.m_playBigWinSayIndex = 1
    end

    self.m_bigWinEffect:setVisible(true)

    util_spinePlay(self.m_bigWinEffect, "actionframe")
    util_spineEndCallFunc(self.m_bigWinEffect, "actionframe", function()
        self.m_bigWinEffect:setVisible(false)
        if func then
            func()
        end
    end)

    -- 角色动画
    self:playBigRoleEffect("daying")
end

-- 播放预告中奖统一接口
-- 子类重写接口
function CodeGameScreenMuchoChilliMachine:showFeatureGameTip(_func)
    local isShow = self:getFeatureGameTipChance()

    if isShow then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_yugao)
        -- 播放预告动画,播放完毕后调用func
        self.b_gameTipFlag = true
        self.m_yugaoSpineEffect:setVisible(true)
        util_spinePlay(self.m_yugaoSpineEffect,"actionframe_yugao",false)
        util_spineEndCallFunc(self.m_yugaoSpineEffect, "actionframe_yugao" ,function ()
            self.m_yugaoSpineEffect:setVisible(false)
            if _func then
                _func()
            end 
        end)
    else
        if _func then
            _func()
        end 
    end
end

--[[
    播放预告中奖概率
]]
function CodeGameScreenMuchoChilliMachine:getFeatureGameTipChance()
    local isNotice = false
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if featureDatas and #featureDatas > 1 then
        isNotice = (math.random(1, 100) <= 40)
    end

    return isNotice
end

function CodeGameScreenMuchoChilliMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenMuchoChilliMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenMuchoChilliMachine:slotReelDown( )

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            --只有播期待的恢复idle状态
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName == "idleframe3" then
                local ccbNode = symbolNode:getCCBNode()
                if ccbNode then
                    util_spineMix(ccbNode.m_spineNode, symbolNode.m_currAnimName, "idleframe2", 0.5)
                end
                symbolNode:runAnim("idleframe2", true)
            end

            -- bonus
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_BONUS and symbolNode.m_currAnimName == "idleframe3" then
                local ccbNode = symbolNode:getCCBNode()
                if ccbNode then
                    util_spineMix(ccbNode.m_spineNode, symbolNode.m_currAnimName, "idleframe2", 0.5)
                end
                symbolNode:runAnim("idleframe2", true)
            end
        end
    end

    if self.m_isTriggerLongRun then
        local features = self.m_runSpinResultData.p_features or {}
        local random = math.random(1, 100)
        if features and #features < 2 and random <= 40 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_no_feature_quickRun)
        end
    end
    
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenMuchoChilliMachine.super.slotReelDown(self)
end

function CodeGameScreenMuchoChilliMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    刷新小块
]]
function CodeGameScreenMuchoChilliMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    end

    if self:isFixLocalSymbol(symbolType) then
        self:setLocalSpecialNodeScore(node)
    end
end

--[[
    判断是否为bonus小块
]]
function CodeGameScreenMuchoChilliMachine:isFixSymbol(symbolType)
    local bonusAry = {
        self.SYMBOL_BONUS,
        self.SYMBOL_SPECIAL_BONUS
    }

    for k,bonusType in pairs(bonusAry) do
        if symbolType == bonusType then
            return true
        end
    end
    
    return false
end

--[[
    判断是否为bonus小块 只有用在假滚
]]
function CodeGameScreenMuchoChilliMachine:isFixLocalSymbol(symbolType)
    local bonusAry = {
        self.SYMBOL_LOCAL_BONUS,
        self.SYMBOL_LOCAL_SPECIAL_BONUS
    }

    for k,bonusType in pairs(bonusAry) do
        if symbolType == bonusType then
            return true
        end
    end
    
    return false
end

--[[
    给bonus信号块上的数字进行赋值 
]]
function CodeGameScreenMuchoChilliMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if self:isFixSymbol(symbolNode.p_symbolType) then
        -- 展示
        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        local coinsView
        if not spineNode.m_csbNode then
            coinsView = util_createAnimation("Socre_MuchoChilli_Bonus_Coins.csb")
            util_spinePushBindNode(spineNode,"shuzi",coinsView)
            spineNode.m_csbNode = coinsView
        else
            spineNode.m_csbNode:setVisible(true)
            coinsView = spineNode.m_csbNode
        end

        local score = 0
        local type = nil
        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            local pos = self:getPosReelIdx(iRow,iCol)
            score, type = self:getReSpinSymbolScore(pos, not self.m_isDuanXian)
        else
            score, type = self:randomDownRespinSymbolScore(symbolNode)
        end
        self:showBonusJackpotOrCoins(coinsView, score, type)
    end
end

--[[
    给bonus信号块上的数字进行赋值 只有用在假滚
]]
function CodeGameScreenMuchoChilliMachine:setLocalSpecialNodeScore(symbolNode)
    if self:isFixLocalSymbol(symbolNode.p_symbolType) then
        if #symbolNode:getCcbProperty("Node_Num"):getChildren() > 0 then
            local child = symbolNode:getCcbProperty("Node_Num"):getChildren()
            for index = 1, #child do
                child[index]:removeFromParent()
                child[index] = nil
            end
        end
        local coinsView = util_createAnimation("Socre_MuchoChilli_Bonus_Coins.csb")
        symbolNode:getCcbProperty("Node_Num"):addChild(coinsView)

        local score = 0
        local type = nil
        score, type = self:randomDownRespinSymbolScore(symbolNode)
        self:showBonusJackpotOrCoins(coinsView, score, type)
    end
end

--[[
    显示bonus上的信息
]]
function CodeGameScreenMuchoChilliMachine:showBonusJackpotOrCoins(coinsView, score, type)
    if coinsView then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        coinsView:findChild("Node_1"):setVisible(false)
        coinsView:findChild("Node_multiplierJackpot"):setVisible(false)
        coinsView:findChild("Node_jackpot"):setVisible(false)

        if type == "bonus" then
            coinsView:findChild("Node_1"):setVisible(true)
            local multi = score / lineBet
            local labCoins = coinsView:findChild("m_lb_num")
            if multi >= 5 then
                labCoins = coinsView:findChild("m_lb_num_high")
                coinsView:findChild("m_lb_num"):setVisible(false)
                coinsView:findChild("m_lb_num_high"):setVisible(true)
            else
                coinsView:findChild("m_lb_num"):setVisible(true)
                coinsView:findChild("m_lb_num_high"):setVisible(false)
            end
            labCoins:setString(util_formatCoins(score, 3, false, true, true))
            self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 145)
        else  
            coinsView:findChild("Node_jackpot"):setVisible(true)
            coinsView:findChild("grand"):setVisible(type == "Grand")
            coinsView:findChild("mega"):setVisible(type == "Mega")
            coinsView:findChild("major"):setVisible(type == "Major")
            coinsView:findChild("minor"):setVisible(type == "Minor")
            coinsView:findChild("mini"):setVisible(type == "Mini")
        end
    end
end
--[[
    棋盘是否集满
]]
function CodeGameScreenMuchoChilliMachine:isJiManReels( )
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    if #storedIcons >= 15 then
        return true
    end
    return false
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenMuchoChilliMachine:getReSpinSymbolScore(_pos, _isAdd)
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local addStoredIcons = selfMakeData.addStoredIcons or {}
    local score = nil
    local type = nil

    for _index, _storeData in pairs(storedIcons) do
        if tonumber(_storeData[1]) == _pos then
            score = _storeData[2]
            type = _storeData[3]
            break
        end
    end

    --respin玩法里 如果有加钱的话 刚滚出来的 先减去加的钱
    if score and _isAdd then
        for _index, _addStoreData in ipairs(addStoredIcons) do
            if tonumber(_addStoreData[1]) == _pos then
                score = score - _addStoreData[2]
                break
            end
        end 
    end

    if score == nil then
       return 0
    end

    return score, type
end

function CodeGameScreenMuchoChilliMachine:randomDownRespinSymbolScore(symbolNode)
    local symbolType = symbolNode.p_symbolType
    local score = 0
    local type = nil
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self:isFixSymbol(symbolType) or self:isFixLocalSymbol(symbolType) then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
        if self.m_isDuanXian then
            symbolNode:runAnim("idleframe2", true)
            local iCol = symbolNode.p_cloumnIndex
            local iRow = symbolNode.p_rowIndex
            if iRow == 2 and iCol == 1 then
                score = "Grand"
            elseif iRow == 2 and iCol == 5 then
                score = "Mega"
            else
                score = "3"
            end
        end
        if score == "Grand" then
            score = 0
            type = "Grand"
        elseif score == "Mega" then
            score = 0
            type = "Mega"
        elseif score == "Major" then
            score = 0
            type = "Major"
        elseif score == "Minor" then
            score = 0
            type = "Minor"
        elseif score == "Mini" then
            score = 0
            type = "Mini"
        else
            score = tonumber(score) * lineBet
            type = "bonus"
        end
    end

    return score, type
end

------------------改写底层快滚------------------------
--[[
    快停相关
]]
function CodeGameScreenMuchoChilliMachine:setReelRunInfo()
    self:getNumByScatterAndBonus()

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
        bonusNum, bRunLong = self:setBonusScatterInfo(self.SYMBOL_BONUS, col , bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenMuchoChilliMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
        soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
    elseif symbolType == self.SYMBOL_BONUS then 
        bRun = true
        bPlayAni = true
        soundType, nextReelLong = self:getBonusRunStatus(column, allSpecicalSymbolNum)
    end

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        local symbolTypeNetWork = self:getSymbolTypeForNetData(column,row,runLen)
        if symbolTypeNetWork == self.SYMBOL_SPECIAL_BONUS then
            symbolTypeNetWork = self.SYMBOL_BONUS
        end
        if symbolTypeNetWork == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
                else
                    soundType, nextReelLong = self:getBonusRunStatus(column, allSpecicalSymbolNum)
                end

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
        
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenMuchoChilliMachine:getBonusRunStatus(col, nodeNum)

    if col < 2 then
        return runStatus.NORUN, false
    else
        if nodeNum >= 4 then
            return runStatus.DUANG, true
        else
            return runStatus.NORUN, false
        end
    end
end

--[[
    获取轮盘结果 特殊图标个数
]]
function CodeGameScreenMuchoChilliMachine:getNumByScatterAndBonus( )
    local scatterNum = 0 -- 前4列超过2个将会触发free快滚 
    local bonusNum = 0 -- 前4列超过4个将会触发bonus快滚 
    for iCol = 1, self.m_iReelColumnNum-1 do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self:getSpinResultReelsType(iCol, iRow)
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterNum = scatterNum + 1
            end
            if symbolType == self.SYMBOL_BONUS or symbolType == self.SYMBOL_SPECIAL_BONUS then
                bonusNum = bonusNum + 1
            end
        end
    end

    -- 是否有快滚
    local showScatterQuick = false
    local showBonusQuick = false

    if scatterNum >= 2 then
        showScatterQuick = true
    end

    if bonusNum >= 4 then
        showBonusQuick = true
    end

    self.m_showScatterQuick = showScatterQuick
    self.m_showBonusQuick = showBonusQuick
end

---
--添加金边
function CodeGameScreenMuchoChilliMachine:creatReelRunAnimation(col)
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
    reelEffectNode:setScaleY(1)

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

    if self.m_showScatterQuick and not self.m_showBonusQuick then --只有scatter快滚
        util_getChildByName(reelEffectNode, "scatter"):setVisible(true)
        util_getChildByName(reelEffectNode, "bouns"):setVisible(false)
    end

    if not self.m_showScatterQuick and self.m_showBonusQuick then --只有bonus快滚
        util_getChildByName(reelEffectNode, "scatter"):setVisible(false)
        util_getChildByName(reelEffectNode, "bouns"):setVisible(true)
    end

    if self.m_showScatterQuick and self.m_showBonusQuick then --scatter bonus快滚同时存在
        util_getChildByName(reelEffectNode, "scatter"):setVisible(true)
        util_getChildByName(reelEffectNode, "bouns"):setVisible(true)
    end

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        if self.m_showScatterQuick and not self.m_showBonusQuick then --只有scatter快滚
            util_getChildByName(reelEffectNodeBG, "scatter"):setVisible(true)
            util_getChildByName(reelEffectNodeBG, "bouns"):setVisible(false)
        end
    
        if not self.m_showScatterQuick and self.m_showBonusQuick then --只有bonus快滚
            util_getChildByName(reelEffectNodeBG, "scatter"):setVisible(false)
            util_getChildByName(reelEffectNodeBG, "bouns"):setVisible(true)
        end
    
        if self.m_showScatterQuick and self.m_showBonusQuick then --scatter bonus快滚同时存在
            util_getChildByName(reelEffectNodeBG, "scatter"):setVisible(true)
            util_getChildByName(reelEffectNodeBG, "bouns"):setVisible(true)
        end

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end
------------------改写底层快滚end------------------------

--[[
    free玩法过场
]]
function CodeGameScreenMuchoChilliMachine:playGuoChangFreeEffect(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_guochang_baseToFree)

    self.m_guochangFreeEffect:setVisible(true)

    util_spinePlay(self.m_guochangFreeEffect, "actionframe", false)
    util_spineEndCallFunc(self.m_guochangFreeEffect, "actionframe" ,function ()
        self.m_guochangFreeEffect:setVisible(false)
        if _func2 then
            _func2()
        end
    end)

    self:delayCallBack(11/30, function(  )
        if _func1 then
            _func1()
        end
    end)
end

--[[
    respin玩法过场
]]
function CodeGameScreenMuchoChilliMachine:playGuoChangReSpinEffect(_func1, _func2, _func3, _isStart)
    if _isStart then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_guochang_toRespin)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_guochang_overRespin)
    end

    self.m_guochangRespinEffect:setVisible(true)

    util_spinePlay(self.m_guochangRespinEffect, "actionframe", false)

    self:delayCallBack(11/30, function(  )
        if _func1 then
            _func1()
        end
    end)

    self:delayCallBack(25/30, function(  )
        if _func2 then
            _func2()
        end
    end)

    util_spineEndCallFunc(self.m_guochangRespinEffect, "actionframe" ,function ()
        self.m_guochangRespinEffect:setVisible(false)
        if _func3 then
            _func3()
        end
    end)
end

--[[
    bonus玩法过场
]]
function CodeGameScreenMuchoChilliMachine:playGuoChangBonusEffect(_func1, _func2, _func3, _isStart)
    if _isStart then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_guochang_toBonus)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_guochang_overBonus)
    end

    self.m_guochangBonusEffect:setVisible(true)

    util_spinePlay(self.m_guochangBonusEffect, "guochang", false)

    self:delayCallBack(30/30, function(  )
        if _func1 then
            _func1()
        end
    end)

    self:delayCallBack(60/30, function(  )
        if _func2 then
            _func2()
        end
    end)

    util_spineEndCallFunc(self.m_guochangBonusEffect, "guochang" ,function ()
        self.m_guochangBonusEffect:setVisible(false)
        if _func3 then
            _func3()
        end
    end)
end

--[[
    触发respin玩法的 bonus触发动画
]]
function CodeGameScreenMuchoChilliMachine:playBonusTriggerEffect( )
    --播放触发动画
    local curBonusList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS or node.p_symbolType == self.SYMBOL_SPECIAL_BONUS then
                    local symbolNode = util_setSymbolToClipReel(self,iCol, iRow, node.p_symbolType,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                    curBonusList[#curBonusList + 1] = node
                end
            end
        end
    end

    -- 显示棋盘压暗
    self.m_darkUI:setVisible(true)
    self.m_darkUI:runCsbAction("start", false)
    self:delayCallBack(1.4, function()
        self.m_darkUI:runCsbAction("over", false, function()
            self.m_darkUI:setVisible(false)
        end)
    end)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonus_trigger)
    -- 播放触发动画
    for bonusIndex, bonusNode in ipairs(curBonusList) do
        self:changeNodeParent(self:findChild("Node_yugao"), bonusNode)
        bonusNode:runAnim("actionframe",false,function (  )
            bonusNode:runAnim("idleframe2",true)
            self:changeNodeParent(self.m_clipParent, bonusNode)
        end)
    end
end

function CodeGameScreenMuchoChilliMachine:changeNodeParent(_parent, _node)
    local nodePos = util_convertToNodeSpace(_node, _parent)
    util_changeNodeParent(_parent, _node)
end
--[[
    主要用来判断是否显示触发动画 和 三选一弹板
]]
function CodeGameScreenMuchoChilliMachine:getIsPlayEffect( )
    local features = self.m_runSpinResultData.p_features or {}
    if #features > 1 and features[2] == 3 then
        return true
    end
    return false
end

---
-- 触发respin 玩法
--
function CodeGameScreenMuchoChilliMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:levelDeviceVibrate(6, "respin")
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
        end
    end

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            1.5,
            self:getModuleName()
        )
    else
        self:delayCallBack(0.5, function()
            self:showRespinView(effectData)
        end)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

--[[
    respin 相关
]]
function CodeGameScreenMuchoChilliMachine:showRespinView()
    local delayTime = 0
    if self:getIsPlayEffect() then
        -- 触发respin玩法的时候 播放角色动画
        if self:getRespinType() ~= nil then
            -- 角色动画
            self:playBigRoleEffect("daying")
            self:playBonusTriggerEffect()
            delayTime = 2
        end
    end

    --先播放动画 再进入respin
    self:clearCurMusicBg()
    self:stopLinesWinSound()

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )
    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()

    local funcCallBack1 = function()
        if self.m_isDoubleReels then
            self.m_baseJackpotView:showRespinOrBaseJackpot(true)
            self.m_miniMachine:setVisible(true)

            self.m_miniMachine:setSpinResultData(self.m_runSpinResultData,true)
            self.m_miniMachine:triggerReSpinCallFun(endTypes, randomTypes)
        end
        if self:getRespinType() == nil then
            self.m_miniMachine:playReelStartEffect("idle")
        end
        if self.m_bProduceSlots_InFreeSpin then
            self.m_baseFreeSpinBar:setVisible(false)
        end
    end

    local funcCallBack2 = function()
        --构造盘面数据
        self:triggerReSpinCallFun(endTypes, randomTypes)
        self:changeBigRoleByRespin(true)
        self:setReelBg(3)
        self.m_respinBarView:setVisible(true)
        self.m_respinBarView:showTips(self.m_isDoubleReels)
        self:showRespinFeature(true)
        --清空赢钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN) 
    end

    local funcCallBack3 = function()
        self:runQuickEffect()
        
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount, (self:getRespinType() == "extraSpin" or self:getRespinType() == nil))
        if self.m_isDoubleReels then
            self.m_miniMachine:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount, true)
        end
        self:runNextReSpinReel()
    end

    -- 进入bonus玩法流程
    if self:getRespinType() == nil then
        self:showBeginBonusGameView(funcCallBack1, funcCallBack2, funcCallBack3)
    else--进入respin玩法流程
        self:showBeginRespinGameView(delayTime, funcCallBack1, funcCallBack2, funcCallBack3)
    end
end

--[[
    Bonus玩法开始
]]
function CodeGameScreenMuchoChilliMachine:showBeginBonusGameView(_funcCallBack1, _funcCallBack2, _funcCallBack3)
    
    self:playBigRoleTriggerEffect(function()
        self:show_Choose_BonusGameView(function(  )
            self.m_isDoubleReels = true
            self:playGuoChangBonusEffect(function()
                if _funcCallBack1 then
                    _funcCallBack1()
                end
            end,function()
                if _funcCallBack2 then
                    _funcCallBack2()
                end
            end, function()
                -- 进入respin 之后 滚动之前的动画
                self:comeInBonusEffect(function(  )
                    if _funcCallBack3 then
                        _funcCallBack3()
                    end
                end)
            end)
        end, true)
    end)
end

--[[
    respin玩法开始
]]
function CodeGameScreenMuchoChilliMachine:showBeginRespinGameView(_delayTime, _funcCallBack1, _funcCallBack2, _funcCallBack3)
    self:delayCallBack(_delayTime, function()
        self:show_Choose_BonusGameView(function(  )
            self.m_isDoubleReels = self:isTriggerDoubleReels()
            self:playGuoChangReSpinEffect(function()
                if _funcCallBack1 then
                    _funcCallBack1()
                end
            end, function()
                if _funcCallBack2 then
                    _funcCallBack2()
                end
            end, function()
                -- 进入respin 之后 滚动之前的动画
                self:comeInRespinEffect(function(  )
                    if _funcCallBack3 then
                        _funcCallBack3()
                    end
                end)
            end, true)
        end)
    end)
end

--[[
    进入respin 之后 滚动之前的动画
    bonusBoost extraSpin doubleSet
]]
function CodeGameScreenMuchoChilliMachine:comeInRespinEffect(_func)
    local reSpinMode = self:getRespinType()
    if reSpinMode == "bonusBoost" then
        self:playBonusBoostEffect(_func)
    elseif reSpinMode == "extraSpin" then
        self:playExtraSpinEffect(_func)
    elseif reSpinMode == "doubleSet" then
        self:playDoubleSetEffect(_func)
    end
end

--[[
    播放bonusBoost 模式的动画
]]
function CodeGameScreenMuchoChilliMachine:playBonusBoostEffect(_func)
    _func()
end

--[[
    播放extraSpin 模式的动画
]]
function CodeGameScreenMuchoChilliMachine:playExtraSpinEffect(_func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_respin_addNum_four)

    util_spinePlay(self.m_bigRole, "actionframe2", false)
    util_spineEndCallFunc(self.m_bigRole, "actionframe2" ,function ()
        self:playRoleIdleByRespin()
    end)
    
    self:delayCallBack(31/30, function()
        self:playExtraSpinFlyEffect(self:findChild("Node_juese"), self.m_respinBarView:getFourthNode(1), function()
            --切换计数框
            self.m_respinBarView:showFourNumAni()
            self.m_respinBarView:playBoxFourFanKuiEffect(true)
            if _func then
                _func()
            end
        end)
    end)
end

--[[
    播放doubleSet 模式的动画
]]
function CodeGameScreenMuchoChilliMachine:playDoubleSetEffect(_func)
    if self:getIsPlayEffect() then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_reel_sheng)
        self.m_miniMachine:playReelStartEffect("sheng", function()
            self:delayCallBack(1, function(  )
                self:playBonusMoveEffect(function()
                    if _func then
                        _func()
                    end
                end)
            end)
        end)
    else
        self.m_miniMachine:playReelStartEffect("idle", function()
            if _func then
                _func()
            end
        end)
    end
end

--[[
    触发双棋盘玩法时，下棋盘上的bonus 飞到上棋盘
]]
function CodeGameScreenMuchoChilliMachine:playBonusMoveEffect(_func)
    local downBonusList = self.m_respinView:getAllCleaningNode()
    local upBonusList = self.m_miniMachine.m_respinView:getAllCleaningNode()
    
    local playFanKuiEffect = function(_position)
        local fanKuiEffect = util_createAnimation("MuchoChilli_fankui.csb")
        self.m_effectNode:addChild(fanKuiEffect, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
        fanKuiEffect:setPosition(_position)
        fanKuiEffect:runCsbAction("fuzhi", false, function()
            fanKuiEffect:removeFromParent()
        end)
    end

    for _index, _symbolNode in ipairs(downBonusList) do
        self:delayCallBack(0.5*(_index-1), function()
            if _index == 1 then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_copy_first)
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_copy_other)
            end
            local startPos = util_convertToNodeSpace(_symbolNode, self.m_effectNode)
            local endPos = util_convertToNodeSpace(upBonusList[_index], self.m_effectNode)
            
            local flyNode = util_spineCreate("Socre_MuchoChilli_Bonus1", true, true)
            self.m_effectNode:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
            flyNode:setPosition(startPos)

            playFanKuiEffect(startPos)

            util_spinePlay(flyNode, "fuzhi", false)

            local seq = cc.Sequence:create({
                cc.MoveTo:create(20/30, endPos),
                cc.CallFunc:create(function(  )
                    upBonusList[_index]:setVisible(true)
                    playFanKuiEffect(endPos)
                end),
                cc.RemoveSelf:create(true)
            })

            flyNode:runAction(seq)
        end)
    end

    self:delayCallBack(0.5 * #downBonusList, function(  )
        if _func then
            _func()
        end
    end)
end

--[[
    播放extraSpin 模式 多加一个计数位置的飞行动画
]]
function CodeGameScreenMuchoChilliMachine:playExtraSpinFlyEffect(_startNode, _endNode, _func, _isChangePos)
    local startPos = util_convertToNodeSpace(_startNode, self.m_effectNode)
    local endPos = util_convertToNodeSpace(_endNode, self.m_effectNode)
    if _isChangePos then
        startPos.x = startPos.x + 290
        startPos.y = startPos.y - 340
    end
    
    local flyNode = util_createAnimation("MuchoChilli_yinfu.csb")
    self.m_effectNode:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    flyNode:setPosition(startPos)
    flyNode:findChild("MuchoChilli_yinfu"..math.random(1,2)):setVisible(false)

    local particle = nil
    if not tolua.isnull(flyNode) then
        particle = flyNode:findChild("Particle_1")
        if particle then
            particle:setPositionType(0)
        end
    end
    flyNode:runCsbAction("fly")
    local seq = cc.Sequence:create({
        cc.MoveTo:create(0.5,endPos),
        cc.CallFunc:create(function(  )
            if particle then
                particle:stopSystem()
            end

            if _func then
                _func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
    
end

function CodeGameScreenMuchoChilliMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()
            
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

function CodeGameScreenMuchoChilliMachine:setReelSlotsNodeVisible(status)
    CodeGameScreenMuchoChilliMachine.super.setReelSlotsNodeVisible(self, status)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(status)
            end
        end
    end
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenMuchoChilliMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if not self:isFixSymbol(symbolType) then
                symbolType = self.SYMBOL_EMPTY
            end
            if symbolType == self.SYMBOL_SPECIAL_BONUS and self:getRespinType() ~= nil then
                symbolType = self.SYMBOL_BONUS
            end

            if symbolType == self.SYMBOL_BONUS and self:getRespinType() == nil then
                symbolType = self.SYMBOL_SPECIAL_BONUS
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end

--[[
    三选一弹板
]]
function CodeGameScreenMuchoChilliMachine:show_Choose_BonusGameView(_func, _isAuto)
    if self:getIsPlayEffect() or self:isTriggerBonus() then
        local chooseView = util_createView("CodeMuchoChilliSrc.MuchoChilliChooseView",self)
        self:findChild("Node_yugao"):addChild(chooseView)
        chooseView:setPosition(cc.p(-display.width/2,-display.height/2))

        --改变棋盘样式
        chooseView:setEndCall(self, function()
            if _func then
                _func()
            end

            if chooseView then
                chooseView:removeFromParent()
            end
        end, _isAuto)
        chooseView:beginPlayEffect()
    else
        if _func then
            _func()
        end
    end
end

--[[
    显示jackpot弹板
]]
function CodeGameScreenMuchoChilliMachine:showRespinJackpot(index, coins, func)
    local view = util_createView("CodeMuchoChilliSrc.MuchoChilliJackpotWinView",{
        jackpotType = index,
        winCoin = coins,
        machine = self,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

-- 结束respin收集
function CodeGameScreenMuchoChilliMachine:playLightEffectEnd()
    if self.m_isDoubleReels then
        self.m_miniMachine:respinOver()
    end
    -- 通知respin结束
    self:respinOver()
 
end

function CodeGameScreenMuchoChilliMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        -- 此处跳出迭代
        self:playLightEffectEnd()
        return 
    end

    local addScore = 0
    local chipNode = self.m_chipList[self.m_playAnimIndex]
    if chipNode then
        local iCol = chipNode.p_cloumnIndex
        local iRow = chipNode.p_rowIndex
        -- 根据网络数据获得当前固定小块的分数
        local score = 0
        local type = nil
        
        if chipNode.m_up then
            score, type = self.m_miniMachine:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
        else
            score, type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) 
        end
        
        local nJackpotType = 0
        local isJiMan = self:getIsJiManRespin()
    
        if type == "bonus" then
        elseif type == "Grand" then
            nJackpotType = 1
        elseif type == "Mega" then
            nJackpotType = 2
        elseif type == "Major" then
            nJackpotType = 3
        elseif type == "Minor" then
            nJackpotType = 4
        elseif type == "Mini" then
            nJackpotType = 5
        end

        if type ~= "bonus" then
            local jackpotCoins = self:getJackpotCoins(type)
            if jackpotCoins ~= 0 then
                score = jackpotCoins
            end
        end

        if isJiMan then
            score = score * 2
        end
        addScore = addScore + score

        self.m_lightScore = self.m_lightScore + addScore
    
        if nJackpotType == 0 then
            self:playBonusJieSuanEffect(chipNode, addScore, false, nJackpotType, function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim()
            end)
        else
            self:playBonusJieSuanEffect(chipNode, addScore, true, nJackpotType, function()
                self:delayCallBack(0.5, function()
                    self:showRespinJackpot(nJackpotType, addScore, function()
                        self.m_playAnimIndex = self.m_playAnimIndex + 1
                        self:playChipCollectAnim()
                    end)
                end)
            end)
        end
    else
        self.m_playAnimIndex = self.m_playAnimIndex + 1
        self:playChipCollectAnim()
    end
end

--[[
    获得jackpot具体数值
]]
function CodeGameScreenMuchoChilliMachine:getJackpotCoins(_type)
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for _jackpotType, _coins in pairs(jackpotCoins) do
        if _jackpotType == _type then
            return _coins
        end
    end
    return 0
end

--[[
    结算每个bonus的动画
]]
function CodeGameScreenMuchoChilliMachine:playBonusJieSuanEffect(_node, _addCoins, _isJackpot, _nJackpotType, _func)
    local jiesuanName = "jiesuan"
    if _isJackpot then
        jiesuanName = "jiesuan2"
        self.m_baseJackpotView:playTriggerEffect(_nJackpotType)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_jackpot_bonus_fanzhuan)
    end

    if not tolua.isnull(_node) then
        local nodePos = util_convertToNodeSpace(_node, self.m_effectNode)
        local oldParent = _node:getParent()
        local oldPosition = cc.p(_node:getPosition())
        util_changeNodeParent(self.m_effectNode, _node, 0)
        _node:setPosition(nodePos)
        _node:runAnim(jiesuanName, false, function()
            if not tolua.isnull(_node) then
                util_changeNodeParent(oldParent, _node, REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - _node.p_rowIndex + _node.p_cloumnIndex)
                _node:setPosition(oldPosition)
                _node:runAnim("idleframe4", true)
            end
        end)
    end

    self:delayCallBack(0.4, function (  )
        if _func then
            _func()
        end
    end)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_respin_bonus_collect_fankui)
    self:playCoinWinEffectUI()
    -- 刷新底栏
    local bottomWinCoin = self:getCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + _addCoins)
    self.m_bottomUI.m_changeLabJumpTime = 0.2
    self:updateBottomUICoins(0, _addCoins, false, true, false)
    self.m_bottomUI.m_changeLabJumpTime = nil

    if self.m_bottomUI.m_bigWinLabCsb then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.6)
        local posY = 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    end

    local params = {
        overCoins  = _addCoins,
        jumpTime   = 1/60,
        animName   = "actionframe2",
    }
    self:playBottomBigWinLabAnim(params)
end

--获取底栏金币
function CodeGameScreenMuchoChilliMachine:getCurBottomWinCoins()
    local winCoin = 0

    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
        if "" == sCoins then
            return winCoin
        end
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end

--更新底栏金币
function CodeGameScreenMuchoChilliMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--结束移除小块调用结算特效
function CodeGameScreenMuchoChilliMachine:reSpinEndAction()
    self.m_playAnimIndex = 1
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = {}
    local downChipList = self.m_respinView:getAllCleaningNode()

    if self.m_isDoubleReels then
        local upChipList = self.m_miniMachine.m_respinView:getAllCleaningNode()
        for _index, _chipNode in ipairs(upChipList) do
            _chipNode.m_up = true
            table.insert(self.m_chipList, _chipNode)
        end
    end

    for _index, _chipNode in ipairs(downChipList) do
        _chipNode.m_up = false
        table.insert(self.m_chipList, _chipNode)
    end 
    
    self:playBonusEffectOfRespinEnd(function()
        self:playChipCollectAnim()
    end)
    
end

--[[
    结算前 播放触发动画
]]
function CodeGameScreenMuchoChilliMachine:playBonusEffectOfRespinEnd(_func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_respin_bonus_fanzhuan)
    for _, _chipNode in ipairs(self.m_chipList) do
        if _chipNode and _chipNode.p_symbolType then
            _chipNode:runAnim("actionframe", false, function()
                _chipNode:runAnim("idleframe2", true)
            end)
        end
    end

    self:delayCallBack(2, function()
        if _func then
            _func()
        end
    end)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenMuchoChilliMachine:getRespinRandomTypes( )
    local symbolList = { 
        self.SYMBOL_EMPTY,
        self.SYMBOL_BONUS,
        self.SYMBOL_SPECIAL_BONUS,
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenMuchoChilliMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_SPECIAL_BONUS, runEndAnimaName = "buling", bRandom = false},
    }

    return symbolList
end

--ReSpin开始改变UI状态
function CodeGameScreenMuchoChilliMachine:changeReSpinStartUI(respinCount)
    local reSpinMode = self:getRespinType()
    self.m_respinBarView:setVisible(true)
    if reSpinMode == "bonusBoost" then
        self.m_respinBarView:showBarByReelNums(1)
    elseif reSpinMode == "extraSpin" then
        self.m_respinBarView:showBarByReelNums(1)
    elseif reSpinMode == "doubleSet" or reSpinMode == nil then
        self.m_respinBarView:showBarByReelNums(2, false)
        self.m_miniMachine.m_respinBarView:showBarByReelNums(2, true)
    end
end

--ReSpin刷新数量
function CodeGameScreenMuchoChilliMachine:changeReSpinUpdateUI(curCount, _isComeIn)
    print("当前展示位置信息  %d ", curCount)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_respinBarView:updateRespinCount(curCount, totalCount, _isComeIn)
end

--ReSpin结算改变UI状态
function CodeGameScreenMuchoChilliMachine:changeReSpinOverUI()
    
end

function CodeGameScreenMuchoChilliMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    -- self:removeRespinNode()
    self:delayCallBack(0.5, function()
        self:showRespinOverView()
    end)
end

function CodeGameScreenMuchoChilliMachine:showRespinOverView(effectData)
    local funcCallBack1 = function()
        self:changeBigRoleByRespin(false)
        if self.m_bProduceSlots_InFreeSpin then
            self:setReelBg(2)
            self.m_baseFreeSpinBar:setVisible(true)
        else
            if self.m_bigRoleStage == 3 then
                self:setReelBg(4)
            else
                self:setReelBg(1)
            end
        end
        self:setReelSlotsNodeVisible(true)

        self:removeRespinNode()
        self.m_baseJackpotView:showRespinOrBaseJackpot(false)
    end

    local funcCallBack2 = function()
        self.m_respinBarView:setVisible(false)
        self:showRespinFeature(false)
        if self.m_isDoubleReels then
            self.m_miniMachine:playReelStartEffect("idle1")
            self.m_miniMachine:removeRespinNode()
        end
        self.m_miniMachine:setVisible(false)
    end

    local funcCallBack3 = function()
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.m_lightScore = 0
    end

    self:clearCurMusicBg()
    local strCoins=util_formatCoins(self.m_serverWinCoins,30)
    local view=self:showReSpinOver(strCoins,function()
        if self:getRespinType() == nil then
            self:playGuoChangBonusEffect(function()
                util_spinePlay(self.m_bigRoleKuang, "idleframe", true)
                self.m_bigRoleKuangHuo:setVisible(false)
                funcCallBack1()
            end, function()
                funcCallBack2()
            end, function()
                funcCallBack3()
            end, false)
        else
            self:playGuoChangReSpinEffect(function()
                funcCallBack1()
            end, function()
                funcCallBack2()
            end, function()
                funcCallBack3()
            end, false)
        end
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},560)
    if self:getRespinType() == nil then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_overView_start)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_MuchoChilli_click
        view:setBtnClickFunc(function(  )
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_overView_over)
        end)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_respinOverView_start)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_MuchoChilli_click
        view:setBtnClickFunc(function(  )
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_respinOverView_over)
        end)
    end
end

function CodeGameScreenMuchoChilliMachine:showReSpinOver(coins, func, index)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    if self:getRespinType() == nil then
        return self:showDialog("ReSpinOver1", ownerlist, func, nil, index)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func, nil, index)
    end
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

function CodeGameScreenMuchoChilliMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== respin  server=" .. self.m_serverWinCoins .. "    client=" .. score .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        local params = {self:getLastWinCoin(), false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    else
        coins = self.m_serverWinCoins or 0
        local params = {self.m_serverWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--[[
   respin结束 把respin小块放回对应滚轴位置
]]
function CodeGameScreenMuchoChilliMachine:checkChangeRespinFixNode(node)
    if node.p_symbolType == self.SYMBOL_EMPTY then
        local randType = math.random(0, self.SYMBOL_SCORE_10)
        self:changeSymbolType(node,randType)
    else
        node:runAnim("idleframe2",true)
    end
    CodeGameScreenMuchoChilliMachine.super.checkChangeRespinFixNode(self, node)
end

-- --重写组织respinData信息
function CodeGameScreenMuchoChilliMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        
        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

--[[
    respin玩法的类型
]]
function CodeGameScreenMuchoChilliMachine:getRespinType( )
    local reSpinMode = nil
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.reSpinMode then
        reSpinMode = self.m_runSpinResultData.p_selfMakeData.reSpinMode
    end
    return reSpinMode
end

---判断结算
function CodeGameScreenMuchoChilliMachine:reSpinReelDown(addNode)
    self:runQuickEffect()

    self:oneReSpinReelDown()
end

--[[
    respin每次停轮之后 的处理
]]
function CodeGameScreenMuchoChilliMachine:oneReSpinReelDown( )
    self:removeLightRespin()
    self:setGameSpinStage(STOP_RUN)

    self.m_downReelCount = self.m_downReelCount + 1
    local maxCount = self.m_isDoubleReels and 2 or 1

    if self.m_downReelCount < maxCount then
        return
    end

    self:resetMoveNodeStatus(function()
        self:checkAddBonusSymbolScore(function()
            self:playJiManEffect(function()
                self:updateQuestUI()
                if self:isRespinEnd() or self:getIsJiManRespin() then
                    self.m_respinBarView:showTextByNums(self.m_runSpinResultData.p_reSpinCurCount, true)
                    self.m_miniMachine.m_respinBarView:showTextByNums(self.m_runSpinResultData.p_reSpinCurCount, true)
    
                    self.m_lightEffectNode:removeAllChildren(true)
    
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
    
                    --quest
                    self:updateQuestBonusRespinEffectData()
    
                    --加0.5s延时
                    self:delayCallBack(0.5,function(  )
                        --结束
                        self:reSpinEndAction()
                    end)
    
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    
                    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
                    self.m_isWaitingNetworkData = false
    
                    return
                end
    
                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
                
                -- if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
                --     self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
                -- end
                --继续
                self:runNextReSpinReel()
    
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end)
        end)
    end)
end

--[[
    bonusBoost玩法 加钱
]]
function CodeGameScreenMuchoChilliMachine:checkAddBonusSymbolScore(_func)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    --下棋盘
    local addStoredIcons = selfMakeData.addStoredIcons or {}
    --上棋盘
    local addUpStoredIcons = selfMakeData.viceAddStoredIcons or {}

    local allAddStoreIcons = {}
    for _index, _data in ipairs(addStoredIcons) do
        _data[3] = "down"
        table.insert(allAddStoreIcons, _data)
    end

    for _index, _data in ipairs(addUpStoredIcons) do
        _data[3] = "up"
        table.insert(allAddStoreIcons, _data)
    end

    if #allAddStoreIcons > 0 then
        local delayTime = 31/30
        local startNode = self:findChild("Node_juese")
        local isChangePos = false
        if self:getRespinType() == "doubleSet" or self:getRespinType() == nil then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_addCoins)
            delayTime = 40/30
            self.m_guochangBonusEffect:setVisible(true)
            util_spinePlay(self.m_guochangBonusEffect, "actionframe3", false)
            util_spineEndCallFunc(self.m_guochangBonusEffect, "actionframe3" ,function ()
                self.m_guochangBonusEffect:setVisible(false)
            end)
            startNode = self:findChild("Node_yugao")
            isChangePos = true
        else
            local random = math.random(1, 2)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_MuchoChilli_respin_one_add_coins"..random])
            util_spinePlay(self.m_bigRole, "actionframe2", false)
            util_spineEndCallFunc(self.m_bigRole, "actionframe2" ,function ()
                self:playRoleIdleByRespin()
            end)
        end

        self:delayCallBack(delayTime, function()
            for _index, _data in ipairs(allAddStoreIcons) do
                local fixPos = self:getRowAndColByPos(_data[1])
                local respinNode = nil
                if _data[3] == "up" then
                    respinNode = self.m_miniMachine.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
                else
                    respinNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
                end
                if respinNode then
                    self:playExtraSpinFlyEffect(startNode, respinNode, function()
                        self:playAddCoinsBonusEffect(respinNode, _data[1], _data[2], "bonus", _data[3])
                        if _index == #allAddStoreIcons then
                            --加钱流程之后 延迟0.5秒
                            self:delayCallBack(0.5, function()
                                if _func then
                                    _func()
                                end
                            end)
                        end
                    end, isChangePos)
                end
            end
        end)
    else
        if _func then
            _func()
        end
    end
end

--[[
    给respin棋盘上的小块 加钱动画
]]
function CodeGameScreenMuchoChilliMachine:playAddCoinsBonusEffect(_respinNode, _pos, _addCoins, _bonusType, _upAndDown, _isJiman)
    _respinNode:runAnim("fankui", false, function()
        _respinNode:runAnim("idleframe2", true)
    end)

    local symbol_node = _respinNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()

    -- 图标上的反馈动画
    local startPos = util_convertToNodeSpace(_respinNode, self.m_effectNode)
    local fankuiNode = util_createAnimation("MuchoChilli_fankui.csb")
    self.m_effectNode:addChild(fankuiNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    fankuiNode:setPosition(startPos)
    fankuiNode:runCsbAction("fankui", false, function()
        fankuiNode:removeFromParent()
    end)

    -- 图标bonus字 做个假的
    local bonusNumNode = util_createAnimation("Socre_MuchoChilli_Bonus_Coins.csb")
    self.m_effectNode:addChild(bonusNumNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    bonusNumNode:setPosition(startPos)
    bonusNumNode:setVisible(false)

    --加钱
    local addCoinsNode = util_createAnimation("MuchoChilli_Bonus_BoostNums.csb")
    self.m_effectNode:addChild(addCoinsNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)
    addCoinsNode:setPosition(startPos)
    addCoinsNode:findChild("m_lb_num"):setString("+"..util_formatCoins(_addCoins, 3))
    addCoinsNode:runCsbAction("actionframe", false, function()
        addCoinsNode:removeFromParent()
    end)

    local isJiMan = self:getIsJiManRespin()
    -- 第三帧切换金额
    -- self:delayCallBack(3/30, function()
        if spineNode.m_csbNode then
            local coinsNode = spineNode.m_csbNode
            local score = 0
            local oldScore = 0
            local type = nil
            if _bonusType == "bonus" then
                if _upAndDown == "up" then
                    score, type = self.m_miniMachine:getReSpinSymbolScore(_pos)
                    oldScore, type = self.m_miniMachine:getReSpinSymbolScore(_pos, true)
                else
                    score, type = self:getReSpinSymbolScore(_pos)
                    oldScore, type = self:getReSpinSymbolScore(_pos, true)
                end
                if isJiMan and _isJiman then
                    score = score * 2
                end
                
                if not tolua.isnull(coinsNode) then
                    local lineBet = globalData.slotRunData:getCurTotalBet()
                    local multiply = score / lineBet
                    local labCoins = coinsNode:findChild("m_lb_num")
                    if multiply >= 5 then
                        labCoins = coinsNode:findChild("m_lb_num_high")
                        coinsNode:findChild("m_lb_num"):setVisible(false)
                        coinsNode:findChild("m_lb_num_high"):setVisible(true)
                    else
                        coinsNode:findChild("m_lb_num"):setVisible(true)
                        coinsNode:findChild("m_lb_num_high"):setVisible(false)
                    end
    
                    labCoins:setString(util_formatCoins(score, 3, false, true, true))
                    self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 145)
                end
            else
                coinsNode:findChild("Node_1"):setVisible(false)
                coinsNode:findChild("Node_jackpot"):setVisible(false)
                coinsNode:findChild("Node_multiplierJackpot"):setVisible(true)
                coinsNode:findChild("grand_mul"):setVisible(_bonusType == "Grand")
                coinsNode:findChild("mega_mul"):setVisible(_bonusType == "Mega")
                coinsNode:findChild("major_mul"):setVisible(_bonusType == "Major")
                coinsNode:findChild("minor_mul"):setVisible(_bonusType == "Minor")
                coinsNode:findChild("mini_mul"):setVisible(_bonusType == "Mini")
            end

            coinsNode:setVisible(false)
            bonusNumNode:setVisible(true)
            self:showBonusJackpotOrCoins(bonusNumNode, oldScore, _bonusType)
            if _bonusType == "bonus" then
                self:jumpCoinsUp(bonusNumNode, score, oldScore, coinsNode)
            else
                self:delayCallBack(50/60, function()
                    coinsNode:setVisible(true)
                    bonusNumNode:setVisible(false)
                end)
            end
        end
    -- end)
end

-- 金币跳动
function CodeGameScreenMuchoChilliMachine:jumpCoinsUp(node, _coins, _curCoins, _coinsNode)
    if not tolua.isnull(node) then
        local curCoins = _curCoins or 0
        local lineBet = globalData.slotRunData:getCurTotalBet()
        -- 每秒60帧
        local coinRiseNum =  (_coins - _curCoins) / (0.7 * 60)

        local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
        coinRiseNum = tonumber(str)
        coinRiseNum = math.ceil(coinRiseNum)

        node.m_updateCoinsAction = schedule(self, function()
            curCoins = curCoins + coinRiseNum
            curCoins = curCoins < _coins and curCoins or _coins
            
            local sCoins = curCoins

            if not tolua.isnull(node) then
                local multiply = sCoins / lineBet
                local labCoins = node:findChild("m_lb_num")
                if multiply >= 5 then
                    labCoins = node:findChild("m_lb_num_high")
                    node:findChild("m_lb_num"):setVisible(false)
                    node:findChild("m_lb_num_high"):setVisible(true)
                else
                    node:findChild("m_lb_num"):setVisible(true)
                    node:findChild("m_lb_num_high"):setVisible(false)
                end

                labCoins:setString(util_formatCoins(sCoins, 3, false, true, true))
                self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 145)
            end

            if curCoins >= _coins then
                node:setVisible(false)
                if not tolua.isnull(node) then
                    _coinsNode:setVisible(true)
                end 
                self:stopUpDateCoinsUp(node)
            end
        end,0.008)
    end
end

function CodeGameScreenMuchoChilliMachine:stopUpDateCoinsUp(node)
    if not tolua.isnull(node) then
        if node.m_updateCoinsAction then
            self:stopAction(node.m_updateCoinsAction)
            node.m_updateCoinsAction = nil

            node:removeFromParent()
        end
    end
end

--开始滚动
function CodeGameScreenMuchoChilliMachine:startReSpinRun()
    self.m_downReelCount = 0
    self.m_isPlayUpdateRespinNums = true
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}
    self.m_isDuanXian = false

    if self:isRespinEnd() or self:getIsJiManRespin() then
        return
    end

    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    self:requestSpinReusltData()

    --mini轮开始滚动
    if self:getRespinType() == "doubleSet" or self:getRespinType() == nil then
        self.m_miniMachine:startReSpinRun()
    end
    --下面的轮盘停了但是上面还没停
    if self.m_runSpinResultData.p_reSpinCurCount <= 0 then
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.RUN)
        self.m_respinBarView:showTextByNums(self.m_runSpinResultData.p_reSpinCurCount, true)
        self:reSpinReelDown()
        self:moveRootNodeAction()
        return
    end

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    self.m_respinView:startMove()
    self:moveRootNodeAction()
end

--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function CodeGameScreenMuchoChilliMachine:checkTriggerInReSpin()
    local isPlayGameEff = false
    self.m_isDoubleReels = self:isTriggerDoubleReels()
    if not self:isRespinEnd() then
        --手动添加freespin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        local reSpinEffect = GameEffectData.new()
        reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
        reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

        self.m_isRunningEffect = true

        if self.checkControlerReelType and self:checkControlerReelType() then
            globalMachineController.m_isEffectPlaying = true
        end

        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    else
        self.m_isDoubleReels = false
    end

    return isPlayGameEff
end

--[[
    是否触发双轮盘玩法
]]
function CodeGameScreenMuchoChilliMachine:isTriggerDoubleReels( )
    if self:getRespinType() == "doubleSet" or self:getRespinType() == nil then
        return true
    end
    return false
end

--[[
    respin是否结束
]]
function CodeGameScreenMuchoChilliMachine:isRespinEnd( )
    local isRespinEnd = false
    local extraCount = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.viceReSpinCurTimes then
        extraCount = selfData.viceReSpinCurTimes
    end

    if not self.m_isDoubleReels and self.m_runSpinResultData.p_reSpinCurCount == 0 then
        isRespinEnd = true
    elseif self.m_isDoubleReels and self.m_runSpinResultData.p_reSpinCurCount == 0 and extraCount == 0 then
        isRespinEnd = true
    end
    return isRespinEnd
end

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenMuchoChilliMachine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" or spinData.action == "FEATURE" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
                self:getRandomList()
                if self.m_isDoubleReels then
                    self.m_miniMachine:setSpinResultData(self.m_runSpinResultData)
                end

                self:stopRespinRun()

                self:setGameSpinStage(GAME_MODE_ONE_RUN)

                if not self.m_isRespinQuickRunLast then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
                end
            end
        else
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
        return true
    end
    return false
end

--接收到数据开始停止滚动
function CodeGameScreenMuchoChilliMachine:stopRespinRun()
    local storedNodeInfo = self:getRespinSpinData()
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    
    if self.m_isDoubleReels then
        self.m_miniMachine:stopRespinRun()
    end
end

--- respin 快停
function CodeGameScreenMuchoChilliMachine:quicklyStop()
    self.m_respinView:quicklyStop()
    if self.m_isDoubleReels then
        self.m_miniMachine:quicklyStop()
    end
end

--[[
    判断是否是 respin 最后一次
]]
function CodeGameScreenMuchoChilliMachine:getIsLastRespin( )
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount or 1
    local viceReSpinCurTimes = 1
    local isLastRespin = false
    --双棋盘
    if self.m_isDoubleReels then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        viceReSpinCurTimes = selfData.viceReSpinCurTimes or 1
        -- 判断是否是 respin 最后一次
        if (reSpinCurCount == 1 and viceReSpinCurTimes == 0) or (reSpinCurCount == 0 and viceReSpinCurTimes == 1) then
            isLastRespin = true
        end
    else
        -- 判断是否是 respin 最后一次
        if reSpinCurCount == 1 then
            isLastRespin = true
        end
    end
    
    return isLastRespin
end
--[[
    快滚特效 respin
]]
function CodeGameScreenMuchoChilliMachine:runQuickEffect()
    self.m_qucikRespinNode = {}
    local bonus_count = 0

    local isLastRespin = self:getIsLastRespin()
    --双棋盘
    if self.m_isDoubleReels then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local viceStoredIcons = selfData.viceStoredIcons or {}
        bonus_count = #self.m_runSpinResultData.p_storedIcons + #viceStoredIcons
    else
        bonus_count = #self.m_runSpinResultData.p_storedIcons
    end

    local getQuickRunNode = function()
        if self.m_respinView then
            for _index = 1, #self.m_respinView.m_respinNodes do
                local repsinNode = self.m_respinView.m_respinNodes[_index]
                if repsinNode.m_runLastNodeType == self.SYMBOL_EMPTY then
                    self.m_qucikRespinNode[#self.m_qucikRespinNode + 1] = {
                        node = repsinNode
                    }
                else
                    repsinNode:changeRunSpeed(false)
                end
            end
        end
    end

    if self.m_isDoubleReels then
        if bonus_count >= 29 then
            getQuickRunNode()
            if self.m_miniMachine.m_respinView then
                for _index = 1, #self.m_miniMachine.m_respinView.m_respinNodes do
                    local repsinNode = self.m_miniMachine.m_respinView.m_respinNodes[_index]
                    if repsinNode.m_runLastNodeType == self.SYMBOL_EMPTY then
                        self.m_qucikRespinNode[#self.m_qucikRespinNode + 1] = {
                            node = repsinNode
                        }
                    else
                        repsinNode:changeRunSpeed(false)
                    end
                end
            end
        end
    else
        if bonus_count >= 14 then
            getQuickRunNode()
        end
    end

    if #self.m_qucikRespinNode > 0 then
        if not self.m_lightEffectNode:getChildByName("quickRunEffect") then
            self.m_lightEffectNode:removeAllChildren(true)
            for _index = 1, #self.m_qucikRespinNode do
                local quickRunInfo = self.m_qucikRespinNode[_index]
                if not quickRunInfo.isEnd then
                    local light_effect = util_createAnimation("MuchoChilli_chayige.csb")
                    light_effect:runCsbAction("actionframe1",true)  --普通滚动状态
                    self.m_lightEffectNode:addChild(light_effect)
                    light_effect:setName("quickRunEffect")
                    light_effect:setPosition(util_convertToNodeSpace(quickRunInfo.node, self.m_lightEffectNode))
                    quickRunInfo.node:changeRunSpeed(true, isLastRespin)
                end
            end
        else
            for _index = 1, #self.m_qucikRespinNode do
                local quickRunInfo = self.m_qucikRespinNode[_index]
                if not quickRunInfo.isEnd then
                    quickRunInfo.node:changeRunSpeed(true, isLastRespin)
                end
            end
        end
    end
end

--[[
    移除快滚特效 respin
]]
function CodeGameScreenMuchoChilliMachine:removeLightRespin()
    local bonus_count = 0
    --双棋盘
    if self.m_isDoubleReels then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local viceStoredIcons = selfData.viceStoredIcons or {}
        bonus_count = #self.m_runSpinResultData.p_storedIcons + #viceStoredIcons
    else
        bonus_count = #self.m_runSpinResultData.p_storedIcons
    end

    if self.m_isDoubleReels then
        if bonus_count >= 30 then
            self.m_lightEffectNode:removeAllChildren(true)
        end
    else
        if bonus_count >= 15 then
            self.m_lightEffectNode:removeAllChildren(true)
        end
    end
end

--[[
    拉伸镜头效果
]]
function CodeGameScreenMuchoChilliMachine:moveRootNodeAction()
    if #self.m_qucikRespinNode == 0 then
        return 
    end
    local isLastRespin = self:getIsLastRespin()
    if not isLastRespin then
        return
    end

    local moveNode = self:findChild("Node_1")
    local parentNode = moveNode:getParent()

    local params = {
        moveNode = moveNode,--要移动节点
        targetNode = self.m_qucikRespinNode[1].node,--目标位置节点
        parentNode = parentNode,--移动节点的父节点
        time = 2.8,--移动时间
        actionType = 3,
        scale = 2,--缩放倍数
    }

    self.m_isRespinQuickRunLast = true
    util_moveRootNodeAction(params)

    local quickEffectNode = self.m_lightEffectNode:getChildByName("quickRunEffect")
    if quickEffectNode then
        quickEffectNode:runCsbAction("actionframe",true)  --特殊滚动状态
    end
    self.m_respinQuickRunSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_respin_quick_run)
end

--[[
    重置移动节点状态
]]
function CodeGameScreenMuchoChilliMachine:resetMoveNodeStatus(_func)
    if self.m_isRespinQuickRunLast then
        if self.m_respinQuickRunSound then
            gLobalSoundManager:stopAudio(self.m_respinQuickRunSound)
            self.m_respinQuickRunSound = nil
        end

        self.m_isRespinQuickRunLast = false
        local moveNode = self:findChild("Node_1")
        --恢复移动节点状态
        local spawn = cc.Spawn:create({
            cc.MoveTo:create(0.5,cc.p(0,0)),
            cc.ScaleTo:create(0.5,1)
        })
        moveNode:stopAllActions()
        moveNode:runAction(cc.Sequence:create(
            cc.EaseSineInOut:create(spawn),
            cc.CallFunc:create(function()
                if _func then
                    _func()
                end
            end)))
    else
        if _func then
            _func()
        end
    end
end

--[[
    进入bonus玩法之前的动画
]]
function CodeGameScreenMuchoChilliMachine:comeInBonusEffect(_func)
    self.m_miniMachine:playReelStartEffect("idle", function()
        if self:getIsPlayEffect() then
            self:delayCallBack(1, function(  )
                self:playBonusMoveEffect(function()
                    self:playBonusExtraSpinEffect(function ()
                        if _func then
                            _func()
                        end
                    end)
                end)
            end)
        else
            self:playBonusExtraSpinEffect(function ()
                if _func then
                    _func()
                end
            end)
        end
    end)
end

--[[
    播放bonus玩法 计数框多加1次动画
]]
function CodeGameScreenMuchoChilliMachine:playBonusExtraSpinEffect(_func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_addNum)
    self.m_guochangBonusEffect:setVisible(true)
    util_spinePlay(self.m_guochangBonusEffect, "actionframe3", false)
    util_spineEndCallFunc(self.m_guochangBonusEffect, "actionframe3" ,function ()
        self.m_guochangBonusEffect:setVisible(false)
        if _func then
            _func()
        end
    end)
    self:delayCallBack(40/30, function (  )
        local startNode = self:findChild("Node_yugao")
        
        self:playExtraSpinFlyEffect(startNode, self.m_respinBarView:getFourthNode(2, false), function()
            --切换计数框
            self.m_respinBarView:showFourNumAni()
            self.m_respinBarView:playBoxFourFanKuiEffect(true)
        end, true)

        self:playExtraSpinFlyEffect(startNode, self.m_miniMachine.m_respinBarView:getFourthNode(2, true), function()
            --切换计数框
            self.m_miniMachine.m_respinBarView:showFourNumAni()
            self.m_miniMachine.m_respinBarView:playBoxFourFanKuiEffect()
        end, true)
    end)
end

--[[
    棋盘集满动画
]]
function CodeGameScreenMuchoChilliMachine:playJiManEffect(_func)
    if self:getIsJiManRespin() then
        -- self:changeBonusParentByJiMan(true)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_respin_jiman_bg)

        self.m_respinMansNode:setVisible(true)
        self.m_respinManxNode:setVisible(true)
        self.m_respinMansNode:runCsbAction("actionframe", false, function()
            self.m_respinMansNode:setVisible(false)
        end)
        self.m_respinManxNode:runCsbAction("actionframe", false, function()
            self.m_respinManxNode:setVisible(false)
        end)

        self:delayCallBack(120 / 60, function()
            self.m_respinChengBeiNode:setVisible(true)
            self.m_respinChengBeiNode:runCsbAction("start", false)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_respin_jiman_chengbei)
        end)

        -- start之后 0.5秒播放
        self:delayCallBack((120+33+0.5) / 60, function()
            self.m_respinChengBeiNode:runCsbAction("chengbei", false, function()
                self.m_respinChengBeiNode:setVisible(false)
            end)
        end)

        if self.m_isDoubleReels then
            self.m_miniMachine:playJiManEffect()
        end

        -- chengbei 45帧播放
        self:delayCallBack((120+33+0.5+45) / 60, function()
            -- self:changeBonusParentByJiMan(false)
            self:playAddCoinsJiManEffect(_func)
        end)
    else
        if _func then
            _func()
        end
    end
end

--[[
    判断棋盘是否集满
]]
function CodeGameScreenMuchoChilliMachine:getIsJiManRespin( )
    -- 下棋盘
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local viceStoredIcons = {}
    -- 上棋盘
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.viceStoredIcons then
        viceStoredIcons = selfData.viceStoredIcons
    end
    -- 双棋盘两个都集满才算
    if self.m_isDoubleReels then
        if #storedIcons >= 15 and #viceStoredIcons >= 15 then
            return true
        end
    else
        if #storedIcons >= 15 then
            return true
        end
    end
    return false
end

--[[
    棋盘集满 给所有bonus加钱
]]
function CodeGameScreenMuchoChilliMachine:playAddCoinsJiManEffect(_func)
    -- 下棋盘
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local viceStoredIcons = {}
    -- 上棋盘
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.viceStoredIcons then
        viceStoredIcons = selfData.viceStoredIcons
    end

    local allAddStoreIcons = {}
    for _index, _data in ipairs(storedIcons) do
        _data[4] = "down"
        table.insert(allAddStoreIcons, _data)
    end

    for _index, _data in ipairs(viceStoredIcons) do
        _data[4] = "up"
        table.insert(allAddStoreIcons, _data)
    end

    for _index, _data in ipairs(allAddStoreIcons) do
        local fixPos = self:getRowAndColByPos(_data[1])
        local respinNode = nil
        if _data[4] == "up" then
            respinNode = self.m_miniMachine.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
        else
            respinNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
        end
        if respinNode then
            self:playAddCoinsBonusEffect(respinNode, _data[1], _data[2], _data[3], _data[4], true)
            if _index == #allAddStoreIcons then
                if _func then
                    _func()
                end
            end
        end
    end
end

--关卡重写接口-获取滚动的列表数据-处理base和free假滚
function CodeGameScreenMuchoChilliMachine:checkUpdateReelDatas(parentData)
    local replaceList = self.REPLACE_BONUS_LIST
    local reelDatas = CodeGameScreenMuchoChilliMachine.super.checkUpdateReelDatas(self, parentData)
    local newReelDatas = {}
    --替换指定信号
    for _, _symbolType in ipairs(reelDatas) do
        local replaceSymbolType = replaceList[_symbolType]
        local symbolType = nil ~= replaceSymbolType and replaceSymbolType or _symbolType
        newReelDatas[#newReelDatas + 1] = symbolType
    end
    --替换整个假滚列表
    parentData.reelDatas = newReelDatas

    return reelDatas
end

--respin 模式下更换背景音乐
function CodeGameScreenMuchoChilliMachine:changeReSpinBgMusic()
    if self:getRespinType() == nil then
        self.m_currentMusicBgName = self.m_bonusBgMusicName
        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_bonusBgMusicName)
    else
        if self.m_rsBgMusicName ~= nil then
            self.m_currentMusicBgName = self.m_rsBgMusicName
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_rsBgMusicName)
        end
    end
end

function CodeGameScreenMuchoChilliMachine:getReSpinMusicBg()
    if self:getRespinType() == nil then
        return self.m_bonusBgMusicName
    else
        return self.m_rsBgMusicName
    end
end

--[[
    检测播放bonus落地音效
]]
function CodeGameScreenMuchoChilliMachine:checkPlayBonusDownSound(_node)
    local colIndex = _node.p_cloumnIndex
    if not self.m_bonus_down[colIndex] then
        --播放bonus
        if _node.p_symbolType == self.SYMBOL_BONUS then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonus_buling)
        elseif _node.p_symbolType == self.SYMBOL_SPECIAL_BONUS then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MuchoChilli_bonus_special_buling)
        end
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_bonus_down[iCol] = true
        end
    else
        self.m_bonus_down[colIndex] = true
    end
end

--[[
    respin单列停止
]]
function CodeGameScreenMuchoChilliMachine:respinOneReelDown(colIndex,isQuickStop)
    if not self.m_respinReelDownSound[colIndex] then
        if not isQuickStop then
            gLobalSoundManager:playSound("MuchoChilliSounds/sound_MuchoChilli_reelDown.mp3")
        else
            gLobalSoundManager:playSound("MuchoChilliSounds/sound_MuchoChilli_quickReelDown.mp3")
        end
    end

    self.m_respinReelDownSound[colIndex] = true
    if isQuickStop then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_respinReelDownSound[iCol] = true
        end
    end
end

function CodeGameScreenMuchoChilliMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    local mainPosY = (uiBH - uiH - 30) / 2

    CodeGameScreenMuchoChilliMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    if  ratio >= 768/1024 then
        local mainScale = 0.69
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(18)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.81 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(13)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.87 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(5)
    end
    if display.width/display.height >= 1812/2176 then
        local mainScale = 0.58
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

return CodeGameScreenMuchoChilliMachine
