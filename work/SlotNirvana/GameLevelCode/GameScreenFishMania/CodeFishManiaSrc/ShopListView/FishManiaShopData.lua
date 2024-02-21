local FishManiaShopData = class("FishManiaShopData")

FishManiaShopData.m_shopIndex = 1 -- 当前所在页
FishManiaShopData.m_selectIndex = 0 -- 当前选择商店
FishManiaShopData.m_pickScore = 0 -- 商店积分
FishManiaShopData.m_shopSpend = {} -- 自由商店 所有选项的任务额度
FishManiaShopData.m_shopPageData = {} -- 商店具体信息
FishManiaShopData.m_commodityState = {} -- 装饰品状态 0:未购买 1:购买且摆放 2:购买未摆放
FishManiaShopData.m_commodityCash = {} -- 装饰品的数据包 本地缓存 (必须为有序数组)
FishManiaShopData.COMMODITYSTATE = {
    NORMAL = 0,
    SET = 1,
    NOTSET = 2
}

function FishManiaShopData:ctor()
    self.m_shopIndex = 1
    self.m_selectIndex = 0
    self.m_pickScore = 0
    self.m_shopPageData = {}
    self.m_commodityState = {}
    self.m_commodityCash = {}

    self.m_guideState = false --引导状态
end

--[[
    装饰品本地数据缓存相关
]]
function FishManiaShopData:initCommodityCash()
    local keyStr = string.format("%s_FishMania_CommodityCash", globalData.userRunData.userUdid)
    local jsonStr = gLobalDataManager:getStringByField(keyStr, "")

    if "" == jsonStr then
    else
        self.m_commodityCash = cjson.decode(jsonStr)
    end
end
function FishManiaShopData:saveCommodityCash()
    local keyStr = string.format("%s_FishMania_CommodityCash", globalData.userRunData.userUdid)
    local jsonStr = cjson.encode(self.m_commodityCash)
    gLobalDataManager:setStringByField(keyStr, jsonStr, true)
end
-- 根据传入参数 或 服务器数据刷新
function FishManiaShopData:upDateCommodityCash(_cashData)
    --[[
        _cashData = {
            shopIndex = 1,
            commodityId = 1,
            --
            state = 0,
            pos = {x=0, y=0},
            scale = 1,
        }
    ]]
    local initCashDataTable = function(_shopIndex, _commodityId)
        local cashData = self:getCommodityCash(_shopIndex, _commodityId)
        if not cashData then
            --没有拿到就初始化一个塞进去
            cashData = {
                shopIndex = _shopIndex,
                commodityId = _commodityId
            }
            table.insert(self.m_commodityCash, cashData)
        end

        return cashData
    end

    if _cashData then
        --只修改传入参数不直接覆盖
        local cashData = initCashDataTable(_cashData.shopIndex, _cashData.commodityId)
        for k, v in pairs(_cashData) do
            cashData[k] = v
        end
    elseif self.m_shopPageData then
        for _shopIndex, _shopData in pairs(self.m_shopPageData) do
            for _index, _commodity in ipairs(_shopData) do
                local id = tonumber(_commodity.type) + 1
                local cashData = initCashDataTable(_shopIndex, id)
                --已购买
                if _commodity.buy then
                    --未购买
                    if not cashData.state or self.COMMODITYSTATE.NORMAL == cashData.state then
                        cashData.state = self.COMMODITYSTATE.SET
                    end
                else
                    cashData.state = self.COMMODITYSTATE.NORMAL
                end
            end
        end
    end

    self:saveCommodityCash()
end
function FishManiaShopData:getCommodityCash(_shopIndex, _commodityId)
    for i, _cashData in ipairs(self.m_commodityCash) do
        if _shopIndex == _cashData.shopIndex and _commodityId == _cashData.commodityId then
            return _cashData
        end
    end

    return nil
end

function FishManiaShopData:getCommodityState(_shopIndex, _commodityId)
    local state = self.COMMODITYSTATE.NORMAL

    local cashData = self:getCommodityCash(_shopIndex, _commodityId)
    if cashData then
        state = cashData.state or self.COMMODITYSTATE.NORMAL
    end

    return state
end

function FishManiaShopData:parseShopData(_data)
    --[[
        _data = {
            shopIndex = 1,
            selectSuperFree = 0,
            shop4Score = {
                [1] = 0,
            },
            shop = {
                "1" ={
                    [1] ={
                        buy = false,
                        price = "500",
                        type = "0",
                    }
                }
            }
        }
    ]]
    if _data.shopIndex then
        self.m_shopIndex = _data.shopIndex
    end
    if _data.selectSuperFree then
        self.m_selectIndex = _data.selectSuperFree
    end
    if _data.shop4Score then
        self.m_shopSpend = _data.shop4Score
    end

    if _data.shop then
        self.m_shopPageData = {}
        for _shopIndexStr, _shopData in pairs(_data.shop) do
            local shopIndex = tonumber(_shopIndexStr)
            if shopIndex then
                self.m_shopPageData[shopIndex] = _shopData
            end
        end

        self:initToyIdCfg()
        self:upDateCommodityCash()
    end
