---
--xcyy
--2018年5月23日
--TakeOrStakeBonusGame.lua

local SendDataManager = require "network.SendDataManager"
local BaseRoomData = require "data.slotsdata.BaseRoomData"
local BaseView = require "base.BaseView"
local TakeOrStakeBonusGame = class("TakeOrStakeBonusGame",BaseView)

local HEART_BEAT_TIME = 10 --心跳间隔

local FRONT_OEDER = 100
local MID_ORDER = 50
local BEHIND_ORDER = 10

local ACTION_OVER = 3       --玩法结束

-- 这三个时间用来 判断房间有多人 有人加速 有人不加速的时候 保证只有在正确的倒计时时间内 玩家才可以点击操作
-- 不然的话 加速玩家的流程 会比不加速玩家 快 导致出错
local PICK_FIRST_LEFTTIME = 5 --第一次pick箱子的倒计时
local PICK_LEFTTIME = 11 --其他pick箱子的倒计时
local TAKE_LEFTTIME = 8 --take 的倒计时

function TakeOrStakeBonusGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("TakeOrStake/GameScreenTakeOrStake_Shejiao.csb")

    self:runCsbAction("idle",true)

    self.m_isCanClick = false -- 控制是否可以点击
    self.m_isCanUpdataTime = false -- 是否可以刷新倒计时
    self.m_playTriSelectBoxEffect = false -- 正在播放触发玩家选择箱子之后 的动画 暂时不刷新
    self.m_playOpenBoxAndTakeEffect = false --正在播放pick 选完箱子 之后 ；打开箱子以及take stake 等相关动画
    self.m_isHaveEnd = false --表示是否已经走到结算流程 用来判断取消加速的时候底层会再次调用 刷新房间消息 防止多次走结算流程
    self.m_clickTake = false --玩家点击take按钮 赢钱板子需要播放2秒的动画，为了保证动画播完 后续流程可以延时2秒
    self.m_clickTakeOverBtn = false --记录玩家 是否点击了 takeover弹板上的按钮
    self.m_pickEffectStop = false --记录每次的动画是否走完 主要用来 解决玩家加速 导致不加速的玩家 不同步问题
    self.m_curPlayerEventList = {} --存储玩家没有播放的事件

    -- 显示左右的倍数
    self.m_chengBeiZuo = util_createAnimation("TakeOrStake_chengbeilanzuo.csb")
    self:findChild("chengbeizuo"):addChild(self.m_chengBeiZuo)

    self.m_chengBeiYou = util_createAnimation("TakeOrStake_chengbeilanyou.csb")
    self:findChild("chengbeiyou"):addChild(self.m_chengBeiYou)

    self.m_chengBeiList = {} --存24个成倍
    for _index = 1, 12 do
        local chengBeiNode = util_createAnimation("TakeOrStake_chengbei.csb")
        self.m_chengBeiZuo:findChild("chengbei_"..(_index-1)):addChild(chengBeiNode)
        self.m_chengBeiList[_index] = chengBeiNode
    end

    for _index = 1, 12 do
        local chengBeiNode = util_createAnimation("TakeOrStake_chengbei.csb")
        self.m_chengBeiYou:findChild("chengbei_"..(_index-1)):addChild(chengBeiNode)
        self.m_chengBeiList[_index+12] = chengBeiNode
    end

    -- 中间的台子
    self.m_chengBeiTaiZi = util_createAnimation("TakeOrStake_taizi.csb")
    self:findChild("Node_taizi"):addChild(self.m_chengBeiTaiZi)

    -- 创建24个箱子
    self:createClickBox()

    -- 选中的展示 台子
    self.m_chengBeiSelectTaiZi = util_createAnimation("TakeOrStake_xiaotaizi.csb")
    self:findChild("Node_xiaotaizi"):addChild(self.m_chengBeiSelectTaiZi)

    -- 触发玩家 选中的箱子
    self.m_triPalyerBox = util_spineCreate("TakeOrStake_baoxiang",true,true)
    self.m_chengBeiSelectTaiZi:findChild("baoxiang"):addChild(self.m_triPalyerBox)
    self.m_triPalyerBox:setVisible(false)
    local boxMultiple = util_createAnimation("TakeOrStake_baoxiang_1.csb")
    self.m_triPalyerBox:addChild(boxMultiple)
    self.m_triPalyerBox.boxMultiple = boxMultiple

    -- 下方玩家头像
    self:initPlayerItem()

    -- 黑色界面 压暗
    self.m_darkUI = util_createAnimation("TakeOrStake_dark.csb")
    self:findChild("Node_dark"):addChild(self.m_darkUI)
    self.m_darkUI:setVisible(false)

    -- 引导弹板
    self.m_yinDaoTanBan = util_createAnimation("TakeOrStake_Bonus_TipsTanban.csb")
    self:findChild("Node_tanban"):addChild(self.m_yinDaoTanBan)
    self.m_yinDaoTanBan:setVisible(false)

    self.m_yinDaoTanBanFrame = util_createAnimation("TakeOrStake_touxiangkuang_moren.csb")
    self.m_yinDaoTanBan:findChild("Node_touxiang"):addChild(self.m_yinDaoTanBanFrame)

    self:addClick(self.m_yinDaoTanBan:findChild("Button_ShowMe"))
    self:addClick(self.m_yinDaoTanBan:findChild("Button_BackSpin"))

    -- 角色
    self.m_jiaoSe = util_spineCreate("Socre_TakeOrStake_juese",true,true)
    self.m_yinDaoTanBan:findChild("juese"):addChild(self.m_jiaoSe)
    self.m_jiaoSe:setVisible(false)

    -- 触发玩家 额外显示的弹板
    self.m_triPlayerShowUI = util_createAnimation("TakeOrStake_PlayerPickerTips.csb")
    self:findChild("Node_tanban"):addChild(self.m_triPlayerShowUI)
    self.m_triPlayerShowUI:setVisible(false)

    -- 倒计时 弹板
    self.m_selectBoxTimeUI = util_createAnimation("TakeOrStake_pickingbanzi.csb")
    self:findChild("Node_pickingbanzi"):addChild(self.m_selectBoxTimeUI)
    self.m_selectBoxTimeUI:setVisible(false)

    self.m_selectBoxTimeUIFrame = util_createAnimation("TakeOrStake_touxiangkuang_moren.csb")
    self.m_selectBoxTimeUI:findChild("Node_touxiang"):addChild(self.m_selectBoxTimeUIFrame)

    -- 开始 pick 的弹板
    self.m_pickTanBan = util_createAnimation("TakeOrStake_touxiang1.csb")
    self:findChild("Node_touxiang1"):addChild(self.m_pickTanBan)
    self.m_pickTanBan:setVisible(false)
    self.m_pickTanBanGuang = util_createAnimation("TakeOrStake_touxiang1_guang.csb")
    self.m_pickTanBan:findChild("Node_guang"):addChild(self.m_pickTanBanGuang)

    self.m_pickTanBanFrame = util_createAnimation("TakeOrStake_touxiangkuang_moren.csb")
    self.m_pickTanBan:findChild("Node_touxiang"):addChild(self.m_pickTanBanFrame)

    -- take leave 阶段展示的台子
    self.m_takeJinBiTaiZi = util_createAnimation("TakeOrStake_jinbitaizi.csb")
    self:findChild("Node_jinbitaizi"):addChild(self.m_takeJinBiTaiZi)
    self.m_takeJinBiTaiZi:setVisible(false)

    self.m_jiaoSeJieSuan = util_spineCreate("Socre_TakeOrStake_juese",true,true)
    self.m_takeJinBiTaiZi:findChild("jueseguang"):addChild(self.m_jiaoSeJieSuan)
    self.m_jiaoSeJieSuan:setVisible(false)

    -- 历史记录
    self.m_liShiJiLuBanZi = util_createAnimation("TakeOrStake_previousbanzi.csb")
    self:findChild("Node_previousbanzi"):addChild(self.m_liShiJiLuBanZi)
    self.m_liShiJiLuBanZi:setVisible(false)

    self.m_takeYingQianBanZi = util_createAnimation("TakeOrStake_yingqianbanzi.csb")
    self.m_takeJinBiTaiZi:findChild("yingqianbanzi"):addChild(self.m_takeYingQianBanZi)
    self.m_takeYingQianBanZi:setVisible(false)

    self.m_takeBtn = util_createAnimation("TakeOrStake_TakeItBtn.csb")
    self.m_takeJinBiTaiZi:findChild("Node_TakeItBtn"):addChild(self.m_takeBtn)
    self.m_takeBtn:setVisible(false)

    self.m_leaveBtn = util_createAnimation("TakeOrStake_LeaveItBtn.csb")
    self.m_takeJinBiTaiZi:findChild("Node_TLeaveItBtn"):addChild(self.m_leaveBtn)
    self.m_leaveBtn:setVisible(false)

    self:addClick(self.m_takeBtn:findChild("Button_1"))
    self:addClick(self.m_leaveBtn:findChild("Button_2"))

    -- 结算弹板 显示的头像
    self.m_jieSuanTanBan = util_createAnimation("TakeOrStake_touxiang2.csb")
    self:findChild("Node_touxiang2"):addChild(self.m_jieSuanTanBan)
    self.m_jieSuanTanBan:setVisible(false)

    -- 结算弹板 
    self.m_sheJiaoOver = util_createAnimation("TakeOrStake/BnousOverRank.csb")
    self:findChild("Node_BnousOverRank"):addChild(self.m_sheJiaoOver)
    self.m_sheJiaoOver:setVisible(false)

    self:addClick(self.m_sheJiaoOver:findChild("Button_Collect"))
    self.m_sheJiaoOver:findChild("Button_Collect"):setTouchEnabled(false)

    -- 结算角色
    self.m_jiaoSeOver = util_spineCreate("Socre_TakeOrStake_juese",true,true)
    self.m_sheJiaoOver:findChild("juese"):addChild(self.m_jiaoSeOver)
    self.m_jiaoSeOver:setVisible(false)

    -- 点击take 之后 结算弹板
    self.m_clickTakeOverView = util_createAnimation("TakeOrStake/BnousOverTake.csb")
    self:findChild("Node_overTake"):addChild(self.m_clickTakeOverView)
    self.m_clickTakeOverView:setPosition(cc.p(-display.width / 2, -display.height / 2))
    self.m_clickTakeOverView:setVisible(false)
    self:addClick(self.m_clickTakeOverView:findChild("Btn_collect"))
    self.m_clickTakeOverView:findChild("Btn_collect"):setTouchEnabled(false)

    -- 玩家选择 留下观看的话 显示 back to spin 按钮
    self.m_backToSpinBtn = util_createAnimation("TakeOrStake_Bonus_BtnBackToSpin.csb")
    self:findChild("Node_BackToSpinBtn"):addChild(self.m_backToSpinBtn)
    self.m_backToSpinBtn:setVisible(false)
    self:addClick(self.m_backToSpinBtn:findChild("backToSpinBtn"))

    util_setCascadeOpacityEnabledRescursion(self:findChild("shejiaoplayer"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("shejiaoplayer"), true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_xiaotaizi"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_xiaotaizi"), true)

    self:createGameOverNode()
end

--[[
    创建24个箱子
]]
function TakeOrStakeBonusGame:createClickBox( )
    self.m_boxList = {} --存24个箱子
    self.m_boxPicList = {} --存24个箱子的图片
    for _index = 1, 24 do
        local boxPic = util_createAnimation("TakeOrStake_xiang.csb")
        self.m_chengBeiTaiZi:findChild("baoxiang_".._index):addChild(boxPic)
        for _num = 1, 24 do
            boxPic:findChild(tostring(_num)):setVisible(false)
        end
        boxPic:findChild(tostring(_index)):setVisible(true)
        self.m_boxPicList[_index] = boxPic
        self.m_boxPicList[_index]:setVisible(false)

        local box = util_spineCreate("TakeOrStake_baoxiang",true,true)
        self.m_chengBeiTaiZi:findChild("baoxiang_".._index):addChild(box)
        box:setSkin(_index)
        self.m_boxList[_index] = box
        self.m_boxList[_index].isClick = true -- 是否可点击
        self.m_boxList[_index].isShow = true -- 是否显示
        self.m_boxList[_index].isOpen = false -- 是否打开
        self.m_boxList[_index]:setVisible(false)

        util_setCascadeOpacityEnabledRescursion(self.m_chengBeiTaiZi:findChild("baoxiang_".._index), true)
        util_setCascadeColorEnabledRescursion(self.m_chengBeiTaiZi:findChild("baoxiang_".._index), true)

        local boxMultiple = util_createAnimation("TakeOrStake_baoxiang_1.csb")
        self.m_boxList[_index]:addChild(boxMultiple)
        self.m_boxList[_index].boxMultiple = boxMultiple

        local multipleInfo = util_createAnimation("TakeOrStake_MultiplierInfo.csb")
        boxMultiple:findChild("Node_MultiplierInfo"):addChild(multipleInfo)
        self.m_boxList[_index].multipleInfo = multipleInfo

        self:addClick(self.m_chengBeiTaiZi:findChild(tostring(_index))) -- 非按钮节点得手动绑定监听
    end
end

function TakeOrStakeBonusGame:createGameOverNode( )
    self.m_gameOver_action = cc.Node:create()
    self.m_gameOver_action:setPosition(display.width * 0.5, display.height * 0.5)
    self:findChild("Node_overTake"):addChild(self.m_gameOver_action, 200)
end

-- 下方玩家头像
function TakeOrStakeBonusGame:initPlayerItem()
    self.m_playerItems = {}
    for _index = 1, 8 do
        local item = util_createView("CodeTakeOrStakeSrc.TakeOrStakeBonusPlayerItem")
        local parent = self:findChild(string.format("player_%d", _index-1))
        parent:addChild(item)
        item:showPickerUI(false)
        -- 判断显示 底
        if _index < 4 then
            item:showDiUI(1)
        elseif _index > 5 then
            item:showDiUI(3)
        else
            item:showDiUI(2)
        end
        table.insert(self.m_playerItems, item)
    end
end

