--[[
    宝箱
    断线重连时初始化
        开出的是奖品时，没必要做
        开出的是鲨鱼时，上一次打开的宝箱位置要消失，只有三个等待玩家开启
]]
local CSMainBox = class("CSMainBox", BaseView)

function CSMainBox:initDatas(_index, _levelType, _isOpened, _boxData, _clickBoxFunc)
    self.m_index = _index
    self.m_levelType = _levelType
    self:setOpenStatus(_isOpened)
    -- self.m_boxData = _boxData -- 暂时没用，如果有用，每次resetView时也要重新赋值
    self.m_clickBoxFunc = _clickBoxFunc
end

function CSMainBox:setOpenStatus(_isOpened)
    self.m_isOpened = _isOpened
end

function CSMainBox:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_Box.csb"
end

function CSMainBox:initCsbNodes()
    -- self.m_nodeReward = self:findChild("Node_prize")
    self.m_spNormalBox = self:findChild("sp_box_normal")
    self.m_spSpecialBox = self:findChild("sp_box_special")
    self.m_panelTouch = self:findChild("Panel_touch")
    self:addClick(self.m_panelTouch)
end

function CSMainBox:initUI()
    CSMainBox.super.initUI(self)
    self:initView()
end

function CSMainBox:initView()
    self:initIcon()
    if self.m_isOpened then
        self:playHideIdle()
    else
        self:playShowIdle()
    end
end

-- 更改为最初始的状态
function CSMainBox:resetView()
    -- 更换层级
    -- self.m_nodeReward:removeAllChildren()
    -- self:initRewardColor(false)
    self:playShowIdle()
    self:setOpenStatus(false)
end

function CSMainBox:initIcon()
    self.m_spNormalBox:setVisible(self.m_levelType == CardSeekerCfg.LevelType.normal)
    self.m_spSpecialBox:setVisible(self.m_levelType == CardSeekerCfg.LevelType.special)
end

function CSMainBox:resetIcon(_levelType)
    -- 层级类型不一样要更改icon
    if self.m_levelType ~= _levelType then
        self.m_levelType = _levelType
        self:initIcon()
    end
end

-- function CSMainBox:initReward(_boxData)
--     assert(_boxData ~= nil, "_boxData is nil")
--     self.m_nodeReward:removeAllChildren()
--     local rewardNode = nil
--     if _boxData:isMonsterBox() then
--         -- rewardNode = util_createSprite(CardSeekerCfg.otherPath .. "CardSeeker_Guard.png")
--         -- rewardNode:setScale(0.7)
--         -- rewardNode = util_createAnimation(CardSeekerCfg.csbPath .. "Seeker_Monster.csb")
--         -- rewardNode:playAction("idle", true, nil, 60)
--         rewardNode = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainBoxMonster")
--     else
--         local _type = _boxData:getType()
--         local value = _boxData:getValue()
--         local itemDatas = _boxData:getItems()
--         if _type == CardSeekerCfg.BoxType.coin then
--             local tempData = gLobalItemManager:createLocalItemData("Coins", value, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
--             rewardNode = gLobalItemManager:createRewardNode(tempData, ITEM_SIZE_TYPE.REWARD_BIG)
--         elseif _type == CardSeekerCfg.BoxType.gem then
--             local tempData = gLobalItemManager:createLocalItemData("Gem", value, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
--             rewardNode = gLobalItemManager:createRewardNode(tempData, ITEM_SIZE_TYPE.REWARD_BIG)
--         elseif _type == CardSeekerCfg.BoxType.item then
--             for i = 1, #itemDatas do
--                 rewardNode = gLobalItemManager:createRewardNode(itemDatas[i], ITEM_SIZE_TYPE.REWARD_BIG)
--                 break
--             end
--         end
--     end
--     if rewardNode then
--         self.m_nodeReward:addChild(rewardNode)
--     end
-- end

-- function CSMainBox:initRewardColor(_isGrey)
--     local color = _isGrey and cc.c3b(127, 115, 150) or cc.c3b(255, 255, 255)
--     self.m_nodeReward:setColor(color)
--     local children = self.m_nodeReward:getChildren()
--     for i = 1, #children do
--         if children[i].setGrey then
--             children[i]:setGrey(_isGrey)
--         end
--     end
-- end

function CSMainBox:setTouchVisible(_visible)
    self.m_panelTouch:setVisible(_visible)
end

function CSMainBox:playStart(_over)
    -- print("---CSMainBox:playStart ---", self.m_index, util_getymdhms_format(), debug.traceback("", 4))
    gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/box_appear.mp3")
    self:runCsbAction("start", false, _over, 60)
end

function CSMainBox:playShake(_over)
    -- print("---CSMainBox:playShake ---", self.m_index, util_getymdhms_format(), debug.traceback("", 4))
    self:runCsbAction("shake", false, _over, 60)
end

function CSMainBox:playShowIdle()
    -- print("---CSMainBox:playShowIdle ---", self.m_index, util_getymdhms_format(), debug.traceback("", 4))
    self:runCsbAction("idle_show", true, nil, 60)
end

function CSMainBox:playHideIdle()
    -- print("---CSMainBox:playHideIdle ---", self.m_index, util_getymdhms_format(), debug.traceback("", 4))
    self:runCsbAction("idle_hide", true, nil, 60)
end

function CSMainBox:playOpen(_over)
    -- print("---CSMainBox:playOpen ---", self.m_index, util_getymdhms_format(), debug.traceback("", 4))
    self:runCsbAction("click", false, _over, 60)
end

function CSMainBox:playHide(_over)
    -- print("---CSMainBox:playHide ---", self.m_index, util_getymdhms_format(), debug.traceback("", 4))
    self:runCsbAction("box_hide", false, _over, 60)
end

-- function CSMainBox:playDisappear(_over)
--     self:runCsbAction("prize_xiaoshi", false, _over, 60)
-- end

function CSMainBox:clickBox()
    if self.m_clickBoxFunc then
        self.m_clickBoxFunc(self.m_index)
    end
end

function CSMainBox:clickFunc(sender)
    -- 开着的宝箱不能点击
    if self.m_isOpened == true then
        return
    end
    local name = sender:getName()
    if name == "Panel_touch" then
        self:clickBox()
    end
end

function CSMainBox:getTSGameData()
    return G_GetMgr(G_REF.CardSeeker):getData()
end

return CSMainBox
