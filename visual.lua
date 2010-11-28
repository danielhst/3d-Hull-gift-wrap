require "iuplua"
require "iupluagl"
require "luagl"
require "luaglu"
require "iupluacontrols"
require "iuplua_pplot51"

require "vec3"
require "giftWrap"


function generateCubeRandomPoints(n)
  local points = {}
  for i=1, n do
    local v = newVec3(math.random()*2-1, math.random()*2-1, math.random()*2-1)
    table.insert(points, v)
  end
  return points
end

function generateParaboloidRandomPoints(n)
  local points = {}
  local a = 1
  local b = 1
  for i = 1, n do
    local x = math.random()*2-1
    local z = math.random()*2-1
    local y = (x*x)/(a*a) + (z*z)/(b*b)
    local p = newVec3(x, y, z)

    local v = newVec3((math.random()*2-1)/10., (math.random()*2-1)/10., (math.random()*2-1)/10.)

    p = p + v
    table.insert(points, p)
  end
  return points
end

function getBorderPoints(points, polys)
  local borderpoints = {}
  if points == nil or polys == nil then
    return borderpoints
  end

  for i = 1, #points do
    borderpoints[i] = false
  end

  for i, triangle in ipairs(polys) do
    for j, vertex_index in ipairs(triangle) do
      borderpoints[vertex_index] = true
    end
  end
  return borderpoints
end



local app = {
--CameraControll
  cam = {
    alpha = 0,
    beta = 0,
    r = 10,
    angInc = 5,
    center = {x = 0, y = 0},

    near = 0.1,
    far = 10000.,
    fovy = 60.0,
  },

  render = {
    wireFrameEnabled = false, --W
    flatEnabled = false,     --Q
  },

  mouse = {
    state = 0, -- Release
    button = iup.BUTTON1, -- LEFT_BUTTON
    pos = {x = 0, y = 0}
  },

  options = {
    showBorderPoints = true,
    showAxis = true,
    depthTest = true,
  },

  genMethod = {
    {name = "Cube", func = generateCubeRandomPoints} ,
    {name = "Paraboloid", func = generateParaboloidRandomPoints} ,
  },

  anim = {
    enabled = true,
    pause = false,
    step = 1,
    type = "edge",
    count = 0,

    transitionTime = 60,
    edgeTransitionTime = 30,

    Reset = function (self)
      self.step = 1
      self.type = "edge"
      self.count = 0
    end
  },

  width = 800,
  height = 800,
}

function app:SetWireframeEnabled()
  self.render.wireFrameEnabled = not self.render.wireFrameEnabled
  gl.PolygonMode(gl.FRONT_AND_BACK, self.render.wireFrameEnabled and gl.LINE or gl.FILL)
end

function app:SetBorderOptionsEnabled()
  self.options.showBorderPoints = not self.options.showBorderPoints
end

function app:SetDepthEnabled()
  self.options.depthTest = not self.options.depthTest
end

function app:SetAxisEnabled()
  self.options.showAxis = not self.options.showAxis
end

function app:SetAnimEnabled()
  self.anim.enabled = not self.anim.enabled
  self.anim:Reset()
end

function app:SetAnimVelocity(value)
  local val = 1.4 - tonumber(value)
  self.anim.transitionTime = 60*val
  self.anim.edgeTransitionTime = 30*val
end

function app:SetAnimPause()
  self.anim.pause = not self.anim.pause
end

function app:SetAnimNextStep()
  if self.anim.enabled then
    self.anim.pause = true
    self.anim.step = self.anim.step + 1
    self.anim.type = "edge"
    self.anim.count = 0
  end
end

function app:SetAnimPrevStep()
  if self.anim.enabled then
    self.anim.pause = true
    self.anim.step = math.max(self.anim.step - 1, 1)
    self.anim.type = "edge"
    self.anim.count = 0
  end
end

function app:SetFlatEnabled()
  self.render.flatEnabled = not self.render.flatEnabled
  gl.ShadeModel(self.render.flatEnabled and gl.FLAT or gl.SMOOTH)
end

