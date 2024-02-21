---
--smy
--2018年4月26日
--GirlsMagicBonusChoose.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local GirlsMagicBonusChoose = class("GirlsMagicBonusChoose", BaseGame)

local ACTION_SELECT = 1
local MAX_AUTO_TIME = 4 --最大自动选择时间

local BTN_ATG_PREVIOUS = 1001 --上一步
local BTN_TAG_NEXT = 1002 --下一步

local GUIDE_CHOOSE_SOUND = {
    "GirlsMagicSounds/sound_GirlsMagic_choose_color.mp3",
    "GirlsMagicSounds/sound_GirlsMagic_choose_accessory.mp3",
    "GirlsMagicSounds/sound_GirlsMagic_choose_pattern.mp3"
}

function GirlsMagicBonusChoose:initUI(params)
    self:createCsbNode("GirlsMagic/BonusChoose.csb")
    --主类对象
    self.m_machine = params.machine
    --是否可以接受消息
    self.isCanReceive = false
    self.m_isWaiting = false

    -- self:setScale(self.m_machine.m_machineRootScale)

    self.m_root_node = self:findChild("root")

    self.m_root_node:setVisible(false)

    --pad选择界面
    self.m_padView = util_createView("CodeGirlsMagicSrc.GirlsMagicBonusIpadView", {parent = self})
    local Node_ipad = self:findChild("Node_ipad")
    Node_ipad:removeAllChildren(true)
    Node_ipad:addChild(self.m_padView)

    self:findChild("Panel_3"):setVisible(false)

    --模型节点
    self.m_model_node = self:findChild("Node_model")
    self.m_model_node:removeAllChildren(true)
    --创建模特模型
    self.m_suitSpines = {}
    for index = 1, 3 do
        local spine = self.m_machine.m_spineManager:getChooseClothes(-1)
        self.m_suitSpines[index] = spine
        spine:setVisible(index == 1)

        local zOrder = index
        if index == 2 then
            zOrder = 10
        end
        self.m_model_node:addChild(spine, zOrder)
    end

    self.m_showAni = util_createView("CodeGirlsMagicSrc.GirlsMagicBonusShowChooseView", {parent = self, machine = self.m_machine})
    self:addChild(self.m_showAni)
    self.m_showAni:hideView()
    self.m_showAni:setPosition(self:findChild("root"):getPosition())

    self.m_btn_next = self:findChild("Button_NEXT")
    self.m_btn_ok = self:findChild("Button_OK")

    self.m_btn_next:setTag(BTN_TAG_NEXT)
    self.m_btn_ok:setTag(BTN_TAG_NEXT)
    self.m_btn_next:setVisible(true)
    self.m_btn_ok:setVisible(false)

    self:findChild("Sprite_1"):setVisible(false)
    self:showGuideWord(1)

    local node
end

function GirlsMagicBonusChoose:onEnter()
    BaseGame.onEnter(self)
end

function GirlsMagicBonusChoose:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_padView.m_isWaitting or self.m_isWaiting then
        return
    end

    if tag == BTN_ATG_PREVIOUS then --上一步
        if self.m_padView:getCurIndex() <= 1 then
            return
        end
        self.m_padView:changeCurStep(-1)
    else
        --当前还没有选择,不能进行下一步
        if not self.m_padView:isChoosed() then
            return
        end
        self.m_padView:changeCurStep(1)
    end

    local curIndex = self.m_padView:changeOption()

    self.m_btn_next:setVisible(curIndex < 3)
    self.m_btn_ok:setVisible(curIndex >= 3)

    --变更按钮状态
    self:changeBtnStatus(curIndex)

    if curIndex > 3 then
        self:chooseEnd()
    else
        self:showGuideWord(curIndex)
        self:runCsbAction(
            "change",
            false,
            function()
                self:runCsbAction("idle2")
            end
        )
    end
end

--[[
    重置pad
]]
function GirlsMagicBonusChoose:resetPadForRestart()
    self.m_padView:resetForRestart()