-- 刷新头像
function TakeOrStakeBonusGame:upDatePlayerItem()
    local playersInfo = self:getPlayersInfo()

    if #playersInfo == 0 then
        return
    end

    for index = 1,8 do
        local info = playersInfo[index]
        local item = self.m_playerItems[index]
        if info then
            item:refreshData(info)
            --刷新头像
            item:refreshHead()
            item:showPickerUI(false)
            item:runCsbAction("idleframe", true)
        else
            item:noShowUI()
        end
    end
end

-- 初始化左右两遍的 倍数
function TakeOrStakeBonusGame:initChengBei( )
    local roomData = self.m_machine.m_roomDataClone
    local extra = roomData.extra

    if extra and extra.multiples then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_chengbei_chuxian)

        local callBack = function(_index, _color)
            self.m_chengBeiList[_index]:findChild("glow1"):setColor(_color)
            self.m_chengBeiList[_index]:findChild("glow2"):setColor(_color)
        end

        for _index, _multiples in ipairs(extra.multiples) do
            local delayTime = 0
            if _index >= 22 then
                delayTime = 0.5*(_index-22)
            end
            self.m_chengBeiList[_index]:findChild("m_lb_num1"):setString(_multiples .. "X")
            self.m_chengBeiList[_index]:findChild("m_lb_num2"):setString(_multiples .. "X")

            performWithDelay(self.m_gameOver_action, function()
                if _index <= 12 then
                    callBack(_index, cc.c3b(98, 207, 0))
                    self.m_chengBeiList[_index]:findChild("Node_lan"):setVisible(false)
                    self.m_chengBeiList[_index]:findChild("Node_hong"):setVisible(false)
                    self.m_chengBeiList[_index]:runCsbAction("start",false)
                elseif _index >= 22 then
                    callBack(_index, cc.c3b(255, 189, 48))
                    self.m_chengBeiList[_index]:findChild("Node_lan"):setVisible(false)
                    self.m_chengBeiList[_index]:findChild("Node_lv"):setVisible(false)
                    self.m_chengBeiList[_index]:findChild("Particle_1"):setVisible(true)
                    self.m_chengBeiList[_index]:findChild("Particle_1"):resetSystem() 
                    self.m_chengBeiList[_index]:runCsbAction("start2",false,function()
                        if self.m_isGameOver then
                            return
                        end
                        if _index == 24 then
                            self:showUIDark(nil, false)
                            
                            self:playYinDaoTanBanUI(2, true, "Node_OnlyOneHides1000", "Node_StartPicking", function()
                                if self.m_isGameOver then
                                    return
                                end
                                self:isTriPlayerShowUI(true)
                                self.m_isCanUpdataTime = true
                                self.m_isCanClick = true
                                local roomData = self.m_machine.m_roomDataClone
                                local extra = roomData.extra

                                self:showSelectBoxTimeUI(extra, true)
                            end)

                            self.m_jiaoSe:setVisible(true)
                            util_spinePlay(self.m_jiaoSe, "shejiao_tanban_start", false)
                            util_spineEndCallFunc(self.m_jiaoSe, "shejiao_tanban_start", function()
                                util_spinePlay(self.m_jiaoSe, "shejiao_idle", true)
                            end)
                        end
                    end)
                else
                    callBack(_index, cc.c3b(48, 183, 255))
                    self.m_chengBeiList[_index]:findChild("Node_hong"):setVisible(false)
                    self.m_chengBeiList[_index]:findChild("Node_lv"):setVisible(false)
                    self.m_chengBeiList[_index]:runCsbAction("start",false)
                end
            end, 0.1*(_index-1)+delayTime)
        end
    end
end

-- 初始化左右的倍数
function TakeOrStakeBonusGame:initChengBeiNum( )
    local roomData = self.m_machine.m_roomDataClone
    local extra = roomData.extra
    if extra and extra.multiples then
        for _index, _multiples in ipairs(extra.multiples) do
            self.m_chengBeiList[_index]:findChild("m_lb_num1"):setString(_multiples .. "X")
            self.m_chengBeiList[_index]:findChild("m_lb_num2"):setString(_multiples .. "X")
        end
    end
end

--显示宝箱的图片 或者 spine
-- isShowPic表示是否显示 图片
function TakeOrStakeBonusGame:changeBoxAndPic(boxId, isShowPic)
    if self.m_boxList[boxId].isShow then
        self.m_boxPicList[boxId]:setVisible(isShowPic)
        self.m_boxList[boxId]:setVisible(not isShowPic)
    else
        self.m_boxPicList[boxId]:setVisible(false)
        self.m_boxList[boxId]:setVisible(false)
    end
end

-- 播放宝箱的idle
function TakeOrStakeBonusGame:playBoxPicIdle( )
    if self.m_isGameOver then
        return
    end
    local random = math.random(1, 24)
    self.m_boxPicList[random]:runCsbAction("idleframe2", false, function()
        self:playBoxPicIdle()
    end)
end

-- 初始化 箱子
function TakeOrStakeBonusGame:initBox(func)
    for i,vNode in ipairs(self.m_playerItems) do
        vNode:setVisible(true)
    end

    local roomData = self.m_machine.m_roomDataClone
    local extra = roomData.extra
    
    self.m_chengBeiZuo:setVisible(true)
    self.m_chengBeiYou:setVisible(true)

    self.m_chengBeiTaiZi:setVisible(true)
    self.m_chengBeiTaiZi:runCsbAction("idle", false)
    self.m_chengBeiSelectTaiZi:setVisible(true)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_chuxian)

    for _boxIndex = 1, 24 do
        local delayTime = 0
        if _boxIndex >= 8 and _boxIndex <= 13 then
            delayTime = 0.2
        elseif _boxIndex >= 14 and _boxIndex <= 18 then
            delayTime = 0.4
        elseif _boxIndex >= 19 and _boxIndex <= 22 then
            delayTime = 0.6
        elseif _boxIndex >= 23 and _boxIndex <= 24 then
            delayTime = 0.8
        end
        performWithDelay(self.m_gameOver_action, function()
            self.m_boxList[_boxIndex]:setVisible(true)

            if extra.firstSelect and (extra.firstSelect + 1) == _boxIndex then
                self.m_boxList[_boxIndex]:setVisible(false)
                self.m_boxPicList[_boxIndex]:setVisible(false)
            end
            self:changeBoxAndPic(_boxIndex, false)
            
            util_spinePlay(self.m_boxList[_boxIndex], "start", false)
            util_spineEndCallFunc(self.m_boxList[_boxIndex], "start", function()
                util_spinePlay(self.m_boxList[_boxIndex], "idleframe", true)
                self:changeBoxAndPic(_boxIndex, true)
                if _boxIndex == 24 then
                    if func then
                        func()
                    end
                    -- 防止触发的玩家 一开始就加速了 不加速的玩家有可能 显示错误
                    for _index = 1, 24 do
                        if not self.m_boxList[_index].isShow then
                            self.m_boxList[_index]:setVisible(false)
                            self.m_boxPicList[_index]:setVisible(false)
                        end
                    end
                    self:playBoxPicIdle()
                end
            end)
        end, delayTime)
    end
end

function TakeOrStakeBonusGame:initSheJiaoUI( )
    self.m_isLastPlayerClick = false
    self.m_isSelectVisitOpenBox = true
    self.m_pickEffectStop = false
    self.m_curPlayerEventList = {}
    self.m_isHaveEnd = false
    self:runCsbAction("idle1",false)
    self.m_chengBeiZuo:runCsbAction("idle",false)
    self.m_chengBeiYou:runCsbAction("idle",false)
    self.m_chengBeiTaiZi:runCsbAction("idle", false)
    self.m_chengBeiSelectTaiZi:runCsbAction("idle", false)
    self.m_clickTake = false
    self.m_clickTakeOverBtn = false
    self.m_isCanUpdataTime = false
    self.m_isCanUpdataTime1 = false
    self.m_isCanClick = false

    self.m_liShiJiLuBanZi:setVisible(false)
    for i=1,8 do
        self.m_liShiJiLuBanZi:findChild("m_lb_num"..i):setString("")
    end
    self.m_takeJinBiTaiZi:setVisible(false)
    self.m_jieSuanTanBan:setVisible(false)
    self.m_sheJiaoOver:setVisible(false)
    self.m_selectBoxTimeUI:setVisible(false)
    self.m_pickTanBan:setVisible(false)
    self.m_darkUI:setVisible(false)
    self.m_yinDaoTanBan:setVisible(false)
    self.m_triPlayerShowUI:setVisible(false)
    self.m_backToSpinBtn:setVisible(false)
    self.m_jiaoSeOver:setVisible(false)
    self.m_triPalyerBox:setVisible(false)
    self.m_triPalyerBox.boxMultiple:runCsbAction("idle",false)
    self.m_isClickTakeAndLeave = false
end

-- 断线进来之后 初始化界面
function TakeOrStakeBonusGame:initDuanXianUI( )
    local roomData = self.m_machine.m_roomDataClone
    local event = self.m_machine.m_roomList.m_roomData:getRoomEvent()
    local extra = roomData.extra
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())

    util_setCascadeOpacityEnabledRescursion(self:findChild("shejiaoplayer"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("shejiaoplayer"), true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_xiaotaizi"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_xiaotaizi"), true)

    if extra.currentPhase == nil and roomData.result then
        if self.m_machine.m_haveBeginOpenBoxEffect then
            self.m_machine.m_haveBeginOpenBoxEffect = false
            self.m_haveJieShuOverView = true
            self:duanxianJieShuOverView(roomData.result.data)
            --发送停止刷新房间消息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
            --发送退出房间消息
            self.m_machine.m_roomList:sendLogOutRoom()

            return
        else
            self:duanxianJieShuOver(roomData.result)
        end
        
        extra = roomData.result.data
    end
    -- 判断显示选中的箱子
    if extra.firstSelect and extra.firstSelect > 0 then
        self.m_chengBeiSelectTaiZi:runCsbAction("idle1", false)
        self.m_triPalyerBox:setVisible(true)
        util_spinePlay(self.m_triPalyerBox, "idleframe2", true)
        self.m_triPalyerBox:setSkin(tonumber(extra.firstSelect)+1)
    end

    --左右两边的倍数
    if extra.leftMultiples then
        self:initDuanXianUIMultiples(extra)
    end

    -- 中间的24个箱子
    for _boxIndex = 1, 24 do
        self:changeBoxAndPic(_boxIndex, true)
        self.m_boxList[_boxIndex]:setVisible(true)
        util_spinePlay(self.m_boxList[_boxIndex], "idleframe", true)
    end

    self:playBoxPicIdle()

    --已选的 不显示
    if extra.selected then
        for _, _selected in ipairs(extra.selected) do
            self.m_boxList[_selected+1]:setVisible(false)
            self.m_boxPicList[_selected+1]:setVisible(false)
            self.m_boxList[_selected+1].isShow = false -- 是否显示
        end
    end

    if extra.currentPhase then
        self:initDuanXianUICurrentPhase(extra)
    end
end

--[[
    断线进来之后 初始化界面 两边的 成倍
]]
function TakeOrStakeBonusGame:initDuanXianUIMultiples(extra)
    local callBack = function(_index, _color)
        self.m_chengBeiList[_index]:findChild("glow1"):setColor(_color)
        self.m_chengBeiList[_index]:findChild("glow2"):setColor(_color)
    end

    for _index, _multiples in ipairs(extra.multiples) do
        self.m_chengBeiList[_index]:findChild("m_lb_num1"):setString(_multiples .. "X")
        self.m_chengBeiList[_index]:findChild("m_lb_num2"):setString(_multiples .. "X")
        local isHave = false
        for _, _leftMultiples in ipairs(extra.leftMultiples) do
            if _multiples == _leftMultiples then
                isHave = true
            end
        end
        if _index <= 12 then
            callBack(_index, cc.c3b(98, 207, 0))
            self.m_chengBeiList[_index]:findChild("Node_lan"):setVisible(false)
            self.m_chengBeiList[_index]:findChild("Node_hong"):setVisible(false)
            self.m_chengBeiList[_index]:runCsbAction("idle1",false)
        elseif _index >= 22 then
            callBack(_index, cc.c3b(255, 189, 48))
            self.m_chengBeiList[_index]:findChild("Node_lan"):setVisible(false)
            self.m_chengBeiList[_index]:findChild("Node_lv"):setVisible(false)
            self.m_chengBeiList[_index]:runCsbAction("idle2",false)
        else
            callBack(_index, cc.c3b(48, 183, 255))
            self.m_chengBeiList[_index]:findChild("Node_lv"):setVisible(false)
            self.m_chengBeiList[_index]:findChild("Node_hong"):setVisible(false)
            self.m_chengBeiList[_index]:runCsbAction("idle1",false)
        end

        if not isHave then
            self.m_chengBeiList[_index]:runCsbAction("idleDark",false)
        end
    end
end

