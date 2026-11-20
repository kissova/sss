#define IMGUI_DEFINE_MATH_OPERATORS
#import "DrawView.h"
#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>
#include "imgui.h"
#include "imgui_impl_metal.h"

bool menu_open = false;
bool show_4e_menu = false;
bool show_neverlose_menu = false;

static bool e4_opt1 = false;
static bool e4_opt2 = false;
static float e4_slider = 50.0f;

static bool nl_opt1 = false;
static bool nl_opt2 = false;
static float nl_slider = 50.0f;

@interface ImGuiDrawView () <MTKViewDelegate>
@end

@implementation ImGuiDrawView

- (instancetype)init {
    self = [super init];
    if (self) {
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();

        ImGuiIO &io = ImGui::GetIO();
        io.IniFilename = nullptr;
        io.Fonts->AddFontDefault();

        ImGui::StyleColorsDark();
        ImGuiStyle &style = ImGui::GetStyle();
        style.WindowRounding = 10.0f;
        style.FrameRounding = 6.0f;
        style.ScaleAllSizes(1.1f);

        id<MTLDevice> dev = MTLCreateSystemDefaultDevice();
        if (dev) {
            ImGui_ImplMetal_Init(dev);
        }
    }
    return self;
}

- (void)loadView {
    CGRect bounds = [UIScreen mainScreen].bounds;
    self.view = [[MTKView alloc] initWithFrame:bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    MTKView *mtk = (MTKView *)self.view;
    mtk.device = MTLCreateSystemDefaultDevice();
    mtk.delegate = self;
    mtk.clearColor = MTLClearColorMake(0, 0, 0, 0);
    mtk.backgroundColor = [UIColor clearColor];
    mtk.opaque = NO;
}

- (void)updateIOWithTouchEvent:(UIEvent *)event {
    ImGuiIO &io = ImGui::GetIO();
    UITouch *touch = event.allTouches.anyObject;
    if (touch) {
        CGPoint pos = [touch locationInView:self.view];
        io.MousePos = ImVec2(pos.x, pos.y);
    }

    BOOL isDown = NO;
    for (UITouch *t in event.allTouches) {
        if (t.phase != UITouchPhaseEnded && t.phase != UITouchPhaseCancelled) {
            isDown = YES;
            break;
        }
    }
    io.MouseDown[0] = isDown;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)drawInMTKView:(MTKView *)view {
    if (!menu_open || (!show_4e_menu && !show_neverlose_menu)) {
        return;
    }

    id<MTLDevice> dev = view.device ? view.device : MTLCreateSystemDefaultDevice();
    id<MTLCommandQueue> queue = [dev newCommandQueue];
    if (!dev || !queue) {
        return;
    }

    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize = ImVec2(view.bounds.size.width, view.bounds.size.height);
    CGFloat scale = view.window.screen.nativeScale > 0 ? view.window.screen.nativeScale : 1.0f;
    io.DisplayFramebufferScale = ImVec2(scale, scale);
    io.DeltaTime = 1.0f / 60.0f;

    id<MTLCommandBuffer> commandBuffer = [queue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (!renderPassDescriptor) {
        [commandBuffer commit];
        return;
    }

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder pushDebugGroup:@"ImGuiMenu"];

    ImGui_ImplMetal_NewFrame(renderPassDescriptor);
    ImGui::NewFrame();

    if (show_4e_menu) {
        ImGui::SetNextWindowSize(ImVec2(360, 250), ImGuiCond_FirstUseEver);
        if (ImGui::Begin("4E?", &show_4e_menu)) {
            ImGui::Text("4E? Panel");
            ImGui::Separator();
            ImGui::Checkbox("Option 1", &e4_opt1);
            ImGui::Checkbox("Option 2", &e4_opt2);
            ImGui::SliderFloat("Value", &e4_slider, 0.0f, 100.0f, "%.0f");
        }
        ImGui::End();
        if (!show_4e_menu) {
            menu_open = show_neverlose_menu;
        }
    }

    if (show_neverlose_menu) {
        ImGui::SetNextWindowSize(ImVec2(360, 250), ImGuiCond_FirstUseEver);
        if (ImGui::Begin("NEVERLOSE", &show_neverlose_menu)) {
            ImGui::Text("NEVERLOSE Panel");
            ImGui::Separator();
            ImGui::Checkbox("Option 1", &nl_opt1);
            ImGui::Checkbox("Option 2", &nl_opt2);
            ImGui::SliderFloat("Value", &nl_slider, 0.0f, 100.0f, "%.0f");
        }
        ImGui::End();
        if (!show_neverlose_menu) {
            menu_open = show_4e_menu;
        }
    }

    if (!show_4e_menu && !show_neverlose_menu) {
        menu_open = false;
        self.view.hidden = YES;
        [self.view setUserInteractionEnabled:NO];
    }

    ImGui::Render();
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderEncoder);

    [renderEncoder popDebugGroup];
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end
