---
--xcyy
--2018年5月23日
--DazzlingDiscoBonusView.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoBonusView = class("DazzlingDiscoBonusView",util_require("Levels.BaseLevelDialog"))

local MAX_SPOT_COUNT    =       60  --最大点位数量
local BTN_TAG_EXIT      =       1001    --退出按钮

DazzlingDiscoBonusView.m_endFunc = nil


local  STATUS_CHANG_HEAD = {
    ACC_SPEED = 1,  --  加速状态
    HIGH_SPEED = 2, -- 匀速状态
    DECELER_SPEED = 3,   --减速状态
    MIN_SPEED = 4   --最低速状态
}

local ACC_SPEED_COUNT = 5         --加速个数
local DECELER_SPEED_COUNT = 5      --减速个数
local HIGH_SPEED_COUNT = 7         --匀速个数
local MIN_SPEED_COUNT = 1           --最低速个数

function DazzlingDiscoBonusView:ctor()
    DazzlingDiscoBonusView.super.ctor(self)
    self.m_curDataIndex = 1

    self.m_winCoins = 0
    self.m_isExitWatching = false
    
end

function DazzlingDiscoBonusView:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("DazzlingDisco/GameScreenSocial.csb")

    self.m_playerItems = {}
    
    for index = 1,MAX_SPOT_COUNT do
        local item = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoSpotHeadItem",{index = index,parent = self})
        self:findChild("Node_"..index):addChild(item)
        self.m_playerItems[index] = item
        item:setVisible(false)
    end
    self.m_headNode = self:findChild("Node_rentouxiang")
    self.m_headNode:setVisible(false)

    --主持人
    self.m_hostMan = util_spineCreate("DazzlingDisco_bg",true,true)
    self:findChild("Node_juese"):addChild(self.m_hostMan)
    self.m_hostMan:setVisible(false)

    self:createSubTitleNode()

    --设置粒子是否显示
    self:setParticleVisible(false)

    --次数条
    self.m_spinBar = util_createAnimation("DazzlingDisco_spinsbar.csb")
    self:findChild("Node_spinsbar"):addChild(self.m_spinBar)

    self.m_spotBar = util_createAnimation("DazzlingDisco_spotbar.csb")
    self:findChild("Node_spotbar"):addChild(self.m_spotBar)

    self.m_miniMachine = util_createView("CodeDazzlingDiscoBonusGame.DazzlingDiscoMiniReelMachine",{machine = self.m_machine,parentView = self})
    self:findChild("Node_machine"):addChild(self.m_miniMachine)

    --选人界面
    self.m_select_player = util_createAnimation("DazzlingDisco_eveybodywin_xuanren.csb")
    self:findChild("Node_eveybodywin_xuanren"):addChild(self.m_select_player)
    self.m_select_player:setVisible(false)
    self.m_select_player:findChild("sp_nameBg"):setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_select_player,true)

    self.m_changeSceneAni = util_spineCreate("DazzlingDisco_bg",true,true)
    self:findChild("Node_changeSceneAni"):addChild(self.m_changeSceneAni)
    self.m_changeSceneAni:setVisible(false)

    --退出观看按钮
    self.m_btn_exit_watch = util_createAnimation("DazzlingDisco_social_watching.csb")
    self:findChild("Node_watching"):addChild(self.m_btn_exit_watch)
    self.m_btn_exit_watch:setVisible(false)
    local btn = self.m_btn_exit_watch:findChild("Button_1")
    btn:setTag(BTN_TAG_EXIT)
    self:addClick(btn)
end

--[[
    设置粒子可见性
]]
function DazzlingDiscoBonusView:setParticleVisible(isShow)
    for index = 1,2 do
        local particle = self:findChild("Particle_"..index)
        if particle then
            if isShow then
                particle:resetSystem()
            else
                particle:stopSystem()
            end
            -- particle:setVisible(isShow)
        end
    end
end

