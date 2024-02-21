--道具管理
local ShopItem = util_require("data.baseDatas.ShopItem")
local ItemManager = class("ItemManager")
-- FIX IOSxx
ItemManager.m_instance = nil
-- 通用道具不同尺寸的资源路径
GD.ITEM_PATH = {
    SIZE_128 = "PBRes/CommonItemRes/icon/", -- 128X128
    SIZE_320 = "PBRes/CommonItemRes/icon320x320/" -- 320X320
}
--道具尺寸类型
GD.ITEM_SIZE_TYPE = {
    REWARD_BIG = 1, --道具最大 icon 1.5     更大的图标传这个在整体缩放
    REWARD = 2, --奖励道具 icon 正常尺寸128
    BATTLE_PASS = 3, --特殊活动道具 icon 0.7     --奖励描述都是放在正下方不受位置影响
    TOP = 4, --排行榜图标 icon 0.55   更小的图标传这个在整体缩放
    REWARD_SUPER = 5, -- 320x320 2.5
    SIDEKICKS = 6   -- 宠物专用
}
--数值显示位置标记
GD.ITEM_MARK_TYPE = {
    NONE = 0, --无角标
    CENTER_X = 1, --右下角×角标
    CENTER_ADD = 2, --下方居中加号角标
    CENTER_BUFF = 3, --下方居中无符号(BUFF&金币)
    CARD = 4, --集卡特殊卡包占用
    CENTER_X_ITEM = 5, -- 拓展给reward size 使用角标居中
    ONLYONE = 6, --只显示X1
    MIDDLE_X = 7, --下方居中x角标
}
--道具描述按节点显示值
GD.ITEM_DESC_NODEVALUE = {
    NODE_STAR = "NODE_STAR", --星星
    NODE_JACKPOT_RETURN = "RETURN"
}
--特殊道具(和统一规范有差异的道具)
GD.ITEM_SPECIAL_LIST = {
    --集卡特殊道具
    Card_Star_1 = "PBCode2.IconCardNode",
    Card_Star_2 = "PBCode2.IconCardNode",
    Card_Star_3 = "PBCode2.IconCardNode",
    Card_Star_4 = "PBCode2.IconCardNode",
    Card_Star_5 = "PBCode2.IconCardNode",
    --折扣卷特殊道具
    Coupon1 = "PBCode2.IconCouponNode",
    Coupon2 = "PBCode2.IconCouponNode",
    Coupon3 = "PBCode2.IconCouponNode",
    --CASHBACK道具
    CashBack = "PBCode2.IconCashBackNode"
}
--兼容老数据道具命名
local ItemOldIcoinList = {
    --兼容集卡道具Icon命名
    card_4link_b = "Card_Nado_4",
    card_4link = "Card_Nado_4",
    card_4link1 = "Card_Nado_4_Gray",
    card_5link_b = "Card_Nado_5",
    card_5link = "Card_Nado_5",
    card_5link1 = "Card_Nado_5_Gray",
    card_5putong = "Card_Normal_5",
    card_5putong1 = "Card_Normal_5_Gray",
    card_kabao_b = "Card_Normal_Package",
    card_kabao = "Card_Normal_Package",
    card_kabao1 = "Card_Normal_Package_Gray",
    card_linkkabao = "Card_Nado_Package",
    card_linkkabao1 = "Card_Nado_Package_Gray",
    card_wild = "Card_Any_Wild",
    card_wild1 = "Card_Any_Wild_Gray",
    Rank_1 = "Card_Nado_5",
    Rank_2 = "Card_Nado_4",
    Rank_3 = "Card_Star_4",
    Rank_4 = "Card_Star_4",
    Rank_5 = "Card_Star_3",
    Rank_6 = "Card_Star_3",
    Rank_7 = "Card_Star_2",
    Rank_8 = "Card_Star_5",
    Rank_9 = "Card_Star_4",
    Rank_10 = "Card_Normal_4or5",
    Rank_11 = "Card_Gold_4",
    Rank_12 = "Card_Gold_5",
    Rank_13 = "Card_Normal_4",
    Rank_14 = "Card_Normal_5",
    Rank_15 = "Card_Gold_3",
    Rank_card_wild = "Card_Any_Wild",
    Rank_card_wild2 = "Card_Normal_Wild",
    Rank_card_wild3 = "Card_Gold_Wild",
    Rank_card_wild4 = "Card_Nado_Wild",
    -- --额外金币
    ExtraCoins = "shop_tanban_extra"
}

