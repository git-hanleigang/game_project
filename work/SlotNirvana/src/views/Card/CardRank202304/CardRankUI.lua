-- 集卡 排行榜主界面

local showDayTime = 8*24*60*60 -- 7天 
local CardRankConfig = require("views.Card.CardRank202304.CardRankConfig")
local BaseRankUI = require("src.baseRank.BaseRankUI")
local CardRankUI = class("CardRankUI", BaseRankUI)

function CardRankUI:initDatas()
    CardRankUI.super.initDatas(self)
    self.m_isShowTime = false
end

function CardRankUI:initUI()
    CardRankUI.super.initUI(self)
    self:setExtendData("CardRankUI")
    self:onTick()
end

-- 弃用
function CardRankUI:sendRankRequestAction()
    -- G_GetMgr(G_REF.CardRank):sendActionRank(1)
end

function CardRankUI:getRefName()
    return G_REF.CardRank
end

function CardRankUI:getCsbName()
    return CardRankConfig.RankUI
end

function CardRankUI:getRankHelpPath()
    return CardRankConfig.RankHelpUI
end

function CardRankUI:getRankTitlePath()
    return CardRankConfig.RankTitleUI
end

-- [v1]周若宇：不显示倒计时
-- [v2]周若宇：又要显示倒计时
function CardRankUI:getRankTimerPath()
    return CardRankConfig.RankTimerUI
end

function CardRankUI:initTimer()
    CardRankUI.super.initTimer(self)

    local act_ata = G_GetMgr(G_REF.CardRank):getRunningData()
    local left_time = act_ata:getLeftTime()
    self.m_isShowTime = left_time <= showDayTime
    self.node_rankTime:setVisible(self.m_isShowTime)
end

function CardRankUI:getUserCellPath()
    return CardRankConfig.RankPlayerItemUI
end

function CardRankUI:getRewardCellPath()
    return CardRankConfig.RankRewardItemUI
end

function CardRankUI:getCoinMaxLen()
    return 8
end

function CardRankUI:getRewardCellLua()
    return CardRankConfig.RankRewardCellLuaPath
end

function CardRankUI:getTopThreeCellLuaPath()
    return CardRankConfig.RankTopThreeCellLuaPath
end

--显示规则
function CardRankUI:showRankHelpUI()
    local csb_res = self:getRankHelpPath()
    if not csb_res then
        return
    end

    local rankHelpUI = util_createView("views.Card.CardRank202304.CardRankHelpUI")
    if rankHelpUI then
        self:addChild(rankHelpUI)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    end
end

function CardRankUI:onTick()
    local function tick()
        local act_ata = G_GetMgr(G_REF.CardRank):getRunningData()
        if not act_ata then
            if self.schedule_timer then
                self:stopAction(self.schedule_timer)
                self.schedule_timer = nil
            end
            self:closeUI(
                function()
                    -- 打开查看了 玩家信息板子关闭
                    local userMatonLayer = gLobalViewManager:getViewByExtendData("UserInfoMation")
                    if not tolua.isnull(userMatonLayer) then
                        userMatonLayer:closeUI()
                    end
                end
            )
            return
        end

        -- tip
        self:showTip(act_ata:getMyRank())

        local left_time = act_ata:getLeftTime()
        if not left_time or left_time <= 0 then
            self.m_isShowTime = false
            self.node_rankTime:setVisible(false)
            if self.schedule_timer then
                self:stopAction(self.schedule_timer)
                self.schedule_timer = nil
            end
            self:closeUI(
                function()
                    -- 打开查看了 玩家信息板子关闭
                    local userMatonLayer = gLobalViewManager:getViewByExtendData("UserInfoMation")
                    if not tolua.isnull(userMatonLayer) then
                        userMatonLayer:closeUI()
                    end
                end
            )
        else
            if left_time <= showDayTime and self.m_isShowTime == false then
                self.m_isShowTime = true
                self.node_rankTime:setVisible(true)
            end
        end
    end

    if not self.schedule_timer then
        self.schedule_timer = util_schedule(self, tick, 1)
    end

    tick()
end

function CardRankUI:showTip(_rank)
    local node = self:findChild("node_tip")
    if node and not self.m_tip then
        local tip = util_csbCreate(CardRankConfig.RankTipUI)
        if tip then 
            node:addChild(tip)
            self.m_tip = tip
        end
    end

    if _rank <= -1 then
        if self.m_tip then
            self.m_tip:setVisible(true)
        end

        if self.node_empty then
            self.node_empty:setVisible(false)
        end
    else
        if self.m_tip then
            self.m_tip:setVisible(false)
        end
    end
end

-- 排行榜名次列表中，单个cell的size
function CardRankUI:getUserCellSize()
    return cc.size(824, 90)
end

-- 排行榜奖励列表中，单个cell的size
function CardRankUI:getRewardCellSize()
    return cc.size(822, 90)
end

return CardRankUI
