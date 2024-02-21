
-- 公会数据

local ClanConfig = require "data.clanData.ClanConfig"
local ClanData = class("ClanData")
local ShopItem = util_require("data.baseDatas.ShopItem")
local ClanRankData = util_require("data.clanData.ClanRankData")
local ClanRankBenifitData = util_require("data.clanData.ClanRankBenifitData")
local ClanRankTopInfoData = util_require("data.clanData.ClanRankTopInfoData")
local ClanRushData = util_require("data.clanData.ClanRushData")
local ClanMemberData = util_require("data.clanData.ClanMemberData")
local ClanRedGiftSingleData = util_require("data.clanData.ClanRedGiftSingleData")
local ClanBaseInfoData = util_require("data.clanData.ClanBaseInfoData")
local ClanInviteData = util_require("data.clanData.ClanInviteData")
local ClanRankTopMembersInfoData = util_require("data.clanData.ClanRankTopMembersInfoData")
local ClanDuelData = util_require("data.clanData.ClanDuelData")

function ClanData:ctor()
    self.m_bInitServerData = false -- 是否被初始化过
    self.createClan = false
    self.m_pointState = ClanConfig.LastTaskState.COLLECTED

    self:resetClanData()
end

function ClanData:resetClanData()
    self.m_clanSimpleInfo = ClanBaseInfoData:create()      -- 公会简要信息
    self.m_clanMemberList = {}      -- 公会成员列表
    self.m_rankData = ClanRankData:create() --公会排行数据
    self.m_clanRankInfo = {}        -- 公会段位信息
    self.m_selfBenifitData = ClanRankBenifitData:create() -- 公会各段位权益数据
    self.m_rankMemberRewardList = {} -- 公会排行各成员贡献和奖励数据
    self.m_topTeamRankData = ClanRankTopInfoData:create() -- 最强公会排行榜列表
    self.m_teamRushData = ClanRushData:create() -- 公会rush数据
    self.m_teamRedGiftList = {}    -- 公会红包礼物列表
    self.m_topMembersRankData = ClanRankTopMembersInfoData:create() -- 最强百人排行榜列表
    self.m_clanDuelData = ClanDuelData:create() -- 公会对决
end