--[[
    断线进来之后 初始化界面 刷新当前处于第几个阶段
]]
function TakeOrStakeBonusGame:initDuanXianUICurrentPhase(extra)
    if self:getPlayerIsClickTake(extra) then
        self.m_backToSpinBtn:setVisible(true)
    end

    -- 阶段 0 1 需要有倒计时框
    if extra.currentPhase == 0 or extra.currentPhase == 1 then
        self:showTouXiangPicker()
        local leftTime = extra.optionExpireAt - globalData.userRunData.p_serverTime
        leftTime = math.floor(leftTime / 1000)
        if leftTime <= 0 then
            self.m_isCanClick = false
        else
            self.m_isCanClick = true
        end
        self.m_isCanUpdataTime = true
        self:showSelectBoxTimeUI(extra, extra.currentPhase == 0 and true or false)
    -- 阶段2 是 take / stake
    elseif extra.currentPhase == 2 then
        self:showTouXiangPicker()
        if #extra.selected >= 23 then
            self.m_takeJinBiTaiZi:findChild("zi"):setVisible(false)
            self.m_takeJinBiTaiZi:findChild("zi2"):setVisible(true)
        else
            self.m_takeJinBiTaiZi:findChild("zi"):setVisible(true)
            self.m_takeJinBiTaiZi:findChild("zi2"):setVisible(false)
        end

        self.m_takeJinBiTaiZi:setVisible(true)
        self.m_takeYingQianBanZi:setVisible(true)
        self.m_takeYingQianBanZi:runCsbAction("idle", true)
        self.m_takeJinBiTaiZi:runCsbAction("idle", false)
        self.m_chengBeiTaiZi:runCsbAction("idle1", false)

        self.m_takeJinBiTaiZi:findChild("m_lb_num")
        self.m_takeJinBiTaiZi:findChild("m_lb_num"):setString(util_formatCoins(extra.offerFinal, 50) .. "X")
        self.m_takeYingQianBanZi:findChild("m_lb_num"):setString(util_formatCoins(extra.offerFinal,50))
        self.m_takeYingQianBanZi:findChild("m_lb_coins1"):setString(util_formatCoins(extra.score == 0 and 1 or extra.score,50))
        self.m_takeYingQianBanZi:findChild("m_lb_coins2"):setString(util_formatCoins(extra.offerFinal*(extra.score == 0 and 1 or extra.score),50))
        self:updateLabelSize({label=self.m_takeYingQianBanZi:findChild("m_lb_num"),sx=0.47,sy=0.5}, 105)
        self:updateLabelSize({label=self.m_takeYingQianBanZi:findChild("m_lb_coins1"),sx=0.46,sy=0.5}, 340)
        self:updateLabelSize({label=self.m_takeYingQianBanZi:findChild("m_lb_coins2"),sx=0.66,sy=0.68}, 634)

        self.m_jueseGuang = util_createAnimation("TakeOrStake_tanban_guang.csb")
        self.m_takeJinBiTaiZi:findChild("Node_guang"):addChild(self.m_jueseGuang)
        util_setCascadeOpacityEnabledRescursion(self.m_takeJinBiTaiZi:findChild("Node_guang"), true)
        util_setCascadeColorEnabledRescursion(self.m_takeJinBiTaiZi:findChild("Node_guang"), true)

        self.m_jueseGuang:runCsbAction("idle", true)

        self:runCsbAction("idle2", false)
        self:showUpdateUIByTakeOrLeaveBtn(extra,nil,true)

        self.m_isCanUpdataTime = true
    end
end

function TakeOrStakeBonusGame:duanxianJieShuOver(result)
    self.m_clickTake = false

    if self.m_isHaveEnd then
        return
    end
    if self.m_isGameOver then
        return
    end
    self.m_isHaveEnd = true
    self.m_isCanUpdataTime = false
    self.m_isCanUpdataTime1 = false
    --发送停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
    
    self.m_jiaoSeJieSuan:setVisible(false)
        
    self.m_takeJinBiTaiZi:setVisible(false)

    self.m_chengBeiTaiZi:setVisible(true)
    self.m_chengBeiTaiZi:runCsbAction("idle", false)
    self.m_selectBoxTimeUI:setVisible(false)

    self:showWinJieSuanView(result.data)

    self.m_liShiJiLuBanZi:setVisible(false)
end

-- 直接显示 断线的界面
function TakeOrStakeBonusGame:duanxianJieShuOverView(data)
    self.m_chengBeiZuo:runCsbAction("idle2",false)
    self.m_chengBeiYou:runCsbAction("idle2",false)
    self.m_chengBeiTaiZi:runCsbAction("idle2",false)
    self:runCsbAction("idle3",false)

    self:showOverView(data)
end

function TakeOrStakeBonusGame:showOverView(data)
    self.m_sheJiaoOver:setVisible(true)

    -- 重构数据
    local playerWinOld = clone(data.playerWin)
    local playerWin = {}
    for k,v in pairs(playerWinOld) do
        local player = {}
        player.udid = k
        player.coins = v
        table.insert(playerWin, player)
    end
    table.sort(playerWin, function(a, b)
        return a.coins > b.coins
    end)

    for _nodeIndex = 1, 8 do
        self.m_sheJiaoOver:findChild("Node_".._nodeIndex):setVisible(false)
    end

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_jiesuan_taizi_chuxian)

    self.m_sheJiaoOver:runCsbAction("start1", false, function()
        
        self.m_sheJiaoOver:findChild("Node_" .. #playerWin):setVisible(true)
        self.m_sheJiaoOver:findChild("Player".. #playerWin .."_TopWinner"):removeAllChildren(true)

        local topWinner = util_createAnimation("TakeOrStake_Jiesuan_TopWinner.csb")
        self.m_sheJiaoOver:findChild("Player".. #playerWin .."_TopWinner"):addChild(topWinner)
        topWinner:findChild("m_lb_coins"):setString(util_formatCoins(playerWin[1].coins, 3))

        local playerInfo = self:getPlayerInfoByUdid(playerWin[1].udid,data)

        if playerInfo then
            local head = topWinner:findChild("sp_touxiang")
            head:removeAllChildren(true)
            topWinner:findChild("Node_touxiang"):removeAllChildren(true)

            local frame = util_createAnimation("TakeOrStake_touxiangkuang_moren.csb")
            topWinner:findChild("Node_touxiang"):addChild(frame)

            local isMe = (globalData.userRunData.userUdid == playerInfo.udid)
            if playerInfo.frame == "" or playerInfo.frame == nil then
                frame:findChild("Player"):setVisible(isMe)
                frame:findChild("Others"):setVisible(not isMe)
            else
                frame:findChild("Player"):setVisible(false)
                frame:findChild("Others"):setVisible(false)
            end

            local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(playerInfo.facebookId, playerInfo.head, playerInfo.frame, nil, head:getContentSize())
            head:addChild(nodeAvatar)
            nodeAvatar:setPosition( head:getContentSize().width * 0.5, head:getContentSize().height * 0.5 )
        end

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_jiesuan_coin_chuxian)

        topWinner:runCsbAction("start", false, function()
            topWinner:runCsbAction("idle", false)
        end)
        if #playerWin - 1 > 0 then
            for i=1,#playerWin - 1 do
                self.m_sheJiaoOver:findChild("Player".. #playerWin .."_" .. i):removeAllChildren(true)
                local winner = util_createAnimation("TakeOrStake_Jiesuan_Winner.csb")
                self.m_sheJiaoOver:findChild("Player".. #playerWin .."_" .. i):addChild(winner)
                winner:findChild("m_lb_coins"):setString(util_formatCoins(playerWin[i+1].coins, 3))

                local playerInfo = self:getPlayerInfoByUdid(playerWin[i+1].udid,data)

                if playerInfo then
                    local head = winner:findChild("sp_touxiang")
                    head:removeAllChildren(true)
                    winner:findChild("Node_touxiang"):removeAllChildren(true)

                    local frame = util_createAnimation("TakeOrStake_touxiangkuang_moren.csb")
                    winner:findChild("Node_touxiang"):addChild(frame)

                    local isMe = (globalData.userRunData.userUdid == playerInfo.udid)
                    if playerInfo.frame == "" or playerInfo.frame == nil then
                        frame:findChild("Player"):setVisible(isMe)
                        frame:findChild("Others"):setVisible(not isMe)
                    else
                        frame:findChild("Player"):setVisible(false)
                        frame:findChild("Others"):setVisible(false)
                    end
                    
                    winner:findChild("player"):setVisible(isMe)
                    winner:findChild("playerL"):setVisible(isMe)
                    winner:findChild("others"):setVisible(not isMe)
                    winner:findChild("othersL"):setVisible(not isMe)

                    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(playerInfo.facebookId, playerInfo.head, playerInfo.frame, nil, head:getContentSize())
                    head:addChild(nodeAvatar)
                    nodeAvatar:setPosition( head:getContentSize().width * 0.5, head:getContentSize().height * 0.5 )
                end
                
                winner:runCsbAction("start", false, function()
                    winner:runCsbAction("idle", false)
                end)
            end
        end

        self.m_machine.m_gameBg:runCsbAction("bonus_win",true)
        self.m_machine.m_gameBg:findChild("caidai"):setVisible(true)
        for _particleIndex = 6, 13 do
            self.m_machine.m_gameBg:findChild("Particle_".._particleIndex):resetSystem()
        end
        performWithDelay(self.m_gameOver_action, function()
            self.m_sheJiaoOver:runCsbAction("start2", false, function()
                self.m_sheJiaoOver:findChild("Button_Collect"):setTouchEnabled(true)
            end)
            if #playerWin <= 6 then
                self.m_jiaoSeOver:setVisible(true)

                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_jiesuan_nvzhuchi_chuxian)

                util_spinePlay(self.m_jiaoSeOver, "jiesuan_start2", false)
                util_spineEndCallFunc(self.m_jiaoSeOver, "jiesuan_start2", function()
                    util_spinePlay(self.m_jiaoSeOver, "jiesuan_guzhang", true)
                end)
            end
        end, 160/60)
    end)
end

-- 显示界面压暗
function TakeOrStakeBonusGame:showUIDark(func, isOpenBox)
    if isOpenBox then
        if not self.m_isFirstPickResult2 then
            self.m_isFirstPickResult2 = true
            self.m_darkUI:setVisible(true)
            self.m_darkUI:runCsbAction("start",false,function()
                self.m_darkUI:runCsbAction("idle",false)
                if func then
                    func()
                end
            end)
        else
            if func then
                func()
            end
        end
    else
        self.m_darkUI:setVisible(true)
        self.m_darkUI:runCsbAction("start",false,function()
            self.m_darkUI:runCsbAction("idle",false)
            if func then
                func()
            end
        end)
    end
end

-- 显示界面压暗 取消
function TakeOrStakeBonusGame:closeUIDark(func)
    self.m_darkUI:runCsbAction("over",false,function()
        self.m_darkUI:setVisible(false)
        if func then
            func()
        end
    end)
end

-- 播放引导弹板
function TakeOrStakeBonusGame:playYinDaoTanBanUI(time, isCloseDark, startName, switchName, func)
    if startName == "Node_OnlyOneHides1000" then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_yindao_tanban1)
    elseif startName == "Node_PrizeChosen" then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_begin_tanban)
    end

    self.m_isCanClick = false
    self.m_yinDaoTanBan:setVisible(true)
    local function closeNode( )
        local nodeName = {"Node_StartPicking", "Node_PrizeChosen", "Node_StartOpening", "Node_LastCaseOpen", "Node_OnlyOneHides1000", "Node_AllPlayersWin"}
        for k,vName in pairs(nodeName) do
            self.m_yinDaoTanBan:findChild(vName):setVisible(false)
        end
    end
    
    closeNode()
    self.m_yinDaoTanBan:findChild(startName):setVisible(true)

    self.m_yinDaoTanBan:runCsbAction("start",false,function()
        self.m_yinDaoTanBan:runCsbAction("idle",false)
        performWithDelay(self.m_gameOver_action, function()

            if startName == "Node_OnlyOneHides1000" then
                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_yindao_tanban_qiehuan)
            elseif startName == "Node_PrizeChosen" then
                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_begin_tanban_qiehuan)
            end

            self.m_yinDaoTanBan:runCsbAction("switch",false,function()
                performWithDelay(self.m_gameOver_action, function()
                    if isCloseDark then
                        self:closeUIDark()
    
                        util_spinePlay(self.m_jiaoSe, "shejiao_tanban_over", false)
                        util_spineEndCallFunc(self.m_jiaoSe, "shejiao_tanban_over", function()
                            self.m_jiaoSe:setVisible(false)
                        end)
                    end
                    if startName == "Node_OnlyOneHides1000" then
                        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_yindao_tanban_close)
                    elseif startName == "Node_PrizeChosen" then
                        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_begin_tanban_close)
                    end
                    
                    self.m_yinDaoTanBan:runCsbAction("over",false,function()
                        if func then
                            func()
                        end
                    end)
    
                    if not isCloseDark then
                        util_spinePlay(self.m_jiaoSe, "shejiao_tanban_over", false)
                        util_spineEndCallFunc(self.m_jiaoSe, "shejiao_tanban_over", function()
                            self.m_jiaoSe:setVisible(false)
                        end)
                    end 
                end, 2)
            end)
            performWithDelay(self.m_gameOver_action, function()
                closeNode()
                self.m_yinDaoTanBan:findChild(switchName):setVisible(true)
                if switchName == "Node_StartPicking" then
                    local head = self.m_yinDaoTanBan:findChild("sp_touxiang")
                    head:removeAllChildren(true)
                    local roomData = self.m_machine.m_roomDataClone
                    local playerInfo = roomData.triggerPlayer

                    local isMe = (globalData.userRunData.userUdid == playerInfo.udid)
                    if playerInfo.frame == "" or playerInfo.frame == nil then
                        self.m_yinDaoTanBanFrame:findChild("Player"):setVisible(isMe)
                        self.m_yinDaoTanBanFrame:findChild("Others"):setVisible(not isMe)
                    else
                        self.m_yinDaoTanBanFrame:findChild("Player"):setVisible(false)
                        self.m_yinDaoTanBanFrame:findChild("Others"):setVisible(false)
                    end
        
                    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(playerInfo.facebookId, playerInfo.head, playerInfo.frame, nil, head:getContentSize())
                    head:addChild(nodeAvatar)
                    nodeAvatar:setPosition( head:getContentSize().width * 0.5, head:getContentSize().height * 0.5 )

                    local txt_name = self.m_yinDaoTanBan:findChild("m_lb_PlayerName")
                    txt_name:setString(playerInfo.nickName or "")
                    txt_name:stopAllActions()
                    
                    local clipNode = txt_name:getParent()
                    local clipSize = clipNode:getContentSize()
                    txt_name:setAnchorPoint(cc.p(0.5,0.5))
                    txt_name:setPosition(cc.p(clipSize.width / 2,clipSize.height / 2))
                    txt_name:ignoreContentAdaptWithSize(true)
                    util_wordSwing(txt_name, 1, clipNode, 2, 30, 2)
                end
            end, 20/60)
        end, time)
    end)

    if not isCloseDark then
        self.m_jiaoSe:setVisible(true)
        util_spinePlay(self.m_jiaoSe, "shejiao_tanban_start", false)
        util_spineEndCallFunc(self.m_jiaoSe, "shejiao_tanban_start", function()
            util_spinePlay(self.m_jiaoSe, "shejiao_idle", true)
        end)
    end
end