function CreateGlCanvas(GetPoints_cb, GetPolys_cb, GetBorderPoints_cb)
  local glCanvas = iup.glcanvas{buffer="DOUBLE"}

  local function SetupLights()
    local ambient = { .2, .2, .2, 1.}
    local diffuse = { .8, .8, .8, 1.}
    local specular = { 1., 1., 1., 1.}

    gl.Light(gl.LIGHT0, gl.AMBIENT,  ambient)
    gl.Light(gl.LIGHT0, gl.DIFFUSE,  diffuse)
    gl.Light(gl.LIGHT0, gl.SPECULAR, specular)
  end

  local function ActiveCamLight(op, x, y, z)
    if op then
      local pos = { x, y, z, 1.}
      gl.PushAttrib(gl.LIGHTING_BIT, gl.ENABLE_BIT)
      gl.Enable(gl.LIGHTING)

      gl.Enable(gl.LIGHT0)

      gl.Light(gl.LIGHT0, gl.POSITION, pos)
    else
      gl.PopAttrib()
    end
  end

  local function ActiveMaterial(op)
    local ambient = { .2, .2, .2, 1.}
    local diffuse = { .8, 0, 0, 1.}
    local specular = { 1., 1., 1., 1.}
    local shi = 10
    if op then
      gl.PushAttrib(gl.LIGHTING_BIT)
      gl.Material(gl.FRONT_AND_BACK, gl.AMBIENT,  ambient);
      gl.Material(gl.FRONT_AND_BACK, gl.DIFFUSE,  diffuse);
      gl.Material(gl.FRONT_AND_BACK, gl.SPECULAR, specular);
      gl.Material(gl.FRONT_AND_BACK, gl.SHININESS, shi);
    else
      gl.PopAttrib()
    end
  end

  local function SetupCamera()
    local x = app.cam.r*math.sin(math.rad(app.cam.beta))*math.cos(math.rad(app.cam.alpha))
    local y = app.cam.r*math.sin(math.rad(app.cam.alpha))
    local z = app.cam.r*math.cos(math.rad(app.cam.beta))*math.cos(math.rad(app.cam.alpha))

    local nextAlpha =  math.min(app.cam.alpha + app.cam.angInc, 360.)

    local ux = math.sin(math.rad(app.cam.beta))*math.cos(math.rad(nextAlpha)) - x
    local uy = math.sin(math.rad(nextAlpha)) - y
    local uz = math.cos(math.rad(app.cam.beta))*math.cos(math.rad(nextAlpha)) - z


    local pos = newVec3(x,y,z)
    local at = newVec3(0,0,0)
    local up = newVec3(ux,uy,uz)
    up:normalize()

    local dir = at - pos
    dir:normalize()

    local right = dir:cross(up)
    right:normalize()

    up = right:cross(dir)
    up:normalize()

    at = at + right*app.cam.center.x + up*app.cam.center.y
    pos = pos + right*app.cam.center.x + up*app.cam.center.y

    gl.LoadIdentity()
    glu.LookAt(pos.x, pos.y, pos.z, at.x, at.y, at.z, up.x, up.y, up.z)
    return pos.x, pos.y, pos.z, at.x, at.y, at.z, up.x, up.y, up.z
  end

  local function DrawAxis()
    gl.PushAttrib(gl.LINE_BIT, gl.ENABLE_BIT)
    gl.Disable(gl.LIGHTING)
    gl.LineWidth(2)
    gl.Begin(gl.LINES)
      gl.Color(0, 0, 1); gl.Vertex(0, 0, 0); gl.Color(0, 0, 1); gl.Vertex(0, 0, 1000)
      gl.Color(0, 1, 0); gl.Vertex(0, 0, 0); gl.Color(0, 1, 0); gl.Vertex(0, 1000, 0)
      gl.Color(1, 0, 0); gl.Vertex(0, 0, 0); gl.Color(1, 0, 0); gl.Vertex(1000, 0, 0)
    gl.End()
    gl.PopAttrib()
  end

  local function DrawPoints(points, borderpoints)
    gl.PushAttrib(gl.ENABLE_BIT, gl.POINT_BIT)
    if app.options.depthTest == false then
      gl.Disable(gl.DEPTH_TEST)
    end
    gl.Disable(gl.LIGHTING)
    gl.Enable(gl.POINT_SMOOTH)
    gl.PointSize(9)
    gl.Begin(gl.POINTS)
      for i, point in ipairs(points) do
        if borderpoints[i] then
          gl.Color(0,0,1)
        else
          gl.Color(1,0,0)
        end
        gl.Vertex(point.x, point.y, point.z)
      end
    gl.End()

    gl.PopAttrib()
  end

  local function DrawHull(points, polys, x, y, z)
    ActiveMaterial(true)
    gl.Begin(gl.TRIANGLES)
    gl.Color(0,1,0)
    for i, triangle in ipairs(polys) do
      local v1 = points[triangle[2]] - points[triangle[1]]
      local v2 = points[triangle[3]] - points[triangle[1]]
      local normal = v1:cross(v2)
      normal:normalize()

      gl.Normal(normal.x, normal.y, normal.z)
      for j, vertex_index in ipairs(triangle) do
        gl.Vertex(points[vertex_index].x, points[vertex_index].y, points[vertex_index].z)
      end
    end
    gl.End()
    ActiveMaterial(false)
  end

  local function DrawHullAnim(points, polys, x, y, z)
    ActiveMaterial(true)
    gl.Begin(gl.TRIANGLES)
    gl.Color(0,1,0)
    for i, triangle in ipairs(polys) do
      if i >= app.anim.step then
        break
      end
      local v1 = points[triangle[2]] - points[triangle[1]]
      local v2 = points[triangle[3]] - points[triangle[1]]
      local normal = v1:cross(v2)
      normal:normalize()

      gl.Normal(normal.x, normal.y, normal.z)
      for j, vertex_index in ipairs(triangle) do
        gl.Vertex(points[vertex_index].x, points[vertex_index].y, points[vertex_index].z)
      end
    end
    gl.End()

    ActiveMaterial(false)

    gl.PushAttrib(gl.LINE_BIT, gl.ENABLE_BIT)
    gl.Disable(gl.LIGHTING)
    gl.LineWidth(4)
    gl.Begin(gl.LINES)
    gl.Color(0,1,0)
      for j = 1, 2 do
        gl.Vertex(points[polys[app.anim.step][j]].x, points[polys[app.anim.step][j]].y, points[polys[app.anim.step][j]].z)
      end
    gl.End()
    gl.PopAttrib()

    if app.anim.pause == false then
      if app.anim.count > app.anim.transitionTime then
        if app.anim.type == "edge" then
          app.anim.type = "triangle"
        elseif app.anim.count > app.anim.transitionTime + app.anim.edgeTransitionTime then
          app.anim.step = app.anim.step + 1
          app.anim.type = "edge"
          app.anim.count = 0
        else
          app.anim.count = app.anim.count + 1
        end
      else
        app.anim.count = app.anim.count + 1
      end
    end
  end

  function glCanvas:initGl()
    iup.GLMakeCurrent(self)

    gl.ClearColor(.8,.8,.8,1.0)

    gl.ShadeModel(app.render.flatEnabled and gl.FLAT or gl.SMOOTH)

    gl.PolygonMode(gl.FRONT_AND_BACK, app.render.wireFrameEnabled and gl.LINE or gl.FILL)

  -- gl.CullFace(gl.BACK)
  -- gl.CullFace(gl.FRONT)
  -- gl.Enable(gl.CULL_FACE)

    gl.Enable(gl.DEPTH_TEST)
    -- gl.Light(gl.LIGHT0, gl.DIFFUSE, glLightDif)

    self:resize_cb(app.width, app.height)

    SetupLights()
  end

  function glCanvas:action()
    self:display()
  end

  function glCanvas:resize_cb(width, height)
    app.width = width;
    app.height = height;

    gl.Viewport (0, 0, app.width, app.height);
    gl.MatrixMode (gl.PROJECTION);
    gl.LoadIdentity ();
    glu.Perspective(app.cam.fovy, app.width / app.height, app.cam.near, app.cam.far);
    gl.MatrixMode (gl.MODELVIEW);
  end

  function glCanvas:keypress_cb(key, pressed)
    -- print(key)
    if pressed == 1 then

      if key == 27 then --ESC
        os.exit()

      elseif key == 119 or key == 87 then --W
        app:SetWireframeEnabled()

      elseif key == 113 or key == 81 then --Q
        app:SetFlatEnabled()

      elseif key == 328 then --UP ARROW
        app.cam.alpha = (app.cam.alpha - app.cam.angInc)%360
      elseif key == 336 then --Down ARROW
        app.cam.alpha = (app.cam.alpha + app.cam.angInc)%360
      elseif key == 331 then --LEFT ARROW
        app.cam.beta = (app.cam.beta + app.cam.angInc)%360
      elseif key == 333 then --RIGHT ARROW
        app.cam.beta = (app.cam.beta - app.cam.angInc)%360
      elseif key == 45 then -- +
        app.cam.r = app.cam.r + 1
      elseif key == 43 then -- -
        app.cam.r = app.cam.r - 1


      elseif key == 329 then --pgup
      elseif key == 337 then --pqDown

      elseif key == 315 then --F1
      elseif key == 316 then --F2

      elseif key == 49 then --1
        -- points = generateCubeRandomPoints(10)
        -- polys = getHullPolys( points )
      elseif key == 50 then --2
      elseif key == 51 then --3
      elseif key == 55 then --7
      elseif key == 56 then --8
      elseif key == 57 then --9
      elseif key == 48 then --0
      end
    end
  end

  function glCanvas:button_cb(but, pressed, x, y, status)
    app.mouse.state = pressed
    app.mouse.button = but

    app.mouse.pos.x = x
    app.mouse.pos.y = y
  end

  function glCanvas:motion_cb(x, y, status)
    if app.mouse.button == iup.BUTTON1 and  app.mouse.state == 1 then--LEFT_BUTTON PRESSED
      local angleX = (x - app.mouse.pos.x)*.5
      local angleY = (y - app.mouse.pos.y)*.5

      app.cam.alpha = (app.cam.alpha + angleY)%360
      app.cam.beta =  (app.cam.beta - angleX)%360

    elseif app.mouse.button == iup.BUTTON2 and app.mouse.state == 1 then --MIDDLE_BUTTON PRESSED
      app.cam.center.x = app.cam.center.x  - (x - app.mouse.pos.x)/50.0
      app.cam.center.y = app.cam.center.y  + (y - app.mouse.pos.y)/50.0

    elseif app.mouse.button == iup.BUTTON3 and app.mouse.state == 1 then --RIGHT_BUTTON PRESSED
      app.cam.r = app.cam.r + (y - app.mouse.pos.y)/20.0
    end

    app.mouse.pos.x = x
    app.mouse.pos.y = y
  end

  function glCanvas:display()
    iup.GLMakeCurrent(self)

    gl.Clear('COLOR_BUFFER_BIT,DEPTH_BUFFER_BIT')

    local x, y, z = SetupCamera()


    if app.options.showAxis then
      DrawAxis()
    end

    local points = GetPoints_cb()
    local polys = GetPolys_cb()
    local borderpoints = GetBorderPoints_cb()

    ActiveCamLight(true, x, y, z)
    if app.anim.enabled and app.anim.step <= #polys then
      DrawHullAnim(points, polys)
    else
      DrawHull(points, polys)
    end
    ActiveCamLight(false)

    DrawPoints(points, borderpoints)

    iup.GLSwapBuffers(self)
  end


  return glCanvas
