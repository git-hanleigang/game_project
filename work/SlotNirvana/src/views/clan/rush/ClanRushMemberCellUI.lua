--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-27 17:44:22
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-27 18:16:32
FilePath: /SlotNirvana/src/views/clan/rush/ClanRushMemberCellUI.lua
Description: 公会rush 各玩家贡献排行
--]]
local ClanRushMemberCellUI = class("ClanRushMemberCellUI", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRushMemberCellUI:initDatas(_taskIconPath, _memberData)
    ClanRushMemberCellUI.super.initDatas(self)

    self.m_taskIconPath = _taskIconPath
    self.m_memberData = _memberData
    self.m_bMe = _memberData:checkIsBMe() 
end

function ClanRushMemberCellUI:initUI()
    ClanRushMemberCellUI.super.initUI(self)

    -- 背景显隐
    self:initBgUI()
    -- 排行icon
    self:initRankIconUI()
    -- 个人头像
    self:initUserHead()
    -- 用户等级
    self:initUserLevelUI()
    -- 用户名字
    self:initUserNameUI()
    -- 任务贡献点数
    self:initTaskPoints()
    -- 玩家预计奖励
    self:initRewardUI()
end

function ClanRushMemberCellUI:getCsbName()
    return "Club/csd/Rush/node_rush_ranking.csb"
end

-- 背景显隐
function ClanRushMemberCellUI:initBgUI()
    local spMe = self:findChild("img_bg_me")
    local spOther = self:findChild("img_bg_other")
    spMe:setVisible(self.m_bMe)
    spOther:setVisible(not self.m_bMe)
end

-- 排行icon
function ClanRushMemberCellUI:initRankIconUI()
    local sp1 = self:findChild("sp_1st")
    local sp2 = self:findChild("sp_2nd")
    local sp3 = self:findChild("sp_3rd")
    local lbRank = self:findChild("lb_rank")
    local rank = self.m_memberData:getRank()
    sp1:setVisible(rank == 1)
    sp2:setVisible(rank == 2)
    sp3:setVisible(rank == 3)
    lbRank:setVisible(rank > 3)
    if rank > 4 then
        lbRank:setString(rank)
    end
end

-- 个人头像
function ClanRushMemberCellUI:initUserHead()
    local nodeHead = self:findChild("sp_head")
    self:updateHeadUI(nodeHead)
end

-- 用户等级
function ClanRushMemberCellUI:initUserLevelUI()
    local lbLevel_me = self:findChild("lb_myLv")
    local lbLevel_other = self:findChild("lb_otherLv")
    lbLevel_me:setVisible(self.m_bMe)
    lbLevel_other:setVisible(not self.m_bMe)
    local lbLevel = self.m_bMe and lbLevel_me or lbLevel_other
    local level = self.m_memberData:getLevel()
    lbLevel:setString("LV" .. level)
end

-- 用户名字
function ClanRushMemberCellUI:initUserNameUI()
    local layoutName = self:findChild("layout_name")
    local lbName_me = self:findChild("lb_myName")
    local lbName_other = self:findChild("lb_otherName")
    lbName_me:setVisible(self.m_bMe)
    lbName_other:setVisible(not self.m_bMe)
    local lbName = self.m_bMe and lbName_me or lbName_other
    local name = self.m_memberData:getName()
    lbName:setString(name)
    util_wordSwing(lbName, 1, layoutName, 3, 30, 3)
end

-- 任务贡献点数
function ClanRushMemberCellUI:initTaskPoints()
    local spRewardBg_me = self:findChild("img_reward_bg_me")
    local spRewardBg_other = self:findChild("img_reward_bg_other")
    spRewardBg_me:setVisible(self.m_bMe)
    spRewardBg_other:setVisible(not self.m_bMe)

    local spTaskIcon = self:findChild("sp_icon")
    -- util_changeTexture(spTaskIcon, self.m_taskIconPath)
    ClanManager:changeTeamRushTaskIcon(spTaskIcon, self.m_taskIconPath)

    local lbCount = self:findChild("txt_reward")
    local points = self.m_memberData:getProgress()
    lbCount:setString(util_getFromatMoneyStr(points))
end

-- 更新玩家头像
function ClanRushMemberCellUI:updateHeadUI(_headParent)
    if tolua.isnull(_headParent) then
        return
    end
    _headParent:removeAllChildren()

    local fbId = self.m_memberData:getFacebookId()
    local head = self.m_memberData:getHead() 
    local frameId = self.m_memberData:getFrameId() 
    local headSize = _headParent:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, headSize)
    nodeAvatar:setPosition( cc.p( (headSize.width)/2, (headSize.height)/2 ) )
    nodeAvatar:addTo(_headParent)
end

-- 玩家预计奖励
function ClanRushMemberCellUI:initRewardUI()
    -- 金币
    local lbCoins = self:findChild("lb_coins")
    local coins = self.m_memberData:getRewardCoins()
    lbCoins:setString(util_formatCoins(coins, 6))
    
    -- 道具
    local nodeItem = self:findChild("node_item")
    local itemList = self.m_memberData:getRewardList()
    nodeItem:removeAllChildren()
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    local itemNode = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.TOP, 0.5, width, true)
	nodeItem:addChild(itemNode)
    nodeItem:setVisible(false)

    -- 居中排列
    local alignUIList = {
        {node = lbCoins},
    }
    if #itemList > 0 then
        lbCoins:setString(util_formatCoins(coins, 4) .. " + ")
        table.insert(alignUIList, {node = nodeItem, alignX = 5, size = cc.size(#itemList * width*0.5, width*0.5)})
        nodeItem:setVisible(true)
    end
    local totalW = util_alignCenter(alignUIList)
    if totalW > 164 then
        self:findChild("node_align"):setScale(164 / totalW)
    end
end

function ClanRushMemberCellUI:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_userInfo" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_memberData:getUdid(), "", self.m_memberData:getName(), self.m_memberData:getFrameId())
    end
end

return ClanRushMemberCellUI