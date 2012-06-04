package
{
    import com.adobe.utils.*;
 
    import flash.display.*;
    import flash.display3D.*;
    import flash.display3D.textures.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.geom.*;
    import flash.text.*;
    import flash.utils.*;
 
    /**
    *   Test of view frustum culling on performance
    *   @author Jackson Dunstan, http://JacksonDunstan.com
    */
    public class ViewFrustumCulling extends Sprite 
    {
        /** Number of cubes per dimension (X, Y, Z) */
        private static const NUM_CUBES:int = 32;
 
        /** Number of total cubes */
        private static const NUM_CUBES_TOTAL:int = NUM_CUBES*NUM_CUBES*NUM_CUBES;
 
        /** Positions of all cubes' vertices */
        private static const POSITIONS:Vector.<Number> = new <Number>[
            // back face - bottom tri
            -0.5, -0.5, -0.5,
            -0.5, 0.5, -0.5,
            0.5, -0.5, -0.5,
            // back face - top tri
            -0.5, 0.5, -0.5,
            0.5, 0.5, -0.5,
            0.5, -0.5, -0.5,
 
            // front face - bottom tri
            -0.5, -0.5, 0.5,
            -0.5, 0.5, 0.5,
            0.5, -0.5, 0.5,
            // front face - top tri
            -0.5, 0.5, 0.5,
            0.5, 0.5, 0.5,
            0.5, -0.5, 0.5,
 
            // left face - bottom tri
            -0.5, -0.5, -0.5,
            -0.5, 0.5, -0.5,
            -0.5, -0.5, 0.5,
            // left face - top tri
            -0.5, 0.5, -0.5,
            -0.5, 0.5, 0.5,
            -0.5, -0.5, 0.5,
 
            // right face - bottom tri
            0.5, -0.5, -0.5,
            0.5, 0.5, -0.5,
            0.5, -0.5, 0.5,
            // right face - top tri
            0.5, 0.5, -0.5,
            0.5, 0.5, 0.5,
            0.5, -0.5, 0.5,
 
            // bottom face - bottom tri
            -0.5, -0.5, 0.5,
            -0.5, -0.5, -0.5,
            0.5, -0.5, 0.5,
            // bottom face - top tri
            -0.5, -0.5, -0.5,
            0.5, -0.5, -0.5,
            0.5, -0.5, 0.5,
 
            // top face - bottom tri
            -0.5, 0.5, 0.5,
            -0.5, 0.5, -0.5,
            0.5, 0.5, 0.5,
            // top face - top tri
            -0.5, 0.5, -0.5,
            0.5, 0.5, -0.5,
            0.5, 0.5, 0.5
        ];
 
        /** Texture coordinates of all cubes' vertices */
        private static const TEX_COORDS:Vector.<Number> = new <Number>[
            // back face - bottom tri
            1, 1,
            1, 0,
            0, 1,
            // back face - top tri
            1, 0,
            0, 0,
            0, 1,
 
            // front face - bottom tri
            0, 1,
            0, 0,
            1, 1,
            // front face - top tri
            0, 0,
            1, 0,
            1, 1,
 
            // left face - bottom tri
            0, 1,
            0, 0,
            1, 1,
            // left face - top tri
            0, 0,
            1, 0,
            1, 1,
 
            // right face - bottom tri
            1, 1,
            1, 0,
            0, 1,
            // right face - top tri
            1, 0,
            0, 0,
            0, 1,
 
            // bottom face - bottom tri
            0, 0,
            0, 1,
            1, 0,
            // bottom face - top tri
            0, 1,
            1, 1,
            1, 0,
 
            // top face - bottom tri
            0, 1,
            0, 0,
            1, 1,
            // top face - top tri
            0, 0,
            1, 0,
            1, 1
        ];
 
        /** Triangles of all cubes */
        private static const TRIS:Vector.<uint> = new <uint>[
            2, 1, 0,    // back face - bottom tri
            5, 4, 3,    // back face - top tri
            6, 7, 8,    // front face - bottom tri
            9, 10, 11,  // front face - top tri
            12, 13, 14, // left face - bottom tri
            15, 16, 17, // left face - top tri
            20, 19, 18, // right face - bottom tri
            23, 22, 21, // right face - top tri
            26, 25, 24, // bottom face - bottom tri
            29, 28, 27, // bottom face - top tri
            30, 31, 32, // top face - bottom tri
            33, 34, 35  // top face - bottom tri
        ];
 
        [Embed(source="/flash_logo.png")]
        private static const TEXTURE:Class;
 
        private static const TEMP_DRAW_MATRIX:Matrix3D = new Matrix3D();
 
        private var context3D:Context3D;
        private var vertexBuffer:VertexBuffer3D;
        private var vertexBuffer2:VertexBuffer3D;
        private var indexBuffer:IndexBuffer3D; 
        private var program:Program3D;
        private var texture:Texture;
        private var camera:Camera3D;
        private var cubes:Vector.<Cube> = new Vector.<Cube>();
 
        private var fps:TextField = new TextField();
        private var lastFPSUpdateTime:uint;
        private var lastFrameTime:uint;
        private var frameCount:uint;
        private var driver:TextField = new TextField();
        private var draws:TextField = new TextField();
 
        public function ViewFrustumCulling()
        {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.frameRate = 60;
 
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.requestContext3D(Context3DRenderMode.AUTO);
        }
 
        protected function onContextCreated(ev:Event): void
        {
            // Setup context
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            context3D = stage3D.context3D;            
            context3D.configureBackBuffer(
                stage.stageWidth,
                stage.stageHeight,
                0,
                true
            );
            context3D.enableErrorChecking = true;
 
            // Setup camera
            camera = new Camera3D(
                0.1, // near
                100, // far
                stage.stageWidth / stage.stageHeight, // aspect ratio
                40*(Math.PI/180), // vFOV
                -6, -8, 6, // position
                0, 0, 0, // target
                0, 1, 0 // up dir
            );
 
            // Setup cubes
            for (var i:int; i < NUM_CUBES; ++i)
            {
                for (var j:int = 0; j < NUM_CUBES; ++j)
                {
                    for (var k:int = 0; k < NUM_CUBES; ++k)
                    {
                        cubes.push(new Cube(i*2, j*2, -k*2));
                    }
                }
            }
 
            // Setup UI
            fps.background = true;
            fps.backgroundColor = 0xffffffff;
            fps.autoSize = TextFieldAutoSize.LEFT;
            fps.text = "Getting FPS...";
            addChild(fps);
 
            driver.background = true;
            driver.backgroundColor = 0xffffffff;
            driver.text = "Driver: " + context3D.driverInfo;
            driver.autoSize = TextFieldAutoSize.LEFT;
            driver.y = fps.height;
            addChild(driver);
 
            draws.background = true;
            draws.backgroundColor = 0xffffffff;
            draws.text = "Getting draws...";
            draws.autoSize = TextFieldAutoSize.LEFT;
            draws.y = driver.y + driver.height;
            addChild(draws);
 
            makeButtons(
                "Move Forward", "Move Backward", "Move Left", "Move Right",
                "Move Up", "Move Down", "Yaw Left", "Yaw Right",
                "Pitch Up", "Pitch Down", "Roll Left", "Roll Right"
            );
 
            var assembler:AGALMiniAssembler = new AGALMiniAssembler();
 
            // Vertex shader
            var vertSource:String = "m44 op, va0, vc0\nmov v0, va1\n"
            assembler.assemble(Context3DProgramType.VERTEX, vertSource);
            var vertexShaderAGAL:ByteArray = assembler.agalcode;
 
            // Fragment shader
            var fragSource:String = "tex oc, v0, fs0 <2d,linear,mipnone>";
            assembler.assemble(Context3DProgramType.FRAGMENT, fragSource);
            var fragmentShaderAGAL:ByteArray = assembler.agalcode;
 
            // Shader program
            program = context3D.createProgram();
            program.upload(vertexShaderAGAL, fragmentShaderAGAL);
 
            // Setup buffers
            vertexBuffer = context3D.createVertexBuffer(36, 3);
            vertexBuffer.uploadFromVector(POSITIONS, 0, 36);
            vertexBuffer2 = context3D.createVertexBuffer(36, 2);
            vertexBuffer2.uploadFromVector(TEX_COORDS, 0, 36);
            indexBuffer = context3D.createIndexBuffer(36);
            indexBuffer.uploadFromVector(TRIS, 0, 36);
 
            // Setup texture
            var bmd:BitmapData = (new TEXTURE() as Bitmap).bitmapData;
            texture = context3D.createTexture(
                bmd.width,
                bmd.height,
                Context3DTextureFormat.BGRA,
                true
            );
            texture.uploadFromBitmapData(bmd);
 
            // Start the simulation
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
 
        private function makeButtons(...labels): void
        {
            const PAD:Number = 5;
 
            var curX:Number = PAD;
            var curY:Number = stage.stageHeight - PAD;
            for each (var label:String in labels)
            {
                var tf:TextField = new TextField();
                tf.mouseEnabled = false;
                tf.selectable = false;
                tf.defaultTextFormat = new TextFormat("_sans", 16, 0x0071BB);
                tf.autoSize = TextFieldAutoSize.LEFT;
                tf.text = label;
                tf.name = "lbl";
 
                var button:Sprite = new Sprite();
                button.buttonMode = true;
                button.graphics.beginFill(0xF5F5F5);
                button.graphics.drawRect(0, 0, tf.width+PAD, tf.height+PAD);
                button.graphics.endFill();
                button.graphics.lineStyle(1);
                button.graphics.drawRect(0, 0, tf.width+PAD, tf.height+PAD);
                button.addChild(tf);
                button.addEventListener(MouseEvent.CLICK, onButton);
                if (curX + button.width > stage.stageWidth - PAD)
                {
                    curX = PAD;
                    curY -= button.height + PAD;
                }
                button.x = curX;
                button.y = curY - button.height;
                addChild(button);
 
                curX += button.width + PAD;
            }
        }
 
        private function onButton(ev:MouseEvent): void
        {
            var mode:String = ev.target.getChildByName("lbl").text;
            switch (mode)
            {
                case "Move Forward":
                    camera.moveForward(1);
                    break;
                case "Move Backward":
                    camera.moveBackward(1);
                    break;
                case "Move Left":
                    camera.moveLeft(1);
                    break;
                case "Move Right":
                    camera.moveRight(1);
                    break;
                case "Move Up":
                    camera.moveUp(1);
                    break;
                case "Move Down":
                    camera.moveDown(1);
                    break;
                case "Yaw Left":
                    camera.yaw(-10);
                    break;
                case "Yaw Right":
                    camera.yaw(10);
                    break;
                case "Pitch Up":
                    camera.pitch(-10);
                    break;
                case "Pitch Down":
                    camera.pitch(10);
                    break;
                case "Roll Left":
                    camera.roll(10);
                    break;
                case "Roll Right":
                    camera.roll(-10);
                    break;
            }
        }
 
        private function onEnterFrame(ev:Event): void
        {
            // Render scene
            context3D.setProgram(program);
            context3D.setVertexBufferAt(
                0,
                vertexBuffer,
                0,
                Context3DVertexBufferFormat.FLOAT_3
            );
            context3D.setVertexBufferAt(
                1,
                vertexBuffer2,
                0,
                Context3DVertexBufferFormat.FLOAT_2
            );
            context3D.setTextureAt(0, texture);
 
            context3D.clear(0.5, 0.5, 0.5);
 
            // Draw all cubes
            var worldToClip:Matrix3D = camera.worldToClipMatrix;
            var drawMatrix:Matrix3D = TEMP_DRAW_MATRIX;
            var numDraws:int;
            for each (var cube:Cube in cubes)
            {
                if (camera.isSphereInFrustum(cube.sphere))
                {
                    cube.mat.copyToMatrix3D(drawMatrix);
                    drawMatrix.prepend(worldToClip);
                    context3D.setProgramConstantsFromMatrix(
                        Context3DProgramType.VERTEX,
                        0,
                        drawMatrix,
                        false
                    );
                    context3D.drawTriangles(indexBuffer, 0, 12);
                    numDraws++;
                }
            }
            draws.text = "Draws: " + numDraws + " / " + NUM_CUBES_TOTAL
                + " (" + (100*(numDraws/NUM_CUBES_TOTAL)).toFixed(1) + "%)";
 
            context3D.present();
 
            // Update frame rate display
            frameCount++;
            var now:int = getTimer();
            var dTime:int = now - lastFrameTime;
            var elapsed:int = now - lastFPSUpdateTime;
            if (elapsed > 1000)
            {
                var framerateValue:Number = 1000 / (elapsed / frameCount);
                fps.text = "FPS: " + framerateValue.toFixed(1);
                lastFPSUpdateTime = now;
                frameCount = 0;
            }
            lastFrameTime = now;
        }
    }
}
import flash.geom.*;
class Cube
{
    public var mat:Matrix3D;
    public var sphere:Vector3D;
 
    public function Cube(x:Number, y:Number, z:Number)
    {
        mat = new Matrix3D(
            new <Number>[
                1, 0, 0, x,
                0, 1, 0, y,
                0, 0, 1, z,
                0, 0, 0, 1
            ]
        );
        sphere = new Vector3D(x, y, z, 2);
    }
}