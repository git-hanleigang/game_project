local sysRewardView = class("sysRewardView", BaseLayer)

sysRewardView.type = nil
sysRewardView.num = nil
sysRewardView.path = nil
sysRewardView.describe = nil

function sysRewardView:initDatas(rewardTable, param, rewardID)
    self.rewardID = rewardID
    self.type = rewardTable.type
    --facebook 奖励钱数读服务器传回来的
    if rewardID == "FBReward" and globalData.userRunData.getFbBindReward then
        self.num = globalData.userRunData:getFbBindReward()
    elseif rewardID == "EmailReward" then
        self.num = globalData.userRunData:getFbBindReward()
    elseif rewardID == "NewUserProtectReward" then
        self.num = globalData.userRunData:getNewUserReward()
    elseif rewardID == "newVersion" then
        self.num = tonumber(param.addCoins or rewardTable.num)
    else
        self.num = tonumber(rewardTable.num)
    end
    self.describe = rewardTable.describe
    self.path = rewardTable.path

    self:setLandscapeCsbName(self.path)
    self:setKeyBackEnabled(false)
end

function sysRewardView:initUI(rewardTable, param, rewardID)
    sysRewardView.super.initUI(self)

    self.isCollect = false

    self.m_lb_reward = self:findChild("m_lb_reward")
    self.m_lb_reward:setString(util_formatCoins(self.num, 12))
    local sx = self.m_lb_reward:getScaleX()
    local sy = self.m_lb_reward:getScaleY()
    self:updateLabelSize({label = self.m_lb_reward, sx = sx, sy = sy}, 1200)
    self.m_btn_collect = self:findChild("btn_collect") --领取按钮

    local sp_coin = self:findChild("coin_dollar")
    local uiList = {}
    table.insert(uiList, {node = sp_coin})
    table.insert(uiList, {node = self.m_lb_reward, alignX = 10, alignY = 2})
    util_alignCenter(uiList)
end

function sysRewardView:collect()
    if self.isCollect then
        -- body
        return
    end

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    self.isCollect = true

    self:getReward()
end

function sysRewardView:getReward()
    if self.type == "coins" then
        if self.rewardID == "newVersion" then
            self:collectReward()
        else
            self:getCoinsReward()
        end
    end
end

function sysRewardView:collectReward()
    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if cuyMgr then
        local flyList = {}
        if self.num > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.num, startPos = startPos})
        end

        cuyMgr:playFlyCurrency(
            flyList,
            function()
                if not tolua.isnull(self) then
                    self:closeUI()
                end
            end
        )
    end
end

function sysRewardView:getCoinsReward()
    --检查联网状态
    if gLobalSendDataManager:checkShowNetworkDialog() then
        self:failedCallFun()
        return
    end
    -- --添加loading
    gLobalViewManager:addLoadingAnima()
    -- 发送消息
    gLobalSendDataManager:getNetWorkFeature():sendSystemReward(
        self.rewardID,
        nil,
        function()
            if not tolua.isnull(self) then
                self:successCallFun()
                gLobalViewManager:removeLoadingAnima()
            end
        end,
        function()
            if not tolua.isnull(self) then
                self:failedCallFun()
                gLobalViewManager:removeLoadingAnima()
            end
        end
    )
end

--[[
    @desc: 飞金币
    author:{author}
    time:2018-11-29 15:58:18
    @return:
]]
function sysRewardView:flyBonusGameCoins(callback)
    local endPos = globalData.flyCoinsEndPos

    local startPos = self.m_btn_collect:getParent():convertToWorldSpace(cc.p(self.m_btn_collect:getPosition()))
    local baseCoins = globalData.topUICoinCount

    local view = gLobalViewManager:getFlyCoinsView()
    view:pubShowSelfCoins(true)
    view:pubPlayFlyCoin(startPos, endPos, baseCoins, self.num, callback)
end

function sysRewardView:successCallFun()
    print("Cool测试～～～～～领取奖励成功")
    globalData.signInfo.fbReward = globalData.userRunData.fbUdid
    globalData.userRunData:setCoins(globalData.userRunData.coinNum + self.num)
    gLobalSendDataManager:getNetWorkFeature():sendActionLoginReward(globalData.signInfo)
    self:flyBonusGameCoins(
        function()
            if not tolua.isnull(self) then
                -- 不刷新可能显示假的
                self.isCollect = false
                self:removeView()
            end
        end
    )
end

function sysRewardView:failedCallFun()
    self.isCollect = false
    print("Cool测试～～～～～领取奖励失败")
end

function sysRewardView:removeView(func)
    if not tolua.isnull(self) then
        self:closeUI(func)
    end
end

function sysRewardView:onShowedCallFunc()
    self:runCsbAction("waiting", true)
end

function sysRewardView:onEnter()
    sysRewardView.super.onEnter(self)
    self:runCsbAction("idle")
end

-- function sysRewardView:onKeyBack()
-- end

-- function sysRewardView:onExit()
-- end

function sysRewardView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    self:collect()
end

function sysRewardView:updateLab(str1, str2, str3)
    local font_base = self:findChild("font_base")
    local font_bonus = self:findChild("font_bonus")
    local font_total = self:findChild("font_total")

    if font_base then
        font_base:setString(str1)
    end
    if font_bonus then
        font_bonus:setString(str2)
    end
    if font_total then
        font_total:setString(str3)
    end
end

return sysRewardView