end

function FishManiaShopData:buyUpDateShopData(_data)
    --[[
    _data = {
        pickScore = selfData.pickScore,
        shopIndex = self.m_buyData.shopIndex,
        commodityType = self.m_buyData.commodityType,
    }
]]
    for _shopIndex, _shopData in pairs(self.m_shopPageData) do
        if _shopIndex == _data.shopIndex then
            for _index, _commodity in ipairs(_shopData) do
                if _commodity.type == _data.commodityType then
                    _commodity.buy = true
                    break
                end
            end
            break
        end
    end

    self:upDateCommodityCash()

    --带事件的放在最后
    self:setPickScore(_data.pickScore, true)
end
--superFree结束时清理 自由商店 所有装饰品的购买状态 和 所选商店
function FishManiaShopData:superFreeOverClearData()
    self.m_selectIndex = 0

    local shopData = self.m_shopPageData[4]

    if shopData then
        for _index, _commodity in pairs(shopData) do
            _commodity.buy = false
        end
    end

    self:upDateCommodityCash()
end
--当前所属商店  1~4
function FishManiaShopData:getShowIndex()
    return self.m_shopIndex
end
--当前选择的商店类型  1~3
function FishManiaShopData:getSelectIndex()
    return self.m_selectIndex
end

function FishManiaShopData:getshopPageData()
    return self.m_shopPageData
end

function FishManiaShopData:getShopDataByIndex(_shopIndex)
    return self.m_shopPageData and self.m_shopPageData[_shopIndex]
end

function FishManiaShopData:getCommodityData(_shopIndex, commodityIndex)
    local shopData = self.m_shopPageData[_shopIndex]
    if shopData then
        local commodity = shopData[commodityIndex]
        return commodity
    end

    return nil
end

function FishManiaShopData:setPickScore(_pickScore, _isNotic)
    self.m_pickScore = _pickScore
    if _isNotic then
        local p_fishManiaCfg = globalMachineController.p_fishManiaPlayConfig
        gLobalNoticManager:postNotification(p_fishManiaCfg.EventName.PICKSCORE_CHANGE, {self.m_pickScore})
    end
end
function FishManiaShopData:getPickScore()
    return self.m_pickScore
end

function FishManiaShopData:getCommodityPrice(_shopIndex, _commodityId)
    local shopData = self:getShopDataByIndex(_shopIndex)
    if shopData then
        local commodityType = string.format("%d", _commodityId - 1)
        for _index, _commodity in ipairs(shopData) do
            if _commodity.type == commodityType then
                return tonumber(_commodity.price)
            end
        end
    end

    return 999999
end

function FishManiaShopData:getShopSpend(_shopIndex, _selectIndex)
    local curSpend = 0
    local allSpend = 0
    --
    if 4 == _shopIndex then
        local selectIndex = _selectIndex or self.m_selectIndex
        allSpend = self.m_shopSpend[selectIndex] or 0
    end

    local shopData = self:getShopDataByIndex(_shopIndex)
    if shopData then
        for _index, _commodity in ipairs(shopData) do
            local priceValue = tonumber(_commodity.price)

            if 4 ~= _shopIndex then
                allSpend = allSpend + priceValue
            end

            if _commodity.buy then
                curSpend = curSpend + priceValue
            end
        end
    end

    return curSpend, allSpend
end

function FishManiaShopData:getShopProgress(_shopIndex)
    local curSpend, allSpend = self:getShopSpend(_shopIndex)
    local progress = 0

    if 0 ~= allSpend then
        progress = util_keepFloatNum(curSpend / allSpend, 2)
        progress = math.min(1, progress)
    end

    return progress
end
-- 通过 商品在对应商店的索引 获取 商品类型
function FishManiaShopData:getCommodityType(_shopIndex, _index)
    local commodityType = nil

    local shopData = self:getShopDataByIndex(_shopIndex)
    if shopData then
        for index, commodity in ipairs(shopData) do
            if index == _index then
                commodityType = commodity.type
                break
            end
        end
    end

    return commodityType
end
-- 通过 商品类型 获取 商品在对应商店的索引
function FishManiaShopData:getCommodityIndex(_shopIndex, _commodityType)
    local commodityIndex = nil

    local shopData = self:getShopDataByIndex(_shopIndex)
    if shopData then
        for index, commodity in ipairs(shopData) do
            if _commodityType == commodity.type then
                commodityIndex = index
                break
            end
        end
    end

    return commodityIndex
