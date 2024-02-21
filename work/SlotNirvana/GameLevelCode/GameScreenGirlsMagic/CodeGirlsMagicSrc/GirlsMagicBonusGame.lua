---
--xcyy
--2018年5月23日
--GirlsMagicBonusGame.lua

local SendDataManager = require "network.SendDataManager"
local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseView = require "base.BaseView"
local GirlsMagicBonusGame = class("GirlsMagicBonusGame",BaseView)

local HEART_BEAT_TIME       =       10          --心跳间隔

local FRONT_OEDER       =       100
local MID_ORDER         =       50
local BEHIND_ORDER      =       10

local MATCH_STEP    =       {"fullMatch","color","bag","pattern"}

local WORD_GIRL_LEFT = {
    {node = "GirlsMagic_duihua_zi5_13",sound = "GirlsMagicSounds/sound_GirlsMagic_word_i_know.mp3"},
    {node = "GirlsMagic_duihua_zi1_9",sound = "GirlsMagicSounds/sound_GirlsMagic_word_yes.mp3"},
    {node = "GirlsMagic_duihua_zi6_14",sound = "GirlsMagicSounds/sound_GirlsMagic_word_got_it.mp3"}
}

local WORD_GIRL_RIGHT = {
    {node = "GirlsMagic_duihua_zi2_10",sound = "GirlsMagicSounds/sound_GirlsMagic_word_i_suppose.mp3"},
    {node = "GirlsMagic_duihua_zi3_11",sound = "GirlsMagicSounds/sound_GirlsMagic_word_maybe.mp3"},
    {node = "GirlsMagic_duihua_zi4_12",sound = "GirlsMagicSounds/sound_GirlsMagic_word_perhaps.mp3"}
}

local ACTION_OVER = 3       --玩法结束