local _itemModels = {}

--单例
function ItemManager:getInstance()
    if ItemManager.m_instance == nil then
        ItemManager.m_instance = ItemManager.new()
    end
    return ItemManager.m_instance
end
--构造函数
function ItemManager:ctor()
    self:initData()
    self:registerObservers()
end
--初始化数据
function ItemManager:initData()
    -- ExtraCoins
end
--清除数据
function ItemManager:clearData()
end
--注册事件
function ItemManager:registerObservers()
end
-----------------------------------------------------功能 START
--创建通用奖励道具
function ItemManager:createRewardNode(data, itemSizeType, mul)
    return self:createBaseNode("PBCode2.ItemRewardNode", data, itemSizeType, mul)
end
--创建描述详细信息道具
function ItemManager:createDescNode(data, itemSizeType, mul)
    return self:createBaseNode("PBCode2.ItemDescNode", data, itemSizeType, mul)
end
--创建描述详细信息道具 只显示道具数量
function ItemManager:createDescSingleNumNode(data, itemSizeType, mul)
    return self:createBaseNode("PBCode2.ItemDescSingleNumNode", data, itemSizeType, mul)
end
--创建描述详细信息道具 -- 商城新版 说明node 新字体新大小，后续别的模块也可以使用
function ItemManager:createDescShopBenefitNode(data, itemSizeType, mul)
    return self:createBaseNode("PBCode2.ItemDescNodeShop22", data, itemSizeType, mul)
end
--创建支付成功的提示道具
function ItemManager:createTipNode(data, itemSizeType, mul)
    return self:createBaseNode("PBCode2.ItemTipNode", data, itemSizeType, mul)
end
--创建道具父函数
function ItemManager:createBaseNode(luaName, data, itemSizeType, mul)
    if not luaName then
        return
    end
    local newData = self:createLocalItemData(data.p_icon, data.p_num, data)
    if not newData or not newData.p_icon or newData.p_icon == "" then
        return
    end
    local newIcon = self:getOldToNewIcon(newData.p_icon)
    if string.find(newIcon, "PropFrame_") then
        return util_createView(luaName, newData, newIcon, itemSizeType, mul)
    end
    
    local path = itemSizeType == ITEM_SIZE_TYPE.REWARD_SUPER and ITEM_PATH.SIZE_320 or ITEM_PATH.SIZE_128
    if not util_IsFileExist(path .. newIcon .. ".png") then
        local errorMsg = "ERROR,Item Create Fail --- luaName =  " .. luaName .. " path = " .. path .. newIcon .. ".png"
        util_sendToSplunkMsg("ItemManager_createBaseNode", errorMsg)
        newIcon = "unknown"
    end

    return util_createView(luaName, newData, newIcon, itemSizeType, mul)
end

function ItemManager:updateItem(item, newData, itemSizeType, mul)
    if tolua.isnull(item) then
        return
    end
    if not newData or not newData.p_icon or newData.p_icon == "" then
        return
    end
    local newIcon = self:getOldToNewIcon(newData.p_icon)
    local path = nil
    if itemSizeType == ITEM_SIZE_TYPE.REWARD_SUPER then
        path = ITEM_PATH.SIZE_320 .. newIcon .. ".png"
    else
        path = ITEM_PATH.SIZE_128 .. newIcon .. ".png"
    end
    if path and util_IsFileExist(path) or string.find(newIcon, "PropFrame_") then
        if newData then
            --刷新显示用的临时数据
            if newData.updateTempData then
                newData:updateTempData()
            end
            local luaName = item.__cname
            -- local new_item = require("PBCode2." .. luaName)
            -- new_item:create()
            -- new_item:initDatas(newData, newIcon, itemSizeType, mul)
            -- local new_path = new_item:getCsbPath()

            -- local luaModel = _itemModels[luaName]
            -- if not luaModel then
            --     luaModel = require("PBCode2." .. luaName)
            --     _itemModels[luaName] = luaModel
            -- end
            -- local new_path = luaModel._getCsbPath(itemSizeType)
            -- local lua_path = item:getCsbPath()

            -- if lua_path == new_path then
                item:resetUI(newData, newIcon, itemSizeType, mul)
                self:setItemNodeByExtraData(newData, item, mul)
            -- else
            --     item.m_csbNode:removeSelf()
            --     item.m_csbAct = nil
            --     item:initUI()
            -- end
        end
    end