--[[
    创建字幕节点
]]
function DazzlingDiscoBonusView:createSubTitleNode()
    --字幕
    self.m_subLight = util_createAnimation("DazzlingDisco_zimu_glow.csb")
    local node = cc.Node:create()
    node:addChild(self.m_subLight)
    self:findChild("Node_zimu"):addChild(node)
    self.m_subNode = node

    self.m_subLight:runCsbAction("idle",true)
    self.m_subNode:setVisible(false)

    --升行扩列提示文字
    self.m_changeReelTip = util_createAnimation("DazzlingDisco_social_qipankuozhan_zimu.csb")
    self:findChild("Node_zimu"):addChild(self.m_changeReelTip)
    self.m_changeReelTip:setVisible(false)
end

--[[
    显示字幕
]]
function DazzlingDiscoBonusView:showSubTitleAni(subType,isShowLight,func,endFunc)
    local subTitle = util_createAnimation("DazzlingDisco_zimu.csb")
    if isShowLight then
        self.m_subNode:addChild(subTitle)
    else
        self:findChild("Node_zimu"):addChild(subTitle)
    end
    
    subTitle:findChild("getyougaoove"):setVisible(subType == "ready")
    subTitle:findChild("readytoboogie"):setVisible(subType == "ready1")
    subTitle:findChild("letgo"):setVisible(subType == "go")
    subTitle:findChild("everbodywin"):setVisible(subType == "allWins")
    subTitle:findChild("whowillbestar"):setVisible(subType == "leader")
    subTitle:findChild("herewild"):setVisible(subType == "wild")

    local idleName = "idle"
    if subType == "leader" then
        idleName = "idle2"
    end

    local params = {}
    params[#params + 1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = subTitle,   --执行动画节点  必传参数
        actionName = "start", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = subTitle,   --执行动画节点  必传参数
        actionName = idleName, --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            if type(func) == "function" then
                func()
            end
        end
    }
    params[#params + 1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = subTitle,   --执行动画节点  必传参数
        actionName = "over", --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            if type(endFunc) == "function" then
                endFunc()
            end
            subTitle:removeFromParent()
        end

    }
    util_runAnimations(params)
end