--判断 是否是触发玩家 是的话 额外显示一个弹板
function TakeOrStakeBonusGame:isTriPlayerShowUI(isTrigger)
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())
    if isTrigger then
        local roomData = self.m_machine.m_roomDataClone
        isMe = (globalData.userRunData.userUdid == roomData.triggerPlayer)
    end
    if isMe then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_begin_pick_tixing)
        self.m_triPlayerShowUI:setVisible(true)
        self.m_triPlayerShowUI:runCsbAction("auto",false)
        performWithDelay(self.m_gameOver_action, function()
            if self.m_triPlayerTiShiClose then
                self.m_triPlayerTiShiClose = false
                return
            end
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_begin_pick_tixing_close)
        end, 130/60)
    end
end

--[[
    显示或隐藏 take level按钮
]]
function TakeOrStakeBonusGame:showBtnTakeOrLevel(_isShow)
    self.m_takeBtn:findChild("Button_1"):setTouchEnabled(_isShow)
    self.m_leaveBtn:findChild("Button_2"):setTouchEnabled(_isShow)
    self.m_takeBtn:findChild("Button_1"):setBright(_isShow)
    self.m_leaveBtn:findChild("Button_2"):setBright(_isShow)
end

-- 显示 倒计时 弹板
function TakeOrStakeBonusGame:showSelectBoxTimeUI(extra, isTriPlayerSelect)
    if extra and extra.currentPhase then
        if extra.currentPhase == 2 then
            if #self.m_curPlayerEventList > 0 and isTriPlayerSelect then
                self.m_pickEffectStop = true
            end
            if self.m_leaveBtn:isVisible() then
                if not self.m_isCanUpdataTime1 then
                    return
                end
                local leftTime = extra.optionExpireAt - globalData.userRunData.p_serverTime
                leftTime = math.floor(leftTime / 1000)
                if leftTime < 0 then
                    leftTime = 0
                end

                if tonumber(extra.optionExpire) > TAKE_LEFTTIME then
                    self:showBtnTakeOrLevel(false)
                else
                    if self.m_isClickTakeAndLeave or self:getPlayerIsClickTake(extra) then
                        self:showBtnTakeOrLevel(false)
                    else
                        self:showBtnTakeOrLevel(true)
                    end
                end

                self.m_leaveBtn:findChild("m_lb_tim1"):setString(util_count_down_str1(leftTime))

                if leftTime <= 0 then
                    self.m_isCanUpdataTime = false
                    self:updataServerData()

                    --重置自动退出时间间隔
                    self.m_machine.m_roomList:resetLogoutTime()
                end 
            end
        else
            if not self.m_isCanUpdataTime then
                return
            end
            local selectBoxEffect = true --断线 加速等原因导致 当前玩家流程慢于其他玩家
            for _, vEvent in ipairs(self.m_curPlayerEventList) do
                if vEvent.eventType == "GAME_SELECT" then
                    selectBoxEffect = false
                end
            end
            if self.m_selectBoxTimeUI:isVisible() then
                local leftTime = self:showLeftTime(extra, selectBoxEffect)

                if leftTime <= 5 then
                    self.m_selectBoxTimeUI:runCsbAction("idle2",true)
                end
        
                if leftTime <= 0 then
                    self.m_isCanUpdataTime = false
                    self:updataServerData()
                    self:closeSelectBoxTimeUI()

                    --重置自动退出时间间隔
                    self.m_machine.m_roomList:resetLogoutTime()
                end 
            else
                local head = self.m_selectBoxTimeUI:findChild("sp_touxiang")
                head:removeAllChildren(true)
                local playerInfo = self:getPickerInfo(extra)
                if not playerInfo then
                    return
                end
                local isMe = (globalData.userRunData.userUdid == playerInfo.udid)
                if playerInfo.frame == "" or playerInfo.frame == nil then
                    self.m_selectBoxTimeUIFrame:findChild("Player"):setVisible(isMe)
                    self.m_selectBoxTimeUIFrame:findChild("Others"):setVisible(not isMe)
                else
                    self.m_selectBoxTimeUIFrame:findChild("Player"):setVisible(false)
                    self.m_selectBoxTimeUIFrame:findChild("Others"):setVisible(false)
                end
    
                local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(playerInfo.facebookId, playerInfo.head, playerInfo.frame, nil, head:getContentSize())
                head:addChild(nodeAvatar)
                nodeAvatar:setPosition( head:getContentSize().width * 0.5, head:getContentSize().height * 0.5 )
                
                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_timeUI)
                self.m_selectBoxTimeUI:setVisible(true)
                self.m_selectBoxTimeUI:runCsbAction("start",false)
                self.m_pickEffectStop = true
                self.m_liShiJiLuBanZi:setVisible(false)

                self:showLeftTime(extra, selectBoxEffect)
            end
        end
    end
end

--[[
    显示倒计时
]]
function TakeOrStakeBonusGame:showLeftTime(extra, selectBoxEffect)
    local leftTime = extra.optionExpireAt - globalData.userRunData.p_serverTime
    leftTime = math.floor(leftTime / 1000)
    if leftTime < 0 then
        leftTime = 0
    end

    self.m_selectBoxTimeUI:findChild("m_lb_tim1"):setString(util_count_down_str1(leftTime))

    if extra.currentPhase == 0 or (not selectBoxEffect) then
        if tonumber(extra.optionExpire) > PICK_FIRST_LEFTTIME then
            self.m_isCanClick = false
        else
            self.m_isCanClick = true
        end
        self.m_selectBoxTimeUI:findChild("m_lb_num"):setString(1)
    else
        if tonumber(extra.optionExpire) > PICK_LEFTTIME then
            self.m_isCanClick = false
        else
            self.m_isCanClick = true
        end
        self.m_selectBoxTimeUI:findChild("m_lb_num"):setString(extra.leftTimes)
    end
    return leftTime
end

-- 关闭 倒计时 弹板
function TakeOrStakeBonusGame:closeSelectBoxTimeUI( )
    if self.m_selectBoxTimeUI:isVisible() then 
        print("关闭倒计时")
        self.m_isCanUpdataTime = false
        
        self.m_isCanClick = false
        
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_timeUI_close)

        self.m_selectBoxTimeUI:runCsbAction("over",false,function()
            self.m_selectBoxTimeUI:setVisible(false)
        end)
    end
end

function TakeOrStakeBonusGame:getPlayersInfo()
    local setData = {}

    local result = self.m_machine.m_roomData:getSpotResult()

    -- 玩法触发后需要优先取触发座位的数据
    -- 因为房间数据内可能不包含触发玩法后立刻断线玩家的数据
    if self.m_machine.m_roomList.m_roomData.m_teamData.room.extra.sets then
        setData = clone(self.m_machine.m_roomList.m_roomData.m_teamData.room.extra.sets)
    else
        if result then
            setData = result.data.sets or {}
        end
    end
    
    table.sort(setData, function(a,b)
        -- 按座位排序
        if a.chairId and b.chairId then
            return a.chairId < b.chairId
        end

        return false
    end)
    
    return setData
end

--[[
    游戏结束
]]
function TakeOrStakeBonusGame:gameEnd()
    self.m_isCanUpdataTime = false
    self.m_isGameOver = true
    
    self.m_haveBeginOpenBoxEffect = false
    self.m_haveJieShuOverView = false

    self.m_gameOver_action:stopAllActions()
    self.m_gameOver_action:removeAllChildren()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_guochang)

    self.m_machine.m_guochangOver:setVisible(true)
    util_spinePlay(self.m_machine.m_guochangOver, "guochang", false)
    util_spineEndCallFunc(self.m_machine.m_guochangOver, "guochang", function()
        if not self.m_machine then
            return
        end
        self.m_machine:sendSeverWins()
    end)
    self.m_machine:waitWithDelay(30/30, function()
        if not self.m_machine then
            return
        end
        self.m_machine.m_roomList.m_refreshTime = os.time()
        self.m_machine.m_roomList.m_heart_beat_time = 5

        self.m_machine.m_roomList.m_logOutTime = 0
        self.m_machine.m_roomList.m_logout_time = 300

        self.m_machine.m_roomDataClone = {}

        --重新刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)

        self.m_machine:setReelBg(1)

        self:initSheJiaoUI()

        for _boxIndex = 1, 24 do
            self.m_boxList[_boxIndex].isClick = true -- 是否可点击
            self.m_boxList[_boxIndex].isShow = true -- 是否显示
            self.m_boxList[_boxIndex].isOpen = false -- 是否打开
            self.m_boxList[_boxIndex]:setVisible(false)
            self.m_boxPicList[_boxIndex]:setVisible(false)
            util_setChildNodeOpacity(self.m_boxList[_boxIndex], 255)

            self.m_chengBeiList[_boxIndex]:runCsbAction("idle3",false)
        end

        self.m_machine:setCurrSpinMode(NORMAL_SPIN_MODE)

        self.m_machine.m_isRunningEffect = false
        self.m_machine.m_isTriggerBonus = false
        self.m_machine.m_gameEffects = {}
        self.m_machine.m_bEnterUpDateCollect = false

        self:setVisible(false)
        self.m_machine:showBottonUI(true)
        self.m_machine:findChild("Node_qipan"):setVisible(true)
        self.m_machine:setCollectBonusNum()

        self.m_machine:resetMusicBg()
        self.m_machine:checkTriggerOrInSpecialGame(function(  )
            self.m_machine:reelsDownDelaySetMusicBGVolume( ) 
        end)

        self.m_machine.m_collectSorce:runCsbAction("idle",false)
        self.m_machine:sheJiaoOverShowBonus()
        self.m_machine.m_isFirstComeInSheJiao = false
        self.m_machine.m_isNotDuanXianComeInSheJiao = false

        self.m_isHaveEnd = false
        self.m_playTriSelectBoxEffect = false
    end)
end

-- 选择箱子 
function TakeOrStakeBonusGame:sendSelectBoxData(selectId)
    --重置自动退出时间间隔
    self.m_machine.m_roomList:resetLogoutTime()

    local httpSendMgr = SendDataManager:getInstance()
    local gameName = self.m_machine:getNetWorkModuleName()
    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end

    local roomData = self.m_machine.m_roomDataClone
    local actionData = httpSendMgr:getNetWorkSlots():getSendActionData(ActionType.TeamMissionOption, gameName)
    local params = {}
    params.action = roomData.extra.currentPhase -- 表示当前阶段
    params.extra = {} --  玩家选择的箱子位置 整数0-n
    params.extra.value = selectId
    actionData.data.params = json.encode(params)
    print("选择的箱子ID：")
    print(selectId)
    httpSendMgr:getNetWorkSlots():sendMessageData(actionData)
end

-- 倒计时为0 之后 客服端主动告诉 服务器 
function TakeOrStakeBonusGame:updataServerData( )
    local httpSendMgr = SendDataManager:getInstance()
    local gameName = self.m_machine:getNetWorkModuleName()
    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end

    local roomData = self.m_machine.m_roomDataClone
    local actionData = httpSendMgr:getNetWorkSlots():getSendActionData(ActionType.TeamMissionRefresh, gameName)
    local params = {}
    params.action = 2
    actionData.data.params = json.encode(params)
    httpSendMgr:getNetWorkSlots():sendMessageData(actionData)
end

--[[
    获取用户ID
]]
function TakeOrStakeBonusGame:getPlayerID()
    local roomData = self.m_machine.m_roomDataClone
    if roomData.extra and roomData.extra.currentUser then
        return roomData.extra.currentUser
    end
    return ""
end

--[[
    整理服务器发过来的事件
]]
function TakeOrStakeBonusGame:getEventList(event)
    local curAuToPickList = {}
    local curResultList = {}
    local newEventList = {}
    if #event > 0 then
        for i,vEvent in ipairs(event) do
            if vEvent.eventType == "GAME_PICK_AUTO" then
                table.insert( curAuToPickList, vEvent)
            else
                table.insert( curResultList, vEvent)
            end
        end
        for i,vEvent in ipairs(curAuToPickList) do
            if #newEventList > 0 then
                local curEvent = clone(vEvent)
                table.insert( newEventList[1].value, tonumber(curEvent.value))
            else
                local curEvent = clone(vEvent)
                table.insert( newEventList, curEvent)
                newEventList[1].value = {}
                table.insert( newEventList[1].value, tonumber(vEvent.value))
            end
        end

        for i,vEvent in ipairs(curResultList) do
            table.insert( newEventList, vEvent)
        end
    end 

    if #curAuToPickList <= 0 then
        newEventList = event
        self.m_pickEffectStop = true
    end

    if not self.m_pickEffectStop then
        for i,vEvent in ipairs(newEventList) do
            table.insert(self.m_curPlayerEventList, vEvent)
        end
        newEventList = {}
    else
        for i,vEvent in ipairs(self.m_curPlayerEventList) do
            table.insert(newEventList, clone(vEvent))
            self.m_pickEffectStop = false
        end
        self.m_curPlayerEventList = {}
    end

    return newEventList
end

--[[
    从后台切回游戏 刷新
]]
function TakeOrStakeBonusGame:updataUIByBackStageToGame( )
    self.m_machine.m_roomList.m_roomData.m_teamData.events = {}

    self:upDatePlayerItem()
    self:initChengBeiNum()
    self:initSheJiaoUI()
    self:initDuanXianUI()
end

