//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  TikTokDevDylib.m
//  TikTokDevDylib
//
//  Created by Darren Ou on 2021/8/24.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//

#import "TikTokDevDylib.h"
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Cycript/Cycript.h>
#import <MDCycriptManager.h>
#import <VideoToolbox/VideoToolbox.h>
#import "fishhook.h"
#import <OpenGLES/EAGLDrawable.h>
#import <AVFoundation/AVFoundation.h>

static NSObject *_lock;
static double kOutputTs = 0;
static double kDecodeTs = 0;
static double kDisplayTs = 0;
static double kTextureTs = 0;

CHDeclareClass(AWEUserPolicyAlertViewController)
CHDeclareClass(EAGLContext)

CHOptimizedMethod1(self, void, EAGLContext, presentRenderbuffer, NSUInteger, arg1) {
    NSTimeInterval lastTs = kDisplayTs;
    kDisplayTs = [[NSDate date] timeIntervalSince1970];
    printf("---- - %f presentRenderbuffer:%p target %lu cost%f rate:%f thread:%s\n", kDisplayTs, self, (unsigned long)arg1, (kDisplayTs - kOutputTs) * 1000, 1 / (kDisplayTs - lastTs), [[NSThread currentThread].description UTF8String]);
    CHSuper1(EAGLContext, presentRenderbuffer, arg1);
}

void perform(id tar, SEL sel) {
    [tar performSelector:sel];
}

CHOptimizedMethod1(self, void, AWEUserPolicyAlertViewController, viewWillAppear, BOOL, arg1) {
    perform(self, @selector(dismissAllPopUp));
    CHSuper1(AWEUserPolicyAlertViewController, viewWillAppear, arg1);
}

CHConstructor {
    CHLoadLateClass(AWEUserPolicyAlertViewController);
    CHLoadLateClass(EAGLContext);
    
    CHHook1(AWEUserPolicyAlertViewController, viewWillAppear);
    CHHook1(EAGLContext, presentRenderbuffer);
}

static OSStatus (*oldVTDecompressionSessionCreate)(CM_NULLABLE CFAllocatorRef allocator, CM_NONNULL CMVideoFormatDescriptionRef videoFormatDescription, CM_NULLABLE CFDictionaryRef videoDecoderSpecification, CM_NULLABLE CFDictionaryRef destinationImageBufferAttributes, const VTDecompressionOutputCallbackRecord * CM_NULLABLE outputCallback, CM_RETURNS_RETAINED_PARAMETER CM_NULLABLE VTDecompressionSessionRef * CM_NONNULL decompressionSessionOut);

OSStatus myVTDecompressionSessionCreate(CM_NULLABLE CFAllocatorRef allocator, CM_NONNULL CMVideoFormatDescriptionRef videoFormatDescription, CM_NULLABLE CFDictionaryRef videoDecoderSpecification, CM_NULLABLE CFDictionaryRef destinationImageBufferAttributes, const VTDecompressionOutputCallbackRecord * CM_NULLABLE outputCallback, CM_RETURNS_RETAINED_PARAMETER CM_NULLABLE VTDecompressionSessionRef * CM_NONNULL decompressionSessionOut) {
    
    NSLog(@"---- - VTDecompressionSessionCreate");
    
    return oldVTDecompressionSessionCreate(allocator, videoFormatDescription, videoDecoderSpecification, destinationImageBufferAttributes, outputCallback, decompressionSessionOut);
}

static OSStatus (*oldVTCompressionSessionCreate)(CM_NULLABLE CFAllocatorRef allocator, int32_t width, int32_t height, CMVideoCodecType codecType, CM_NULLABLE CFDictionaryRef encoderSpecification, CM_NULLABLE CFDictionaryRef sourceImageBufferAttributes, CM_NULLABLE CFAllocatorRef compressedDataAllocator, CM_NULLABLE VTCompressionOutputCallback outputCallback, void * CM_NULLABLE outputCallbackRefCon, CM_RETURNS_RETAINED_PARAMETER CM_NULLABLE VTCompressionSessionRef * CM_NONNULL compressionSessionOut);

