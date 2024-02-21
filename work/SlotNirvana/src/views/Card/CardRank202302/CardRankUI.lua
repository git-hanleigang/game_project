-- 集卡 排行榜主界面

local CardRankConfig = require("views.Card.CardRank202302.CardRankConfig")
local BaseRankUI = require("src.baseRank.BaseRankUI")
local CardRankUI = class("CardRankUI", BaseRankUI)

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

function CardRankUI:getRankTimerPath()
    return CardRankConfig.RankTimerUI
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

    local rankHelpUI = util_createView("views.Card.CardRank202302.CardRankHelpUI")
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
        local left_time = act_ata:getLeftTime()
        if not left_time or left_time <= 0 then
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
        end
    end

    if not self.schedule_timer then
        self.schedule_timer = util_schedule(self, tick, 1)
    end

    tick()
end

return CardRankUI