--[[
    开始下一次spin
]]
function DazzlingDiscoBonusView:runNextSpin()
    if not self.m_bonusData then
        return
    end
    local resultList = self.m_bonusData.spinResultList

    self.m_randSubList = {1,2,3,4}
    --玩法结束
    if self.m_curDataIndex > #resultList then
        self:gameOver()
        return
    end

    if self.m_curDataIndex == 1 then
        self:updateSpinBar(self.m_curDataIndex,#resultList)
        local curResultData = resultList[self.m_curDataIndex]
        self.m_curDataIndex = self.m_curDataIndex + 1

        self.m_miniMachine:parseResultData(curResultData)
        self.m_miniMachine:beginMiniReel()
    else
        --最小轮盘不播过场
        if self.m_miniMachine:checkIsMinReel() then
            self.m_miniMachine:resetView()
            self:updateSpinBar(self.m_curDataIndex,#resultList)
            local curResultData = resultList[self.m_curDataIndex]
            self.m_curDataIndex = self.m_curDataIndex + 1
    
            self.m_miniMachine:parseResultData(curResultData)
            self.m_miniMachine:beginMiniReel()
        else
            self:chageSceneAni(function(  )
                self.m_miniMachine:resetView()
                self:updateSpinBar(self.m_curDataIndex,#resultList)
            end,function(  )
                local curResultData = resultList[self.m_curDataIndex]
                self.m_curDataIndex = self.m_curDataIndex + 1
        
                self.m_miniMachine:parseResultData(curResultData)
                self.m_miniMachine:beginMiniReel()
            end)
        end
        
    end

    
    
end

--[[
    刷新当前spin次数
]]
function DazzlingDiscoBonusView:updateSpinBar(curCount,totalCount)
    self.m_spinBar:findChild("m_lb_num_1"):setString(curCount)
    self.m_spinBar:findChild("m_lb_num_2"):setString(totalCount)
end

--[[
    刷新spot数量
]]
function DazzlingDiscoBonusView:updateSpotCount()
    local collectList = self.m_bonusData.collects
    local count = 0
    if collectList then
        for i,data in ipairs(collectList) do
            if data.udid == globalData.userRunData.userUdid then
                count = count + 1
            end
        end
    end

    self.m_spotBar:findChild("m_lb_num"):setString(count)
end

--[[
    重置界面
]]
function DazzlingDiscoBonusView:resetView(data,func)
    self.m_endFunc = func
    self.m_bonusData = data

    self.m_winCoins = 0

    --自身点位数量
    self.m_spotCount = self:getSelfSpotCount()

    --当前数据索引
    self.m_curDataIndex = 1
    self.m_isExitWatching = false

    self.m_miniMachine:resetView()
    self:updateSpotCount()
    self.m_miniMachine:setVisible(false)
    self.m_spinBar:setVisible(false)
    self.m_btn_exit_watch:setVisible(false)
    self.m_spotBar:setVisible(false)
    self.m_hostMan:setVisible(false)
    self:setParticleVisible(false)

    local resultList = self.m_bonusData.spinResultList
    if resultList then
        self:updateSpinBar(self.m_curDataIndex,#resultList)
    end

    --刷新头像
    self:refreshPlayerHeads()
end

--[[
    刷新所有玩家头像
]]
function DazzlingDiscoBonusView:refreshPlayerHeads()
    self.m_headNode:setVisible(false)
    local collectList = self.m_bonusData.collects
    for index = 1,MAX_SPOT_COUNT do
        local collectData = collectList[index]
        local item = self.m_playerItems[index]
        item:updateHead(collectData)
        item:setVisible(false)
    end
end

--[[
    显示所有玩家头像(随机显示)
]]
function DazzlingDiscoBonusView:showAllPlayerAni(func)
    --主持人入场
    self.m_hostMan:setVisible(true)
    util_spinePlay(self.m_hostMan,"start")
    util_spineEndCallFunc(self.m_hostMan,"start",function()
        util_spinePlay(self.m_hostMan,"idle3",true)
    end)

    self.m_headNode:setVisible(true)
    local randList = {}
    for index = 1,MAX_SPOT_COUNT do
        randList[index] = index
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_all_player)

    self:showNextPlayer(randList,func)
end

--[[
    显示下一个玩家头像
]]
function DazzlingDiscoBonusView:showNextPlayer(list,func)
    if #list == 0 then
        if type(func) == "function" then
            func()
        end
        
        return 
    end

    for index = 1,2 do
        local randIndex = math.random(1,#list)
        local headIndex = list[randIndex]
        table.remove(list,randIndex)
        local headItem = self.m_playerItems[headIndex]
        headItem:setVisible(true)
        headItem:runShowAni()
    end
    
    self.m_machine:delayCallBack(5 / 60,function(  )
        self:showNextPlayer(list,func)
    end)

end

--[[
    显示界面
]]
function DazzlingDiscoBonusView:showView(data,func)
    
    self:setVisible(true)
    
    --显示所有玩家头像
    self:showAllPlayerAni(function(  )
        util_spinePlay(self.m_hostMan,"idle4")
        util_spineEndCallFunc(self.m_hostMan,"idle4",function()
            util_spinePlay(self.m_hostMan,"idle3",true)
            --预备开始字幕
            self:showStartSub(function(  )
                
                self:chageSceneAni(function(  )
                    self.m_headNode:setVisible(false)
                    self.m_miniMachine:setVisible(true)
                    self.m_spinBar:setVisible(true)
                    self.m_btn_exit_watch:setVisible(self.m_spotCount == 0)
                    self.m_spotBar:setVisible(true)
                    self:setParticleVisible(false)
                    self.m_miniMachine:showAni()
                end,function(  )
                    --开始spin
                    self:runNextSpin()
                end)
            end)
        end)
    end)
end

--[[
    音浪动画
]]
function DazzlingDiscoBonusView:runSoundbyteAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_sound_byte_ani)
    local spine = util_spineCreate("DazzlingDisco_bg",true,true)
    self:findChild("Node_juese"):addChild(spine)
    util_spinePlay(spine,"actionframe")
    util_spineEndCallFunc(spine,"actionframe",function(  )
        spine:setVisible(false)
        self.m_machine:delayCallBack(0.1,function(  )
            spine:removeFromParent()
        end)

        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示开始字幕
]]
function DazzlingDiscoBonusView:showStartSub(func)
    self.m_subNode:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_sub_ready1)
    self:showSubTitleAni("ready1",true,function(  )

        util_spinePlay(self.m_hostMan,"idle2",true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_sub_ready)
        self:showSubTitleAni("ready",true,function(  )
            --全屏音浪
            self:runSoundbyteAni()
            self:setParticleVisible(true)
            --修改背景动画
            self.m_machine:changeBgAni("bonus2")

            util_spinePlay(self.m_hostMan,"idle1",true)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_sub_go)
            self:showSubTitleAni("go",true,nil,function(  )
                self.m_subNode:setVisible(false)
                --角色移出屏幕
                util_spinePlay(self.m_hostMan,"over")
                util_spineEndCallFunc(self.m_hostMan,"over",function(  )
                    self.m_hostMan:setVisible(false)
                end)

                if type(func) == "function" then
                    func()
                end
            end)
        end)
    end)