---------------------------------------------------  解析数据接口  ---------------------------------------------------
-- 解析公会数据
-- //公会信息返回
--[[
    message ClanInfo {
        optional string identity = 1; //身份(leader/member)
        optional Clan clan = 2; //公会基础信息
        optional ClanPoints points = 3;//公会公共Points数据
        optional int32 myPoints = 4;//公会任务 玩家累积点数
        repeated ClanPointsLevel levels = 5;  //公会成员Points等级数据
        optional ClanChallenge challenge = 6;  //公会挑战数据
        optional bool createClan = 7; //是否可以创建公会标识
        optional bool collectLast = 8;//上期Points结算标识
        optional int64 number = 9; //编号
        repeated ClanInvite invite = 10; //受邀数据
        optional bool remind = 11;//解锁弹窗标识
        optional string shareUrl = 12; //公会分享地址
        optional int32 gems = 13;//创建公会消耗消耗第二货币数量
        optional int64 askChipCD = 14;//索要卡片CD
        optional int32 pointState = 15;//points是否已领取 0未完成 1 已完成 2 已领取
        optional int32 updateNameGems = 16;//改名字消耗消耗第二货币数量
        optional int32 roomNum = 17;  //排行榜 房间
        optional int32 rankUp = 18; //排行榜 排名上升的幅度
        optional int32 rank = 19; //排行榜 排名
        optional int64 rankPoints = 20; //排行榜 点数
        optional ClanDivisionInterest interest = 21; //最新段位及权益
        optional int32 lastDivision = 22; //排行榜 最近一次的段位
        optional bool displayedDivision = 23; //排行榜 段位是否已展示
        optional int64 rankCoins = 24; //排行榜 奖励金币
        repeated ShopItem rankItems = 25; //排行榜 奖励物品 废弃
        repeated int32 rankHighLimitPoints = 25; //排行榜 高倍场点数
        optional string position = 27;//职位
        optional string oldPosition = 28;//之前的职位
        optional bool redPackageSwitch = 29;//公会红包开关
        optional ClanDuel clanDuel = 30;//公会对决
    }
]]
function ClanData:parseClanInfoData( data )
    self.m_bInitServerData = true

    -- 先清空数据 防止旧数据污染
    self.m_clanSimpleInfo = ClanBaseInfoData:create()      -- 公会简要信息
    
    -- 公会邀请列表
    self:parseInviteList(data.invite)

    -- 是否可以创建公会(这个值在最前面解析 没有公会数据时也会有这个数据)
    self.createClan = data.createClan
    self.createGems = data.gems
    if not data.clan or not data.clan.cid or #data.clan.cid <= 0 then
        local bNotify = false
        if self.userIdentity ~= nil and self.userIdentity ~= ClanConfig.userIdentity.NON then
            bNotify = true
        end
        -- 没有公会数据意味着玩家没有加入公会 不再解析剩余数据
        self.userIdentity = ClanConfig.userIdentity.NON

        -- 公会职位 状态发生变化 更新活动数据
        if bNotify then
            self:resetClanData()
            gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig() -- 商城公会权益发生变化
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.SEND_SYNC_CLAN_ACT_DATA) -- 更新活动信息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ClOSE_CLEAR_TCP) -- close socket
        end
        return
    end

    -- 解析公会数据
    self.m_clanSimpleInfo:parseData(data.clan)

    local bNotify = false
    -- 玩家在公会里的职位(leader:会长 / member:成员)
    if self.userIdentity ~= nil and self.userIdentity ~= data.position then
        bNotify = true
    end
    self.userIdentity = data.position
    self.userIdentityOld = data.position
    if data.oldPosition and #data.oldPosition > 0 then
        self.userIdentityOld = data.oldPosition
    end
    -- 公会职位 状态发生变化 更新活动数据
    if bNotify then
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.SEND_SYNC_CLAN_ACT_DATA) 
    end

    -- 公会任务数据
    self.m_taskData = self:parseTaskData(data.points)
    --(服务器担心有些情况下 公会任务数据会对非公会玩家展示 不想再去组装数据 所以独立出来了 对前端没有影响 再组装进去就是了)
    self.m_taskData.myPoints = data.myPoints -- 个人累积点数
    self.m_taskData.myTotalPoints = data.myPoints -- 个人能达到的总点数
    
    -- 公会任务奖励列表(奖励分阶段，个人累积的任务点数越高，能拿到的奖励越好)
    self.m_taskRewardsList = self:parseTaskRewardsData(data.levels, data.myPoints)
    self:resetTaskStep()

    -- slef.remind = data.remind   -- 解锁宝箱标识(保留字段 这个现在似乎用不到)

    -- 公会分享地址
    self.m_shareUrl = data.shareUrl

    -- 公会索要卡片的CD
    self.m_requestCardCD = tonumber(data.askChipCD) or 0

    -- points是否已领取 0未完成 1 已完成 2 已领取
    self.m_pointState = data.pointState or ClanConfig.LastTaskState.COLLECTED

    -- 改名字消耗消耗第二货币数量
    self.m_updateNameGems = tonumber(data.updateNameGems) or 0

    -------------- 排行 --------------
    self:parseSelfRankInfo(data)
    -------------- 排行 --------------
    -- 公会rush
    self:parseRushData(data.rush)
    --公会红包开关
    self.m_bRedGiftOpen = data.redPackageSwitch or false
    --公会对决duel
    self:parseClanDuelData(data.clanDuel)

    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    ClanManager:setRedGiftOpenSign(self.m_bRedGiftOpen)
end

