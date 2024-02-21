--[[
    
    author:徐袁
    time:2021-03-19 20:20:32
]]
local StatuePickOverLayer = class("StatuePickOverLayer", BaseLayer)

StatuePickOverLayer.ActionType = "Common"

function StatuePickOverLayer:ctor()
    StatuePickOverLayer.super.ctor(self)

    self:setLandscapeCsbName("CardRes/season202102/Statue/StatuePickOverLayer.csb")
    -- self:setPauseSlotsEnabled(true)
    self:setExtendData("StatuePickOverLayer")
    -- self:setShowBgOpacity(0)
    -- test
    -- self:setKeyBackEnabled(true)
end

--[[
    @desc: 初始化csb节点
    author:徐袁
    time:2021-03-19 20:20:32
    @return:
]]
function StatuePickOverLayer:initCsbNodes()
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_btnBuy = self:findChild("btn_buy")
    -- self.m_fntPrice = self:findChild("fnt_price")

    self.m_spGem = self:findChild("games")
    self.m_lbNum = self:findChild("lb_num")
end

--[[
    @desc: 初始化界面显示
    author:徐袁
    time:2021-03-19 20:20:32
    @return:
]]
function StatuePickOverLayer:initView()
end

--[[
    @desc: 刷新界面显示
    author:徐袁
    time:2021-03-19 20:20:32
    @return:
]]
function StatuePickOverLayer:updateView()
    local _price = StatuePickGameData:getBuyPrice()
    -- self.m_fntPrice:setString(_price)
    self:setButtonLabelContent("btn_buy", _price)
    -- 当前玩家的宝石数
    local userGemsNum = globalData.userRunData.gemNum or 0
    self.m_lbNum:setString(util_formatCoins(tonumber(userGemsNum), 33))
    if _price > userGemsNum then
        -- 钻石不够
        self.m_lbNum:setColor(cc.c3b(255, 0, 0))
    else
        self.m_lbNum:setColor(cc.c3b(255, 255, 255))
    end

    local UIList = {}
    table.insert(UIList, {node = self.m_spGem, anchor = cc.p(0.5, 0.5)})
    table.insert(UIList, {node = self.m_lbNum, anchor = cc.p(0.5, 0.5)})
    util_alignCenter(UIList)
end

function StatuePickOverLayer:initGem()
    self.m_GemUI = util_createView("GameModule.CardMiniGames.Statue.StatuePick.StatuePickGemNode")
    self.m_nodeAddGems:addChild(self.m_GemUI)
end

function StatuePickOverLayer:updateGem()
    if self.m_GemUI and self.m_GemUI.updateUI then
        self.m_GemUI:updateUI()
    end
end

-- 注册消息事件
function StatuePickOverLayer:registerListener()
    StatuePickOverLayer.super.registerListener(self)

    -- 购买PICKS数量结果
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local isSuccess = params.result or false
            if not isSuccess then
                self:setBtnEnabled(true)
            else
                local callFunc = function()
                    gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_SHOW_BOX_ARRAY)
                end
                self:closeUI(callFunc)
            end
        end,
        ViewEventType.STATUS_PICK_BUY_PICKS_RESULT
    )

    -- 领取奖励结果
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local isSuccess = params.result or false
            if isSuccess then
                -- local callFunc = function()
                --     StatuePickControl:showCollectLayer()
                -- end
                -- self:closeUI(callFunc)
            else
                self:setBtnEnabled(true)
            end
        end,
        ViewEventType.STATUS_PICK_COLLECT_REWARD_RESULT
    )
end

function StatuePickOverLayer:onEnter()
    StatuePickOverLayer.super.onEnter(self)
    self:updateView()
end

function StatuePickOverLayer:onExit()
    StatuePickOverLayer.super.onExit(self)
end

-- layer显示完成的回调
function StatuePickOverLayer:onShowedCallFunc()
end

function StatuePickOverLayer:clickFunc(sender)
    local senderName = sender:getName()

    if senderName == "btn_buy" then
        self:buyPicks()
    elseif senderName == "btn_collect" then
        self:collectReward()
    end
end

function StatuePickOverLayer:setBtnEnabled(isEnabled)
    self.m_btnBuy:setTouchEnabled(isEnabled)
    self.m_btnCollect:setTouchEnabled(isEnabled)
end

-- 领取奖励
function StatuePickOverLayer:collectReward()
    self:setBtnEnabled(false)
    StatuePickControl:requestCollectRewards()
end

-- 购买游戏次数
function StatuePickOverLayer:buyPicks()
    -- 是否能有购买次数
    if not StatuePickGameData:isHasBuyTimes() then
        return
    end
    self:setBtnEnabled(false)
    StatuePickControl:buyPicks()
end

return StatuePickOverLayer
