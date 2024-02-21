--[[
Author: your name
Date: 2021-11-26 10:34:45
LastEditTime: 2021-11-26 10:34:46
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/choose/LotterChooseNumberListView.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotterChooseNumberListView = class("LotterChooseNumberListView", BaseView)

function LotterChooseNumberListView:initDatas(_params)
    LotterChooseNumberListView.super.initDatas(self, _params)

    self.m_chooseNumberList = G_GetMgr(G_REF.Lottery):getChooseNumberList() 
end

function LotterChooseNumberListView:initUI(_params)
    LotterChooseNumberListView.super.initUI(self)

    -- 初始化 球
    self:initChooseNumberUI()

    self:playIdleAct()
end

-- 初始化 已选球的列表UI
function LotterChooseNumberListView:initChooseNumberUI()
    for idx=1, #self.m_chooseNumberList do

        local number = self.m_chooseNumberList[idx]
        local parent = self:findChild("node_choose_" .. idx)
        local item = self:createShowBallItem(number, idx == #self.m_chooseNumberList)
        parent:addChild(item)
        item:setVisible(false)

    end
end

-- 创建 只供展示的球
function LotterChooseNumberListView:createShowBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    view:setName("node_show_ball")
    return view
end

-- 更新 选择的 球
function LotterChooseNumberListView:updaetChooseNumberUI(_idx, _number)
    if not _idx then
        return
    end

    local number = self.m_chooseNumberList[_idx]
    local bCancel = number ~= 0

    local parent = self:findChild("node_choose_" .. _idx)
    local item = parent:getChildByName("node_show_ball")
    if bCancel then
        _number = 0
        item:setVisible(false)
    else
        item:updateNumberUI(_number)
        item:setVisible(true)
        item:playShowAct(false)
    end
    
    -- 更新manager存储的选号
    self.m_chooseNumberList[_idx] = _number
    G_GetMgr(G_REF.Lottery):setChooseNumberList(_idx, _number)
end

function LotterChooseNumberListView:clickFunc(sender)
    local name = sender:getName()
    
    if string.find(name, "btn_touch_") then
        local idx = tonumber(string.sub(name, -1)) or 0
        if idx == 0 then
            return
        end

        local showNumber = self.m_chooseNumberList[idx]
        local bEnabled = showNumber > 0
        if bEnabled then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_UPDATE_BALL_CHOOSE_STATE, {number = showNumber, bRed = idx==#self.m_chooseNumberList}) -- 更新球库里的球选取状态
            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_CANCEL, {number = showNumber, bRed = idx==#self.m_chooseNumberList}) --选择号码 _取消选择
        end
    end
end

-- 选择球
-- _params = {number=int, bRed=bool}
function LotterChooseNumberListView:chooseNumberEvt(_params)

    if _params.bRed then
        self.m_chooseNumberList[#self.m_chooseNumberList] = 0
        self:updaetChooseNumberUI(#self.m_chooseNumberList, _params.number)
        return
    end

    for idx=1, #self.m_chooseNumberList-1 do
        local number = self.m_chooseNumberList[idx]
        if number == 0 then
            self:updaetChooseNumberUI(idx, _params.number)
            break
        end
    end

end

-- 取消 选择球
function LotterChooseNumberListView:cancelChooseNumberEvt(_params)

    if _params.bRed then
        self:updaetChooseNumberUI(#self.m_chooseNumberList, _params.number)
        return
    end

    for idx=1, #self.m_chooseNumberList-1 do
        local number = self.m_chooseNumberList[idx]
        if number == _params.number then
            self:updaetChooseNumberUI(idx, _params.number)
            break
        end
    end

end

-- 取消 所有选择的球
function LotterChooseNumberListView:cancelAllChooseNumber()

    for idx=1, #self.m_chooseNumberList do

        local number = self.m_chooseNumberList[idx]
        if number > 0 then
            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_UPDATE_BALL_CHOOSE_STATE, {number = number, bRed = idx==#self.m_chooseNumberList}) -- 更新球库里的球选取状态
            self:updaetChooseNumberUI(idx, 0)
        end

    end

end

-- 服务器生成随机号码成功
function LotterChooseNumberListView:generateRanNumberEvt()
    self.m_chooseNumberList = G_GetMgr(G_REF.Lottery):getChooseNumberList() 
    
    for idx=1, #self.m_chooseNumberList do

        -- 选择的球UI
        local number = self.m_chooseNumberList[idx]
        local parent = self:findChild("node_choose_" .. idx)
        local item = parent:getChildByName("node_show_ball")
        item:updateNumberUI(number)
        item:setVisible(true)
        item:playSweepAct()
    end
    
end

function LotterChooseNumberListView:getCsbName()
    return "Lottery/csd/Choose/node_show.csb"
end

function LotterChooseNumberListView:playIdleAct()
    self:runCsbAction("idle") 
end
function LotterChooseNumberListView:playShowAct(_loop)
    self:runCsbAction("start",_loop) 
end

return LotterChooseNumberListView