end

--[[
    变更按钮状态
]]
function GirlsMagicBonusChoose:changeBtnStatus(curIndex)
    local choose = self.m_padView:getChoosed()
    if not choose[curIndex] then
        self.m_btn_next:setTouchEnabled(false)
        self.m_btn_next:setBright(false)
        self.m_btn_ok:setTouchEnabled(false)
        self.m_btn_ok:setBright(false)
    else
        self.m_btn_next:setTouchEnabled(true)
        self.m_btn_next:setBright(true)
        self.m_btn_ok:setTouchEnabled(true)
        self.m_btn_ok:setBright(true)
    end
end

--[[
    显示界面
]]
function GirlsMagicBonusChoose:showView(isInit, func)
    --回调函数
    self.m_callBack = func
    self.m_machine:changeBg("choose")
    self.m_isWaiting = false
    self.m_machine.m_roomList:changeStatus(false)

    self.m_btn_next:setVisible(true)
    self.m_btn_ok:setVisible(false)

    self.m_padView:resetStatus()
    self.isCanReceive = false
    --变更按钮状态
    self:changeBtnStatus(1)

    self:setVisible(true)

    --显示空白模特
    for index = 1, 3 do
        local spine = self.m_suitSpines[index]
        spine:setVisible(index == 1)
        self.m_machine.m_spineManager:playClothesAni(spine, -1)
    end

    --隐藏轮盘
    self.m_machine:hideReel()
    --禁用按钮
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:pauseForIndex(0)

    -- gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_choose_show_pop_not_first.mp3")

    self.m_root_node:setVisible(true)
    if not isInit then
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_bonus_ipad_show.mp3")
    end

    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle1")
        end
    )

    self.m_machine:delayCallBack(
        0.5,
        function()
            self.m_padView:changeOption()
        end
    )
end

--[[
    展示上次选择衣服
]]
function GirlsMagicBonusChoose:showLastClothes(func)
    self.m_callBack = func
    self.m_isWaiting = false
    local choose = self.m_padView:getChoosed()
    if #choose == 0 then
        choose = self:loadChoose()
    end
    if #choose == 0 then
        return
    end
    self.m_showAni:showView(choose)
end

--[[
    隐藏上次选择衣服
]]
function GirlsMagicBonusChoose:hideLastClothes()
    self.m_isWaiting = true
    self.m_showAni:hideView()
end

function GirlsMagicBonusChoose:onExit()
    BaseGame.onExit(self)
end

--[[
    显示引导提示
]]
function GirlsMagicBonusChoose:showGuideWord(index)
    self:findChild("Tutorials_1"):setVisible(index == 1)
    self:findChild("Tutorials_2"):setVisible(index == 2)
    self:findChild("Tutorials_3"):setVisible(index == 3)
end

--[[
    关闭界面
]]
function GirlsMagicBonusChoose:closeView()
    --显示过场动画
    self.m_machine:closeCurtain(
        true,
        function()
            self.m_showAni:hideView()

            self.m_machine:onChooseEnd()
            self:setVisible(false)

            --重新刷新房间消息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)

            if type(self.m_callBack) == "function" then
                self.m_callBack()
                self.m_callBack = nil
            end
            self.m_machine:openCurtain(true)
        end
    )
end

--[[
    刷新界面
]]
function GirlsMagicBonusChoose:refreshView(isInit)
end

--[[
    选择结束
]]
function GirlsMagicBonusChoose:chooseEnd()
    self:showClothes()
end

function GirlsMagicBonusChoose:changeCloth(curIndex, curChoose)
    local spine = self.m_suitSpines[curIndex]
    spine:setVisible(true)
    self.m_machine.m_spineManager:playClothesAni(spine, curIndex, curChoose)
    self:changeBtnStatus(curIndex)
end

-------------------子类继承-------------------
--处理数据 子类可以继承改写
--:calculateData(featureData)
--子类调用
--:getZoomScale(width)获取缩放比例
--:isTouch()item是否可以点击
--:sendStep(pos)item点击回调函数
--.m_otherTime=1      --其他宝箱展示时间
--.m_rewardTime=3     --结算界面弹出时间

