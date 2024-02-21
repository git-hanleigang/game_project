--[[--
    装修活动总数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local RedecorTreasureData = import(".RedecorTreasureData")
local RedecorChapterData = import(".RedecorChapterData")
local RedecorFullViewData = import(".RedecorFullViewData")
local RedecorPlotConfigData = import(".RedecorPlotConfigData")
local RedecorPlotTextConfigData = import(".RedecorPlotTextConfigData")
local RedecorNodeConfigData = import(".RedecorNodeConfigData")
local RedecorTreasureInfoData = import(".RedecorTreasureInfoData")
local RedecorWheelResultData = import(".RedecorWheelResultData")

local RedecoratePlotConfig = import("..config.RedecoratePlotConfig")
local RedecoratePlotTextConfig = import("..config.RedecoratePlotTextConfig")
local RedecorateNodeConfig = import("..config.RedecorateNodeConfig")

local BaseActivityData = util_require("baseActivity.BaseActivityData")
local RedecorData = class("RedecorData", BaseActivityData)

-- message Redecorate {
--     optional string activityId = 1;    //活动 id
--     optional int64 expireAt = 2;      //活动截止时间
--     optional int64 expire = 3;        //活动剩余时间
--     optional int32 curChapter = 4;  //当前章节
--     optional int32 chapterMax = 5;  //最大章节
--     optional int32 curRound = 6;  //当前轮数
--     optional int32 material = 7;  //材料数量
--     optional int32 materialMax = 8;  //材料上限
--     repeated RedecorateChapter chapters = 9;  //章节
--     optional int32 collect = 10;  //收集能量
--     optional int32 collectMax = 11;  //最大收集能量
--     repeated RedecorateTreasure treasures = 12;  //玩家的宝箱
--     optional int32 treasureMax = 13;  //最大宝箱数量
--     optional int64 roundCoins = 14;    //轮次奖励金币
--     repeated ShopItem roundItems = 15;    //轮次奖励物品
--     optional int32 zone = 16;  //排行榜 赛区
--     optional int32 roomType = 17;  //排行榜 房间类型
--     optional int32 roomNum = 18;  //排行榜 房间数
--     optional int32 rankUp = 19; //排行榜排名上升的幅度
--     optional int32 rank = 20; //排行榜排名
--     optional int32 points = 21; //排行榜点数
--     repeated RedecorateTreasure lastTreasures = 22;  //玩家溢出的宝箱
--     repeated RedecorateTreasureInfo treasureInfos = 23;  //宝箱配置信息
--     optional int32 doubleWheel = 24;  //双指针剩余次数
--     optional int32 addition = 25;  //章节奖励加成
--   }
function RedecorData:parseData(data, isJson, isNetData)
    RedecorData.super.parseData(self, data, isJson)

    self.p_curChapter = data.curChapter
    self.p_chapterMax = data.chapterMax
    self.p_curRound = data.curRound
    self.p_material = data.material
    self.p_materialMax = data.materialMax

    self.p_chapters = {}
    if data.chapters and #data.chapters > 0 then
        for i = 1, #data.chapters do
            local chapterData = RedecorChapterData:create()
            chapterData:parseData(data.chapters[i])
            table.insert(self.p_chapters, chapterData)
        end
    end
    self.p_collect = data.collect
    self.p_collectMax = data.collectMax

    self.p_treasures = {}
    if data.treasures and #data.treasures > 0 then
        for i = 1, #data.treasures do
            local giftData = RedecorTreasureData:create()
            giftData:parseData(data.treasures[i])
            table.insert(self.p_treasures, giftData)
        end
    end

    self.p_lastTreasures = {}
    if data.lastTreasures and #data.lastTreasures > 0 then
        for i = 1, #data.lastTreasures do
            local giftData = RedecorTreasureData:create()
            giftData:parseData(data.lastTreasures[i])
            table.insert(self.p_lastTreasures, giftData)
        end
    end

    self.p_wheelTreasures = {}
    if data.wheelTreasures and #data.wheelTreasures > 0 then
        for i = 1, #data.wheelTreasures do
            local giftData = RedecorTreasureData:create()
            giftData:parseData(data.wheelTreasures[i])
            table.insert(self.p_wheelTreasures, giftData)
        end
    end

    self.p_treasureInfos = {}
    if data.treasureInfos and #data.treasureInfos > 0 then
        for i = 1, #data.treasureInfos do
            local tInfo = RedecorTreasureInfoData:create()
            tInfo:parseData(data.treasureInfos[i])
            table.insert(self.p_treasureInfos, tInfo)
        end
    end

    self.p_treasureMax = data.treasureMax

    self.p_roundCoins = tonumber(data.roundCoins)

    self.p_roundItems = {}
    if data.roundItems and #data.roundItems > 0 then
        for i = 1, #data.roundItems do
            local rItemData = ShopItem:create()
            rItemData:parseData(data.roundItems[i])
            table.insert(self.p_roundItems, rItemData)
        end
    end

    self.p_zone = data.zone
    self.p_roomType = data.roomType
    self.p_roomNum = data.roomNum
    -- self.p_rankUp = data.rankUp
    -- self.p_rank = data.rank
    self.p_points = data.points

    self.p_doubleWheel = data.doubleWheel
    self.p_addition = data.addition

    self.p_isGroupB = data.abtestGroup
    -- self:setABTest(true)

    self:initCsvConfig()

    self:setFurnitureDatas()

    release_print("---------------------------------------------------- data parse done")
    -- 刷新数据
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.Redecor})
end

