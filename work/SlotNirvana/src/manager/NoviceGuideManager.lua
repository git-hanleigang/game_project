--
--2019年2月28日
--NoviceGuideManager.lua
--新手引导管理

--[[
1.需要一个引导队列  依次展示队列中的引导
2.需要一个add 方法 当某个引导满足条件时 添加到引导队列
3.需要一个order 所有引导的优先级  添加队列时用来排序     1
4.如果配置nextId 添加完成后执行的下一个
5.如果配置preId 需要先判断perId是否完成

--]]
local NoviceGuideManager = class("NoviceGuideManager")

NoviceGuideManager.m_instance = nil

--order
GD.NOVICEGUIDE_ORDER = {
    -- 第一新手引导按照分组来，（一部分领新手金币， 一部分直接进入关卡（在关卡里领金币））
    goToFirstSlotGame = {id = 0},
    -- 1.新手金币指引
    initIcons = {id = 1, nextId = 2, size = {200, 200}},
    -- 2.
    comeCust = {
        id = 2,
        preId = 1,
        size = {250, 300},
        offset = {0, 130},
        finger = {-65, -70},
        fingerRotate = 45,
        bubble = {170, 130},
        npc = {id = 2, x = 450, y = -70},
        name = "comeCust_2",
        force = true
    },
    -- 3.关卡中paytable指引
    payTable = {id = 3, nextId = 6, size = {60, 60}, bubble = {15, -25}, portrait = {size = {50, 50}}},
    -- 4.新手任务开始
    noobTaskStart1 = {id = 4, preId = 2, size = {250, 250}, offset = {0, 0}, finger = {0, 140}, fingerRotate = 0, force = true},
    -- 5.升级，关卡中bet提示
    levelUp = {id = 5, size = {200, 200}, force = true},
    -- 6.提升bet值
    addBet = {id = 6, size = {50, 50}, bubble = {0, 45}},
    -- 7.新手任务结束指引
    noobTaskFinish1 = {id = 7, size = {20, 50}, bubble = {170, 315}, name = "noobTaskFinish1_8"},
    noobTaskFinish2 = {id = 8, preId = 7, size = {20, 50}, bubble = {170, 315}, name = "noobTaskFinish2_10"},
    noobTaskFinish3 = {id = 9, preId = 8, size = {20, 50}, bubble = {170, 315}, name = "noobTaskFinish3_12"},
    -- 8.未找到
    noobQuestReward4 = {id = 100, size = {20, 50}},
    -- 9.关卡中小猪银行出现指引
    piggyBank = {id = 9999, size = {20, 50}, offset = {0, -50}, bubble = {-10, 15}},
    -- 10.quest活动打点
    quest_newPlayer = {
        id = 111,
        size = {300, 300},
        offset = {0, 80},
        npc = {id = 1, x = 550, y = 10},
        bubble = {280, 240},
        name = "questStart",
        touchCallBack = function()
            -- local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            -- if questConfig and questConfig.p_expireAt then
            --     gLobalDataManager:setBoolByField("quest_fristGudie"..questConfig.p_expireAt,false)
            -- end
        end
    },
    -- 11. 关卡右下角任务指引(后面补充引导内容)
    dallyMissionReward = {preId = 9999, id = 140, size = {200, 200}, offset = {0, 0}, bubble = {0, 60}, bubble_portrait = {5, 65}, name = "cashBonus_22"},
    -- 12.未找到
    sale = {id = 150, size = {20, 50}, offset = {0, 0}},
    -- 13-1.bingo强制引导-关卡选择界面
    bingoFirstEnter_Select = {id = 181, size = {200, 200}, force = true},
    -- 13-2.bingo强制引导-主界面， 如果直接完成了的这一步那么上一步也算完成
    bingoFirstEnter_Game_Machine = {id = 182, size = {200, 200}, force = true},
    -- 13-3.bingo非强制引导-主界面
    bingoFirstEnter_Game_Rank = {preId = 182, id = 183, size = {200, 200}},
    -- 13-4.bingo非强制引导-主界面
    bingoFirstEnter_Game_PayLine = {preId = 183, id = 184, size = {200, 200}},
    -- 14.游戏大厅右下角中的轮盘指引-每日轮盘
    dallyWhell = {id = 200, size = {200, 250}, force = true},
    -- 15.游戏大厅右下角中的轮盘指引-银轮盘
    silverEntrepot = {preId = 9999, id = 210, size = {200, 250}, bubble = {-150, 480}, name = "silverEntrepot", finger = {0, 0}, fingerRotate = 180, npc = {id = 5, x = -400, y = 250}, force = true},
    -- 16.CashBonus主界面，两个引导-银轮盘
    silverFront = {preId = 9999, id = 214, size = {180, 155}, bubble = {90, 130}, name = "silverEntrepot_front", finger = {0, 0}, fingerRotate = 180, force = true},
    silverBack = {preId = 214, id = 215, nextId = 220, size = {180, 150}, bubble = {90, 130}, name = "silverEntrepot_back"},
    -- 17.银库领奖指引
    bonusTips = {id = 220},
    -- 18.商城引导
    shopReward = {id = 230, preId = 999, levelNum = 20},
    shopReward2 = {
        preId = 230,
        id = 240,
        -- preId = 999,
        size = {250, 120},
        offset = {0, 0},
        bubble = {-100, 480},
        name = "freecoins",
        finger = {5, 0},
        finger_portrait = {0, 0},
        fingerRotate = 180,
        npc = {id = 5, x = -350, y = 230},
        force = true
    },
    -- 19.每日商城礼物-点击引导
    shopTips = {id = 250, preId = 999},
    -- 20.关卡中左上角cashbonus的提示
    cashbonusMul = {preId = 240, id = 260},
    -- 20.defend活动引导

    -- shopTips = {id = 260},

    -- 可重复弹出的id
    -- 22.商城奖励刷新引导
    shopReward3 = {id = 235, preId = 999, levelNum = 20, repetition = true},
    -- 23.进入大厅时，金库可以收集时弹框引导
    goldenEntrepotOpen = {id = 300, preId = 999, repetition = true},
    goldenEntrepotClose = {id = 301, preId = 999, repetition = true},
    -- 24.登陆到大厅需要更新每日任务完成时引导
    missionComleted = {id = 302, preId = 999, repetition = true},
    --------------- 公会 --------------
    -- 25. 公会
    clanFirstEnterMain = {id = 400, preId=999}, -- 第一次进入公会主页
    clanFirstEnterChat = {id = 401, preId=999}, -- 第一次进入公会聊天
    clanFirstEnterMember = {id = 402, preId=999}, -- 第一次进入公会成员列表
    clanFirstEnterRank = {id = 4031, preId=999}, -- 第一次进入公会排行界面 (403 -> 4031新UI重新跑一下引导)
    clanFirstEnterRankBenifit = {id = 404, preId=999}, -- 第一次进入公会排行界权益界面
    clanFirstEnterHomeTip = {id = 405, preId=999}, -- 第一次进入公会主界面 弹新功能宣传
    clanFirstEnterRush = {id = 406, preId=999}, -- 第一次进入公会Rush界面
    clanFirstCheckNewEditMain = {id = 407, preId=999}, -- 会长第一次查看新版公会信息页
    clanFirstCheckNewEditPanel = {id = 408, preId=999}, -- 会长第一次查看新版公会信息页
    clanFirstCheckNewPositionView = {id = 409, preId=999}, -- 会长第一次查看公会成员职位view
    --------------- 公会 --------------
    -- 26. 个人信息也引导
    userInfoGuide = {id = 500, preId = 999},
    -- 27. 彩票乐透
    lotteryChooseNumber = {id = 700, preId = 999},
    -- 28. 头像框
    AvatarFrameMachineEntry = {id = 800, preId = 999},
    AvatarFrameMainUI = {id = 801, preId = 999},
}
GD.GUIDE_LEVEL_POP = {
    LevelUpFast = "LevelUpFast",
    MaxBet = "MaxBet",
    AddBet = "AddBet",
    ReturnLobbyForGame = "ReturnLobbyForGame",
    BetUpNotice = "BetUpNotice", -- spin 升级后 bet值小于指定bet 弹出气泡
}
NoviceGuideManager.current_info = nil
NoviceGuideManager.m_newbieMask = nil --防止点击的遮罩
NoviceGuideManager.m_menuNodeClick = nil --特殊处理
--执行队列
local NoviceGuideQueue = {}
local NoviceGuideRepetitionQueue = {}
local NodeList = {}