end

--[[
    隐藏界面
]]
function DazzlingDiscoBonusView:hideView(func)
    self:setVisible(false)
end

--[[
    显示随机头像
]]
function DazzlingDiscoBonusView:showRandomHead(randomPos,func)
    if self.m_isExitWatching then
        return
    end
    local collectData = self.m_bonusData.collects
    self.m_select_player:setVisible(true)
    self.m_select_player:findChild("sp_nameBg"):setVisible(false)
    local headNode = self.m_select_player:findChild("sp_head")
    headNode:removeAllChildren()
    util_csbPauseForIndex(self.m_select_player.m_csbAct,0)

    self.m_changeHeadStatus = STATUS_CHANG_HEAD.ACC_SPEED
    self.m_curChangeTime = 1
    self.m_changeHeadCount = ACC_SPEED_COUNT

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_sub_who_is_leader)
    self:showSubTitleAni("leader",false,nil,function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_the_lead_dancer_is)
        self.m_select_player:runCsbAction("idle2")
        self.m_select_player:findChild("sp_who"):setVisible(true)
        self.m_machine:delayCallBack(1.5,function()
            self.m_select_player:findChild("sp_who"):setVisible(false)
            self.m_select_player:runCsbAction("idle",true)
            self:showNextHead(collectData,1,randomPos,function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_leader)
                self:setParticleVisible(true)
                self.m_select_player:findChild("sp_nameBg"):setVisible(true)
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_lock_leader)
                self.m_select_player:runCsbAction("suoding",false,function(  )
                    self.m_select_player:runCsbAction("idle4")
                    self.m_machine:delayCallBack(3,function()
                        self:setParticleVisible(false)
                        self.m_select_player:setVisible(false)
                        if type(func) == "function" then
                            func()
                        end
                    end)
                    
                end)
            end)
        end)
        
    end)
    
end