-- 刷新界面
function TakeOrStakeBonusGame:upDateSheJiaoUI()
    local roomData1 = self.m_machine.m_roomList:getRoomData()
    if roomData1.extra.currentUser or (roomData1.result and roomData1.result.data and roomData1.result.data.currentPhase) then
        self.m_machine.m_roomDataClone = clone(roomData1)
    end

    local roomData = self.m_machine.m_roomDataClone
    local event = self.m_machine.m_roomList.m_roomData:getRoomEvent()
    local extra = roomData.extra
    local result = roomData.result
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())
    if self.m_machine.m_isQieHuanHouTai then
        self.m_machine.m_isQieHuanHouTai = false
        self:updataUIByBackStageToGame()
        return
    end

    -- 如果有 auto事件 自己整合一下数据
    local newEventList = self:getEventList(event)

    local pickAutoDelayTime = 0
    for i,vEvent in ipairs(newEventList) do
        -- GAME_SELECT 表示触发的玩家 选择箱子
        if vEvent.eventType == "GAME_SELECT" then
            -- 正在播放动画 不刷新
            if not self.m_playTriSelectBoxEffect then
                self.m_playTriSelectBoxEffect = true
                pickAutoDelayTime = 12
                self.m_isCanClick = false
                self:triPlayerSelectBoxUpdateUI(vEvent,extra)
                self:closeSelectBoxTimeUI()
            end
        end
        -- GAME_PICK 表示pick玩家 选择的箱子
        if vEvent.eventType == "GAME_PICK" then
            performWithDelay(self.m_gameOver_action, function()
                self:pickerSelectBoxUpdateUI(vEvent)
            end, pickAutoDelayTime)
        end

        -- GAME_PICK 表示pick玩家没来得及 选完箱子，倒计时结束了 服务器给随机的箱子
        if vEvent.eventType == "GAME_PICK_AUTO" then
            local isPlayShengYin = false--播放音效的时候 判断是否播放一次
            for _, _event in ipairs(newEventList) do
                if _event.eventType == "GAME_PICK" then
                    isPlayShengYin = true
                end
            end

            performWithDelay(self.m_gameOver_action, function()
                self:pickerSelectBoxUpdateUIAuTo(vEvent, isPlayShengYin)
            end, pickAutoDelayTime)

            pickAutoDelayTime = pickAutoDelayTime + 0.5
        end

        -- GAME_PICK_OPEN 表示pick玩家 选择的箱子选完之后 依次打开箱子
        if vEvent.eventType == "GAME_PICK_RESULT" then
            performWithDelay(self.m_gameOver_action, function()
                -- m_isFirstPickResult 防止多次走到这个事件
                -- 如果加速的玩家走的比较快的话 可能导致 不加速的玩家 积攒多个pick_result事件 
                -- 这么做 是为了保证 有多个事件的时候 直走一次
                if not self.m_isFirstPickResult1 then
                    self.m_isFirstPickResult1 = true
                    self:closeSelectBoxTimeUI()
                end
                self:pickerSelectBoxOpenEffect(vEvent, extra)
            end, pickAutoDelayTime)
        end

        -- GAME_TAKE 表示玩家 选择 take 之后 ,需要实时推送这个消息
        if vEvent.eventType == "GAME_TAKE" then
            if vEvent.value == "1" then
                if globalData.userRunData.userUdid == vEvent.udid then
                    self.m_clickTake = true
                    if result and result.data and result.data.currentPhase == 3 then
                        self.m_isSelectVisitOpenBox = false
                    end
                    self:selectTakeOverView(extra)
                end
            end
        end

        if vEvent.eventType == "GAME_TAKE_RESULT" then
            if result and result.data and result.data.currentPhase == 3 then
                for _, _event in ipairs(newEventList) do
                    if _event.eventType == "GAME_TAKE" then
                        if _event.value == "1" then
                            if globalData.userRunData.userUdid == _event.udid then
                                self.m_isLastPlayerClick = true
                            end
                        end
                    end
                end
            end
        end

        if extra.currentPhase or (result and result.data and result.data.currentPhase ~= 3) then
            -- GAME_TAKE 表示所有玩家 选择 take leave 之后 ，推送给所有玩家
            if vEvent.eventType == "GAME_TAKE_RESULT" and (not result) then
                local delayTime = 0
                if self.m_clickTake then
                    delayTime = 2
                end
                -- m_isFirstTakeResult 防止多次走到这个事件
                -- 如果加速的玩家走的比较快的话 可能导致 不加速的玩家 积攒多个take_result事件 
                -- 这么做 是为了保证 有多个事件的时候 直走一次
                if not self.m_isFirstTakeResult then
                    self.m_isFirstTakeResult = true
                    performWithDelay(self.m_gameOver_action, function()
                        self:updataUIByTakeResult(extra)
                    end, delayTime)
                end
            end
        end
    end

    --在piker 选多个箱子阶段 按钮 状态 
    -- pick阶段 刚结束 服务器会马上把 currentPhase 变成2 表示pick完箱子 玩家的选择阶段
    -- 客户端可以判断 第一次 接收到 currentPhase 为2 作为开箱子的节点
    if extra.currentPhase == 2 then
        if not self.m_playOpenBoxAndTakeEffect then
            self.m_isCanClick = false
            self.m_playOpenBoxAndTakeEffect = true
        end
    end

    -- 表示结算阶段 社交玩法 结束
    if result and result.data and result.data.currentPhase == 3 then
        if self.m_haveJieShuOverView then
            return
        end
        local delayTime = 0.01
        if self.m_clickTake and (not self.m_isLastPlayerClick) then
            delayTime = 5
        end
        if self.m_isSelectVisitOpenBox then
            performWithDelay(self.m_gameOver_action, function()
                self:updataUiByClickOver(result)
            end, delayTime)
        end
        
    end

    if extra.currentPhase and extra.currentPhase ~= 0 and extra.leftTimes and extra.leftTimes <= 0 then
        self.m_isCanClick = false
    end

    self:showSelectBoxTimeUI(extra)
end

--[[
    根据GAME_TAKE_RESULT 事件的结果 刷新界面
]]
function TakeOrStakeBonusGame:updataUIByTakeResult(extra)
    local delayTime1 = 0
    if self.m_jueseGuang then
        delayTime1 = 30/60
        self.m_takeJinBiTaiZi:runCsbAction("over2", false, function()
            if not tolua.isnull() then
                self.m_jueseGuang:removeFromParent()
            end
            self.m_jueseGuang = nil
        end)
        util_spinePlay(self.m_jiaoSeJieSuan, "jiesuan_over", false)
        util_spineEndCallFunc(self.m_jiaoSeJieSuan, "jiesuan_over", function()
            self.m_jiaoSeJieSuan:setVisible(false)
        end) 
    end

    self.m_clickTake = false
    self.m_isCanUpdataTime1 = false
    performWithDelay(self.m_gameOver_action, function()
        self:runCsbAction("start", false)

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_taizi_qiehuan_qian)

        self.m_takeJinBiTaiZi:runCsbAction("switch2", false, function()
            self.m_takeJinBiTaiZi:setVisible(false)
        end)
        self.m_chengBeiTaiZi:setVisible(true)
        self.m_chengBeiTaiZi:runCsbAction("start", false, function()
            self.m_chengBeiTaiZi:runCsbAction("idle", false)
            
            self.m_isClickTakeAndLeave = false

            self.m_takeBtn:setVisible(false)
            
            self.m_leaveBtn:setVisible(false)

            self:beginPick(extra)

            self.m_isFirstTakeResult = false
        end)

        if self.m_liShiJiLuBanZi:isVisible() then
            self.m_liShiJiLuBanZi:runCsbAction("over", false, function()
                self.m_liShiJiLuBanZi:setVisible(false)
            end)
        end
        if delayTime1 == 0 then
            util_spinePlay(self.m_jiaoSeJieSuan, "jiesuan_over", false)
            util_spineEndCallFunc(self.m_jiaoSeJieSuan, "jiesuan_over", function()
                self.m_jiaoSeJieSuan:setVisible(false)
            end) 
        end
    end, delayTime1)
end

--[[
    进入结算流程
]]
function TakeOrStakeBonusGame:updataUiByClickOver(result)
    self.m_clickTake = false
    
    if self.m_isHaveEnd then
        return
    end
    if self.m_isGameOver then
        return
    end
    self.m_haveBeginOpenBoxEffect = true
    self.m_isHaveEnd = true
    self.m_isCanUpdataTime = false
    self.m_isCanUpdataTime1 = false
    --发送停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
    -- --发送退出房间消息
    self.m_machine.m_roomList:sendLogOutRoom()
    
    if self.m_jueseGuang then
        self.m_takeJinBiTaiZi:runCsbAction("over2", false, function()
            if not tolua.isnull() then
                self.m_jueseGuang:removeFromParent()
            end
            self.m_jueseGuang = nil
        end)
    end
    performWithDelay(self.m_gameOver_action, function()
        util_spinePlay(self.m_jiaoSeJieSuan, "jiesuan_over", false)
        util_spineEndCallFunc(self.m_jiaoSeJieSuan, "jiesuan_over", function()
            self.m_jiaoSeJieSuan:setVisible(false)
        end)

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_taizi_qiehuan_last)
        
        self:runCsbAction("start", false)
        
        self.m_takeJinBiTaiZi:runCsbAction("switch2", false, function()
            self.m_takeJinBiTaiZi:setVisible(false)
        end)
        self.m_chengBeiTaiZi:setVisible(true)
        self.m_chengBeiTaiZi:runCsbAction("start", false, function()
            self.m_chengBeiTaiZi:runCsbAction("idle", false)

            self.m_takeBtn:setVisible(false)
            
            self.m_leaveBtn:setVisible(false)
            
            performWithDelay(self.m_gameOver_action, function()
                if self.m_isGameOver then
                    return
                end
                self:showWinJieSuanView(result.data)
            end, 0.01)
        end)

        if self.m_liShiJiLuBanZi:isVisible() then
            self.m_liShiJiLuBanZi:runCsbAction("over", false, function()
                self.m_liShiJiLuBanZi:setVisible(false)
            end)
        end
    end, 0.5)
end

--默认按钮监听回调
function TakeOrStakeBonusGame:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    -- 点击take
    if name == "Button_1" then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_clickBtn)
        self.m_isCanClick = false
        self.m_isClickTakeAndLeave = true
        self:sendSelectBoxData(1)
        self:showBtnTakeOrLevel(false)
        return
    end

    -- 点击 leave
    if name == "Button_2" then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_clickBtn)
        self.m_isCanClick = false
        self.m_isClickTakeAndLeave = true
        self:sendSelectBoxData(2)
        self:showBtnTakeOrLevel(false)
        return
    end

    -- 最终结算界面按钮
    if name == "Button_Collect" then
        self.m_sheJiaoOver:findChild("Button_Collect"):setTouchEnabled(false)
        self:gameEnd()
        return
    end

    -- 点击take 结算界面按钮
    if name == "Btn_collect" then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_clickBtn)
        self.m_clickTakeOverBtn = true
        self.m_clickTakeOverView:findChild("Btn_collect"):setTouchEnabled(false)
        self.m_clickTakeOverView:runCsbAction("over", false, function()
            self.m_clickTakeOverView:setVisible(false)
            
            local roomData = self.m_machine.m_roomDataClone
            local result = roomData.result
            if result and result.data and result.data.currentPhase == 3 then
                if self.m_isLastPlayerClick then
                    self:clickTakeAndGameEnd()
                end
            end
            -- 恢复背景音乐
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        return
    end

    -- 点击take 结算界面 之后的选择界面
    if name == "Button_ShowMe" then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_clickBtn)
        self.m_yinDaoTanBan:findChild("Button_ShowMe"):setTouchEnabled(false)
        self.m_yinDaoTanBan:findChild("Button_BackSpin"):setTouchEnabled(false)

        self:closeUIDark()
        self.m_isSelectVisitOpenBox = true
        self.m_yinDaoTanBan:runCsbAction("over",false,function()
            
        end)
        return
    end

    if name == "Button_BackSpin" then
        self.m_backToSpinBtn:setVisible(false)
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_clickBtn)
        --发送退出房间消息
        self.m_machine.m_roomList:sendLogOutRoom()
        self.m_yinDaoTanBan:findChild("Button_ShowMe"):setTouchEnabled(false)
        self.m_yinDaoTanBan:findChild("Button_BackSpin"):setTouchEnabled(false)

        self:closeUIDark()
        self.m_yinDaoTanBan:runCsbAction("over",false,function()
            --发送退出房间消息
            self.m_machine.m_roomList:sendLogOutRoom()
            self:gameEnd()
        end)
        return
    end

    if name == "backToSpinBtn" then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_clickBtn)
        self.m_backToSpinBtn:setVisible(false)
        --发送退出房间消息
        self.m_machine.m_roomList:sendLogOutRoom()
        self:gameEnd()
        return
    end

    -- 不是当前 可操作玩家 不能选择
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())
    if not isMe then
        return
    end

    if not self.m_isCanClick then
        return
    end

    if self.m_boxList[tonumber(name)].isClick then
        self.m_boxList[tonumber(name)].isClick = false

        self.m_isCanClick = false
        if self.m_triPlayerShowUI:isVisible() then
            self.m_triPlayerTiShiClose = true
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_begin_pick_tixing_close)
            self.m_triPlayerShowUI:setVisible(false)
        end
        local roomData = self.m_machine.m_roomDataClone
        local extra = roomData.extra
        if extra and extra.currentPhase == 0 then
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_click)
        else
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_click_liang)
        end

        self:changeBoxAndPic(tonumber(name), false)
        util_spinePlay(self.m_boxList[tonumber(name)], "actionframe2", false)
        util_spineEndCallFunc(self.m_boxList[tonumber(name)], "actionframe2", function()
            util_spinePlay(self.m_boxList[tonumber(name)], "start2", false)
            util_spineEndCallFunc(self.m_boxList[tonumber(name)], "start2", function()
                util_spinePlay(self.m_boxList[tonumber(name)], "idleframe3", true)
            end)
        end)

        self:sendSelectBoxData(tonumber(name)-1)
    end
end