OSStatus myVTCompressionSessionCreate(CM_NULLABLE CFAllocatorRef allocator, int32_t width, int32_t height, CMVideoCodecType codecType, CM_NULLABLE CFDictionaryRef encoderSpecification, CM_NULLABLE CFDictionaryRef sourceImageBufferAttributes, CM_NULLABLE CFAllocatorRef compressedDataAllocator, CM_NULLABLE VTCompressionOutputCallback outputCallback, void * CM_NULLABLE outputCallbackRefCon, CM_RETURNS_RETAINED_PARAMETER CM_NULLABLE VTCompressionSessionRef * CM_NONNULL compressionSessionOut) {
    printf("---- - VTCompressionSessionCreate width:%d height:%d\n", width, height);
    return oldVTCompressionSessionCreate(allocator, width, height, codecType, encoderSpecification, sourceImageBufferAttributes, compressedDataAllocator, outputCallback, outputCallbackRefCon, compressionSessionOut);
}

static void (*oldglShaderSource) (GLuint shader, GLsizei count, const GLchar* const *string, const GLint* length);

void myglShaderSource (GLuint shader, GLsizei count, const GLchar* const *string, const GLint* length) {
    printf("---- - glShaderSource shader:%d string:%s\n", shader, *string);
    oldglShaderSource(shader, count, string, length);
}

static id (*oldMTLCreateSystemDefaultDevice)();

id myMTLCreateSystemDefaultDevice() {
    printf("---- - MTLCreateSystemDefaultDevice\n");
    return oldMTLCreateSystemDefaultDevice();
}

static CVReturn (*oldCVOpenGLESTextureCacheCreateTextureFromImage)(
                                                                   CFAllocatorRef CV_NULLABLE allocator,
                                                                   CVOpenGLESTextureCacheRef CV_NONNULL textureCache,
                                                                   CVImageBufferRef CV_NONNULL sourceImage,
                                                                   CFDictionaryRef CV_NULLABLE textureAttributes,
                                                                   GLenum target,
                                                                   GLint internalFormat,
                                                                   GLsizei width,
                                                                   GLsizei height,
                                                                   GLenum format,
                                                                   GLenum type,
                                                                   size_t planeIndex,
                                                                   CV_RETURNS_RETAINED_PARAMETER CVOpenGLESTextureRef CV_NULLABLE * CV_NONNULL textureOut );

static CVReturn myCVOpenGLESTextureCacheCreateTextureFromImage(
                                                               CFAllocatorRef CV_NULLABLE allocator,
                                                               CVOpenGLESTextureCacheRef CV_NONNULL textureCache,
                                                               CVImageBufferRef CV_NONNULL sourceImage,
                                                               CFDictionaryRef CV_NULLABLE textureAttributes,
                                                               GLenum target,
                                                               GLint internalFormat,
                                                               GLsizei width,
                                                               GLsizei height,
                                                               GLenum format,
                                                               GLenum type,
                                                               size_t planeIndex,
                                                               CV_RETURNS_RETAINED_PARAMETER CVOpenGLESTextureRef CV_NULLABLE * CV_NONNULL textureOut ) {
    CVReturn re = oldCVOpenGLESTextureCacheCreateTextureFromImage(allocator, textureCache, sourceImage, textureAttributes, target, internalFormat, width, height, format, type, planeIndex, textureOut);
    kTextureTs = [[NSDate date] timeIntervalSince1970];
    CVPixelBufferLockBaseAddress(sourceImage, 0);
    printf("---- - %f CVOpenGLESTextureCacheCreateTextureFromImage:%dx%d res:%d sourceImage:%p textureOut:%p, sourceImageAddr:%p target:%d, name:%d cost:%f thread:%s\n", kTextureTs, width, height, re, sourceImage, textureOut, CVPixelBufferGetBaseAddress(sourceImage), CVOpenGLESTextureGetTarget(*textureOut), CVOpenGLESTextureGetName(*textureOut), (kTextureTs - kOutputTs) * 1000, [[NSThread currentThread].description UTF8String]);
    CVPixelBufferUnlockBaseAddress(sourceImage, 0);
    return re;
}