-- 解析被邀列表
function ClanData:parseInviteList( _inviteList )
    _inviteList = _inviteList or {}
    self.m_inviteList = {}

    for _, inviteData in ipairs(_inviteList) do
        local data = ClanInviteData:create()
        data:parseData(inviteData)
        table.insert(self.m_inviteList, data)
    end
end
-- 获取受邀公会列表
function ClanData:getInviteList()
    return self.m_inviteList or {}
end

-- 解析公会成员信息
function ClanData:parseClanMemberList( _list )
    self:parseMemberData(_list, "ClanUser") 
end
-- 解析公会成员信息
function ClanData:parseMemberData(_list, _dataType)
    local clanMemberList = {}
    local points = 0
    self.m_eliteCount = 0 -- 精英成员数量
    for i=1, #_list do
        local memberInfo = _list[i]
        local memberData = self:getTeamMemberByUdid(memberInfo.udid)
        if not memberData then
            memberData = ClanMemberData:create()
        end
        memberData:parseData(memberInfo, _dataType)

        -- 记录 精英成员数量
        if memberData:checkIsElite() then
            self.m_eliteCount = self.m_eliteCount + 1
        end
        -- 本人 职位
        if memberData:checkIsBMe() then
            self.userIdentity = memberData:getIdentity()
        end
        -- 所有玩家积累的点数
        points = points + memberData:getPoints()

        table.insert(clanMemberList, memberData)
    end

    -- 排序 公会点数
    table.sort(clanMemberList, function(aMData, bMData)
        return aMData:getPoints() > bMData:getPoints()
    end)
    -- 点开成员列表正好 有其他玩家增加公会点数了， 更新下公会基本信息里的点数
    if self.m_taskData and tonumber(self.m_taskData.current) < points then
        self.m_taskData.current = points
    end

    self.m_lastReqMemDataType = _dataType or "ClanUser"
    self.m_clanMemberList = clanMemberList
end
-- 玩家退出或被踢更新 成员数据
function ClanData:deleteMemberByUdid(_udid)
    for idx=1, #self.m_clanMemberList do
        local memberData = self.m_clanMemberList[idx]
        if memberData:getUdid() == _udid then
            table.remove(self.m_clanMemberList, idx)
            break
        end
    end
end
-- 获取 某一玩家信息
function ClanData:getTeamMemberByUdid(_udid)
    for idx=1, #self.m_clanMemberList do
        local memberData = self.m_clanMemberList[idx]
        if memberData:getUdid() == _udid then
            return memberData
        end
    end
end 
-- 获取公会成员信息
function ClanData:getClanMemberList()
    return self.m_clanMemberList or {}
end
function ClanData:resetClanMemberList()
    self.m_clanMemberList = {}
end
-- 获取上次 成员信息 请求的类型
function ClanData:getLastReqMemDataType()
    return self.m_lastReqMemDataType
end

-- 获取公会精英成员数量
function ClanData:getEliteMemberCount()
    return self.m_eliteCount or 0
end

-- 设置当前公会成员上限
function ClanData:setMemberMax( data )
    self.memberMax = data
end
function ClanData:getMemberMax()
    return self.memberMax or 0
end

-- 设置当前申请入会成员数量
function ClanData:setApplyCounts( data )
    self.applyCounts = data
end

function ClanData:getApplyCounts()
    return self.applyCounts or 0
end

-- 解析公会信息编辑返回数据
function ClanData:parseClanEditData(data)
    if data and data.clanInfo then
        self:parseClanInfoData(data.clanInfo)
    else
        printInfo("------>    解析公会信息编辑返回数据 公会数据缺失")
    end
end

---------------------------------------------------  解析数据接口  ---------------------------------------------------




---------------------------------------------------  数据解析结构  ---------------------------------------------------
-- //公会基础信息
function ClanData:parseClanData( data )
    self.m_clanSimpleInfo:parseData(data)
end
-- 获取公会简要信息( id 名称 logo 公会宣言 )
function ClanData:getClanSimpleInfo()
    return self.m_clanSimpleInfo or ClanBaseInfoData:create()