function GirlsMagicBonusChoose:initViewData(callBackFun, gameSecen)
    self:initData()
end

function GirlsMagicBonusChoose:resetView(featureData, callBackFun, gameSecen)
    self:initData()
end

function GirlsMagicBonusChoose:initData()
    self:initItem()
end

function GirlsMagicBonusChoose:initItem()
end

--数据发送
function GirlsMagicBonusChoose:sendData(choose)
    if self.loadAni or self.m_isWaiting or self.isCanReceive then
        return
    end

    self.m_action = self.ACTION_SEND
    --防止连续点击
    self.m_isWaiting = true

    self.isCanReceive = true
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_TEAM_MISSION_OPTION,
        choose = choose,
        action = 1
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
    self.m_machine:changeClothes(choose)
    self:saveChoose(choose)
end

function GirlsMagicBonusChoose:uploadCoins(featureData)
end

--[[
    展示选择的衣服
]]
function GirlsMagicBonusChoose:showClothes()
    local choose = self.m_padView:getChoosed()

    local node = cc.Node:create()
    --创建选择的衣服
    for index = 1, #choose do
        local spine = self.m_machine.m_spineManager:getChooseClothes(index, choose[index], false, true)
        node:addChild(spine)
        if index == 2 then
            spine:setLocalZOrder(10)
        else
            spine:setLocalZOrder(index)
        end
    end
    --创建展示动画
    local ani = util_createAnimation("GirlsMagic_YourDress.csb")
    self:addChild(ani)
    ani:setPosition(self:findChild("root"):getPosition())
    ani:findChild("Node_ren"):addChild(node)

    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_show_my_clothes.mp3")
    ani:runCsbAction(
        "start",
        false,
        function()
            ani:runCsbAction("idle", true)
            self:sendData(choose)
            performWithDelay(
                ani,
                function()
                    ani:removeFromParent(true)
                end,
                1
            )
        end
    )
end

--数据接收
function GirlsMagicBonusChoose:recvBaseData()
    self.m_action = self.ACTION_RECV
    self.isCanReceive = false
    self:closeView()
    self.m_machine:startConutDown()
end

function GirlsMagicBonusChoose:sortNetData(data)
    -- 服务器非得用这种结构 只能本地转换一下结构
    local localdata = {}
    if data.bonus then
        if data.bonus then
            data.choose = data.bonus.choose
            data.content = data.bonus.content
            data.extra = data.bonus.extra
            data.status = data.bonus.status
        end
    end

    localdata = data

    return localdata
end

--[[
    接受网络回调
]]
function GirlsMagicBonusChoose:featureResultCallFun(param)
    if self.isCanReceive then
        if param[1] == true then
            self:recvBaseData()
        else
            -- 处理消息请求错误情况
        end
    end
end

--[[
    存储当前选择
]]
function GirlsMagicBonusChoose:saveChoose(choose)
    local chooseID = choose[1] * 100 + choose[2] * 10 + choose[3]
    gLobalDataManager:setNumberByField("GirlsMagicChoose", chooseID, true)
end

--[[
    读取当前选择
]]
function GirlsMagicBonusChoose:loadChoose()
    local chooseID = gLobalDataManager:getNumberByField("GirlsMagicChoose", 0)
    local choose = {}
    if chooseID ~= 0 then
        choose[1] = math.floor(chooseID / 100)
        choose[2] = math.floor((chooseID % 100) / 10)
        choose[3] = chooseID % 10
        --数据范围安全判定
        if choose[1] < 1 or choose[1] > 4 then
            choose[1] = 1
        end
        if choose[2] < 1 or choose[2] > 3 then
            choose[2] = 1
        end
        if choose[3] < 1 or choose[3] > 2 then
            choose[3] = 1
        end
    end

    return choose
end
return GirlsMagicBonusChoose