function NoviceGuideManager:getInstance()
    if NoviceGuideManager.m_instance == nil then
        NoviceGuideManager.m_instance = NoviceGuideManager.new()
    end
    return NoviceGuideManager.m_instance
end

-- 构造函数
function NoviceGuideManager:ctor()
    self.m_isRepetitionShow = false
    self.m_firstGuideInfo = nil
end

function NoviceGuideManager:setShowState(flg)
    self.m_isRepetitionShow = flg
end

function NoviceGuideManager:getShowState()
    return self.m_isRepetitionShow
end

function NoviceGuideManager:attemptShowRepetition()
    if self.m_isRepetitionShow then
        return
    end
    self:NextShowRepetition()
end

--防止报错
function NoviceGuideManager:getWorldPos(id)
    local pos = cc.p(display.cx, display.cy)
    if not id then
        return pos
    end
    release_print("NoviceGuideManager:getWorldPos start id =" .. id)
    local nodoInfo = NodeList[id]
    if nodoInfo then
        xpcall(
            function()
                if nodoInfo.node and nodoInfo.node.getParent then
                    pos = nodoInfo.node:getParent():convertToWorldSpace(cc.p(nodoInfo.node:getPosition()))
                end
            end,
            function()
                release_print("NoviceGuideManager:getWorldPos error for id =" .. id)
            end
        )
    end
    release_print("NoviceGuideManager:getWorldPos end id =" .. id)
    return pos
end

function NoviceGuideManager:addNode(id, node, scale)
    NodeList[id.id] = {}
    NodeList[id.id].node = node
    if not scale then
        scale = 1
    end
    NodeList[id.id].scale = scale
end

--尝试完成引导检测开启下一个引导 checkInfo尝试完成的引导  isStopNext停止下一个引导弹出
function NoviceGuideManager:checkFinishGuide(checkInfo, isStopNext, isFixMaskUI, success_callback, faild_callback)
    if not checkInfo or not checkInfo.id then
        return
    end
    --如果存在任务 完成任务判断是否有后续任务
    if self.current_info then
        if self.current_info.id == checkInfo.id then
            if not isFixMaskUI then
                self:removeMaskUI()
            end

            local successCallback = function()
                if success_callback then
                    success_callback()
                end
            end

            self:addFinishList(checkInfo, successCallback, faild_callback)
            self:checkNextGuide(checkInfo, isStopNext)
            return true
        end
    end
    return false
end

--跟着父节点透明度变化
function NoviceGuideManager:autoFadeOut(time)
    if self:isMaskUI() and time then
        self.m_baseNode:stopAllActions()
        util_setCascadeOpacityEnabledRescursion(self.m_baseNode, true)
        self.m_baseNode:runAction(cc.FadeOut:create(time))
    end
end

--清理引导
function NoviceGuideManager:clearGuide()
    if self:isMaskUI() then
        self.m_delayTime = nil
        self.m_baseNode:removeAllChildren()
        self.m_baseNode:removeFromParent()
        self.m_baseNode = nil
    end
    NoviceGuideQueue = {}
    self.current_info = nil
    --遇到需要清理引导ui可以在这发消息
    self.m_newPopList = {}
end

--检测是否可以弹出某个引导 isClearQueue清理引导强制执行当前引导
function NoviceGuideManager:checkNextShow(checkInfo, isClearQueue, ignoreNoobLevel)
    if not self:isNoobUsera(ignoreNoobLevel) then
        return
    end

    if not checkInfo then
        return false
    end

    --正在执行的引导
    if self:isCurrentGuide(checkInfo) then
        return false
    end

    --是否有等级限制
    if checkInfo.levelNum ~= nil then
        if checkInfo.levelNum > globalData.userRunData.levelNum then
            return false
        end
    end

    --是否有前置条件
    if checkInfo.preId then
        if not self:getIsFinish(checkInfo.preId) then
            return false
        end
    end

    --是否已经完成了
    if self:getIsFinish(checkInfo.id) then
        return false
    end

    if isClearQueue then
        self:clearGuide()
    end

    --是否已经在队列中
    if NoviceGuideQueue and #NoviceGuideQueue > 0 then
        for i = 1, #NoviceGuideQueue do
            if checkInfo.id == NoviceGuideQueue[1].id then
                self:NextShow()
                return true
            end
        end
    end
    --添加队列
    self:addQueue(checkInfo)
    --尝试展示
    self:NextShow()
    return true