end

function FishManiaShopData:getShopIsCanBuy()
    local bCanBuy = false

    local shopIndex = self:getShowIndex()
    local shopData = self:getShopDataByIndex(shopIndex)
    if shopData then
        local pickScore = self:getPickScore()
        for index, commodity in ipairs(shopData) do
            if not commodity.buy and tonumber(commodity.price) <= pickScore then
                bCanBuy = true
                break
            end
        end
    end

    return bCanBuy
end

function FishManiaShopData:setGuideState(_isGuide)
    self.m_guideState = _isGuide
end
function FishManiaShopData:getGuideState()
    return true == self.m_guideState
end
--[[
    配置文件读取
]]
function FishManiaShopData:getFishToyCfg(_commodityId)
    local allFishToyCfg = globalMachineController.p_fishManiaPlayConfig.FishToyCfg
    return allFishToyCfg[_commodityId]
end
--物件在商店的静态图
function FishManiaShopData:getShopIconPath(_commodityId)
    local fishToyCfg = self:getFishToyCfg(_commodityId)
    local path = string.format("common/FishMania_shop_ui_gang%d.png", fishToyCfg.shopIcon)

    return path
end
--物件使用工程csb的路径
function FishManiaShopData:getFishToyCsdPath(_commodityId)
    local fishToyCfg = self:getFishToyCfg(_commodityId)
    local path = string.format("FishToy/FishMania_wuToy_%d.csb", fishToyCfg.shopIcon)

    return path
end
--物件在商店的名称
function FishManiaShopData:getCommodityName(_commodityId)
    local fishToyCfg = self:getFishToyCfg(_commodityId)
    local name = fishToyCfg.name

    return name
end
--物件在商店的缩放
function FishManiaShopData:getCommodityShopScale(_commodityId)
    local fishToyCfg = self:getFishToyCfg(_commodityId)
    local scale = fishToyCfg.shopScale

    return scale
end
--物件在弹板的缩放
function FishManiaShopData:getCommodityBonusOverScale(_commodityId)
    local fishToyCfg = self:getFishToyCfg(_commodityId)
    local scale = fishToyCfg.bonusScale

    return scale
end
--物件在界面的配置层级
function FishManiaShopData:getCommodityOrder(_commodityId)
    local fishToyCfg = self:getFishToyCfg(_commodityId)
    local order = fishToyCfg.order

    return order
end
--物件的最大数量
function FishManiaShopData:getFishToyMaxCount()
    local allFishToyCfg = globalMachineController.p_fishManiaPlayConfig.FishToyCfg
    local count = #allFishToyCfg

    return count
end
--判读该物件是不是鱼 配置移动参数的物件，默认都是鱼
function FishManiaShopData:isFish(_commodityType)
    local commodityId = tonumber(_commodityType) + 1
    local moveCfg = globalMachineController.p_fishManiaPlayConfig.ToyMove
    local moveParams = moveCfg[commodityId]
    local isFish = nil ~= moveParams

    return isFish
end

function FishManiaShopData:initToyIdCfg()
    local toyIdCfg = globalMachineController.p_fishManiaPlayConfig.ToyId
    for _shopIndex, _shopData in pairs(self.m_shopPageData) do
        toyIdCfg[_shopIndex] = {}
        for _index, _commodity in ipairs(_shopData) do
            local commodityId = tonumber(_commodity.type) + 1
            table.insert(toyIdCfg[_shopIndex], commodityId)
        end
    end
end
--商店最大页数
function FishManiaShopData:getShopPageCount()
    local toyIdCfg = globalMachineController.p_fishManiaPlayConfig.ToyId
    local count = #toyIdCfg

    return count
end
--获取一个物件的商品id
function FishManiaShopData:getCommodityId(_shopIndex, _index)
    local commodityId = nil

    local toyIdCfg = globalMachineController.p_fishManiaPlayConfig.ToyId

    if toyIdCfg[_shopIndex] and toyIdCfg[_shopIndex][_index] then
        commodityId = toyIdCfg[_shopIndex][_index]
    end

    if nil == commodityId then
        local msg = string.format("[FishManiaShopData:getCommodityId] commodityId is nil _shopIndex=(%d) _index=(%d)", _shopIndex, _index)
        release_print(msg)
        error(msg)
    end

    return commodityId
end

function FishManiaShopData:getCommoditySpineName(_commodityId)
    local spineCfg = globalMachineController.p_fishManiaPlayConfig.ToySpineName
    local spinePngCfg = globalMachineController.p_fishManiaPlayConfig.ToySpinePngName

    local name = spineCfg[_commodityId]
    local pngName = spinePngCfg[_commodityId] or ""

    return name, pngName
end

return FishManiaShopData
