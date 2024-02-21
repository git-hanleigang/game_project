--[[
Author: cxc
Date: 2021-11-23 20:14:51
LastEditTime: 2021-11-23 20:14:52
LastEditors: your name
Description: 乐透选号界面
FilePath: /SlotNirvana/src/views/lottery/choose/LotteryChooseNumberLayer.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryChooseNumberLayer = class("LotteryChooseNumberLayer", BaseLayer)

function LotteryChooseNumberLayer:ctor()
    LotteryChooseNumberLayer.super.ctor(self)
    self:setPauseSlotsEnabled(true) 
    self:setExtendData("LotteryChooseNumberLayer")

    if "f8aa2478-3884-364d-978f-c209ff4aa392:SlotNewCashLink" == globalData.userRunData.userUdid then
        if not util_IsFileExist("Lottery/csd/Choose/Lottery_Choose_heng.csb") then
            -- 这货 怎么老判断 这个功能下载完能玩的啊？ Android 11,level 30  Sky_Devices/X8A1
            gLobalDataManager:setVersion("dy_" .. "Lottery", nil)
        end
    end
    self:setLandscapeCsbName("Lottery/csd/Choose/Lottery_Choose_heng.csb")
    self:setPortraitCsbName("Lottery/csd/Choose/Lottery_Choose_shu.csb")
end

function LotteryChooseNumberLayer:initDatas()
    LotteryChooseNumberLayer.super.initDatas(self)
    
    self.m_data = G_GetMgr(G_REF.Lottery):getData()

    self.m_bMachine = false -- 是否是机选号码
    self.m_chooseNumberList = G_GetMgr(G_REF.Lottery):getChooseNumberList() 
end

function LotteryChooseNumberLayer:initCsbNodes()
    self.m_lbDate = self:findChild("lb_riqi")
    self.m_btnRandom = self:findChild("btn_random")
    self.m_btnDececlect = self:findChild("btn_dececlect")
end

-- 创建 可选的球
function LotteryChooseNumberLayer:createChooseBallItem(_number, _bRed)
    local view = util_createView("views.lottery.choose.LotteryChooseBall", {number = _number, bRed = _bRed})
    view:setName("node_choose_ball")
    return view
end

function LotteryChooseNumberLayer:initView()
    -- 日期
    self:initTimeUI()

    -- 白球
    for idx=1, 30 do
        local item = self:createChooseBallItem(idx, false)
        local parent = self:findChild("node_white_" .. idx)
        parent:addChild(item)
    end
    -- 红球
    for idx=1, 9 do
        local item = self:createChooseBallItem(idx, true)
        local parent = self:findChild("node_red_" .. idx)
        parent:addChild(item)
    end

    -- 初始化 已选球的列表
    self:initChooseNumberUI()

    -- 初始化okBtn
    self:initOkBtnUI()

    -- 更新按钮显示状态
    self:updateBtnState()
end

-- 初始化 已选球的列表UI
function LotteryChooseNumberLayer:initChooseNumberUI()
    local parent = self:findChild("node_show")
    local view = util_createView("views.lottery.choose.LotterChooseNumberListView")
    parent:addChild(view)
    self.m_nodeChooseNumerList = view
end

-- 初始化okBtn
function LotteryChooseNumberLayer:initOkBtnUI()
    local parent = self:findChild("node_ok")
    local view = util_createView("views.lottery.choose.LotteryChooseOKBtn")
    parent:addChild(view)
    self.m_btnOK = view
end

-- 更新按钮显示状态
function LotteryChooseNumberLayer:updateBtnState(_bMachine)
    self.m_bMachine = _bMachine -- 是否是机选号码
    local bCanCancel = G_GetMgr(G_REF.Lottery):checkCanCancelChooseList()

    self.m_btnRandom:setVisible(not bCanCancel)
    self.m_btnDececlect:setVisible(bCanCancel)

    self.m_btnOK:updateBtnState(self.m_bMachine)
end

function LotteryChooseNumberLayer:initTimeUI()
    local days = util_leftDays(self.m_data:getEndChooseTimeAt())
    if days < 1 then
        self:updateLeftTimeUI()
        self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
        return
    end

    self.m_lbDate:setString(self.m_data:getEndDataStr())
end

function LotteryChooseNumberLayer:updateLeftTimeUI()
    local leftTimeStr, bOver = util_daysdemaining(self.m_data:getEndChooseTimeAt())
    self.m_lbDate:setString(leftTimeStr)
    if bOver then
        self:clearScheduler()
        self:closeUI()
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CLOSE_CHOOSE_NUMBER_OTHER_LAYER) --时间结束关闭弹板
        G_GetMgr(G_REF.Lottery):showTimeOutTipLayer() 
    end

end

function LotteryChooseNumberLayer:onShowedCallFunc()
    LotteryChooseNumberLayer.super.onShowedCallFunc(self)

    self:dealGuideLogic()
end

function LotteryChooseNumberLayer:clickFunc(sender)
    local name = sender:getName()
    
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" then
        local bCanSyncNumber = G_GetMgr(G_REF.Lottery):checkCanSyncNumberList()
        G_GetMgr(G_REF.Lottery):showChooseNumberTipLayer(not bCanSyncNumber or self.m_bMachine)
    elseif name == "btn_shuoming" then
        G_GetMgr(G_REF.Lottery):showMainLayer()

        -- G_GetMgr(G_REF.Lottery):showFAQView() 
    elseif name == "btn_dececlect" then
        self:cancelAllChooseNumber()
    elseif name == "btn_random" then
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.GUIDE_FINAL_STEP)
        G_GetMgr(G_REF.Lottery):sendGenerateRanNumber()
    end