end

--判断是否有后续任务
function NoviceGuideManager:checkNextGuide(checkInfo, isStopNext)
    if checkInfo.nextId then
        local nextInfo = self:getInfo(checkInfo.nextId)
        if nextInfo then
            self:addQueue(nextInfo)
        end
    end
    if not isStopNext then
        self:NextShow()
    end
end

--检测是否是当前引导
function NoviceGuideManager:isCurrentGuide(checkInfo)
    if self.current_info then
        if self.current_info.id == checkInfo.id then
            return true
        end
    end
    return false
end

--是否有引导
function NoviceGuideManager:isNoGuide()
    if NoviceGuideQueue and #NoviceGuideQueue > 0 then
        return false
    end
    return true
end

--是否存在遮罩
function NoviceGuideManager:isMaskUI()
    if self.m_baseNode and not tolua.isnull(self.m_baseNode) then
        return true
    end
end
--是否存在额外遮罩
function NoviceGuideManager:isNewMaskUI()
    if self.m_newbieMask and not tolua.isnull(self.m_newbieMask) then
        return true
    end
end
--移除引导动画
function NoviceGuideManager:removeMaskUI()
    if self:isMaskUI() then
        self.m_delayTime = nil
        local node = self.m_baseNode
        self.m_baseNode = nil
        util_setCascadeOpacityEnabledRescursion(node, true)
        node:runAction(cc.FadeTo:create(0.5, 0))
        performWithDelay(
            node,
            function()
                node:removeFromParent()
            end,
            0.5
        )
    end
    if self:isNewMaskUI() then
        self.m_newbieMask:removeFromParent()
        self.m_newbieMask = nil
    end
end

function NoviceGuideManager:createAndRemoveBubble(info, path, time, frames)
    if not time then
        time = 3
    end
    if not frames then
        frames = 60
    end

    local zorder = ViewZorder.ZORDER_GUIDE
    if info.id == NOVICEGUIDE_ORDER.dallyMissionReward.id then
        zorder = 0
    end

    local baseNode = cc.Node:create()
    if gLobalViewManager:isViewPause() then
        display.getRunningScene():addChild(baseNode, zorder)
    else
        gLobalViewManager:getViewLayer():addChild(baseNode, zorder)
    end

    local pos = self:getWorldPos(info.id)
    --位置偏移
    if info.offset then
        pos = cc.p(pos.x + info.offset[1], pos.y + info.offset[2])
    end

    --小手
    if info.finger then
        local finger = util_createView("views.noviceGuide.NoobTaskFinger")
        baseNode:addChild(finger)
        local x = pos.x + info.finger[1]
        local y = pos.y + info.finger[2]
        if globalData.slotRunData.isPortrait == true then
            if info.finger_portrait then
                x = pos.x + info.finger_portrait[1]
                y = pos.y + info.finger_portrait[2]
            end
        end
        finger:setPosition(x, y)
        util_setCascadeOpacityEnabledRescursion(finger, true)
        finger:setOpacity(0)
        if info.fingerRotate then
            finger:setRotation(info.fingerRotate)
        end
        performWithDelay(
            baseNode,
            function()
                finger:runAction(cc.FadeTo:create(0.5, 255))
            end,
            1
        )
    end

    --气泡
    local bubble
    if info.bubble then
        if path then
            bubble = util_createAnimation(path)
            bubble:runCsbAction("show", false)
        else
            bubble = util_createView("views.noviceGuide.NoobBubble", info.name)
            util_setCascadeOpacityEnabledRescursion(bubble, true)
            bubble:setOpacity(0)
            performWithDelay(
                baseNode,
                function()
                    bubble:runAction(cc.FadeTo:create(0.5, 255))
                end,
                0.5
            )
        end

        baseNode:addChild(bubble)
        local x = pos.x + info.bubble[1]
        local y = pos.y + info.bubble[2]
        if globalData.slotRunData.isPortrait == true then
            if info.bubble_portrait then
                x = pos.x + info.bubble_portrait[1]
                y = pos.y + info.bubble_portrait[2]
            end
        end
        bubble:setPosition(x, y)
    end
    if bubble then
        performWithDelay(
            baseNode,
            function()
                bubble:runCsbAction(
                    "over",
                    false,
                    function()
                        self:checkFinishGuide(info)
                        util_setCascadeOpacityEnabledRescursion(baseNode, true)
                        baseNode:runAction(cc.FadeTo:create(0.5, 0))
                        performWithDelay(
                            baseNode,
                            function()
                                baseNode:removeFromParent()
                            end,
                            0.5
                        )
                    end,
                    frames
                )
            end,
            time
        )
    end

    return bubble
end

function NoviceGuideManager:addNewPop(key, pos, path)
    if not self.m_newPopList then
        self.m_newPopList = {}
    end
    local baseNode = cc.Node:create()
    local zorder = ViewZorder.ZORDER_GUIDE

    if gLobalViewManager:isViewPause() then
        display.getRunningScene():addChild(baseNode, zorder)
    else
        gLobalViewManager:getViewLayer():addChild(baseNode, zorder)
    end
    -- pos = nodoInfo.node:getParent():convertToWorldSpace(cc.p(nodoInfo.node:getPosition()))
    local pop = util_createAnimation("NoviceGuide/" .. path)
    baseNode:addChild(pop)
    pop:setPosition(pos.x, pos.y)
    pop:playAction("show", false, nil, 60)
    performWithDelay(
        baseNode,
        function()
            if baseNode then
                pop:playAction(
                    "over",
                    false,
                    function()
                        if self.m_newPopList[key] then
                            self.m_newPopList[key]:removeFromParent()
                            self.m_newPopList[key] = nil
                        end
                    end,
                    60
                )
            end
        end,
        4
    )
    self.m_newPopList[key] = baseNode
end

function NoviceGuideManager:removeNewPop(key)
    if self.m_newPopList and self.m_newPopList[key] then
        self.m_newPopList[key]:removeFromParent()
        self.m_newPopList[key] = nil
    end
end