function RedecorData:setABTest(_isBGroup)
    self.p_isGroupB = _isBGroup
end

function RedecorData:getABTest()
    return self.p_isGroupB and self.p_isGroupB == "B"
end

function RedecorData:initCsvConfig()
    -- 剧情配置
    if not self.m_initPlotsCfg then
        self.m_initPlotsCfg = true
        if RedecoratePlotConfig and #RedecoratePlotConfig > 0 then
            self.cfg_plots = {}
            for i = 1, #RedecoratePlotConfig do
                if i > 1 then
                    local plotConfig = RedecorPlotConfigData:create()
                    plotConfig:parseData(RedecoratePlotConfig[i])
                    table.insert(self.cfg_plots, plotConfig)
                end
            end
        end
    end
    -- 剧情文本配置
    if not self.m_initPlotTextsCfg then
        self.m_initPlotTextsCfg = true
        if RedecoratePlotTextConfig and #RedecoratePlotTextConfig > 0 then
            self.cfg_plotTexts = {}
            for i = 1, #RedecoratePlotTextConfig do
                if i > 1 then
                    local plotTextConfig = RedecorPlotTextConfigData:create()
                    plotTextConfig:parseData(RedecoratePlotTextConfig[i])
                    table.insert(self.cfg_plotTexts, plotTextConfig)
                end
            end
        end
    end
    -- 家具节点配置
    if not self.m_initNodesCfg then
        self.m_initNodesCfg = true
        if RedecorateNodeConfig and #RedecorateNodeConfig > 0 then
            self.cfg_nodes = {}
            for i = 1, #RedecorateNodeConfig do
                if i > 1 then
                    local nodeConfig = RedecorNodeConfigData:create()
                    nodeConfig:parseData(RedecorateNodeConfig[i])
                    table.insert(self.cfg_nodes, nodeConfig)
                end
            end
        end
    end
end

-- 当前章节
function RedecorData:getCurChapter()
    return self.p_curChapter
end
-- 最大章节
function RedecorData:getChapterMax()
    return self.p_chapterMax
end
-- 当前轮数
function RedecorData:getCurRound()
    return self.p_curRound
end

-- 材料数量
function RedecorData:getMaterialNum()
    return self.p_material
end
function RedecorData:setMaterialNum(_materialNum)
    self.p_material = _materialNum
end
-- 材料上限
function RedecorData:getMaterialMax()
    return self.p_materialMax
end
function RedecorData:setMaterialMax(_materialMax)
    self.p_materialMax = _materialMax
end
-- 章节
function RedecorData:getChapters()
    return self.p_chapters
end
-- 收集能量
function RedecorData:getCollectNum()
    return self.p_collect
end
function RedecorData:setCollectNum(_collectNum)
    self.p_collect = _collectNum
end
-- 最大收集能量
function RedecorData:getCollectMax()
    return self.p_collectMax
end
function RedecorData:setCollectMax(_collectMax)
    self.p_collectMax = _collectMax
end
-- 玩家的礼物
function RedecorData:getTreasures()
    return self.p_treasures
end
-- 最大宝箱数量
function RedecorData:getTreasureMax()
    return self.p_treasureMax
end
-- 轮次奖励金币
function RedecorData:getRoundCoins()
    return self.p_roundCoins
end
-- 轮次奖励物品
function RedecorData:getRoundItems()
    return self.p_roundItems
end
-- 排行榜 赛区
function RedecorData:getZone()
    return self.p_zone
end
-- 排行榜 房间类型
function RedecorData:getRoomType()
    return self.p_roomType