end

--增加道具列表ItemDataList道具数据列表,type类型四种大小,scale统一缩放值,width间距,isLeft是否左对齐tempData非服务器配置前端强制更改数据
--如果需要穿插特殊节点 ItemDataList[#ItemDataList+1] = {baseItemNode = 已经创建好的特殊节点}
function ItemManager:addPropNodeList(ItemDataList, itemSizeType, scale, width, isLeft, tempData)
    scale = scale or 1
    width = width or self:getIconDefaultWidth(itemSizeType)
    local baseNode = cc.Node:create()
    local itemNodeList = {}
    for i = 1, #ItemDataList do
        local itemData = ItemDataList[i]
        local itemNode = nil
        local baseScale = scale
        if itemData.baseItemNode then
            itemNode = itemData.baseItemNode
            --如果存在设计尺寸根据当前其他道具大小缩放传入道具
            if itemData.baseScale then
                baseScale = baseScale * itemData.baseScale
            end
            ----------- 特殊节点可能没有 触摸接口 -----------
            if not itemNode.setIconTouchEnabled then
                itemNode["setIconTouchEnabled"] = function() end
            end
            if not itemNode.setIconTouchSwallowed then
                itemNode["setIconTouchSwallowed"] = function() end
            end
            ----------- 特殊节点可能没有 触摸接口 -----------
        else
            if tempData then
                --因为显示需求强制该更的临时数据
                itemData:setTempData(tempData, false)
            end
            itemNode = self:createRewardNode(itemData, itemSizeType)
        end
        if itemNode then
            baseNode:addChild(itemNode)
            itemNode:setTag(i)
            itemNode:setScale(baseScale)
            local nodeData = {node = itemNode, size = cc.size(width, 0), anchor = cc.p(0.5, 0.5)}
            itemNodeList[#itemNodeList + 1] = nodeData
        end
    end
    if isLeft then
        util_alignLeft(itemNodeList)
    else
        util_alignCenter(itemNodeList, 0)
    end
    return baseNode
end
--创建收益道具提示saleData大部分为促销数据
function ItemManager:createInfoPBNode(saleData, itemList, isOneLine, sourceName)
    itemList = self:checkAddLocalItemList(saleData, itemList, sourceName)
    local infoNode = util_createFindView("PBCode2/PBTipsNode", itemList, isOneLine, isOneLine)
    return infoNode
end

--创建道具列表布局（非通用道具奖励界面内部调用这个布局）itemList道具列表(必填),size布局大小默认800x400
-- csc 2022-01-26 list 提供新的接口，允许一行多列以及自定义cell间距和缩放
-- maxCount 最大个数 默认5个
-- nodeSpace 自定义itemnode 的宽高 ， 默认是 itemType_rewardBig  192x192 的大小
-- scale 自定义 缩放， 默认是 0.87
function ItemManager:createRewardListView(itemList, size, maxCount, nodeSpace, scale, doublePos, onelineNoScale)
    return util_createView("PBCode2.ItemRewardList", itemList, size, maxCount, nodeSpace, scale, doublePos, onelineNoScale)
end
--创建通用道具奖励界面 itemList道具列表(必填),clickFunc点击回调,flyCoins飞金币数量,skipRotate是否跳过横竖屏翻转处理
-- theme 选填 根据不同主题 显示不同UI
function ItemManager:createRewardLayer(itemList, clickFunc, flyCoins, skipRotate, theme, nodeSize)
    return util_createView("PBCode2.ItemRewardLayer", itemList, clickFunc, flyCoins, skipRotate, theme, nodeSize)
end
--手动添加本地道具
--自定义促销数据
--saleData = {p_keyId = 支付id,p_price = 价格,p_vipPoint = vip点数,clubPoints = 高倍场点数}
--(支付id和价格选填一个其他可以不填有默认值)
function ItemManager:checkAddLocalItemList(saleData, itemList, sourceName, _notRemoveSame)
    if not saleData then
        return {}
    end
    if not itemList then
        itemList = {}
    else
        itemList = clone(itemList)
    end
    local iapKey = saleData.p_keyId
    local iapPrice = saleData.p_price
    local vipPoints = saleData.p_vipPoint
    local clubPoints = saleData.p_clubPoints
    --获得根据支付金额生成赠送的集卡道具
    local cardItemData = gLobalItemManager:createCardDataForIap(iapKey, iapPrice, sourceName)
    if cardItemData then
        table.insert(itemList, 1, cardItemData)
    end
    --获取支付金额对应默认的vip和高倍场点数
    local purchaseData = self:getCardPurchase(iapKey, iapPrice)
    if purchaseData then
        if not vipPoints then
            vipPoints = self:getItemVipPoints(purchaseData.p_vipPoints)
        end
        if not clubPoints then
            clubPoints = purchaseData.p_clubPoints
        end
    end
    --检测道具里面是否已经存在vip和高倍场存在不手动添加
    local isSkipVip = nil
    local isSkipDeluxeClub = nil
    if not _notRemoveSame then
        for i = 1, #itemList do
            local itemData = itemList[i]
            if itemData then
                if itemData.p_icon == "Vip" then
                    isSkipVip = true
                end
                if itemData.p_icon == "DeluxeClub" then
                    isSkipDeluxeClub = true
                end
            end
        end
    end
    if vipPoints and not isSkipVip then
        --手动增加vip道具
        itemList[#itemList + 1] = self:createLocalItemData("Vip", vipPoints)
    end
    if clubPoints and not isSkipDeluxeClub then
        --手动增加club point 道具
        itemList[#itemList + 1] = self:createLocalItemData("DeluxeClub", clubPoints)
    end
    --添加通用
    if globalData.saleRunData.checkAddCommonBuyItemTips then
        globalData.saleRunData:checkAddCommonBuyItemTips(itemList, sourceName, iapPrice)
    end
    return itemList
end

--根据用户当前vip等级重新计算vip点数(2023.08.25 新增v9配置)
function ItemManager:getItemVipPoints(baseVipPoints)
    local vipLevel = globalData.userRunData.vipLevel
    local vipData = G_GetMgr(G_REF.Vip):getData()
    local maxLevel = vipData and vipData:getMaxLevel() or 0
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if vipBoost and vipBoost:isOpenBoost() and vipLevel < maxLevel then
        local extraLevel = vipBoost:getBoostVipLevel()
        if extraLevel > 0 then
            vipLevel = vipLevel + extraLevel
        end
    end

    if vipLevel > maxLevel then
        vipLevel = maxLevel
    end
    local levelInfo = vipData and vipData:getVipLevelInfo(vipLevel)
    if levelInfo then
        baseVipPoints = baseVipPoints * levelInfo.vipPoint
    end
    return baseVipPoints
end

--获取当前等级vip图标
function ItemManager:getVipIconPath()
    -- --显示现阶段Vip图标展示
    local vipLevel = globalData.userRunData.vipLevel
    local vipData = G_GetMgr(G_REF.Vip):getData()
    local maxLevel = vipData and vipData:getMaxLevel() or 0
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if vipBoost and vipBoost:isOpenBoost() and vipLevel < maxLevel then
        local extraLevel = vipBoost:getBoostVipLevelIcon()
        if extraLevel > 0 then
            vipLevel = vipLevel + extraLevel
        end
    end
    
    if vipLevel > maxLevel then
        vipLevel = maxLevel
    end
    return ITEM_PATH.SIZE_128 .. "Vip" .. vipLevel .. ".png"
end

--常规图标路径
function ItemManager:getNormalIconPath(newIcon, itemSizeType)
    if not newIcon then
        return ""
    end
    if newIcon == "Vip" then
        return self:getVipIconPath()
    end
    if itemSizeType == ITEM_SIZE_TYPE.REWARD_SUPER then
        return ITEM_PATH.SIZE_320 .. newIcon .. ".png"
    else
        return ITEM_PATH.SIZE_128 .. newIcon .. ".png"
    end
end

--常规图标
-- function ItemManager:createNormalNode(newIcon, itemSizeType)
--     if not newIcon then
--         return
--     end
--     if newIcon == "Vip" then
--         return util_createSprite(self:getVipIconPath())
--     end
--     if itemSizeType == ITEM_SIZE_TYPE.REWARD_SUPER then
--         return util_createSprite(ITEM_PATH.SIZE_320 .. newIcon .. ".png")
--     else
--         return util_createSprite(ITEM_PATH.SIZE_128 .. newIcon .. ".png")
--     end
-- end

-- 创建头像框道具
function ItemManager:createPropFrameNode(newIcon)
    local headFrameId = string.split(newIcon, "_")[2]
    local view
    if headFrameId then
        view = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(headFrameId)
        if view then
            -- 没法算， 头像框大小不固定。只有内圈是固定的。
            view:setScale(0.36)
        end
    end
    return view
end

--检测特殊节点
function ItemManager:checkSpecialNode(newIcon)
    if newIcon and ITEM_SPECIAL_LIST[newIcon] then
        return true
    elseif string.find(newIcon, "PropFrame_") then
        return true
    end
    return false
end

--创建特殊节点
function ItemManager:createSpecialNode(data, newIcon, mul)
    if newIcon and ITEM_SPECIAL_LIST[newIcon] then
        local luaName = ITEM_SPECIAL_LIST[newIcon]
        return util_createView(luaName, data, newIcon, mul)
    elseif string.find(newIcon, "PropFrame_") then
        return self:createPropFrameNode(newIcon) 
    end
end

--创建非通用活动道具(用来和通用道具一起排列)oterNode自定义道具节点,scale自定义缩放
function ItemManager:createOtherItemData(oterNode, scale)
    return {baseItemNode = oterNode, baseScale = scale}
end
--创建客户端道具
function ItemManager:createLocalItemData(icon, num, itemData)
    --兼容各种格式道具
    if not itemData then
        itemData = ShopItem:create()
    elseif itemData.__cname and itemData.__cname == "ShopItem" then
        itemData = itemData:getData()
    elseif tolua.type(itemData) == "table" then
        local tempData = itemData
        itemData = ShopItem:create()
        for key, value in pairs(tempData) do
            itemData[key] = value
        end
    else
        itemData = ShopItem:create()
    end
    --设置默认限制
    if not itemData.p_limit then
        itemData.p_limit = 6 --数量显示限制最大为6位
    end
    --图标和数量
    itemData.p_icon = icon
    if num then
        itemData.p_num = num
    end
    --物品表
    if not itemData.p_itemInfo then
        itemData.p_itemInfo = {}
    end
    --物品表名字
    if not itemData.p_itemInfo.p_name then
        itemData.p_itemInfo.p_name = icon
    end
    --物品表描述
    if not itemData.p_itemInfo.p_subtitle or itemData.p_itemInfo.p_subtitle == "" then
        itemData.p_itemInfo.p_subtitle = "+%s"
    end
    --本地道具VIP和高倍场因为服务器有特殊处理客户端当本地道具处理
    if icon == "Coins" then
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}
    elseif icon == "Buck" then
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_ADD}
        -- 代币不格式化只切分
        itemData.p_formatFunc = function(_num, _limit)
            -- 代币有小数点，用字符串
            _num = "" .. _num
            return util_cutCoins(_num, true, 2)
        end    
    elseif icon == "ExtraCoins" then
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}
        itemData.p_buyTipDesc = "(SALE+VIP)"
        itemData.p_itemInfo.p_name = "BONUS COINS"
    elseif icon == "Vip" then
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_ADD}
        itemData.p_itemInfo.p_name = "VIP POINTS"
    elseif icon == "DeluxeClub" then
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_ADD}
        itemData.p_itemInfo.p_name = "CLUB POINTS"
    elseif icon == "DoubleXP" then
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}
        itemData.p_type = "Buff"
        itemData.p_buffInfo = {buffID = "nil", buffExpire = num, name = "DoubleXP", buffMultiple = "2"}
    elseif icon == "Gift" then
        itemData.p_buyTipDesc = "REWARD"
        itemData.p_itemInfo.p_name = "MYSTERY"
    elseif icon == "LuckyStamp" then
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_X}
        itemData.p_itemInfo.p_name = "STAMP CARD"
        itemData.p_num = itemData.p_num or 1
    elseif icon == "LuckyStampGolden" then
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_X}
        itemData.p_itemInfo.p_name = "STAMP CARD"
        itemData.p_num = itemData.p_num or 1    
    elseif icon == "RepeatJackpot" then
        itemData.p_itemInfo.p_name = "JACKPOT"
        itemData.p_itemInfo.p_subtitle = "RETURN"
    elseif icon == "RepeatFreeSpin" then
        itemData.p_itemInfo.p_name = "FREE GAMES"
        itemData.p_itemInfo.p_subtitle = "FEVER"
    elseif icon == "EchoWins" then
        itemData.p_itemInfo.p_name = "ECHO WINS"
        itemData.p_itemInfo.p_subtitle = ""
    elseif icon == "GrandPrize" then
        itemData.p_itemInfo.p_name = "DIAMOND COIN"
    elseif icon == "HolidayChallenge" then
        itemData.p_itemInfo.p_name = "CHEERS SPECIAL" 
    end
    --刷新显示用的临时数据
    if itemData.updateTempData then
        itemData:updateTempData()
    end
    return itemData