--遮罩抠洞 infoList = {{x,y,width},{x,y,width}}
function NoviceGuideManager:addSimpleMaskUI(infoList, autoTime, func, clickFunc)
    if not infoList or #infoList == 0 then
        return nil
    end
    local baseNode = cc.Node:create()
    gLobalViewManager:getViewLayer():addChild(baseNode, ViewZorder.ZORDER_SPECIAL)
    local mask = util_newMaskLayer()
    local stencilNode = cc.Node:create()
    mask:setOpacity(0)
    local isTouch = false
    mask:onTouch(
        function(event)
            if not isTouch then
                return true
            end
            if event.name ~= "ended" then
                return true
            end

            for i = 1, #infoList do
                local info = infoList[i]
                if info[3] > math.abs(event.x - info[1]) and info[3] > math.abs(event.y - info[2]) then
                    if clickFunc then
                        clickFunc()
                    end
                    break
                end
            end
            if baseNode then
                baseNode:removeFromParent()
                baseNode = nil
            end

            if func then
                func()
                func = nil
            end
            return true
        end,
        false,
        true
    )
    local clipNode = cc.ClippingNode:create()
    baseNode:addChild(clipNode)
    clipNode:setInverted(true)
    clipNode:setAlphaThreshold(0.95)
    clipNode:setStencil(stencilNode)
    clipNode:addChild(mask)
    --延迟显示遮罩
    mask:runAction(cc.FadeTo:create(0.5, 190))
    for i = 1, #infoList do
        local info = infoList[i]
        local sp_clip = display.newSprite("NoviceGuide/Other/zhezhao_yuan.png")
        stencilNode:addChild(sp_clip)
        local sp_mask = display.newSprite("NoviceGuide/Other/zhezhao_yuan2.png")
        baseNode:addChild(sp_mask)
        sp_mask:setOpacity(0)
        sp_mask:runAction(cc.FadeTo:create(0.5, 255))
        --设置坐标
        sp_clip:setPosition(info[1], info[2])
        sp_mask:setPosition(info[1], info[2])
        local size = sp_clip:getContentSize()
        local scale = info[3] / size.width
        --设置缩放
        sp_clip:setScale(scale)
        sp_mask:setScale(scale)
    end
    performWithDelay(
        baseNode,
        function()
            isTouch = true
        end,
        0.5
    )
    if autoTime then
        performWithDelay(
            baseNode,
            function()
                if baseNode then
                    baseNode:removeFromParent()
                    baseNode = nil
                end
                if func then
                    func()
                    func = nil
                end
            end,
            autoTime + 0.5
        )
    end
    return baseNode
end