end

-- 解析公会任务数据
-- //公会任务数据
-- message ClanPoints {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional int64 current = 3; //当前点数
--     optional int64 total = 4; //解锁总点数
-- }
function ClanData:parseTaskData( data )
    local task_data = {}
    if data then
        task_data.expire = data.expire
        task_data.expireAt = data.expireAt
        task_data.current = tonumber(data.current)
        task_data.total = tonumber(data.total)
    else
        printInfo("------>    解析公会任务数据 公共数据缺失")
    end

    return task_data
end

-- 解析公会任务 个人部分数据
-- //所属公会任务
-- message ClanPointsLevel {
--     optional int32 level = 1;//等级
--     optional int64 points = 2;  //任务个人点数
--     optional int64 coins = 3; //金币奖励
--     repeated ShopItem items = 4;  //物品奖励
-- }
function ClanData:parseTaskRewardsData( data, myPoints )
    myPoints = myPoints or self.m_taskData.myPoints
    local max_point = 0
    local taskRewardsList = {}
    if data and next(data) then
        for i,taskData in ipairs(data) do
            if taskData then
                local task_data = {}
                task_data.level = taskData.level
                task_data.points = tonumber(taskData.points)
                task_data.coins = taskData.coins
                task_data.items = self:parseShopItemList(taskData.items)
                task_data.isCanCollect = task_data.points <= myPoints --是否可以领取
                table.insert(taskRewardsList, task_data)
                if max_point < task_data.points then
                    max_point = task_data.points
                end
            end
        end
        self.m_taskData.myTotalPoints = max_point
    else
        printInfo("------>    解析公会任务数据 任务奖励列表缺失")
    end
    return taskRewardsList
end

-- 解析道具
function ClanData:parseShopItemList(_items)
    local shopItemList = {}
    for _, data in ipairs(_items) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)
        if CardSysManager:isNovice() and shopItem.p_type == "Package" then
            -- 新手集卡期不显示 集卡 道具
        else
            table.insert(shopItemList, shopItem)
        end
    end

    return shopItemList
end

function ClanData:resetTaskStep()
    if not self.m_taskData or not self.m_taskData.myPoints then
        return
    end

    local filterIdx = 0
    local energy = 0
    local rewardList = self:getTaskRewardList() -- 阶段奖励
    if not next(rewardList) then
        return
    end
    
    for i = 1, 6 do
        local rewardInfo = rewardList[i]
        local points = rewardInfo.points or 0
        if self.m_taskData.myPoints < points then
            break
        end 
        filterIdx = i
        rewardInfo.isCanCollect = true
        energy = self.m_taskData.myPoints - points
    end
    self.m_taskData.curStep = filterIdx
    self.m_taskData.curStepEnergy = energy
    if filterIdx == 6 then
        self.m_taskData.totalStepEnergy = self.m_taskData.curStepEnergy
    elseif filterIdx > 1 then
        self.m_taskData.totalStepEnergy = rewardList[filterIdx+1].points - rewardList[filterIdx].points
    else
        self.m_taskData.totalStepEnergy = rewardList[filterIdx+1].points
    end
end

---------------------------------------------------  数据解析结构  ---------------------------------------------------


---------------------------------------------------  获取数据接口  ---------------------------------------------------
-- 是否是公会成员 (是否已加入公会)
function ClanData:isClanMember()
    return not (self:getUserIdentity() == ClanConfig.userIdentity.NON)
end

function ClanData:canCreateClan()
    return self.createClan
end

function ClanData:getGemCost()
    return self.createGems or 0
end

-- 获取玩家身份信息
function ClanData:getUserIdentity()
    return self.userIdentity or ClanConfig.userIdentity.NON 
end
-- 获取玩家身份信息 old
function ClanData:getUserIdentityOld()
    return self.userIdentityOld or ClanConfig.userIdentity.NON 
end
function ClanData:resetUserIdentityOld()
    self.userIdentityOld = self:getUserIdentity()