static CVReturn (*oldCVMetalTextureCacheCreateTextureFromImage)(
                                                                CFAllocatorRef CV_NULLABLE allocator,
                                                                CVMetalTextureCacheRef CV_NONNULL textureCache,
                                                                CVImageBufferRef CV_NONNULL sourceImage,
                                                                CFDictionaryRef CV_NULLABLE textureAttributes,
                                                                MTLPixelFormat pixelFormat,
                                                                size_t width,
                                                                size_t height,
                                                                size_t planeIndex,
                                                                CV_RETURNS_RETAINED_PARAMETER CVMetalTextureRef CV_NULLABLE * CV_NONNULL textureOut );

static CVReturn myCVMetalTextureCacheCreateTextureFromImage(
                                                            CFAllocatorRef CV_NULLABLE allocator,
                                                            CVMetalTextureCacheRef CV_NONNULL textureCache,
                                                            CVImageBufferRef CV_NONNULL sourceImage,
                                                            CFDictionaryRef CV_NULLABLE textureAttributes,
                                                            MTLPixelFormat pixelFormat,
                                                            size_t width,
                                                            size_t height,
                                                            size_t planeIndex,
                                                            CV_RETURNS_RETAINED_PARAMETER CVMetalTextureRef CV_NULLABLE * CV_NONNULL textureOut ) {
    CVReturn re = oldCVMetalTextureCacheCreateTextureFromImage(allocator, textureCache, sourceImage, textureAttributes, pixelFormat, width, height, planeIndex, textureOut);
    printf("---- - %f CVMetalTextureCacheCreateTextureFromImage:%zuux%d res:%d sourceImage:%p textureOut:%p, sourceImageAddr:%p thread:%s\n", [[NSDate date] timeIntervalSince1970], width, height, re, sourceImage, textureOut, CVPixelBufferGetBaseAddress(sourceImage), [[NSThread currentThread].description UTF8String]);
    return re;
}

static OSStatus (*oldVTCompressionSessionEncodeFrame)(
                                                      CM_NONNULL VTCompressionSessionRef    session,
                                                      CM_NONNULL CVImageBufferRef            imageBuffer,
                                                      CMTime                                presentationTimeStamp,
                                                      CMTime                                duration, // may be kCMTimeInvalid
                                                      CM_NULLABLE CFDictionaryRef            frameProperties,
                                                      void * CM_NULLABLE                    sourceFrameRefcon,
                                                      VTEncodeInfoFlags * CM_NULLABLE        infoFlagsOut );

static OSStatus myVTCompressionSessionEncodeFrame(
                                                  CM_NONNULL VTCompressionSessionRef    session,
                                                  CM_NONNULL CVImageBufferRef            imageBuffer,
                                                  CMTime                                presentationTimeStamp,
                                                  CMTime                                duration, // may be kCMTimeInvalid
                                                  CM_NULLABLE CFDictionaryRef            frameProperties,
                                                  void * CM_NULLABLE                    sourceFrameRefcon,
                                                  VTEncodeInfoFlags * CM_NULLABLE        infoFlagsOut ) {
    OSStatus st = oldVTCompressionSessionEncodeFrame(session, imageBuffer, presentationTimeStamp, duration, frameProperties, sourceFrameRefcon, infoFlagsOut);
    NSTimeInterval lastTs = kDecodeTs;
    kDecodeTs = [[NSDate date] timeIntervalSince1970];
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    printf("---- - %f VTCompressionSessionEncodeFrame:%d imageBuffer:%p addr:%p cost:%f rate:%f thread:%s\n", kDecodeTs, st, imageBuffer, CVPixelBufferGetBaseAddress(imageBuffer), (kDecodeTs - kOutputTs) * 1000, 1 / (kDecodeTs - lastTs), [[NSThread currentThread].description UTF8String]);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    //    printf("---- - %f VTCompressionSessionEncodeFrame:%f\n", kDecodeTs, (kDecodeTs - kOutputTs) * 1000);
    sleep(1);
    return st;
}