end
--集卡根据支付金额生成的特殊道具
function ItemManager:createLocalCardData(purchaseData)
    local star = purchaseData.p_maxStar or 1
    local itemData = ShopItem:create()
    itemData.p_limit = 6 --数量显示限制最大为6位
    itemData.p_icon = "Card_Star_" .. star
    itemData.p_num = purchaseData.p_cards
    itemData.p_mark = {ITEM_MARK_TYPE.CARD, purchaseData.p_cards, star, purchaseData.p_maxStarCards}
    itemData.p_itemInfo = {p_subtitle = ITEM_DESC_NODEVALUE.NODE_STAR, p_name = "MIN " .. purchaseData.p_maxStarCards .. " OF"}
    return itemData
end
--默认宽度
function ItemManager:getIconDefaultWidth(itemSizeType)
    if not itemSizeType then
        return 192
    end
    if itemSizeType == ITEM_SIZE_TYPE.REWARD_SUPER then
        return 320 --128*2.5
    elseif itemSizeType == ITEM_SIZE_TYPE.REWARD_BIG then
        return 192 --128*1.5
    elseif itemSizeType == ITEM_SIZE_TYPE.REWARD then
        return 128
    elseif itemSizeType == ITEM_SIZE_TYPE.BATTLE_PASS then
        return 90 --128*0.7
    elseif itemSizeType == ITEM_SIZE_TYPE.TOP then
        return 70 --128*0.55
    end
    return 192