end
-- 公会分享地址
function ClanData:getFbShareUrl()
return self.m_shareUrl
end

------------  任务和挑战  ------------
-- 是否展示领取任务奖励面板
function ClanData:willShowTaskReward()
    return self.m_pointState == ClanConfig.LastTaskState.UNDONE or self.m_pointState == ClanConfig.LastTaskState.DONE
end
function ClanData:resetLastTaskSign()
    self.m_pointState = ClanConfig.LastTaskState.COLLECTED
end

function ClanData:getLastTaskSign()
    return self.m_pointState
end

-- 获取公会任务奖励列表
function ClanData:getTaskRewardList()
    return self.m_taskRewardsList or {}
end

-- 获取当前任务进度数据
function ClanData:getTaskData()
    return self.m_taskData
end

-- 获取个人的点数
function ClanData:getMyPoints()
    if not self.m_taskData then
        return 0
    end
    return self.m_taskData.myPoints or 0
end
function ClanData:getMyTotalPoints()
    if not self.m_taskData then
        return 0
    end
    return self.m_taskData.myTotalPoints or 0 
end

-- 获取任务 倒计时
function ClanData:getClanLeftTime()
    local taskData = self:getTaskData() or {}
    local expireAt = tonumber(taskData.expireAt) or 0
    if expireAt <= 0 then
        return 0
    end
    return math.floor(util_getLeftTime(expireAt))
end
-- 获取任务 到期时间戳
function ClanData:getClanTaskExpireAt()
    local taskData = self:getTaskData() or {}
    local expireAt = tonumber(taskData.expireAt) or 0
    return expireAt * 0.001
end

-- 公会索要卡片的CD
function ClanData:getReqCardCD()
    return self.m_requestCardCD or 0
end
function ClanData:setReqCardCD(_cb)
    self.m_requestCardCD = tonumber(_cb) or 0
end

-- 获取改名字消耗消耗第二货币数量
function ClanData:getUpdateNameGems()
    return self.m_updateNameGems
end

--------- 排行榜 信息 ------------
function ClanData:parseSelfRankInfo(_clanBaseInfo)
    self.m_selfBenifitData:parseData(_clanBaseInfo.interest) -- 本公会最新权益
    self.m_clanRankInfo.benifitData =  self.m_selfBenifitData
    self.m_clanRankInfo.division    =  self.m_selfBenifitData:getDivision() -- 排行榜 段位
    self.m_clanSimpleInfo:setTeamDivision(self.m_selfBenifitData:getDivision()) -- 排行榜 段位
    self.m_clanRankInfo.roomNum     =  _clanBaseInfo.roomNum or 0 -- 排行榜 房间
    self.m_clanRankInfo.rankUp      =  _clanBaseInfo.rankUp or 0 -- 行榜 排名上升的幅度
    self.m_clanRankInfo.rank        =  math.max(1, _clanBaseInfo.rank or 1) -- 行榜 排名
    self.m_clanRankInfo.rankPoints  =  _clanBaseInfo.rankPoints or 0 -- 行榜 点数
    self.m_clanRankInfo.bPopReportLayer = _clanBaseInfo.displayedDivision -- 排行榜结算是否谈过结算面板
    self.m_clanRankInfo.lastDivision  =  math.max(1, _clanBaseInfo.lastDivision or 1) -- 段位变化 值 
    self.m_clanRankInfo.rankCoins   =  tonumber(_clanBaseInfo.rankCoins) or 0 -- 段位奖励金币值 
    self.m_clanRankInfo.rankItems   =  self:parseRankRewardItems(_clanBaseInfo.rankItems or {}) -- 段位奖励的道具
    self.m_clanRankInfo.rankHighLimitPoints = tonumber(_clanBaseInfo.rankHighLimitPoints) or 0 --排行榜 高倍场点数
end