static CVReturn (*oldCVPixelBufferCreate)(
                                          CFAllocatorRef CV_NULLABLE allocator,
                                          size_t width,
                                          size_t height,
                                          OSType pixelFormatType,
                                          CFDictionaryRef CV_NULLABLE pixelBufferAttributes,
                                          CV_RETURNS_RETAINED_PARAMETER CVPixelBufferRef CV_NULLABLE * CV_NONNULL pixelBufferOut);

static CVReturn myCVPixelBufferCreate(
                                      CFAllocatorRef CV_NULLABLE allocator,
                                      size_t width,
                                      size_t height,
                                      OSType pixelFormatType,
                                      CFDictionaryRef CV_NULLABLE pixelBufferAttributes,
                                      CV_RETURNS_RETAINED_PARAMETER CVPixelBufferRef CV_NULLABLE * CV_NONNULL pixelBufferOut) {
    printf("---- - %f CVPixelBufferCreate:%zux%zu pixelBufferOutAddr:%p thread:%s\n", [[NSDate date] timeIntervalSince1970], width, height, pixelBufferOut, [[NSThread currentThread].description UTF8String]);
    return oldCVPixelBufferCreate(allocator, width, height, pixelFormatType, pixelBufferAttributes, pixelBufferOut);
}

static void (*oldglBindFramebuffer) (GLenum target, GLuint framebuffer);

static void myglBindFramebuffer (GLenum target, GLuint framebuffer) {
    printf("---- - %f glBindFramebuffer: %d, %d, thread:%s\n", [[NSDate date] timeIntervalSince1970], target, framebuffer, [[NSThread currentThread].description UTF8String]);
    oldglBindFramebuffer(target, framebuffer);
}

static void (*oldglFramebufferTexture2D) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);

static void myglFramebufferTexture2D (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level) {
    printf("---- - %f glFramebufferTexture2D target:%d attachment:%d textarget:%d texture:%d level:%d thread:%s\n", [[NSDate date] timeIntervalSince1970], target, attachment, textarget, texture, level, [[NSThread currentThread].description UTF8String]);
    oldglFramebufferTexture2D(target, attachment, textarget, texture, level);
}

void (*oldglBindTexture) (GLenum target, GLuint texture);

void myglBindTexture (GLenum target, GLuint texture) {
    printf("---- - %f glBindTexture: %d thread:%s\n", [[NSDate date] timeIntervalSince1970], texture, [[NSThread currentThread].description UTF8String]);
    oldglBindTexture(target, texture);
}

static OSStatus (*oldVTDecompressionSessionDecodeFrame)(
                                                        CM_NONNULL VTDecompressionSessionRef    session,
                                                        CM_NONNULL CMSampleBufferRef            sampleBuffer,
                                                        VTDecodeFrameFlags                        decodeFlags, // bit 0 is enableAsynchronousDecompression
                                                        void * CM_NULLABLE                        sourceFrameRefCon,
                                                        VTDecodeInfoFlags * CM_NULLABLE         infoFlagsOut);

static OSStatus myVTDecompressionSessionDecodeFrame(
                                                    CM_NONNULL VTDecompressionSessionRef    session,
                                                    CM_NONNULL CMSampleBufferRef            sampleBuffer,
                                                    VTDecodeFrameFlags                        decodeFlags, // bit 0 is enableAsynchronousDecompression
                                                    void * CM_NULLABLE                        sourceFrameRefCon,
                                                    VTDecodeInfoFlags * CM_NULLABLE         infoFlagsOut) {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    printf("---- - VTDecompressionSessionDecodeFrame width:%d height:%d\n", CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer));
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return oldVTDecompressionSessionDecodeFrame(session, sampleBuffer, decodeFlags, sourceFrameRefCon, infoFlagsOut);
}