--[[
    显示下一个头像
]]
function DazzlingDiscoBonusView:showNextHead(collectData,index,randomPos,func)
    if self.m_isExitWatching then
        return
    end

    local randIndex = math.random(1,#collectData)
    local randData = collectData[randIndex]

    self.m_select_player:findChild("sp_nameBg"):setVisible(false)

    if self.m_changeHeadStatus == STATUS_CHANG_HEAD.MIN_SPEED and self.m_changeHeadCount <= 0  then
        randData = collectData[randomPos + 1]
        
    end

    local headNode = self.m_select_player:findChild("sp_head")
    self:updateHead(headNode,randData)

    local txt_name = self.m_select_player:findChild("txt_name")
    txt_name:setString(randData.nickName or "")
    txt_name:stopAllActions()
    
    local clipNode = txt_name:getParent()
    local clipSize = clipNode:getContentSize()
    txt_name:setAnchorPoint(cc.p(0.5,0.5))
    txt_name:setPosition(cc.p(clipSize.width / 2,clipSize.height / 2))

    util_wordSwing(txt_name, 1, clipNode, 2, 30, 2)


    -- util_nodeFadeIn(headNode, self.m_curChangeTime, 0, 255, nil, function()
        
    -- end)

    self.m_machine:delayCallBack(self.m_curChangeTime,function()
        self.m_changeHeadCount  = self.m_changeHeadCount - 1
        if self.m_changeHeadStatus == STATUS_CHANG_HEAD.ACC_SPEED then
            if self.m_curChangeTime == 1 then
                self.m_curChangeTime = 0.5
            else
                self.m_curChangeTime  = self.m_curChangeTime - 0.1
            end

            if self.m_curChangeTime <= 0.2 then
                self.m_curChangeTime = 0.2
            end
            if self.m_changeHeadCount <= 0 then
                self.m_changeHeadStatus = STATUS_CHANG_HEAD.HIGH_SPEED
                self.m_changeHeadCount = HIGH_SPEED_COUNT
            end
        elseif self.m_changeHeadStatus == STATUS_CHANG_HEAD.HIGH_SPEED then
            self.m_curChangeTime = 0.1
            if self.m_changeHeadCount <= 0 then
                self.m_changeHeadStatus = STATUS_CHANG_HEAD.DECELER_SPEED
                self.m_changeHeadCount = DECELER_SPEED_COUNT
            end
        elseif self.m_changeHeadStatus == STATUS_CHANG_HEAD.DECELER_SPEED then
            self.m_curChangeTime  = self.m_curChangeTime + 0.2
            if self.m_curChangeTime >= 1 then
                self.m_curChangeTime = 1
            end
            if self.m_changeHeadCount <= 0 then
                self.m_changeHeadStatus = STATUS_CHANG_HEAD.MIN_SPEED
                self.m_changeHeadCount = MIN_SPEED_COUNT
            end
        elseif self.m_changeHeadStatus == STATUS_CHANG_HEAD.MIN_SPEED then
            self.m_curChangeTime = 1
            if self.m_changeHeadCount < 0 then
                if type(func) == "function" then
                    func()
                end
                return
            end
        end 
        self:showNextHead(collectData,index + 1,randomPos,func)
    end)
end

--[[
    刷新选人头像
]]
function DazzlingDiscoBonusView:updateHead(headNode,headData)
    if not headNode then
        return
    end
    headNode:removeAllChildren(true)
    local isMe = (globalData.userRunData.userUdid == headData.udid)

    local frameId = isMe and globalData.userRunData.avatarFrameId or headData.frame
    local headId = isMe and globalData.userRunData.HeadName or headData.head
    local headSize = headNode:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.Avatar):createAvatarOutClipNode(headData.facebookId,headId,nil,true,headSize)
    headNode:addChild(nodeAvatar)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
end

--[[
    显示选中玩家赢钱
]]
function DazzlingDiscoBonusView:showLeaderWins(winCoins,totalWins,userPos,func)
    if self.m_isExitWatching then
        return
    end
    local view = util_createAnimation("DazzlingDisco_eveybodywin_jiangjin.csb")
    self:findChild("Node_eveybodywin_jiangjin"):addChild(view)

    local collectData = self.m_bonusData.collects
    local headData = collectData[userPos + 1]

    self:updateHead(view:findChild("sp_head"),headData)

    local txt_name = view:findChild("txt_name")
    txt_name:setString(headData.nickName or "")
    txt_name:stopAllActions()
    
    local clipNode = txt_name:getParent()
    local clipSize = clipNode:getContentSize()
    txt_name:setAnchorPoint(cc.p(0.5,0.5))
    txt_name:setPosition(cc.p(clipSize.width / 2,clipSize.height / 2))

    util_wordSwing(txt_name, 1, clipNode, 2, 30, 2)

    util_setCascadeOpacityEnabledRescursion(view,true)

    -- view:findChild("m_lbl_coins"):setString(util_formatCoins(winCoins, 50))
    -- local info1={label=view:findChild("m_lbl_coins"),sx=1,sy=1}
    -- self:updateLabelSize(info1,612)

    view:findChild("m_lbl_coins_all"):setString("X"..util_formatCoins(totalWins * 100, 50))
    local info2={label=view:findChild("m_lbl_coins_all"),sx=1,sy=1}
    self:updateLabelSize(info2,612)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_leader_wins)
    view:runCsbAction("start",false,function(  )
    end)

    self:jumpCoins({
        label = view:findChild("m_lbl_coins"),
        startCoins = winCoins / 100,
        endCoins = winCoins,
        maxWidth = 612,
        endFunc = function()
            if self.m_isExitWatching then
                return
            end
            
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_collect_leader_wins)
            local selfWins = self.m_miniMachine:getSelfWinCoins(globalData.userRunData.userUdid)
            if selfWins and selfWins > 0 then
                --刷新赢钱
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                    self.m_winCoins + selfWins, false, true,self.m_winCoins
                })
                self.m_winCoins = self.m_winCoins + selfWins
                self.m_machine:playCoinWinEffectUI()
            end

            self:setParticleVisible(true)
            view:runCsbAction("actionframe",false,function(  )
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_all_players_wins)
                view:runCsbAction("switch",false,function(  )
                    self.m_machine:delayCallBack(2,function()
                        view:removeFromParent()
                        self:setParticleVisible(false)
                        if type(func) == "function" then
                            func()
                        end
                    end)
                end)
            end)
        end
    })
