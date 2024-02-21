--关卡通用工具库

-------------------------------------------RESPIN START
--respinNode状态
GD.RESPIN_NODE_STATUS = {
    IDLE = 1, --待机中
    RUNNING = 2, --转动中
    LOCK = 3 --结束 锁定状态
}
--respin小块层级
GD.SHOW_ZORDER = {
    SHADE_ORDER = 1000,         --在黑色遮罩下面的小块
    SHADE_LAYER_ORDER = 2000,   --遮罩层
    LIGHT_ORDER = 3000          --遮罩层上面的小块
}
--repsin裁切类型
GD.RESPIN_CLIPTYPE = {
    SINGLE = 1,     --单个小格子
    COMBINE = 2     --合并行
}
--respin裁切模式
GD.RESPIN_CLIPMODE = {
    RECT = 1,       --矩形裁切
    MOULD = 2       --模板裁切
}
--respin遮罩层
GD.RESPIN_COLOR_TYPE = {
    DRAWNODE = 1,       --画矩形
    LAYERCOLOR = 2,     --画带颜色的layer
    SPRITE = 3          --使用图片
}
--创建裁切区域组 baseNode 父节点 config 裁切区域配置文件
function GD.util_createClipNodes(config)
    if not config or not config.clipSize then
        return
    end
    --必填配置
    local clipSize = config["clipSize"]         --单个裁切区域大小
    local iColNum = config["iColNum"]           --裁切列数 
    local iRowNum = config["iRowNum"]           --裁切行数
    --选填配置
    local clipOffsetSize = config["clipOffsetSize"]                 --裁切修正大小
    local clipType = config["clipType"] or RESPIN_CLIPTYPE.SINGLE   --裁切类型 1.单个、2.合并行 默认1
    local clipMode = config["clipMode"] or RESPIN_CLIPMODE.RECT     --裁切方式 1.矩形、2.模板 默认1
    local clipPos = config["clipPos"] or cc.p(-clipSize.width*0.5,-clipSize.height*0.5) --初始坐标默认宽高一半
    local clipOffsetPos = config["clipOffsetPos"] or cc.p(0,0)      --初始坐标 默认cc.p(0,0)
    clipPos = cc.pAdd(clipPos,clipOffsetPos)
    --返回值 附带参数
    local clipNodesData = {}
    local baseNode = cc.Node:create()    --所有裁切层的父节点
    clipNodesData.clipType = clipType    --保存裁切方式
    clipNodesData.baseNode = baseNode    --保存父节点
    clipNodesData.rowClips = {}          --合并行裁切区域

    local oneClipSize = nil --创建裁切区域大小
    if clipOffsetSize then
        --修正真实裁切大小
        oneClipSize = cc.size(clipSize.width+clipOffsetSize.width,clipSize.height+clipOffsetSize.height)
    else
        oneClipSize = clipSize
    end
    --裁切方式
    if clipType == RESPIN_CLIPTYPE.SINGLE then
        --单个小格子裁切
        for col=1,iColNum do
            clipNodesData[col] = {}
            for row = 1,iRowNum do
                local clipNode = util_createOneClipNode(clipMode,oneClipSize,clipPos)
                clipNodesData[col][row] = clipNode
                baseNode:addChild(clipNode)
                --设置裁切块属性
                local originalPos = cc.p((col-1)*clipSize.width,(row-1)*clipSize.height)
                util_setClipNodeInfo(clipNode,clipType,clipMode,oneClipSize,originalPos)
            end
        end
    elseif clipType == RESPIN_CLIPTYPE.COMBINE then
        --行裁切
        for row=1,iRowNum do
            local size = cc.size(clipSize.width*iColNum,oneClipSize.height)
            local baseClip = util_createOneClipNode(clipMode,size,clipPos)
            baseNode:addChild(baseClip)
            clipNodesData.rowClips[row] = baseClip
            --设置裁切块属性
            local baseOriginalPos = cc.p(0,(row-1)*clipSize.height)
            util_setClipNodeInfo(baseClip,clipType,clipMode,size,baseOriginalPos)
            --模拟行列裁切
            for col = 1,iColNum do
                local clipNode = cc.Node:create() --统一格式
                baseClip:addChild(clipNode)
                if not clipNodesData[col] then
                    clipNodesData[col] = {}
                end
                clipNodesData[col][row] = clipNode
                --设置裁切块属性
                local originalPos = cc.p(clipSize.width*(col-1),0)
                util_setClipNodeInfo(clipNode,clipType,clipMode,oneClipSize,originalPos)
            end
        end
    end
    return clipNodesData