CHConstructor{
    rebind_symbols((struct rebinding[1]){{"VTDecompressionSessionCreate", myVTDecompressionSessionCreate, (void *)&oldVTDecompressionSessionCreate}}, 1);
    rebind_symbols((struct rebinding[1]){{"VTCompressionSessionCreate", myVTCompressionSessionCreate, (void *)&oldVTCompressionSessionCreate}}, 1);
    rebind_symbols((struct rebinding[1]){{"glShaderSource", myglShaderSource, (void *)&oldglShaderSource}}, 1);
    rebind_symbols((struct rebinding[1]){{"MTLCreateSystemDefaultDevice", myMTLCreateSystemDefaultDevice, (void *)&oldMTLCreateSystemDefaultDevice}}, 1);
    rebind_symbols((struct rebinding[1]){{"CVOpenGLESTextureCacheCreateTextureFromImage", myCVOpenGLESTextureCacheCreateTextureFromImage, (void *)&oldCVOpenGLESTextureCacheCreateTextureFromImage}}, 1);
    rebind_symbols((struct rebinding[1]){{"VTCompressionSessionEncodeFrame", myVTCompressionSessionEncodeFrame, (void *)&oldVTCompressionSessionEncodeFrame}}, 1);
    rebind_symbols((struct rebinding[1]){{"CVPixelBufferCreate", myCVPixelBufferCreate, (void *)&oldCVPixelBufferCreate}}, 1);
    rebind_symbols((struct rebinding[1]){{"glBindFramebuffer", myglBindFramebuffer, (void *)&oldglBindFramebuffer}}, 1);
    rebind_symbols((struct rebinding[1]){{"glFramebufferTexture2D", myglFramebufferTexture2D, (void *)&oldglFramebufferTexture2D}}, 1);
    rebind_symbols((struct rebinding[1]){{"glBindTexture", myglBindTexture, (void *)&oldglBindTexture}}, 1);
    rebind_symbols((struct rebinding[1]){{"CVMetalTextureCacheCreateTextureFromImage", myCVMetalTextureCacheCreateTextureFromImage, (void *)&oldCVMetalTextureCacheCreateTextureFromImage}}, 1);
    rebind_symbols((struct rebinding[1]){{"VTDecompressionSessionDecodeFrame", myVTDecompressionSessionDecodeFrame, (void *)&oldVTDecompressionSessionDecodeFrame}}, 1);
    
}
CHDeclareClass(LiveCoreCamera)
CHDeclareClass(IESMMCaptureKit)
CHDeclareClass(CameraAudioDelegate)
CHDeclareClass(_TtC17TikTokNewScanImpl11ScanManager)
CHDeclareClass(AVCaptureVideoDataOutput)
CHDeclareClass(AVCaptureSession)
CHDeclareClass(AVCaptureDevice)

CHOptimizedMethod3(self, void, LiveCoreCamera, captureOutput, id, arg1, didOutputSampleBuffer, CMSampleBufferRef, arg2, fromConnection, id, arg3) {
    CHSuper3(LiveCoreCamera, captureOutput, arg1, didOutputSampleBuffer, arg2, fromConnection, arg3);
}

CHOptimizedMethod3(self, void, IESMMCaptureKit, captureOutput, id, arg1, didOutputSampleBuffer, CMSampleBufferRef, arg2, fromConnection, id, arg3) {
    NSTimeInterval lastTs = kOutputTs;
    kOutputTs = [[NSDate date] timeIntervalSince1970];
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(arg2);
    printf("---- - %f didOutputSampleBuffer pixelBuffer:%p rate:%f thread:%s\n", kOutputTs, pixelBuffer, 1/ (kOutputTs - lastTs), [[NSThread currentThread].description UTF8String]);
    CHSuper3(IESMMCaptureKit, captureOutput, arg1, didOutputSampleBuffer, arg2, fromConnection, arg3);
}