function GirlsMagicBonusGame:initUI(params)
    self.m_machine = params.machine
    self.m_spineManager = self.m_machine.m_spineManager

    self.m_totalCount = 5

    self:createCsbNode("GirlsMagic/BonusSpin.csb")

    self:runCsbAction("idle",true)
    
    self.m_node_model = self:findChild("Node_model")

    self.m_isEnd = false
    self.m_isShowEnd = false

    --用于挂载衣服
    self.m_node_front = cc.Node:create()
    --用于挂载衣服阴影
    self.m_node_behind = cc.Node:create()
    --用于挂载说话角色
    self.m_node_mid = cc.Node:create()
    self.m_spine_role = util_spineCreate("GirlsMagic_BonusSpin_juese",true,true)
    self.m_node_mid:addChild(self.m_spine_role)
    self.m_node_mid:setVisible(false)

    --用于挂载结果角色
    self.m_node_role_result = cc.Node:create()
    self.m_node_model:addChild(self.m_node_role_result,MID_ORDER + 1)
    self.m_node_role_result:setVisible(false)
    

    self.m_node_model:addChild(self.m_node_front,FRONT_OEDER)
    self:findChild("Node_shadow"):addChild(self.m_node_behind,BEHIND_ORDER)
    self.m_node_model:addChild(self.m_node_mid,MID_ORDER)

    --用于挂台词
    self.m_node_word = cc.Node:create()
    self:findChild("root"):addChild(self.m_node_word,100)
    self.m_node_word:setPosition(cc.p(self.m_node_model:getPosition()))

    self.m_node_front:setPositionY(-45)
    self.m_node_behind:setPositionY(-85)

    self.m_isSpinEnd = false    --是否结束旋转

    --玩家选择结果界面
    self.m_chooseResultView = util_createView("CodeGirlsMagicSrc.GirlsMagicBonusSelectInfoView",{machine = self.m_machine})
    self:addChild(self.m_chooseResultView)
    self.m_chooseResultView:setPosition(display.width / 2,display.height / 2)
    self.m_chooseResultView:hideView()

    --spin结果界面
    self.m_result_view = util_createView("CodeGirlsMagicSrc.GirlsMagicBonusResultView",{machine = self.m_machine})
    self.m_machine:findChild("root"):addChild(self.m_result_view,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 70)
    self.m_result_view:setVisible(false)
    self.m_result_view:setPosition(cc.p(-display.width / 2,-display.height / 2))

    self.m_big_role = self.m_spineManager:createBigClothesSpine()
    self.m_node_role_result:addChild(self.m_big_role)
    self.m_big_role:setPosition(util_convertToNodeSpace(self.m_result_view:findChild("Node_PlayerDress"),self.m_node_role_result))
    --结果大角色光效,用于匹配时亮起
    self.m_big_role_light = self.m_spineManager:createBigClothesLightSpine( )
    self.m_big_role:addChild(self.m_big_role_light)
    self.m_big_role_light:setVisible(false)

    self.m_matchWord = util_createAnimation("GirlsMagic_FullMatch.csb")
    -- self.m_result_view:findChild("Node_Match"):addChild(self.m_matchWord,1010)
    self.m_machine:addChild(self.m_matchWord,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    self.m_matchWord:setPosition(cc.p(display.width / 2,display.height * 0.6))
    self.m_matchWord:setVisible(false)

    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_effectNode:setPosition(cc.p(display.width / 2,display.height / 2))

    self.m_bonusCredits = util_createAnimation("GirlsMagic_BonusCredits.csb")
    self:findChild("Node_BonusCredits"):addChild(self.m_bonusCredits)
    self.m_bonusCredits:findChild("Node_base"):setVisible(false)
    self.m_bonusCredits:setVisible(false)
    self:findChild("Node_BonusCredits"):setPositionY((display.height - 200) * (1 + 1 - self.m_machine.m_machineRootScale))
    
end


--默认按钮监听回调
function GirlsMagicBonusGame:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end

--[[
    修改中奖信息
]]
function GirlsMagicBonusGame:changeBonusCredis(multipls)
    local m_lb_multiplier = self.m_bonusCredits:findChild("m_lb_multiplier")
    local m_lb_coins = self.m_bonusCredits:findChild("m_lb_coins")

    local score = 1 
    if self.m_result and self.m_result.userScore then
        score = self.m_result.userScore[globalData.userRunData.userUdid] or 1
    end
    if score < 1 then
        score = 1
    end
    m_lb_multiplier:setString(multipls)
    m_lb_coins:setString(util_formatCoins(score, 4))
    self:updateLabelSize({label = m_lb_coins,sx = 0.8,sy = 0.8},128)
    self:updateLabelSize({label = m_lb_multiplier,sx = 0.8,sy = 0.8},78)
end

--[[
    自己的选择显示
]]
function GirlsMagicBonusGame:refreshSelfSelected()
    local choose = self:getSelfSelected()
    --数据错误返回大厅
    if not choose then
        self.m_machine:showOutGame()
        return false
    end
    local node = cc.Node:create()
    --创建选择的衣服
    for index = 1,#choose do
        local spine = self.m_machine.m_spineManager:getChooseClothes(index,choose[index])
        node:addChild(spine)
        if index == 2 then
            spine:setLocalZOrder(10)
        else
            spine:setLocalZOrder(index)
        end
    end
    -- release_print("***************************添加自己选择的衣服")
    local Node_dress = self.m_bonusCredits:findChild("Node_dress")
    Node_dress:removeAllChildren(true)
    Node_dress:addChild(node)

    return true
end

--[[
    显示选择界面
]]
function GirlsMagicBonusGame:showChooseView(endFunc)
    if self.m_isEnd then
        return
    end
    self:setGameEnd(false)
    self.m_isShowEnd = false
    self:setVisible(true)
    self:hideSpinView()
    self.m_result_view:setVisible(false)
    self.m_bonusCredits:setVisible(false)
    self.m_node_role_result:setVisible(false)
    self.m_totalCount = 5
    
    --设置结束回调
    self.m_endFunc = endFunc
    self.m_chooseResultView:changeLeftTimes(0,self.m_totalCount)
    

    local bonusStart = function(roomData)
        --清空回调
        self.m_chooseResultView:setCallBack(nil)
        if self.m_isEnd then
            return
        end

        --获取房间数据
        self.m_roomData = roomData
        self.m_result = self.m_roomData.result.data
        self.m_curSpinIndex = 1
        self:changeBonusCredis(0)
        
        --执行开始动画
        self.m_chooseResultView:startAni(function(  )
            if self.m_isEnd then
                return
            end
            --过场动画
            self.m_machine:closeCurtain(false,function(  )
                if self.m_isEnd then
                    return
                end

                self.m_chooseResultView:showShadow()
                self.m_chooseResultView:downAni()
                self:showView()
                self.m_machine:openCurtain(false)
            end)
        end)
        
    end
    self.m_chooseResultView:showView()

    --设置回调函数
    self.m_chooseResultView:setCallBack(bonusStart)
    --开始刷帧,刷新数据
    self.m_chooseResultView:startSchdule()
    
end

--[[
    设置游戏结束
]]
function GirlsMagicBonusGame:setGameEnd(isEnd)
    self.m_isEnd = isEnd
end

--[[
    显示界面
]]
function GirlsMagicBonusGame:showView()
    self:setVisible(true)
    self:showSpinView()
    if self.m_isEnd then
        return
    end
    
    --判断是否自身数据存在问题
    local isHaveSelfData = self:refreshSelfSelected()
    if not isHaveSelfData then
        return
    end

    --开始旋转
    self:startSpin()
end

--[[
    开始旋转
]]
function GirlsMagicBonusGame:startSpin()
    if self.m_isEnd then
        return
    end
    self.m_bonusCredits:setVisible(true)
    self.m_chooseResultView:changeLeftTimes(self.m_curSpinIndex,self.m_totalCount)
    -- release_print("***************************移除特效")
    self.m_effectNode:removeAllChildren(true)
    local freeType = self:getFreeType()
    local allClothes = self.m_spineManager:randAllClothes(freeType[1],freeType[2],freeType[3])
    
    self.m_isSpinEnd = false

    local actionIndex = 0
    --创建角色
    -- release_print("***************************角色说话")
    self.m_spineManager:roleSpeakAni(self.m_spine_role,handler(nil,function(  )
        actionIndex = actionIndex + 1
        if actionIndex < 2 then
            -- release_print("***************************随机台词")
            --随机台词
            local wordIndex = math.random(1,3)
            self:showWordAni(false,wordIndex)
        else
            --结束选择
            self.m_isSpinEnd = true
            local wordIndex = math.random(1,3)
            self:showWordAni(true,wordIndex)

            self.m_machine:delayCallBack(0.8,function(  )
                if self.m_isEnd then
                    return
                end
                --过场动画
                self.m_machine:closeCurtain(false,function()
                    if self.m_isEnd then
                        return
                    end
                    self.m_node_mid:setVisible(false)
                    self:hideSpinView()
                    self:showResultView()
                    self.m_machine:openCurtain(false)
                end)
            end)
            
            
        end
        
    end))
    self:createNextClothes(allClothes,1)
end

--[[
    展示台词
]]
function GirlsMagicBonusGame:showWordAni(isLeft,wordIndex)
    local aniName = isLeft and "GirlsMagic_qipaoidle1.csb" or "GirlsMagic_qipaoidle2.csb"
    local wordAni = util_createAnimation(aniName)
    self.m_node_word:addChild(wordAni)

    local WORD_GIRL = isLeft and WORD_GIRL_LEFT or WORD_GIRL_RIGHT

    for iWord = 1,#WORD_GIRL do
        wordAni:findChild(WORD_GIRL[iWord].node):setVisible(iWord == wordIndex)
        if iWord == wordIndex then
            gLobalSoundManager:playSound(WORD_GIRL[iWord].sound)
        end
    end
    wordAni:setPosition(cc.p(isLeft and -50 or 50,150))
    wordAni:runCsbAction("start",false,function(  )
        self.m_machine:delayCallBack(0.5,function(  )
            if wordAni then
                wordAni:runCsbAction("over",false,function(  )
                    wordAni:removeFromParent(true)
                end)
            end
            
        end)
    end)
end

--[[
    随机台词
]]
function GirlsMagicBonusGame:randWord()
    
    local rand_direction = math.random(1,2) --1 左侧 2右侧
    local isLeft = rand_direction == 1

    local word_index = 1
    if isLeft then
        word_index = math.random(1,2)
    else
        word_index = math.random(1,3)
    end
    
    return isLeft,word_index
end

--[[
    创建下一件衣服
]]
function GirlsMagicBonusGame:createNextClothes(allClothes,index)
    if index > #allClothes then
        index = 1
    end
    local clothType = allClothes[index]

    self.m_spineManager:createRoundShowAni(clothType,self.m_node_front,self.m_node_behind,100 - index,function(  )
        if self.m_isSpinEnd or self.m_isEnd then
            return
        end
        self:createNextClothes(allClothes,index + 1)
    end)
end

--[[
    是否为free奖励
]]
function GirlsMagicBonusGame:getFreeType()

    local curResult = self.m_result.suits[self.m_curSpinIndex]
    local freeType = {false,false,false}

    if curResult[1] > 4 then
        freeType[1] = true
    end
    if curResult[2] > 3 then
        freeType[2] = true
    end
    if curResult[3] > 2 then
        freeType[3] = true
    end

    return freeType
end

--[[
    显示旋转界面
]]
function GirlsMagicBonusGame:showSpinView()
    self:findChild("rope_bg"):setVisible(true)
    self:findChild("rope"):setVisible(true)
    self.m_node_front:setVisible(true)
    self.m_node_behind:setVisible(true)
    -- release_print("***************************移除展示结果")
    --用于挂载角色
    self.m_node_mid:setVisible(true)
    self.m_node_role_result:setVisible(false)
end

--[[
    隐藏旋转界面
]]
function GirlsMagicBonusGame:hideSpinView()
    self:findChild("rope_bg"):setVisible(false)
    self:findChild("rope"):setVisible(false)
    self.m_node_front:setVisible(false)
    self.m_node_behind:setVisible(false)
    -- release_print("***************************移除说话角色")
    --用于挂载角色
    self.m_node_mid:setVisible(false)
end

--[[
    显示结算界面
]]
function GirlsMagicBonusGame:showResultView()

    if self.m_isEnd then
        return
    end
    self.m_big_role_light:setVisible(false)
    --本次spin的衣服
    local curSuit = self.m_result.suits[self.m_curSpinIndex]
    self.m_spineManager:changeClothes(self.m_big_role,curSuit[1],curSuit[2],curSuit[3])
    
    
    self.m_node_role_result:setVisible(true)
    self.m_chooseResultView:upAni()
    self.m_result_view:setVisible(true)
    self.m_result_view:progressStartAni()

    --获取匹配结果
    local matchResult = self:getMatchResult()
    local percent = self:getPercentOfProcess()
    self.m_result_view:resetProgress(percent)

    self.m_curMutiples = self:getBerforeMutiple(self.m_curSpinIndex - 1)

    --开始匹配结果
    self.m_machine:delayCallBack(1.5,function(  )
        if self.m_isEnd then
            return
        end
        self:doNextMatch(matchResult,percent,1,function(isAllFull)
            if self.m_isEnd then
                return
            end
            self.m_curSpinIndex = self.m_curSpinIndex + 1
            if self.m_curSpinIndex > #self.m_result.suits then
                self:gameEnd()
            else
                --过场动画
                self.m_machine:closeCurtain(false,function()
                    if self.m_isEnd then
                        return
                    end
                    self.m_chooseResultView:downAni()
                    self.m_big_role_light:setVisible(false)
                    --三个进度条全部集满直接显示结果
                    if isAllFull then
                        self:showResultView()
                    else
                        self.m_result_view:setVisible(false)
                        self:showSpinView()
                        self:startSpin()
                    end
                    
                    self.m_machine:openCurtain(false)
                end)
            end
            
        end)
    end)
end

--[[
    显示freegame提示
]]
function GirlsMagicBonusGame:showFreeTip(freeType,func)
    local view = util_createAnimation("GirlsMagic/FreeSpinStart.csb")

    local tip = {
        color = "GirlsMagic_wenben07",
        bag = "GirlsMagic_wenben09_11",
        pattern = "GirlsMagic_wenben10_12"
    }

    local progress = {
        color = self.m_result_view.m_progress_color,
        bag = self.m_result_view.m_progress_bag,
        pattern = self.m_result_view.m_progress_pattern,
    }

    local node_pos_sign = {
        "Node_wild_0",
        "Node_wild_1",
        "Node_wild_2"
    }

    for key,value in pairs(node_pos_sign) do
        view:findChild(value):removeAllChildren(true)
    end

    for key,value in pairs(tip) do
        if table.indexof(freeType,key) then
            view:findChild(value):setVisible(true)
        else
            view:findChild(value):setVisible(false)
        end
    end

    --排列位置
    for index = 1,#freeType do
        view:findChild(tip[freeType[index]]):setPositionY(-130 + (-80 * (index - 1)))

        local progress = progress[freeType[index]]
        local temp = progress:findChild("GirlsMagic_jindutiao_bt11_22")
        local sp = cc.Sprite:createWithSpriteFrame(temp:getSpriteFrame())
        view:findChild(node_pos_sign[index]):addChild(sp)
    end

    self.m_machine.m_effectNode:addChild(view)
    
    view:findChild("Particle_1"):resetSystem()
    view:findChild("Particle_1_0"):resetSystem()
    view:setPosition(cc.p(-display.width / 2,-display.height / 2))
    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_freeSpin_start.mp3")
    view:runCsbAction("auto",false,function()
        view:removeFromParent(true)
    end)
    self.m_machine:delayCallBack(1.5,function(  )
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    开始下一阶段匹配
]]
function GirlsMagicBonusGame:doNextMatch(matchResult,percent,index,func)
    if self.m_isEnd then
        return
    end
    local curSuit = self.m_result.suits[self.m_curSpinIndex]
    --匹配结束
    if index > 4 then
        --重置倍数
        self.m_curMutiples = self:getBerforeMutiple(self.m_curSpinIndex)
        self:changeBonusCredis(self.m_curMutiples)
        
        --是否触发freegame
        local freeType = {}
        local isFree = false
        for i = 1,#percent do
            if percent[i].after >= 100 then
                isFree = true
                self.m_result_view:fullLightAni(MATCH_STEP[i + 1])
                table.insert(freeType,#freeType + 1,MATCH_STEP[i + 1])
            end
        end
        if isFree then
            self.m_totalCount = self.m_totalCount + 1
            self.m_machine:delayCallBack(0.6,function(  )
                --飞粒子效果
                for i = 1,#freeType do
                    local startNode = self.m_result_view:getProgressPosNode(freeType[i])
                    self:flyParticleAni(startNode,self:findChild("Node_PlayerDress"))
                end
                self.m_machine:delayCallBack(0.8,function()
                    --显示freegame提示
                    self:showFreeTip(freeType,function()
                        if self.m_isEnd then
                            return
                        end
                        if type(func) == "function" then
                            func(#freeType >= 3)
                        end
                    end)
                end)
            end)
        else
            if type(func) == "function" then
                func()
            end
        end
        
        return
    end

    --单次对比结束
    local function matchEnd()
        if self.m_isEnd then
            return
        end
        self:doNextMatch(matchResult,percent,index + 1,func)
        
    end

    local curMatch = MATCH_STEP[index]
    --完全匹配
    if curMatch == "fullMatch" then
        if #matchResult[curMatch] > 0 then
            self:showMatchWord(true,function(  )
                self.m_chooseResultView:fullMatchAni(matchResult[curMatch],self.m_curSpinIndex,function()
                    
                    matchEnd()
                end)
            end)
        else
            self:showMatchWord(false,nil,function(  )
                matchEnd()
            end)
            
        end
    else
        --匹配单项
        self.m_result_view:showProgress(curMatch,percent,function()
            self.m_big_role_light:setVisible(true)
            self.m_machine.m_spineManager:playBigRoleLight(self.m_big_role_light,index - 1,curSuit)
            

            if #matchResult[curMatch] > 0 then
                --判断当前匹配是否有自己
                for k,udid in pairs(matchResult[curMatch]) do
                    if udid == globalData.userRunData.userUdid then
                        local headItem = self.m_chooseResultView:getSelfHeadNode()
                        if headItem then
                            local startNode = headItem.multi_2
                            local endNode = self.m_bonusCredits:findChild("m_lb_multiplier")
                            self.m_machine:delayCallBack(2.8,function(  )
                                self:selfMatchAni(startNode,endNode,function(  )
                                    self.m_curMutiples = self.m_curMutiples + self:getMatchMutiple(index - 1)
                                    self:changeBonusCredis(self.m_curMutiples)
                                end)
                            end)
                        end
                        break
                    end
                end
                --匹配动画
                gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_bonus_complete.mp3")
                self.m_chooseResultView:matchAni(curMatch,matchResult[curMatch],self.m_curSpinIndex,function()
                    --更改进度条
                    self.m_result_view:changeProgress(curMatch,percent,function()
                        --回复最后一个进度条状态
                        if index >= 4 then
                            self.m_result_view:resetPatternAni()
                        end
                        --延时下一次匹配
                        self.m_machine:delayCallBack(0.5,function(  )
                            matchEnd()
                        end)
                    end)
                    
                end)
            else
                self.m_machine:delayCallBack(0.8,function(  )
                    matchEnd()
                end)
            end
        end)
    end
end

--[[
    自身匹配获得分数粒子动画
]]
function GirlsMagicBonusGame:selfMatchAni(startNode,endNode,func)
    if self.m_isEnd then
        return
    end
    local flyNode = util_createAnimation("GirlsMagic_tuowei.csb")
    local startPos = util_convertToNodeSpace(startNode,self.m_machine.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_machine.m_effectNode)
    flyNode:setPosition(startPos)
    self.m_machine.m_effectNode:addChild(flyNode,1000)

    local angle = util_getAngleByPos(startPos, endPos)
    flyNode:setRotation(-angle)

    local scaleSize = math.sqrt(math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2))
    flyNode:setScaleX(scaleSize / 460)

    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_fly_mutiples.mp3")
    
    flyNode:runCsbAction("actionframe",false,function(  )
        flyNode:removeFromParent(true)
    end)

    self.m_machine:delayCallBack(44 / 60,function(  )
        if self.m_isEnd then
            return
        end
        local bombAni = util_createAnimation("Socre_GirlsMagic_Bonus_shouji_bao.csb")
        self.m_machine.m_effectNode:addChild(bombAni,1000)
        bombAni:setPosition(endPos)
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_refresh_score_bonus.mp3")
        bombAni:runCsbAction("actionframe",false,function(  )
            bombAni:removeFromParent(true)
        end)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    获取前一次自身的总倍数
]]
function GirlsMagicBonusGame:getBerforeMutiple(spinIndex)
    if spinIndex < 1 then
        return 0
    end

    local userMultiples = self.m_result.userMultiples
    return userMultiples[spinIndex][globalData.userRunData.userUdid]