end
--兼容旧的道具命名
function ItemManager:getOldToNewIcon(icon)
    if icon and ItemOldIcoinList[icon] then
        return ItemOldIcoinList[icon]
    else
        return icon
    end
end

--获取付费卡片道具 因为特殊不走local道具创建
function ItemManager:createCardDataForIap(IapKeyId, price, key)
    -- 新手集卡期间不显示 普通集卡 卡片
    local bCardNovice = CardSysManager:isNovice()
    if bCardNovice then
        return
    end

    -- 特殊逻辑：在某些商店或者促销中以下活动不生效
    local isCardStarAlive = true
    local isDoubleCardAlive = true
    if key then
        if key == "GemStoreItem" or key == "GemStoreTip" then
            isCardStarAlive = false
        end
        if key == "GemStoreItem" or key == "GemStoreTip" then
            isDoubleCardAlive = false
        end
    end

    local purchaseCardData = nil
    -- TODO: 两套数据重叠了，策划说暂时不开活动，以后开了再处理
    -- 第一套：双倍送卡活动、升星活动
    local cardStarData = G_GetActivityDataByRef(ACTIVITY_REF.CardStar)
    if isCardStarAlive and cardStarData and cardStarData.isExist and cardStarData:isExist() then
        purchaseCardData = globalData.purchaseActCards
    end
    -- 第二套：神像buff
    if key then
        -- BUFFTYPE_COINSHOP_CARD_PACKAGE_BONUS = "SpecialCardDouble", -- 金币商城购买时，卡包数量翻倍，
        -- BUFFTYPE_COINSHOP_CARD_STAR_BONUS = "SpecialCardStarUp", -- 金币商城购买时，卡包内卡牌的星级提升
        if key == "CoinStoreItem" or key == "CoinStoreTip" or key == "LuckySpinMainLayer" then
            local starupBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_COINSHOP_CARD_STAR_BONUS)
            if starupBuff and starupBuff > 0 then
                if globalData.purchaseBuffCards and #globalData.purchaseBuffCards > 0 then
                    purchaseCardData = globalData.purchaseBuffCards
                end
            end
        end

    -- -- BUFFTYPE_GEMSHOP_GEM_BONUS = "SpecialGems", -- 钻石商城购买时，钻石加成
    -- if key == "GemStoreItem" then
    --     local gemMulBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_GEMSHOP_GEM_BONUS)
    --     if gemMulBuff and gemMulBuff > 0 then
    --         if globalData.purchaseBuffCards and #globalData.purchaseBuffCards > 0 then
    --             purchaseCardData = globalData.purchaseBuffCards
    --         end
    --     end
    -- end
    end

    -- local isDoubleCards = nil
    -- local doubleCardData = G_GetActivityDataByRef(ACTIVITY_REF.DoubleCard)
    -- if isDoubleCardAlive and doubleCardData and doubleCardData.isExist and doubleCardData:isExist() then
    --     isDoubleCards = true
    -- end
    if CardSysManager:canShopGiftCard() then
        local purchaseData = self:getCardPurchase(IapKeyId, price, purchaseCardData)
        if purchaseData then
            local itemData = self:createLocalCardData(purchaseData)
            return itemData
        end
    end