end

--[[
    金币跳动
]]
function DazzlingDiscoBonusView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound = PublicConfig.SoundConfig.sound_DazzlingDisco_jump_leader_wins
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_DazzlingDisco_jump_leader_wins_end

    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (90  * duration)

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0
    label:stopAllActions()

    local jumpSoundID
    if jumpSound then
        jumpSoundID = gLobalSoundManager:playSound(jumpSound,true)
    end
    
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then
            label:stopAllActions()
            label:setString(util_formatCoins(endCoins,50))
            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)

            if jumpSoundID then
                gLobalSoundManager:stopAudio(jumpSoundID)
                --跳动结束音效
                if jumpSoundEnd then
                    gLobalSoundManager:playSound(jumpSoundEnd)
                end
                jumpSoundID = nil
            end

            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoins(curCoins,50))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    根据索引获取对应玩家数据
]]
function DazzlingDiscoBonusView:getHeadDataByPosIndex(userPos)
    if not self.m_bonusData then
        return
    end
    local collectData = self.m_bonusData.collects

    local headData = collectData[userPos + 1]
    return headData
end

--[[
    获取自身获得的spot数量
]]
function DazzlingDiscoBonusView:getSelfSpotCount()
    if not self.m_bonusData then
        return 0
    end
    local collectList = self.m_bonusData.collects 
    local count = 0
    for i,data in ipairs(collectList) do
        if data.udid == globalData.userRunData.userUdid then
            count = count + 1
        end
    end

    return count
end

--[[
    游戏结束
]]
function DazzlingDiscoBonusView:gameOver()

    --显示压黑层
    self.m_miniMachine:showBlackLayer()
    local winCoins = self:getSelfWinCoins()
    --刷新赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
        winCoins, false, true,self.m_winCoins
    })
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_bonus_completed)
    local ani = util_createAnimation("DazzlingDisco_zimu_1.csb")
    self:findChild("Node_zimu"):addChild(ani)
    ani:runCsbAction("auto",false,function(  )
        self.m_miniMachine:setVisible(false)
        self.m_spinBar:setVisible(false)
        self.m_spotBar:setVisible(false)
        self.m_btn_exit_watch:setVisible(false)
        self:setParticleVisible(true)

        --没有获取点位不弹结算弹板
        if self.m_spotCount > 0 then
            self.m_machine:showRankListView(self.m_bonusData.rank,self.m_bonusData.collects,function(  )
                self.m_machine:showBonusOverView(winCoins,function()
                    if type(self.m_endFunc) == "function" then
                        self.m_endFunc()
                        self.m_endFunc = nil
                    end
                end)
            end)
        else
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
                self.m_endFunc = nil
            end
        end
    end)
end

--[[
    获取自身赢钱
]]
function DazzlingDiscoBonusView:getSelfWinCoins()
    local rankList = self.m_bonusData.rank
    for i,data in ipairs(rankList) do
        if data.udid == globalData.userRunData.userUdid then
            return data.coins
        end
    end

    return self.m_winCoins
end

--[[
    super reel 提示
]]
function DazzlingDiscoBonusView:showSuperReelTip(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_super_spin)
    local tip = util_createAnimation("DazzlingDisco_social_qipankuozhan_zimu_0.csb")
    self:findChild("Node_zimu"):addChild(tip)
    tip:runCsbAction("auto",false,function(  )
        self.m_machine:delayCallBack(0.5,function()
            if type(func) == "function" then
                func()
            end
        end)
        
        tip:removeFromParent()
    end)
end