-- 触发玩家选择完箱子 出现在底部中间 刷新界面
function TakeOrStakeBonusGame:triPlayerSelectBoxUpdateUI(eventData, extra)
    print("看看事件返回的选择箱子ID")
    print(tonumber(eventData.value)+1)
    self.m_boxList[tonumber(eventData.value)+1].isShow = false -- 是否显示
    self.m_boxList[tonumber(eventData.value)+1]:setVisible(false)
    self.m_boxPicList[tonumber(eventData.value)+1]:setVisible(false)

    local startPos = util_convertToNodeSpace(self.m_chengBeiTaiZi:findChild("baoxiang_" .. tonumber(eventData.value)+1),self:findChild("Node_box"))

    local endNode = self.m_chengBeiSelectTaiZi:findChild("baoxiang")
    local endPos = util_convertToNodeSpace(endNode,self:findChild("Node_box"))

    local boxFlyNode = util_spineCreate("TakeOrStake_baoxiang",true,true)
    boxFlyNode:setSkin(tonumber(eventData.value)+1)
    self:findChild("Node_box"):addChild(boxFlyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    boxFlyNode:setPosition(startPos)

    util_spinePlay(boxFlyNode, "fly", false)

    performWithDelay(self.m_gameOver_action, function()
        local actList = {}
        actList[#actList + 1]  = cc.MoveTo:create(10/30,cc.p(0, 0))
        actList[#actList + 1] = cc.CallFunc:create(function (  )
        end)
        
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_fly1)
        boxFlyNode:runAction(cc.Sequence:create(actList))
    end, 10/30)

    performWithDelay(self.m_gameOver_action, function()
        local actList = {}
        actList[#actList + 1]  = cc.MoveTo:create(13/30,endPos)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            
            boxFlyNode:removeFromParent()

            self.m_triPalyerBox:setVisible(true)
            util_spinePlay(self.m_triPalyerBox, "idleframe2", true)
            self.m_triPalyerBox:setSkin(tonumber(eventData.value)+1)
            self.m_chengBeiSelectTaiZi:runCsbAction("actionframe",false,function()
                self:playYinDaoTanBanUI(2, false, "Node_PrizeChosen", "Node_StartOpening", function()
                    self:beginPick(extra)
                end)
            end)
        end)

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_fly2)
        boxFlyNode:runAction(cc.Sequence:create(actList))
    end, 55/30)
end

-- picker 玩家选择完箱子 消息推送给所有人 所有人 都根据消息刷新选择pick的箱子
-- 根据箱子 的可点击 状态 刷新 self.m_boxList[i].isClick = true -- 是否可点击
function TakeOrStakeBonusGame:pickerSelectBoxUpdateUI(eventData)
    if self.m_boxList[tonumber(eventData.value)+1].isShow then
        self.m_isCanClick = true
        if self.m_boxList[tonumber(eventData.value)+1].isClick then
            self.m_boxList[tonumber(eventData.value)+1].isClick = false
            self:changeBoxAndPic(tonumber(eventData.value)+1, false)
            util_spinePlay(self.m_boxList[tonumber(eventData.value)+1], "idleframe3", true)
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_click_liang)
        end
    end
end

-- picker 玩家选择完箱子 消息推送给所有人 所有人 都根据消息刷新选择pick的箱子
-- 根据箱子 的可点击 状态 刷新 self.m_boxList[i].isClick = true -- 是否可点击
-- 倒计时结束之后 服务器随机给的箱子 ID
function TakeOrStakeBonusGame:pickerSelectBoxUpdateUIAuTo(eventData, isPlayShengYin)
    self.m_selectBoxTimeUI:findChild("m_lb_num"):setString(1)
    if eventData.value and #eventData.value > 0 then
        for _index, _eventData in ipairs(eventData.value) do
            if self.m_boxList[tonumber(_eventData)+1].isShow then
                self.m_isCanClick = true
                if self.m_boxList[tonumber(_eventData)+1].isClick then
                    self.m_boxList[tonumber(_eventData)+1].isClick = false
                    self:changeBoxAndPic(tonumber(_eventData)+1, false)
                    util_spinePlay(self.m_boxList[tonumber(_eventData)+1], "idleframe3", true)
                    if _index == 1 then
                        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_click_liang)
                    end
                end
            end
        end
    end
end

--筛选当前正在 pick的玩家 的信息
function TakeOrStakeBonusGame:getPickerInfo(extra)
    local setData = clone(extra.sets)
    if setData and #setData then
        for i,vInfo in ipairs(setData) do
            if self:getPlayerID() == vInfo.udid then
                return vInfo
            end
        end
    end
    return nil
end

-- 玩家开始 pick的相关动画 流程
function TakeOrStakeBonusGame:beginPick(extra)
    self.m_isCanClick = false
    local head = self.m_pickTanBan:findChild("sp_touxiang")
    head:removeAllChildren(true)
    local playerInfo = self:getPickerInfo(extra)
    if not playerInfo then
        return
    end
    local isMe = (globalData.userRunData.userUdid == playerInfo.udid)
    if playerInfo.frame == "" or playerInfo.frame == nil then
        self.m_pickTanBanFrame:findChild("Player"):setVisible(isMe)
        self.m_pickTanBanFrame:findChild("Others"):setVisible(not isMe)
    else
        self.m_pickTanBanFrame:findChild("Player"):setVisible(false)
        self.m_pickTanBanFrame:findChild("Others"):setVisible(false)
    end

    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(playerInfo.facebookId, playerInfo.head, playerInfo.frame, nil, head:getContentSize())
    head:addChild(nodeAvatar)
    nodeAvatar:setPosition( head:getContentSize().width * 0.5, head:getContentSize().height * 0.5 )

    self.m_pickTanBan:setVisible(true)

    self:showTouXiangPicker()

    -- 中间的24个箱子
    for _boxIndex = 1, 24 do
        self:changeBoxAndPic(_boxIndex, true)
        util_spinePlay(self.m_boxList[_boxIndex], "idleframe", true)
    end

    local roomData = self.m_machine.m_roomDataClone
    local extra = roomData.extra
    self.m_pickTanBan:findChild("m_lb_num"):setString(extra.totalTimes or 1)
    self.m_pickTanBanGuang:runCsbAction("idle",true)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_picker_tanban)

    self.m_pickTanBan:runCsbAction("start",false,function()
        self.m_pickTanBan:runCsbAction("idle",false,function()
            self.m_pickTanBan:runCsbAction("over",false,function()
                self.m_pickTanBan:setVisible(false)

                self:isTriPlayerShowUI(false)
                self.m_isCanUpdataTime = true
                self.m_isCanClick = true
                self:showSelectBoxTimeUI(extra)
            end)
        end)
    end)
end

-- 显示下面八个玩家头像 上面的 picker
function TakeOrStakeBonusGame:showTouXiangPicker( )
    
    local playersInfo = self:getPlayersInfo()

    if #playersInfo == 0 then
        return
    end

    for index = 1,8 do
        local info = playersInfo[index]
        local item = self.m_playerItems[index]
        if info then
            if info.udid == self:getPlayerID() then
                item:showPickerUI(true)
            else
                item:showPickerUI(false)
            end
        else
            item:noShowUI()
        end
    end
end

-- pick阶段完了 走打开箱子的流程
function TakeOrStakeBonusGame:pickerSelectBoxOpenEffect(eventData, extra)
    local extraNum = table.nums(json.decode(eventData.extra))
    self:showDarkAndChangeOrder(eventData.extra, function()
        local openIndex = 0
        for boxId, boxMultiple in pairs(json.decode(eventData.extra)) do
            openIndex = openIndex + 1
            performWithDelay(self.m_gameOver_action, function()
                if self.m_boxList[tonumber(boxMultiple.player)+1].isShow then
                    if not self.m_boxList[tonumber(boxMultiple.player)+1].isOpen then
                        self.m_boxList[tonumber(boxMultiple.player)+1].isOpen = true
                        self.m_boxList[tonumber(boxMultiple.player)+1]:setZOrder(1000+openIndex)

                        self:changeBoxAndPic(tonumber(boxMultiple.player)+1, false)

                        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_open)

                        util_spinePlay(self.m_boxList[tonumber(boxMultiple.player)+1], "actionframe3", false)
                        self.m_boxList[tonumber(boxMultiple.player)+1].boxMultiple:runCsbAction("actionframe", false, function()
                            self:playZuoAndYouChengBeiEffect(boxMultiple.multiple, self.m_boxList[tonumber(boxMultiple.player)+1])

                        end)
                        self.m_boxList[tonumber(boxMultiple.player)+1].boxMultiple:findChild("m_lb_coins"):setString(boxMultiple.multiple.."X")

                        self.m_boxList[tonumber(boxMultiple.player)+1].multipleInfo:findChild("GoodJob"):setVisible(false)
                        self.m_boxList[tonumber(boxMultiple.player)+1].multipleInfo:findChild("Nice"):setVisible(false)
                        self.m_boxList[tonumber(boxMultiple.player)+1].multipleInfo:findChild("Ohno"):setVisible(false)

                        if boxMultiple.multiple >= 500 then
                            self.m_boxList[tonumber(boxMultiple.player)+1].multipleInfo:findChild("Ohno"):setVisible(true)
                            self.m_boxList[tonumber(boxMultiple.player)+1].multipleInfo:runCsbAction("auto", false)
                        elseif boxMultiple.multiple <= 6 then
                            local nodeName = {"GoodJob", "Nice"}
                            local random = math.random(1,2)
                            if random == 1 then
                                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_open_goodjob)
                            else
                                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_box_open_nice)
                            end
                            self.m_boxList[tonumber(boxMultiple.player)+1].multipleInfo:findChild(nodeName[random]):setVisible(true)
                            self.m_boxList[tonumber(boxMultiple.player)+1].multipleInfo:runCsbAction("auto", false)
                        end
                    end
                end
            end, 2.5 * (openIndex-1))
        end

        if not self.m_isFirstPickResult3 then
            self.m_isFirstPickResult3 = true
            local delayTime = 2.5 * (extraNum-1)
            performWithDelay(self.m_gameOver_action, function()
                self.m_isHavingDelay = false
                self:closeUIDark(function()
                    if self.m_isGameOver then
                        return
                    end
                    self:resetKenoNode()

                    self:playSelectTakeOrLeaveEffect(extra)
                end)

            end, delayTime + 30/60 + 60/60 + 55/60 + 0.3)
        end
    end)
end

-- 打开箱子之前 要 压暗 提层
function TakeOrStakeBonusGame:showDarkAndChangeOrder(extra, func)
    self.m_TraiNodeList = {}
    local setNewParentFun = function(node)
        local nodeParent = node:getParent()
        node.m_oldPreX = node:getPositionX()
        node.m_oldPreY = node:getPositionY()
        node.m_oldParent = nodeParent
        node.m_oldZOrder = node:getZOrder()
        local pos = nodeParent:convertToWorldSpace(cc.p(node.m_oldPreX, node.m_oldPreY))
        pos = self:findChild("Node_box"):convertToNodeSpace(pos)

        util_changeNodeParent(self:findChild("Node_box"), node)
        node:setPosition(pos.x, pos.y)
        table.insert( self.m_TraiNodeList, node)
    end

    -- 选中的箱子 提层
    for boxId, boxMultiple in pairs(json.decode(extra)) do
        self:changeBoxAndPic(tonumber(boxMultiple.player)+1, false)
        setNewParentFun(self.m_boxList[tonumber(boxMultiple.player)+1])
    end

    -- 左右灯牌 提层
    setNewParentFun(self.m_chengBeiZuo )
    setNewParentFun(self.m_chengBeiYou)

    -- 下面八个玩家头像
    for i,vNode in ipairs(self.m_playerItems) do
        setNewParentFun(vNode)
    end
    
    -- 触发玩家选中的箱子 提层
    setNewParentFun(self.m_chengBeiSelectTaiZi)

    self:showUIDark(func, true)
end

-- 还原已经提层的节点
function TakeOrStakeBonusGame:resetKenoNode()
    for i,node in ipairs(self.m_TraiNodeList) do
        util_changeNodeParent(node.m_oldParent, node, node.m_oldZOrder)
        node:setPosition(node.m_oldPreX, node.m_oldPreY)
        node.m_oldPreX = nil
        node.m_oldPreY = nil
        node.m_oldParent = nil
        node.m_oldZOrder = nil
    end
    self.m_TraiNodeList = {}
end

-- 开箱子的时候 播放左右两边 成倍的 相关动画
function TakeOrStakeBonusGame:playZuoAndYouChengBeiEffect(boxMultiple, node)

    local roomData = self.m_machine.m_roomDataClone
    local extra = roomData.extra
    if extra and extra.multiples then
        for i,v in ipairs(extra.multiples) do
            if v == boxMultiple then
                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_chengbei_close)

                self.m_chengBeiList[i]:runCsbAction("actionframe2",false,function()
                    -- 渐隐效果
                    util_nodeFadeIn(node, 0.5, 255, 0, nil, function()
                        node:setVisible(false)
                        node.isShow = false -- 是否显示
                        node.boxMultiple:runCsbAction("idle",false)
                        node.multipleInfo:runCsbAction("idle",false)
                    end)
                end)
            end
        end
    end
end

-- 箱子打开之后 开始进行 take/ leave 相关操作的界面动画
function TakeOrStakeBonusGame:playSelectTakeOrLeaveEffect(extra)
    if self.m_isGameOver then
        return
    end
    
    if not extra.selected then
        return
    end

    if #extra.selected >= 23 then
        self.m_takeJinBiTaiZi:findChild("zi"):setVisible(false)
        self.m_takeJinBiTaiZi:findChild("zi2"):setVisible(true)
    else
        self.m_takeJinBiTaiZi:findChild("zi"):setVisible(true)
        self.m_takeJinBiTaiZi:findChild("zi2"):setVisible(false)
    end
    self.m_takeJinBiTaiZi:setVisible(true)
    self.m_takeYingQianBanZi:setVisible(true)
    self.m_takeYingQianBanZi:runCsbAction("idle", true)
    
    self.m_takeJinBiTaiZi:findChild("m_lb_num"):setString(util_formatCoins(extra.offer, 50) .. "X")
    self.m_takeYingQianBanZi:findChild("m_lb_num"):setString(util_formatCoins(extra.offer,50))
    self.m_takeYingQianBanZi:findChild("m_lb_coins1"):setString(util_formatCoins(extra.score == 0 and 1 or extra.score,50))
    self.m_takeYingQianBanZi:findChild("m_lb_coins2"):setString(util_formatCoins(extra.offer*(extra.score == 0 and 1 or extra.score),50))
    self:updateLabelSize({label=self.m_takeYingQianBanZi:findChild("m_lb_coins1"),sx=0.46,sy=0.5}, 340)
    self:updateLabelSize({label=self.m_takeYingQianBanZi:findChild("m_lb_coins2"),sx=0.66,sy=0.68}, 634)

    self.m_takeBtn:setVisible(false)
    self.m_leaveBtn:setVisible(false)
    self.m_jiaoSeJieSuan:setVisible(false)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_taizi_qiehuan)

    self.m_takeJinBiTaiZi:runCsbAction("switch", false, function()
        
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_taizi_coin_chuxian)
        self.m_takeJinBiTaiZi:runCsbAction("start", false, function()
            performWithDelay(self.m_gameOver_action, function()
                if extra.offerUp and not extra.offerSuper then
                    self:showOfferBoost(extra,function()
                        self:showUpdateUIByTakeOrLeaveBtn(extra,false)
                    end)
                end
    
                if not extra.offerUp and extra.offerSuper then
                    self:showSurpriseOffer(extra,function()
                        self:showUpdateUIByTakeOrLeaveBtn(extra,false)
                    end)
                end
    
                if extra.offerUp and extra.offerSuper then
                    self:showOfferBoost(extra, function()
                        self:showSurpriseOffer(extra,function()
                            self:showUpdateUIByTakeOrLeaveBtn(extra,false)
                        end)
                    end)
                end
    
                if not extra.offerUp and not extra.offerSuper then
                    self:showUpdateUIByTakeOrLeaveBtn(extra,true)
                end
            end, 1)
        end)
    end)
    self.m_chengBeiTaiZi:runCsbAction("over", false)
