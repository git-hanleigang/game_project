--[[
    spine管理器 用于换装spine动画管理

    时间线统一规律
    Y_颜色1	    棕色包，白色花纹
    Y_颜色2	    紫色包，白色花纹
    Y_颜色3	    蓝色包，白色花纹
    Y_颜色4	    彩色包，白色花纹
    Y_颜色5	    棕色包，棕色花纹
    Y_颜色6	    紫色包，棕色花纹
    Y_颜色7	    蓝色包，棕色花纹
    Y_颜色8	    彩色包，棕色花纹
    Y_颜色9	    棕色包，两种花纹
    Y_颜色10	紫色包，两种花纹
    Y_颜色11	蓝色包，两种花纹
    Y_颜色12	彩色包，两种花纹

    “颜色”分别为
    hong（红色衣服）
    lan（蓝色衣服）
    qing（青色衣服）
    huang（黄色衣服）
    cai（彩色衣服）
]]

local GirlsMagicSpineManager = class("GirlsMagicSpineManager")

local COLOR_RED         =       1       --红色
local COLOR_BULE        =       2       --蓝色
local COLOR_CYAN        =       3       --青色
local COLOR_YELLOW      =       4       --黄色
local COLOR_CAI         =       5       --彩色
local COLOR_SHADOW      =       6       --阴影

local COLOR_TYPE = {
    [COLOR_RED] = "hong",
    [COLOR_BULE] = "lan",
    [COLOR_CYAN] = "qing",
    [COLOR_YELLOW] = "huang",
    [COLOR_CAI] = "cai",
    [COLOR_SHADOW] = "yinying"
}

local BAG_TYPE_BROWN                =       1       --棕色包
local BAG_TYPE_PURPLE               =       2       --紫色包
local BAG_TYPE_BULE                 =       3       --蓝色包
local BAG_TYPE_THREE_COLOR          =       4       --三色包
local BAG_TYPE = {
    [BAG_TYPE_BROWN] = "zong",
    [BAG_TYPE_PURPLE] = "fen",
    [BAG_TYPE_BULE] = "lan",
    [BAG_TYPE_THREE_COLOR] = "cai"
}

local PATTERN_TYPE_WHITE            =       1       --白色花纹
local PATTERN_TYPE_BROWN            =       2       --棕色花纹
local PATTERN_TYPE_TWO_COLOR        =       3       --两色花纹
local PATTERN_TYPE = {
    [PATTERN_TYPE_WHITE] = "bai",
    [PATTERN_TYPE_BROWN] = "zong",
    [PATTERN_TYPE_TWO_COLOR] = "heti"
}

GirlsMagicSpineManager.m_spine_pool = {}
GirlsMagicSpineManager.m_spine_all = {}

function GirlsMagicSpineManager:ctor( )
    self.m_spine_pool = {}
    --存储所有的旋转动画
    self.m_spine_all = {}
end

--[[
    获取动画名
]]
function GirlsMagicSpineManager:getSpineName(colorType,bagType,patternType)
    if colorType == COLOR_SHADOW then
        return "Y_yinying"
    end
    local name = "Y_"
    local color = COLOR_TYPE[colorType]
    local num = (patternType - 1) * 4 + bagType
    name = name..color..num
    return name
end

--[[
    创建大动画  结算用
    需配合变更动作接口使用
]]
function GirlsMagicSpineManager:createBigClothesSpine()
    local spine = util_spineCreate("GirlsMagic_BonusSpin_juese2",true,true)
    return spine
end

--[[
    创建大动画光效
]]
function GirlsMagicSpineManager:createBigClothesLightSpine( )
    local spine = util_spineCreate("GirlsMagic_BonusSpin_pick4",true,true)
    return spine
end

--[[
    创建衣服动画
    旋转展示用
]]
function GirlsMagicSpineManager:createClothesSpine()
    local spine = util_spineCreate("GirlsMagic_BonusSpin_spin",true,true)
    return spine
end

--[[
    变更动作
]]
function GirlsMagicSpineManager:changeClothes(spine,colorType,bagType,patternType,isLoop)
    local name = self:getSpineName(colorType,bagType,patternType)
    if not isLoop then
        isLoop = false
    end
    util_spinePlay(spine,name,isLoop)
end

