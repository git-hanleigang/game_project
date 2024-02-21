--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-27 16:50:59
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-27 16:51:08
FilePath: /SlotNirvana/src/activities/Activity_Blast/views/noviceTask/BlastNoviceTaskRewardLayer.lua
Description: 新手blast 任务 奖励界面
--]]
local BlastNoviceTaskRewardLayer = class("BlastNoviceTaskRewardLayer", BaseLayer)

function BlastNoviceTaskRewardLayer:initDatas(_missionData)
    BlastNoviceTaskRewardLayer.super.initDatas(self)

    self.m_curMissionData = _missionData
    self:initDropList()

    self:setPauseSlotsEnabled(true)
    self:setName("BlastNoviceTaskRewardLayer")
    self:setLandscapeCsbName("Activity/BlastBlossomTask/csb/blastMission_rewardLayer.csb")
end

function BlastNoviceTaskRewardLayer:initView()
    local parent = self:findChild("Node_jiedian")
    parent:removeAllChildren()
    local missionData = self.m_curMissionData
    local rewardList = clone(missionData:getRewardList())
    local coins = missionData:getCoins()
    if coins > 0 then
        local shopItem = gLobalItemManager:createLocalItemData("Coins", coins)
        shopItem:setTempData({p_limit = 3})
        table.insert(rewardList, 1, shopItem)
    end

    local itemNode = gLobalItemManager:addPropNodeList(rewardList, ITEM_SIZE_TYPE.REWARD, 1)
    parent:addChild(itemNode)
end

-- 弹出动画
function BlastNoviceTaskRewardLayer:playShowAction()
    BlastNoviceTaskRewardLayer.super.playShowAction(self, "show")
end
-- 待机动画
function BlastNoviceTaskRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end
-- 隐藏动画
function BlastNoviceTaskRewardLayer:playHideAction()
    BlastNoviceTaskRewardLayer.super.playHideAction(self, "over")
end

function BlastNoviceTaskRewardLayer:onClickMask()
    self:onClickCollect()
end
function BlastNoviceTaskRewardLayer:clickFunc(_sander)
    self:onClickCollect()
end

function BlastNoviceTaskRewardLayer:onClickCollect()
    if self.m_isCanTouch then
        return
    end
    self.m_isCanTouch = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    
    self:flyCurrency(util_node_handler(self, self.triggerDropFuncNext))
end
function BlastNoviceTaskRewardLayer:flyCurrency(_func)
    local coins = self.m_curMissionData:getCoins()
    local btnCollect = self:findChild("btn_DailyBonus_RewardCollect") or self:findChild("Node_jiedian")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local flyList = {}
        if coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = coins, startPos = startPos})
        end
        curMgr:playFlyCurrency(flyList, _func)
    else
        if coins <= 0 then
            _func()
            return
        end

        gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, coins, _func)
    end
end

------------------------------------------------ 领取掉落 检测list ------------------------------------------------
-- 初始化 list
function BlastNoviceTaskRewardLayer:initDropList()
    local _dropFuncList = {}

    _dropFuncList[#_dropFuncList + 1] = util_node_handler(self, self.triggerDropCrads)
    _dropFuncList[#_dropFuncList + 1] = util_node_handler(self, self.triggerDeluxeCard)
    _dropFuncList[#_dropFuncList + 1] = util_node_handler(self, self.triggerPropsBagView)

    self.m_dropFuncList = _dropFuncList
end

-- 检测 list 调用方法
function BlastNoviceTaskRewardLayer:triggerDropFuncNext()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        if not tolua.isnull(self) then
            performWithDelay(self, function()
                self:closeUI()
            end, 0)
        end
        return
    end

    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

-- 检测掉卡
function BlastNoviceTaskRewardLayer:triggerDropCrads()
    if CardSysManager:needDropCards("New User Blast Mission") == true then
        -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                self:triggerDropFuncNext()
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("New User Blast Mission", nil)
    else
        self:triggerDropFuncNext()
    end
end

-- 检测掉落 合成福袋
function BlastNoviceTaskRewardLayer:triggerPropsBagView()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    local propsBagist = self.m_curMissionData:getDelxueMergePropBagList()
    mergeManager:popMergePropsBagRewardPanel(propsBagist, handler(self, self.triggerDropFuncNext))
end

-- 检测高倍场体验卡
function BlastNoviceTaskRewardLayer:triggerDeluxeCard()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM, handler(self, self.triggerDropFuncNext))
end
------------------------------------------------ 领取掉落 检测list ------------------------------------------------

return BlastNoviceTaskRewardLayer