end

----------IUP MAIN-----------
----------IUP MAIN-----------
----------IUP MAIN-----------
----------IUP MAIN-----------


local ConvexHullVisual = {
  points = {},
  polys = {},
  borderpoints = {},
  numPoints = 10,
}

function ConvexHullVisual:GeneratePoints()
  self.points = app.genMethod[tonumber(self.generationMethodsList.value)].func(self.numPoints)
  self.polys = getHullPolys(self.points)
  self.borderpoints = getBorderPoints(self.points, self.polys)

  for i, point in ipairs(self.points) do
    local str = string.format("%.2f", point.x)..",  ".. string.format("%.2f", point.y)..",  ".. string.format("%.2f", point.z)
    self.pointsList[i] = str
  end
  self.pointsList[#self.points + 1] = nil
  app.anim:Reset()
end

function ConvexHullVisual:BuildInterface()
  self.pointsList = iup.list{expand = "VERTICAL"}
  self.generationMethodsList = iup.list{dropdown = "YES", value = 1}
  for i, method in ipairs(app.genMethod) do
    self.generationMethodsList[i] = method.name
  end
  self.generationMethodsList[#app.genMethod + 1] = nil

  self:GeneratePoints()

  self.numPointsText = iup.text{value = tostring(self.numPoints)}


  self.animPauseButton = iup.button{title = app.anim.pause and "Play" or "Pause",
    active = app.anim.enabled and "YES" or "NO",
    action = function(lself)
      app:SetAnimPause()
      lself.title = app.anim.pause and "Play" or "Pause"
      self.animPrevButton.active = app.anim.step > 1 and "YES" or "NO"
      self.animNextButton.active = app.anim.step <= #self.polys and "YES" or "NO"
    end
  }

  self.animPrevButton = iup.button{title = "Prev",
    action = function(lself)
      app:SetAnimPrevStep()
      lself.active = app.anim.step > 1 and "YES" or "NO"
      self.animPauseButton.title = app.anim.pause and "Play" or "Pause"      self.animNextButton.active = app.anim.step <= #self.polys and "YES" or "NO"
    end
  }

  self.animNextButton = iup.button{title = "Next",
    action = function(lself)
      app:SetAnimNextStep()
      lself.active = app.anim.step <= #self.polys and "YES" or "NO"
      self.animPauseButton.title = app.anim.pause and "Play" or "Pause"
      self.animPrevButton.active = app.anim.step > 1 and "YES" or "NO"
    end
  }

  self.animToggle = iup.toggle{title = "Animation", value = app.anim.enabled and "ON" or "OFF",
    action = function(lself)
      app:SetAnimEnabled()
      self.animNextButton.active = (app.anim.enabled and app.anim.step <= #self.polys) and "YES" or "NO"
      self.animPrevButton.active = (app.anim.enabled and app.anim.step > 1) and "YES" or "NO"
      self.animPauseButton.active = app.anim.enabled and "YES" or "NO"
    end
  }



  self.opsBox = iup.hbox {
    iup.fill{size = 5},
    iup.vbox{
      iup.fill{size = 5},
      -------------------------
      iup.button{title = "ResetCamera",
        action = function(lself) app.cam.center = {x = 0, y = 0} app.cam.alpha = 0 app.cam.beta = 0    end
      },
      iup.fill{size = 5},

      iup.toggle{title = "WireFrame", value = app.render.wireFrameEnabled and "ON" or "OFF",
        action = function(lself) app:SetWireframeEnabled()     end
      },
      iup.fill{size = 5},

      iup.toggle{title = "DepthTest", value = app.options.depthTest and "ON" or "OFF",
        action = function(lself) app:SetDepthEnabled()     end
      },
      iup.fill{size = 5},

      iup.toggle{title = "BorderPoints", value = app.options.showBorderPoints and "ON" or "OFF",
        action = function(lself) app:SetBorderOptionsEnabled()     end
      },
      iup.fill{size = 5},

      iup.toggle{title = "Axis", value = app.options.showAxis and "ON" or "OFF",
        action = function(lself) app:SetAxisEnabled()     end
      },
      iup.fill{size = 5},

      self.animToggle,
      iup.fill{size = 5},

      iup.label{title = "AnimationControll:"},
      iup.hbox{
        self.animPrevButton,
        self.animPauseButton,
        self.animNextButton,
      },

      iup.label{title = "AnimationSpeed:"},
      iup.val{"horizontal", value = .5,
        button_release_cb = function(lself) app:SetAnimVelocity(lself.value) return iup.DEFAULT end
      },
      ------------------------
      iup.fill{size = 15},
      iup.vbox{
        iup.label{title = "Points:"},
        self.pointsList
      },
      ------------------------
      iup.fill{size = 15},
      iup.label{title = "Generation:"},
      self.generationMethodsList,
      iup.fill{size = 5},
      iup.vbox{
        iup.label{title = "Num Points:"},
        iup.fill{size = 5},
        iup.spinbox { self.numPointsText,
          spin_cb = function (lself, inc)
            self.numPoints = math.max(self.numPoints + tonumber(inc), 3)
            self.numPointsText.value = tostring(self.numPoints)
          end
        },
      },
      iup.fill{size = 5},
      iup.button{title = "Generate Points",
        action = function(lself) self:GeneratePoints() end
      },
      -------------------------
      iup.fill{size = 5},
    },
    iup.fill{size = 5}

  }

  self.glCanvas = CreateGlCanvas(
    function() return self.points end ,
    function() return self.polys end,
    function() return app.options.showBorderPoints == true and self.borderpoints or {} end
    )

  self.iupelem = iup.hbox{
    self.opsBox,
    self.glCanvas,
  }

  self.dialog = iup.dialog{self.iupelem, title = "3DConvexHullVisual", menu = nil, rastersize = tostring(app.width).."x"..tostring(app.height)}
  return self.iupelem
end

function ConvexHullVisual:Show()
  self.timer = iup.timer{TIME = 10, RUN = "YES"}
  function self.timer.action_cb(lself)
    self.glCanvas:display()
  end
  self.dialog:show()
  self.glCanvas:initGl()
  self.glCanvas:display()

  iup.MainLoop()
end

ConvexHullVisual:BuildInterface()
ConvexHullVisual:Show()