CHOptimizedMethod3(self, void, CameraAudioDelegate, captureOutput, id, arg1, didOutputSampleBuffer, CMSampleBufferRef, arg2, fromConnection, id, arg3) {
    CHSuper3(CameraAudioDelegate, captureOutput, arg1, didOutputSampleBuffer, arg2, fromConnection, arg3);
}

CHOptimizedMethod3(self, void, _TtC17TikTokNewScanImpl11ScanManager, captureOutput, id, arg1, didOutputSampleBuffer, CMSampleBufferRef, arg2, fromConnection, id, arg3) {
    CHSuper3(_TtC17TikTokNewScanImpl11ScanManager, captureOutput, arg1, didOutputSampleBuffer, arg2, fromConnection, arg3);
}

CHOptimizedMethod1(self, void, AVCaptureVideoDataOutput, setVideoSettings, id, arg1) {
    CHSuper1(AVCaptureVideoDataOutput, setVideoSettings, arg1);
}

CHOptimizedMethod1(self, void, AVCaptureDevice, setActiveVideoMinFrameDuration, CMTime, arg1) {
    printf("");
    CHSuper1(AVCaptureDevice, setActiveVideoMinFrameDuration, arg1);
}

CHOptimizedMethod1(self, void, AVCaptureDevice, setActiveVideoMaxFrameDuration, CMTime, arg1) {
    CHSuper1(AVCaptureDevice, setActiveVideoMaxFrameDuration, arg1);
}

CHOptimizedMethod0(self, id, AVCaptureSession, init) {
    printf("----- AVCaptureSession init\n");
    return CHSuper0(AVCaptureSession, init);
}

CHOptimizedMethod2(self, void, AVCaptureVideoDataOutput, setSampleBufferDelegate, id, arg1, queue, dispatch_queue_t, arg2) {
    printf("----- setSampleBufferDelegate thread:%s\n", [[NSThread currentThread].description UTF8String]);
    CHSuper2(AVCaptureVideoDataOutput, setSampleBufferDelegate, arg1, queue, arg2);
}

CHOptimizedMethod1(self, void, AVCaptureVideoDataOutput, setAlwaysDiscardsLateVideoFrames, BOOL, arg1) {
    NSLog(@"---- - [AVCaptureVideoDataOutput setAlwaysDiscardsLateVideoFrames]: %d thread:%s", arg1, [[NSThread currentThread].description UTF8String]);
    CHSuper1(AVCaptureVideoDataOutput, setAlwaysDiscardsLateVideoFrames, arg1);
}

CHConstructor {
    _lock = [[NSObject alloc] init];
    
    CHLoadLateClass(LiveCoreCamera);
    CHLoadLateClass(IESMMCaptureKit);
    CHLoadLateClass(CameraAudioDelegate);
    CHLoadLateClass(_TtC17TikTokNewScanImpl11ScanManager);
    CHLoadLateClass(AVCaptureSession);
    CHLoadLateClass(AVCaptureDevice);
    
    CHHook3(LiveCoreCamera, captureOutput, didOutputSampleBuffer, fromConnection);
    CHHook3(IESMMCaptureKit, captureOutput, didOutputSampleBuffer, fromConnection);
    CHHook3(CameraAudioDelegate, captureOutput, didOutputSampleBuffer, fromConnection);
    CHHook3(_TtC17TikTokNewScanImpl11ScanManager, captureOutput, didOutputSampleBuffer, fromConnection);
    
    CHLoadLateClass(AVCaptureVideoDataOutput);
    
    CHHook1(AVCaptureVideoDataOutput, setVideoSettings);
    CHHook1(AVCaptureVideoDataOutput, setAlwaysDiscardsLateVideoFrames);
    CHHook2(AVCaptureVideoDataOutput, setSampleBufferDelegate, queue);
    CHHook0(AVCaptureSession, init);
    CHHook1(AVCaptureDevice, setActiveVideoMinFrameDuration);
    CHHook1(AVCaptureDevice, setActiveVideoMaxFrameDuration);
}