end
-- 排行榜 房间数
function RedecorData:getRoomNum()
    return self.p_roomNum
end
-- -- 排行榜排名上升的幅度
-- function RedecorData:getRankUp()
--     return self.p_rankUp
-- end
-- -- 排行榜排名
-- function RedecorData:getRank()
--     return self.p_rank
-- end
-- 排行榜点数
function RedecorData:getPoints()
    return self.p_points
end
-- 双指针剩余次数
function RedecorData:getDoubleWheel()
    return self.p_doubleWheel
end
-- 章节奖励加成
function RedecorData:getAddition()
    return self.p_addition
end
-- 玩家溢出的宝箱
function RedecorData:getLastTreasures()
    return self.p_lastTreasures
end
-- 轮盘赠送的宝箱
function RedecorData:getWheelTreasures()
    return self.p_wheelTreasures
end
-- 礼盒配置
function RedecorData:getTreasureInfos()
    return self.p_treasureInfos
end
-- 剧情
function RedecorData:getPlotsCfg()
    return self.cfg_plots
end
-- 对话
function RedecorData:getPlotTextsCfg()
    return self.cfg_plotTexts
end
-- 家具客户端配置
function RedecorData:getNodesCfg()
    return self.cfg_nodes
end

---促销用函数-------------------------------------
-- 双指针剩余次数
function RedecorData:getHits()
    return self:getDoubleWheel()
end

-- 获取金票持有的最大值(商城和促销购买获得的)
function RedecorData:getHitsMax()
    return self.hitsLimit or 100
end

---打点用函数-------------------------------------
function RedecorData:getSequence()
    return self.p_curRound
end

function RedecorData:getCurrent()
    return self.p_curChapter
end

function RedecorData:getCurChapterCompletedNum()
    local curChapterData = self:getCurChapterData()
    return curChapterData:getCompletedNodeNum()
end

---大厅小红点-------------------------------------
function RedecorData:getLobbyRedNum()
    -- local redNum = 0
    -- local chapterData = self:getCurChapterData()
    -- local waitNodeDatas = chapterData:getCurChapterWaitNodes()
    -- if waitNodeDatas and #waitNodeDatas > 0 then
    --     for i = 1, #waitNodeDatas do
    --         local nodeData = waitNodeDatas[i]
    --         if self:getMaterialNum() >= nodeData:getMaterial() then
    --             redNum = redNum + 1
    --         end
    --     end
    -- end
    -- return redNum
    local wheelNum = self:getMaterialNum()
    return wheelNum or 0
end
------------------------------------------------

---关卡弹框增加逻辑判断-------------------------------------
function RedecorData:isTicketEnough()
    if self:getLobbyRedNum() > 0 then
        return true
    end
    return false
end
------------------------------------------------

------------------------------------------------
-- 获得家具客户端配置
function RedecorData:getFurnitureCfgByRefName(_refName)
    local nodesCfg = self:getNodesCfg()
    if nodesCfg and #nodesCfg > 0 then
        for i = 1, #nodesCfg do
            local nodeCfg = nodesCfg[i]
            if nodeCfg:getRefName() == _refName then
                return nodeCfg
            end
        end
    end
end

-- 获得所有家具
function RedecorData:setFurnitureDatas()
    self.m_furnitures = {}
    if self.p_chapters and #self.p_chapters > 0 then
        for i = 1, #self.p_chapters do
            local chapter = self.p_chapters[i]
            local chapterNodes = chapter:getNodes()
            if chapterNodes and #chapterNodes > 0 then
                for j = 1, #chapterNodes do
                    table.insert(self.m_furnitures, chapterNodes[j])
                end
            end
        end
    end
end

function RedecorData:getFurnitureDatas()
    return self.m_furnitures
end

-- 获取轮盘默认家具的引用名
function RedecorData:getCurFurnitureRefName()
    local chapterData = self:getCurChapterData()
    local waitNodeDatas = chapterData:getCurChapterWaitNodes()
    if waitNodeDatas and #waitNodeDatas > 0 then
        local wNodeData = waitNodeDatas[1]
        if wNodeData then
            return wNodeData:getRefName()
        else
            release_print("---- getCurFurnitureRefName wNodeData is nil ----")
        end
    else
        release_print("---- getCurFurnitureRefName waitNodeDatas is nil ----")
    end
end

function RedecorData:getFurnitureDataByRefName(_refName)
    local fNodesData = self:getFurnitureDatas()
    if fNodesData and #fNodesData > 0 then
        for i = 1, #fNodesData do
            local fNode = fNodesData[i]
            if fNode:getRefName() == _refName then
                return fNode
            end
        end
    end