--添加引导动画
function NoviceGuideManager:addMaskUI(info, path, noMask)
    self.m_delayTime = 0
    local baseNode = cc.Node:create()
    self.m_baseNode = baseNode
    local zorder = ViewZorder.ZORDER_SPECIAL
    if
        info.id == NOVICEGUIDE_ORDER.noobTaskStart1.id or info.id == NOVICEGUIDE_ORDER.noobTaskFinish1.id or info.id == NOVICEGUIDE_ORDER.noobTaskFinish2.id or
            info.id == NOVICEGUIDE_ORDER.noobTaskFinish3.id
     then
        zorder = 0
    end
    if gLobalViewManager:isViewPause() then
        display.getRunningScene():addChild(baseNode, zorder)
    else
        gLobalViewManager:getViewLayer():addChild(baseNode, zorder)
    end
    local mask = util_newMaskLayer()
    self.m_touchLayer = mask
    local pos = self:getWorldPos(info.id)
    local sp
    local sp1
    if info.id == NOVICEGUIDE_ORDER.shopReward2.id then
        sp = display.newSprite("NoviceGuide/Other/zhezhao_tyuan.png")
        sp1 = display.newSprite("NoviceGuide/Other/zhezhao_tyuan2.png")
    elseif info.id == NOVICEGUIDE_ORDER.noobTaskStart1.id then
        sp = display.newSprite("NoviceGuide/Other/zhezhao_tyuan.png")
        sp1 = display.newSprite("NoviceGuide/Other/zhezhao_tyuan3.png")
    else
        sp = display.newSprite("NoviceGuide/Other/zhezhao_yuan.png")
        sp1 = display.newSprite("NoviceGuide/Other/zhezhao_yuan2.png")
    end

    if info.offset then
        if globalData.slotRunData.isPortrait == true then
        else
            pos = cc.p(pos.x + info.offset[1], pos.y + info.offset[2])
        end
    end
    sp:setPosition(pos.x, pos.y)
    sp1:setPosition(pos.x, pos.y)
    local size = sp:getContentSize()
    local scaleX = info.size[1] / size.width
    local scaleY = info.size[2] / size.height
    local scalem = scaleX
    if globalData.slotRunData.isPortrait == true then
        scalem = scaleY
    end
    if info.scale then
        scalem = info.scale
    end
    sp:setScale(scalem)
    sp1:setScale(scalem)
    if globalData.slotRunData.isPortrait == true then
    end
    if noMask then
        -- baseNode:addChild(sp1)  --点击区域位置  测试用 正式注释掉
        baseNode:addChild(mask)
        mask:setOpacity(0)
    else
        mask:setOpacity(0)
        sp1:setOpacity(0)
        if info.id == NOVICEGUIDE_ORDER.noobTaskStart1.id then
            mask:runAction(cc.FadeTo:create(0.5, 130))
        else
            mask:runAction(cc.FadeTo:create(0.5, 190))
        end
        sp1:runAction(cc.FadeTo:create(0.5, 255))
        if self.m_delayTime < 0.5 then
            self.m_delayTime = 0.5
        end
        local clipNode = cc.ClippingNode:create()
        baseNode:addChild(clipNode)
        baseNode:addChild(sp1)
        clipNode:setInverted(true)
        clipNode:setAlphaThreshold(0.95)
        clipNode:setStencil(sp)
        clipNode:addChild(mask)
    end

    local btnPos = self:getWorldPos(info.id)
    if info.arrow then
    end
    --npc
    if info.npc then
        local npcNode = util_createAnimation("NoviceGuide/npc.csb")
        baseNode:addChild(npcNode)
        npcNode:setPosition(pos.x + info.npc.x, pos.y + info.npc.y)
        npcNode:setName("npcNode")
        for i = 1, 5 do
            local npc = npcNode:findChild("node_npc" .. i)
            if info.npc.id == i then
                npc:setVisible(true)
            else
                npc:setVisible(false)
            end
        end
        util_setCascadeOpacityEnabledRescursion(npcNode, true)
        npcNode:setOpacity(0)
        npcNode:runAction(cc.FadeTo:create(0.5, 255))
        --npc裁切特殊适配
        if info.id == NOVICEGUIDE_ORDER.levelUp.id then
            if globalData.slotRunData.isPortrait then
                npcNode:setScaleX(0.6)
                npcNode:setScaleY(0.6)
            else
                npcNode:setScaleX(0.75)
                npcNode:setScaleY(0.75)
            end
            npcNode:setPositionX(npcNode:getPositionX() + 70)
        elseif info.id == NOVICEGUIDE_ORDER.shopReward2.id then
            npcNode:setScaleX(-1)
        end
        if CC_RESOLUTION_RATIO == 2 then
            if info.id == NOVICEGUIDE_ORDER.comeCust.id then
                npcNode:setScaleX(0.75)
                npcNode:setScaleY(0.75)
                npcNode:setPositionX(npcNode:getPositionX() - 70)
            end
        end
    end

    if info.finger then
        local finger = util_createView("views.noviceGuide.NoobTaskFinger")
        baseNode:addChild(finger)
        finger:setName("finger")
        local x = pos.x + info.finger[1]
        local y = pos.y + info.finger[2]
        if globalData.slotRunData.isPortrait == true then
            if info.finger_portrait then
                x = pos.x + info.finger_portrait[1]
                y = pos.y + info.finger_portrait[2]
            end
        end
        finger:setPosition(x, y)
        if info.fingerRotate then
            finger:setRotation(info.fingerRotate)
        end
        util_setCascadeOpacityEnabledRescursion(finger, true)
        finger:setOpacity(0)
        performWithDelay(
            baseNode,
            function()
                finger:runAction(cc.FadeTo:create(0.5, 255))
            end,
            0.8
        )
        if self.m_delayTime < 1 then
            self.m_delayTime = 1
        end
    end
    if info.bubble then
        local bubble
        if path then
            bubble = util_createAnimation(path)
            bubble:playAction("show", false)
        else
            bubble = util_createView("views.noviceGuide.NoobBubble", info.name)
        end

        baseNode:addChild(bubble)
        local x = pos.x + info.bubble[1]
        local y = pos.y + info.bubble[2]
        if globalData.slotRunData.isPortrait == true then
            if info.bubble_portrait then
                x = pos.x + info.bubble_portrait[1]
                y = pos.y + info.bubble_portrait[2]
            end
        end
        bubble:setPosition(x, y)
        util_setCascadeOpacityEnabledRescursion(bubble, true)
        bubble:setOpacity(0)
        performWithDelay(
            baseNode,
            function()
                bubble:runAction(cc.FadeTo:create(0.5, 255))
            end,
            0.5
        )
        if self.m_delayTime < 0.5 then
            self.m_delayTime = 0.5
        end
    end

    local maskR = info.size[1]
    if globalData.slotRunData.isPortrait == true then
        maskR = info.size[2]
    end

    performWithDelay(
        baseNode,
        function()
            self.m_delayTime = nil
        end,
        self.m_delayTime
    )

    self.m_touchLayer:onTouch(
        function(event)
            if self.m_delayTime then
                return true
            end

            local rect = cc.rect(pos.x - maskR * 0.5, pos.y - maskR * 0.5, maskR, maskR)
            if info.touchSize then
                local touchSize = {}
                touchSize[1] = info.touchSize[1]
                touchSize[2] = info.touchSize[2]
                rect = cc.rect(btnPos.x - touchSize[1] * 0.5, btnPos.y - touchSize[2] * 0.5, touchSize[1], touchSize[2])
            end
            local touchPos = cc.p(event.x, event.y)

            if cc.rectContainsPoint(rect, touchPos) then
                if info.id == NOVICEGUIDE_ORDER.payTable.id then
                    return false
                end
            end

            --触摸屏幕不会自动关闭的引导
            if info.id == NOVICEGUIDE_ORDER.noobTaskFinish1.id then
                return false
            end
            if info.id == NOVICEGUIDE_ORDER.noobTaskFinish2.id then
                return false
            end
            if info.id == NOVICEGUIDE_ORDER.noobTaskFinish3.id then
                return false
            end

            if info.id == NOVICEGUIDE_ORDER.dallyMissionReward.id then
                return false
            end

            if event.name == "ended" then
            end

            if info.force then
            else
                if info.touchCallBack ~= nil then
                    info.touchCallBack()
                    info.touchCallBack = nil
                end
                self:removeMaskUI()
                self:checkFinishGuide(info)
            end

            if cc.rectContainsPoint(rect, touchPos) then
                return false
            end
            return true
        end,
        false,
        true
    )
end

-- 展示下一个
function NoviceGuideManager:NextShow()
    --  if NoviceGuideQueue == nil or #NoviceGuideQueue == 0  then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TRIGGER_NEXT)
    --  end

    if self.current_info then
        if not self:getIsFinish(self.current_info.id) then
            return
        end
    end

    local next = table.remove(NoviceGuideQueue, 1)
    self.current_info = next
    self:showNextTips(next)
end

-- 展示下一个可重复引导
function NoviceGuideManager:NextShowRepetition()
    if NoviceGuideRepetitionQueue == nil or #NoviceGuideRepetitionQueue == 0 then
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TRIGGER_NEXT)
        self.m_isRepetitionShow = true
    else
        self.m_isRepetitionShow = false
    end
    local next = table.remove(NoviceGuideRepetitionQueue, 1)
    -- self.current_info = next
    self:showNextTips(next)
end