end

-- 选择球
-- _params = {number=int, bRed=bool}
function LotteryChooseNumberLayer:chooseNumberEvt(_params)
    self.m_nodeChooseNumerList:chooseNumberEvt(_params)
    self.m_chooseNumberList = G_GetMgr(G_REF.Lottery):getChooseNumberList()
    self:updateBtnState()
end

-- 取消 选择球
function LotteryChooseNumberLayer:cancelChooseNumberEvt(_params)
    self.m_nodeChooseNumerList:cancelChooseNumberEvt(_params)
    self.m_chooseNumberList = G_GetMgr(G_REF.Lottery):getChooseNumberList()
    self:updateBtnState()
end

-- 取消 所有选择的球
function LotteryChooseNumberLayer:cancelAllChooseNumber()
    self.m_nodeChooseNumerList:cancelAllChooseNumber()
    self.m_chooseNumberList = G_GetMgr(G_REF.Lottery):getChooseNumberList()
    self:updateBtnState()
end

-- 服务器生成随机号码成功
function LotteryChooseNumberLayer:generateRanNumberEvt()
    self.m_chooseNumberList = G_GetMgr(G_REF.Lottery):getChooseNumberList() 
    
    self.m_nodeChooseNumerList:generateRanNumberEvt()

    for idx=1, #self.m_chooseNumberList do
        local number = self.m_chooseNumberList[idx]

        -- 白球
        if idx < #self.m_chooseNumberList then
            for idx=1, 30 do
                local parent = self:findChild("node_white_" .. idx)
                local item = parent:getChildByName("node_choose_ball")
                item:generateRanNumberEvt(number)
            end
        end
        
        -- 红球
        if idx == #self.m_chooseNumberList then
            for idx=1, 9 do
                local parent = self:findChild("node_red_" .. idx)
                local item = parent:getChildByName("node_choose_ball")
                item:generateRanNumberEvt(number)
            end
        end

    end
    self:updateBtnState(true)
end

-- 关闭
function LotteryChooseNumberLayer:closeUI()
    local cb = function()
        G_GetMgr(G_REF.Lottery):resumeChooseNumberCoroutine()
    end

    LotteryChooseNumberLayer.super.closeUI(self, cb)
end

function LotteryChooseNumberLayer:registerListener()
    LotteryChooseNumberLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "closeUI", LotteryConfig.EVENT_NAME.RECIEVE_SYNC_CHOOSE_NUMBER) --跟服务器同步号码成功
    gLobalNoticManager:addObserver(self, "closeUI", LotteryConfig.EVENT_NAME.TIME_END_CLOSE_CHOOSE_NUMBER_CODE) --选号时间结束关闭选号功能
    gLobalNoticManager:addObserver(self, "generateRanNumberEvt", LotteryConfig.EVENT_NAME.RECIEVE_GENERATE_RANDOM_NUMBER) --服务器生成随机号码成功

    gLobalNoticManager:addObserver(self, "chooseNumberEvt", LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_SELECT) --选择号码 _选择
    gLobalNoticManager:addObserver(self, "cancelChooseNumberEvt", LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_CANCEL) --选择号码 _取消选择

    gLobalNoticManager:addObserver(
        self,
        function(target, loop)
            self.m_nodeChooseNumerList:playShowAct(loop)
        end,
        LotteryConfig.EVENT_NAME.GUIDE_EFFECT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, loop)
            self.m_nodeChooseNumerList:playIdleAct()
        end,
        LotteryConfig.EVENT_NAME.GUIDE_EFFECT_STOP
    )

end

function LotteryChooseNumberLayer:clearScheduler()
    if self.m_leftTimeScheduler then
        self:stopAction(self.m_leftTimeScheduler)
        self.m_leftTimeScheduler = nil
    end
end

-- 新手引导
function LotteryChooseNumberLayer:dealGuideLogic()
    if tolua.isnull(self) then
        return
    end
    
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.lotteryChooseNumber.id) -- 第一次进入公会主页
    if bFinish then
        return
    end

    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.lotteryChooseNumber)


    local nodeContent = self:findChild("node_ball_choose") -- 号码内容UI
    local nodeChooseNumber = self:findChild("node_show") -- 号码展示UI
    local nodeBtnRandom = self:findChild("node_random") -- 随机选号按钮
    local guideNodeList = {nodeContent, nodeChooseNumber, nodeBtnRandom}

    local npcGuideNodeList = {}
    for i=1, 3 do

        local guideNode = self:findChild("node_guide_" .. i)
        if not tolua.isnull(guideNode) then
            -- table.insert(npcGuideNodeList, guideNode)
            npcGuideNodeList[i] = guideNode
        end
        
    end

    local scale = self:findChild("root"):getScale()
    G_GetMgr(G_REF.Lottery):showGuideLayer(guideNodeList, npcGuideNodeList, scale)
end

return LotteryChooseNumberLayer