end

-- 显示 点击take/leave 按钮 之后的刷新
function TakeOrStakeBonusGame:showUpdateUIByTakeOrLeaveBtn(extra,isPlay,isDuanXian)
    if self.m_isGameOver then
        return
    end
    -- 倒计时弹板出现之后 这个后续不走了 防止显示错误
    if self.m_isCanUpdataTime then
        self.m_pickEffectStop = true
        self.m_isFirstPickResult1 = false
        self.m_isFirstPickResult2 = false
        self.m_isFirstPickResult3 = false
        self.m_isCanUpdataTime1 = true
        self.m_isCanClick = true
        return
    end

    self.m_takeYingQianBanZi:findChild("m_lb_num"):setString(util_formatCoins(extra.offerFinal,50))
    self.m_takeYingQianBanZi:findChild("m_lb_coins1"):setString(util_formatCoins(extra.score == 0 and 1 or extra.score,50))
    self:updateLabelSize({label=self.m_takeYingQianBanZi:findChild("m_lb_coins1"),sx=0.46,sy=0.5}, 340)

    if isDuanXian then
        self.m_takeYingQianBanZi:runCsbAction("idle", true)
    else
        self.m_takeYingQianBanZi:runCsbAction("actionframe2", false, function()
            self.m_takeYingQianBanZi:runCsbAction("idle", true)
        end)
    end

    if extra.previousOffer and #extra.previousOffer > 0 then
        -- 历史记录
        self.m_liShiJiLuBanZi:setVisible(true)
        for i,v in ipairs(extra.previousOffer) do
            self.m_liShiJiLuBanZi:findChild("m_lb_num"..i):setString(v .. "X")
        end

        if isDuanXian then
            self.m_liShiJiLuBanZi:runCsbAction("idle", true)
        else
            self.m_liShiJiLuBanZi:runCsbAction("start", false, function()
                self.m_liShiJiLuBanZi:runCsbAction("idle", true)
            end)
        end
    end

    if not isDuanXian then
        self:runCsbAction("over2", false)
    end
    
    self.m_takeBtn:setVisible(true)
    if tonumber(extra.optionExpire) > TAKE_LEFTTIME then
        self:showBtnTakeOrLevel(false)
    else
        self:showBtnTakeOrLevel(true)
    end
    
    if isDuanXian then
        self.m_takeBtn:runCsbAction("idle", true)
        self.m_pickEffectStop = true
        self.m_isFirstPickResult1 = false
        self.m_isFirstPickResult2 = false
        self.m_isFirstPickResult3 = false
    else
        self.m_takeBtn:runCsbAction("start", false, function()
            self.m_takeBtn:runCsbAction("idle", true)
            self.m_pickEffectStop = true
            self.m_isFirstPickResult1 = false
            self.m_isFirstPickResult2 = false
            self.m_isFirstPickResult3 = false
        end)
    end

    self.m_leaveBtn:setVisible(true)
    self.m_isCanUpdataTime1 = true
    local leftTime = extra.optionExpireAt - globalData.userRunData.p_serverTime
    leftTime = math.floor(leftTime / 1000)
    if leftTime < 0 then
        leftTime = 0
    end
    -- util_count_down_str
    self.m_leaveBtn:findChild("m_lb_tim1"):setString(util_count_down_str1(leftTime))
    if isDuanXian then
        self.m_leaveBtn:runCsbAction("idle", true)
        self.m_isCanClick = true
    else
        self.m_leaveBtn:runCsbAction("start", false, function()
            self.m_leaveBtn:runCsbAction("idle", true)
            self.m_isCanClick = true
        end)
    end
    if self:getPlayerIsClickTake(extra) then
        self:showBtnTakeOrLevel(false)
    end

    if #extra.selected >= 23 then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_select_take_level_last)
    else
        local random = math.random(1,2)
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig["sound_TakeOrStake_shejiao_select_take_level"..random])
    end

    self.m_jiaoSeJieSuan:setVisible(true)
    if isDuanXian then
        util_spinePlay(self.m_jiaoSeJieSuan, "jiesuan_idle", true)
    else
        util_spinePlay(self.m_jiaoSeJieSuan, "jiesuan_start", false)
        util_spineEndCallFunc(self.m_jiaoSeJieSuan, "jiesuan_start", function()
            util_spinePlay(self.m_jiaoSeJieSuan, "jiesuan_idle", true)
        end)
    end

    self.m_jueseGuang = util_createAnimation("TakeOrStake_tanban_guang.csb")
    self.m_takeJinBiTaiZi:findChild("Node_guang"):addChild(self.m_jueseGuang)
    util_setCascadeOpacityEnabledRescursion(self.m_takeJinBiTaiZi:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(self.m_takeJinBiTaiZi:findChild("Node_guang"), true)
    self.m_jueseGuang:runCsbAction("idle", true)
    self.m_takeJinBiTaiZi:runCsbAction("start2", false)

    if isPlay then
        local myCoin = extra.offerFinal * (extra.score == 0 and 1 or extra.score)
        self:jumpCoinsChengBei(myCoin, 0, self.m_takeYingQianBanZi:findChild("m_lb_coins2"), 2)
    end
end

-- 玩家如果 点击过take 按钮 则后续的点击按钮 都不可以操作了
function TakeOrStakeBonusGame:getPlayerIsClickTake(extra)
    if extra.overTake then
        return true
    else
        return false
    end
end

-- take /leave 阶段 出发了offer boost
function TakeOrStakeBonusGame:showOfferBoost(extra, func)
    if self.m_isGameOver then
        return
    end
    -- offer boost界面
    local offerBoostView = util_createAnimation("TakeOrStake_OfferBoost.csb")
    self.m_takeJinBiTaiZi:findChild("Node_tanban"):addChild(offerBoostView)

    local offerBoostGuang = util_createAnimation("TakeOrStake_tanban_guang.csb")
    self.m_takeJinBiTaiZi:findChild("Node_guang"):addChild(offerBoostGuang)
    util_setCascadeOpacityEnabledRescursion(self.m_takeJinBiTaiZi:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(self.m_takeJinBiTaiZi:findChild("Node_guang"), true)

    offerBoostGuang:runCsbAction("idle", true)

    self.m_takeJinBiTaiZi:runCsbAction("start2", false)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_boostOffer)

    offerBoostView:runCsbAction("start", false, function()
        self.m_takeJinBiTaiZi:runCsbAction("over2", false, function()
            offerBoostGuang:removeFromParent()
        end)

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_boostOffer_add)

        offerBoostView:runCsbAction("over", false, function()
            offerBoostView:removeFromParent()

            self.m_takeJinBiTaiZi:runCsbAction("actionframe", false, function()
                
            end)
            self:jumpCoins(extra.offerUp, extra.offer, self.m_takeJinBiTaiZi:findChild("m_lb_num"), 1)
            performWithDelay(self.m_gameOver_action, function()
                self.m_takeYingQianBanZi:findChild("m_lb_num"):setString(util_formatCoins(extra.offerUp, 50))
                self.m_takeYingQianBanZi:findChild("m_lb_coins1"):setString(util_formatCoins(extra.score == 0 and 1 or extra.score, 50))
                self:updateLabelSize({label=self.m_takeYingQianBanZi:findChild("m_lb_coins1"),sx=0.46,sy=0.5}, 340)
                self.m_takeYingQianBanZi:runCsbAction("actionframe2", false, function()
                    self.m_takeYingQianBanZi:runCsbAction("idle", true)
                    if func then
                        func()
                    end
                end)
            
                local myCoin = extra.offerUp * (extra.score == 0 and 1 or extra.score)
                self:jumpCoinsChengBei(myCoin, 0, self.m_takeYingQianBanZi:findChild("m_lb_coins2"), 2)
            end, 1)
        end)
    end)
end

function TakeOrStakeBonusGame:jumpCoinsChengBei(coins, _curCoins, node, time)
    local curCoins    = _curCoins or 0
    -- 每秒60帧
    local coinRiseNum =  (coins - _curCoins) / (0.5 * 60)  

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 
    
    self:stopUpDateCoinsChengBei()

    self.m_soundIdChengBei = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_taizi_coin_up)

    self.m_updateAction1 = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < coins and curCoins or coins
        
        local sCoins = util_formatCoins(curCoins, 50)
        local label  = node
        label:setString(sCoins .. "X")
        if time == 2 then
            self:updateLabelSize({label=label,sx=0.66,sy=0.68}, 634)
        else
            self:updateLabelSize({label=label,sx=1.02,sy=1}, 223)
        end

        if curCoins >= coins then
            if self.m_soundIdChengBei then
                gLobalSoundManager:stopAudio(self.m_soundIdChengBei)
                self.m_soundIdChengBei = nil
            end
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_taizi_coin_down)
            self:stopUpDateCoinsChengBei()
        end
    end,0.008)
end

function TakeOrStakeBonusGame:stopUpDateCoinsChengBei()
    if self.m_updateAction1 then
        self:stopAction(self.m_updateAction1)
        self.m_updateAction1 = nil
    end
end

function TakeOrStakeBonusGame:jumpCoins(coins, _curCoins, node, time)
    local curCoins    = _curCoins or 0
    -- 每秒60帧
    local coinRiseNum =  (coins - _curCoins) / (0.5 * 60)  

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 
    
    self:stopUpDateCoins()

    -- self.m_soundId = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_taizi_coin_up)

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < coins and curCoins or coins
        
        local sCoins = util_formatCoins(curCoins, 50)
        local label  = node
        label:setString(sCoins .. "X")
        if time == 2 then
            self:updateLabelSize({label=label,sx=0.66,sy=0.68}, 634)
        else
            self:updateLabelSize({label=label,sx=1.02,sy=1}, 223)
        end

        if curCoins >= coins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            -- gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_taizi_coin_down)
            self:stopUpDateCoins()
        end
    end,0.008)
end

function TakeOrStakeBonusGame:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
    end
end

-- take /leave 阶段 出发了SurpriseOffer
function TakeOrStakeBonusGame:showSurpriseOffer(extra, func)
    if self.m_isGameOver then
        return
    end
    -- SurpriseOffer界面
    local surpriseOfferView = util_createAnimation("TakeOrStake_SurpriseOffer.csb")
    self.m_takeJinBiTaiZi:findChild("Node_tanban"):addChild(surpriseOfferView)
    local surpriseOfferGuang = util_createAnimation("TakeOrStake_tanban_guang.csb")
    self.m_takeJinBiTaiZi:findChild("Node_guang"):addChild(surpriseOfferGuang)
    util_setCascadeOpacityEnabledRescursion(self.m_takeJinBiTaiZi:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(self.m_takeJinBiTaiZi:findChild("Node_guang"), true)

    surpriseOfferGuang:runCsbAction("idle", true)
    self.m_takeJinBiTaiZi:runCsbAction("start2", false)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_surpriseOffer)

    surpriseOfferView:runCsbAction("start", false, function()
        
        local nodeId = self:getChengBeiNodeId(extra, extra.offerSuper[1])
        self.m_chengBeiList[nodeId]:runCsbAction("actionframe2",false,function()
            self:surpriseOfferTuoWei(extra,function()
                self.m_takeJinBiTaiZi:runCsbAction("over2", false, function()
                    surpriseOfferGuang:removeFromParent()
                end)

                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_surpriseOffer_add)

                surpriseOfferView:runCsbAction("over", false, function()
                    surpriseOfferView:removeFromParent()

                    self.m_takeJinBiTaiZi:runCsbAction("actionframe", false, function()
                        
                    end)
                    local lastOffer = extra.offer
                    if extra.offerUp then
                        lastOffer = extra.offerUp
                    end
                    self:jumpCoins(extra.offerSuper[3], lastOffer, self.m_takeJinBiTaiZi:findChild("m_lb_num"), 1)

                    performWithDelay(self.m_gameOver_action, function()
                        self.m_takeYingQianBanZi:findChild("m_lb_num"):setString(util_formatCoins(extra.offerSuper[3],50))
                        self.m_takeYingQianBanZi:findChild("m_lb_coins1"):setString(util_formatCoins(extra.score,50))
                        self:updateLabelSize({label=self.m_takeYingQianBanZi:findChild("m_lb_coins1"),sx=0.46,sy=0.5}, 340)
                        self.m_takeYingQianBanZi:runCsbAction("actionframe2", false, function()
                            self.m_takeYingQianBanZi:runCsbAction("idle", true)
                            if func then
                                func()
                            end
                        end)
                    
                        local myCoin = extra.offerSuper[3] * (extra.score == 0 and 1 or extra.score)
                        local myLastCoin = extra.offerUp and extra.offerUp * (extra.score == 0 and 1 or extra.score) or 0
                        self:jumpCoinsChengBei(myCoin, myLastCoin, self.m_takeYingQianBanZi:findChild("m_lb_coins2"), 2)
                    end, 1)
                end)
            end)
        end)
    end)
end

-- 根据数据 获得左右两遍乘倍几点ID
function TakeOrStakeBonusGame:getChengBeiNodeId(extra, chengbei)
    for i,v in ipairs(extra.multiples) do
        if v == chengbei then
            return i
        end
    end
end

