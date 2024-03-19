local config = {}

config.shadow = {
    name = 'shadow',
    showName = '阴影',
    frag = "Shader/shader/shadow.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        pixelOffset = {
            type = 'Vec2',
            value = cc.p(0.5,0.5)
        },
        color = {
            type = "Vec4",
            value = cc.vec4(0,0,0,1)
        }
    },
}

config.gray = {
    name = 'gray',
    showName = '灰度',
    frag = "Shader/shader/gray.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        gray = {
            type = 'float',
            value = 0.5
        },
    },
}

config.brightness = {
    name = 'brightness',
    showName = '亮度',
    frag = "Shader/shader/brightness.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        brightness = {
            type = 'float',
            value = 0.5
        },
    },
}


config.edge1 = {
    name = 'edge1',
    showName = '外描边',
    frag = "Shader/shader/edge1.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        width = {
            type = 'float',
            value = 1.0
        },
        borderColor = {
            type = 'Vec4',
            value = cc.vec4(1,0,0,1)
        },
    },
}

config.dissolve = {
    name = 'dissolve',
    showName = '溶解',
    frag = "Shader/shader/dussolve.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        addColor = {
            type = 'Vec4',
            value = cc.vec4(1,1,1,1)
        },
        noise = {
            type = "sample2d",
            value = "shader/noise/01dissolve.jpeg"
        },
        percent = {
            type = 'float',
            value = 1.0
        }
    }
}

config.wave1 = {
    name = 'wave1',
    showName = '波纹',
    frag = "Shader/shader/wave1.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        udist = {
            type = 'float',
            value = 1.0
        },
        startPos = {
            type = 'Vec2',
            value = cc.p(0.5,0.5)
        },
    }
}

config.mosaic = {
    name = 'mosaic',
    showName = "马赛克",
    frag = "Shader/shader/mosaic.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        pixelSize = {
            type = 'Vec2',
            value = cc.p(0.1,0.2)
        },
    }
}

config.contour = {
    name = 'contour',
    showName = "轮廓",
    frag = "Shader/shader/contour.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        pixelSize = {
            type = 'Vec2',
            value = cc.p(0.1,0.1)
        },
        color = {
            type = 'Vec4',
            value = cc.vec4(1,0.3,0.3,1)
        },
    }
}


config.distirt = {
    name = 'distirt',
    showName = "扭曲黑洞",
    frag = "Shader/shader/distirt.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        time = {
            type = 'float',
            value = 0.0,
            mul = 20.0,
        },
    }
}

config.wave2 = {
    name = 'wave2',
    showName = "波纹2",
    frag = "Shader/shader/wave2.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        udist = {
            type = 'float',
            value = 1.0,         
            mul = 1.0,
        },
        amp = {
            type = 'float',
            value = 0.1,         
            mul = 1,
        },
        wl = {
            type = 'float',
            value = 30.0,         
            mul = 1.0,
        },
        startPos = {
            type = 'Vec2',
            value = cc.p(0.5,0.5)
        },
    }
}



config.distirt = {
    name = 'MirFrag',
    showName = "镜子碎片",
    frag = "Shader/shader/MirFrag.frag",
    vertex = "Shader/shader/normal.vertex",
    uniform = {
        time = {
            type = 'float',
            value = 0.0,
            mul = 5.0,
        },
    }
}

return config