--引导弹窗
function NoviceGuideManager:showNextTips(nextInfo)
    if not nextInfo then
        return
    end
    if nextInfo.id == NOVICEGUIDE_ORDER.goToFirstSlotGame.id then
        local firstGameID = globalData.slotRunData:getFirstGameID()
        gLobalViewManager:lobbyGotoGameScene(firstGameID)
    elseif nextInfo.id == NOVICEGUIDE_ORDER.initIcons.id then
        self.m_newbieMask = util_newMaskLayer()
        self.m_newbieMask:setOpacity(0)
        gLobalViewManager:getViewLayer():addChild(self.m_newbieMask, ViewZorder.ZORDER_GUIDE)
        local view = util_createView("views.newbieTask.WelcomeLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_GUIDE)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_Welcome)
        end
    elseif nextInfo.id == NOVICEGUIDE_ORDER.comeCust.id then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_CherryGuide)
        end

        -- 引导打点：进入关卡-1.遮罩显示
        gLobalSendDataManager:getLogGuide():setGuideParams(
            1,
            {
                isForce = NOVICEGUIDE_ORDER.comeCust.force,
                isRepeat = NOVICEGUIDE_ORDER.comeCust.repetition,
                guideId = NOVICEGUIDE_ORDER.comeCust.id
            }
        )
        gLobalSendDataManager:getLogGuide():sendGuideLog(1, 1)

        if self:isNewMaskUI() then
            self.m_newbieMask:removeFromParent()
            self.m_newbieMask = nil
        end
        -- globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.comeCust)
        self.m_newbieMask = util_newMaskLayer()
        gLobalViewManager:getViewLayer():addChild(self.m_newbieMask, ViewZorder.ZORDER_GUIDE - 1)
        local view = util_createView("views.newbieTask.FirstEnterLayer")
        gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_GUIDE + 1)
    elseif nextInfo.id == NOVICEGUIDE_ORDER.payTable.id then
        -- 提层级消息
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NOVICEGUIDE_SHOW,nextInfo)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_PayTableShow)
        end
        -- globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.payTable,"NoviceGuide/Paytable.csb")
        local pos = self:getWorldPos(nextInfo.id)
        local view = util_createView("views.newbieTask.GuidePaytableNode", nextInfo, pos)
        gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_GUIDE + 1)
    elseif nextInfo.id == NOVICEGUIDE_ORDER.noobTaskStart1.id then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_FirstSpinTip)
        end
        -- 引导打点：进入关卡-3.SPIN遮罩显示
        gLobalSendDataManager:getLogGuide():sendGuideLog(1, 3)
        -- 引导打点：新手任务-1.任务触发
        local sysNoviceTaskMgr = G_GetMgr(G_REF.SysNoviceTask)
        local _taskId
        if sysNoviceTaskMgr and sysNoviceTaskMgr:checkEnabled() then
            local data =  sysNoviceTaskMgr:getData()
            if data then
                _taskId = data:getTaskIdx()
            end
        else
            local taskData = globalNewbieTaskManager:getCurrentTaskData()
            if taskData then
                _taskId = taskData.p_id
            end
        end
        gLobalSendDataManager:getLogGuide():setGuideParams(
            2,
            {
                guideId = NOVICEGUIDE_ORDER.noobTaskStart1.id,
                isForce = NOVICEGUIDE_ORDER.noobTaskStart1.force,
                isRepeat = NOVICEGUIDE_ORDER.noobTaskStart1.repetition,
                -- taskId = taskData and taskData.p_id
                taskId = _taskId
            }
        )
        gLobalSendDataManager:getLogGuide():sendGuideLog(2, 1)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_NEWTASK_ZORDER)

        if self:isNewMaskUI() then
            self.m_newbieMask:removeFromParent()
            self.m_newbieMask = nil
        end
        self.m_newbieMask = util_newMaskLayer()
        gLobalViewManager:getViewLayer():addChild(self.m_newbieMask, ViewZorder.ZORDER_GUIDE - 1)
    elseif nextInfo.id == NOVICEGUIDE_ORDER.levelUp.id then
        -- elseif nextInfo.id == NOVICEGUIDE_ORDER.addBet.id  then
        -- if globalFireBaseManager.sendFireBaseLogDirect then
        --     globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_MAXBET)
        -- end
        -- -- local path = "NoviceGuide/AddBet.csb"
        -- local path = "NoviceGuide/NewBets.csb"
        -- if globalData.slotRunData.isPortrait == true then
        --     -- path = "NoviceGuide/AddBetPortrait.csb"
        --     -- path = "NoviceGuide/NewBetsPortrait.csb"
        --     path = "NoviceGuide/NewBetsPortrait.csb"
        -- end
        -- local bubble = self:createAndRemoveBubble(NOVICEGUIDE_ORDER.addBet,path,4)
        -- if bubble then
        --     local maxBetData = globalData.slotRunData:getMaxBetData()
        --     local  betValue = 0
        --     if maxBetData ~= nil then
        --         betValue = maxBetData.p_totalBetValue
        --     else
        --         betValue = globalData.slotRunData:getCurTotalBet()
        --     end
        --     -- bubble:findChild("bet"):setString(util_formatCoins(betValue,30).." Coins")
        -- end
        -- globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.addBet,path,true)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_Level2)
        end
        globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.levelUp, nil, true)
    elseif nextInfo.id == NOVICEGUIDE_ORDER.noobTaskFinish1.id then
        -- globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.noobTaskFinish1,nil,true)
        -- globalNoviceGuideManager:createAndRemoveBubble(NOVICEGUIDE_ORDER.noobTaskFinish1)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_FinishSpin10)
        end
    elseif nextInfo.id == NOVICEGUIDE_ORDER.noobTaskFinish2.id then
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_TIPS,{1,false})
        -- globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.noobTaskFinish2,nil,true)
        -- globalNoviceGuideManager:createAndRemoveBubble(NOVICEGUIDE_ORDER.noobTaskFinish2)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_Level5)
        end
    elseif nextInfo.id == NOVICEGUIDE_ORDER.noobTaskFinish3.id then
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_TIPS,{1,false})
        -- globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.noobTaskFinish3,nil,true)
        -- globalNoviceGuideManager:createAndRemoveBubble(NOVICEGUIDE_ORDER.noobTaskFinish3)
        -- elseif nextInfo.id == NOVICEGUIDE_ORDER.bingoFirstEnter_Lobby.id then
        --     if self:isNewMaskUI() then
        --         self.m_newbieMask:removeFromParent()
        --         self.m_newbieMask = nil
        --     end
        --     self.m_newbieMask = util_newMaskLayer()
        --     gLobalViewManager:getViewLayer():addChild(self.m_newbieMask,ViewZorder.ZORDER_GUIDE-1)
        --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BINGO_FIRST_ENTER_GUIDE_ZORDER,{tag = "show", id = nextInfo.id})
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_LevelUpTwice)
        end
    elseif nextInfo.id == NOVICEGUIDE_ORDER.bingoFirstEnter_Select.id then
        if self:isNewMaskUI() then
            self.m_newbieMask:removeFromParent()
            self.m_newbieMask = nil
        end
        -- self.m_newbieMask = util_newMaskLayer()
        -- gLobalViewManager:getViewLayer():addChild(self.m_newbieMask,ViewZorder.ZORDER_GUIDE-1)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BINGO_FIRST_ENTER_GUIDE_ZORDER, {tag = "show", id = nextInfo.id})
    elseif nextInfo.id == NOVICEGUIDE_ORDER.bingoFirstEnter_Game_Machine.id then
        if self:isNewMaskUI() then
            self.m_newbieMask:removeFromParent()
            self.m_newbieMask = nil
        end
        -- self.m_newbieMask = util_newMaskLayer()
        -- gLobalViewManager:getViewLayer():addChild(self.m_newbieMask,ViewZorder.ZORDER_GUIDE-1)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BINGO_FIRST_ENTER_GUIDE_ZORDER, {tag = "show", id = nextInfo.id})
    elseif nextInfo.id == NOVICEGUIDE_ORDER.bingoFirstEnter_Game_Rank.id then
        if self:isNewMaskUI() then
            self.m_newbieMask:removeFromParent()
            self.m_newbieMask = nil
        end
        -- local touch = ccui.Layout:create()
        -- touch:setTouchEnabled(true)
        -- touch:setSwallowTouches(false)
        -- touch:setAnchorPoint(0.5000, 0.5000)
        -- touch:setContentSize(cc.size(display.width, display.height))
        -- touch:setPosition(cc.p(display.width*0.5, display.height*0.5))
        -- touch:setClippingEnabled(false)
        -- touch:setBackGroundColor(cc.c4b(0, 0, 0 ))
        -- touch:setBackGroundColorOpacity( 70 )

        self.m_newbieMask = util_newMaskLayer(true)

        -- local isTouch = false
        -- performWithDelay(self.m_newbieMask,function()
        --     isTouch = true
        -- end, 0.5)
        -- self.m_newbieMask:onTouch(function(event)
        --     if not isTouch then
        --         return true
        --     end
        --     if event.name ~= "ended" then
        --         return true
        --     end
        --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BINGO_FIRST_ENTER_GUIDE_ZORDER,{tag = "hide", id = nextInfo.id})
        -- end)
        -- gLobalViewManager:getViewLayer():addChild(self.m_newbieMask,ViewZorder.ZORDER_GUIDE-1)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BINGO_FIRST_ENTER_GUIDE_ZORDER, {tag = "show", id = nextInfo.id})
    elseif nextInfo.id == NOVICEGUIDE_ORDER.bingoFirstEnter_Game_PayLine.id then
        if self:isNewMaskUI() then
            self.m_newbieMask:removeFromParent()
            self.m_newbieMask = nil
        end
        -- local touch = ccui.Layout:create()
        -- touch:setTouchEnabled(true)
        -- touch:setSwallowTouches(false)
        -- touch:setAnchorPoint(0.5000, 0.5000)
        -- touch:setContentSize(cc.size(display.width, display.height))
        -- touch:setPosition(cc.p(display.width*0.5, display.height*0.5))
        -- touch:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        -- touch:setBackGroundColor(cc.c4b(0, 0, 0 ))
        -- touch:setBackGroundColorOpacity(190)

        -- self.m_newbieMask = util_newMaskLayer(true)

        -- local isTouch = false
        -- performWithDelay(self.m_newbieMask,function()
        --     isTouch = true
        -- end, 0.5)
        -- self.m_newbieMask:onTouch(function(event)
        --     if not isTouch then
        --         return true
        --     end
        --     if event.name ~= "ended" then
        --         return true
        --     end
        --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BINGO_FIRST_ENTER_GUIDE_ZORDER,{tag = "hide", id = nextInfo.id})
        -- end)
        -- gLobalViewManager:getViewLayer():addChild(self.m_newbieMask,ViewZorder.ZORDER_GUIDE-1)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BINGO_FIRST_ENTER_GUIDE_ZORDER, {tag = "show", id = nextInfo.id})
    elseif nextInfo.id == NOVICEGUIDE_ORDER.dallyMissionReward.id then
        local path = "NoviceGuide/tishi_missionRewadPortrait.csb"
        globalNoviceGuideManager:createAndRemoveBubble(NOVICEGUIDE_ORDER.dallyMissionReward, path, 10)
    elseif nextInfo.id == NOVICEGUIDE_ORDER.dallyWhell.id then
        -- cxc 2021年06月25日15:00:47 没有开启新手期新功能 走以前的引导逻辑
        if not globalData.GameConfig:checkUseNewNoviceFeatures() then
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.CashBonusGuide)
            end
            if self:isNewMaskUI() then
                self.m_newbieMask:removeFromParent()
                self.m_newbieMask = nil
            end
            -- globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.comeCust)
            self.m_newbieMask = util_newMaskLayer()
            gLobalViewManager:getViewLayer():addChild(self.m_newbieMask, ViewZorder.ZORDER_GUIDE - 1)
            local view = util_createView("views.newbieTask.FirstWheelLayer")
            gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_GUIDE + 1)
            return
        end

        -- csc 2021年05月20日10:48:24
        if globalData.userRunData.levelNum >= 10 then
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.CashBonusGuide)
            end
            if self:isNewMaskUI() then
                self.m_newbieMask:removeFromParent()
                self.m_newbieMask = nil
            end
            -- globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.comeCust)
            self.m_newbieMask = util_newMaskLayer()
            -- cxc 2021年06月23日16:05:26 变为非强制引导
            local bTouch = true
            self.m_newbieMask:onTouch(
                function(event)
                    if not bTouch then
                        return
                    end
                    if event.name == "ended" then
                        bTouch = false
                        globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.dallyWhell)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_CASHWHEEL_ZORDER, false)
                    end
                    return true
                end,
                false,
                true
            )
            gLobalViewManager:getViewLayer():addChild(self.m_newbieMask, ViewZorder.ZORDER_GUIDE - 1)
            local view = util_createView("views.newbieTask.FirstWheelLayer")
            gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_GUIDE + 1)
        end
    elseif nextInfo.id == NOVICEGUIDE_ORDER.silverEntrepot.id then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.CashBonusGuideLobby)
        end
        globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.silverEntrepot)
    elseif nextInfo.id == NOVICEGUIDE_ORDER.silverFront.id then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.CashBonusInterface)
        end
        globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.silverFront)
    elseif nextInfo.id == NOVICEGUIDE_ORDER.silverBack.id then
        globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.silverBack)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.CashBonusInterfaceThreeHours)
        end
    elseif nextInfo.id == NOVICEGUIDE_ORDER.bonusTips.id then
        globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.bonusTips)
        if not globalLocalPushManager:isNotifyEnabled() then
            gLobalViewManager:showDialog(
                "Dialog/Opentongzhi.csb",
                function()
                    print("弹bonusTips通知")
                    globalPlatformManager:sendPlatformMsg(globalPlatformManager.OPEN_NOTIFY_ENABLED)
                end,
                function()
                    print("返回游戏")
                end,
                false,
                ViewZorder.ZORDER_GUIDE
            )
        end
    elseif nextInfo.id == NOVICEGUIDE_ORDER.shopTips.id then
        globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.shopTips)
        if not globalLocalPushManager:isNotifyEnabled() then
            gLobalViewManager:showDialog(
                "Dialog/Opentongzhi.csb",
                function()
                    print("弹shopTips通知")
                    globalPlatformManager:sendPlatformMsg(globalPlatformManager.OPEN_NOTIFY_ENABLED)
                end,
                function()
                    print("返回游戏")
                end,
                false,
                ViewZorder.ZORDER_GUIDE
            )
        end
    elseif nextInfo.id == NOVICEGUIDE_ORDER.shopReward2.id then
        -- 引导打点：免费领取商店金币-3.遮罩手指显示
        if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.shopReward2) then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(9) then
                gLobalSendDataManager:getLogGuide():sendGuideLog(9, 3)
            end
        end
        globalNoviceGuideManager:addMaskUI(NOVICEGUIDE_ORDER.shopReward2)
    else
        --没有在这里处理的发消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NOVICEGUIDE_SHOW, nextInfo)
    end