function ClanData:syncMyRankInfo(_rankCellData)
    if not _rankCellData then
        return
    end

    self.m_clanRankInfo.rank        =  _rankCellData:getRank() -- 行榜 排名
    self.m_clanRankInfo.rankPoints  =  _rankCellData:getPoints() -- 行榜 点数

    -- 更新公会排行榜数据后， 发现公会的点数大于当前公会基本信息里的点数了。更新下公会基本信息里的点数
    if self.m_taskData and tonumber(self.m_taskData.current) < self.m_clanRankInfo.rankPoints then
        self.m_taskData.current = self.m_clanRankInfo.rankPoints
    end
end
-- 获取本功会的排行信息
function ClanData:getSelfClanRankInfo()
    return self.m_clanRankInfo
end
function ClanData:resetPopReportLayerSign()
    self.m_clanRankInfo.bPopReportLayer = true -- 排行榜结算是否谈过结算面板
    self:setCanReqNewTopRank(true)
end
-- 解析本公会排行榜 奖励道具
function ClanData:parseRankRewardItems(_items)
    local itemList = {}
    for k, data in ipairs(_items) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)
        table.insert(itemList, shopItem)
    end

    return itemList
end

-- 排行榜总数据
function ClanData:parseClanRankData(_rankInfo)
    self.m_rankData:parseData(_rankInfo, self.m_clanRankInfo.division, self.m_clanSimpleInfo:getTeamCid(), self.m_taskData and self.m_taskData.current or nil)
end
function ClanData:getClanRankData()
    return  self.m_rankData
end

-- 最强工会信息
function ClanData:parseRankTopListData(_data)
    self.m_topTeamRankData:parseData(_data, self.m_clanSimpleInfo:getTeamCid())
    self:setCanReqNewTopRank(false)
end
function ClanData:getRankTopListData()
    return self.m_topTeamRankData
end

-- 最强百人信息
function ClanData:parseRankTopMembersListData(_data)
    self.m_topMembersRankData:parseData(_data, self.m_clanSimpleInfo:getTeamCid())
    self:setCanReqNewTopRank(false)
end
function ClanData:getRankTopMembersListData()
    return self.m_topMembersRankData
end

-- 是否可以拉取最新的 最强功会排行
function ClanData:checkCanReqNewTopRank()
    if self.m_bCanReqNewTopRank == nil then
        self:setCanReqNewTopRank(true)
    end
    return self.m_bCanReqNewTopRank
end
function ClanData:setCanReqNewTopRank(_bCanReq)
    self.m_bCanReqNewTopRank = _bCanReq
end

-- 本公会各成员奖励
function ClanData:parseRankMemberRewardData(_list)
    self:parseMemberData(_list, "ClanRankUser") 
end
--------- 排行榜 信息 ------------

function ClanData:parseRushData(_data)
    self.m_teamRushData:parseData(_data)
end

-- 获取公会rush任务数据
function ClanData:getTeamRushData()
    return self.m_teamRushData
end

-- 本公会 数据是否初始化过
function ClanData:checkInitServerData()
    return self.m_bInitServerData
end

------------------ 公会 红包 ------------------
-- 解析 红包礼物信息
function ClanData:parseRedGiftData(_list)
    self.m_teamRedGiftList = {}    -- 公会红包礼物列表
    for i=1, #_list do
        local redGiftData = ClanRedGiftSingleData:create(i)
        redGiftData:parseData(_list[i])

        table.insert(self.m_teamRedGiftList, redGiftData)
    end
end
function ClanData:getRedGiftList()
    return self.m_teamRedGiftList or {}
end
------------------ 公会 红包 ------------------

------------------ 公会 对决 ------------------
function ClanData:parseClanDuelData(_data)
    self.m_clanDuelData:parseData(_data, self.m_clanSimpleInfo)
end

function ClanData:getClanDuelData()
    return self.m_clanDuelData
end
------------------ 公会 对决 ------------------

---------------------------------------------------  获取相关数据接口  ---------------------------------------------------

return ClanData
