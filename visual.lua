require "iuplua"
require "iupluagl" 
require "luagl" 
require "luaglu" 
require "iupluacontrols" 
require "iuplua_pplot51" 

require "vec3"
require "giftWrap"


function generateRandomPoints(n)
  local points = {}
  for i=1, n do
    local v = newVec3(math.random()*2-1, math.random()*2-1, math.random()*2-1)
    table.insert(points, v)
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
    movingLightEnabled = false,
    showBorderPoints = true,
    showAxis = true,
  },
  
  width = 800,
  height = 600,
}

function app:SetWireframeEnabled()
  self.render.wireFrameEnabled = not self.render.wireFrameEnabled
  gl.PolygonMode(gl.FRONT_AND_BACK, self.render.wireFrameEnabled and gl.LINE or gl.FILL) 
end

function app:SetMovingLightEnabled()
  self.options.movingLightEnabled = not self.options.movingLightEnabled
end

function app:SetBorderOptionsEnabled()
  self.options.showBorderPoints = not self.options.showBorderPoints
end

function app:SetAxisEnabled()
  self.options.showAxis = not self.options.showAxis
end

function app:SetFlatEnabled()
  self.render.flatEnabled = not self.render.flatEnabled
  gl.ShadeModel(self.render.flatEnabled and gl.FLAT or gl.SMOOTH)
end

function CreateGlCanvas(GetPoints_cb, GetPolys_cb, GetBorderPoints_cb)
  local glCanvas = iup.glcanvas{buffer="DOUBLE"}
  local rotateAngle = 0
  local rotateAngleInc = 5
  local rotateAxis = newVec3(0,1,0)
  
  local function SetupLights()
    local ambient = { .2, .2, .2, 1.} 
    local diffuse = { .8, .8, .8, 1.} 
    local specular = { 1., 1., 1., 1.} 

    gl.Light(gl.LIGHT0, gl.AMBIENT,  ambient)
    gl.Light(gl.LIGHT0, gl.DIFFUSE,  diffuse)
    gl.Light(gl.LIGHT0, gl.SPECULAR, specular)
    
    gl.Light(gl.LIGHT1, gl.AMBIENT,  ambient)
    gl.Light(gl.LIGHT1, gl.DIFFUSE,  diffuse)
    gl.Light(gl.LIGHT1, gl.SPECULAR, specular)

  end 

  local function ActiveLight(op)
    if op then
      local pos = { 0., 3., 2., 1.} 
      gl.PushAttrib(gl.LIGHTING_BIT, gl.ENABLE_BIT)
      
      gl.Disable(gl.LIGHTING)
      
      gl.Enable(gl.POINT_SMOOTH)
      gl.PointSize(12)
      
      gl.Color(1,1,1)
      gl.Begin(gl.POINTS)
        gl.Vertex(pos[1], pos[2], pos[3])
      gl.End()
      
      gl.Enable(gl.LIGHTING)
      gl.Enable(gl.LIGHT0)

      gl.Light(gl.LIGHT0, gl.POSITION, pos)
    else
      gl.PopAttrib()
    end
  end
  
  local function ActiveCamLight(op, x, y, z)
    if op then
      local pos = { x, y, z, 1.} 
      gl.PushAttrib(gl.LIGHTING_BIT, gl.ENABLE_BIT)
      gl.Enable(gl.LIGHTING)
      
      gl.Enable(gl.LIGHT1)

      gl.Light(gl.LIGHT1, gl.POSITION, pos)
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
      gl.PushAttrib('LIGHTING_BIT')
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
    
    gl.LoadIdentity()
    glu.LookAt(x,y,z, 0, 0, 0, ux, uy, uz)
    return x, y, z, 0, 0, 0, ux, uy, yz
  end        

  local function DrawAxis()
    gl.PushAttrib(gl.LINE_BIT)
    gl.LineWidth(2)
    gl.Begin(gl.LINES)
      gl.Color(0, 0, 1); gl.Vertex(0, 0, 0); gl.Color(0, 0, 1); gl.Vertex(0, 0, 1000)
      gl.Color(0, 1, 0); gl.Vertex(0, 0, 0); gl.Color(0, 1, 0); gl.Vertex(0, 1000, 0)
      gl.Color(1, 0, 0); gl.Vertex(0, 0, 0); gl.Color(1, 0, 0); gl.Vertex(1000, 0, 0)
    gl.End()
    gl.PopAttrib()
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
        -- points = generateRandomPoints(10)
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
   

    if app.options.movingLightEnabled then
      rotateAngle = rotateAngle + rotateAngleInc
    end
    gl.PushMatrix()
    gl.Rotate(rotateAngle, rotateAxis.x, rotateAxis.y, rotateAxis.z)
      ActiveLight(true)
    gl.PopMatrix()

    ActiveCamLight(true, x, y, z)
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
    ActiveCamLight(false)
    ActiveLight(false)
    
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
  self.points = generateRandomPoints(self.numPoints)
  self.polys = getHullPolys(self.points)
  self.borderpoints = getBorderPoints(self.points, self.polys)
  for i, point in ipairs(self.points) do
    local str = string.format("%.2f", point.x)..",  ".. string.format("%.2f", point.y)..",  ".. string.format("%.2f", point.z)
    self.pointsList[i] = str
  end
  self.pointsList[#self.points + 1] = nil
end

function ConvexHullVisual:BuildInterface()
  self.pointsList = iup.list{expand = "VERTICAL"}
  self:GeneratePoints()

  self.numPointsText = iup.text{value = tostring(self.numPoints)}
  
  self.opsBox = iup.hbox {
    iup.fill{size = 5},
    iup.vbox{
      iup.fill{size = 5},
      -------------------------
      iup.toggle{title = "WireFrame", value = app.render.wireFrameEnabled and "ON" or "OFF", 
        action = function(lself) app:SetWireframeEnabled()     end
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
      
      iup.toggle{title = "MovingLight", value = app.render.movingLight and "ON" or "OFF", 
        action = function(lself) app:SetMovingLightEnabled()     end
      },
      ------------------------
      iup.fill{size = 15},
      iup.vbox{
        iup.label{title = "Points:"},
        self.pointsList
      },
      ------------------------
      iup.fill{size = 15},
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