end
--根据支付金额获得配置
function ItemManager:getCardPurchase(IapKeyId, price, purchaseCard)
    local data = purchaseCard or globalData.purchaseCards
    if data and #data > 0 then
        for i = 1, #data do
            local purchaseData = data[i]
            --通过计费点名字匹配
            if IapKeyId and purchaseData.p_productId == IapKeyId then
                return purchaseData
            end
            --通过价格匹配
            if price and purchaseData.p_price == price then
                return purchaseData
            end
        end
    end
end
--老方法兼容报错处理
function GD.util_getCardItemData(IapKeyId, price, isActCard)
    return {}
end
function GD.util_createTipBPNode(type, var, char, data)
    return cc.Node:create()
end
function GD.util_createDescBPNode(data, source)
    return cc.Node:create()
end
function GD.util_createInfoPBNode(itemList, isOneLine, source, otherCsb)
    return cc.Node:create()
end
function GD.util_getCardPurchase(IapKeyId, price, isActCard)
    return cc.Node:create()
end

--[[
    @desc: 根据额外的角标需求修改创建出来的道具
]]
function ItemManager:setItemNodeByExtraData(_itemData, _itemNode, _multip)
    local cellLabNode = _itemNode:getValue()
    _multip = _multip or 1
    -- 先找到创建好的 itemnode 节点下的文本字体
    if cellLabNode then
        local newStr = nil
        -- 重新根据需求组装文本
        if string.find(_itemData.p_icon, "club_pass_") then -- 高倍场体验卡
            -- 需要把文字设置成居中模式
            newStr = "X" .. (1 * _multip) -- 高倍场体验卡需要根据倍数来显示个数
        elseif string.find(_itemData.p_icon, "Coupon") then -- 折扣券
            newStr = _itemData.p_num .. "%"
        elseif string.find(_itemData.p_icon, "GiftPickBonusIcon") then -- starpick 小游戏
            -- 需要把文字设置成居中模式
            newStr = "X" .. (1 * _multip) -- 小游戏需要根据倍数来显示个数
        elseif string.find(_itemData.p_icon, "MiniGame_") then
            local num = _itemData.p_num
            if _itemData.p_showTempData and table.nums(_itemData.p_showTempData) then
                num = _itemData.p_showTempData.p_num
            end
            newStr = "+" .. (num * _multip)
        end
        if newStr then
            cellLabNode:setString(newStr)
        end
    end
