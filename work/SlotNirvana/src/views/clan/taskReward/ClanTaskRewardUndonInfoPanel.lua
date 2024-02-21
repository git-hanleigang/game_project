--[[
Author: cxc
Date: 2021-07-27 20:51:23
LastEditTime: 2021-07-27 20:51:24
LastEditors: your name
Description: 公会任务 未完成 点数换金币 详情面板
FilePath: /SlotNirvana/src/views/clan/taskReward/ClanTaskRewardUndonInfoPanel.lua
--]]
local ClanTaskRewardUndonInfoPanel = class("ClanTaskRewardUndonInfoPanel", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ShopItem = util_require("data.baseDatas.ShopItem")

local ACTION_TIME = 2

function ClanTaskRewardUndonInfoPanel:ctor()
    ClanTaskRewardUndonInfoPanel.super.ctor(self)

    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)

    self.m_rewardCoinNum = 0 -- 奖励的金币数
    self.m_myPoints = 0
    self.m_nextPoints = 0

    self:setExtendData("ClanTaskRewardUndonInfoPanel")
    self:setShownAsPortrait(globalData.slotRunData:isMachinePortrait())
    self:setLandscapeCsbName("Club/csd/Rewards/ClubReward_fail_Reward.csb")
end

function ClanTaskRewardUndonInfoPanel:initUI(_rewards, _curStep, _clanData)
    ClanTaskRewardUndonInfoPanel.super.initUI(self)
    _rewards = _rewards or {}
    _curStep = _curStep or 1

    -- 金币
    self.m_rewardCoinNum = tonumber(_rewards.coins) or 0
	local lbCoins = self:findChild("lb_coin_number")
    lbCoins:setString(util_getFromatMoneyStr(self.m_rewardCoinNum))
    util_scaleCoinLabGameLayerFromBgWidth(lbCoins, 887, 0.7)
    util_alignCenter(
        {
            {node = self:findChild("sp_coin")},
            {node = lbCoins, alignX = 5}
        }
    )
    lbCoins:setString("0")

	-- 点数信息
    local points = _clanData:getMyPoints()
	local rewardList = _clanData:getTaskRewardList()
    local nextStepRewardInfo = rewardList[math.min(_curStep+1, #rewardList)] or {}
    local nextStepPoints = nextStepRewardInfo.points or points
	local percent = 0
	if nextStepRewardInfo and nextStepRewardInfo.points > 0 then
		percent = math.floor( points / tonumber(nextStepPoints) * 100 )
	end
	local lbPoint = self:findChild("lb_teampoint_cur")
    local lbNextPoint = self:findChild("lb_teampoint_next")
	local loadingBarPoint = self:findChild("LoadingBar_1")
	lbPoint:setString(util_getFromatMoneyStr(points))
    lbNextPoint:setString(util_getFromatMoneyStr(nextStepPoints))
	loadingBarPoint:setPercent(percent)
    self.m_myPoints = points
    self.m_nextPoints = nextStepPoints
    self.m_loadingBarPoint = loadingBarPoint

    -- btn
    self.m_btnCollect = self:findChild("btn_collect") 
    self.m_btnCollect:setVisible(false)
end

function ClanTaskRewardUndonInfoPanel:onShowedCallFunc()
    ClanTaskRewardUndonInfoPanel.super.onShowedCallFunc(self)

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle")

        self:playNumAni()
    end, 60)
end

function ClanTaskRewardUndonInfoPanel:playNumAni()
    -- GD.util_jumpNum(label, startValue, endValue, addValue, spendTime, formatValue, char, endChar, callBack, perCallBack)
    -- GD.util_cutDownNum(label, startValue, endValue, addValue, spendTime, formatValue, char, endChar, callBack)
    -- 金币上涨
    local lbCoins = self:findChild("lb_coin_number")
    local addValue = self.m_rewardCoinNum / (ACTION_TIME * 60)
    util_jumpNum(lbCoins, 0, self.m_rewardCoinNum, math.ceil(addValue), 1 / 60, {30})

    -- 点数下降
    local lbPoint = self:findChild("lb_teampoint_cur")
    local subValue = -self.m_myPoints / (ACTION_TIME * 60)
    util_cutDownNum(lbPoint, self.m_myPoints, 0, math.ceil(subValue), 1 / 60, {30})

    -- 进度条
    self.m_nextPoints = math.max(self.m_nextPoints, 1)
    schedule(
        self.m_loadingBarPoint,
        function()
            local str = string.gsub(lbPoint:getString(), ",", "")
            local point = tonumber(str) or 0
            local percent = math.floor(point / self.m_nextPoints * 100)
            self.m_loadingBarPoint:setPercent(percent)
            if percent <= 0 then
                self.m_btnCollect:setVisible(true)
                self.m_loadingBarPoint:stopAllActions()
            end
        end,
        1 / 60
    )
    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(0.3),
            cc.CallFunc:create(
                function()
                    self:runCsbAction("collect")
                end
            )
        )
    )
end

function ClanTaskRewardUndonInfoPanel:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_collect" then
        -- 领取 奖励
        self:onClickCollect()
    end
end

function ClanTaskRewardUndonInfoPanel:onClickMask()
    if not self.m_btnCollect:isVisible() then
        return
    end
    
    self:onClickCollect()
end

function ClanTaskRewardUndonInfoPanel:onClickCollect()
    if self.m_bCollected then
        return
    end
    self.m_bCollected = true

    -- 领取 奖励
    if self.m_rewardCoinNum > 0 then
        self:collectRewards()
    else
        self:closeUI()
    end
end

-- 领取奖励
function ClanTaskRewardUndonInfoPanel:collectRewards()
    local callback = function()
        self:closeUI()
    end

    local senderSize = self.m_btnCollect:getContentSize()
    local startPos = self.m_btnCollect:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))

    -- 飞货币
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if cuyMgr then
        local flyList = {}
        if self.m_rewardCoinNum > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_rewardCoinNum, startPos = startPos})
        end

        cuyMgr:playFlyCurrency(flyList, callback)
    else
        gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_rewardCoinNum, callback)
    end
end

function ClanTaskRewardUndonInfoPanel:closeUI()
    local cb = function()
        ClanTaskRewardUndonInfoPanel.super.closeUI(self, self.m_closeUICb)
    end

    self:runCsbAction("over", false, cb, 60)
end

function ClanTaskRewardUndonInfoPanel:setViewOverFunc(_cb)
    self.m_closeUICb = _cb
end

return ClanTaskRewardUndonInfoPanel 