end

--根据id获取数据
function NoviceGuideManager:getInfo(id)
    for key, info in pairs(NOVICEGUIDE_ORDER) do
        if info.id == id then
            return info
        end
    end
end

-- 添加一个队列
function NoviceGuideManager:addQueue(checkInfo)
    if not checkInfo then
        return false
    end

    for i, v in ipairs(NoviceGuideQueue) do
        if v == checkInfo then
            return false
        end
    end

    if checkInfo.preId then
        if not self:getIsFinish(checkInfo.preId) then
            return false
        end
    end

    NoviceGuideQueue[#NoviceGuideQueue + 1] = checkInfo
    table.sort(
        NoviceGuideQueue,
        function(a, b)
            local aOrder = a.order or a.id
            local bOrder = b.order or b.id
            return aOrder < bOrder
        end
    )
    return true
end

-- 添加一个可重复引导队列
function NoviceGuideManager:addRepetitionQueue(checkInfo)
    if not checkInfo then
        return false
    end

    for i, v in ipairs(NoviceGuideRepetitionQueue) do
        if v == checkInfo then
            return false
        end
    end

    if checkInfo.preId then
        if self:isNoobUsera() and not self:getIsFinish(checkInfo.preId) then
            return false
        end
    end

    NoviceGuideRepetitionQueue[#NoviceGuideRepetitionQueue + 1] = checkInfo
    table.sort(
        NoviceGuideRepetitionQueue,
        function(a, b)
            local aOrder = a.order or a.id
            local bOrder = b.order or b.id
            return aOrder < bOrder
        end
    )
    return true
end

-- 删除一个队列
function NoviceGuideManager:removeQueue(guideType)
    --globalNoviceGuideManager:removeQueue(NOVICEGUIDE_ORDER.SHOP)
    for i, v in ipairs(NoviceGuideRepetitionQueue) do
        if v == guideType then
            table.remove(NoviceGuideRepetitionQueue, i)
            return
        end
    end
end

function NoviceGuideManager:addFinishList(info, success_callback, faild_callbackm, noNet)
    if info.repetition then
        return
    end
    for i, v in ipairs(globalData.NoviceGuideFinishList) do
        if v == info.id then
            return
        end
    end
    globalData.NoviceGuideFinishList[#globalData.NoviceGuideFinishList + 1] = info.id
    if self.current_info and self.current_info.id == info.id then
        self.current_info = nil
    end

    -- if success_callback then
    --     success_callback()
    -- end
    gLobalSendDataManager:getNetWorkFeature():sendNoviceGuideFinishListUpdate(globalData.NoviceGuideFinishList, success_callback, faild_callback)
end

function NoviceGuideManager:getIsFinish(id)
    -- (第2步引导 进入关卡 等级判断下2级, 临时写的 很老的号还没有同步是否引导过关卡的功能呢)
    if NOVICEGUIDE_ORDER.comeCust.id == id and globalData.userRunData.levelNum > 2 then
        return true
    end

    for i, v in ipairs(globalData.NoviceGuideFinishList) do
        if v == id then
            return true
        end
    end
    return false
end
--ignoreLevel是否忽略新手期
function NoviceGuideManager:isNoobUsera(ignoreLevel)
    --跳过新手引导
    if CC_SKIP_NOVICEGUIDE and DEBUG == 2 then
        return false
    end
    --已经过了新手期
    if not ignoreLevel and globalData.userRunData.levelNum > globalData.constantData.NEW_USER_GUIDE_LEVEL then
        return false
    end
    local firstGuideInfo = self:getFirstGuideInfo()
    if self:getIsFinish(firstGuideInfo.id) then
        --完成第一个新手引导
        return true
    elseif globalData.userRunData.levelNum == 1 then
        --新用户
        return true
    end
    return false
end

function NoviceGuideManager:setNewBieTeskReachLevelFlag(_flag)
    self.m_newbieTaskReachLevel = _flag
end

function NoviceGuideManager:getNewBieTeskReachLevelFlag()
    return self.m_newbieTaskReachLevel
end

-- 获取第一步引导id
function NoviceGuideManager:getFirstGuideInfo()
    if self.m_firstGuideInfo then
        return self.m_firstGuideInfo
    end

    self.m_firstGuideInfo = NOVICEGUIDE_ORDER.initIcons
    if globalData.constantData.NEW_SUER_FIRST_GUIDE_GO_SLOT_GAMME then
        -- 新版第一步引导直接进入关卡删除大厅引导关卡, 领完新手金币引导 执行 关卡新手任务引导
        self:addFinishList(NOVICEGUIDE_ORDER.comeCust)
        NOVICEGUIDE_ORDER.initIcons.nextId = NOVICEGUIDE_ORDER.noobTaskStart1.id
        self.m_firstGuideInfo = NOVICEGUIDE_ORDER.goToFirstSlotGame
    end

    return self.m_firstGuideInfo
end

return NoviceGuideManager