end

--[[
    获取当前匹配获取的倍数
]]
function GirlsMagicBonusGame:getMatchMutiple(matchIndex)
    if not self.m_result.userExtraMultiples[self.m_curSpinIndex] or
        not self.m_result.userExtraMultiples[self.m_curSpinIndex][globalData.userRunData.userUdid] or 
        not self.m_result.suitMultiple[matchIndex] then
        return 0
    end
    return self.m_result.userExtraMultiples[self.m_curSpinIndex][globalData.userRunData.userUdid] * self.m_result.suitMultiple[matchIndex]
end

--[[
    获取自身选择
]]
function GirlsMagicBonusGame:getSelfSelected()
    --计算完全匹配
    local selects = self.m_result.selects

    local selfSelectInfo = nil
    for index = 1 ,#selects do
        
        if selects[index].udid == globalData.userRunData.userUdid then
            selfSelectInfo = selects[index]
        end
    end
    
    if selfSelectInfo then
        return selfSelectInfo.chooses
    end
    
end

--[[
    计算完全匹配
]]
function GirlsMagicBonusGame:getMatchResult()
    --计算完全匹配
    local selects = self.m_result.selects
    local curResult = self.m_result.suits[self.m_curSpinIndex]

    --存储各项匹配结果
    local matchResult = {
        fullMatch = {},
        color = {},
        bag = {},
        pattern = {}
    }

    for index = 1 ,8 do
        local choose = selects[index].chooses
        local isColorMatch,isBagMatch,isPatternMatch = false,false,false
        --颜色匹配
        if curResult[1] == 5 or curResult[1] == choose[1] then
            table.insert(matchResult.color,#matchResult.color + 1,selects[index].udid)
            isColorMatch = true
        end
        --配饰匹配
        if curResult[2] == 4 or curResult[2] == choose[2] then
            table.insert(matchResult.bag,#matchResult.bag + 1,selects[index].udid)
            isBagMatch = true
        end
        --花纹匹配
        if curResult[3] == 3 or curResult[3] == choose[3] then
            table.insert(matchResult.pattern,#matchResult.pattern + 1,selects[index].udid)
            isPatternMatch = true
        end

        --全部匹配
        -- if isColorMatch and curResult[1] < 5 and isBagMatch and curResult[2] < 4 and isPatternMatch and curResult[3] < 3 then
        --     table.insert(matchResult.fullMatch,#matchResult.fullMatch + 1,selects[index].udid)
        -- end
        if isColorMatch and isBagMatch and isPatternMatch then
            table.insert(matchResult.fullMatch,#matchResult.fullMatch + 1,selects[index].udid)
        end
    end

    return matchResult
end

--[[
    计算当前进度和增加后的进度
]]
function GirlsMagicBonusGame:getPercentOfProcess()
    --当前进度
    local curPercent = self.m_result.processes[self.m_curSpinIndex]
    --上一次进度
    local lastPercent = self.m_result.processes[self.m_curSpinIndex - 1]
    local totalPercent = self.m_result.suitParams

    local process = {}
    for index = 1,3 do
        local tempData = {
            before = 0,
            after = 0
        }
        if self.m_curSpinIndex == 1 then
            tempData.after = (curPercent[index] / totalPercent[index]) * 100
        else
            local tempPercent = lastPercent[index]
            --上一次为奖励次数
            if tempPercent >= totalPercent[index] then
                tempPercent = totalPercent[index]
            end
            tempData.before = (tempPercent / totalPercent[index]) * 100
            tempData.after = (curPercent[index] / totalPercent[index]) * 100
            if tempData.after > 100 then
                tempData.after = 100
            end

            if tempData.before > 100 then
                tempData.before = 100--tempData.before - 100
            end
        end
        process[index] = tempData
    end
    return process
end

--[[
    显示匹配提示词
]]
function GirlsMagicBonusGame:showMatchWord(isFull,keyFunc,endFunc)
    self.m_matchWord:setVisible(true)
    self.m_matchWord:runCsbAction("actionframe",false,function(  )
        self.m_matchWord:setVisible(false)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
    self.m_machine:delayCallBack(2.5,function(  )
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)

    local full_word = self.m_matchWord:findChild("GirlsMagic_FULL_1")
    local who_word = self.m_matchWord:findChild("GirlsMagic_WHO_2")
    if isFull then
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_show_full_match.mp3")
        full_word:setVisible(true)
        who_word:setVisible(false)
        full_word:getChildByName("Particle_1"):resetSystem()
        full_word:getChildByName("Particle_1_0"):resetSystem()
    else
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_show_who_got_match.mp3")
        full_word:setVisible(false)
        who_word:setVisible(true)
        who_word:getChildByName("Particle_1_0_0"):resetSystem()
        who_word:getChildByName("Particle_1_0"):resetSystem()
    end
end

--[[
    飞粒子效果
]]
function GirlsMagicBonusGame:flyParticleAni(startNode,endNode,func)
    local ani = util_createAnimation("GirlsMagic_FreeTW.csb")
    ani:findChild("Particle_2"):setPositionType(0)
    ani:findChild("Particle_2_0"):setPositionType(0)
    self.m_effectNode:addChild(ani)

    ani:setPosition(util_convertToNodeSpace(startNode,self.m_effectNode))

    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(0.5,endPos),
        cc.CallFunc:create(function(  )
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    })
    ani:runAction(seq)
end

--[[
    游戏结束
]]
function GirlsMagicBonusGame:gameEnd()
    self.m_machine:clearCurMusicBg()

    if self.m_isShowEnd then
        return
    end
    self.m_isShowEnd = true

    if not self.m_isEnd then
        local completedAni = util_createAnimation("GirlsMagic/BonusCompleted.csb")
        completedAni:setPosition(cc.p(-display.width / 2,-display.height / 2))
        self.m_machine:findChild("root"):addChild(completedAni, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_bonus_complete.mp3")
        completedAni:runCsbAction("auto",false,function(  )
            completedAni:removeFromParent(true)
            self.m_result_view:setVisible(false)
            --拉上帘子
            self.m_machine:closeCurtain(false,function(  )
                
            end)
            
            self.m_machine:delayCallBack(0.47,function(  )
                --显示bonus结果
                self:showBonusOver(function(  )
                    --拉开帘子
                    self.m_machine:openCurtain(true,function(  )
                        
                    end)
                    if type(self.m_endFunc) == "function" then
                        self.m_endFunc(self.m_result)
                        self.m_endFunc = nil
                    end
                end)
            end)
            
        end)
    else
        self.m_result_view:setVisible(false)
        --拉上帘子
        self.m_machine:closeCurtain(false,function(  )
            
        end)
        
        self.m_machine:delayCallBack(0.47,function(  )
            --显示bonus结果
            self:showBonusOver(function(  )
                --拉开帘子
                self.m_machine:openCurtain(true,function(  )
                    
                end)

                if type(self.m_endFunc) == "function" then
                    self.m_endFunc(self.m_result)
                    self.m_endFunc = nil
                end
            end)
        end)
    end
    
    

    
end

--[[
    显示bonus结果
]]
function GirlsMagicBonusGame:showBonusOver(func)
    --最后一条数据
    local lastData = self.m_result.userMultiples[#self.m_result.userMultiples]

    local ownerlist={}
    local coins = lastData[globalData.userRunData.userUdid] * self.m_result.userScore[globalData.userRunData.userUdid]
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)

    --检测是否获得大奖
    self.m_machine:checkFeatureOverTriggerBigWin(coins, GameEffect.EFFECT_BONUS)

    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_bonus_over.mp3")
    local view = self.m_machine:showDialog("BonusOver",ownerlist,function()
        local gameName = self.m_machine:getNetWorkModuleName()
        local index = -1 
        gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
            function()
                globalData.slotRunData.lastWinCoin = 0
                --刷新顶部金币
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                    coins, true, true
                })
            end,
            function(errorCode, errorData)
                
            end
        )
        if type(func) == "function" then
            func()
        end
    end)
    

    local info={label = view:findChild("m_lb_coins"),sx = 1.33,sy = 1.33}
    self:updateLabelSize(info,568)

    local selects = self.m_result.selects
    --排序
    local sortArray = {}
    for userIndex = 1,8 do
        local temp = {}
        temp.udid = selects[userIndex].udid
        temp.facebookId = selects[userIndex].facebookId
        temp.head = selects[userIndex].head
        temp.mutiples = lastData[selects[userIndex].udid]
        sortArray[userIndex] = temp
    end

    table.sort(sortArray,function(a,b)
        return a.mutiples > b.mutiples
    end)

    
    for index = 1,8 do
        local node = view:findChild("Node_Player_"..index)
        node:removeAllChildren(true)
        
        if sortArray[index] then
            --创建头像
            local item = util_createAnimation("GirlsMagic_Player_BonusOver.csb")
            node:addChild(item)
            item:runCsbAction("actionframe",true)

            local isMe = (globalData.userRunData.userUdid == sortArray[index].udid)
            item:findChild("head_bg_other"):setVisible(not isMe)
            item:findChild("head_bg_me"):setVisible(isMe)
            item:findChild("num_bg_other"):setVisible(not isMe)
            item:findChild("num_bg_me"):setVisible(isMe)

            local head = item:findChild("touxiang")
            --刷新头像
            util_setHead(head, sortArray[index].facebookId, sortArray[index].head, nil, false)
            
            --刷新倍数
            local m_lb_num = item:findChild("m_lb_num")
            m_lb_num:setString("X"..(sortArray[index].mutiples or 0))
        end
    end
    util_setCascadeOpacityEnabledRescursion(view,true)
    
end

return GirlsMagicBonusGame