end

-----------------------------------------------------功能 END
--测试道具
function ItemManager:showTestItem()
    --测试道具列表
    local itemDataList = {
        {p_icon = "Card_Nado_4", p_mark = {ITEM_MARK_TYPE.CENTER_X}, p_num = 3},
        {p_icon = "Coupon1", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_num = 150, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
        {p_icon = "shop_boost_wallet", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
        {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
        --p_mark = {3}:下方居中BUFF角标&金币,p_mark = {4,5,3,2}{星级卡包,总数量,星级,最少出现数量}:卡片数量5;最少3星卡数量为2
        {p_icon = "Card_Star_3", p_mark = {ITEM_MARK_TYPE.CARD, 5, 3, 2}, p_num = 1}
    }
    --普通金币显示
    itemDataList[#itemDataList + 1] = self:createLocalItemData("Coins", 9999999)

    --强制隐藏金币数量
    -- local itemData = self:createLocalItemData("Coins",9999999)
    -- itemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
    -- itemDataList[#itemDataList+1] = itemData

    --强制修改显示长度
    -- local itemData = self:createLocalItemData("Coins",9999999)
    -- itemData:setTempData({p_limit = 3})
    -- itemDataList[#itemDataList+1] = itemData

    itemDataList[#itemDataList + 1] = self:createLocalItemData("LuckyStamp", 1)
    itemDataList[#itemDataList + 1] = self:createLocalItemData("Vip", 1000)
    itemDataList[#itemDataList + 1] = self:createLocalItemData("ExtraCoins", 99)

    local baseNode = cc.Node:create()
    gLobalViewManager:getViewLayer():addChild(baseNode, 99999999)
    --测试遮罩
    local layer = util_newMaskLayer()
    layer:setOpacity(170)
    baseNode:addChild(layer, -1)
    layer:setTouchEnabled(false)

    --最大道具 不传参数默认创建最大
    local itemNode1 = gLobalItemManager:addPropNodeList(itemDataList)
    baseNode:addChild(itemNode1)
    itemNode1:setPosition(display.cx, display.cy + 200)
    --中等道具
    local itemNode2 = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
    baseNode:addChild(itemNode2)
    itemNode2:setPosition(display.cx, display.cy)
    --battlePass道具
    local itemNode3 = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.BATTLE_PASS)
    baseNode:addChild(itemNode3)
    itemNode3:setPosition(display.cx, display.cy - 165)
    --排行道具最小
    local itemNode4 = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.TOP)
    baseNode:addChild(itemNode4)
    itemNode4:setPosition(display.cx, display.cy - 300)

    --创建独立某一个道具
    local itemNode5 = gLobalItemManager:createRewardNode(itemDataList[1])
    baseNode:addChild(itemNode5)
    itemNode5:setPosition(display.cx - 500, display.cy - 250)

    local itemNode6 = gLobalItemManager:createRewardNode(itemDataList[2], ITEM_SIZE_TYPE.TOP)
    baseNode:addChild(itemNode6)
    itemNode6:setPosition(display.cx + 500, display.cy - 250)
end

function ItemManager:showTestRewardLayer()
    local function randomItem()
        local itemDataList = {
            {p_icon = "Card_Nado_4", p_mark = {ITEM_MARK_TYPE.CENTER_X}, p_num = 3},
            {p_icon = "Coupon1", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_num = 150, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_wallet", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            --p_mark = {3}:下方居中BUFF角标&金币,p_mark = {4,5,3,2}{星级卡包,总数量,星级,最少出现数量}:卡片数量5;最少3星卡数量为2
            {p_icon = "Card_Star_3", p_mark = {ITEM_MARK_TYPE.CARD, 5, 3, 2}, p_num = 1},
            {p_icon = "Card_Star_3", p_mark = {ITEM_MARK_TYPE.CARD, 5, 3, 2}, p_num = 1},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}},
            {p_icon = "shop_boost_xp", p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}, p_type = "Buff", p_buffInfo = {buffExpire = 86400}}
        }
        --普通金币显示
        itemDataList[#itemDataList + 1] = self:createLocalItemData("Coins", 9999999)
        itemDataList[#itemDataList + 1] = self:createLocalItemData("LuckyStamp", 1)
        itemDataList[#itemDataList + 1] = self:createLocalItemData("Vip", 1000)
        itemDataList[#itemDataList + 1] = self:createLocalItemData("ExtraCoins", 99)
        local index = math.random(1, #itemDataList)
        return itemDataList[index]
    end
    if not self.m_testCount then
        self.m_testCount = 4
    end
    local count = self.m_testCount
    self.m_testCount = self.m_testCount + 1
    local itemDataList = {}
    for i = 1, count do
        itemDataList[#itemDataList + 1] = randomItem()
    end
    --奖励界面
    local rewardLayer = gLobalItemManager:createRewardLayer(itemDataList)
    gLobalViewManager:showUI(rewardLayer)
end

-- 显示道具介绍说明弹板
function ItemManager:showItemDescTipLayer(_itemData, _itemSizeType, _mul)
    local view = gLobalViewManager:getViewByName("ItemDescTipLayer")
    if view then
        return
    end

    view = util_createView("PBCode2.ItemDescTipLayer", _itemData, _itemSizeType, _mul)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI+10)
end

return ItemManager