end
--设置裁切块属性
function GD.util_setClipNodeInfo(clipNode,clipType,clipMode,clipSize,originalPos)
    if not clipNode then
        return
    end
    clipNode.clipType = clipType            --裁切类型 1.单个、2.合并行 默认1
    clipNode.clipMode = clipMode            --裁切方式 1.矩形、2.模板 默认1
    clipNode.originalPos = originalPos      --初始化时坐标
    clipNode.clipSize = clipSize            --裁切区域大小
    clipNode:setPosition(originalPos)
end
--创建单个裁切区域 clipNode.clipMode 裁切模式
function GD.util_createOneClipNode(clipMode,size,pos)
    local size = cc.size(math.floor(size.width+1),math.floor(size.height+1))
    -- local pos = cc.p(math.ceil(pos.x-1),math.ceil(pos.y-1)) --增大裁切下边缘
    if clipMode == RESPIN_CLIPMODE.RECT then
        --矩形裁切
        local rect = cc.rect(pos.x,pos.y,size.width,size.height)
        local clipNode= cc.ClippingRectangleNode:create(rect)
        return clipNode
    elseif clipMode == RESPIN_CLIPMODE.MOULD then
        --模板裁切
        local reelNode = cc.Node:create()
        local stencil = cc.DrawNode:create()
        local drawList = {
            pos,
            cc.pAdd(pos,cc.p(size.width, 0)),
            cc.pAdd(pos,cc.p(size.width, size.height)),
            cc.pAdd(pos,cc.p(0, size.height))
        }
        stencil:drawPolygon(drawList, 4, cc.c4f(1,1,1,1), 0, cc.c4f(1,1,1,1))
        local clipNode = cc.ClippingNode:create(stencil)
        return clipNode
    end
end
--创建respin小块遮罩
function GD.util_createColorMask(maskType,pos,size,opacity,spPath)
    local size = cc.size(math.floor(size.width+2),math.floor(size.height+2))
    if maskType == RESPIN_COLOR_TYPE.DRAWNODE then
          --画矩形遮罩
          local colorNode= cc.DrawNode:create()
          local drawList = {
                pos,
                cc.pAdd(pos,cc.p(size.width, 0)),
                cc.pAdd(pos,cc.p(size.width, size.height)),
                cc.pAdd(pos,cc.p(0, size.height))
          }
          local ratio = opacity/255
          colorNode:drawPolygon(drawList, 4, cc.c4f(0,0,0,ratio), 0, cc.c4f(0,0,0,ratio))
          return colorNode
    elseif maskType == RESPIN_COLOR_TYPE.LAYERCOLOR then
          --颜色图层遮罩
          local colorNode = cc.LayerColor:create(cc.c4f(0, 0, 0, opacity))
          colorNode:setPosition(pos)
          colorNode:setContentSize(size)
          return colorNode
    elseif maskType == RESPIN_COLOR_TYPE.SPRITE then
          --图片遮罩
          if not spPath then
                spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png" --需要和关卡小块合到一个图层
          end
          local colorNode = util_createSprite(spPath)
          colorNode:setOpacity(opacity)
          colorNode:setPosition(pos)
          colorNode:setContentSize(size)
          return colorNode
    end
end
-------------------------------------------RESPIN END