--[[
    随机衣服
]]
function GirlsMagicSpineManager:randAllClothes(isColorFull,isBagFull,isPatternFull)
    local colorAry,bagAry,patternAry
    if isColorFull then --颜色集满只会出现彩色
        colorAry = {COLOR_CAI}
    else
        colorAry = {COLOR_RED,COLOR_BULE,COLOR_CYAN,COLOR_YELLOW}
    end
    if isBagFull then --包集满只会出现三色
        bagAry = {BAG_TYPE_THREE_COLOR}
    else
        bagAry = {BAG_TYPE_BROWN,BAG_TYPE_PURPLE,BAG_TYPE_BULE}
    end
    if isPatternFull then --花纹集满
        patternAry = {PATTERN_TYPE_TWO_COLOR}
    else
        patternAry = {PATTERN_TYPE_WHITE,PATTERN_TYPE_BROWN}
    end

    --计算所有组合
    local allTypes = {}
    for iColor = 1,#colorAry do
        for iBag=1,#bagAry do
            for iPattern=1,#patternAry do
                --存储衣服属性
                local clothesType = {
                    color = colorAry[iColor],
                    bag = bagAry[iBag],
                    pattern = patternAry[iPattern]
                }
                allTypes[#allTypes + 1] = clothesType
            end
        end
    end

    --打乱组合
    randomShuffle(allTypes)
    return allTypes
end

--[[
    创建旋转展示动画
]]
function GirlsMagicSpineManager:createRoundShowAni(clothesType,node_front,node_behind,zOrder,func)
    --创建衣服
    local clothSpine = self:createClothesSpine()
    local aniName = self:getSpineName(clothesType.color,clothesType.bag,clothesType.pattern)
    util_spinePlay(clothSpine,aniName,true)

    --创建阴影
    local clothShadow = self:createClothesSpine()
    util_spinePlay(clothShadow,self:getSpineName(COLOR_SHADOW),true)

    --创建旋转动画
    local roundSpine1 = self:pop()
    if not roundSpine1 then
        roundSpine1 = util_spineCreate("GirlsMagic_BonusSpin_path",true,true)
        node_front:addChild(roundSpine1)
        table.insert(self.m_spine_all,#self.m_spine_all + 1,roundSpine1)
    end
    roundSpine1:setLocalZOrder(zOrder)

    --将衣服挂在插槽上
    roundSpine1:setVisible(true)
    util_spinePushBindNode(roundSpine1,"Y1",clothSpine)
    util_spinePlay(roundSpine1,"idleframe2",false)
    util_spineEndCallFunc(roundSpine1,"idleframe2",handler(nil,function(  )
        -- release_print("********************************缓存衣服spine")
        roundSpine1:setVisible(false)
        self:push(roundSpine1)
        -- release_print("***************************接触骨骼绑定 衣服")
        util_spineRemoveSlotBindNode(roundSpine1,"Y1")
        util_spineRemoveSlotBindNode(roundSpine1,"Y2")
    end))

    -- util_spineFrameCallFunc(roundSpine1,"idleframe2","Show",handler(nil,function(  )
    --     if type(func) == "function" then    --检测回调
    --         func()
    --     end
    -- end))
    performWithDelay(roundSpine1,function(  )
        if type(func) == "function" then    --检测回调
            func()
        end
    end,0.43)

    local roundSpine2 = self:pop()
    if not roundSpine2 then
        roundSpine2 = util_spineCreate("GirlsMagic_BonusSpin_path",true,true)
        node_behind:addChild(roundSpine2,zOrder)
        table.insert(self.m_spine_all,#self.m_spine_all + 1,roundSpine2)
    end
    roundSpine2:setLocalZOrder(zOrder)
    
    --将阴影挂在插槽上
    roundSpine2:setVisible(true)
    util_spinePushBindNode(roundSpine2,"Y2",clothShadow)
    util_spinePlay(roundSpine2,"idleframe2",false)
    util_spineEndCallFunc(roundSpine2,"idleframe2",handler(nil,function(  )
        -- release_print("*******************************缓存衣服阴影spine")
        roundSpine2:setVisible(false)
        self:push(roundSpine2)
        -- release_print("***************************接触骨骼绑定 阴影")
        util_spineRemoveSlotBindNode(roundSpine2,"Y1")
        util_spineRemoveSlotBindNode(roundSpine2,"Y2")
    end))

    return roundSpine1,roundSpine2
end

--[[
    过场动画
    aniType 1:拉上帘子 2:拉开帘子 3先拉上帘子,再拉开帘子
]]
function GirlsMagicSpineManager:createChangeSceneAni(aniType,func)
    local spine = util_spineCreate("GirlsMagic_guochang",true,true)
    if aniType == 1 then
        util_spinePlay(spine,"actionframe",false)
        util_spineEndCallFunc(spine,"actionframe",handler(nil,function()
            if type(func) == "function" then
                func()
            end
        end))
    elseif aniType == 2 then
        util_spinePlay(spine,"actionframe2",false)
        util_spineEndCallFunc(spine,"actionframe2",handler(nil,function()
            if type(func) == "function" then
                func()
            end
        end))
    else
        local params = {}
        params[1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = spine,   --执行动画节点  必传参数
            actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
        }
        params[2] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = spine,   --执行动画节点  必传参数
            actionName = "actionframe2", --动作名称  动画必传参数,单延时动作可不传
            callBack = function(  )
                if type(func) == "function" then
                    func()
                end
            end
        }
    end
    return spine
end

--[[
    获取选择的衣服
]]
function GirlsMagicSpineManager:getChooseClothes(chooseIndex,clothesType,isInBonus,isIdle)
    local name = isInBonus and "GirlsMagic_BonusSpin_pick2" or "GirlsMagic_BonusSpin_pick"
    local str = isIdle and "_idle" or ""
    local spine = util_spineCreate(name,true,true)
    if chooseIndex == 1 then
        util_spinePlay(spine,"X_yifu_"..COLOR_TYPE[clothesType]..str,false)
    elseif chooseIndex == 2 then
        util_spinePlay(spine,"X_bao_"..BAG_TYPE[clothesType]..str,false)
    elseif chooseIndex == 3 then
        util_spinePlay(spine,"X_huawen_"..PATTERN_TYPE[clothesType]..str,false)
    else
        util_spinePlay(spine,"X_idleframe",false)
    end

    return spine
end

--[[
    播放衣服动画
]]
function GirlsMagicSpineManager:playClothesAni(spine,chooseIndex,clothesType,isIdle)
    local str = isIdle and "_idle" or ""
    if chooseIndex == 1 then
        util_spinePlay(spine,"X_yifu_"..COLOR_TYPE[clothesType]..str,false)
    elseif chooseIndex == 2 then
        util_spinePlay(spine,"X_bao_"..BAG_TYPE[clothesType]..str,false)
    elseif chooseIndex == 3 then
        util_spinePlay(spine,"X_huawen_"..PATTERN_TYPE[clothesType]..str,false)
    else
        util_spinePlay(spine,"X_idleframe",false)
    end
end

--[[
    结算匹配结果时
]]
function GirlsMagicSpineManager:playBigRoleLight(spine,chooseIndex,clothesType)
    --数据安全判定
    if not clothesType then
        return
    end
    local str = "_glow"
    if chooseIndex == 1 then
        util_spinePlay(spine,"X_yifu_"..COLOR_TYPE[clothesType[chooseIndex]]..str,false)
    elseif chooseIndex == 2 then
        util_spinePlay(spine,"X_bao_"..BAG_TYPE[clothesType[chooseIndex]]..str,false)
    elseif chooseIndex == 3 then
        local aniName = "X_huawen_"..PATTERN_TYPE[clothesType[chooseIndex]]..str.."_"..BAG_TYPE[clothesType[2]]
        util_spinePlay(spine,aniName,false)
    end
end

--[[
    角色说话
]]
function GirlsMagicSpineManager:roleSpeakAni(spine,func)
    util_spinePlay(spine,"idleframe1",false)
    util_spineEndCallFunc(spine,"idleframe1",function()        --结束回调
        if type(func) == "function" then
            func()
        end
        
        local randAniName = math.random(1,2) == 1 and "idleframe2" or "idleframe3"
        util_spinePlay(spine,randAniName,false)
        util_spineEndCallFunc(spine,randAniName,function()        --结束回调
            
            if type(func) == "function" then
                func()
            end
            util_spinePlay(spine,"idleframe4",false)
        end)
    end)
    return spine
end

function GirlsMagicSpineManager:pop()
    if not self.m_spine_pool[1] then
        return nil
    end

    local spine = self.m_spine_pool[1]
    table.remove(self.m_spine_pool,1,1)
    return spine
end

function GirlsMagicSpineManager:push(spine)
    table.insert(self.m_spine_pool,#self.m_spine_pool + 1,spine)
end

function GirlsMagicSpineManager:pauseAllSpine( )
    for key,spine in pairs(self.m_spine_all) do
        spine:pause()
    end
end

function GirlsMagicSpineManager:resumeAllSpine( )
    for key,spine in pairs(self.m_spine_all) do
        spine:resume()
    end
end

function GirlsMagicSpineManager:release( )

    self.m_spine_pool = {}
    self.m_spine_all = {}
end

return GirlsMagicSpineManager