end

function RedecorData:getCompleteFurnitureCount()
    local completeCount = 0
    local fNodesData = self:getFurnitureDatas()
    if fNodesData and #fNodesData > 0 then
        for i = 1, #fNodesData do
            local fNode = fNodesData[i]
            if fNode:isComplete() then
                completeCount = completeCount + 1
            end
        end
    end
    return completeCount
end

-- 判断是当前是不是清理操作
-- 只能在界面初始化的时候使用
function RedecorData:isClean()
    local fNodesData = self:getFurnitureDatas()
    if fNodesData and #fNodesData > 0 then
        for i = 1, #fNodesData do
            local fNode = fNodesData[i]
            if fNode:isClean() and not fNode:isComplete() then
                return true
            end
        end
    end
    return false
end

-- 获得礼盒数据
function RedecorData:getTreasureDataByOrder(_order, isLast)
    local tsData = nil
    if isLast then
        tsData = self:getLastTreasures()
    else
        tsData = self:getTreasures()
    end
    if tsData and #tsData > 0 then
        for i = 1, #tsData do
            local tData = tsData[i]
            if tData:getOrder() == _order then
                return tData
            end
        end
    end
    return nil
end

-- 获得当前关卡数据
function RedecorData:getCurChapterData()
    return self.p_chapters[self.p_curChapter]
end

function RedecorData:getPlotsCfgById(_plotId)
    local plotList = {}
    local psCfg = self:getPlotsCfg()
    if psCfg and #psCfg > 0 then
        for i = 1, #psCfg do
            local pData = psCfg[i]
            if pData:getPlotId() == _plotId then
                return pData
            end
        end
    end
    assert(false, "!!! ERROR[MAQUN] dont have _plotId " .. _plotId)
end

function RedecorData:getPlotTextsCfgById(_textId)
    local plotList = {}
    local ptsCfg = self:getPlotTextsCfg()
    if ptsCfg and #ptsCfg > 0 then
        for i = 1, #ptsCfg do
            local ptData = ptsCfg[i]
            if ptData:getId() == _textId then
                return ptData
            end
        end
    end
    assert(false, "!!! ERROR[MAQUN] dont have _textId " .. _textId)
end

--获取入口位置 1：左边，0：右边
function RedecorData:getPositionBar()
    return 1
end

--[[
    @desc: 
    author:{author}
    time:2021-06-08 12:08:59
    --@_netData: 
    @return:
]]
function RedecorData:parseRankConfig(_netData)
    if _netData == nil then
        return
    end

    if not self.p_rankConfig then
        self.p_rankConfig = BaseActivityRankCfg:create()
    end
    self.p_rankConfig:parseData(_netData)
    local myRankConfig = self.p_rankConfig:getMyRankConfig()
    if myRankConfig ~= nil then
        self:setRank(myRankConfig.p_rank)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.Redecor})
end

function RedecorData:getRankConfig()
    return self.p_rankConfig
end

function RedecorData:parseWheelResultData(_netData)
    if _netData == nil or _netData == "" then
        return
    end
    if not self.p_wheelResultData then
        self.p_wheelResultData = RedecorWheelResultData:create()
    end
    self.p_wheelResultData:parseData(_netData)
end

function RedecorData:getWheelResultData()
    return self.p_wheelResultData
end

function RedecorData:clearWheelResultData()
    self.p_wheelResultData = nil
end

--[[--
    fullview数据
]]
function RedecorData:parseFullViewData(_netData)
    self.m_hasFullView = true
    self.p_fullViews = {}
    if _netData and #_netData > 0 then
        for i = 1, #_netData do
            local fvData = RedecorFullViewData:create()
            fvData:parseData(_netData[i])
            table.insert(self.p_fullViews, fvData)
        end
    end
end

function RedecorData:hasFullViewData()
    return self.m_hasFullView == true
end

function RedecorData:getFullViewData()
    return self.p_fullViews
end

function RedecorData:getCurFullViewData()
    return self.p_fullViews[1]
end

-- 客户端缓存 手动更改数据
function RedecorData:setFullViewNodeData(_activityName, _nodeId, _style)
    local fvsData = self:getFullViewData()
    if fvsData and #fvsData > 0 then
        for i = 1, #fvsData do
            local fvData = fvsData[i]
            if fvData:getActivityName() == _activityName then
                local nodeData = fvData:getFurnitureDataByNodeId(_nodeId)
                if nodeData then
                    nodeData:setCurStyle(_style)
                end
            end
        end
    end
end

return RedecorData