-- SurpriseOffer界面 拖尾飞
function TakeOrStakeBonusGame:surpriseOfferTuoWei(extra, func)
    local startId = self:getChengBeiNodeId(extra, extra.offerSuper[1])
    local endId = self:getChengBeiNodeId(extra, extra.offerSuper[2])

    local startPos = util_convertToNodeSpace(self.m_chengBeiList[startId],self:findChild("Node_tanban"))
    local endPos = util_convertToNodeSpace(self.m_chengBeiList[endId],self:findChild("Node_tanban"))

    local tuoWeiFlyNode = util_createAnimation("TakeOrStake_tuowei.csb")
    self:findChild("Node_tanban"):addChild(tuoWeiFlyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    tuoWeiFlyNode:setPosition(startPos)

    tuoWeiFlyNode:findChild("Particle_1"):setDuration(1)     --设置拖尾时间(生命周期)
    tuoWeiFlyNode:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾

    local actList = {}
    actList[#actList + 1]  = cc.MoveTo:create(0.5,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        performWithDelay(self.m_gameOver_action, function()
            tuoWeiFlyNode:removeFromParent()
        end, 1)

        local actionframeName = "start"
        if extra.offerSuper[2] >= 500 then
            actionframeName = "start2"
            self.m_chengBeiList[endId]:findChild("glow1"):setColor(cc.c3b(255, 189, 48))
            self.m_chengBeiList[endId]:findChild("glow2"):setColor(cc.c3b(255, 189, 48))
        else
            self.m_chengBeiList[endId]:findChild("glow1"):setColor(cc.c3b(48, 183, 255))
            self.m_chengBeiList[endId]:findChild("glow2"):setColor(cc.c3b(48, 183, 255))
        end
    
        self.m_chengBeiList[endId]:runCsbAction(actionframeName,false,function()
            if func then
                func()
            end
        end)
    end)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_surpriseOffer_fly)

    tuoWeiFlyNode:runAction(cc.Sequence:create(actList))
end

-- 玩法结束 结算流程
function TakeOrStakeBonusGame:showWinJieSuanView(data)
    -- 打来弹板遮罩
    self:showUIDark(nil, false)
                            
    self.m_yinDaoTanBan:setVisible(true)
    local function closeNode( )
        local nodeName = {"Node_StartPicking", "Node_PrizeChosen", "Node_StartOpening", "Node_LastCaseOpen", "Node_OnlyOneHides1000", "Node_AllPlayersWin"}
        for k,vName in pairs(nodeName) do
            self.m_yinDaoTanBan:findChild(vName):setVisible(false)
        end
    end
    
    closeNode()

    self.m_TraiNodeList = {}
    
    local setNewParentFun = function(node)
        local nodeParent = node:getParent()
        node.m_oldPreX = node:getPositionX()
        node.m_oldPreY = node:getPositionY()
        node.m_oldParent = nodeParent
        node.m_oldZOrder = node:getZOrder()
        local pos = nodeParent:convertToWorldSpace(cc.p(node.m_oldPreX, node.m_oldPreY))
        pos = self:findChild("Node_box"):convertToNodeSpace(pos)

        util_changeNodeParent(self:findChild("Node_box"), node)
        node:setPosition(pos.x, pos.y)
        table.insert( self.m_TraiNodeList, node)
    end

    setNewParentFun(self.m_chengBeiSelectTaiZi)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_tanban_last)

    self.m_yinDaoTanBan:findChild("Node_LastCaseOpen"):setVisible(true)
    self.m_yinDaoTanBan:runCsbAction("start",false,function()
        self.m_yinDaoTanBan:runCsbAction("idle",false)
        performWithDelay(self.m_gameOver_action, function()
            self:closeUIDark()

            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_tanban_last_close)

            self.m_yinDaoTanBan:runCsbAction("over",false,function()
                self:resetKenoNode()
                if self.m_isGameOver then
                    return
                end
                self:openLastBox(data)
            end)
            util_spinePlay(self.m_jiaoSe, "shejiao_tanban_over", false)
            util_spineEndCallFunc(self.m_jiaoSe, "shejiao_tanban_over", function()
                self.m_jiaoSe:setVisible(false)
            end)
        end, 1)
    end)

    -- 角色
    self.m_jiaoSe:setVisible(true)
    util_spinePlay(self.m_jiaoSe, "shejiao_tanban_start", false)
    util_spineEndCallFunc(self.m_jiaoSe, "shejiao_tanban_start", function()
        util_spinePlay(self.m_jiaoSe, "shejiao_idle", false)
    end)
end

-- 通过udid获得玩家 信息
function TakeOrStakeBonusGame:getPlayerInfoByUdid(udid, data)

    local playersInfo = {}

    local result = data.result

    -- 玩法触发后需要优先取触发座位的数据
    -- 因为房间数据内可能不包含触发玩法后立刻断线玩家的数据
    if data.sets then
        playersInfo = clone(data.sets)
    else
        if self.m_machine.m_roomList.m_roomData.m_teamData.room.result and self.m_machine.m_roomList.m_roomData.m_teamData.room.result.data then
            playersInfo = clone(self.m_machine.m_roomList.m_roomData.m_teamData.room.result.data.sets) or nil
        end
    end

    for _, _playersData in ipairs(playersInfo) do
        if _playersData.udid == udid then
            return _playersData
        end
    end
end

-- 打开最后的箱子
function TakeOrStakeBonusGame:openLastBox(data)
    self:openLastBoxViewChangeParent()
    self.m_jieSuanTanBan:setVisible(true)
    
    if data.overTake then
        self.m_backToSpinBtn:setVisible(true)
    else
        self.m_backToSpinBtn:setVisible(false)
    end

    self.m_jieSuanTanBan:findChild("m_lb_num1"):setString(data.bestOffer.."X")

    for _index = 1, 16 do
        self.m_jieSuanTanBan:findChild("Node_touxiangkuang_moren".._index):removeAllChildren(true)
        self.m_jieSuanTanBan:findChild("touxiang".._index):removeAllChildren(true)
    end

    local callBack = function(index, playerInfo)
        local frame = util_createAnimation("TakeOrStake_touxiangkuang_moren.csb")
        self.m_jieSuanTanBan:findChild("Node_touxiangkuang_moren"..index):addChild(frame)

        local isMe = (globalData.userRunData.userUdid == playerInfo.udid)
        if playerInfo.frame == "" or playerInfo.frame == nil then
            frame:findChild("Player"):setVisible(isMe)
            frame:findChild("Others"):setVisible(not isMe)
        else
            frame:findChild("Player"):setVisible(false)
            frame:findChild("Others"):setVisible(false)
        end

        local head = self.m_jieSuanTanBan:findChild("touxiang"..index)

        local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(playerInfo.facebookId, playerInfo.head, playerInfo.frame, nil, head:getContentSize())
        head:addChild(nodeAvatar)
        nodeAvatar:setPosition( head:getContentSize().width * 0.5, head:getContentSize().height * 0.5 )
    end

    if data.bestOfferPlayer then
        for _index, udid in ipairs(data.bestOfferPlayer) do
            local playerInfo = self:getPlayerInfoByUdid(udid, data)
            if playerInfo then
                callBack(_index, playerInfo)
            end
        end
    end

    if data.prizeOfferPlayer then
        for _index, udid in ipairs(data.prizeOfferPlayer) do
            local playerInfo = self:getPlayerInfoByUdid(udid,data) 
            if playerInfo then
                callBack(_index+8, playerInfo)
            end
        end
    end

    self.m_chengBeiZuo:runCsbAction("over",false)
    self.m_chengBeiYou:runCsbAction("over",false)
    self.m_chengBeiTaiZi:runCsbAction("over2",false)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_jiesuan_tanban)

    self.m_jieSuanTanBan:runCsbAction("start", false, function()
        self.m_jieSuanTanBan:runCsbAction("idle", false, function()
            self:openFirstSelectBox(data)
        end)
    end)
end

--[[
    结算的时候 打开 一开始选择的箱子
]]
function TakeOrStakeBonusGame:openFirstSelectBox(data)
    --首次选中的箱子 打开
    self.m_backToSpinBtn:setVisible(false)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_jiesuan_box_open)
    
    util_spinePlay(self.m_triPalyerBox, "actionframe", false)
    util_spineEndCallFunc(self.m_triPalyerBox, "actionframe", function()
        util_spinePlay(self.m_triPalyerBox, "idleframe1", true)
    end)
    
    self.m_triPalyerBox.boxMultiple:findChild("m_lb_coins"):setString(data.lockMultiple.."X")
    self.m_triPalyerBox.boxMultiple:runCsbAction("actionframe", false, function()
        self:openLastBoxFly(data.lockMultiple, function()
            if self.m_isGameOver then
                return
            end
            self.m_jieSuanTanBan:findChild("m_lb_num2"):setString(data.lockMultiple.."X")

            self.m_jieSuanTanBan:runCsbAction("actionframe", false, function()
                local actionFrameName = "actionframe3"
                if data.bestOffer > data.lockMultiple then
                    actionFrameName = "actionframe2"
                end

                gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_jiesuan_qingzhu)

                self.m_jieSuanTanBan:runCsbAction(actionFrameName, false, function()

                    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_jiesuan_tanban_close)

                    self.m_jieSuanTanBan:runCsbAction("over", false, function()
                        self:resetKenoNode()
                        self:runCsbAction("over",false,function()
                            self.m_triPalyerBox:setVisible(false)
                        end)
                        self.m_jieSuanTanBan:setVisible(false)

                        self:showOverView(data)
                    end)
                end)
            end)
        end)
    end)
end

-- 结算的时候 部分节点提层
function TakeOrStakeBonusGame:openLastBoxViewChangeParent( )
    self.m_TraiNodeList = {}
    
    local setNewParentFun = function(node)
        local nodeParent = node:getParent()
        node.m_oldPreX = node:getPositionX()
        node.m_oldPreY = node:getPositionY()
        node.m_oldParent = nodeParent
        node.m_oldZOrder = node:getZOrder()
        local pos = nodeParent:convertToWorldSpace(cc.p(node.m_oldPreX, node.m_oldPreY))
        pos = self:findChild("Node_box"):convertToNodeSpace(pos)

        util_changeNodeParent(self:findChild("Node_box"), node)
        node:setPosition(pos.x, pos.y)
        table.insert( self.m_TraiNodeList, node)
    end

    -- 下面八个玩家头像
    for i,vNode in ipairs(self.m_playerItems) do
        setNewParentFun(vNode)
    end

    setNewParentFun(self.m_chengBeiSelectTaiZi)
end

-- 打开最后的箱子 倍数飞
function TakeOrStakeBonusGame:openLastBoxFly(num, func)

    local startPos = util_convertToNodeSpace(self.m_triPalyerBox.boxMultiple,self:findChild("Node_tanban"))
    local endPos = util_convertToNodeSpace(self.m_jieSuanTanBan:findChild("number"),self:findChild("Node_tanban"))
    endPos.y = endPos.y - 37

    local numFlyNode = util_createAnimation("TakeOrStake_baoxiang_1.csb")
    self:findChild("Node_tanban"):addChild(numFlyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    numFlyNode:setPosition(startPos)
    numFlyNode:findChild("m_lb_coins"):setString(num .. "X")

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_jiesuan_chengbei_fly)

    numFlyNode:runCsbAction("fly", false)

    local actList = {}
    actList[#actList + 1]  = cc.MoveTo:create(1,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        
        numFlyNode:removeFromParent()

        if func then
            func()
        end
    end)

    numFlyNode:runAction(cc.Sequence:create(actList))
end

-- 玩家 选择take 按钮 之后 结算
function TakeOrStakeBonusGame:selectTakeOverView(extra)
    util_spinePlay(self.m_jiaoSeJieSuan, "jiesuan_qingzhu", false)
    util_spineEndCallFunc(self.m_jiaoSeJieSuan, "jiesuan_qingzhu", function()
        util_spinePlay(self.m_jiaoSeJieSuan, "jiesuan_idle", true)
    end)

    self.m_takeYingQianBanZi:findChild("Particle_1"):resetSystem()
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_take_click)

    self.m_takeYingQianBanZi:runCsbAction("actionframe", false, function()
        self.m_takeYingQianBanZi:runCsbAction("idle", true)
        self.m_clickTakeOverView:setVisible(true)
        local winCoins = self.m_machine.m_roomList.m_roomData:getMailWinCoins()
        self.m_clickTakeOverView:findChild("m_lb_coins"):setString(util_formatCoins(winCoins, 50))
        self:updateLabelSize({label=self.m_clickTakeOverView:findChild("m_lb_coins"),sx=1,sy=1}, 668)

        -- 暂停背景音乐
        gLobalSoundManager:setBackgroundMusicVolume(0)

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_take_click_jiesuan_tanban)

        self.m_clickTakeOverView:runCsbAction("start", false, function()
            self.m_backToSpinBtn:setVisible(true)
            self.m_clickTakeOverView:runCsbAction("idle", true)
            self.m_clickTakeOverView:findChild("Btn_collect"):setTouchEnabled(true)
        end)
    end)
end

-- 点击take 并且 结束游戏需要弹弹板
function TakeOrStakeBonusGame:clickTakeAndGameEnd( )
    -- 打来弹板遮罩
    self:showUIDark(nil, false)

    self.m_yinDaoTanBan:setVisible(true)
    local function closeNode( )
        local nodeName = {"Node_StartPicking", "Node_PrizeChosen", "Node_StartOpening", "Node_LastCaseOpen", "Node_OnlyOneHides1000", "Node_AllPlayersWin"}
        for k,vName in pairs(nodeName) do
            self.m_yinDaoTanBan:findChild(vName):setVisible(false)
        end
    end
    
    closeNode()

    self.m_yinDaoTanBan:findChild("Button_ShowMe"):setTouchEnabled(true)
    self.m_yinDaoTanBan:findChild("Button_BackSpin"):setTouchEnabled(true)

    self.m_yinDaoTanBan:findChild("Node_AllPlayersWin"):setVisible(true)
    self.m_yinDaoTanBan:runCsbAction("start",false,function()
        self.m_yinDaoTanBan:runCsbAction("idle",false)
        
    end)
end

return TakeOrStakeBonusGame