--[[
    显示自身赢钱字幕
]]
function DazzlingDiscoBonusView:showSelfWinCoins(winCoins,isBigWin,func)
    if self.m_isExitWatching then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_self_line_wins)
    local tip
    if isBigWin then
        tip = util_createAnimation("DazzlingDisco_zimu_2.csb")
    else
        tip = util_createAnimation("DazzlingDisco_zimu_0.csb")
    end
    self:findChild("Node_zimu"):addChild(tip)
    tip:findChild("m_lb_coins"):setString("+"..util_formatCoins(winCoins,4))
    tip:runCsbAction("actionframe",false,function(  )
        if type(func) == "function" then
            func()
        end
        tip:removeFromParent()
    end)
    --刷新赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
        self.m_winCoins + winCoins, false, true,self.m_winCoins
    })
    self.m_winCoins = self.m_winCoins + winCoins
    self.m_machine:playCoinWinEffectUI()
end

--[[
    hugeWin
]]
function DazzlingDiscoBonusView:showHugeWin(func)
    if self.m_isExitWatching then
        return
    end
    local tip = util_createAnimation("DazzlingDisco_zimu_hugewin.csb")
    self:findChild("Node_zimu"):addChild(tip)
    tip:runCsbAction("actionframe",false,function(  )
        if type(func) == "function" then
            func()
        end
        tip:removeFromParent()
    end)
end
--[[
    升行扩列提示
    direction 1 横向 2 纵向
    isMax 是否变为最大
]]
function DazzlingDiscoBonusView:showReelChangeTip(direction,isMax,func)
    self.m_changeReelTip:setVisible(true)
    local randIndex = math.random(1,4)
    local subIndex = randIndex
    if self.m_randSubList and #self.m_randSubList > 0 then
        randIndex = math.random(1,#self.m_randSubList)
        subIndex = self.m_randSubList[randIndex]
        table.remove(self.m_randSubList,randIndex)
    end

    if isMax then
        self.m_changeReelTip:findChild("Node_Amazing"):setVisible(false)
        self.m_changeReelTip:findChild("Node_wow"):setVisible(false)
        self.m_changeReelTip:findChild("Node_omg"):setVisible(false)
        self.m_changeReelTip:findChild("Node_farout"):setVisible(false)
        self.m_changeReelTip:findChild("Node_YESSS"):setVisible(false)
        self.m_changeReelTip:findChild("Node_maxsize"):setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_DazzlingDisco_show_extra_reel_tip_6"])
    else
        self.m_changeReelTip:findChild("Node_Amazing"):setVisible(subIndex == 1)
        self.m_changeReelTip:findChild("Node_wow"):setVisible(subIndex == 2)
        self.m_changeReelTip:findChild("Node_omg"):setVisible(subIndex == 3)
        self.m_changeReelTip:findChild("Node_farout"):setVisible(subIndex == 4)
        self.m_changeReelTip:findChild("Node_YESSS"):setVisible(subIndex == 5)
        self.m_changeReelTip:findChild("Node_maxsize"):setVisible(false)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_DazzlingDisco_show_extra_reel_tip_"..subIndex])
    end
    self.m_changeReelTip:findChild("zuoyou"):setVisible(direction == 1)
    self.m_changeReelTip:findChild("shangxia"):setVisible(direction == 2)

    self.m_changeReelTip:runCsbAction("auto",false,function(  )
        self.m_changeReelTip:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

end

--[[
    重置界面过场
]]
function DazzlingDiscoBonusView:chageSceneAni(func,endFunc)
    self.m_changeSceneAni:setVisible(true)
    util_spinePlay(self.m_changeSceneAni,"switch")
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_change_scene_for_reset_reel)
    self.m_machine:delayCallBack(1,function(  )
        if type(func) == "function" then
            func()
        end
    end)

    self.m_machine:delayCallBack(1.5,function(  )
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

--默认按钮监听回调
function DazzlingDiscoBonusView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if tag == BTN_TAG_EXIT then
        self.m_isExitWatching = true
        self.m_miniMachine.m_scheduleNode:unscheduleUpdate()
        self.m_miniMachine:stopReelSchedule()
        self.m_miniMachine:resetView()
        self.m_miniMachine:clearAllLineSymbols()
        
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
            self.m_endFunc = nil
        end
    end
end

return DazzlingDiscoBonusView