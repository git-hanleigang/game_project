--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-19 17:24:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-19 17:50:08
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/views/NoviceSevenSignRewardLayer.lua
Description: 新手期 7日签到V2 领奖弹板
--]]
local NoviceSevenSignRewardLayer = class("NoviceSevenSignRewardLayer", BaseLayer)
local NoviceSevenSignConfig = util_require("GameModule.NoviceSevenSign.config.NoviceSevenSignConfig")

function NoviceSevenSignRewardLayer:initDatas(_rewardList, _coins)
    NoviceSevenSignRewardLayer.super.initDatas(self)
    
    self._rewardList = _rewardList
    self._coins = _coins
    self._bgProgList = {}
    for _, shopItem in ipairs(self._rewardList) do
        if string.find(shopItem.p_icon, "Pouch") then
            table.insert(self._bgProgList, shopItem)
        end
    end
    self:initDropList()
    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("DailyBonusNoviceResV2/csd/Activity_DailyBonus_Reward.csb")
    self:setName("NoviceSevenSignRewardLayer")
end

function NoviceSevenSignRewardLayer:initView()
    local parent = self:findChild("node_coin")
    local itemNode = gLobalItemManager:addPropNodeList(self._rewardList, ITEM_SIZE_TYPE.REWARD)
    parent:addChild(itemNode)
end

function NoviceSevenSignRewardLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    NoviceSevenSignRewardLayer.super.playShowAction(self, "open")
end
function NoviceSevenSignRewardLayer:onShowedCallFunc()
    NoviceSevenSignRewardLayer.super.onShowedCallFunc(self)

    self:runCsbAction("idle", true) 
end
function NoviceSevenSignRewardLayer:playHideAction()
    gLobalSoundManager:playSound(SOUND_ENUM.SOUND_HIDE_VIEW)
    NoviceSevenSignRewardLayer.super.playHideAction(self, "close")
end

function NoviceSevenSignRewardLayer:onClickMask()
    self:collectReward()
end

function NoviceSevenSignRewardLayer:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local btnName = sender:getName()
    if btnName == "btn_collect" then
        self:collectReward()
    end
end

function NoviceSevenSignRewardLayer:collectReward()
    if self.bClose then
        return
    end
    self.bClose = true

    if self._coins > 0 then
        self:flyCoins(util_node_handler(self, self.triggerDropFuncNext))
        return
    end
    self:triggerDropFuncNext()
end

function NoviceSevenSignRewardLayer:flyCoins(_cb)
    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local curMgr = G_GetMgr(G_REF.Currency)
    local flyList = {}
    table.insert(flyList, {cuyType = FlyType.Coin, addValue = self._coins, startPos = startPos})
    curMgr:playFlyCurrency(flyList, _cb)
end

-- 初始化 list
function NoviceSevenSignRewardLayer:initDropList()
    local _dropFuncList = {}

    _dropFuncList[#_dropFuncList + 1] = util_node_handler(self, self.triggerDropCrads)
    _dropFuncList[#_dropFuncList + 1] = util_node_handler(self, self.triggerDeluxeCard)
    _dropFuncList[#_dropFuncList + 1] = util_node_handler(self, self.triggerPropsBagView)

    self.m_dropFuncList = _dropFuncList
end

-- 检测 list 调用方法
function NoviceSevenSignRewardLayer:triggerDropFuncNext()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        if tolua.isnull(self) then
            return
        end
        self:closeUI()
        return
    end

    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

-- 检测掉卡
function NoviceSevenSignRewardLayer:triggerDropCrads()
    if CardSysManager:needDropCards("Novice Check2 Reward") == true then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                if not tolua.isnull(self) then
                    self:triggerDropFuncNext()
                end
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("Novice Check2 Reward", nil)
    else
        self:triggerDropFuncNext()
    end
end

-- 检测高倍场体验卡
function NoviceSevenSignRewardLayer:triggerDeluxeCard()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM, util_node_handler(self, self.triggerDropFuncNext))
end

-- 检测掉落 合成福袋
function NoviceSevenSignRewardLayer:triggerPropsBagView()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:popMergePropsBagRewardPanel(self._bgProgList , util_node_handler(self, self.triggerDropFuncNext))
end

function NoviceSevenSignRewardLayer:closeUI()
    local cb = function()
        gLobalNoticManager:postNotification(NoviceSevenSignConfig.EVENT_NAME.NOTIFY_COLLECT_NOVICE_SENVEN_SIGN_DAY_MULTI)
    end
    NoviceSevenSignRewardLayer.super.closeUI(self, cb)
end

return NoviceSevenSignRewardLayer